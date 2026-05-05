abstract final class ProductionDataGuard {
  static final RegExp _blocked = RegExp(
    r'(E2E|CLEANED|CLEANED_RECORD|REGISTRO REMOVIDO|NEXO_[A-Z_]*TEST|SAFE_TEST|\bTEST\b|DEBUG|debug_)',
    caseSensitive: false,
  );

  static bool containsBlockedMarker(String? value) {
    final text = value?.trim() ?? '';
    return text.isNotEmpty && _blocked.hasMatch(text);
  }

  static bool visible(Iterable<String?> values) {
    return !values.any(containsBlockedMarker);
  }

  static String friendlySyncError(String subject) {
    return 'Nao consegui atualizar $subject agora. Tente novamente em alguns segundos.';
  }
}
