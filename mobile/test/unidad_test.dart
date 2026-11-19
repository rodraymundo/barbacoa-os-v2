// Pruebas unitarias de Barbacoa OS (Practica 13, AUT-01 a AUT-03).
// No usan red: la logica se prueba con datos de ejemplo y un ApiService falso.
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:barbacoa_movil/models/models.dart';
import 'package:barbacoa_movil/providers/auth_provider.dart';
import 'package:barbacoa_movil/services/api_service.dart';

/// JSON de un pedido como lo manda el servidor.
Map<String, dynamic> pedidoJson({
  String estado = 'ABIERTO',
  num total = 75,
  List<Map<String, dynamic>>? items,
}) {
  final renglones = items ??
      <Map<String, dynamic>>[
        {
          'id': 1,
          'productoId': 2,
          'productoNombre': 'Taco de barbacoa',
          'cantidad': 3,
          'subtotal': 75,
        },
      ];
  return {
    'id': 7,
    'mesaNumero': 3,
    'estado': estado,
    'total': total,
    'fechaCreacion': '2026-11-10T14:30:00',
    'items': renglones,
  };
}

/// ApiService falso: no toca la red, responde lo que la prueba indique.
class ApiFalso extends ApiService {
  Map<String, dynamic>? respuesta;
  Object? error;

  @override
  Future<Map<String, dynamic>> login(String usuario, String password) async {
    if (error != null) throw error!;
    return respuesta!;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AUT-01 Pedido: estados y banderas', () {
    test('estadoTexto traduce cada estado conocido (entrada valida)', () {
      final esperado = {
        'ABIERTO': 'Armando orden',
        'PENDIENTE': 'Enviada a cocina',
        'EN_PREPARACION': 'En preparación',
        'LISTO': 'Lista para entregar',
        'ENTREGADO': 'Entregada',
        'CANCELADO': 'Cancelada',
      };
      esperado.forEach((estado, texto) {
        expect(Pedido.fromJson(pedidoJson(estado: estado)).estadoTexto, texto);
      });
    });

    test('un estado fuera del catalogo se muestra tal cual', () {
      final p = Pedido.fromJson(pedidoJson(estado: 'ESTADO_RARO'));
      expect(p.estadoTexto, 'ESTADO_RARO');
    });

    test('un estado vacio no rompe la pantalla', () {
      final p = Pedido.fromJson(pedidoJson(estado: ''));
      expect(p.estadoTexto, '');
    });

    test('abierto y listo solo son verdaderos en su propio estado', () {
      final abierto = Pedido.fromJson(pedidoJson(estado: 'ABIERTO'));
      final listo = Pedido.fromJson(pedidoJson(estado: 'LISTO'));
      expect(abierto.abierto, isTrue);
      expect(abierto.listo, isFalse);
      expect(listo.abierto, isFalse);
      expect(listo.listo, isTrue);
    });
  });

  group('AUT-02 Modelos: lectura del JSON', () {
    test('Pedido.fromJson lee un pedido valido', () {
      final p = Pedido.fromJson(pedidoJson());
      expect(p.id, 7);
      expect(p.mesaNumero, 3);
      expect(p.total, 75.0);
      expect(p.fecha.year, 2026);
      expect(p.items.length, 1);
      expect(p.items.first.productoNombre, 'Taco de barbacoa');
      expect(p.items.first.cantidad, 3);
    });

    test('un total entero se convierte a double', () {
      final p = Pedido.fromJson(pedidoJson(total: 150));
      expect(p.total, isA<double>());
      expect(p.total, 150.0);
    });

    test('un pedido sin renglones queda con lista vacia', () {
      final p = Pedido.fromJson(pedidoJson(items: <Map<String, dynamic>>[]));
      expect(p.items, isEmpty);
    });

    test('Producto.fromJson con descripcion nula usa texto vacio', () {
      final p = Producto.fromJson({
        'id': 1,
        'nombre': 'Taco',
        'descripcion': null,
        'precio': 25,
        'categoria': 'TACOS',
      });
      expect(p.descripcion, '');
      expect(p.precio, 25.0);
    });

    test('un JSON sin estado lanza TypeError', () {
      final json = pedidoJson()..remove('estado');
      expect(() => Pedido.fromJson(json), throwsA(isA<TypeError>()));
    });
  });

  group('AUT-03 AuthProvider.iniciarSesion', () {
    late ApiFalso api;
    late AuthProvider auth;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      api = ApiFalso();
      auth = AuthProvider(api);
    });

    test('rechaza a un usuario que no es mesero', () async {
      api.respuesta = {'token': 'abc', 'nombre': 'Cocinero', 'rol': 'COCINA'};
      final mensaje = await auth.iniciarSesion('cocina', 'clave');
      expect(mensaje, 'Esta app es solo para meseros');
      expect(auth.autenticado, isFalse);
    });

    test('acepta a un mesero y abre la sesion', () async {
      api.respuesta = {'token': 'jwt-123', 'nombre': 'Mesero Demo', 'rol': 'MESERO'};
      final mensaje = await auth.iniciarSesion('mesero', 'clave');
      expect(mensaje, isNull);
      expect(auth.autenticado, isTrue);
      expect(auth.nombre, 'Mesero Demo');
    });

    test('muestra el mensaje del servidor cuando las credenciales fallan', () async {
      api.error = ApiException('Usuario o contraseña incorrectos', status: 401);
      final mensaje = await auth.iniciarSesion('mesero', 'mal');
      expect(mensaje, 'Usuario o contraseña incorrectos');
      expect(auth.autenticado, isFalse);
    });

    test('un error inesperado da un mensaje generico', () async {
      api.error = StateError('falla interna');
      final mensaje = await auth.iniciarSesion('mesero', 'clave');
      expect(mensaje, 'No se pudo iniciar sesión');
    });
  });
}
