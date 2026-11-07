import { HttpClient } from '@angular/common/http';
import { Injectable, inject, signal } from '@angular/core';
import { Router } from '@angular/router';
import { tap } from 'rxjs';
import { API_URL } from '../config';
import { Rol, Sesion } from '../models';

const KEY = 'barbacoa_sesion';

@Injectable({ providedIn: 'root' })
export class AuthService {
  private http = inject(HttpClient);
  private router = inject(Router);

  sesion = signal<Sesion | null>(this.leer());

  get token(): string | null { return this.sesion()?.token ?? null; }

  login(username: string, password: string) {
    return this.http.post<Sesion>(`${API_URL}/auth/login`, { username, password }).pipe(
      tap(s => {
        localStorage.setItem(KEY, JSON.stringify(s));
        this.sesion.set(s);
      }));
  }

  logout() {
    localStorage.removeItem(KEY);
    this.sesion.set(null);
    this.router.navigate(['/login']);
  }

  rutaInicial(rol: Rol): string {
    return rol === 'ADMIN' ? '/admin' : rol === 'COCINA' ? '/cocina' : '/mesero';
  }

  private leer(): Sesion | null {
    try { return JSON.parse(localStorage.getItem(KEY) ?? 'null'); } catch { return null; }
  }
}
