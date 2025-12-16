/// Configuración para el cliente HTTP
class ApiConfig {
  final String? baseUrl;
  final String? authority;
  final Duration timeout;
  final Map<String, String> defaultHeaders;
  final String? tokenUrl;
  final String? tokenField;

  const ApiConfig({
    this.baseUrl,
    this.authority,
    this.timeout = const Duration(minutes: 1),
    this.defaultHeaders = const {
      'Content-Type': 'application/json',
    },
    this.tokenUrl,
    this.tokenField,
  });

  ApiConfig copyWith({
    String? baseUrl,
    String? authority,
    Duration? timeout,
    Map<String, String>? defaultHeaders,
    String? tokenUrl,
    String? tokenField,
  }) {
    return ApiConfig(
      baseUrl: baseUrl ?? this.baseUrl,
      authority: authority ?? this.authority,
      timeout: timeout ?? this.timeout,
      defaultHeaders: defaultHeaders ?? this.defaultHeaders,
      tokenUrl: tokenUrl ?? this.tokenUrl,
      tokenField: tokenField ?? this.tokenField,
    );
  }

  @override
  String toString() {
    return 'ApiConfig(baseUrl: $baseUrl, authority: $authority, timeout: $timeout, defaultHeaders: $defaultHeaders, tokenUrl: $tokenUrl, tokenField: $tokenField)';
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
