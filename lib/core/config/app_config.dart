/// Centralized configuration for environment variables
///
/// Values are injected at compile time using --dart-define-from-file
class AppConfig {
  /// Supabase project URL
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');

  /// Supabase anonymous key
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  /// R2 storage endpoint
  static const r2Endpoint = String.fromEnvironment('R2_ENDPOINT');

  /// R2 access key
  static const r2AccessKey = String.fromEnvironment('R2_ACCESS_KEY');

  /// R2 secret key
  static const r2SecretKey = String.fromEnvironment('R2_SECRET_KEY');

  /// R2 bucket name
  static const r2Bucket = String.fromEnvironment('R2_BUCKET');

  /// R2 CDN URL
  static const r2CdnUrl = String.fromEnvironment('R2_CDN_URL');
}
