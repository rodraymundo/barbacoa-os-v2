import { Component, inject } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { AuthService } from '../core/auth.service';

@Component({
  selector: 'app-login',
  standalone: true,
  imports: [FormsModule],
  template: `
    <div class="caja card">
      <div class="logo">
        <img src="assets/logo.png" alt="Barbacoa OS">
      </div>
      <h1>Iniciar sesión</h1>
      <form (ngSubmit)="entrar()" #f="ngForm">
        <div class="campo">
          <label for="u">Usuario</label>
          <input id="u" name="u" [(ngModel)]="usuario" required autocomplete="username">
        </div>
        <div class="campo">
          <label for="p">Contraseña</label>
          <input id="p" name="p" type="password" [(ngModel)]="password" required autocomplete="current-password">
        </div>
        @if (error) { <p class="error" role="alert">{{ error }}</p> }
        <button class="btn" style="width:100%" [disabled]="f.invalid || cargando">
          {{ cargando ? 'Entrando...' : 'Ingresar' }}
        </button>
      </form>
    </div>
  `,
  styles: [`
    .caja { max-width: 380px; margin: 9vh auto 0; padding: 30px 28px; }
    .logo { width: 96px; height: 96px; background: none; display: grid; place-items: center;
      margin: 0 auto 14px; }
      .logo img { width: 100%; height: 100%; object-fit: contain; }
  `]
})
export class LoginComponent {
  private auth = inject(AuthService);
  private router = inject(Router);
  usuario = ''; password = ''; error = ''; cargando = false;

  constructor() {
    const s = this.auth.sesion();
    if (s) this.router.navigateByUrl(this.auth.rutaInicial(s.rol));
  }

  entrar() {
    this.cargando = true; this.error = '';
    this.auth.login(this.usuario.trim(), this.password).subscribe({
      next: s => this.router.navigateByUrl(this.auth.rutaInicial(s.rol)),
      error: e => {
        this.cargando = false;
        this.error = e.status === 0 ? 'No hay conexión con el servidor' : (e.error?.error ?? 'No se pudo iniciar sesión');
      }
    });
  }
}
