package mx.barbacoa.api.web;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import mx.barbacoa.api.model.Producto;
import mx.barbacoa.api.repo.ProductoRepository;
import mx.barbacoa.api.web.Dtos.*;
import org.springframework.http.HttpStatus;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/productos")
@RequiredArgsConstructor
public class ProductoController {
    private final ProductoRepository repo;

    /** Admin ve todo el catalogo; el resto solo lo disponible. */
    @GetMapping
    public List<ProductoDto> listar(Authentication auth) {
        boolean admin = auth.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_ADMIN"));
        return (admin ? repo.findAllByOrderByCategoriaAscNombreAsc()
                      : repo.findByDisponibleTrueOrderByCategoriaAscNombreAsc())
                .stream().map(ProductoDto::from).toList();
    }

    @PostMapping
    @PreAuthorize("hasRole('ADMIN')")
    public ProductoDto crear(@Valid @RequestBody ProductoRequest req) {
        Producto p = new Producto();
        aplicar(p, req);
        return ProductoDto.from(repo.save(p));
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public ProductoDto actualizar(@PathVariable Long id, @Valid @RequestBody ProductoRequest req) {
        Producto p = repo.findById(id)
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Producto no encontrado"));
        aplicar(p, req);
        return ProductoDto.from(repo.save(p));
    }

    private void aplicar(Producto p, ProductoRequest r) {
        p.setNombre(r.nombre().trim());
        p.setDescripcion(r.descripcion());
        p.setPrecio(r.precio());
        p.setCategoria(r.categoria().trim());
        if (r.disponible() != null) p.setDisponible(r.disponible());
    }
}
