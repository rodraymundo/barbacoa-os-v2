import { Routes } from '@angular/router';
import { rolGuard } from './core/rol.guard';
import { AdminDashboardComponent } from './pages/admin-dashboard.component';
import { AdminMesasComponent } from './pages/admin-mesas.component';
import { AdminProductosComponent } from './pages/admin-productos.component';
import { CocinaComponent } from './pages/cocina.component';
import { LoginComponent } from './pages/login.component';
import { MeseroComponent } from './pages/mesero.component';
import { HistorialComponent } from './pages/historial.component';
import { SoporteComponent } from './pages/soporte.component';

export const routes: Routes = [
  { path: 'login', component: LoginComponent },
  {
    path: 'admin', canActivate: [rolGuard], data: { roles: ['ADMIN'] },
    children: [
      { path: '', component: AdminDashboardComponent },
      { path: 'productos', component: AdminProductosComponent },
      { path: 'mesas', component: AdminMesasComponent }
    ]
  },
  { path: 'cocina', component: CocinaComponent, canActivate: [rolGuard], data: { roles: ['COCINA', 'ADMIN'] } },
  { path: 'mesero', component: MeseroComponent, canActivate: [rolGuard], data: { roles: ['MESERO', 'ADMIN'] } },
  { path: 'historial', component: HistorialComponent, canActivate: [rolGuard], data: { roles: ['MESERO', 'ADMIN'] } },
  { path: 'soporte', component: SoporteComponent, canActivate: [rolGuard] },
  { path: '', pathMatch: 'full', redirectTo: 'login' },
  { path: '**', redirectTo: 'login' }
];
