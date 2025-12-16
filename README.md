# API REST Connect

Un cliente HTTP REST robusto para Flutter con manejo avanzado de errores, logging, gestión automática de tokens y capacidades de reintento automático.

## Características

- ✅ **Métodos HTTP completos**: GET, POST, PUT, DELETE
- ✅ **Gestión automática de tokens**: Agrega tokens automáticamente a las peticiones
- ✅ **Refresh automático de tokens**: Refresca tokens expirados y reintenta peticiones
- ✅ **Manejo de errores robusto**: Tipos de error específicos y mensajes claros
- ✅ **Logging detallado**: Interceptores para request, response y errores
- ✅ **Configuración flexible**: Headers personalizados, timeouts, URLs base
- ✅ **Persistencia de tokens**: Almacenamiento seguro con SharedPreferences
- ✅ **Validación de conectividad**: Verifica conexión a internet antes de peticiones
- ✅ **Reintento automático**: Reintenta peticiones cuando el token expira (401)

## Instalación

Agrega la dependencia a tu `pubspec.yaml`:

```yaml
dependencies:
  api_rest_connect:
    git:
      url: https://github.com/tu-usuario/api_rest_connect.git
      # o si está en pub.dev:
      # version: ^1.0.0
```

Luego ejecuta:

```bash
flutter pub get
```

## Configuración Inicial

### Configuración Básica

```dart
import 'package:api_rest_connect/api_rest_connect_export.dart';

// Crear instancia con configuración básica
final client = ApiRestConnect(
  config: ApiConfig(
    baseUrl: 'api.example.com',
    timeout: Duration(seconds: 30),
  ),
);
```

### Configuración con Token

```dart
final client = ApiRestConnect(
  config: ApiConfig(
    baseUrl: 'api.example.com',
    tokenUrl: 'https://api.example.com/auth/refresh',
    tokenField: 'token', // Campo donde está el token en la respuesta
    timeout: Duration(seconds: 30),
    defaultHeaders: {
      'Content-Type': 'application/json',
    },
  ),
);
```

## Uso

### Métodos HTTP

#### GET - Obtener datos

```dart
try {
  // GET simple
  final data = await client.executeGet(
    path: '/api/users',
  );

  // GET con parámetros de consulta
  final users = await client.executeGet(
    path: '/api/users',
    params: {
      'page': 1,
      'limit': 10,
      'status': 'active',
    },
  );

  // GET con headers personalizados
  final response = await client.executeGet(
    path: '/api/users',
    headers: {
      'X-Custom-Header': 'value',
    },
  );

  // GET con otra autoridad (dominio diferente)
  final externalData = await client.executeGet(
    path: '/api/data',
    otherAuthority: 'external-api.com',
  );

  print(data); // Los datos ya están parseados como Map o List
} on ApiError catch (e) {
  print('Error: ${e.type}, Status: ${e.statusCode}');
}
```

#### POST - Crear o enviar datos

```dart
try {
  // POST con body como Map
  final response = await client.executePost(
    path: '/api/users',
    body: {
      'name': 'Juan Pérez',
      'email': 'juan@example.com',
      'age': 30,
    },
  );

  // POST con headers personalizados
  final result = await client.executePost(
    path: '/api/notifications',
    body: {
      'OPC': '1',
      'TNOTIF': '4',
      'TITLE': 'Notificación',
      'MSJ': 'Mensaje de prueba',
    },
    headers: {
      'Content-Type': 'application/json',
      'Cookie': 'PHPSESSID=abc123',
    },
  );

  // POST con otra autoridad
  final externalResponse = await client.executePost(
    path: '/api/data',
    body: {'key': 'value'},
    otherAuthority: 'external-api.com',
  );

  print(response); // Datos parseados
} on ApiError catch (e) {
  print('Error: ${e.type}');
}
```

#### PUT - Actualizar datos

```dart
try {
  final updated = await client.executePut(
    path: '/api/users/123',
    body: {
      'name': 'Juan Pérez Actualizado',
      'email': 'juan.nuevo@example.com',
    },
  );

  print(updated);
} on ApiError catch (e) {
  print('Error: ${e.type}');
}
```

#### DELETE - Eliminar datos

```dart
try {
  // DELETE simple
  await client.executeDelete(
    path: '/api/users/123',
  );

  // DELETE con parámetros
  await client.executeDelete(
    path: '/api/users',
    params: {'id': 123},
  );

  // DELETE con body
  await client.executeDelete(
    path: '/api/bulk',
    body: {'ids': [1, 2, 3]},
  );
} on ApiError catch (e) {
  print('Error: ${e.type}');
}
```

### Gestión de Tokens

#### Guardar Token Manualmente

```dart
import 'package:api_rest_connect/api_rest_connect_export.dart';

// Guardar token
await TokenUtils.saveToken('mi_token_aqui');

// Obtener token
final token = await TokenUtils.getToken();

// Eliminar token
await TokenUtils.removeToken();
```

#### Refresh Automático de Token

```dart
// Si configuraste tokenUrl y tokenField en ApiConfig
final client = ApiRestConnect(
  config: ApiConfig(
    baseUrl: 'api.example.com',
    tokenUrl: 'https://api.example.com/auth/refresh',
    tokenField: 'token',
  ),
);

// Refresh automático usando la configuración
try {
  final newToken = await client.refreshToken(
    body: {
      'refresh_token': 'refresh_token_value',
    },
  );
  print('Nuevo token: $newToken');
} catch (e) {
  print('Error al refrescar token: $e');
}

// O especificar URL y campo manualmente
final token = await client.refreshToken(
  url: 'https://api.example.com/auth/refresh',
  tokenField: 'access_token', // Campo anidado: 'data.token'
  body: {'refresh_token': 'xxx'},
);
```

#### Token Automático en Peticiones

El token se agrega automáticamente a todas las peticiones si está guardado:

```dart
// Guardar token
await TokenUtils.saveToken('mi_token');

// El token se agregará automáticamente como:
// Authorization: Bearer mi_token
final data = await client.executeGet(
  path: '/api/protected-data',
);
```

#### Reintento Automático con Token Expirado

Cuando una petición GET recibe un error 401 (Unauthorized), el cliente automáticamente:

1. Detecta el error de token
2. Llama a `refreshToken()` si está configurado
3. Reintenta la petición original con el nuevo token

```dart
final client = ApiRestConnect(
  config: ApiConfig(
    baseUrl: 'api.example.com',
    tokenUrl: 'https://api.example.com/auth/refresh',
    tokenField: 'token',
  ),
);

// Si el token expira, se refrescará automáticamente
try {
  final data = await client.executeGet(
    path: '/api/protected-data',
    retryOnTokenError: true, // Por defecto es true
  );
} on ApiError catch (e) {
  // Solo se lanza error si el refresh también falla
  print('Error: ${e.type}');
}
```

### Métodos Builder

#### withConfig - Nueva instancia con configuración

```dart
final client = ApiRestConnect();

final newClient = client.withConfig(
  ApiConfig(
    baseUrl: 'new-api.example.com',
    timeout: Duration(seconds: 60),
  ),
);
```

#### withBaseUrl - Nueva instancia con URL base

```dart
final client = ApiRestConnect();

final newClient = client.withBaseUrl('new-api.example.com');
```

#### withHeaders - Nueva instancia con headers

```dart
final client = ApiRestConnect();

final newClient = client.withHeaders({
  'Authorization': 'Bearer token123',
  'X-Custom-Header': 'value',
});
```

#### withTokenConfig - Nueva instancia con configuración de token

```dart
final client = ApiRestConnect();

final newClient = client.withTokenConfig(
  tokenUrl: 'https://api.example.com/auth/refresh',
  tokenField: 'token',
);
```

### Manejo de Errores

```dart
try {
  final data = await client.executeGet(path: '/api/data');
} on ApiError catch (e) {
  switch (e.type) {
    case ApiErrorType.noInternet:
      print('Sin conexión a internet');
      break;
    case ApiErrorType.unauthorized:
      print('No autorizado - Token inválido');
      break;
    case ApiErrorType.forbidden:
      print('Acceso prohibido');
      break;
    case ApiErrorType.notFound:
      print('Recurso no encontrado');
      break;
    case ApiErrorType.timeout:
      print('Tiempo de espera agotado');
      break;
    case ApiErrorType.serverError:
      print('Error del servidor');
      break;
    case ApiErrorType.badRequest:
      print('Solicitud incorrecta');
      break;
    case ApiErrorType.networkError:
      print('Error de red');
      break;
    default:
      print('Error desconocido: ${e.type}');
  }

  print('Status Code: ${e.statusCode}');
  print('Error original: ${e.originalError}');
}
```

### Tipos de Error

- `ApiErrorType.noInternet` - Sin conexión a internet
- `ApiErrorType.timeout` - Tiempo de espera agotado
- `ApiErrorType.serverError` - Error del servidor (5xx)
- `ApiErrorType.clientError` - Error del cliente (4xx)
- `ApiErrorType.unauthorized` - No autorizado (401)
- `ApiErrorType.forbidden` - Prohibido (403)
- `ApiErrorType.notFound` - No encontrado (404)
- `ApiErrorType.badRequest` - Solicitud incorrecta (400)
- `ApiErrorType.invalidResponse` - Respuesta inválida
- `ApiErrorType.networkError` - Error de red
- `ApiErrorType.unknown` - Error desconocido

## Ejemplos Completos

### Ejemplo 1: Cliente Simple

```dart
import 'package:api_rest_connect/api_rest_connect_export.dart';

void main() async {
  final client = ApiRestConnect(
    config: ApiConfig(
      baseUrl: 'jsonplaceholder.typicode.com',
    ),
  );

  try {
    // Obtener usuarios
    final users = await client.executeGet(
      path: '/users',
    );
    print('Usuarios: $users');

    // Crear usuario
    final newUser = await client.executePost(
      path: '/users',
      body: {
        'name': 'John Doe',
        'email': 'john@example.com',
      },
    );
    print('Usuario creado: $newUser');
  } catch (e) {
    print('Error: $e');
  }
}
```

### Ejemplo 2: Cliente con Autenticación

```dart
import 'package:api_rest_connect/api_rest_connect_export.dart';

void main() async {
  // Configurar cliente con token
  final client = ApiRestConnect(
    config: ApiConfig(
      baseUrl: 'api.example.com',
      tokenUrl: 'https://api.example.com/auth/refresh',
      tokenField: 'token',
    ),
  );

  // Login y guardar token
  try {
    final loginResponse = await client.executePost(
      path: '/auth/login',
      body: {
        'email': 'user@example.com',
        'password': 'password123',
      },
    );

    // Guardar token manualmente
    if (loginResponse is Map && loginResponse.containsKey('token')) {
      await TokenUtils.saveToken(loginResponse['token']);
    }
  } catch (e) {
    print('Error en login: $e');
    return;
  }

  // Usar API protegida (token se agrega automáticamente)
  try {
    final profile = await client.executeGet(
      path: '/api/profile',
    );
    print('Perfil: $profile');
  } on ApiError catch (e) {
    if (e.type == ApiErrorType.unauthorized) {
      // Token expirado, refrescar
      try {
        await client.refreshToken();
        // Reintentar
        final profile = await client.executeGet(
          path: '/api/profile',
        );
        print('Perfil: $profile');
      } catch (refreshError) {
        print('Error al refrescar token: $refreshError');
      }
    }
  }
}
```

### Ejemplo 3: Cliente con Headers Personalizados

```dart
final client = ApiRestConnect(
  config: ApiConfig(
    baseUrl: 'api.example.com',
    defaultHeaders: {
      'Content-Type': 'application/json',
      'X-API-Key': 'mi-api-key',
    },
  ),
);

// Headers personalizados por petición
final data = await client.executeGet(
  path: '/api/data',
  headers: {
    'X-Custom-Header': 'valor-personalizado',
  },
);
```

## API Reference

### ApiRestConnect

#### Constructor

```dart
ApiRestConnect({ApiConfig? config})
```

#### Métodos

- `Future<dynamic> executeGet({...})` - Ejecuta petición GET
- `Future<dynamic> executePost({...})` - Ejecuta petición POST
- `Future<dynamic> executePut({...})` - Ejecuta petición PUT
- `Future<dynamic> executeDelete({...})` - Ejecuta petición DELETE
- `Future<String> refreshToken({...})` - Refresca el token de autenticación
- `ApiRestConnect withConfig(ApiConfig config)` - Crea instancia con nueva configuración
- `ApiRestConnect withBaseUrl(String baseUrl)` - Crea instancia con nueva URL base
- `ApiRestConnect withHeaders(Map<String, String> headers)` - Crea instancia con nuevos headers
- `ApiRestConnect withTokenConfig({...})` - Crea instancia con configuración de token

### ApiConfig

```dart
ApiConfig({
  String? baseUrl,
  String? authority,
  Duration timeout = Duration(minutes: 1),
  Map<String, String> defaultHeaders = const {'Content-Type': 'application/json'},
  String? tokenUrl,
  String? tokenField,
})
```

### TokenUtils

- `Future<String?> getToken()` - Obtiene el token guardado
- `Future<bool> saveToken(String token)` - Guarda un token
- `Future<bool> removeToken()` - Elimina el token guardado

## Logging

El paquete incluye logging automático de todas las peticiones, respuestas y errores a través de `ApiInterceptor`. Los logs incluyen:

- Método HTTP
- URL completa
- Headers
- Body de la petición
- Status code
- Body de la respuesta
- Duración de la petición
- Errores detallados

## Contribuir

Las contribuciones son bienvenidas. Por favor:

1. Fork el proyecto
2. Crea una rama para tu feature (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request

## Licencia

Este proyecto está bajo la Licencia MIT - ver el archivo [LICENSE](LICENSE) para más detalles.

## Soporte

Para reportar bugs o solicitar features, por favor abre un issue en el repositorio de GitHub.
