package mx.barbacoa.api.web;

import lombok.RequiredArgsConstructor;
import mx.barbacoa.api.service.DashboardService;
import mx.barbacoa.api.web.Dtos.ResumenDto;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/dashboard")
@RequiredArgsConstructor
public class DashboardController {
    private final DashboardService service;

    @GetMapping
    @PreAuthorize("hasRole('ADMIN')")
    public ResumenDto resumen() {
        return service.resumen();
    }
}
