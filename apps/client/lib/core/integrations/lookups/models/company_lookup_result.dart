class CompanyLookupResult {
  const CompanyLookupResult({
    this.legalName,
    this.tradeName,
    this.phone,
    this.zipCode,
    this.street,
    this.neighborhood,
    this.city,
    this.stateCode,
  });

  final String? legalName;
  final String? tradeName;
  final String? phone;
  final String? zipCode;
  final String? street;
  final String? neighborhood;
  final String? city;
  final String? stateCode;
}
