/// Backend configuration for local development.
/// Update these values when deploying a hosted backend later.
class BackendConfig {
  BackendConfig._();

  static const String httpBaseUrl = 'http://127.0.0.1:8000';
  static const String websocketUrl = 'ws://127.0.0.1:8000/ws';
}
