import 'package:shared_preferences/shared_preferences.dart';

/// Constante para la clave del token en SharedPreferences
const String tokenKey = 'token';

/// Utilidades para manejar el token
class TokenUtils {
  /// Obtiene el token guardado
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(tokenKey);
  }

  /// Guarda el token
  static Future<bool> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    return await prefs.setString(tokenKey, token);
  }

  /// Elimina el token
  static Future<bool> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    return await prefs.remove(tokenKey);
  }
}
