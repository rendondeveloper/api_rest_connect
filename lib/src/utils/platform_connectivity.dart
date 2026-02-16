/// Abstracción de conectividad multiplataforma
///
/// Usa imports condicionales para seleccionar automáticamente la implementación:
/// - En app (mobile/desktop): usa dart:io con InternetAddress.lookup
/// - En web: asume conectividad y deja que HTTP falle naturalmente
///
/// Por defecto usa la implementación IO (app). Solo cambia a web cuando
/// detecta que dart.library.html está disponible (entorno de navegador).
export 'platform_connectivity_io.dart'
    if (dart.library.html) 'platform_connectivity_web.dart';
