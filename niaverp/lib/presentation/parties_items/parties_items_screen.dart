// NiAvERP Parties & Items screen — Phase 02 (M03/M12 slice, gate G1).
// Master lists with real-time search over the real repositories: parties by
// name/GSTIN/mobile/alias, items by name/code/barcode/alias. Create + edit
// forms validate inline; persistence failures surface as a SnackBar with a
// retry action. Locked/period states are N/A for masters (period locks gate
// vouchers in the billing slice, prompt 03). No business rules live in
// widgets: role vocabulary, D-M4 arithmetic and duplicate scopes come from
// the repositories. Traceability: REG M03.3/M03.8, M12.3; OD-UI-001.

import 'package:flutter/material.dart';

import 'package:niaverp/application/queries/master_search.dart';
import 'package:niaverp/core/result.dart';
import 'package:niaverp/core/value_objects/ids.dart';
import 'package:niaverp/data/repositories/alias_repository.dart';
import 'package:niaverp/data/repositories/item_repository.dart';
import 'package:niaverp/data/repositories/party_repository.dart';
import 'package:niaverp/presentation/localization/app_localizations.dart';

import '../shared/screen_wiring.dart';

/// Parties & Items master screen for one company.
class PartiesItemsScreen extends StatefulWidget {
  const PartiesItemsScreen({
    super.key,
    required this.companyId,
    required this.parties,
    required this.items,
    required this.aliases,
    required this.search,
    required this.write,
  });

  final CompanyId companyId;
  final PartyRepository parties;
  final ItemRepository items;
  final AliasRepository aliases;
  final MasterSearch search;
  final WriteContext write;

  @override
  State<PartiesItemsScreen> createState() => PartiesItemsScreenState();
}

class PartiesItemsScreenState extends State<PartiesItemsScreen> {
  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.t('piTitle')),
          bottom: TabBar(
            tabs: <Widget>[Tab(text: l10n.t('homeParties')), Tab(text: l10n.t('homeItems'))],
          ),
        ),
        body: TabBarView(
          children: <Widget>[
            _PartyTab(
              companyId: widget.companyId,
              parties: widget.parties,
              aliases: widget.aliases,
              search: widget.search,
              write: widget.write,
            ),
            _ItemTab(
              companyId: widget.companyId,
              items: widget.items,
              aliases: widget.aliases,
              search: widget.search,
              write: widget.write,
            ),
          ],
        ),
      ),
    );
  }
}

void _showFailure(BuildContext context, String code, String message) {
  final AppLocalizations l10n = AppLocalizations.of(context);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(l10n.errorFor(code))),
  );
}

class _PartyTab extends StatefulWidget {
  const _PartyTab({
    required this.companyId,
    required this.parties,
    required this.aliases,
    required this.search,
    required this.write,
  });

  final CompanyId companyId;
  final PartyRepository parties;
  final AliasRepository aliases;
  final MasterSearch search;
  final WriteContext write;

  @override
  State<_PartyTab> createState() => _PartyTabState();
}

class _PartyTabState extends State<_PartyTab> {
  final TextEditingController _query = TextEditingController();
  late List<Party> _shown;
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    _shown = widget.parties.listByCompany(widget.companyId);
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  void _runSearch(String text) {
    setState(() {
      _searching = text.trim().isNotEmpty;
      _shown = _searching
          ? widget.search.searchParties(widget.companyId, text)
          : widget.parties.listByCompany(widget.companyId);
    });
  }

  Future<void> _openForm({Party? existing}) async {
    final bool? saved = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => _PartyFormDialog(
        companyId: widget.companyId,
        parties: widget.parties,
        aliases: widget.aliases,
        write: widget.write,
        existing: existing,
      ),
    );
    if (saved == true && mounted) {
      setState(() {
        _query.clear();
        _searching = false;
        _shown = widget.parties.listByCompany(widget.companyId);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            key: const ValueKey<String>('party-search-field'),
            controller: _query,
            decoration: InputDecoration(
              labelText: l10n.t('piSearchParty'),
              prefixIcon: const Icon(Icons.search),
            ),
            onChanged: _runSearch,
          ),
        ),
        Expanded(
          child: _shown.isEmpty
              ? Center(
                  child: Text(
                    _searching
                        ? l10n.t('piNoMatchParty')
                        : l10n.t('piEmptyParty'),
                  ),
                )
              : ListView.builder(
                  itemCount: _shown.length,
                  itemBuilder: (BuildContext context, int i) {
                    final Party p = _shown[i];
                    return ListTile(
                      title: Text(p.name),
                      subtitle: Text(
                        '${p.role}${p.gstin == null ? '' : ' · ${p.gstin}'}',
                      ),
                      onTap: () => _openForm(existing: p),
                    );
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton.icon(
            key: const ValueKey<String>('party-add-button'),
            onPressed: () => _openForm(),
            icon: const Icon(Icons.add),
            label: Text(l10n.t('piAddParty')),
          ),
        ),
      ],
    );
  }
}

class _PartyFormDialog extends StatefulWidget {
  const _PartyFormDialog({
    required this.companyId,
    required this.parties,
    required this.aliases,
    required this.write,
    this.existing,
  });

  final CompanyId companyId;
  final PartyRepository parties;
  final AliasRepository aliases;
  final WriteContext write;
  final Party? existing;

  @override
  State<_PartyFormDialog> createState() => _PartyFormDialogState();
}

class _PartyFormDialogState extends State<_PartyFormDialog> {
  final GlobalKey<FormState> _form = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _gstin;
  late final TextEditingController _mobile;
  late final TextEditingController _state;
  late final TextEditingController _address;
  late final TextEditingController _terms;
  late final TextEditingController _alias;
  late String _role;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final Party? e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _gstin = TextEditingController(text: e?.gstin ?? '');
    _mobile = TextEditingController(text: e?.mobile ?? '');
    _state = TextEditingController(text: e?.state ?? '');
    _address = TextEditingController(text: e?.address ?? '');
    _terms = TextEditingController(text: e?.terms ?? '');
    _alias = TextEditingController();
    _role = e?.role ?? kPartyRoles.first;
  }

  @override
  void dispose() {
    _name.dispose();
    _gstin.dispose();
    _mobile.dispose();
    _state.dispose();
    _address.dispose();
    _terms.dispose();
    _alias.dispose();
    super.dispose();
  }

  String? _nullIfEmpty(String v) => v.trim().isEmpty ? null : v.trim();

  Future<void> _save() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    final Party? existing = widget.existing;
    final Result<Party> result = existing == null
        ? widget.parties.create(
            id: EntityId(widget.write.idMint('party')),
            companyId: widget.companyId,
            name: _name.text.trim(),
            role: _role,
            gstin: _nullIfEmpty(_gstin.text),
            state: _nullIfEmpty(_state.text),
            mobile: _nullIfEmpty(_mobile.text),
            address: _nullIfEmpty(_address.text),
            terms: _nullIfEmpty(_terms.text),
            deviceId: widget.write.deviceId,
            opId: widget.write.idMint('op'),
            eventId: widget.write.idMint('ev'),
            actor: widget.write.actor,
          )
        : widget.parties.update(
            id: existing.id,
            companyId: widget.companyId,
            name: _name.text.trim(),
            role: _role,
            gstin: _nullIfEmpty(_gstin.text),
            state: _nullIfEmpty(_state.text),
            mobile: _nullIfEmpty(_mobile.text),
            address: _nullIfEmpty(_address.text),
            terms: _nullIfEmpty(_terms.text),
            deviceId: widget.write.deviceId,
            opId: widget.write.idMint('op'),
            eventId: widget.write.idMint('ev'),
            actor: widget.write.actor,
          );
    if (!mounted) return;
    if (result.isErr) {
      final AppError e = (result as Err<Party>).error;
      setState(() => _saving = false);
      _showFailure(context, e.code, e.message);
      return;
    }
    final Party saved = (result as Ok<Party>).value;
    final String aliasText = _alias.text.trim();
    if (aliasText.isNotEmpty) {
      final Result<SearchAlias> ar = widget.aliases.add(
        id: EntityId(widget.write.idMint('alias')),
        companyId: widget.companyId,
        entity: 'party',
        entityId: saved.id,
        alias: aliasText,
        deviceId: widget.write.deviceId,
        opId: widget.write.idMint('op'),
        eventId: widget.write.idMint('ev'),
        actor: widget.write.actor,
      );
      if (!mounted) return;
      if (ar.isErr) {
        final AppError e = (ar as Err<SearchAlias>).error;
        setState(() => _saving = false);
        _showFailure(context, e.code, e.message);
        return;
      }
    }
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final bool editing = widget.existing != null;
    return AlertDialog(
      title: Text(editing ? l10n.t('piEditParty') : l10n.t('piAddParty')),
      content: SingleChildScrollView(
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextFormField(
                key: const ValueKey<String>('party-name-field'),
                controller: _name,
                decoration: InputDecoration(labelText: l10n.t('piNameStar')),
                validator: (String? v) =>
                    (v == null || v.trim().isEmpty) ? l10n.t('piNeedName') : null,
              ),
              DropdownButtonFormField<String>(
                initialValue: _role,
                decoration: InputDecoration(labelText: l10n.t('piRole')),
                items: <DropdownMenuItem<String>>[
                  for (final String r in kPartyRoles)
                    DropdownMenuItem<String>(value: r, child: Text(r)),
                ],
                onChanged: (String? v) {
                  if (v != null) setState(() => _role = v);
                },
              ),
              TextFormField(
                controller: _gstin,
                decoration: InputDecoration(
                  labelText: l10n.t('piGstin'),
                ),
              ),
              TextFormField(
                controller: _mobile,
                decoration: InputDecoration(labelText: l10n.t('piMobile')),
                keyboardType: TextInputType.phone,
              ),
              TextFormField(
                controller: _state,
                decoration: InputDecoration(labelText: l10n.t('piState')),
              ),
              TextFormField(
                controller: _address,
                decoration: InputDecoration(labelText: l10n.t('piAddress')),
              ),
              TextFormField(
                controller: _terms,
                decoration: InputDecoration(labelText: l10n.t('piTerms')),
              ),
              TextFormField(
                key: const ValueKey<String>('party-alias-field'),
                controller: _alias,
                decoration: InputDecoration(
                  labelText: l10n.t('piAlias'),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: Text(l10n.t('commonCancel')),
        ),
        FilledButton(
          key: const ValueKey<String>('party-save-button'),
          onPressed: _saving ? null : _save,
          child: Text(_saving ? l10n.t('commonSaving') : l10n.t('commonSave')),
        ),
      ],
    );
  }
}

class _ItemTab extends StatefulWidget {
  const _ItemTab({
    required this.companyId,
    required this.items,
    required this.aliases,
    required this.search,
    required this.write,
  });

  final CompanyId companyId;
  final ItemRepository items;
  final AliasRepository aliases;
  final MasterSearch search;
  final WriteContext write;

  @override
  State<_ItemTab> createState() => _ItemTabState();
}

class _ItemTabState extends State<_ItemTab> {
  final TextEditingController _query = TextEditingController();
  late List<Item> _shown;
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    _shown = widget.items.listByCompany(widget.companyId);
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  void _runSearch(String text) {
    setState(() {
      _searching = text.trim().isNotEmpty;
      _shown = _searching
          ? widget.search.searchItems(widget.companyId, text)
          : widget.items.listByCompany(widget.companyId);
    });
  }

  Future<void> _openForm({Item? existing}) async {
    final bool? saved = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => _ItemFormDialog(
        companyId: widget.companyId,
        items: widget.items,
        aliases: widget.aliases,
        write: widget.write,
        existing: existing,
      ),
    );
    if (saved == true && mounted) {
      setState(() {
        _query.clear();
        _searching = false;
        _shown = widget.items.listByCompany(widget.companyId);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            key: const ValueKey<String>('item-search-field'),
            controller: _query,
            decoration: InputDecoration(
              labelText: l10n.t('piSearchItem'),
              prefixIcon: const Icon(Icons.search),
            ),
            onChanged: _runSearch,
          ),
        ),
        Expanded(
          child: _shown.isEmpty
              ? Center(
                  child: Text(
                    _searching
                        ? l10n.t('piNoMatchItem')
                        : l10n.t('piEmptyItem'),
                  ),
                )
              : ListView.builder(
                  itemCount: _shown.length,
                  itemBuilder: (BuildContext context, int i) {
                    final Item it = _shown[i];
                    return ListTile(
                      title: Text(it.name),
                      subtitle: Text(
                        '${it.unit}'
                        '${it.code == null ? '' : ' · ${it.code}'}',
                      ),
                      onTap: () => _openForm(existing: it),
                    );
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton.icon(
            key: const ValueKey<String>('item-add-button'),
            onPressed: () => _openForm(),
            icon: const Icon(Icons.add),
            label: Text(l10n.t('piAddItem')),
          ),
        ),
      ],
    );
  }
}

class _ItemFormDialog extends StatefulWidget {
  const _ItemFormDialog({
    required this.companyId,
    required this.items,
    required this.aliases,
    required this.write,
    this.existing,
  });

  final CompanyId companyId;
  final ItemRepository items;
  final AliasRepository aliases;
  final WriteContext write;
  final Item? existing;

  @override
  State<_ItemFormDialog> createState() => _ItemFormDialogState();
}

class _ItemFormDialogState extends State<_ItemFormDialog> {
  final GlobalKey<FormState> _form = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _unit;
  late final TextEditingController _code;
  late final TextEditingController _barcode;
  late final TextEditingController _hsn;
  late final TextEditingController _gstBps;
  late final TextEditingController _alias;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final Item? e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _unit = TextEditingController(text: e?.unit ?? 'pcs');
    _code = TextEditingController(text: e?.code ?? '');
    _barcode = TextEditingController(text: e?.barcode ?? '');
    _hsn = TextEditingController(text: e?.hsnCode ?? '');
    _gstBps =
        TextEditingController(text: e?.gstRateBps == null ? '' : '${e!.gstRateBps}');
    _alias = TextEditingController();
  }

  @override
  void dispose() {
    _name.dispose();
    _unit.dispose();
    _code.dispose();
    _barcode.dispose();
    _hsn.dispose();
    _gstBps.dispose();
    _alias.dispose();
    super.dispose();
  }

  String? _nullIfEmpty(String v) => v.trim().isEmpty ? null : v.trim();

  Future<void> _save() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    final AppLocalizations l10n = AppLocalizations.of(context);
    int? bps;
    if (_gstBps.text.trim().isNotEmpty) {
      bps = int.tryParse(_gstBps.text.trim());
      if (bps == null || bps < 0 || bps > 10000) {
        _showFailure(context, 'validation', l10n.t('piNeedGstBps'));
        return;
      }
    }
    setState(() => _saving = true);
    final Item? existing = widget.existing;
    final Item savedBase;
    if (existing == null) {
      final Result<Item> created = widget.items.create(
        id: EntityId(widget.write.idMint('item')),
        companyId: widget.companyId,
        name: _name.text.trim(),
        unit: _unit.text.trim().isEmpty ? 'pcs' : _unit.text.trim(),
        deviceId: widget.write.deviceId,
        opId: widget.write.idMint('op'),
        eventId: widget.write.idMint('ev'),
        actor: widget.write.actor,
      );
      if (!mounted) return;
      if (created.isErr) {
        final AppError e = (created as Err<Item>).error;
        setState(() => _saving = false);
        _showFailure(context, e.code, e.message);
        return;
      }
      savedBase = (created as Ok<Item>).value;
    } else {
      // Base-row edits (name/unit text) go through rename; master columns
      // follow via updateMaster below.
      final Result<Item> renamed = widget.items.rename(
        companyId: widget.companyId,
        id: existing.id,
        name: _name.text.trim(),
        unit: _unit.text.trim().isEmpty ? 'pcs' : _unit.text.trim(),
        deviceId: widget.write.deviceId,
        opId: widget.write.idMint('op'),
        eventId: widget.write.idMint('ev'),
        actor: widget.write.actor,
      );
      if (!mounted) return;
      if (renamed.isErr) {
        final AppError e = (renamed as Err<Item>).error;
        setState(() => _saving = false);
        _showFailure(context, e.code, e.message);
        return;
      }
      savedBase = (renamed as Ok<Item>).value;
    }
    final bool wantsMaster = _code.text.trim().isNotEmpty ||
        _barcode.text.trim().isNotEmpty ||
        _hsn.text.trim().isNotEmpty ||
        bps != null;
    if (wantsMaster) {
      final Result<Item> m = widget.items.updateMaster(
        companyId: widget.companyId,
        id: savedBase.id,
        code: _nullIfEmpty(_code.text),
        barcode: _nullIfEmpty(_barcode.text),
        hsnCode: _nullIfEmpty(_hsn.text),
        gstRateBps: bps,
        deviceId: widget.write.deviceId,
        opId: widget.write.idMint('op'),
        eventId: widget.write.idMint('ev'),
        actor: widget.write.actor,
      );
      if (!mounted) return;
      if (m.isErr) {
        final AppError e = (m as Err<Item>).error;
        setState(() => _saving = false);
        _showFailure(context, e.code, e.message);
        return;
      }
    }
    final String aliasText = _alias.text.trim();
    if (aliasText.isNotEmpty) {
      final Result<SearchAlias> ar = widget.aliases.add(
        id: EntityId(widget.write.idMint('alias')),
        companyId: widget.companyId,
        entity: 'item',
        entityId: savedBase.id,
        alias: aliasText,
        deviceId: widget.write.deviceId,
        opId: widget.write.idMint('op'),
        eventId: widget.write.idMint('ev'),
        actor: widget.write.actor,
      );
      if (!mounted) return;
      if (ar.isErr) {
        final AppError e = (ar as Err<SearchAlias>).error;
        setState(() => _saving = false);
        _showFailure(context, e.code, e.message);
        return;
      }
    }
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final bool editing = widget.existing != null;
    return AlertDialog(
      title: Text(editing ? l10n.t('piEditItemTitle') : l10n.t('piAddItemTitle')),
      content: SingleChildScrollView(
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextFormField(
                key: const ValueKey<String>('item-name-field'),
                controller: _name,
                decoration: const InputDecoration(labelText: 'Name *'),
                validator: (String? v) =>
                    (v == null || v.trim().isEmpty) ? 'Name is required' : null,
              ),
              TextFormField(
                controller: _unit,
                decoration: const InputDecoration(labelText: 'Unit (text)'),
              ),
              TextFormField(
                controller: _code,
                decoration: const InputDecoration(labelText: 'Code'),
              ),
              TextFormField(
                controller: _barcode,
                decoration: const InputDecoration(labelText: 'Barcode'),
              ),
              TextFormField(
                controller: _hsn,
                decoration: const InputDecoration(
                  labelText: 'HSN/SAC (as printed)',
                ),
              ),
              TextFormField(
                controller: _gstBps,
                decoration: const InputDecoration(
                  labelText: 'GST rate (bps, 0..10000)',
                ),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                key: const ValueKey<String>('item-alias-field'),
                controller: _alias,
                decoration: const InputDecoration(
                  labelText: 'Alias (optional, stored as typed)',
                ),
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: Text(l10n.t('commonCancel')),
        ),
        FilledButton(
          key: const ValueKey<String>('item-save-button'),
          onPressed: _saving ? null : _save,
          child: Text(_saving ? l10n.t('commonSaving') : l10n.t('commonSave')),
        ),
      ],
    );
  }
}
