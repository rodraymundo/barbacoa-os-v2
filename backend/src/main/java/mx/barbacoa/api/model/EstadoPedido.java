package mx.barbacoa.api.model;

/** ABIERTO = el mesero aun arma la orden; PENDIENTE = enviada a cocina. */
public enum EstadoPedido { ABIERTO, PENDIENTE, EN_PREPARACION, LISTO, ENTREGADO, CANCELADO }
