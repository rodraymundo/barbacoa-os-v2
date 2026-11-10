package mx.barbacoa.api.model;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.LocalDateTime;

@Entity
@Table(name = "tickets_soporte")
@Getter @Setter @NoArgsConstructor
public class TicketSoporte {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    private Usuario usuario;
    @Column(nullable = false, length = 120)
    private String asunto;
    @Column(nullable = false, length = 1000)
    private String descripcion;
    @Enumerated(EnumType.STRING) @Column(nullable = false)
    private EstadoTicket estado = EstadoTicket.ABIERTO;
    @Column(length = 1000)
    private String respuesta;
    @Column(nullable = false)
    private LocalDateTime fechaCreacion = LocalDateTime.now();
    @Column(nullable = false)
    private LocalDateTime fechaActualizacion = LocalDateTime.now();
}