import 'package:flutter/foundation.dart';

import '../models/models.dart';
import '../services/api_service.dart';

/// Estado de la orden en curso (la mesa que el mesero tiene asignada).
class OrderProvider extends ChangeNotifier {
  final ApiService api;
  OrderProvider(this.api);

  List<Producto> productos = [];
  Pedido? pedido;
  bool cargando = false;
  String? error;

  Map<String, List<Producto>> get porCategoria {
    final mapa = <String, List<Producto>>{};
    for (final p in productos) {
      mapa.putIfAbsent(p.categoria, () => []).add(p);
    }
    return mapa;
  }

  Future<bool> _run(Future<void> Function() accion) async {
    cargando = true;
    error = null;
    notifyListeners();
    try {
      await accion();
      return true;
    } on ApiException catch (e) {
      error = e.message;
      return false;
    } catch (_) {
      error = 'Ocurrió un error inesperado';
      return false;
    } finally {
      cargando = false;
      notifyListeners();
    }
  }

  /// Flujo principal: escanear QR -> el servidor crea (o recupera) la orden de esa mesa.
  Future<bool> abrirDesdeQr(String codigo) => _run(() async {
        if (productos.isEmpty) productos = await api.productos();
        pedido = await api.abrirPedido(codigo);
      });

  Future<bool> agregar(Producto p) => _run(() async {
        pedido = await api.agregarItem(pedido!.id, p.id, 1);
      });

  Future<bool> quitar(PedidoItem item) => _run(() async {
        pedido = await api.quitarItem(pedido!.id, item.id);
      });

  Future<bool> enviarACocina() => _run(() async {
        pedido = await api.cambiarEstado(pedido!.id, 'PENDIENTE');
      });

  Future<bool> marcarEntregado() => _run(() async {
        await api.cambiarEstado(pedido!.id, 'ENTREGADO');
        pedido = null; // la mesa queda libre
      });

  Future<bool> actualizar() => _run(() async {
        final p = await api.obtenerPedido(pedido!.id);
        pedido = (p.estado == 'ENTREGADO' || p.estado == 'CANCELADO') ? null : p;
      });

  void limpiar() {
    pedido = null;
    productos = [];
    error = null;
    notifyListeners();
  }
}
