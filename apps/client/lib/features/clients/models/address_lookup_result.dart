class AddressLookupResult {
  const AddressLookupResult({
    required this.zipCode,
    required this.street,
    required this.neighborhood,
    required this.city,
    required this.stateCode,
  });

  final String zipCode;
  final String street;
  final String neighborhood;
  final String city;
  final String stateCode;
}
