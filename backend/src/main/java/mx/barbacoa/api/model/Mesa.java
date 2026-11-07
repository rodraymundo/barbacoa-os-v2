package mx.barbacoa.api.model;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "mesas")
@Getter @Setter @NoArgsConstructor
public class Mesa {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    @Column(nullable = false, unique = true)
    private int numero;
    /** Texto que contiene el QR impreso en la mesa. */
    @Column(nullable = false, unique = true)
    private String codigoQr;
    @Enumerated(EnumType.STRING) @Column(nullable = false)
    private EstadoMesa estado = EstadoMesa.LIBRE;
}
