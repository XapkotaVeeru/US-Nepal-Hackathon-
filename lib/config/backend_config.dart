class BackendConfig {
  BackendConfig._();

  static const String localHttpBaseUrl = 'http://127.0.0.1:8000';
  static const String defaultApiBaseUrl =
      'https://x0dge4fjri.execute-api.us-east-1.amazonaws.com/prod';

  static String websocketUrlFor(String httpBaseUrl) {
    final uri = Uri.parse(httpBaseUrl);
    final scheme = uri.scheme == 'https' ? 'wss' : 'ws';
    final normalizedPath = uri.path.endsWith('/ws')
        ? uri.path
        : '${uri.path.replaceFirst(RegExp(r'/$'), '')}/ws';

    return uri.replace(scheme: scheme, path: normalizedPath).toString();
  }
}
