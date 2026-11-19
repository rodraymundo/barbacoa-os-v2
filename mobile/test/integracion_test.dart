// Pruebas de integracion de Barbacoa OS (Practica 13, AUT-04 a AUT-06).
// ApiService, AuthProvider y SharedPreferences trabajan juntos; solo el servidor
// esta simulado con MockClient, asi las pruebas no dependen de Render ni de Internet.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:barbacoa_movil/providers/auth_provider.dart';
import 'package:barbacoa_movil/services/api_service.dart';

/// Respuesta JSON del servidor simulado.
http.Response jsonResp(Object cuerpo, [int status = 200]) => http.Response.bytes(
      utf8.encode(jsonEncode(cuerpo)),
      status,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

/// Ejecuta la prueba con un servidor simulado en lugar de la red real.
Future<T> conServidor<T>(
  Future<http.Response> Function(http.Request) servidor,
  Future<T> Function() prueba,
) =>
    http.runWithClient(prueba, () => MockClient(servidor));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AUT-04 ApiService envia y recibe datos validos', () {
    test('login manda usuario y contraseña por POST y devuelve el token', () async {
      late http.Request recibida;
      final respuesta = await conServidor((req) async {
        recibida = req;
        return jsonResp({'token': 'jwt-1', 'nombre': 'Mesero Demo', 'rol': 'MESERO'});
      }, () => ApiService().login('mesero', 'clave'));

      expect(recibida.method, 'POST');
      expect(recibida.url.path, endsWith('/auth/login'));
      expect(jsonDecode(recibida.body), {'username': 'mesero', 'password': 'clave'});
      expect(respuesta['token'], 'jwt-1');
    });

    test('abrirPedido manda el QR con el token y devuelve el pedido', () async {
      late http.Request recibida;
      final api = ApiService()..token = 'abc';
      final pedido = await conServidor((req) async {
        recibida = req;
        return jsonResp({
          'id': 11,
          'mesaNumero': 1,
          'estado': 'ABIERTO',
          'total': 0,
          'fechaCreacion': '2026-11-10T14:30:00',
          'items': <Object>[],
        });
      }, () => api.abrirPedido('BARBACOA-MESA-1'));

      expect(recibida.url.path, endsWith('/pedidos'));
      expect(recibida.headers['Authorization'], 'Bearer abc');
      expect(jsonDecode(recibida.body), {'codigoQr': 'BARBACOA-MESA-1'});
      expect(pedido.mesaNumero, 1);
      expect(pedido.estado, 'ABIERTO');
    });
  });

  group('AUT-05 ApiService maneja los errores del servidor', () {
    test('un HTTP 500 con mensaje lanza ApiException con ese mensaje', () async {
      final api = ApiService();
      await conServidor(
        (req) async => jsonResp({'error': 'Error interno del servidor'}, 500),
        () => expectLater(
          api.abrirPedido('X'),
          throwsA(isA<ApiException>()
              .having((e) => e.status, 'status', 500)
              .having((e) => e.message, 'message', 'Error interno del servidor')),
        ),
      );
    });

    test('un HTTP 401 con sesion activa avisa para cerrar la sesion', () async {
      var avisos = 0;
      final api = ApiService()
        ..token = 'vencido'
        ..onUnauthorized = () => avisos++;
      await conServidor(
        (req) async => jsonResp({'error': 'Sesión inválida'}, 401),
        () => expectLater(api.abrirPedido('X'), throwsA(isA<ApiException>())),
      );
      expect(avisos, 1);
    });

    test('un HTTP 401 sin sesion (login fallido) no cierra nada', () async {
      var avisos = 0;
      final api = ApiService()..onUnauthorized = () => avisos++;
      await conServidor(
        (req) async => jsonResp({'error': 'Credenciales inválidas'}, 401),
        () => expectLater(
          api.login('mesero', 'mal'),
          throwsA(isA<ApiException>()
              .having((e) => e.message, 'message', 'Credenciales inválidas')),
        ),
      );
      expect(avisos, 0);
    });

    test('sin conexion muestra un mensaje controlado', () async {
      final api = ApiService();
      await conServidor(
        (req) async {
          throw const SocketException('sin red');
        },
        () => expectLater(
          api.login('mesero', 'clave'),
          throwsA(isA<ApiException>()
              .having((e) => e.message, 'message', 'Sin conexión con el servidor')),
        ),
      );
    });

    test('una respuesta de error sin JSON usa el mensaje generico', () async {
      final api = ApiService();
      await conServidor(
        (req) async => http.Response('', 503),
        () => expectLater(
          api.abrirPedido('X'),
          throwsA(isA<ApiException>()
              .having((e) => e.status, 'status', 503)
              .having((e) => e.message, 'message', 'Ocurrió un error. Intenta de nuevo.')),
        ),
      );
    });
  });

  group('AUT-06 Persistencia de la sesion (SharedPreferences)', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('iniciar sesion guarda el token y el nombre', () async {
      final auth = AuthProvider(ApiService());
      final mensaje = await conServidor(
        (req) async =>
            jsonResp({'token': 'jwt-123', 'nombre': 'Mesero Demo', 'rol': 'MESERO'}),
        () => auth.iniciarSesion('mesero', 'clave'),
      );
      final prefs = await SharedPreferences.getInstance();
      expect(mensaje, isNull);
      expect(prefs.getString('token'), 'jwt-123');
      expect(prefs.getString('nombre'), 'Mesero Demo');
    });

    test('restaurarSesion recupera la sesion guardada al abrir la app', () async {
      SharedPreferences.setMockInitialValues(
          {'token': 'jwt-guardado', 'nombre': 'Mesero Demo'});
      final auth = AuthProvider(ApiService());
      await auth.restaurarSesion();
      expect(auth.listo, isTrue);
      expect(auth.autenticado, isTrue);
      expect(auth.nombre, 'Mesero Demo');
    });

    test('cerrarSesion borra los datos guardados', () async {
      SharedPreferences.setMockInitialValues({'token': 't', 'nombre': 'n'});
      final auth = AuthProvider(ApiService());
      await auth.restaurarSesion();
      await auth.cerrarSesion();
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('token'), isNull);
      expect(auth.autenticado, isFalse);
    });

    test('un HTTP 401 cierra la sesion y borra el token guardado', () async {
      SharedPreferences.setMockInitialValues(
          {'token': 'vencido', 'nombre': 'Mesero Demo'});
      final api = ApiService();
      final auth = AuthProvider(api);
      await auth.restaurarSesion();
      await conServidor(
        (req) async => jsonResp({'error': 'Sesión inválida'}, 401),
        () => expectLater(api.abrirPedido('X'), throwsA(isA<ApiException>())),
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));
      final prefs = await SharedPreferences.getInstance();
      expect(auth.autenticado, isFalse);
      expect(prefs.getString('token'), isNull);
    });
  });
}
