import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config.dart';
import '../models/models.dart';

class ApiException implements Exception {
  final String message;
  final int? status;
  ApiException(this.message, {this.status});

  @override
  String toString() => message;
}

/// Unico punto de contacto con el backend Spring Boot.
class ApiService {
  String? token;

  /// La establece AuthProvider: se llama cuando el servidor responde 401 con sesion activa.
  void Function()? onUnauthorized;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  Future<dynamic> _send(Future<http.Response> Function() call) async {
    try {
      final res = await call().timeout(const Duration(seconds: 10));
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return res.body.isEmpty ? null : jsonDecode(utf8.decode(res.bodyBytes));
      }
      if (res.statusCode == 401 && token != null) onUnauthorized?.call();
      var msg = 'Ocurrió un error. Intenta de nuevo.';
      try {
        msg = (jsonDecode(utf8.decode(res.bodyBytes)) as Map)['error'] as String? ?? msg;
      } catch (_) {}
      throw ApiException(msg, status: res.statusCode);
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw ApiException('El servidor no responde');
    } on SocketException {
      throw ApiException('Sin conexión con el servidor');
    } on http.ClientException {
      throw ApiException('Sin conexión con el servidor');
    }
  }

  Uri _u(String path) => Uri.parse('$apiUrl$path');

  Future<Map<String, dynamic>> login(String usuario, String password) async {
    final data = await _send(() => http.post(_u('/auth/login'),
        headers: _headers,
        body: jsonEncode({'username': usuario, 'password': password})));
    return data as Map<String, dynamic>;
  }

  Future<List<Producto>> productos() async {
    final data = await _send(() => http.get(_u('/productos'), headers: _headers));
    return (data as List).map((e) => Producto.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Escanear el QR de una mesa: crea la orden (o devuelve la que ya estaba abierta).
  Future<Pedido> abrirPedido(String codigoQr) async {
    final data = await _send(() => http.post(_u('/pedidos'),
        headers: _headers, body: jsonEncode({'codigoQr': codigoQr})));
    return Pedido.fromJson(data as Map<String, dynamic>);
  }

  Future<Pedido> obtenerPedido(int id) async {
    final data = await _send(() => http.get(_u('/pedidos/$id'), headers: _headers));
    return Pedido.fromJson(data as Map<String, dynamic>);
  }

  Future<Pedido> agregarItem(int pedidoId, int productoId, int cantidad) async {
    final data = await _send(() => http.post(_u('/pedidos/$pedidoId/items'),
        headers: _headers,
        body: jsonEncode({'productoId': productoId, 'cantidad': cantidad})));
    return Pedido.fromJson(data as Map<String, dynamic>);
  }

  Future<Pedido> quitarItem(int pedidoId, int itemId) async {
    final data = await _send(
        () => http.delete(_u('/pedidos/$pedidoId/items/$itemId'), headers: _headers));
    return Pedido.fromJson(data as Map<String, dynamic>);
  }

  Future<Pedido> cambiarEstado(int pedidoId, String estado) async {
    final data = await _send(() => http.patch(_u('/pedidos/$pedidoId/estado'),
        headers: _headers, body: jsonEncode({'estado': estado})));
    return Pedido.fromJson(data as Map<String, dynamic>);
  }
}
