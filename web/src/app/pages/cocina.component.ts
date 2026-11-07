import { Component, OnDestroy, OnInit, inject } from '@angular/core';
import { ApiService } from '../core/api.service';
import { EstadoPedido, Pedido } from '../models';

interface Columna { estado: EstadoPedido; titulo: string; accion?: string; siguiente?: EstadoPedido; }

@Component({
  selector: 'app-cocina',
  standalone: true,
  template: `
    <div class="tablero">
      <div class="contenido">
      <div class="cab"><h1>Cocina</h1><span>{{ pedidos.length }} pedidos en curso · se actualiza solo cada 5 s</span></div>
      @if (error) { <p class="error">{{ error }}</p> }
      <div class="columnas">
        @for (c of columnas; track c.estado) {
          <section>
            <h2>{{ c.titulo }} <span class="n">{{ por(c.estado).length }}</span></h2>
            @for (p of por(c.estado); track p.id) {
              <article [class.urgente]="minutos(p) >= 15 && c.estado !== 'LISTO'">
                <header><strong>Mesa {{ p.mesaNumero }}</strong><span>{{ minutos(p) }} min</span></header>
                <ul>
                  @for (i of p.items; track i.id) {
                    <li><b>{{ i.cantidad }}×</b> {{ i.productoNombre }} @if (i.nota) { <em>({{ i.nota }})</em> }</li>
                  }
                </ul>
                @if (c.siguiente) {
                  <button (click)="avanzar(p, c.siguiente)">{{ c.accion }}</button>
                } @else { <p class="espera">Esperando al mesero</p> }
              </article>
            } @empty { <p class="vacio">Sin pedidos</p> }
          </section>
        }
      </div>
      </div>
    </div>
  `,
  styles: [`
    .tablero { background: #1d1a19; color: #f4efeb; width: 100vw; margin: -24px 0 -60px calc(50% - 50vw);
    padding: 24px 0 60px; min-height: calc(100vh - 56px); }
    .contenido { max-width: 1200px; margin: 0 auto; padding: 0 20px; }
    .cab { display: flex; justify-content: space-between; align-items: baseline; flex-wrap: wrap; gap: 8px; }
    .cab span { color: #a79f99; font-size: .9rem; }
    .columnas { display: grid; grid-template-columns: repeat(3, 1fr); gap: 18px; align-items: start; }
    h2 { font-size: 1.1rem; display: flex; justify-content: space-between; border-bottom: 3px solid var(--ambar); padding-bottom: 8px; }
    section:nth-child(2) h2 { border-color: #e67e22; } section:nth-child(3) h2 { border-color: #3ea66b; }
    .n { background: #3a3532; border-radius: 99px; padding: 0 12px; }
    article { background: #2b2726; border-radius: 10px; padding: 14px; margin-bottom: 12px; border-left: 6px solid #6d6560; }
    article.urgente { border-left-color: #e5533d; }
    article header { display: flex; justify-content: space-between; font-size: 1.25rem; margin-bottom: 8px; }
    article header span { color: #a79f99; font-size: 1rem; }
    ul { list-style: none; margin: 0 0 12px; padding: 0; font-size: 1.1rem; }
    li { padding: 3px 0; } li b { color: var(--ambar); } li em { color: #a79f99; font-size: .9rem; }
    button { width: 100%; padding: 12px; font: inherit; font-size: 1.05rem; font-weight: 700; border: 0; border-radius: 8px;
      background: var(--ambar); color: #2b2100; cursor: pointer; }
    button:hover { background: #ffc94d; }
    .espera, .vacio { color: #a79f99; margin: 0; }
    @media (max-width: 900px) { .columnas { grid-template-columns: 1fr; } }
  `]
})
export class CocinaComponent implements OnInit, OnDestroy {
  private api = inject(ApiService);
  pedidos: Pedido[] = [];
  error = '';
  private timer?: ReturnType<typeof setInterval>;

  columnas: Columna[] = [
    { estado: 'PENDIENTE', titulo: 'Pendientes', accion: 'Empezar a preparar', siguiente: 'EN_PREPARACION' },
    { estado: 'EN_PREPARACION', titulo: 'En preparación', accion: 'Marcar como listo', siguiente: 'LISTO' },
    { estado: 'LISTO', titulo: 'Listos para entregar' }
  ];

  ngOnInit() {
    this.cargar();
    this.timer = setInterval(() => this.cargar(), 5000);
  }
  ngOnDestroy() { clearInterval(this.timer); }

  cargar() {
    this.api.pedidos(['PENDIENTE', 'EN_PREPARACION', 'LISTO']).subscribe({
      next: ps => { this.pedidos = ps; this.error = ''; },
      error: () => this.error = 'Sin conexión con el servidor. Reintentando...'
    });
  }

  por(estado: EstadoPedido) { return this.pedidos.filter(p => p.estado === estado); }

  minutos(p: Pedido) { return Math.max(0, Math.floor((Date.now() - new Date(p.fechaCreacion).getTime()) / 60000)); }

  avanzar(p: Pedido, estado: EstadoPedido) {
    this.api.cambiarEstado(p.id, estado).subscribe({
      next: () => this.cargar(),
      error: e => this.error = e.error?.error ?? 'No se pudo cambiar el estado'
    });
  }
}
