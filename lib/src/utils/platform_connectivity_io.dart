import 'dart:io';

/// Verifica la conectividad a internet usando dart:io (mobile/desktop)
///
/// Realiza un DNS lookup a google.com para verificar si hay conexión.
/// Este archivo se usa automáticamente en plataformas que soportan dart:io.
Future<bool> checkInternetConnection() async {
  try {
    final result = await InternetAddress.lookup('google.com');
    return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
  } on SocketException catch (_) {
    return false;
  }
}

/// Verifica si un error es de tipo SocketException (dart:io)
bool isSocketException(dynamic error) {
  return error is SocketException;
}
