import { CurrencyPipe } from '@angular/common';
import { AfterViewInit, Component, ElementRef, OnDestroy, ViewChild, inject } from '@angular/core';
import { Chart, registerables } from 'chart.js';
import { ApiService } from '../core/api.service';
import { Resumen } from '../models';

Chart.register(...registerables);

@Component({
  selector: 'app-admin-dashboard',
  standalone: true,
  imports: [CurrencyPipe],
  template: `
    <h1>Dashboard</h1>
    <section class="kpis">
      <div class="card kpi"><span>Ventas de hoy</span><strong>{{ r?.ventasHoy ?? 0 | currency:'MXN':'symbol-narrow' }}</strong></div>
      <div class="card kpi"><span>Pedidos de hoy</span><strong>{{ r?.pedidosHoy ?? 0 }}</strong></div>
      <div class="card kpi"><span>Ticket promedio</span><strong>{{ r?.ticketPromedio ?? 0 | currency:'MXN':'symbol-narrow' }}</strong></div>
      <div class="card kpi"><span>Pedidos activos ahora</span><strong>{{ r?.pedidosActivos ?? 0 }}</strong></div>
    </section>
    @if (error) { <p class="error">{{ error }}</p> }
    <section class="graficas">
      <div class="card ancha"><h3>Ventas de los últimos 7 días</h3><div class="caja"><canvas #ventas></canvas></div></div>
      <div class="card"><h3>Pedidos por estado (7 días)</h3><div class="caja"><canvas #estados></canvas></div></div>
      <div class="card"><h3>Productos más vendidos</h3><div class="caja"><canvas #top></canvas></div></div>
    </section>
  `,
  styles: [`
    .kpis { display: grid; grid-template-columns: repeat(auto-fit, minmax(190px, 1fr)); gap: 14px; margin-bottom: 18px; }
    .kpi span { display: block; color: var(--suave); font-size: .85rem; }
    .kpi strong { font-size: 1.8rem; }
    .graficas { display: grid; grid-template-columns: repeat(2, 1fr); gap: 16px; }
    .ancha { grid-column: 1 / -1; }
    .caja { position: relative; height: 280px; }
    @media (max-width: 800px) { .graficas { grid-template-columns: 1fr; } }
  `]
})
export class AdminDashboardComponent implements AfterViewInit, OnDestroy {
  private api = inject(ApiService);
  @ViewChild('ventas') ventas!: ElementRef<HTMLCanvasElement>;
  @ViewChild('estados') estados!: ElementRef<HTMLCanvasElement>;
  @ViewChild('top') top!: ElementRef<HTMLCanvasElement>;

  r?: Resumen;
  error = '';
  private charts: Chart[] = [];
  private timer?: ReturnType<typeof setInterval>;

  ngAfterViewInit() {
    this.cargar();
    this.timer = setInterval(() => this.cargar(), 15000);
  }

  ngOnDestroy() {
    clearInterval(this.timer);
    this.charts.forEach(c => c.destroy());
  }

  private cargar() {
    this.api.dashboard().subscribe({
      next: r => { this.r = r; this.error = ''; this.pintar(r); },
      error: () => this.error = 'No se pudo cargar el resumen'
    });
  }

  private pintar(r: Resumen) {
    const dias = r.ventasPorDia.map(v => v.fecha.slice(5));
    const ventas = r.ventasPorDia.map(v => v.total);
    const estadosEt = Object.keys(r.pedidosPorEstado);
    const estadosVal = Object.values(r.pedidosPorEstado);
    const topEt = r.topProductos.map(t => t.nombre);
    const topVal = r.topProductos.map(t => t.cantidad);

    if (this.charts.length) {
      const datos = [[dias, ventas], [estadosEt, estadosVal], [topEt, topVal]];
      this.charts.forEach((c, i) => {
        c.data.labels = datos[i][0];
        c.data.datasets[0].data = datos[i][1] as number[];
        c.update('none');
      });
      return;
    }
    const opciones = { responsive: true, maintainAspectRatio: false };
    this.charts = [
      new Chart(this.ventas.nativeElement, {
        type: 'bar',
        data: { labels: dias, datasets: [{ label: 'Ventas ($)', data: ventas, backgroundColor: '#7a1c24' }] },
        options: { ...opciones, plugins: { legend: { display: false } } }
      }),
      new Chart(this.estados.nativeElement, {
        type: 'doughnut',
        data: { labels: estadosEt, datasets: [{ data: estadosVal,
          backgroundColor: ['#bbb', '#f2b632', '#e67e22', '#2e7d4f', '#7a1c24', '#6d6560'] }] },
        options: opciones
      }),
      new Chart(this.top.nativeElement, {
        type: 'bar',
        data: { labels: topEt, datasets: [{ label: 'Unidades', data: topVal, backgroundColor: '#f2b632' }] },
        options: { ...opciones, indexAxis: 'y', plugins: { legend: { display: false } } }
      })
    ];
  }
}
