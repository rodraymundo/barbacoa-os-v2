import { inject } from '@angular/core';
import { CanActivateFn, Router } from '@angular/router';
import { Rol } from '../models';
import { AuthService } from './auth.service';

export const rolGuard: CanActivateFn = route => {
  const auth = inject(AuthService);
  const router = inject(Router);
  const s = auth.sesion();
  if (!s) return router.parseUrl('/login');
  const roles = route.data['roles'] as Rol[] | undefined;
  if (roles && !roles.includes(s.rol)) return router.parseUrl(auth.rutaInicial(s.rol));
  return true;
};
