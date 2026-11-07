package mx.barbacoa.api.model;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.math.BigDecimal;

@Entity
@Table(name = "pedido_items")
@Getter @Setter @NoArgsConstructor
public class PedidoItem {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    private Pedido pedido;
    @ManyToOne(optional = false)
    private Producto producto;
    @Column(nullable = false)
    private int cantidad;
    /** Se copia el precio al momento de ordenar para no alterar ventas pasadas. */
    @Column(nullable = false, precision = 10, scale = 2)
    private BigDecimal precioUnitario;
    private String nota;
}
