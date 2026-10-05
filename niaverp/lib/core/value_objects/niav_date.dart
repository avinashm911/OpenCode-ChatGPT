// NiAvERP date value object — Phase 00.
// D-M4: dates are ISO TEXT (YYYY-MM-DD); timestamps are epoch-ms UTC.
// This type validates the ISO calendar-date shape only; period/financial-year
// policy lives in later slices. Traceability: D-M4/OD-DB-001.

/// ISO calendar date (YYYY-MM-DD).
class NiavDate {
  NiavDate(this.iso) {
    if (!_isoDate.hasMatch(iso) || DateTime.tryParse(iso) == null) {
      throw ArgumentError.value(iso, 'iso', 'must be YYYY-MM-DD');
    }
  }

  final String iso;

  static final RegExp _isoDate = RegExp(r'^\d{4}-\d{2}-\d{2}$');

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is NiavDate && other.iso == iso);

  @override
  int get hashCode => iso.hashCode;

  @override
  String toString() => 'NiavDate($iso)';
}
