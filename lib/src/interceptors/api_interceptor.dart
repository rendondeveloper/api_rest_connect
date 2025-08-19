import 'dart:developer';
import 'dart:convert';
import '../models/api_error.dart';

/// Configuración para interceptors de logging
class ApiInterceptor {
  static void logRequest({
    required String method,
    required Uri uri,
    Map<String, String>? headers,
    Object? body,
  }) {
    log('🌐 API REQUEST', name: 'ApiRestConnect');
    log('📤 Method: $method', name: 'ApiRestConnect');
    log('🔗 URL: ${uri.toString()}', name: 'ApiRestConnect');
    
    if (headers != null && headers.isNotEmpty) {
      log('📋 Headers: ${_formatHeaders(headers)}', name: 'ApiRestConnect');
    }
    
    if (body != null) {
      log('📦 Body: ${_formatBody(body)}', name: 'ApiRestConnect');
    }
  }

  static void logResponse({
    required int statusCode,
    required String body,
    required Duration duration,
    Map<String, String>? headers,
  }) {
    log('📥 API RESPONSE', name: 'ApiRestConnect');
    log('📊 Status: $statusCode', name: 'ApiRestConnect');
    log('⏱️ Duration: ${duration.inMilliseconds}ms', name: 'ApiRestConnect');
    
    if (headers != null && headers.isNotEmpty) {
      log('📋 Response Headers: ${_formatHeaders(headers)}', name: 'ApiRestConnect');
    }
    
    log('📦 Response Body: ${_formatResponseBody(body)}', name: 'ApiRestConnect');
  }

  static void logError({
    required String error,
    required String method,
    required Uri uri,
    ApiErrorType? errorType,
  }) {
    log('❌ API ERROR', name: 'ApiRestConnect');
    log('📤 Method: $method', name: 'ApiRestConnect');
    log('🔗 URL: ${uri.toString()}', name: 'ApiRestConnect');
    if (errorType != null) {
      log('🚨 Error Type: $errorType', name: 'ApiRestConnect');
    }
    log('💥 Error: $error', name: 'ApiRestConnect');
  }

  static String _formatHeaders(Map<String, String> headers) {
    return headers.entries
        .map((e) => '${e.key}: ${e.value}')
        .join('\n        ');
  }

  static String _formatBody(Object body) {
    if (body is String) {
      try {
        final json = jsonDecode(body);
        return const JsonEncoder.withIndent('  ').convert(json);
      } catch (_) {
        return body;
      }
    } else if (body is Map) {
      return const JsonEncoder.withIndent('  ').convert(body);
    }
    return body.toString();
  }

  static String _formatResponseBody(String body) {
    try {
      final json = jsonDecode(body);
      return const JsonEncoder.withIndent('  ').convert(json);
    } catch (_) {
      return body;
    }
  }
}
