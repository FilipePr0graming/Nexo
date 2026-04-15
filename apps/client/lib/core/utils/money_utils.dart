class MoneyUtils {
  const MoneyUtils._();

  static double parseInput(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      return 0;
    }

    final cleaned = trimmed.replaceAll(RegExp(r'[^0-9,.\-]'), '');
    if (cleaned.isEmpty) {
      return 0;
    }

    final normalized = cleaned.contains(',')
        ? cleaned.replaceAll('.', '').replaceAll(',', '.')
        : cleaned;

    return double.tryParse(normalized) ?? 0;
  }

  static String format(num value) {
    final isNegative = value < 0;
    final absolute = value.abs();
    final cents = (absolute * 100).round();
    final integerPart = cents ~/ 100;
    final decimalPart = (cents % 100).toString().padLeft(2, '0');

    return 'R\$ ${isNegative ? '-' : ''}${_group(integerPart)},$decimalPart';
  }

  static String signed(num value) {
    final sign = value < 0 ? '-' : '+';
    return '$sign${format(value.abs()).replaceFirst('R\$ ', '')}';
  }

  static String _group(int value) {
    final digits = value.toString();
    final buffer = StringBuffer();

    for (var index = 0; index < digits.length; index++) {
      final remaining = digits.length - index;
      buffer.write(digits[index]);
      if (remaining > 1 && remaining % 3 == 1) {
        buffer.write('.');
      }
    }

    return buffer.toString();
  }
}
