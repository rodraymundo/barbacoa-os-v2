import { CurrencyPipe, DatePipe } from '@angular/common';
import { Component, OnInit, inject } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { ApiService } from '../core/api.service';
import { Pedido } from '../models';

const TEXTO: Record<string, string> = {
  ABIERTO: 'Armando orden', PENDIENTE: 'En cocina', EN_PREPARACION: 'Preparando',
  LISTO: 'Lista', ENTREGADO: 'Entregada', CANCELADO: 'Cancelada'
};

@Component({
  selector: 'app-historial',
  standalone: true,
  imports: [FormsModule, CurrencyPipe, DatePipe],
  template: `
    <div class="cabecera">
      <h1>Historial de pedidos</h1>
      <select [(ngModel)]="filtro" aria-label="Filtrar por estado">
        <option value="">Todos</option>
        @for (e of estados; track e) { <option [value]="e">{{ texto(e) }}</option> }
      </select>
    </div>
    <p class="ayuda">Las órdenes que has tomado (las 100 más recientes).</p>
    @if (error) { <p class="error">{{ error }}</p> }

    @for (p of visibles; track p.id) {
      <details class="card pedido">
        <summary>
          <span>{{ p.fechaCreacion | date:'dd/MM/yyyy HH:mm' }}</span>
          <strong>Mesa {{ p.mesaNumero }}</strong>
          <span class="etiqueta" [class.ok]="p.estado === 'ENTREGADO'" [class.off]="p.estado === 'CANCELADO'">{{ texto(p.estado) }}</span>
          <b>{{ p.total | currency:'MXN':'symbol-narrow' }}</b>
        </summary>
        <ul>
          @for (i of p.items; track i.id) {
            <li><span><b>{{ i.cantidad }}×</b> {{ i.productoNombre }}</span>
              <span>{{ i.subtotal | currency:'MXN':'symbol-narrow' }}</span></li>
          } @empty { <li class="ayuda">Sin productos</li> }
        </ul>
      </details>
    } @empty {
      @if (!error) { <p class="ayuda">Todavía no tienes pedidos en el historial.</p> }
    }
  `,
  styles: [`
    .cabecera { display: flex; justify-content: space-between; align-items: center; gap: 12px; flex-wrap: wrap; }
    .cabecera h1 { margin: 0; } .cabecera select { width: 200px; }
    .ayuda { color: var(--suave); }
    .pedido { margin-bottom: 10px; padding: 0; }
    summary { display: grid; grid-template-columns: 1.4fr 1fr 1fr auto; gap: 12px; align-items: center;
      padding: 14px 16px; cursor: pointer; list-style-position: inside; }
    ul { list-style: none; margin: 0; padding: 0 16px 14px; }
    li { display: flex; justify-content: space-between; padding: 6px 0; border-top: 1px solid var(--borde); }
    @media (max-width: 700px) { summary { grid-template-columns: 1fr 1fr; } }
  `]
})
export class HistorialComponent implements OnInit {
  private api = inject(ApiService);
  pedidos: Pedido[] = [];
  filtro = '';
  error = '';
  estados = ['ABIERTO', 'PENDIENTE', 'EN_PREPARACION', 'LISTO', 'ENTREGADO', 'CANCELADO'];

  ngOnInit() {
    this.api.historial().subscribe({
      next: ps => this.pedidos = ps,
      error: e => this.error = e.error?.error ?? 'No se pudo cargar el historial'
    });
  }

  get visibles() { return this.filtro ? this.pedidos.filter(p => p.estado === this.filtro) : this.pedidos; }
  texto(e: string) { return TEXTO[e] ?? e; }
}