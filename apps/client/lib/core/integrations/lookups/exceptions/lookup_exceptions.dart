class LookupValidationException implements Exception {
  const LookupValidationException(this.message);

  final String message;

  @override
  String toString() {
    return message;
  }
}

class LookupNotFoundException implements Exception {
  const LookupNotFoundException(this.message);

  final String message;

  @override
  String toString() {
    return message;
  }
}

class LookupRequestException implements Exception {
  const LookupRequestException(this.message);

  final String message;

  @override
  String toString() {
    return message;
  }
}
