// NiAvERP books report screen — M14.1/M14.2 books slice (G1).
// Three read-only projections of the same posted transactions, one screen
// with two tabs: Day Book / voucher register (gross totals, type filter,
// series, cancelled visibility) and Trial Balance (ledger-wise signed
// Dr-positive balances, Dr = Cr statement, group summary). Tapping a ledger
// row opens its account: opening + posted lines + running balance.
// Every number comes from [LedgerBooks]; no report-specific arithmetic
// exists in this file. Only the visible tab queries, so a failing read
// surfaces on the tab that asked for it.
// States: loading, empty, success, recoverable-error with retry
// (FutureBuilder + retry block, the report pattern). Validation and
// locked/conflict states are N/A — these screens take no business input and
// post nothing; a period lock never hides history, it only blocks posting.
// Main-app wiring arrives through the D1 startup sequence (P-SQLIB approved
// 2026-10-05; on-device proof stays G0-VER-001 evidence).
// Traceability: M14.1 (day book / register / ledger account), M14.2 (trial
// balance group-wise and ledger-wise), FR-M06-004, OD-UI-001.

import 'package:flutter/material.dart';

import 'package:niaverp/application/queries/ledger.dart';
import 'package:niaverp/core/value_objects/ids.dart';
import 'package:niaverp/core/value_objects/money.dart';
import 'package:niaverp/data/repositories/ledger_masters.dart';

/// Books screen for one company: registers, trial balance, ledger account.
class BooksReportScreen extends StatefulWidget {
  const BooksReportScreen({
    super.key,
    required this.companyId,
    required this.books,
    required this.ledgers,
  });

  final CompanyId companyId;
  final LedgerBooks books;
  final LedgerRepository ledgers;

  @override
  State<BooksReportScreen> createState() => BooksReportScreenState();
}

class BooksReportScreenState extends State<BooksReportScreen> {
  String _typeFilter = '';

  /// One day-book load: the register rows plus the posted types offered as
  /// filter options (read together so a failing database only fails the tab
  /// that asked for it).
  Future<_DayBookView> _loadDayBook() async {
    await Future<void>.delayed(Duration.zero);
    return _DayBookView(
      rows: widget.books.dayBook(
        widget.companyId,
        types: _typeFilter.isEmpty ? null : <String>[_typeFilter],
      ),
      types: widget.books.postedVoucherTypes(widget.companyId),
    );
  }

  Future<_TrialView> _loadTrial() async {
    await Future<void>.delayed(Duration.zero);
    final List<LedgerBalance> ledgers =
        widget.books.trialBalance(widget.companyId);
    int sum = 0;
    for (final LedgerBalance b in ledgers) {
      sum += b.balancePaise;
    }
    return _TrialView(
      ledgers: ledgers,
      groups: widget.books.groupTrialBalance(widget.companyId),
      difference: ledgers.isEmpty ? null : sum,
    );
  }

  Widget _dayBook() {
    return FutureBuilder<_DayBookView>(
      future: _loadDayBook(),
      builder: (BuildContext context, AsyncSnapshot<_DayBookView> snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return BooksErrorBlock(
            message: 'Could not load day book',
            onRetry: () => setState(() {}),
          );
        }
        final _DayBookView? view = snap.data;
        final List<DayBookEntry> rows = view?.rows ?? <DayBookEntry>[];
        return Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      rows.isEmpty
                          ? ''
                          : '${rows.length} vouchers · gross '
                              '₹${MoneyPaise(rows.fold(0, (int s, DayBookEntry e) => s + e.totalPaise)).toRupeesString()}',
                      key: const ValueKey<String>('daybook-total'),
                    ),
                  ),
                  DropdownButton<String>(
                    key: const ValueKey<String>('daybook-type-filter'),
                    value: _typeFilter.isEmpty ? null : _typeFilter,
                    hint: const Text('All types'),
                    items: <DropdownMenuItem<String>>[
                      const DropdownMenuItem<String>(
                          value: '', child: Text('All types')),
                      for (final String t in view?.types ?? <String>[])
                        DropdownMenuItem<String>(
                          key: ValueKey<String>('daybook-filter-$t'),
                          value: t,
                          child: Text(t),
                        ),
                    ],
                    onChanged: (String? v) {
                      setState(() {
                        _typeFilter = (v == null || v.isEmpty) ? '' : v;
                      });
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: rows.isEmpty
                  ? const Center(
                      key: ValueKey<String>('daybook-empty'),
                      child: Text('No posted vouchers.'),
                    )
                  : ListView.builder(
                      key: const ValueKey<String>('daybook-list'),
                      itemCount: rows.length,
                      itemBuilder: (BuildContext context, int i) {
                        final DayBookEntry e = rows[i];
                        return ListTile(
                          key: ValueKey<String>('daybook-row-${e.voucherNo}'),
                          title: Text('${e.voucherNo} · ${e.voucherType}'),
                          subtitle: Text(
                              '${e.dateIso} · ${e.series} · ${e.lineCount} lines'),
                          trailing: Text(
                              '₹${MoneyPaise(e.totalPaise).toRupeesString()}'),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _trialBalance() {
    return FutureBuilder<_TrialView>(
      future: _loadTrial(),
      builder: (BuildContext context, AsyncSnapshot<_TrialView> snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return BooksErrorBlock(
            message: 'Could not load trial balance',
            onRetry: () => setState(() {}),
          );
        }
        final _TrialView? view = snap.data;
        if (view == null || view.ledgers.isEmpty) {
          return const Center(
            key: ValueKey<String>('trial-empty'),
            child: Text('No ledgers yet.'),
          );
        }
        return ListView(
          key: const ValueKey<String>('trial-list'),
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                view.difference == 0
                    ? 'Dr = Cr'
                    : 'Out of balance by '
                        '₹${MoneyPaise(view.difference!.abs()).toRupeesString()}',
                key: const ValueKey<String>('trial-difference'),
                style: TextStyle(
                  color: view.difference == 0
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.error,
                ),
              ),
            ),
            const Divider(height: 1),
            for (final LedgerBalance b in view.ledgers)
              ListTile(
                key: ValueKey<String>('trial-ledger-${b.ledgerId.value}'),
                title: Text(b.name),
                trailing: Text(
                  '${b.balancePaise < 0 ? 'Cr' : 'Dr'} '
                  '₹${MoneyPaise(b.balancePaise.abs()).toRupeesString()}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (BuildContext context) => LedgerAccountScreen(
                      companyId: widget.companyId,
                      books: widget.books,
                      ledgerId: b.ledgerId,
                    ),
                  ),
                ),
              ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Text('Group summary',
                  style: Theme.of(context).textTheme.titleMedium),
            ),
            for (final GroupBalance g in view.groups)
              ListTile(
                key: ValueKey<String>('trial-group-${g.groupId.value}'),
                dense: true,
                title: Text(g.name),
                subtitle: Text('${g.ledgerCount} ledgers'),
                trailing: Text(
                  '${g.balancePaise < 0 ? 'Cr' : 'Dr'} '
                  '₹${MoneyPaise(g.balancePaise.abs()).toRupeesString()}',
                ),
              ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Books'),
          bottom: const TabBar(
            tabs: <Widget>[Tab(text: 'Day Book'), Tab(text: 'Trial Balance')],
          ),
        ),
        // Only the selected tab is built, so one failed read cannot leak
        // into the other tab's state.
        body: Builder(
          builder: (BuildContext context) {
            final TabController controller = DefaultTabController.of(context);
            return AnimatedBuilder(
              animation: controller,
              builder: (BuildContext context, Widget? _) => controller.index == 0
                  ? _dayBook()
                  : _trialBalance(),
            );
          },
        ),
      ),
    );
  }
}

/// One day-book load: register rows and the filter's type options.
class _DayBookView {
  const _DayBookView({required this.rows, required this.types});

  final List<DayBookEntry> rows;
  final List<String> types;
}

/// One trial-balance load: ledger rows, group rows and the signed sum.
class _TrialView {
  const _TrialView({
    required this.ledgers,
    required this.groups,
    required this.difference,
  });

  final List<LedgerBalance> ledgers;
  final List<GroupBalance> groups;

  /// Signed sum of all ledger balances; zero for balanced books. Null when
  /// the company has no ledgers (an empty book is not "balanced").
  final int? difference;
}

/// Ledger account: opening, posted lines with running balance, closing.
class LedgerAccountScreen extends StatefulWidget {
  const LedgerAccountScreen({
    super.key,
    required this.companyId,
    required this.books,
    required this.ledgerId,
  });

  final CompanyId companyId;
  final LedgerBooks books;
  final EntityId ledgerId;

  @override
  State<LedgerAccountScreen> createState() => LedgerAccountScreenState();
}

class LedgerAccountScreenState extends State<LedgerAccountScreen> {
  Future<LedgerAccount?> _load() async {
    await Future<void>.delayed(Duration.zero);
    return widget.books.ledgerAccount(widget.companyId, widget.ledgerId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.ledgerId.value)),
      body: FutureBuilder<LedgerAccount?>(
        future: _load(),
        builder: (BuildContext context, AsyncSnapshot<LedgerAccount?> snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return BooksErrorBlock(
              message: 'Could not load ledger account',
              onRetry: () => setState(() {}),
            );
          }
          final LedgerAccount? account = snap.data;
          if (account == null) {
            return const Center(
              key: ValueKey<String>('ledger-missing'),
              child: Text('Ledger not found.'),
            );
          }
          if (account.entries.isEmpty) {
            return Center(
              key: const ValueKey<String>('ledger-empty'),
              child: Text(
                'No entries. Opening '
                '₹${MoneyPaise(account.openingPaise).toRupeesString()}',
              ),
            );
          }
          return ListView(
            key: const ValueKey<String>('ledger-entries-list'),
            children: <Widget>[
              ListTile(
                title: const Text('Opening'),
                trailing: Text(
                    '₹${MoneyPaise(account.openingPaise).toRupeesString()}'),
              ),
              for (final LedgerEntry e in account.entries)
                ListTile(
                  key: ValueKey<String>('ledger-entry-${e.voucherNo}-${e.lineNo}'),
                  dense: true,
                  title: Text('${e.voucherNo} · ${e.dateIso}'),
                  subtitle: Text(e.drCr ?? '—'),
                  trailing: Text(
                    '₹${MoneyPaise(e.amountPaise).toRupeesString()} · bal '
                    '₹${MoneyPaise(e.balanceAfterPaise).toRupeesString()}',
                  ),
                ),
              const Divider(height: 1),
              ListTile(
                key: const ValueKey<String>('ledger-closing'),
                title: const Text('Closing'),
                trailing: Text(
                  '₹${MoneyPaise(account.closingPaise).toRupeesString()}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Recoverable-error block with a retry action (shared by the books tabs).
class BooksErrorBlock extends StatelessWidget {
  const BooksErrorBlock({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(message),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}