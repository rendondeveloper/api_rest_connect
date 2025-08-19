/// Tipos de errores de API
enum ApiErrorType {
  noInternet,
  timeout,
  serverError,
  clientError,
  unauthorized,
  forbidden,
  notFound,
  badRequest,
  invalidResponse,
  networkError,
  unknown,
}

/// Clase para manejar errores de API
class ApiError implements Exception {
  final ApiErrorType type;
  // final String message;
  final int? statusCode;
  final dynamic originalError;

  const ApiError({
    required this.type,
    // required this.message,
    this.statusCode,
    this.originalError,
  });

  @override
  String toString() => 'ApiError(type: $type, statusCode: $statusCode)';

  /// Obtiene mensaje de error basado en el tipo
  // static String getErrorMessageByType(ApiErrorType type) {
  //   switch (type) {
  //     case ApiErrorType.noInternet:
  //       return 'Sin conexión a internet';
  //     case ApiErrorType.timeout:
  //       return 'Tiempo de espera agotado';
  //     case ApiErrorType.serverError:
  //       return 'Error del servidor';
  //     case ApiErrorType.clientError:
  //       return 'Error del cliente';
  //     case ApiErrorType.unauthorized:
  //       return 'No autorizado';
  //     case ApiErrorType.forbidden:
  //       return 'Acceso prohibido';
  //     case ApiErrorType.notFound:
  //       return 'Recurso no encontrado';
  //     case ApiErrorType.badRequest:
  //       return 'Solicitud incorrecta';
  //     case ApiErrorType.invalidResponse:
  //       return 'Respuesta inválida';
  //     case ApiErrorType.networkError:
  //       return 'Error de red';
  //     case ApiErrorType.unknown:
  //       return 'Error desconocido';
  //   }
  // }

  /// Valida el código de estado HTTP y retorna el tipo de error correspondiente
  static ApiErrorType validateStatusCode(int statusCode) {
    if (statusCode >= 200 && statusCode < 300) {
      return ApiErrorType.unknown; // No es un error
    }

    switch (statusCode) {
      case 400:
        return ApiErrorType.badRequest;
      case 401:
        return ApiErrorType.unauthorized;
      case 403:
        return ApiErrorType.forbidden;
      case 404:
        return ApiErrorType.notFound;
      case 408:
        return ApiErrorType.timeout;
      case 500:
      case 502:
      case 503:
      case 504:
        return ApiErrorType.serverError;
      default:
        if (statusCode >= 400 && statusCode < 500) {
          return ApiErrorType.clientError;
        } else if (statusCode >= 500) {
          return ApiErrorType.serverError;
        }
        return ApiErrorType.unknown;
    }
  }
}
