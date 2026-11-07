import { Component, inject } from '@angular/core';
import { RouterLink, RouterLinkActive, RouterOutlet } from '@angular/router';
import { AuthService } from './core/auth.service';

@Component({
  selector: 'app-root',
  standalone: true,
  imports: [RouterOutlet, RouterLink, RouterLinkActive],
  template: `
    @if (auth.sesion(); as s) {
      <header class="topbar">
        <span class="marca">Barbacoa OS</span>
        <nav>
          @if (s.rol === 'ADMIN') {
            <a routerLink="/admin" routerLinkActive="activo" [routerLinkActiveOptions]="{ exact: true }">Dashboard</a>
            <a routerLink="/admin/productos" routerLinkActive="activo">Productos</a>
            <a routerLink="/admin/mesas" routerLinkActive="activo">Mesas y QR</a>
          }
          @if (s.rol === 'ADMIN' || s.rol === 'COCINA') {
            <a routerLink="/cocina" routerLinkActive="activo">Cocina</a>
          }
          @if (s.rol === 'ADMIN' || s.rol === 'MESERO') {
            <a routerLink="/mesero" routerLinkActive="activo">Mesero</a>
          }
        </nav>
        <span class="usuario">{{ s.nombre }}</span>
        <button class="btn ghost chico" (click)="auth.logout()">Cerrar sesión</button>
      </header>
    }
    <main><router-outlet /></main>
  `,
  styles: [`
    .topbar { display: flex; align-items: center; gap: 22px; padding: 0 22px; height: 56px;
      background: var(--vino); color: #fff; position: sticky; top: 0; z-index: 10; }
    .marca { font-weight: 800; font-size: 1.15rem; letter-spacing: .2px; }
    nav { display: flex; gap: 4px; flex: 1; }
    nav a { color: #f3dcd9; text-decoration: none; padding: 8px 12px; border-radius: 8px; font-weight: 600; }
    nav a:hover { background: rgba(255,255,255,.12); }
    nav a.activo { background: var(--ambar); color: #2b2100; }
    .usuario { font-size: .9rem; opacity: .9; }
    .topbar .btn.ghost { color: #fff; }
    @media (max-width: 760px) { .topbar { flex-wrap: wrap; height: auto; padding: 8px 12px; gap: 8px; } nav { flex-wrap: wrap; order: 3; width: 100%; } }
  `]
})
export class AppComponent {
  auth = inject(AuthService);
}
