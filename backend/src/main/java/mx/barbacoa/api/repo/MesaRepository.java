package mx.barbacoa.api.repo;

import mx.barbacoa.api.model.Mesa;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface MesaRepository extends JpaRepository<Mesa, Long> {
    Optional<Mesa> findByCodigoQr(String codigoQr);
    List<Mesa> findAllByOrderByNumeroAsc();
    boolean existsByNumero(int numero);
}
