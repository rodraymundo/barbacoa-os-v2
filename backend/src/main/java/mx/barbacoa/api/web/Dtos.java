package mx.barbacoa.api.web;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import mx.barbacoa.api.model.EstadoPedido;
import mx.barbacoa.api.model.Mesa;
import mx.barbacoa.api.model.Producto;

import jakarta.validation.constraints.Size;
import mx.barbacoa.api.model.EstadoTicket;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

/** Todos los objetos que viajan por la API (entrada y salida). */
public final class Dtos {
    private Dtos() {}

    // ----- auth
    public record LoginRequest(@NotBlank String username, @NotBlank String password) {}
    public record LoginResponse(String token, String username, String nombre, String rol) {}

    // ----- productos
    public record ProductoRequest(@NotBlank String nombre, String descripcion,
                                  @NotNull @DecimalMin("0.0") BigDecimal precio,
                                  @NotBlank String categoria, Boolean disponible) {}
    public record ProductoDto(Long id, String nombre, String descripcion, BigDecimal precio,
                              String categoria, boolean disponible) {
        public static ProductoDto from(Producto p) {
            return new ProductoDto(p.getId(), p.getNombre(), p.getDescripcion(), p.getPrecio(),
                    p.getCategoria(), p.isDisponible());
        }
    }

    // ----- mesas
    public record MesaRequest(@NotNull @Min(1) Integer numero) {}
    public record MesaDto(Long id, int numero, String codigoQr, String estado) {
        public static MesaDto from(Mesa m) {
            return new MesaDto(m.getId(), m.getNumero(), m.getCodigoQr(), m.getEstado().name());
        }
    }

    // ----- pedidos
    /** Se envia mesaId (web) o codigoQr (movil). */
    public record AbrirPedidoRequest(Long mesaId, String codigoQr) {}
    public record ItemRequest(@NotNull Long productoId, @NotNull @Min(1) Integer cantidad, String nota) {}
    public record EstadoRequest(@NotNull EstadoPedido estado) {}
    public record ItemDto(Long id, Long productoId, String productoNombre, int cantidad,
                          BigDecimal precioUnitario, String nota, BigDecimal subtotal) {}
    public record PedidoDto(Long id, Long mesaId, int mesaNumero, String meseroNombre, String estado,
                            LocalDateTime fechaCreacion, BigDecimal total, List<ItemDto> items) {}

    // ----- dashboard
    public record VentaDia(LocalDate fecha, BigDecimal total) {}
    public record TopProducto(String nombre, long cantidad) {}
    public record ResumenDto(BigDecimal ventasHoy, long pedidosHoy, BigDecimal ticketPromedio,
                             long pedidosActivos, Map<String, Long> pedidosPorEstado,
                             List<VentaDia> ventasPorDia, List<TopProducto> topProductos) {}

        // ----- soporte tecnico
    public record TicketRequest(@NotBlank @Size(max = 120) String asunto,
                                @NotBlank @Size(max = 1000) String descripcion) {}
    public record TicketRespuestaRequest(@NotNull EstadoTicket estado, @Size(max = 1000) String respuesta) {}
    public record TicketDto(Long id, String usuarioNombre, String usuarioRol, String asunto,
                            String descripcion, String estado, String respuesta,
                            LocalDateTime fechaCreacion, LocalDateTime fechaActualizacion) {}                         
}
