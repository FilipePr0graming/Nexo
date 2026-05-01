class AppEnvironment {
  const AppEnvironment._();

  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY');
  static const String supabasePublishableKey =
      String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

  static String get supabaseClientKey {
    final anonKey = supabaseAnonKey.trim();
    if (anonKey.isNotEmpty) {
      return anonKey;
    }

    return supabasePublishableKey.trim();
  }

  static bool get hasSupabase =>
      supabaseUrl.trim().isNotEmpty && supabaseClientKey.isNotEmpty;
}
