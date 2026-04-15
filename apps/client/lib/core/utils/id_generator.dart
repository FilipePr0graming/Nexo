import 'dart:math';

class IdGenerator {
  IdGenerator._();

  static final Random _random = Random();

  static String next(String prefix) {
    final timestamp = DateTime.now().toUtc().microsecondsSinceEpoch;
    final randomSuffix =
        _random.nextInt(0xFFFFFF).toRadixString(16).padLeft(6, '0');

    return '$prefix-$timestamp-$randomSuffix';
  }
}
