package mx.barbacoa.api.web;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import mx.barbacoa.api.model.EstadoPedido;
import mx.barbacoa.api.service.PedidoService;
import mx.barbacoa.api.web.Dtos.*;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/pedidos")
@RequiredArgsConstructor
public class PedidoController {
    private final PedidoService service;

    /** Movil: {"codigoQr": "..."}; web: {"mesaId": 1}. */
    @PostMapping
    @PreAuthorize("hasAnyRole('MESERO','ADMIN')")
    public PedidoDto abrir(@RequestBody AbrirPedidoRequest req, Authentication auth) {
        return service.abrir(req, auth.getName());
    }

    @GetMapping
    public List<PedidoDto> listar(@RequestParam(required = false) List<EstadoPedido> estados,
                                  Authentication auth) {
        return service.listar(estados, auth.getName());
    }

    @GetMapping("/historial")
    public List<PedidoDto> historial(Authentication auth) {
        return service.historial(auth.getName());
    }

    @GetMapping("/{id}")
    public PedidoDto obtener(@PathVariable Long id, Authentication auth) {
        return service.obtener(id, auth.getName());
    }

    @PostMapping("/{id}/items")
    @PreAuthorize("hasAnyRole('MESERO','ADMIN')")
    public PedidoDto agregarItem(@PathVariable Long id, @Valid @RequestBody ItemRequest req,
                                 Authentication auth) {
        return service.agregarItem(id, req, auth.getName());
    }

    @DeleteMapping("/{id}/items/{itemId}")
    @PreAuthorize("hasAnyRole('MESERO','ADMIN')")
    public PedidoDto quitarItem(@PathVariable Long id, @PathVariable Long itemId, Authentication auth) {
        return service.quitarItem(id, itemId, auth.getName());
    }

    @PatchMapping("/{id}/estado")
    public PedidoDto cambiarEstado(@PathVariable Long id, @Valid @RequestBody EstadoRequest req,
                                   Authentication auth) {
        return service.cambiarEstado(id, req.estado(), auth.getName());
    }
}