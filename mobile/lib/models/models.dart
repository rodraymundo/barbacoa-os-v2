double _d(dynamic v) => (v as num).toDouble();

class Producto {
  final int id;
  final String nombre;
  final String descripcion;
  final double precio;
  final String categoria;

  Producto({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.precio,
    required this.categoria,
  });

  factory Producto.fromJson(Map<String, dynamic> j) => Producto(
        id: j['id'] as int,
        nombre: j['nombre'] as String,
        descripcion: (j['descripcion'] ?? '') as String,
        precio: _d(j['precio']),
        categoria: j['categoria'] as String,
      );
}

class PedidoItem {
  final int id;
  final int productoId;
  final String productoNombre;
  final int cantidad;
  final double subtotal;

  PedidoItem({
    required this.id,
    required this.productoId,
    required this.productoNombre,
    required this.cantidad,
    required this.subtotal,
  });

  factory PedidoItem.fromJson(Map<String, dynamic> j) => PedidoItem(
        id: j['id'] as int,
        productoId: j['productoId'] as int,
        productoNombre: j['productoNombre'] as String,
        cantidad: j['cantidad'] as int,
        subtotal: _d(j['subtotal']),
      );
}

class Pedido {
  final int id;
  final int mesaNumero;
  final String estado;
  final double total;
  final List<PedidoItem> items;

  Pedido({
    required this.id,
    required this.mesaNumero,
    required this.estado,
    required this.total,
    required this.items,
  });

  bool get abierto => estado == 'ABIERTO';
  bool get listo => estado == 'LISTO';

  String get estadoTexto {
    switch (estado) {
      case 'ABIERTO':
        return 'Armando orden';
      case 'PENDIENTE':
        return 'Enviada a cocina';
      case 'EN_PREPARACION':
        return 'En preparación';
      case 'LISTO':
        return 'Lista para entregar';
      case 'ENTREGADO':
        return 'Entregada';
      default:
        return estado;
    }
  }

  factory Pedido.fromJson(Map<String, dynamic> j) => Pedido(
        id: j['id'] as int,
        mesaNumero: j['mesaNumero'] as int,
        estado: j['estado'] as String,
        total: _d(j['total']),
        items: (j['items'] as List)
            .map((e) => PedidoItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
