/// Verifica la conectividad a internet en plataforma web
///
/// En web no se puede usar dart:io (InternetAddress.lookup).
/// Se asume conectividad disponible y se deja que las peticiones HTTP
/// fallen naturalmente si no hay conexión (el navegador maneja esto).
Future<bool> checkInternetConnection() async {
  return true;
}

/// Verifica si un error es de tipo SocketException
///
/// En web, SocketException no existe, por lo que siempre retorna false.
bool isSocketException(dynamic error) {
  return false;
}
