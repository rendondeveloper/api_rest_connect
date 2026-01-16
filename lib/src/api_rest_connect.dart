import 'package:api_rest_connect/api_rest_connect_export.dart';
import 'package:flutter/foundation.dart';
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

  /// Agrega el token a los headers si existe y no está ya presente
  Future<void> _addTokenToHeaders(Map<String, String> headers) async {
    // Solo agregar el token si no existe ya un header Authorization
    if (!headers.containsKey('Authorization')) {
      final token = await TokenUtils.getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
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
    bool retryOnTokenError = true,
  }) async {
    return await _executeGetWithRetry(
      path: path,
      params: params,
      otherAuthority: otherAuthority,
      headers: headers,
      overrideConfig: overrideConfig,
      retryOnTokenError: retryOnTokenError,
    );
  }

  /// Convierte un mapa de parámetros dinámicos a strings para usar en query parameters
  Map<String, String>? _convertParamsToString(Map<String, dynamic>? params) {
    if (params == null) return null;
    return params.map((key, value) {
      if (value == null) {
        return MapEntry(key, '');
      } else if (value is String) {
        return MapEntry(key, value);
      } else if (value is num) {
        return MapEntry(key, value.toString());
      } else if (value is bool) {
        return MapEntry(key, value.toString());
      } else {
        return MapEntry(key, value.toString());
      }
    });
  }

  /// Método interno para ejecutar GET con reintento automático
  Future<dynamic> _executeGetWithRetry({
    required String path,
    Map<String, dynamic>? params,
    String? otherAuthority,
    Map<String, String>? headers,
    ApiConfig? overrideConfig,
    bool retryOnTokenError = true,
  }) async {
    final config = overrideConfig ?? _config;
    final uri = Uri.https(
      otherAuthority ?? currentBaseUrl,
      path,
      _convertParamsToString(params),
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

    // Combinar headers: primero los por defecto, luego los personalizados (tienen prioridad)
    final finalHeaders = <String, String>{};
    finalHeaders.addAll(config.defaultHeaders);
    if (headers != null) {
      finalHeaders.addAll(headers);
    }

    // Agregar token si existe y no está ya presente en los headers
    await _addTokenToHeaders(finalHeaders);

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

        // Si es error de token (401) y no es un reintento, intentar refrescar token
        if (errorType == ApiErrorType.unauthorized &&
            retryOnTokenError &&
            (_config.tokenUrl != null && _config.tokenField != null)) {
          try {
            debugPrint('Token expirado, intentando refrescar...');
            await refreshToken();
            debugPrint(
                'Token refrescado exitosamente, reintentando petición...');

            // Reintentar la petición una vez
            return await _executeGetWithRetry(
              path: path,
              params: params,
              otherAuthority: otherAuthority,
              headers: headers,
              overrideConfig: overrideConfig,
              retryOnTokenError: false,
            );
          } catch (refreshError) {
            debugPrint('Error al refrescar token: $refreshError');
            // Si falla el refresh, lanzar el error original
            ApiInterceptor.logError(
              error: apiError.toString(),
              method: 'GET',
              uri: uri,
              errorType: apiError.type,
            );
            throw apiError;
          }
        }

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

      // Si es error de token (401) y no es un reintento, intentar refrescar token
      if (apiError.type == ApiErrorType.unauthorized &&
          retryOnTokenError &&
          (_config.tokenUrl != null && _config.tokenField != null)) {
        try {
          debugPrint('Token expirado, intentando refrescar...');
          await refreshToken();
          debugPrint('Token refrescado exitosamente, reintentando petición...');

          // Reintentar la petición una vez
          return await _executeGetWithRetry(
            path: path,
            params: params,
            otherAuthority: otherAuthority,
            headers: headers,
            overrideConfig: overrideConfig,
            retryOnTokenError: false,
          );
        } catch (refreshError) {
          debugPrint('Error al refrescar token: $refreshError');
          // Si falla el refresh, lanzar el error original
          ApiInterceptor.logError(
            error: apiError.toString(),
            method: 'GET',
            uri: uri,
            errorType: apiError.type,
          );
          throw apiError;
        }
      }

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
    dynamic body,
    dynamic requestData,
    Map<String, dynamic>? params,
    String? otherAuthority,
    Map<String, String>? headers,
    ApiConfig? overrideConfig,
  }) async {
    final config = overrideConfig ?? _config;
    final uri = Uri.https(
      otherAuthority ?? currentBaseUrl,
      path,
      _convertParamsToString(params),
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

    // Combinar headers
    final finalHeaders = <String, String>{};

    if (headers != null) {
      finalHeaders.addAll(headers);
      debugPrint('Headers custom $headers');
    } else {
      finalHeaders.addAll(config.defaultHeaders);
      debugPrint('Headers default $finalHeaders');
    }

    // Agregar token si existe
    await _addTokenToHeaders(finalHeaders);

    try {
      // Crear request usando http.Request (igual que el código que funciona)
      final request = http.Request('POST', uri);

      // Agregar body al request (igual que el código que funciona)
      if (body != null) {
        if (body is Map<String, dynamic>) {
          request.body = json.encode(body);
        } else if (body is String) {
          request.body = body;
        }
      }

      // Agregar headers (igual que el código que funciona)
      request.headers.addAll(finalHeaders);

      // Log de la petición
      ApiInterceptor.logRequest(
        method: 'POST',
        uri: uri,
        headers: request.headers,
        body: request.body,
      );

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

    // Agregar token si existe
    await _addTokenToHeaders(finalHeaders);

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
      _convertParamsToString(params),
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

    // Agregar token si existe
    await _addTokenToHeaders(finalHeaders);

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

  /// Refresca el token desde el servidor
  ///
  /// [url] - URL completa del endpoint para refrescar el token (opcional, usa tokenUrl de ApiConfig si no se proporciona)
  /// [tokenField] - Campo en la respuesta donde se encuentra el token (opcional, usa tokenField de ApiConfig si no se proporciona)
  /// [body] - Body opcional para la petición POST
  /// [headers] - Headers opcionales para la petición
  ///
  /// Retorna el token actualizado o lanza una excepción si falla
  Future<String> refreshToken({
    String? url,
    String? tokenField,
    dynamic body,
    Map<String, String>? headers,
  }) async {
    try {
      // Usar valores de la configuración si no se proporcionan
      final finalUrl = url ?? _config.tokenUrl;
      final finalTokenField = tokenField ?? _config.tokenField;

      if (finalUrl == null || finalUrl.isEmpty) {
        throw Exception(
            'URL del token no configurada. Proporciona la URL o configúrala en ApiConfig.tokenUrl');
      }

      if (finalTokenField == null || finalTokenField.isEmpty) {
        throw Exception(
            'Campo del token no configurado. Proporciona el campo o configúralo en ApiConfig.tokenField');
      }

      // Parsear la URL
      final uri = Uri.parse(finalUrl);
      final path = uri.path;
      final authority = uri.host;
      final port = uri.port;

      // Construir la URL con puerto si es necesario
      String? otherAuthority;
      if (port != 80 && port != 443) {
        otherAuthority = '$authority:$port';
      } else {
        otherAuthority = authority;
      }

      // Realizar la petición POST para obtener el token
      final response = await executePost(
        path: path,
        params: _config.tokenParams,
        otherAuthority: otherAuthority,
        headers: headers,
      );

      // Extraer el token del campo especificado
      String token;
      if (response is Map<String, dynamic>) {
        // Si el campo tiene puntos, navegar por el objeto
        final fields = finalTokenField.split('.');
        dynamic value = response;

        for (final field in fields) {
          if (value is Map<String, dynamic> && value.containsKey(field)) {
            value = value[field];
          } else {
            throw Exception(
                'Campo "$finalTokenField" no encontrado en la respuesta');
          }
        }

        if (value is String) {
          token = value;
        } else {
          token = value.toString();
        }
      } else {
        throw Exception('La respuesta no es un objeto JSON válido');
      }

      if (token.isEmpty) {
        throw Exception('El token está vacío en el campo "$finalTokenField"');
      }

      // Guardar el token
      await TokenUtils.saveToken(token);

      return token;
    } catch (error) {
      debugPrint('Error al refrescar token: $error');
      rethrow;
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

  /// Método para crear una instancia con configuración de token
  ApiRestConnect withTokenConfig({
    required String tokenUrl,
    required String tokenField,
  }) {
    final newConfig = _config.copyWith(
      tokenUrl: tokenUrl,
      tokenField: tokenField,
    );
    return ApiRestConnect(config: newConfig);
  }
}
