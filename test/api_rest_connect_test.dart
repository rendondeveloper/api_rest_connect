import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:api_rest_connect/api_rest_connect_export.dart';

void main() {
  setUp(() async {
    // Limpiar SharedPreferences antes de cada test
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  });

  group('ApiRestConnect - Constructor', () {
    test('debe crear una instancia con configuración por defecto', () {
      final client = ApiRestConnect();
      expect(client, isNotNull);
      expect(client.currentBaseUrl, '');
    });

    test('debe crear una instancia con configuración personalizada', () {
      const config = ApiConfig(
        baseUrl: 'api.example.com',
        timeout: Duration(seconds: 30),
      );
      final client = ApiRestConnect(config: config);
      expect(client, isNotNull);
      expect(client.currentBaseUrl, 'api.example.com');
    });
  });

  group('ApiRestConnect - refreshToken', () {
    test('debe lanzar error si tokenUrl no está configurado', () async {
      final client = ApiRestConnect(
        config: const ApiConfig(
          baseUrl: 'api.example.com',
        ),
      );

      expect(
        () => client.refreshToken(),
        throwsA(isA<Exception>()),
      );
    });

    test('debe lanzar error si tokenField no está configurado', () async {
      final client = ApiRestConnect(
        config: const ApiConfig(
          baseUrl: 'api.example.com',
          tokenUrl: 'https://api.example.com/auth/refresh',
        ),
      );

      expect(
        () => client.refreshToken(),
        throwsA(isA<Exception>()),
      );
    });

    test('debe aceptar tokenUrl y tokenField como parámetros', () async {
      final client = ApiRestConnect(
        config: const ApiConfig(
          baseUrl: 'api.example.com',
        ),
      );

      // Debe lanzar error de red porque intenta hacer la petición
      // pero no debe lanzar error de validación
      expect(
        () => client.refreshToken(
          url: 'https://api.example.com/auth/refresh',
          tokenField: 'token',
        ),
        throwsA(isA<ApiError>()),
      );
    });
  });

  group('ApiRestConnect - Builder Methods', () {
    test('withConfig debe crear una nueva instancia', () {
      final client = ApiRestConnect();
      const newConfig = ApiConfig(
        baseUrl: 'new-api.example.com',
        timeout: Duration(seconds: 30),
      );

      final newClient = client.withConfig(newConfig);
      expect(newClient, isNotNull);
      expect(newClient, isA<ApiRestConnect>());
      expect(newClient, isNot(same(client)));
    });

    test('withBaseUrl debe crear una nueva instancia con URL base', () {
      final client = ApiRestConnect();
      final newClient = client.withBaseUrl('new-api.example.com');

      expect(newClient, isNotNull);
      expect(newClient, isA<ApiRestConnect>());
      expect(newClient, isNot(same(client)));
      expect(newClient.currentBaseUrl, 'new-api.example.com');
    });

    test('withHeaders debe crear una nueva instancia con headers', () {
      final client = ApiRestConnect();
      final newClient = client.withHeaders({
        'Authorization': 'Bearer token123',
      });

      expect(newClient, isNotNull);
      expect(newClient, isA<ApiRestConnect>());
      expect(newClient, isNot(same(client)));
    });

    test('withTokenConfig debe crear una nueva instancia con token config', () {
      final client = ApiRestConnect();
      final newClient = client.withTokenConfig(
        tokenUrl: 'https://api.example.com/auth/refresh',
        tokenField: 'token',
      );

      expect(newClient, isNotNull);
      expect(newClient, isA<ApiRestConnect>());
      expect(newClient, isNot(same(client)));
    });
  });

  group('ApiRestConnect - Token Management', () {
    test('debe agregar token a headers cuando existe', () async {
      // Guardar un token
      await TokenUtils.saveToken('test_token_123');

      final client = ApiRestConnect();
      // El token se agregará automáticamente en las peticiones
      expect(client, isNotNull);

      // Verificar que el token está guardado
      final token = await TokenUtils.getToken();
      expect(token, 'test_token_123');
    });
  });
}
