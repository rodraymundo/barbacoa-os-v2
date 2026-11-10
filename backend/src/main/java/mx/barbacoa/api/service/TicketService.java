package mx.barbacoa.api.service;

import lombok.RequiredArgsConstructor;
import mx.barbacoa.api.model.TicketSoporte;
import mx.barbacoa.api.model.Usuario;
import mx.barbacoa.api.repo.TicketRepository;
import mx.barbacoa.api.repo.UsuarioRepository;
import mx.barbacoa.api.web.ApiException;
import mx.barbacoa.api.web.Dtos.*;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;

@Service
@RequiredArgsConstructor
public class TicketService {
    private final TicketRepository tickets;
    private final UsuarioRepository usuarios;

    @Transactional
    public TicketDto crear(String username, TicketRequest req) {
        Usuario u = usuarios.findByUsername(username)
                .orElseThrow(() -> new ApiException(HttpStatus.UNAUTHORIZED, "Sesión inválida"));
        TicketSoporte t = new TicketSoporte();
        t.setUsuario(u);
        t.setAsunto(req.asunto().trim());
        t.setDescripcion(req.descripcion().trim());
        return toDto(tickets.save(t));
    }

    @Transactional(readOnly = true)
    public List<TicketDto> mios(String username) {
        return tickets.findByUsuarioUsernameOrderByFechaCreacionDesc(username).stream().map(this::toDto).toList();
    }

    @Transactional(readOnly = true)
    public List<TicketDto> todos() {
        return tickets.findAllByOrderByFechaCreacionDesc().stream().map(this::toDto).toList();
    }

    @Transactional
    public TicketDto responder(Long id, TicketRespuestaRequest req) {
        TicketSoporte t = tickets.findById(id)
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Solicitud no encontrada"));
        t.setEstado(req.estado());
        String r = req.respuesta() == null ? "" : req.respuesta().trim();
        t.setRespuesta(r.isEmpty() ? null : r);
        t.setFechaActualizacion(LocalDateTime.now());
        return toDto(t);
    }

    private TicketDto toDto(TicketSoporte t) {
        return new TicketDto(t.getId(), t.getUsuario().getNombre(), t.getUsuario().getRol().name(),
                t.getAsunto(), t.getDescripcion(), t.getEstado().name(), t.getRespuesta(),
                t.getFechaCreacion(), t.getFechaActualizacion());
    }
}