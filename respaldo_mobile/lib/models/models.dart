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
  final DateTime fecha;
  final List<PedidoItem> items;

  Pedido({
    required this.id,
    required this.mesaNumero,
    required this.estado,
    required this.total,
    required this.fecha,
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
      case 'CANCELADO':
        return 'Cancelada';
      default:
        return estado;
    }
  }

  factory Pedido.fromJson(Map<String, dynamic> j) => Pedido(
        id: j['id'] as int,
        mesaNumero: j['mesaNumero'] as int,
        estado: j['estado'] as String,
        total: _d(j['total']),
        fecha: DateTime.parse(j['fechaCreacion'] as String),
        items: (j['items'] as List)
            .map((e) => PedidoItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class Ticket {
  final int id;
  final String asunto;
  final String descripcion;
  final String estado;
  final String? respuesta;
  final DateTime fecha;

  Ticket({
    required this.id,
    required this.asunto,
    required this.descripcion,
    required this.estado,
    required this.respuesta,
    required this.fecha,
  });

  String get estadoTexto {
    switch (estado) {
      case 'ABIERTO':
        return 'Abierto';
      case 'EN_PROCESO':
        return 'En revisión';
      case 'RESUELTO':
        return 'Resuelto';
      default:
        return estado;
    }
  }

  factory Ticket.fromJson(Map<String, dynamic> j) => Ticket(
        id: j['id'] as int,
        asunto: j['asunto'] as String,
        descripcion: j['descripcion'] as String,
        estado: j['estado'] as String,
        respuesta: j['respuesta'] as String?,
        fecha: DateTime.parse(j['fechaCreacion'] as String),
      );
}

String formatoFecha(DateTime d) {
  String dos(int n) => n.toString().padLeft(2, '0');
  return '${dos(d.day)}/${dos(d.month)}/${d.year} ${dos(d.hour)}:${dos(d.minute)}';
}