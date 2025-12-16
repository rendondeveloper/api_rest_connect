import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:api_rest_connect/api_rest_connect_export.dart';

void main() {
  group('TokenUtils', () {
    setUp(() async {
      // Limpiar SharedPreferences antes de cada test
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    });

    test('getToken debe retornar null cuando no hay token guardado', () async {
      final token = await TokenUtils.getToken();
      expect(token, isNull);
    });

    test('saveToken debe guardar el token correctamente', () async {
      const testToken = 'test_token_123';
      final saved = await TokenUtils.saveToken(testToken);

      expect(saved, isTrue);

      final retrieved = await TokenUtils.getToken();
      expect(retrieved, testToken);
    });

    test('saveToken debe sobrescribir el token anterior', () async {
      const firstToken = 'first_token';
      const secondToken = 'second_token';

      await TokenUtils.saveToken(firstToken);
      await TokenUtils.saveToken(secondToken);

      final retrieved = await TokenUtils.getToken();
      expect(retrieved, secondToken);
    });

    test('removeToken debe eliminar el token guardado', () async {
      const testToken = 'test_token_123';

      await TokenUtils.saveToken(testToken);
      final beforeRemove = await TokenUtils.getToken();
      expect(beforeRemove, testToken);

      final removed = await TokenUtils.removeToken();
      expect(removed, isTrue);

      final afterRemove = await TokenUtils.getToken();
      expect(afterRemove, isNull);
    });

    test('tokenKey debe ser una constante válida', () {
      expect(tokenKey, 'token');
    });
  });
}
