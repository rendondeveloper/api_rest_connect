/// Configuración para el cliente HTTP
class ApiConfig {
  final String? baseUrl;
  final String? authority;
  final Duration timeout;
  final Map<String, String> defaultHeaders;

  const ApiConfig({
    this.baseUrl,
    this.authority,
    this.timeout = const Duration(minutes: 1),
    this.defaultHeaders = const {
      'Content-Type': 'application/json; charset=UTF-8',
    },
  });

  ApiConfig copyWith({
    String? baseUrl,
    String? authority,
    Duration? timeout,
    Map<String, String>? defaultHeaders,
  }) {
    return ApiConfig(
      baseUrl: baseUrl ?? this.baseUrl,
      authority: authority ?? this.authority,
      timeout: timeout ?? this.timeout,
      defaultHeaders: defaultHeaders ?? this.defaultHeaders,
    );
  }

  @override
  String toString() {
    return 'ApiConfig(baseUrl: $baseUrl, authority: $authority, timeout: $timeout, defaultHeaders: $defaultHeaders)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ApiConfig &&
        other.baseUrl == baseUrl &&
        other.authority == authority &&
        other.timeout == timeout &&
        other.defaultHeaders.toString() == defaultHeaders.toString();
  }

  @override
  int get hashCode {
    return baseUrl.hashCode ^
        authority.hashCode ^
        timeout.hashCode ^
        defaultHeaders.toString().hashCode;
  }
}
