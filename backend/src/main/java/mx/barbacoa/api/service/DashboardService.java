package mx.barbacoa.api.service;

import lombok.RequiredArgsConstructor;
import mx.barbacoa.api.model.EstadoPedido;
import mx.barbacoa.api.model.Pedido;
import mx.barbacoa.api.repo.PedidoRepository;
import mx.barbacoa.api.web.Dtos.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.util.*;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class DashboardService {
    private final PedidoRepository pedidos;

    @Transactional(readOnly = true)
    public ResumenDto resumen() {
        LocalDate hoy = LocalDate.now();
        List<Pedido> recientes = pedidos.findByFechaCreacionGreaterThanEqual(hoy.minusDays(6).atStartOfDay());
        List<Pedido> entregados = recientes.stream()
                .filter(p -> p.getEstado() == EstadoPedido.ENTREGADO).toList();
        List<Pedido> entregadosHoy = entregados.stream()
                .filter(p -> p.getFechaCreacion().toLocalDate().equals(hoy)).toList();

        BigDecimal ventasHoy = suma(entregadosHoy);
        BigDecimal ticket = entregadosHoy.isEmpty() ? BigDecimal.ZERO
                : ventasHoy.divide(BigDecimal.valueOf(entregadosHoy.size()), 2, RoundingMode.HALF_UP);
        long pedidosHoy = recientes.stream()
                .filter(p -> p.getFechaCreacion().toLocalDate().equals(hoy))
                .filter(p -> p.getEstado() != EstadoPedido.CANCELADO).count();

        Map<String, Long> porEstado = new LinkedHashMap<>();
        for (EstadoPedido e : EstadoPedido.values()) {
            porEstado.put(e.name(), recientes.stream().filter(p -> p.getEstado() == e).count());
        }

        List<VentaDia> ventasPorDia = new ArrayList<>();
        for (int i = 6; i >= 0; i--) {
            LocalDate dia = hoy.minusDays(i);
            ventasPorDia.add(new VentaDia(dia, suma(entregados.stream()
                    .filter(p -> p.getFechaCreacion().toLocalDate().equals(dia)).toList())));
        }

        Map<String, Long> unidades = entregados.stream()
                .flatMap(p -> p.getItems().stream())
                .collect(Collectors.groupingBy(i -> i.getProducto().getNombre(),
                        Collectors.summingLong(i -> i.getCantidad())));
        List<TopProducto> top = unidades.entrySet().stream()
                .sorted(Map.Entry.<String, Long>comparingByValue().reversed())
                .limit(5).map(e -> new TopProducto(e.getKey(), e.getValue())).toList();

        long activos = pedidos.findByEstadoInOrderByFechaCreacionAsc(PedidoService.ACTIVOS).size();
        return new ResumenDto(ventasHoy, pedidosHoy, ticket, activos, porEstado, ventasPorDia, top);
    }

    private BigDecimal suma(List<Pedido> lista) {
        return lista.stream().map(Pedido::total).reduce(BigDecimal.ZERO, BigDecimal::add);
    }
}
