abstract final class LookupFormatters {
  static String digitsOnly(String value) {
    return value.replaceAll(RegExp(r'\D'), '');
  }

  static String? cleanedValue(dynamic value) {
    if (value == null) {
      return null;
    }

    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static String formatZipCode(String? value) {
    final digits = digitsOnly(value ?? '');
    if (digits.length != 8) {
      return value?.trim() ?? '';
    }

    return '${digits.substring(0, 5)}-${digits.substring(5)}';
  }

  static String formatCnpj(String? value) {
    final digits = digitsOnly(value ?? '');
    if (digits.length != 14) {
      return value?.trim() ?? '';
    }

    return '${digits.substring(0, 2)}.${digits.substring(2, 5)}.${digits.substring(5, 8)}/${digits.substring(8, 12)}-${digits.substring(12)}';
  }

  static String? formatPhone(String? value) {
    final digits = digitsOnly(value ?? '');
    if (digits.isEmpty) {
      return null;
    }

    if (digits.length == 10) {
      return '(${digits.substring(0, 2)}) ${digits.substring(2, 6)}-${digits.substring(6)}';
    }

    if (digits.length == 11) {
      return '(${digits.substring(0, 2)}) ${digits.substring(2, 7)}-${digits.substring(7)}';
    }

    if (digits.length > 11) {
      final ddd = digits.substring(0, 2);
      final phone = digits.substring(2);
      if (phone.length == 8) {
        return '($ddd) ${phone.substring(0, 4)}-${phone.substring(4)}';
      }
      if (phone.length == 9) {
        return '($ddd) ${phone.substring(0, 5)}-${phone.substring(5)}';
      }
    }

    return value?.trim();
  }

  static String composeStreet({
    String? streetType,
    String? streetName,
  }) {
    final pieces = [streetType, streetName]
        .whereType<String>()
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList(growable: false);

    return pieces.join(' ');
  }
}
