package mx.barbacoa.api.web;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import mx.barbacoa.api.model.Mesa;
import mx.barbacoa.api.repo.MesaRepository;
import mx.barbacoa.api.web.Dtos.*;
import org.springframework.http.HttpStatus;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/mesas")
@RequiredArgsConstructor
public class MesaController {
    private final MesaRepository repo;

    @GetMapping
    public List<MesaDto> listar() {
        return repo.findAllByOrderByNumeroAsc().stream().map(MesaDto::from).toList();
    }

    @GetMapping("/qr/{codigo}")
    public MesaDto porQr(@PathVariable String codigo) {
        return repo.findByCodigoQr(codigo).map(MesaDto::from)
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Código QR no reconocido"));
    }

    @PostMapping
    @PreAuthorize("hasRole('ADMIN')")
    public MesaDto crear(@Valid @RequestBody MesaRequest req) {
        if (repo.existsByNumero(req.numero())) {
            throw new ApiException(HttpStatus.CONFLICT, "Ya existe la mesa " + req.numero());
        }
        Mesa m = new Mesa();
        m.setNumero(req.numero());
        m.setCodigoQr("BARBACOA-MESA-" + req.numero());
        return MesaDto.from(repo.save(m));
    }
}
