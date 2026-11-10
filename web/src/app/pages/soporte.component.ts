import { DatePipe } from '@angular/common';
import { Component, OnInit, inject } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { ApiService } from '../core/api.service';
import { AuthService } from '../core/auth.service';
import { EstadoTicket, Ticket } from '../models';

const TEXTO: Record<string, string> = { ABIERTO: 'Abierto', EN_PROCESO: 'En revisión', RESUELTO: 'Resuelto' };

@Component({
  selector: 'app-soporte',
  standalone: true,
  imports: [FormsModule, DatePipe],
  template: `
    <h1>Soporte técnico</h1>
    @if (mensaje) { <p class="exito" role="status">{{ mensaje }}</p> }
    @if (error) { <p class="error" role="alert">{{ error }}</p> }

    <div class="layout">
      <form class="card" (ngSubmit)="enviar()" #f="ngForm">
        <h3>Nueva solicitud</h3>
        <p class="ayuda">Cuéntanos qué problema tuviste y cómo se produjo. El administrador te responderá aquí mismo.</p>
        <div class="campo"><label for="as">Asunto</label>
          <input id="as" name="as" [(ngModel)]="asunto" required minlength="3" maxlength="120"></div>
        <div class="campo"><label for="de">Descripción</label>
          <textarea id="de" name="de" rows="6" [(ngModel)]="descripcion" required minlength="10" maxlength="1000"></textarea></div>
        <button class="btn" [disabled]="f.invalid || enviando">{{ enviando ? 'Enviando...' : 'Enviar solicitud' }}</button>
      </form>

      <section>
        <h3>{{ esAdmin ? 'Solicitudes de todos los usuarios' : 'Mis solicitudes' }}</h3>
        @for (t of tickets; track t.id) {
          <article class="card ticket">
            <header>
              <strong>{{ t.asunto }}</strong>
              <span class="etiqueta" [class.ok]="t.estado === 'RESUELTO'">{{ texto(t.estado) }}</span>
            </header>
            <small>{{ t.usuarioNombre }} ({{ t.usuarioRol }}) · {{ t.fechaCreacion | date:'dd/MM/yyyy HH:mm' }}</small>
            <p>{{ t.descripcion }}</p>

            @if (esAdmin) {
              <div class="campo"><label>Estado</label>
                <select [(ngModel)]="borradores[t.id].estado">
                  @for (e of estados; track e) { <option [value]="e">{{ texto(e) }}</option> }
                </select></div>
              <div class="campo"><label>Respuesta</label>
                <textarea rows="3" maxlength="1000" [(ngModel)]="borradores[t.id].respuesta"></textarea></div>
              <button class="btn chico" (click)="guardar(t)">Guardar respuesta</button>
            } @else if (t.respuesta) {
              <div class="resp"><b>Respuesta de soporte:</b> {{ t.respuesta }}</div>
            }
          </article>
        } @empty { <p class="ayuda">Aún no hay solicitudes.</p> }
      </section>
    </div>
  `,
  styles: [`
    .layout { display: grid; grid-template-columns: 380px 1fr; gap: 20px; align-items: start; }
    textarea { resize: vertical; }
    .ayuda { color: var(--suave); font-size: .9rem; }
    .exito { color: var(--ok); font-weight: 600; }
    .ticket { margin-bottom: 12px; }
    .ticket header { display: flex; justify-content: space-between; gap: 8px; }
    .ticket small { color: var(--suave); }
    .resp { background: #f6f1ea; border-left: 4px solid var(--ambar); padding: 10px 12px; border-radius: 6px; }
    @media (max-width: 900px) { .layout { grid-template-columns: 1fr; } }
  `]
})
export class SoporteComponent implements OnInit {
  private api = inject(ApiService);
  private auth = inject(AuthService);

  esAdmin = this.auth.sesion()?.rol === 'ADMIN';
  estados: EstadoTicket[] = ['ABIERTO', 'EN_PROCESO', 'RESUELTO'];
  tickets: Ticket[] = [];
  borradores: Record<number, { estado: EstadoTicket; respuesta: string }> = {};
  asunto = ''; descripcion = '';
  enviando = false; error = ''; mensaje = '';

  ngOnInit() { this.cargar(); }

  texto(e: string) { return TEXTO[e] ?? e; }

  cargar() {
    const lista = this.esAdmin ? this.api.todosTickets() : this.api.misTickets();
    lista.subscribe({
      next: ts => {
        ts.forEach(t => this.borradores[t.id] = { estado: t.estado, respuesta: t.respuesta ?? '' });
        this.tickets = ts;
      },
      error: e => this.error = e.error?.error ?? 'No se pudieron cargar las solicitudes'
    });
  }

  enviar() {
    this.enviando = true; this.error = ''; this.mensaje = '';
    this.api.crearTicket(this.asunto.trim(), this.descripcion.trim()).subscribe({
      next: () => {
        this.asunto = ''; this.descripcion = ''; this.enviando = false;
        this.mensaje = 'Solicitud enviada. Soporte la revisará pronto.';
        this.cargar();
      },
      error: e => { this.enviando = false; this.error = e.error?.error ?? 'No se pudo enviar la solicitud'; }
    });
  }

  guardar(t: Ticket) {
    const b = this.borradores[t.id];
    this.error = ''; this.mensaje = '';
    this.api.responderTicket(t.id, b.estado, b.respuesta).subscribe({
      next: () => { this.mensaje = 'Solicitud actualizada.'; this.cargar(); },
      error: e => this.error = e.error?.error ?? 'No se pudo guardar'
    });
  }
}