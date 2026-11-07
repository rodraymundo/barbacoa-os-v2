package mx.barbacoa.api.repo;

import mx.barbacoa.api.model.EstadoPedido;
import mx.barbacoa.api.model.Pedido;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDateTime;
import java.util.Collection;
import java.util.List;
import java.util.Optional;

public interface PedidoRepository extends JpaRepository<Pedido, Long> {
    Optional<Pedido> findFirstByMesaIdAndEstadoInOrderByIdDesc(Long mesaId, Collection<EstadoPedido> estados);
    List<Pedido> findByEstadoInOrderByFechaCreacionAsc(Collection<EstadoPedido> estados);
    List<Pedido> findTop50ByOrderByFechaCreacionDesc();
    List<Pedido> findByFechaCreacionGreaterThanEqual(LocalDateTime desde);
}
