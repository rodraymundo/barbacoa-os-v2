export type Rol = 'ADMIN' | 'COCINA' | 'MESERO';
export type EstadoPedido = 'ABIERTO' | 'PENDIENTE' | 'EN_PREPARACION' | 'LISTO' | 'ENTREGADO' | 'CANCELADO';

export interface Sesion { token: string; username: string; nombre: string; rol: Rol; }

export interface Producto {
  id?: number; nombre: string; descripcion: string; precio: number; categoria: string; disponible: boolean;
}
export interface Mesa { id: number; numero: number; codigoQr: string; estado: 'LIBRE' | 'OCUPADA'; }

export interface ItemPedido {
  id: number; productoId: number; productoNombre: string; cantidad: number;
  precioUnitario: number; nota: string | null; subtotal: number;
}
export interface Pedido {
  id: number; mesaId: number; mesaNumero: number; meseroNombre: string | null;
  estado: EstadoPedido; fechaCreacion: string; total: number; items: ItemPedido[];
}

export interface Resumen {
  ventasHoy: number; pedidosHoy: number; ticketPromedio: number; pedidosActivos: number;
  pedidosPorEstado: Record<string, number>;
  ventasPorDia: { fecha: string; total: number }[];
  topProductos: { nombre: string; cantidad: number }[];
}
