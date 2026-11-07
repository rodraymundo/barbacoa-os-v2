import { CurrencyPipe } from '@angular/common';
import { Component, OnDestroy, OnInit, inject } from '@angular/core';
import { ApiService } from '../core/api.service';
import { EstadoPedido, Mesa, Pedido, Producto } from '../models';

const TEXTO: Record<string, string> = {
  ABIERTO: 'Armando orden', PENDIENTE: 'En cocina', EN_PREPARACION: 'Preparando', LISTO: 'Lista para entregar'
};

@Component({
  selector: 'app-mesero',
  standalone: true,
  imports: [CurrencyPipe],
  template: `
    <h1>Mesero</h1>
    @if (error) { <p class="error" role="alert">{{ error }}</p> }
    <div class="layout">
      <section>
        <h3>Mesas</h3>
        <div class="mesas">
          @for (m of mesas; track m.id) {
            <button class="mesa" [class]="claseMesa(m)" [class.sel]="sel?.mesaId === m.id" (click)="abrir(m)">
              <strong>{{ m.numero }}</strong>
              <small>{{ textoMesa(m) }}</small>
            </button>
          }
        </div>
        <p class="ayuda">Toca una mesa libre para abrir su orden. En la app móvil esto se hace escaneando el QR.</p>
      </section>

      <section>
        <h3>Menú</h3>
        @if (!sel) { <p class="ayuda">Elige una mesa para empezar a tomar la orden.</p> }
        @else if (sel.estado !== 'ABIERTO' && sel.estado !== 'PENDIENTE') { <p class="ayuda">Esta orden ya está en preparación.</p> }
        @else {
          @for (g of grupos; track g.nombre) {
            <h4>{{ g.nombre }}</h4>
            <div class="productos">
              @for (p of g.items; track p.id) {
                <button class="card prod" (click)="agregar(p)">
                  <span>{{ p.nombre }}</span><b>{{ p.precio | currency:'MXN':'symbol-narrow' }}</b>
                </button>
              }
            </div>
          }
        }
      </section>

      <section>
        <h3>Orden @if (sel) { · Mesa {{ sel.mesaNumero }} }</h3>
        @if (sel) {
          <div class="card orden">
            <span class="etiqueta">{{ texto(sel.estado) }}</span>
            <ul>
              @for (i of sel.items; track i.id) {
                <li>
                  <span><b>{{ i.cantidad }}×</b> {{ i.productoNombre }}</span>
                  <span>{{ i.subtotal | currency:'MXN':'symbol-narrow' }}
                    @if (sel.estado === 'ABIERTO') { <button class="x" (click)="quitar(i.id)" aria-label="Quitar">✕</button> }
                  </span>
                </li>
              } @empty { <li class="ayuda">Aún no hay productos</li> }
            </ul>
            <p class="total">Total: <strong>{{ sel.total | currency:'MXN':'symbol-narrow' }}</strong></p>
            @if (sel.estado === 'ABIERTO') {
              <button class="btn" style="width:100%" [disabled]="!sel.items.length" (click)="cambiar('PENDIENTE')">Enviar a cocina</button>
            }
            @if (sel.estado === 'LISTO') {
              <button class="btn ambar" style="width:100%" (click)="cambiar('ENTREGADO')">Marcar como entregado</button>
            }
            @if (sel.estado === 'ABIERTO' || sel.estado === 'PENDIENTE') {
              <button class="btn ghost chico" style="margin-top:8px" (click)="cambiar('CANCELADO')">Cancelar orden</button>
            }
          </div>
        }
      </section>
    </div>
  `,
  styles: [`
    .layout { display: grid; grid-template-columns: 240px 1fr 330px; gap: 20px; align-items: start; }
    .mesas { display: grid; grid-template-columns: repeat(3, 1fr); gap: 8px; }
    .mesa { border: 2px solid var(--borde); background: #fff; border-radius: 10px; padding: 10px 4px; cursor: pointer; font: inherit; }
    .mesa strong { display: block; font-size: 1.4rem; } .mesa small { color: var(--suave); }
    .mesa.libre { border-color: #b7dcc3; } .mesa.ocupada { background: #fbefd0; border-color: var(--ambar); }
    .mesa.lista { background: #dff3e6; border-color: var(--ok); }
    .mesa.sel { outline: 3px solid var(--vino); }
    h4 { margin: 14px 0 6px; color: var(--vino); }
    .productos { display: grid; grid-template-columns: repeat(auto-fill, minmax(150px, 1fr)); gap: 8px; }
    .prod { display: flex; flex-direction: column; gap: 4px; text-align: left; cursor: pointer; font: inherit; }
    .prod:hover { border-color: var(--vino); }
    .orden ul { list-style: none; padding: 0; margin: 10px 0; }
    .orden li { display: flex; justify-content: space-between; padding: 6px 0; border-bottom: 1px solid var(--borde); }
    .x { border: 0; background: none; color: var(--alerta); cursor: pointer; margin-left: 6px; }
    .total { font-size: 1.1rem; text-align: right; }
    .ayuda { color: var(--suave); font-size: .9rem; }
    @media (max-width: 1000px) { .layout { grid-template-columns: 1fr; } }
  `]
})
export class MeseroComponent implements OnInit, OnDestroy {
  private api = inject(ApiService);
  mesas: Mesa[] = [];
  productos: Producto[] = [];
  grupos: { nombre: string; items: Producto[] }[] = [];
  activos: Pedido[] = [];
  sel: Pedido | null = null;
  error = '';
  private timer?: ReturnType<typeof setInterval>;

  ngOnInit() {
    this.api.productos().subscribe(ps => {
      this.productos = ps;
      const mapa = new Map<string, Producto[]>();
      ps.forEach(p => mapa.set(p.categoria, [...(mapa.get(p.categoria) ?? []), p]));
      this.grupos = [...mapa].map(([nombre, items]) => ({ nombre, items }));
    });
    this.refrescar();
    this.timer = setInterval(() => this.refrescar(), 5000);
  }
  ngOnDestroy() { clearInterval(this.timer); }

  refrescar() {
    this.api.mesas().subscribe(ms => this.mesas = ms);
    this.api.pedidos(['ABIERTO', 'PENDIENTE', 'EN_PREPARACION', 'LISTO']).subscribe({
      next: ps => {
        this.activos = ps;
        if (this.sel) this.sel = ps.find(p => p.id === this.sel!.id) ?? null;
      },
      error: () => this.error = 'Sin conexión con el servidor'
    });
  }

  texto(estado: EstadoPedido) { return TEXTO[estado] ?? estado; }
  pedidoDe(m: Mesa) { return this.activos.find(p => p.mesaId === m.id); }
  claseMesa(m: Mesa) {
    const p = this.pedidoDe(m);
    return !p ? 'libre' : p.estado === 'LISTO' ? 'lista' : 'ocupada';
  }
  textoMesa(m: Mesa) { const p = this.pedidoDe(m); return p ? this.texto(p.estado) : 'Libre'; }

  abrir(m: Mesa) {
    this.error = '';
    this.api.abrirPedido(m.id).subscribe({
      next: p => { this.sel = p; this.refrescar(); },
      error: e => this.error = e.error?.error ?? 'No se pudo abrir la orden'
    });
  }

  agregar(p: Producto) {
    if (!this.sel) return;
    this.api.agregarItem(this.sel.id, p.id!).subscribe({
      next: ped => this.sel = ped,
      error: e => this.error = e.error?.error ?? 'No se pudo agregar'
    });
  }

  quitar(itemId: number) {
    this.api.quitarItem(this.sel!.id, itemId).subscribe(ped => this.sel = ped);
  }

  cambiar(estado: EstadoPedido) {
    this.error = '';
    this.api.cambiarEstado(this.sel!.id, estado).subscribe({
      next: ped => {
        this.sel = (estado === 'ENTREGADO' || estado === 'CANCELADO') ? null : ped;
        this.refrescar();
      },
      error: e => this.error = e.error?.error ?? 'No se pudo cambiar el estado'
    });
  }
}
