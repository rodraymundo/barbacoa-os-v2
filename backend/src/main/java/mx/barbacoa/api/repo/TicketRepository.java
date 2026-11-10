package mx.barbacoa.api.repo;

import mx.barbacoa.api.model.TicketSoporte;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface TicketRepository extends JpaRepository<TicketSoporte, Long> {
    List<TicketSoporte> findByUsuarioUsernameOrderByFechaCreacionDesc(String username);
    List<TicketSoporte> findAllByOrderByFechaCreacionDesc();
}