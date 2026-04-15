class CompanyLookupResult {
  const CompanyLookupResult({
    required this.cnpj,
    required this.legalName,
    required this.tradeName,
    required this.zipCode,
    required this.street,
    required this.neighborhood,
    required this.city,
    required this.stateCode,
    this.phone,
  });

  final String cnpj;
  final String legalName;
  final String tradeName;
  final String zipCode;
  final String street;
  final String neighborhood;
  final String city;
  final String stateCode;
  final String? phone;
}
