class DateLabelUtils {
  const DateLabelUtils._();

  static bool isSameDay(DateTime left, DateTime right) {
    return left.year == right.year &&
        left.month == right.month &&
        left.day == right.day;
  }

  static bool isInCurrentMonth(DateTime value, [DateTime? reference]) {
    final base = reference ?? DateTime.now();
    return value.year == base.year && value.month == base.month;
  }

  static String dayLabel(DateTime value, [DateTime? reference]) {
    final base = reference ?? DateTime.now();
    final normalizedBase = DateTime(base.year, base.month, base.day);
    final normalizedValue = DateTime(value.year, value.month, value.day);
    final difference = normalizedBase.difference(normalizedValue).inDays;

    if (difference == 0) {
      return 'Hoje';
    }

    if (difference == 1) {
      return 'Ontem';
    }

    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    return '$day/$month';
  }

  static String movementLabel(DateTime value, [DateTime? reference]) {
    final baseLabel = dayLabel(value, reference);
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$baseLabel, $hour:$minute';
  }
}
