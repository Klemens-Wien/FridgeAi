/// Build-time configuration. Override with `--dart-define`, e.g.
///
/// ```sh
/// flutter run --dart-define=ANTHROPIC_API_KEY=sk-ant-... \
///             --dart-define=ANTHROPIC_BASE_URL=https://my-proxy.example.com
/// ```
class AppConfig {
  const AppConfig._();

  static const appName = 'FridgeChef';

  /// Claude model used for ingredient recognition and recipe generation.
  static const model = String.fromEnvironment(
    'CLAUDE_MODEL',
    defaultValue: 'claude-opus-5-5',
  );

  /// Optional key baked in at build time (development only — anything shipped
  /// inside an app binary can be extracted). Users can also enter their own
  /// key in Settings, which is kept in the platform's secure storage.
  static const apiKeyFromEnvironment = String.fromEnvironment(
    'ANTHROPIC_API_KEY',
  );

  /// Point this at your own backend proxy in production so the API key never
  /// leaves your server.
  static const baseUrl = String.fromEnvironment(
    'ANTHROPIC_BASE_URL',
    defaultValue: 'https://api.anthropic.com',
  );

  static const maxPhotos = 6;
  static const recipesPerRequest = 6;

  /// Long edge in pixels photos are downscaled to before upload. Larger images
  /// are downscaled by the API anyway, so this only saves bandwidth.
  static const maxImageDimension = 1568.0;
}
