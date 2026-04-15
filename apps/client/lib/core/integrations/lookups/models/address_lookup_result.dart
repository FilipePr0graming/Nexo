class AddressLookupResult {
  const AddressLookupResult({
    this.zipCode,
    this.street,
    this.neighborhood,
    this.city,
    this.stateCode,
  });

  final String? zipCode;
  final String? street;
  final String? neighborhood;
  final String? city;
  final String? stateCode;
}
