class AppConfig {
  const AppConfig._();

  static const String appName = 'Mekelle Fuel Tracker';
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://mk-fuel-monitor.up.railway.app',
  );
  static const Duration requestTimeout = Duration(seconds: 30);
}
