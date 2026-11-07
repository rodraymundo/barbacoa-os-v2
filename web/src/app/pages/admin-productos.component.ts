import { CurrencyPipe } from '@angular/common';
import { Component, OnInit, inject } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { ApiService } from '../core/api.service';
import { Producto } from '../models';

const VACIO: Producto = { nombre: '', descripcion: '', precio: 0, categoria: '', disponible: true };

@Component({
  selector: 'app-admin-productos',
  standalone: true,
  imports: [FormsModule, CurrencyPipe],
  template: `
    <div class="cabecera">
      <h1>Productos</h1>
      <button class="btn" (click)="nuevo()">Nuevo producto</button>
    </div>

    @if (editando) {
      <form class="card form" (ngSubmit)="guardar()" #f="ngForm">
        <h3>{{ editando.id ? 'Editar producto' : 'Nuevo producto' }}</h3>
        <div class="fila">
          <div class="campo"><label for="n">Nombre</label><input id="n" name="n" [(ngModel)]="editando.nombre" required></div>
          <div class="campo"><label for="c">Categoría</label>
            <input id="c" name="c" [(ngModel)]="editando.categoria" required list="cats"></div>
          <div class="campo"><label for="p">Precio (MXN)</label>
            <input id="p" name="p" type="number" min="0" step="0.5" [(ngModel)]="editando.precio" required></div>
        </div>
        <div class="campo"><label for="d">Descripción</label><input id="d" name="d" [(ngModel)]="editando.descripcion"></div>
        <label class="check"><input type="checkbox" name="disp" [(ngModel)]="editando.disponible"> Disponible en el menú</label>
        <datalist id="cats">@for (c of categorias; track c) { <option [value]="c"></option> }</datalist>
        @if (error) { <p class="error">{{ error }}</p> }
        <div class="acciones">
          <button class="btn" [disabled]="f.invalid">Guardar cambios</button>
          <button type="button" class="btn ghost" (click)="editando = null">Cancelar</button>
        </div>
      </form>
    }

    <div class="card">
      <table>
        <thead><tr><th>Producto</th><th>Categoría</th><th>Precio</th><th>Estado</th><th></th></tr></thead>
        <tbody>
          @for (p of productos; track p.id) {
            <tr>
              <td><strong>{{ p.nombre }}</strong><br><small>{{ p.descripcion }}</small></td>
              <td>{{ p.categoria }}</td>
              <td>{{ p.precio | currency:'MXN':'symbol-narrow' }}</td>
              <td><span class="etiqueta" [class.ok]="p.disponible" [class.off]="!p.disponible">{{ p.disponible ? 'Disponible' : 'Agotado' }}</span></td>
              <td class="der">
                <button class="btn chico ghost" (click)="editar(p)">Editar</button>
                <button class="btn chico ghost" (click)="alternar(p)">{{ p.disponible ? 'Marcar agotado' : 'Marcar disponible' }}</button>
              </td>
            </tr>
          } @empty { <tr><td colspan="5">Todavía no hay productos. Crea el primero con “Nuevo producto”.</td></tr> }
        </tbody>
      </table>
    </div>
  `,
  styles: [`
    .cabecera { display: flex; justify-content: space-between; align-items: center; margin-bottom: 14px; }
    .cabecera h1 { margin: 0; }
    .form { margin-bottom: 16px; }
    .fila { display: grid; grid-template-columns: 2fr 1fr 1fr; gap: 12px; }
    .check { display: flex; align-items: center; gap: 8px; color: var(--texto); }
    .check input { width: auto; }
    .acciones { display: flex; gap: 8px; margin-top: 10px; }
    small { color: var(--suave); }
    .der { text-align: right; white-space: nowrap; }
    .der .btn { margin-left: 6px; }
    @media (max-width: 700px) { .fila { grid-template-columns: 1fr; } }
  `]
})
export class AdminProductosComponent implements OnInit {
  private api = inject(ApiService);
  productos: Producto[] = [];
  categorias: string[] = [];
  editando: Producto | null = null;
  error = '';

  ngOnInit() { this.cargar(); }

  cargar() {
    this.api.productos().subscribe(ps => {
      this.productos = ps;
      this.categorias = [...new Set(ps.map(p => p.categoria))];
    });
  }

  nuevo() { this.editando = { ...VACIO }; this.error = ''; }
  editar(p: Producto) { this.editando = { ...p }; this.error = ''; }

  guardar() {
    const p = this.editando!;
    const peticion = p.id ? this.api.actualizarProducto(p.id, p) : this.api.crearProducto(p);
    peticion.subscribe({
      next: () => { this.editando = null; this.cargar(); },
      error: e => this.error = e.error?.error ?? 'No se pudo guardar el producto'
    });
  }

  alternar(p: Producto) {
    this.api.actualizarProducto(p.id!, { ...p, disponible: !p.disponible }).subscribe(() => this.cargar());
  }
}
