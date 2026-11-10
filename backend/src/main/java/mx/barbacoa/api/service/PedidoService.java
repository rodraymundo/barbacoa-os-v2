package mx.barbacoa.api.service;

import lombok.RequiredArgsConstructor;
import mx.barbacoa.api.model.*;
import mx.barbacoa.api.repo.*;
import mx.barbacoa.api.web.ApiException;
import mx.barbacoa.api.web.Dtos.*;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Objects;

@Service
@RequiredArgsConstructor
public class PedidoService {
    public static final List<EstadoPedido> ACTIVOS =
            List.of(EstadoPedido.ABIERTO, EstadoPedido.PENDIENTE, EstadoPedido.EN_PREPARACION, EstadoPedido.LISTO);

    private final PedidoRepository pedidos;
    private final MesaRepository mesas;
    private final ProductoRepository productos;
    private final UsuarioRepository usuarios;

    /** Abre el pedido de una mesa; si ya hay uno activo, devuelve ese mismo (escanear dos veces no duplica). */
    @Transactional
    public PedidoDto abrir(AbrirPedidoRequest req, String username) {
        Mesa mesa;
        if (req.codigoQr() != null && !req.codigoQr().isBlank()) {
            mesa = mesas.findByCodigoQr(req.codigoQr().trim())
                    .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Código QR no reconocido"));
        } else if (req.mesaId() != null) {
            mesa = mesas.findById(req.mesaId())
                    .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Mesa no encontrada"));
        } else {
            throw new ApiException(HttpStatus.BAD_REQUEST, "Indica la mesa o el código QR");
        }
        Pedido pedido = pedidos.findFirstByMesaIdAndEstadoInOrderByIdDesc(mesa.getId(), ACTIVOS)
                .orElseGet(() -> {
                    Pedido p = new Pedido();
                    p.setMesa(mesa);
                    p.setMesero(usuarios.findByUsername(username).orElse(null));
                    p.setEstado(EstadoPedido.ABIERTO);
                    p.setFechaCreacion(LocalDateTime.now());
                    mesa.setEstado(EstadoMesa.OCUPADA);
                    return pedidos.save(p);
                });
        return toDto(pedido);
    }

    @Transactional(readOnly = true)
    public List<PedidoDto> listar(List<EstadoPedido> estados) {
        List<Pedido> lista = (estados == null || estados.isEmpty())
                ? pedidos.findTop50ByOrderByFechaCreacionDesc()
                : pedidos.findByEstadoInOrderByFechaCreacionAsc(estados);
        return lista.stream().map(this::toDto).toList();
    }

    @Transactional(readOnly = true)
    public PedidoDto obtener(Long id) {
        return toDto(buscar(id));
    }

        @Transactional(readOnly = true)
    public List<PedidoDto> historial(String username) {
        return pedidos.findTop100ByMeseroUsernameOrderByFechaCreacionDesc(username)
                .stream().map(this::toDto).toList();
    }

    @Transactional
    public PedidoDto agregarItem(Long id, ItemRequest req) {
        Pedido p = buscar(id);
        if (p.getEstado() != EstadoPedido.ABIERTO && p.getEstado() != EstadoPedido.PENDIENTE) {
            throw new ApiException(HttpStatus.CONFLICT, "Este pedido ya no admite productos");
        }
        Producto prod = productos.findById(req.productoId())
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Producto no encontrado"));
        if (!prod.isDisponible()) {
            throw new ApiException(HttpStatus.CONFLICT, "El producto no está disponible");
        }
        String nota = req.nota() == null ? "" : req.nota().trim();
        PedidoItem existente = p.getItems().stream()
                .filter(i -> i.getProducto().getId().equals(prod.getId())
                        && Objects.equals(i.getNota() == null ? "" : i.getNota(), nota))
                .findFirst().orElse(null);
        if (existente != null) {
            existente.setCantidad(existente.getCantidad() + req.cantidad());
        } else {
            PedidoItem item = new PedidoItem();
            item.setPedido(p);
            item.setProducto(prod);
            item.setCantidad(req.cantidad());
            item.setPrecioUnitario(prod.getPrecio());
            item.setNota(nota.isEmpty() ? null : nota);
            p.getItems().add(item);
        }
        pedidos.flush();
        return toDto(p);
    }

    @Transactional
    public PedidoDto quitarItem(Long id, Long itemId) {
        Pedido p = buscar(id);
        if (p.getEstado() != EstadoPedido.ABIERTO) {
            throw new ApiException(HttpStatus.CONFLICT, "Solo se pueden quitar productos antes de enviar a cocina");
        }
        p.getItems().removeIf(i -> i.getId().equals(itemId));
        pedidos.flush();
        return toDto(p);
    }

    @Transactional
    public PedidoDto cambiarEstado(Long id, EstadoPedido nuevo, String username) {
        Pedido p = buscar(id);
        Usuario u = usuarios.findByUsername(username)
                .orElseThrow(() -> new ApiException(HttpStatus.UNAUTHORIZED, "Sesión inválida"));
        if (!permitido(u.getRol(), p.getEstado(), nuevo)) {
            throw new ApiException(HttpStatus.FORBIDDEN, "No puedes pasar el pedido de "
                    + p.getEstado() + " a " + nuevo);
        }
        if (nuevo == EstadoPedido.PENDIENTE && p.getItems().isEmpty()) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "Agrega al menos un producto antes de enviar a cocina");
        }
        p.setEstado(nuevo);
        if (nuevo == EstadoPedido.ENTREGADO || nuevo == EstadoPedido.CANCELADO) {
            p.getMesa().setEstado(EstadoMesa.LIBRE);
        }
        return toDto(p);
    }

    /** Reglas del flujo: quien puede mover un pedido de un estado a otro. */
    private boolean permitido(Rol rol, EstadoPedido de, EstadoPedido a) {
        return switch (rol) {
            case ADMIN -> true;
            case COCINA -> (de == EstadoPedido.PENDIENTE && a == EstadoPedido.EN_PREPARACION)
                    || (de == EstadoPedido.EN_PREPARACION && a == EstadoPedido.LISTO);
            case MESERO -> (de == EstadoPedido.ABIERTO && a == EstadoPedido.PENDIENTE)
                    || (de == EstadoPedido.LISTO && a == EstadoPedido.ENTREGADO)
                    || (a == EstadoPedido.CANCELADO
                        && (de == EstadoPedido.ABIERTO || de == EstadoPedido.PENDIENTE));
        };
    }

    private Pedido buscar(Long id) {
        return pedidos.findById(id)
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Pedido no encontrado"));
    }

    public PedidoDto toDto(Pedido p) {
        List<ItemDto> items = p.getItems().stream().map(i -> new ItemDto(
                i.getId(), i.getProducto().getId(), i.getProducto().getNombre(), i.getCantidad(),
                i.getPrecioUnitario(), i.getNota(),
                i.getPrecioUnitario().multiply(BigDecimal.valueOf(i.getCantidad())))).toList();
        return new PedidoDto(p.getId(), p.getMesa().getId(), p.getMesa().getNumero(),
                p.getMesero() == null ? null : p.getMesero().getNombre(),
                p.getEstado().name(), p.getFechaCreacion(), p.total(), items);
    }
}
