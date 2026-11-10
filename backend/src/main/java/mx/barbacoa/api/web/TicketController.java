package mx.barbacoa.api.web;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import mx.barbacoa.api.service.TicketService;
import mx.barbacoa.api.web.Dtos.*;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/soporte")
@RequiredArgsConstructor
public class TicketController {
    private final TicketService service;

    @PostMapping
    public TicketDto crear(@Valid @RequestBody TicketRequest req, Authentication auth) {
        return service.crear(auth.getName(), req);
    }

    @GetMapping("/mios")
    public List<TicketDto> mios(Authentication auth) {
        return service.mios(auth.getName());
    }

    @GetMapping
    @PreAuthorize("hasRole('ADMIN')")
    public List<TicketDto> todos() {
        return service.todos();
    }

    @PatchMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public TicketDto responder(@PathVariable Long id, @Valid @RequestBody TicketRespuestaRequest req) {
        return service.responder(id, req);
    }
}