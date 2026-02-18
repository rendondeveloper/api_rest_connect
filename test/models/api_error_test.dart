import 'package:flutter_test/flutter_test.dart';
import 'package:api_rest_connect/api_rest_connect_export.dart';

void main() {
  group('ApiError', () {
    test('debe crear una instancia con tipo y statusCode', () {
      const error = ApiError(
        type: ApiErrorType.unauthorized,
        statusCode: 401,
      );

      expect(error.type, ApiErrorType.unauthorized);
      expect(error.statusCode, 401);
    });

    test('toString debe retornar una representación en string', () {
      const error = ApiError(
        type: ApiErrorType.unauthorized,
        statusCode: 401,
      );

      final str = error.toString();
      expect(str, contains('unauthorized'));
      expect(str, contains('401'));
    });

    group('validateStatusCode', () {
      test('debe retornar success para códigos 2xx sin método', () {
        expect(ApiError.validateStatusCode(200), ApiErrorType.success);
        expect(ApiError.validateStatusCode(201), ApiErrorType.success);
        expect(ApiError.validateStatusCode(204), ApiErrorType.success);
      });

      test('debe retornar success para GET con 200', () {
        expect(
          ApiError.validateStatusCode(200, method: 'GET'),
          ApiErrorType.success,
        );
      });

      test('debe retornar success para POST con 200 y 201', () {
        expect(
          ApiError.validateStatusCode(200, method: 'POST'),
          ApiErrorType.success,
        );
        expect(
          ApiError.validateStatusCode(201, method: 'POST'),
          ApiErrorType.success,
        );
      });

      test('debe retornar success para PUT con 200', () {
        expect(
          ApiError.validateStatusCode(200, method: 'PUT'),
          ApiErrorType.success,
        );
      });

      test('debe retornar success para DELETE con 200 y 204', () {
        expect(
          ApiError.validateStatusCode(200, method: 'DELETE'),
          ApiErrorType.success,
        );
        expect(
          ApiError.validateStatusCode(204, method: 'DELETE'),
          ApiErrorType.success,
        );
      });

      test('POST con 204 no debe ser success', () {
        expect(
          ApiError.validateStatusCode(204, method: 'POST'),
          isNot(ApiErrorType.success),
        );
      });

      test('debe retornar badRequest para 400', () {
        expect(ApiError.validateStatusCode(400), ApiErrorType.badRequest);
      });

      test('debe retornar unauthorized para 401', () {
        expect(ApiError.validateStatusCode(401), ApiErrorType.unauthorized);
      });

      test('debe retornar forbidden para 403', () {
        expect(ApiError.validateStatusCode(403), ApiErrorType.forbidden);
      });

      test('debe retornar notFound para 404', () {
        expect(ApiError.validateStatusCode(404), ApiErrorType.notFound);
      });

      test('debe retornar timeout para 408', () {
        expect(ApiError.validateStatusCode(408), ApiErrorType.timeout);
      });

      test('debe retornar serverError para 500, 502, 503, 504', () {
        expect(ApiError.validateStatusCode(500), ApiErrorType.serverError);
        expect(ApiError.validateStatusCode(502), ApiErrorType.serverError);
        expect(ApiError.validateStatusCode(503), ApiErrorType.serverError);
        expect(ApiError.validateStatusCode(504), ApiErrorType.serverError);
      });

      test('debe retornar clientError para otros códigos 4xx', () {
        expect(ApiError.validateStatusCode(402), ApiErrorType.clientError);
        expect(ApiError.validateStatusCode(405), ApiErrorType.clientError);
        expect(ApiError.validateStatusCode(422), ApiErrorType.clientError);
      });

      test('debe retornar serverError para otros códigos 5xx', () {
        expect(ApiError.validateStatusCode(501), ApiErrorType.serverError);
        expect(ApiError.validateStatusCode(505), ApiErrorType.serverError);
      });
    });
  });
}
