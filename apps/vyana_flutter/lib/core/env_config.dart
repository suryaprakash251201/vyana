/// Environment configuration for Vyana Flutter app.
/// 
/// Values are injected at build time using --dart-define flags.
/// Example: flutter build --dart-define=SUPABASE_URL=xxx --dart-define=SUPABASE_ANON_KEY=yyy
/// 
/// For development, you can create a `.env` file or use VS Code launch configurations.
class EnvConfig {
  /// Supabase project URL
  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://bqqdjkfgkwugqssvowxi.supabase.co',
  );

  /// Supabase anonymous key (safe for client-side use)
  static const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_yonEFuXyx5D4oJLkoS_ing_BSgQIDtO',
  );

  /// Backend URL for API calls
  static const backendUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: '',
  );

  /// Whether running in debug mode
  static const isDebug = bool.fromEnvironment(
    'DEBUG',
    defaultValue: true,
  );
}
