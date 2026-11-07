import { Component, OnInit, inject } from '@angular/core';
import { FormsModule } from '@angular/forms';
import QRCode from 'qrcode';
import { ApiService } from '../core/api.service';
import { Mesa } from '../models';

@Component({
  selector: 'app-admin-mesas',
  standalone: true,
  imports: [FormsModule],
  template: `
    <div class="cabecera no-imprimir">
      <h1>Mesas y códigos QR</h1>
      <div class="nueva">
        <input type="number" min="1" placeholder="Número de mesa" [(ngModel)]="numero" aria-label="Número de mesa nueva">
        <button class="btn" (click)="crear()" [disabled]="!numero">Agregar mesa</button>
        <button class="btn ambar" (click)="imprimir()">Imprimir QR</button>
      </div>
    </div>
    @if (error) { <p class="error no-imprimir">{{ error }}</p> }
    <p class="no-imprimir ayuda">Imprime cada código y pégalo en su mesa. El mesero lo escanea desde la app móvil y se abre la orden de esa mesa.</p>
    <div class="mesas">
      @for (m of mesas; track m.id) {
        <figure class="card">
          @if (qrs[m.codigoQr]) { <img [src]="qrs[m.codigoQr]" [alt]="'QR de la mesa ' + m.numero" width="200" height="200"> }
          <figcaption><strong>Mesa {{ m.numero }}</strong><br><small>{{ m.codigoQr }}</small><br>
            <span class="etiqueta no-imprimir" [class.ok]="m.estado === 'LIBRE'">{{ m.estado === 'LIBRE' ? 'Libre' : 'Ocupada' }}</span>
          </figcaption>
        </figure>
      }
    </div>
  `,
  styles: [`
    .cabecera { display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 12px; }
    .nueva { display: flex; gap: 8px; } .nueva input { width: 150px; }
    .ayuda { color: var(--suave); }
    .mesas { display: grid; grid-template-columns: repeat(auto-fill, minmax(230px, 1fr)); gap: 16px; }
    figure { margin: 0; text-align: center; break-inside: avoid; }
    small { color: var(--suave); }
  `]
})
export class AdminMesasComponent implements OnInit {
  private api = inject(ApiService);
  mesas: Mesa[] = [];
  qrs: Record<string, string> = {};
  numero: number | null = null;
  error = '';

  ngOnInit() { this.cargar(); }

  cargar() {
    this.api.mesas().subscribe(async ms => {
      this.mesas = ms;
      for (const m of ms) {
        if (!this.qrs[m.codigoQr]) this.qrs[m.codigoQr] = await QRCode.toDataURL(m.codigoQr, { width: 400, margin: 1 });
      }
    });
  }

  crear() {
    this.error = '';
    this.api.crearMesa(this.numero!).subscribe({
      next: () => { this.numero = null; this.cargar(); },
      error: e => this.error = e.error?.error ?? 'No se pudo crear la mesa'
    });
  }

  imprimir() { window.print(); }
}
