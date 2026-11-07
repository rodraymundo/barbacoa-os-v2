/// URL base de la API. Se cambia al ejecutar, sin tocar el codigo:
///   flutter run --dart-define=API_URL=http://192.168.1.50:8080/api
/// 10.0.2.2 es la PC vista desde el emulador de Android; en un telefono
/// fisico usa la IP de tu PC en la red Wi-Fi.
const String apiUrl = String.fromEnvironment(
  'API_URL',
  defaultValue: 'http://10.0.2.2:8080/api',
);
