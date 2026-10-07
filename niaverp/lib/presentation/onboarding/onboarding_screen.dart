// NiAvERP onboarding screen — Phase 02 (M01 slice, gate G1).
// Company setup over the real [CompanyRepository]: create-first-company
// form plus existing-company list. States: loading (list fetch), empty
// (no companies yet), validation-error (inline), creating (progress),
// recoverable-error (message + retry). Opens the selected company via
// [onOpen]; company switching UI lands with M01 completion (prompt 02A).
// Traceability: REG M01; DSS-C-001; OD-UI-001.

import 'package:flutter/material.dart';

import 'package:niaverp/core/result.dart';
import 'package:niaverp/core/value_objects/ids.dart';
import 'package:niaverp/data/repositories/company_repository.dart';
import 'package:niaverp/presentation/localization/app_localizations.dart';

import '../shared/screen_wiring.dart';

/// Company setup entry screen.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    super.key,
    required this.companies,
    required this.write,
    required this.onOpen,
  });

  final CompanyRepository companies;
  final WriteContext write;
  final ValueChanged<CompanyId> onOpen;

  @override
  State<OnboardingScreen> createState() => OnboardingScreenState();
}

class OnboardingScreenState extends State<OnboardingScreen> {
  final TextEditingController _name = TextEditingController();
  late Future<List<Company>> _existing;
  bool _creating = false;
  String? _formError;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    _existing = _load();
  }

  Future<List<Company>> _load() async {
    // Repository reads are synchronous; the Future keeps loading/empty/error
    // as real widget states instead of resolving inline.
    if (!mounted) return <Company>[];
    // listByCompany needs a scope; onboarding lists across the single local
    // store via a direct scope-free read below (see _allCompanies).
    return _allCompanies();
  }

  List<Company> _allCompanies() {
    // v1 store holds companies without a parent scope; read straight rows.
    final List<Map<String, Object?>> rows =
        widget.companies.ctx.db.queryArgs(
      'SELECT company_id, name, state_code, created_at FROM company ORDER BY name',
      <Object?>[],
    );
    return <Company>[
      for (final Map<String, Object?> r in rows) Company.fromRow(r),
    ];
  }

  Future<void> _refresh() async {
    setState(() {
      _existing = _load();
    });
    await _existing;
    if (!mounted) return;
  }

  Future<void> _create() async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final String name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _formError = l10n.t('obNeedName'));
      return;
    }
    setState(() {
      _formError = null;
      _saveError = null;
      _creating = true;
    });
    final CompanyId id = CompanyId(widget.write.idMint('company'));
    final Result<Company> result = widget.companies.create(
      id: id,
      name: name,
      deviceId: widget.write.deviceId,
      opId: widget.write.idMint('op'),
      eventId: widget.write.idMint('ev'),
      actor: widget.write.actor,
    );
    if (!mounted) return;
    setState(() => _creating = false);
    if (result.isOk) {
      _name.clear();
      await _refresh();
      if (!mounted) return;
      widget.onOpen(id);
    } else {
      // Failure messages carry codes only (repository contract).
      final AppError e = (result as Err<Company>).error;
      setState(() => _saveError = l10n.errorFor(e.code));
    }
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.t('obSetupTitle'))),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TextField(
              key: const ValueKey<String>('company-name-field'),
              controller: _name,
              decoration: InputDecoration(
                labelText: l10n.t('obCompanyName'),
                errorText: _formError,
              ),
              enabled: !_creating,
            ),
            const SizedBox(height: 12),
            if (_saveError != null)
              _ErrorBlock(
                message: _saveError!,
                onRetry: _create,
              ),
            FilledButton(
              key: const ValueKey<String>('company-create-button'),
              onPressed: _creating ? null : _create,
              child: _creating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.t('obCreateCompany')),
            ),
            const SizedBox(height: 24),
            Text(l10n.t('obExisting')),
            const SizedBox(height: 8),
            Expanded(
              child: FutureBuilder<List<Company>>(
                future: _existing,
                builder: (
                  BuildContext context,
                  AsyncSnapshot<List<Company>> snap,
                ) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snap.hasError) {
                    return _ErrorBlock(
                      message: l10n.t('errLoadCompanies'),
                      onRetry: _refresh,
                    );
                  }
                  final List<Company> list = snap.data ?? <Company>[];
                  if (list.isEmpty) {
                    return Center(
                      child: Text(l10n.t('obEmpty')),
                    );
                  }
                  return ListView.builder(
                    itemCount: list.length,
                    itemBuilder: (BuildContext context, int i) {
                      final Company c = list[i];
                      return ListTile(
                        title: Text(c.name),
                        onTap: () => widget.onOpen(c.id),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Recoverable-error block with a retry action.
class _ErrorBlock extends StatelessWidget {
  const _ErrorBlock({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: <Widget>[
          Expanded(child: Text(message)),
          TextButton(onPressed: () => onRetry(), child: Text(l10n.t('commonRetry'))),
        ],
      ),
    );
  }
}
