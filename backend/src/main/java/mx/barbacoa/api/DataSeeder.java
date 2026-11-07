package mx.barbacoa.api;

import lombok.RequiredArgsConstructor;
import mx.barbacoa.api.model.*;
import mx.barbacoa.api.repo.*;
import org.springframework.boot.CommandLineRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.Random;

/** Carga datos de ejemplo la primera vez (solo si no hay usuarios). */
@Component
@RequiredArgsConstructor
public class DataSeeder implements CommandLineRunner {
    private final UsuarioRepository usuarios;
    private final MesaRepository mesas;
    private final ProductoRepository productos;
    private final PedidoRepository pedidos;
    private final PasswordEncoder encoder;

    @Override
    @Transactional
    public void run(String... args) {
        if (usuarios.count() > 0) return;

        usuario("admin", "admin123", "Administrador", Rol.ADMIN);
        usuario("cocina", "cocina123", "Cocina", Rol.COCINA);
        usuario("mesero", "mesero123", "Mesero Demo", Rol.MESERO);

        List<Mesa> listaMesas = new java.util.ArrayList<>();
        for (int n = 1; n <= 8; n++) {
            Mesa m = new Mesa();
            m.setNumero(n);
            m.setCodigoQr("BARBACOA-MESA-" + n);
            listaMesas.add(mesas.save(m));
        }

        List<Producto> menu = List.of(
                producto("Taco de barbacoa", "Borrego con cebolla y cilantro", "25", "Barbacoa"),
                producto("Orden de 3 tacos", "Con salsa de la casa", "70", "Barbacoa"),
                producto("Medio kilo de barbacoa", "Incluye tortillas y salsas", "280", "Barbacoa"),
                producto("Kilo de barbacoa", "Incluye tortillas y salsas", "520", "Barbacoa"),
                producto("Consomé chico", "Con garbanzo y arroz", "45", "Complementos"),
                producto("Consomé grande", "Con garbanzo y arroz", "70", "Complementos"),
                producto("Pancita", "Orden individual", "90", "Complementos"),
                producto("Agua de horchata", "Vaso de 500 ml", "35", "Bebidas"),
                producto("Agua de jamaica", "Vaso de 500 ml", "35", "Bebidas"),
                producto("Refresco", "Botella de vidrio", "30", "Bebidas"),
                producto("Pulque curado", "Sabor del día", "55", "Bebidas"),
                producto("Flan", "Receta de la casa", "40", "Postres"));

        // Historial de la ultima semana para que las graficas del admin no salgan vacias.
        Random rnd = new Random(7);
        for (int d = 6; d >= 0; d--) {
            int cuantos = 4 + rnd.nextInt(6);
            for (int k = 0; k < cuantos; k++) {
                Pedido p = new Pedido();
                p.setMesa(listaMesas.get(rnd.nextInt(listaMesas.size())));
                p.setEstado(EstadoPedido.ENTREGADO);
                p.setFechaCreacion(LocalDate.now().minusDays(d).atTime(13 + rnd.nextInt(8), rnd.nextInt(60)));
                int lineas = 1 + rnd.nextInt(3);
                for (int l = 0; l < lineas; l++) {
                    Producto prod = menu.get(rnd.nextInt(menu.size()));
                    PedidoItem it = new PedidoItem();
                    it.setPedido(p);
                    it.setProducto(prod);
                    it.setCantidad(1 + rnd.nextInt(3));
                    it.setPrecioUnitario(prod.getPrecio());
                    p.getItems().add(it);
                }
                pedidos.save(p);
            }
        }
    }

    private void usuario(String user, String pass, String nombre, Rol rol) {
        Usuario u = new Usuario();
        u.setUsername(user);
        u.setPassword(encoder.encode(pass));
        u.setNombre(nombre);
        u.setRol(rol);
        usuarios.save(u);
    }

    private Producto producto(String nombre, String desc, String precio, String categoria) {
        Producto p = new Producto();
        p.setNombre(nombre);
        p.setDescripcion(desc);
        p.setPrecio(new BigDecimal(precio));
        p.setCategoria(categoria);
        return productos.save(p);
    }
}
