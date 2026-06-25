/// GCP VM backend — saari API calls yahi URL use karti hain (api_service.dart, socket_service.dart)
/// IP badle to yahan update karo aur naya APK build karo.
class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://35.200.216.188:3000',
  );

  static const String wsUrl = String.fromEnvironment(
    'WS_URL',
    defaultValue: 'http://35.200.216.188:3000',
  );
}
