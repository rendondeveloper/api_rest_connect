import 'package:flutter_test/flutter_test.dart';
import 'package:api_rest_connect/api_rest_connect_export.dart';

void main() {
  group('ApiConfig', () {
    test('debe crear una instancia con valores por defecto', () {
      const config = ApiConfig();

      expect(config.baseUrl, isNull);
      expect(config.authority, isNull);
      expect(config.timeout, const Duration(minutes: 1));
      expect(config.defaultHeaders, {'Content-Type': 'application/json'});
      expect(config.tokenUrl, isNull);
      expect(config.tokenField, isNull);
    });

    test('debe crear una instancia con valores personalizados', () {
      const config = ApiConfig(
        baseUrl: 'api.example.com',
        authority: 'example.com',
        timeout: Duration(seconds: 30),
        defaultHeaders: {'Authorization': 'Bearer token'},
        tokenUrl: 'https://api.example.com/auth/refresh',
        tokenField: 'token',
      );

      expect(config.baseUrl, 'api.example.com');
      expect(config.authority, 'example.com');
      expect(config.timeout, const Duration(seconds: 30));
      expect(config.defaultHeaders, {'Authorization': 'Bearer token'});
      expect(config.tokenUrl, 'https://api.example.com/auth/refresh');
      expect(config.tokenField, 'token');
    });

    test('copyWith debe crear una nueva instancia con valores actualizados',
        () {
      const original = ApiConfig(
        baseUrl: 'api.example.com',
        timeout: Duration(minutes: 1),
      );

      final updated = original.copyWith(
        baseUrl: 'api2.example.com',
        tokenUrl: 'https://api2.example.com/auth/refresh',
        tokenField: 'access_token',
      );

      expect(updated.baseUrl, 'api2.example.com');
      expect(updated.timeout,
          const Duration(minutes: 1)); // Mantiene el valor original
      expect(updated.tokenUrl, 'https://api2.example.com/auth/refresh');
      expect(updated.tokenField, 'access_token');
    });

    test('toString debe retornar una representación en string', () {
      const config = ApiConfig(
        baseUrl: 'api.example.com',
        tokenUrl: 'https://api.example.com/auth/refresh',
        tokenField: 'token',
      );

      final str = config.toString();
      expect(str, contains('api.example.com'));
      expect(str, contains('token'));
    });
  });
}
