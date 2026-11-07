package mx.barbacoa.api.web;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import mx.barbacoa.api.model.Usuario;
import mx.barbacoa.api.repo.UsuarioRepository;
import mx.barbacoa.api.security.JwtService;
import mx.barbacoa.api.web.Dtos.*;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthController {
    private final UsuarioRepository usuarios;
    private final PasswordEncoder encoder;
    private final JwtService jwt;

    @PostMapping("/login")
    public LoginResponse login(@Valid @RequestBody LoginRequest req) {
        // Mensaje generico a proposito: no revelamos si fallo el usuario o la contraseña.
        Usuario u = usuarios.findByUsername(req.username().trim())
                .filter(x -> encoder.matches(req.password(), x.getPassword()))
                .orElseThrow(() -> new ApiException(HttpStatus.UNAUTHORIZED, "Usuario o contraseña incorrectos"));
        return new LoginResponse(jwt.generar(u), u.getUsername(), u.getNombre(), u.getRol().name());
    }
}
