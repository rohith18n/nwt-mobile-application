enum TaxStatus {
  nre('NRE', '21'),
  nro('NRO', '24');

  final String displayName;
  final String taxCode;

  const TaxStatus(this.displayName, this.taxCode);

  /// Get TaxStatus from display name (NRE/NRO)
  static TaxStatus? fromDisplayName(String? name) {
    if (name == null) return null;
    try {
      return TaxStatus.values.firstWhere(
        (status) => status.displayName.toLowerCase() == name.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  /// Get TaxStatus from tax code (21/24)
  static TaxStatus? fromTaxCode(String? code) {
    if (code == null) return null;
    try {
      return TaxStatus.values.firstWhere(
        (status) => status.taxCode == code,
      );
    } catch (e) {
      return null;
    }
  }
}
