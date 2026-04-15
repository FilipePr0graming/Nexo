class LookupException implements Exception {
  const LookupException(this.message);

  final String message;

  @override
  String toString() => message;
}
