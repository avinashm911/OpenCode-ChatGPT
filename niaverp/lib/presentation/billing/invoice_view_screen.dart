// Posted invoice view — billing slice (M04/M05/M11, G1).
// Read-only record of one posted sales invoice over real repositories:
// header, lines with resolved names, D-M4 totals, open balance, posting
// warnings, and a plain-text preview with copy (framework clipboard — no
// plugin). "Record receipt/payment" posts the settlement voucher and
// allocates it
// across the invoice's open lines in line order (sequential fill); any
// remainder stays a reported advance. Print/PDF bytes and payment
// modes/cheques wait on their approved packages and verified rules (G5/G3).
// Traceability: FR-M05-001 (view/posted invoice); FR-M06-002 (receipt +
// allocation); FR-M14-001 (open balance); FR-M21-001 (preview text).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:niaverp/application/formatting/niav_format.dart';
import 'package:niaverp/application/services/voucher_engine.dart';
import 'package:niaverp/core/result.dart';
import 'package:niaverp/core/value_objects/ids.dart';
import 'package:niaverp/core/value_objects/quantity.dart';
import 'package:niaverp/data/accounting/stock_policy.dart';
import 'package:niaverp/data/migrations/validators.dart';
import 'package:niaverp/data/repositories/voucher_repository.dart';
import 'package:niaverp/data/repositories/voucher_type_repository.dart';
import 'package:niaverp/presentation/localization/app_localizations.dart';
import 'package:niaverp/presentation/shared/company_scope.dart';

/// Posted invoice record for [voucherId], with settlement recording.
/// [settlementCanonical] selects the settlement document posted from here:
/// 'Receipt' after a sale, 'Payment' after a purchase, null when the
/// document is never settled directly (delivery notes convert instead).
class InvoiceViewScreen extends StatefulWidget {
  const InvoiceViewScreen({
    super.key,
    required this.companyId,
    required this.voucherId,
    required this.scope,
    this.settlementCanonical,
    this.postingWarnings = const <String>[],
  });

  final CompanyId companyId;
  final EntityId voucherId;
  final CompanyScope scope;
  final String? settlementCanonical;
  final List<String> postingWarnings;

  @override
  State<InvoiceViewScreen> createState() => InvoiceViewScreenState();
}

/// Document (economic) lines versus engine-posted ledger arms (D3-A1).
/// Arms carry a Dr/Cr marker; document lines never do. Views, opens and
/// allocations below read document lines only.
bool _isDocLine(VoucherLine l) => l.drCr == null;

class InvoiceViewScreenState extends State<InvoiceViewScreen> {
  String? _notice;

  CompanyScope get _scope => widget.scope;
  CompanyId get _company => widget.companyId;

  String _itemName(EntityId? id) {
    if (id == null) return '—';
    return _scope.items.get(_company, id)?.name ?? id.value;
  }

  String _partyName(EntityId? id) {
    if (id == null) return '—';
    return _scope.parties.get(_company, id)?.name ?? id.value;
  }

  /// Plain-text invoice (same template fields, screen preview only — not a
  /// print-fidelity claim; thermal/PDF bytes wait on G5 packages/devices).
  String _invoiceText(
      VoucherWithLines v, AppLocalizations l10n, NiavFormat fmt) {
    final StringBuffer out = StringBuffer();
    out.writeln(_scope.companies.get(_company)?.name ?? _company.value);
    out.writeln(
        '${l10n.invoiceTitle(v.voucher.no)}  ${l10n.t('wordDate')} ${v.voucher.date.iso}');
    final Set<String> customers = <String>{
      for (final VoucherLine l in v.lines) _partyName(l.partyId),
    };
    out.writeln('${l10n.t('vfCustomer')}: ${customers.join(', ')}');
    out.writeln('--------------------------------');
    for (final VoucherLine l in v.lines) {
      if (!_isDocLine(l)) continue;
      out.writeln(
          '${_itemName(l.itemId)} x${QuantityQ4(l.qtyQ4).format()} @ '
          '${fmt.paise(l.ratePaise)} = '
          '${fmt.paise(l.amountPaise)}');
    }
    out.writeln('--------------------------------');
    int gross = 0;
    int net = 0;
    for (final VoucherLine l in v.lines) {
      if (!_isDocLine(l)) continue;
      gross += l.amountPaise;
      net += lineNet(
          l.amountPaise, l.discountAmountPaise, l.discountRateBps);
    }
    out.writeln('${l10n.t('wordGross')}: ${fmt.paise(gross)}');
    out.writeln('${l10n.t('wordNet')}: ${fmt.paise(net)}');
    return out.toString();
  }

  List<VoucherType> _settlementTypes() {
    final String? want = widget.settlementCanonical;
    if (want == null) return <VoucherType>[];
    final List<VoucherType> out = <VoucherType>[];
    for (final VoucherType t in _scope.types.listByCompany(_company)) {
      if (t.baseType == want ||
          t.baseType == voucherBaseSlug(want) ||
          t.name == want) {
        out.add(t);
      }
    }
    return out;
  }

  /// Key/label suffix for the settlement flow ('receipt' or 'payment').
  /// Null when this document is never settled directly.
  String? get _settleSuffix {
    if (widget.settlementCanonical == 'Payment') return 'payment';
    if (widget.settlementCanonical == 'Receipt') return 'receipt';
    return null;
  }

  Future<void> _recordSettlement(VoucherWithLines v) async {
    final String? suffix = _settleSuffix;
    if (suffix == null) return;
    final AppLocalizations l10n = AppLocalizations.of(context);
    final List<VoucherType> settlementTypes = _settlementTypes();
    if (settlementTypes.isEmpty) {
      setState(() =>
          _notice = l10n.noTypeRegistered(widget.settlementCanonical!));
      return;
    }
    int open = 0;
    for (final VoucherLine l in v.lines) {
      if (!_isDocLine(l)) continue;
      open += _scope.outstanding.lineOpen(_company, l.id);
    }
    final TextEditingController amount =
        TextEditingController(text: (open / 100).toString());
    final bool? go = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        final AppLocalizations l10n = AppLocalizations.of(context);
        final NiavFormat fmt = NiavFormat(l10n.localeCode);
        final String suffixWord = suffix == 'payment'
            ? l10n.t('wordPayment')
            : l10n.t('wordReceipt');
        return AlertDialog(
          key: ValueKey<String>('invoice-$suffix-dialog'),
          title: Text(l10n.recordWhat(suffixWord)),
          content: TextField(
            key: ValueKey<String>('invoice-$suffix-amount'),
            controller: amount,
            decoration: InputDecoration(
                labelText: l10n.amountOpen(fmt.paise(open))),
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.t('commonCancel')),
            ),
            TextButton(
              key: ValueKey<String>('invoice-$suffix-post'),
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('${l10n.t('commonPost')} $suffixWord'),
            ),
          ],
        );
      },
    );
    final String raw = amount.text;
    amount.dispose();
    if (go != true || !mounted) return;
    final NiavFormat fmt = NiavFormat(l10n.localeCode);
    final String suffixWord = suffix == 'payment'
        ? l10n.t('wordPayment')
        : l10n.t('wordReceipt');
    final double? rupees = double.tryParse(raw.trim());
    if (rupees == null || rupees <= 0) {
      setState(() => _notice = l10n.needPositive(suffixWord));
      return;
    }
    final int paise = (rupees * 100).round();
    final VoucherType type = settlementTypes.first;
    final List<VoucherSeries> auto = <VoucherSeries>[
      for (final VoucherSeries s
          in _scope.types.seriesForType(_company, type.id))
        if (s.mode == 'auto') s,
    ];
    String seriesName = 'manual';
    String voucherNo =
        '${widget.settlementCanonical == 'Payment' ? 'P' : 'R'}-${DateTime.now().millisecondsSinceEpoch}';
    if (auto.isNotEmpty) {
      final Result<String> gen =
          _scope.numbering.nextNumber(_company, auto.first);
      if (gen.isErr) {
        setState(() => _notice = (gen as Err<String>).error.message);
        return;
      }
      seriesName = auto.first.name;
      voucherNo = (gen as Ok<String>).value;
    }
    final EntityId receiptId = EntityId(_scope.write.idMint('voucher'));
    final EntityId? customer = v.lines.isEmpty ? null : v.lines.first.partyId;
    final Result<Voucher> created = _scope.vouchers.create(
      id: receiptId,
      companyId: _company,
      type: type.name,
      series: seriesName,
      no: voucherNo,
      date: _scope.today,
      narration: '${l10n.t('ivAgainst')} ${v.voucher.no}',
      deviceId: _scope.write.deviceId,
      opId: _scope.write.idMint('op'),
      eventId: _scope.write.idMint('ev'),
      actor: _scope.write.actor,
    );
    if (created.isErr) {
      setState(() => _notice = (created as Err<Voucher>).error.message);
      return;
    }
    final EntityId receiptLine = EntityId(_scope.write.idMint('line'));
    final Result<VoucherLine> added = _scope.vouchers.addLine(
      lineId: receiptLine,
      voucherId: receiptId,
      companyId: _company,
      lineNo: 1,
      partyId: customer,
      qtyQ4: 10000,
      ratePaise: paise,
      deviceId: _scope.write.deviceId,
      opId: _scope.write.idMint('op'),
      eventId: _scope.write.idMint('ev'),
      actor: _scope.write.actor,
    );
    if (added.isErr) {
      setState(() => _notice = (added as Err<VoucherLine>).error.message);
      return;
    }
    // Sequential fill across open lines; remainder stays an advance.
    int left = paise;
    final List<AllocationSpec> specs = <AllocationSpec>[];
    final List<VoucherLine> ordered = <VoucherLine>[...v.lines]
      ..sort((VoucherLine a, VoucherLine b) => a.lineNo.compareTo(b.lineNo));
    for (final VoucherLine l in ordered) {
      if (left <= 0) break;
      // Posting arms never carry allocations (D3-A1: bill economics live in
      // the document lines).
      if (!_isDocLine(l)) continue;
      final int lineOpen =
          _scope.outstanding.lineOpen(_company, l.id);
      if (lineOpen <= 0) continue;
      final int take = left < lineOpen ? left : lineOpen;
      specs.add(AllocationSpec(
        sourceLineId: l.id,
        settlementLineId: receiptLine,
        amountPaise: take,
      ));
      left -= take;
    }
    final Result<PostingResult> posted = _scope.engine.postWithStock(
      id: receiptId,
      companyId: _company,
      policy: StockPolicy.allow,
      allocations: specs,
      deviceId: _scope.write.deviceId,
      opId: _scope.write.idMint('op'),
      eventId: _scope.write.idMint('ev'),
      actor: _scope.write.actor,
    );
    if (posted.isErr) {
      final AppError e = (posted as Err<PostingResult>).error;
      setState(() => _notice = l10n.errorFor(e.code));
      return;
    }
    final PostingResult pr = (posted as Ok<PostingResult>).value;
    setState(() {
      _notice = pr.unallocated.isEmpty
          ? l10n.appliedMsg(suffixWord)
          : l10n.advanceMsg(suffixWord,
              fmt.paise(pr.unallocated.single.remainderPaise));
    });
  }

  /// View model load: voucher + per-line open balances. The open-balance
  /// reads can throw on impossible history (never silently clamped), so
  /// loading runs async with loading/error states like the other reports.
  Future<({VoucherWithLines voucher, int open})> _load(
      AppLocalizations l10n) async {
    await Future<void>.delayed(Duration.zero);
    final VoucherWithLines? current =
        _scope.vouchers.get(_company, widget.voucherId);
    if (current == null) {
      throw StateError(l10n.t('ivNotFound'));
    }
    int open = 0;
    for (final VoucherLine l in current.lines) {
      if (!_isDocLine(l)) continue;
      open += _scope.outstanding.lineOpen(_company, l.id);
    }
    return (voucher: current, open: open);
  }

  Future<void> _refresh() async {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.t('ivInvoice'))),
      body: FutureBuilder<({VoucherWithLines voucher, int open})>(
        future: _load(l10n),
        builder: (
          BuildContext context,
          AsyncSnapshot<({VoucherWithLines voucher, int open})> snap,
        ) {
          final AppLocalizations l10n = AppLocalizations.of(context);
          final NiavFormat fmt = NiavFormat(l10n.localeCode);
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text('${snap.error}'),
                  TextButton(
                    onPressed: _refresh,
                    child: Text(l10n.t('commonRetry')),
                  ),
                ],
              ),
            );
          }
          final VoucherWithLines v = snap.data!.voucher;
          final int open = snap.data!.open;
          return _InvoiceBody(
            voucher: v,
            open: open,
            notice: _notice,
            warnings: widget.postingWarnings,
            settle: _settleSuffix,
            itemName: _itemName,
            invoiceText: _invoiceText(v, l10n, fmt),
            onCopy: () async {
              await Clipboard.setData(
                  ClipboardData(text: _invoiceText(v, l10n, fmt)));
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.t('ivCopied'))),
              );
            },
            onSettle: () => _recordSettlement(v),
          );
        },
      ),
    );
  }
}

/// Loaded invoice content (pure display; loading/error handled above).
class _InvoiceBody extends StatelessWidget {
  const _InvoiceBody({
    required this.voucher,
    required this.open,
    required this.notice,
    required this.warnings,
    required this.settle,
    required this.itemName,
    required this.invoiceText,
    required this.onCopy,
    required this.onSettle,
  });

  final VoucherWithLines voucher;
  final int open;
  final String? notice;
  final List<String> warnings;
  final String? settle;
  final String Function(EntityId? id) itemName;
  final String invoiceText;
  final Future<void> Function() onCopy;
  final void Function() onSettle;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final NiavFormat fmt = NiavFormat(l10n.localeCode);
    final VoucherWithLines v = voucher;
    // Document lines only: engine-posted ledger arms (Dr/Cr) are the ledger
    // books' representation and must not inflate document totals or rows.
    final List<VoucherLine> docLines = <VoucherLine>[
      for (final VoucherLine l in v.lines)
        if (_isDocLine(l)) l,
    ];
    int gross = 0;
    int net = 0;
    for (final VoucherLine l in docLines) {
      gross += l.amountPaise;
      net +=
          lineNet(l.amountPaise, l.discountAmountPaise, l.discountRateBps);
    }
    return Scaffold(
      appBar: AppBar(title: Text(l10n.invoiceTitle(v.voucher.no))),
      body: ListView(
        key: const ValueKey<String>('invoice-view'),
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          if (notice != null)
            Semantics(
              liveRegion: true,
              child: Container(
                key: const ValueKey<String>('invoice-notice'),
                padding: const EdgeInsets.all(8),
                color: Theme.of(context).colorScheme.secondaryContainer,
                child: Text(notice!),
              ),
            ),
          for (final String w in warnings) Text(l10n.noteLine(w)),
          Text(l10n.noDate(v.voucher.no, v.voucher.date.iso)),
          Text(l10n.statusLine(v.voucher.status)),
          if (v.voucher.narration != null)
            Text(l10n.narrationLine(v.voucher.narration!)),
          const Divider(),
          for (int i = 0; i < docLines.length; i++)
            ListTile(
              key: ValueKey<String>('invoice-line-$i'),
              title: Text(itemName(docLines[i].itemId)),
              subtitle: Text(l10n.qtyAtLine(
                  QuantityQ4(docLines[i].qtyQ4).format(),
                  fmt.paise(docLines[i].ratePaise))),
              trailing: Text(fmt.paise(docLines[i].amountPaise)),
            ),
          const Divider(),
          Text(
            l10n.grossNet(fmt.paise(gross), fmt.paise(net)),
            key: const ValueKey<String>('invoice-totals'),
          ),
          Text(
            l10n.openLine(fmt.paise(open)),
            key: const ValueKey<String>('invoice-open'),
          ),
          const Divider(),
          Text(l10n.t('ivPreviewLabel')),
          Container(
            key: const ValueKey<String>('invoice-text'),
            padding: const EdgeInsets.all(8),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Text(invoiceText,
                style: const TextStyle(fontFamily: 'monospace')),
          ),
          Row(
            children: <Widget>[
              TextButton(
                key: const ValueKey<String>('invoice-copy'),
                onPressed: onCopy,
                child: Text(l10n.t('ivCopyText')),
              ),
              const SizedBox(width: 8),
              if (settle != null)
                FilledButton(
                  key: ValueKey<String>('invoice-$settle'),
                  onPressed: onSettle,
                  child: Text(l10n.recordWhat(settle == 'payment'
                      ? l10n.t('wordPayment')
                      : l10n.t('wordReceipt'))),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
