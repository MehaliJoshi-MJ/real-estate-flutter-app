/// Override host/port with:
/// `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000`
String propertyApiBaseUrl() {
  const fromEnv = String.fromEnvironment('API_BASE_URL');
  if (fromEnv.isNotEmpty) return fromEnv.replaceAll(RegExp(r'/$'), '');
  return 'http://localhost:3000';
}
