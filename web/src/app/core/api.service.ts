import { HttpClient, HttpParams } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';
import { API_URL } from '../config';
import { EstadoPedido, Mesa, Pedido, Producto, Resumen } from '../models';

@Injectable({ providedIn: 'root' })
export class ApiService {
  private http = inject(HttpClient);

  // productos
  productos() { return this.http.get<Producto[]>(`${API_URL}/productos`); }
  crearProducto(p: Producto) { return this.http.post<Producto>(`${API_URL}/productos`, p); }
  actualizarProducto(id: number, p: Producto) { return this.http.put<Producto>(`${API_URL}/productos/${id}`, p); }

  // mesas
  mesas() { return this.http.get<Mesa[]>(`${API_URL}/mesas`); }
  crearMesa(numero: number) { return this.http.post<Mesa>(`${API_URL}/mesas`, { numero }); }

  // pedidos
  pedidos(estados?: EstadoPedido[]) {
    let params = new HttpParams();
    if (estados?.length) params = params.set('estados', estados.join(','));
    return this.http.get<Pedido[]>(`${API_URL}/pedidos`, { params });
  }
  abrirPedido(mesaId: number) { return this.http.post<Pedido>(`${API_URL}/pedidos`, { mesaId }); }
  agregarItem(id: number, productoId: number, cantidad = 1) {
    return this.http.post<Pedido>(`${API_URL}/pedidos/${id}/items`, { productoId, cantidad });
  }
  quitarItem(id: number, itemId: number) { return this.http.delete<Pedido>(`${API_URL}/pedidos/${id}/items/${itemId}`); }
  cambiarEstado(id: number, estado: EstadoPedido) {
    return this.http.patch<Pedido>(`${API_URL}/pedidos/${id}/estado`, { estado });
  }

  // dashboard
  dashboard() { return this.http.get<Resumen>(`${API_URL}/dashboard`); }
}
