// Ledger voucher entry form — billing slice (M06, G1, D3-B1/B2).
// One implementation behind the Receipt, Payment, Contra, Journal, Debit
// Note and Credit Note entry screens: ledger/party lookup, Dr/Cr entry,
// bill-wise allocation for receipt/payment (existing BillAllocationRepository
// semantics via the engine), narration, date, manual series + number, then
// one atomic post (validation, Dr=Cr, period lock, allocations, status move)
// plus engine cancel of the posted voucher with a reason. Money parsing
// (rupees to paise) uses the shared application-layer parser, never widget
// arithmetic. Posting semantics live in the engine; this screen only maps
// entry widgets to engine calls and renders loading/empty/validation/
// locked-period/success/recoverable-failure states.
// Traceability: FR-M06 (accounting vouchers); FR-M11 (held/counter out of
// scope here); D-M4 (paise); D3 (B1/B2).

import 'package:flutter/material.dart';

import 'package:niaverp/application/formatting/niav_format.dart';
import 'package:niaverp/application/parsing/entry_parsing.dart';
import 'package:niaverp/application/queries/outstanding.dart';
import 'package:niaverp/application/services/voucher_engine.dart';
import 'package:niaverp/core/result.dart';
import 'package:niaverp/core/value_objects/ids.dart';
import 'package:niaverp/core/value_objects/niav_date.dart';
import 'package:niaverp/data/accounting/stock_policy.dart';
import 'package:niaverp/data/repositories/ledger_masters.dart';
import 'package:niaverp/data/repositories/party_repository.dart';
import 'package:niaverp/data/repositories/voucher_repository.dart';
import 'package:niaverp/presentation/localization/app_localizations.dart';
import 'package:niaverp/presentation/shared/company_scope.dart';

/// What differs between the six ledger entry screens. Widget keys are
/// `<keyPrefix>-...`, so each flow keeps stable test keys.
class LedgerVoucherFormConfig {
  const LedgerVoucherFormConfig({
    required this.title,
    required this.titleKey,
    required this.keyPrefix,
    required this.typeCanonical,
    required this.partyRequired,
    required this.allowAllocations,
  });

  final String title;
  final String titleKey;
  final String keyPrefix;

  /// Canonical voucher type, e.g. 'Receipt' (engine profile governs).
  final String typeCanonical;

  /// True where the engine profile requires a party on a line.
  final bool partyRequired;

  /// True for receipt/payment (bill-wise allocation section is shown).
  final bool allowAllocations;
}

/// Receipt entry (keys `receipt-*`).
const LedgerVoucherFormConfig receiptFormConfig = LedgerVoucherFormConfig(
  title: 'New Receipt',
  titleKey: 'lvTitleReceipt',
  keyPrefix: 'receipt',
  typeCanonical: 'Receipt',
  partyRequired: true,
  allowAllocations: true,
);

/// Payment entry (keys `payment-*`).
const LedgerVoucherFormConfig paymentFormConfig = LedgerVoucherFormConfig(
  title: 'New Payment',
  titleKey: 'lvTitlePayment',
  keyPrefix: 'payment',
  typeCanonical: 'Payment',
  partyRequired: false,
  allowAllocations: true,
);

/// Contra entry (keys `contra-*`).
const LedgerVoucherFormConfig contraFormConfig = LedgerVoucherFormConfig(
  title: 'New Contra',
  titleKey: 'lvTitleContra',
  keyPrefix: 'contra',
  typeCanonical: 'Contra',
  partyRequired: false,
  allowAllocations: false,
);

/// Journal entry (keys `journal-*`).
const LedgerVoucherFormConfig journalFormConfig = LedgerVoucherFormConfig(
  title: 'New Journal',
  titleKey: 'lvTitleJournal',
  keyPrefix: 'journal',
  typeCanonical: 'Journal',
  partyRequired: false,
  allowAllocations: false,
);

/// Debit Note entry (keys `debitnote-*`).
const LedgerVoucherFormConfig debitNoteFormConfig = LedgerVoucherFormConfig(
  title: 'New Debit Note',
  titleKey: 'lvTitleDebit',
  keyPrefix: 'debitnote',
  typeCanonical: 'Debit Note without items',
  partyRequired: true,
  allowAllocations: false,
);

/// Credit Note entry (keys `creditnote-*`).
const LedgerVoucherFormConfig creditNoteFormConfig = LedgerVoucherFormConfig(
  title: 'New Credit Note',
  titleKey: 'lvTitleCredit',
  keyPrefix: 'creditnote',
  typeCanonical: 'Credit Note without items',
  partyRequired: true,
  allowAllocations: false,
);

/// One editable ledger line (ephemeral; posted lines are the record).
class _LedgerDraftLine {
  _LedgerDraftLine();

  EntityId? ledgerId;
  String drCr = 'Dr';
  final TextEditingController amount = TextEditingController();

  void dispose() {
    amount.dispose();
  }
}

/// One bill row available for allocation (amount entered by the user).
class _BillAllocRow {
  _BillAllocRow({required this.bill});

  final OutstandingBill bill;
  final TextEditingController amount = TextEditingController(text: '0');

  void dispose() {
    amount.dispose();
  }
}

/// Ledger voucher entry form driven by [LedgerVoucherFormConfig].
class LedgerVoucherFormScreen extends StatefulWidget {
  const LedgerVoucherFormScreen({
    super.key,
    required this.companyId,
    required this.scope,
    required this.config,
  });

  final CompanyId companyId;
  final CompanyScope scope;
  final LedgerVoucherFormConfig config;

  @override
  State<LedgerVoucherFormScreen> createState() =>
      LedgerVoucherFormScreenState();
}

class LedgerVoucherFormScreenState
    extends State<LedgerVoucherFormScreen> {
  String _k(String name) => '${widget.config.keyPrefix}-$name';

  CompanyScope get _scope => widget.scope;
  CompanyId get _company => widget.companyId;

  final TextEditingController _series = TextEditingController(text: 'Main');
  final TextEditingController _no = TextEditingController();
  final TextEditingController _date = TextEditingController();
  final TextEditingController _narration = TextEditingController();
  final TextEditingController _cancelReason = TextEditingController();
  EntityId? _partyId;

  final List<_LedgerDraftLine> _lines = <_LedgerDraftLine>[];
  final List<_BillAllocRow> _bills = <_BillAllocRow>[];

  bool _posting = false;
  bool _loaded = false;
  bool _billsFailed = false;
  String? _error;
  String? _locked;
  String? _postedVoucherId;
  String? _notice;

  @override
  void initState() {
    super.initState();
    _date.text = _scope.today.iso;
    _lines.add(_LedgerDraftLine());
    _loadBills();
  }

  Future<void> _loadBills() async {
    if (!widget.config.allowAllocations) {
      setState(() => _loaded = true);
      return;
    }
    try {
      final List<OutstandingBill> open =
          _scope.outstanding.bills(_company, asOf: _scope.today);
      if (!mounted) return;
      setState(() {
        _bills.addAll(<_BillAllocRow>[
          for (final OutstandingBill b in open) _BillAllocRow(bill: b),
        ]);
        _loaded = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _billsFailed = true;
        _loaded = true;
      });
    }
  }

  @override
  void dispose() {
    _series.dispose();
    _no.dispose();
    _date.dispose();
    _narration.dispose();
    _cancelReason.dispose();
    for (final _LedgerDraftLine l in _lines) {
      l.dispose();
    }
    for (final _BillAllocRow b in _bills) {
      b.dispose();
    }
    super.dispose();
  }

  void _fail(String message) {
    setState(() {
      _error = message;
      _locked = message.contains('locked period') ? message : null;
      _posting = false;
    });
  }

  List<Ledger> _ledgers() => _scope.ledgers.listByCompany(_company);

  List<Party> _parties() => _scope.parties.listByCompany(_company);

  Future<void> _post() async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    setState(() {
      _error = null;
      _locked = null;
      _notice = null;
      _billsFailed = false;
      _posting = true;
    });
    if (_series.text.trim().isEmpty || _no.text.trim().isEmpty) {
      _fail(l10n.t('lvNeedSeries'));
      return;
    }
    NiavDate date;
    try {
      date = NiavDate(_date.text.trim());
    } catch (_) {
      _fail(l10n.t('lvBadDate'));
      return;
    }
    if (widget.config.partyRequired && _partyId == null) {
      _fail(l10n.t('lvNeedParty'));
      return;
    }
    if (_lines.isEmpty) {
      _fail(l10n.t('lvNeedLine'));
      return;
    }
    int dr = 0;
    int cr = 0;
    for (final _LedgerDraftLine l in _lines) {
      if (l.ledgerId == null) {
        _fail(l10n.t('lvNeedLedger'));
        return;
      }
      final int amount = parsePaise(l.amount.text);
      if (amount <= 0) {
        _fail(l10n.t('lvNeedAmount'));
        return;
      }
      if (l.drCr == 'Dr') {
        dr += amount;
      } else {
        cr += amount;
      }
    }
    if (dr != cr) {
      _fail(l10n.t('lvImbalance'));
      return;
    }
    final String voucherId = _scope.write.idMint('v');
    final Result<Voucher> created = _scope.vouchers.create(
      id: EntityId(voucherId),
      companyId: _company,
      type: widget.config.typeCanonical,
      series: _series.text.trim(),
      no: _no.text.trim(),
      date: date,
      narration:
          _narration.text.trim().isEmpty ? null : _narration.text.trim(),
      deviceId: _scope.write.deviceId,
      opId: _scope.write.idMint('op'),
      eventId: _scope.write.idMint('ev'),
      actor: _scope.write.actor,
    );
    if (created.isErr) {
      _fail((created as Err<Voucher>).error.message);
      return;
    }
    int lineNo = 0;
    EntityId? firstLineId;
    for (final _LedgerDraftLine l in _lines) {
      lineNo += 1;
      final EntityId lineId =
          EntityId(_scope.write.idMint('vll'));
      firstLineId ??= lineId;
      final int amount = parsePaise(l.amount.text);
      final Result<VoucherLine> added = _scope.vouchers.addLine(
        lineId: lineId,
        voucherId: EntityId(voucherId),
        companyId: _company,
        lineNo: lineNo,
        ledgerId: l.ledgerId,
        partyId: _partyId,
        drCr: l.drCr,
        qtyQ4: 10000,
        ratePaise: amount,
        deviceId: _scope.write.deviceId,
        opId: _scope.write.idMint('op'),
        eventId: _scope.write.idMint('ev'),
        actor: _scope.write.actor,
      );
      if (added.isErr) {
        _fail((added as Err<VoucherLine>).error.message);
        return;
      }
    }
    final List<AllocationSpec> specs = <AllocationSpec>[];
    if (widget.config.allowAllocations && firstLineId != null) {
      for (final _BillAllocRow row in _bills) {
        final int want = parsePaise(row.amount.text);
        if (want <= 0) continue;
        final VoucherWithLines? bill =
            _scope.vouchers.get(_company, row.bill.voucherId);
        VoucherLine? source;
        if (bill != null) {
          for (final VoucherLine l in bill.lines) {
            if (l.drCr == null) {
              source = l;
              break;
            }
          }
        }
        if (source == null) {
          _fail(l10n.billNoAlloc(row.bill.voucherNo));
          return;
        }
        specs.add(AllocationSpec(
          sourceLineId: source.id,
          settlementLineId: firstLineId,
          amountPaise: want,
        ));
      }
    }
    final Result<PostingResult> posted = _scope.engine.postWithStock(
      id: EntityId(voucherId),
      companyId: _company,
      policy: StockPolicy.allow,
      allocations: specs,
      deviceId: _scope.write.deviceId,
      opId: _scope.write.idMint('op'),
      eventId: _scope.write.idMint('ev'),
      actor: _scope.write.actor,
    );
    if (posted.isErr) {
      _fail((posted as Err<PostingResult>).error.message);
      return;
    }
    setState(() {
      _posting = false;
      _postedVoucherId = voucherId;
    });
  }

  Future<void> _cancelPosted() async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final String? id = _postedVoucherId;
    if (id == null) return;
    if (_cancelReason.text.trim().isEmpty) {
      _fail(l10n.t('lvNeedReason'));
      return;
    }
    final Result<Voucher> cancelled = _scope.engine.cancelPosted(
      id: EntityId(id),
      companyId: _company,
      reason: _cancelReason.text.trim(),
      deviceId: _scope.write.deviceId,
      opId: _scope.write.idMint('op'),
      eventId: _scope.write.idMint('ev'),
      actor: _scope.write.actor,
    );
    if (cancelled.isErr) {
      _fail((cancelled as Err<Voucher>).error.message);
      return;
    }
    setState(() {
      _notice = l10n.t('okCancelled');
      _postedVoucherId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final NiavFormat fmt = NiavFormat(l10n.localeCode);
    final List<Ledger> ledgers = _ledgers();
    final List<Party> parties = _parties();
    return Scaffold(
      appBar: AppBar(title: Text(l10n.t(widget.config.titleKey))),
      body: ListView(
        key: ValueKey<String>(_k('form-list')),
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          if (_error != null || _billsFailed)
            Container(
              key: ValueKey<String>(_k('error')),
              padding: const EdgeInsets.all(8),
              color: Theme.of(context).colorScheme.errorContainer,
              child: Text(_error ?? l10n.t('errLoadBills')),
            ),
          if (_locked != null)
            Container(
              key: ValueKey<String>(_k('locked')),
              padding: const EdgeInsets.all(8),
              color: Theme.of(context).colorScheme.tertiaryContainer,
              child: Text(_locked!),
            ),
          if (_postedVoucherId != null)
            Container(
              key: ValueKey<String>(_k('success')),
              padding: const EdgeInsets.all(8),
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Text(l10n.postedMsg(_postedVoucherId!)),
            ),
          if (_notice != null)
            Text(
              _notice!,
              key: ValueKey<String>(_k('notice')),
            ),
          DropdownButtonFormField<EntityId>(
            key: ValueKey<String>(_k('party')),
            initialValue: _partyId,
            decoration: InputDecoration(labelText: l10n.t('lvPartyOpt')),
            items: <DropdownMenuItem<EntityId>>[
              for (final Party p in parties)
                DropdownMenuItem<EntityId>(
                    value: p.id, child: Text(p.name)),
            ],
            onChanged: (EntityId? v) => setState(() => _partyId = v),
          ),
          TextField(
            key: ValueKey<String>(_k('series')),
            controller: _series,
            decoration: InputDecoration(labelText: l10n.t('lvSeries')),
          ),
          TextField(
            key: ValueKey<String>(_k('no')),
            controller: _no,
            decoration: InputDecoration(labelText: l10n.t('lvNumber')),
          ),
          TextField(
            key: ValueKey<String>(_k('date')),
            controller: _date,
            decoration:
                InputDecoration(labelText: l10n.t('vfDate')),
          ),
          TextField(
            key: ValueKey<String>(_k('narration')),
            controller: _narration,
            decoration: InputDecoration(labelText: l10n.t('lvNarration')),
          ),
          if (_lines.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(l10n.t('lvNoLines')),
              ),
            ),
          for (int i = 0; i < _lines.length; i++)
            _lineRow(i, ledgers),
          TextButton(
            key: ValueKey<String>(_k('add-line')),
            onPressed: _posting
                ? null
                : () => setState(() => _lines.add(_LedgerDraftLine())),
            child: Text(l10n.t('lvAddLine')),
          ),
          if (widget.config.allowAllocations && !_loaded)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            ),
          if (widget.config.allowAllocations && _loaded && _bills.isNotEmpty)
            ...<Widget>[
              const Divider(),
              Text(l10n.t('lvAllocBills')),
              for (final _BillAllocRow row in _bills)
                TextField(
                  key: ValueKey<String>(
                      '${_k('bill')}-${row.bill.voucherId.value}'),
                  controller: row.amount,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                      labelText: l10n.allocLabel(
                          row.bill.voucherNo, fmt.paise(row.bill.openPaise))),
                ),
            ],
          FilledButton(
            key: ValueKey<String>(_k('post')),
            onPressed: _posting ? null : _post,
            child: _posting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : Text(l10n.t('commonPost')),
          ),
          if (_postedVoucherId != null) ...<Widget>[
            TextField(
              key: ValueKey<String>(_k('cancel-reason')),
              controller: _cancelReason,
              decoration:
                  InputDecoration(labelText: l10n.t('lvCancelReason')),
            ),
            TextButton(
              key: ValueKey<String>(_k('cancel-posted')),
              onPressed: _cancelPosted,
              child: Text(l10n.t('lvCancelPosted')),
            ),
          ],
        ],
      ),
    );
  }

  Widget _lineRow(int i, List<Ledger> ledgers) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final _LedgerDraftLine line = _lines[i];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: <Widget>[
            DropdownButtonFormField<EntityId>(
              key: ValueKey<String>('${_k('ledger')}-$i'),
              initialValue: line.ledgerId,
              decoration: InputDecoration(labelText: l10n.t('lvLedger')),
              items: <DropdownMenuItem<EntityId>>[
                for (final Ledger l in ledgers)
                  DropdownMenuItem<EntityId>(
                      value: l.id, child: Text(l.name)),
              ],
              onChanged: (EntityId? v) =>
                  setState(() => line.ledgerId = v),
            ),
            Row(
              children: <Widget>[
                ChoiceChip(
                  key: ValueKey<String>('${_k('side')}-$i-Dr'),
                  label: Text(l10n.t('wordDr')),
                  selected: line.drCr == 'Dr',
                  onSelected: (_) =>
                      setState(() => line.drCr = 'Dr'),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  key: ValueKey<String>('${_k('side')}-$i-Cr'),
                  label: Text(l10n.t('wordCr')),
                  selected: line.drCr == 'Cr',
                  onSelected: (_) =>
                      setState(() => line.drCr = 'Cr'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    key: ValueKey<String>('${_k('amount')}-$i'),
                    controller: line.amount,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    decoration:
                        InputDecoration(labelText: l10n.t('lvAmountRs')),
                  ),
                ),
                IconButton(
                  key: ValueKey<String>('${_k('remove-line')}-$i'),
                  icon: const Icon(Icons.delete),
                  tooltip: l10n.t('commonDeleteRow'),
                  onPressed: () {
                    line.dispose();
                    setState(() => _lines.removeAt(i));
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
