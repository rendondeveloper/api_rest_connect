import 'package:api_rest_connect/api_rest_connect_export.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

/// Cliente HTTP REST mejorado que retorna directamente los datos de la respuesta
class ApiRestConnect {
  final ApiConfig _config;
  String get currentBaseUrl => _config.baseUrl ?? '';

  ApiRestConnect({ApiConfig? config}) : _config = config ?? const ApiConfig();

  /// Verifica la conectividad a internet
  Future<bool> _checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  /// Procesa el body de la respuesta JSON y retorna directamente los datos
  dynamic _processResponseBody(String bodyResponse) {
    if (bodyResponse.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(bodyResponse);
      if (decoded is Map<String, dynamic> || decoded is List) {
        return decoded;
      } else {
        throw const FormatException('Formato de respuesta no soportado');
      }
    } catch (e) {
      throw Exception('Error al procesar la respuesta JSON: $e');
    }
  }

  /// Maneja errores y crea ApiError correspondiente
  ApiError _handleError(dynamic error, int? statusCode) {
    if (error is http.ClientException) {
      return ApiError(
        type: ApiErrorType.networkError,
        // message: 'Error de conexión de red',
        originalError: error,
      );
    } else if (error is SocketException) {
      return ApiError(
        type: ApiErrorType.noInternet,
        // message: 'Sin conexión a internet',
        originalError: error,
      );
    } else if (error is FormatException) {
      return ApiError(
        type: ApiErrorType.invalidResponse,
        // message: 'Respuesta inválida del servidor',
        originalError: error,
      );
    } else if (statusCode != null) {
      final errorType = ApiError.validateStatusCode(statusCode);
      return ApiError(
        type: errorType,
        // message: ApiError.getErrorMessageByType(errorType),
        statusCode: statusCode,
        originalError: error,
      );
    } else {
      return ApiError(
        type: ApiErrorType.unknown,
        // message: 'Error desconocido',
        originalError: error,
      );
    }
  }

  /// Ejecuta una petición GET
  Future<dynamic> executeGet({
    required String path,
    Map<String, dynamic>? params,
    String? otherAuthority,
    Map<String, String>? headers,
    ApiConfig? overrideConfig,
  }) async {
    final config = overrideConfig ?? _config;
    final uri = Uri.https(
      otherAuthority ?? currentBaseUrl,
      path,
      params,
    );

    final startTime = DateTime.now();

    // Verificar conectividad
    if (!await _checkInternetConnection()) {
      const apiError = ApiError(
        type: ApiErrorType.noInternet,
        // message: 'Sin conexión a internet',
      );

      ApiInterceptor.logError(
        error: apiError.toString(),
        method: 'GET',
        uri: uri,
        errorType: apiError.type,
      );

      throw Exception(apiError.toString());
    }

    // Combinar headers
    final finalHeaders = <String, String>{};
    finalHeaders.addAll(config.defaultHeaders);
    if (headers != null) {
      finalHeaders.addAll(headers);
    }

    // Log de la petición
    ApiInterceptor.logRequest(
      method: 'GET',
      uri: uri,
      headers: finalHeaders,
    );

    try {
      // Crear request usando http.Request
      final request = http.Request('GET', uri);
      request.headers.addAll(finalHeaders);

      // Enviar request con timeout
      final streamedResponse = await request.send().timeout(config.timeout);

      // Convertir StreamedResponse a Response
      final response = await http.Response.fromStream(streamedResponse);

      final duration = DateTime.now().difference(startTime);

      // Log de la respuesta
      ApiInterceptor.logResponse(
        statusCode: response.statusCode,
        body: response.body,
        duration: duration,
        headers: response.headers,
      );

      // Validar status code
      final errorType = ApiError.validateStatusCode(response.statusCode);
      if (errorType != ApiErrorType.unknown) {
        final apiError = ApiError(
          type: errorType,
          // message: ApiError.getErrorMessageByType(errorType),
          statusCode: response.statusCode,
        );

        ApiInterceptor.logError(
          error: apiError.toString(),
          method: 'GET',
          uri: uri,
          errorType: apiError.type,
        );

        throw apiError;
      }

      // Procesar respuesta exitosa y retornar directamente los datos
      return _processResponseBody(response.body);
    } catch (error) {
      final apiError = _handleError(error, null);

      ApiInterceptor.logError(
        error: apiError.toString(),
        method: 'GET',
        uri: uri,
        errorType: apiError.type,
      );

      throw apiError;
    }
  }

  /// Ejecuta una petición POST
  Future<dynamic> executePost({
    required String path,
    Object? body,
    dynamic requestData,
    String? otherAuthority,
    Map<String, String>? headers,
    ApiConfig? overrideConfig,
  }) async {
    final config = overrideConfig ?? _config;
    final uri = Uri.https(
      otherAuthority ?? currentBaseUrl,
      path,
    );

    final startTime = DateTime.now();

    // Verificar conectividad
    if (!await _checkInternetConnection()) {
      const apiError = ApiError(
        type: ApiErrorType.noInternet,
        // message: 'Sin conexión a internet',
      );

      ApiInterceptor.logError(
        error: apiError.toString(),
        method: 'POST',
        uri: uri,
        errorType: apiError.type,
      );

      throw apiError;
    }

    // Preparar el body
    Object? finalBody;
    if (requestData != null) {
      finalBody = requestData.toJson();
    } else if (body != null) {
      finalBody = body;
    }

    // Combinar headers
    final finalHeaders = <String, String>{};
    finalHeaders.addAll(config.defaultHeaders);
    if (headers != null) {
      finalHeaders.addAll(headers);
    }

    // Log de la petición
    ApiInterceptor.logRequest(
      method: 'POST',
      uri: uri,
      headers: finalHeaders,
      body: finalBody,
    );

    try {
      // Crear request usando http.Request
      final request = http.Request('POST', uri);
      request.headers.addAll(finalHeaders);

      // Agregar body al request
      if (finalBody != null) {
        if (finalBody is String) {
          request.body = finalBody;
        } else {
          request.body = json.encode(finalBody);
        }
      }

      // Enviar request con timeout
      final streamedResponse = await request.send().timeout(config.timeout);

      // Convertir StreamedResponse a Response
      final response = await http.Response.fromStream(streamedResponse);

      final duration = DateTime.now().difference(startTime);

      // Log de la respuesta
      ApiInterceptor.logResponse(
        statusCode: response.statusCode,
        body: response.body,
        duration: duration,
        headers: response.headers,
      );

      // Validar status code
      final errorType = ApiError.validateStatusCode(response.statusCode);
      if (errorType != ApiErrorType.unknown) {
        final apiError = ApiError(
          type: errorType,
          // message: ApiError.getErrorMessageByType(errorType),
          statusCode: response.statusCode,
        );

        ApiInterceptor.logError(
          error: apiError.toString(),
          method: 'POST',
          uri: uri,
          errorType: apiError.type,
        );

        throw apiError;
      }

      // Procesar respuesta exitosa y retornar directamente los datos
      return _processResponseBody(response.body);
    } catch (error) {
      final apiError = _handleError(error, null);

      ApiInterceptor.logError(
        error: apiError.toString(),
        method: 'POST',
        uri: uri,
        errorType: apiError.type,
      );

      throw apiError;
    }
  }

  /// Ejecuta una petición PUT
  Future<dynamic> executePut({
    required String path,
    Object? body,
    dynamic requestData,
    String? otherAuthority,
    Map<String, String>? headers,
    ApiConfig? overrideConfig,
  }) async {
    final config = overrideConfig ?? _config;
    final uri = Uri.https(
      otherAuthority ?? currentBaseUrl,
      path,
    );

    final startTime = DateTime.now();

    // Verificar conectividad
    if (!await _checkInternetConnection()) {
      const apiError = ApiError(
        type: ApiErrorType.noInternet,
        // message: 'Sin conexión a internet',
      );

      ApiInterceptor.logError(
        error: apiError.toString(),
        method: 'PUT',
        uri: uri,
        errorType: apiError.type,
      );

      throw apiError;
    }

    // Preparar el body
    Object? finalBody;
    if (requestData != null) {
      finalBody = requestData.toJson();
    } else if (body != null) {
      finalBody = body;
    }

    // Combinar headers
    final finalHeaders = <String, String>{};
    finalHeaders.addAll(config.defaultHeaders);
    if (headers != null) {
      finalHeaders.addAll(headers);
    }

    // Log de la petición
    ApiInterceptor.logRequest(
      method: 'PUT',
      uri: uri,
      headers: finalHeaders,
      body: finalBody,
    );

    try {
      // Crear request usando http.Request
      final request = http.Request('PUT', uri);
      request.headers.addAll(finalHeaders);

      // Agregar body al request
      if (finalBody != null) {
        if (finalBody is String) {
          request.body = finalBody;
        } else {
          request.body = json.encode(finalBody);
        }
      }

      // Enviar request con timeout
      final streamedResponse = await request.send().timeout(config.timeout);

      // Convertir StreamedResponse a Response
      final response = await http.Response.fromStream(streamedResponse);

      final duration = DateTime.now().difference(startTime);

      // Log de la respuesta
      ApiInterceptor.logResponse(
        statusCode: response.statusCode,
        body: response.body,
        duration: duration,
        headers: response.headers,
      );

      // Validar status code
      final errorType = ApiError.validateStatusCode(response.statusCode);
      if (errorType != ApiErrorType.unknown) {
        final apiError = ApiError(
          type: errorType,
          // message: ApiError.getErrorMessageByType(errorType),
          statusCode: response.statusCode,
        );

        ApiInterceptor.logError(
          error: apiError.toString(),
          method: 'PUT',
          uri: uri,
          errorType: apiError.type,
        );

        throw apiError;
      }

      // Procesar respuesta exitosa y retornar directamente los datos
      return _processResponseBody(response.body);
    } catch (error) {
      final apiError = _handleError(error, null);

      ApiInterceptor.logError(
        error: apiError.toString(),
        method: 'PUT',
        uri: uri,
        errorType: apiError.type,
      );

      throw apiError;
    }
  }

  /// Ejecuta una petición DELETE
  Future<dynamic> executeDelete({
    required String path,
    Map<String, dynamic>? params,
    String? otherAuthority,
    Map<String, String>? headers,
    Object? body,
    ApiConfig? overrideConfig,
  }) async {
    final config = overrideConfig ?? _config;
    final uri = Uri.https(
      otherAuthority ?? currentBaseUrl,
      path,
      params,
    );

    final startTime = DateTime.now();

    // Verificar conectividad
    if (!await _checkInternetConnection()) {
      const apiError = ApiError(
        type: ApiErrorType.noInternet,
        // message: 'Sin conexión a internet',
      );

      ApiInterceptor.logError(
        error: apiError.toString(),
        method: 'DELETE',
        uri: uri,
        errorType: apiError.type,
      );

      throw apiError;
    }

    // Combinar headers
    final finalHeaders = <String, String>{};
    finalHeaders.addAll(config.defaultHeaders);
    if (headers != null) {
      finalHeaders.addAll(headers);
    }

    // Log de la petición
    ApiInterceptor.logRequest(
      method: 'DELETE',
      uri: uri,
      headers: finalHeaders,
      body: body,
    );

    try {
      // Crear request usando http.Request
      final request = http.Request('DELETE', uri);
      request.headers.addAll(finalHeaders);

      // Agregar body al request si existe
      if (body != null) {
        if (body is String) {
          request.body = body;
        } else {
          request.body = json.encode(body);
        }
      }

      // Enviar request con timeout
      final streamedResponse = await request.send().timeout(config.timeout);

      // Convertir StreamedResponse a Response
      final response = await http.Response.fromStream(streamedResponse);

      final duration = DateTime.now().difference(startTime);

      // Log de la respuesta
      ApiInterceptor.logResponse(
        statusCode: response.statusCode,
        body: response.body,
        duration: duration,
        headers: response.headers,
      );

      // Validar status code
      final errorType = ApiError.validateStatusCode(response.statusCode);
      if (errorType != ApiErrorType.unknown) {
        final apiError = ApiError(
          type: errorType,
          // message: ApiError.getErrorMessageByType(errorType),
          statusCode: response.statusCode,
        );

        ApiInterceptor.logError(
          error: apiError.toString(),
          method: 'DELETE',
          uri: uri,
          errorType: apiError.type,
        );

        throw apiError;
      }

      // Procesar respuesta exitosa y retornar directamente los datos
      return _processResponseBody(response.body);
    } catch (error) {
      final apiError = _handleError(error, null);

      ApiInterceptor.logError(
        error: apiError.toString(),
        method: 'DELETE',
        uri: uri,
        errorType: apiError.type,
      );

      throw apiError;
    }
  }

  /// Método para crear una instancia con configuración personalizada
  ApiRestConnect withConfig(ApiConfig config) {
    return ApiRestConnect(config: config);
  }

  /// Método para crear una instancia con URL base personalizada
  ApiRestConnect withBaseUrl(String baseUrl) {
    final newConfig = _config.copyWith(baseUrl: baseUrl);
    return ApiRestConnect(config: newConfig);
  }

  /// Método para crear una instancia con headers personalizados
  ApiRestConnect withHeaders(Map<String, String> headers) {
    final newDefaultHeaders = <String, String>{};
    newDefaultHeaders.addAll(_config.defaultHeaders);
    newDefaultHeaders.addAll(headers);

    final newConfig = _config.copyWith(defaultHeaders: newDefaultHeaders);
    return ApiRestConnect(config: newConfig);
  }
}
