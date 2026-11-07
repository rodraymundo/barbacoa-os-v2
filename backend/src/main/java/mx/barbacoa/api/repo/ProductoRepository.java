package mx.barbacoa.api.repo;

import mx.barbacoa.api.model.Producto;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface ProductoRepository extends JpaRepository<Producto, Long> {
    List<Producto> findAllByOrderByCategoriaAscNombreAsc();
    List<Producto> findByDisponibleTrueOrderByCategoriaAscNombreAsc();
}
