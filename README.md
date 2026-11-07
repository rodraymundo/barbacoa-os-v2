# Barbacoa OS

Sistema para restaurante de barbacoa, reconstruido desde cero con tres piezas que comparten la misma API:

```
 Angular (web)  ──┐
  admin · cocina · mesero      ├── HTTP/JSON + JWT ──►  Spring Boot  ──►  Base de datos
 Flutter (móvil) ─┘                                      (backend)        (H2 / MySQL)
  solo mesero: escanea QR de mesa
```

| Carpeta    | Qué es                                   | Puerto / comando                              |
|------------|------------------------------------------|-----------------------------------------------|
| `backend/` | API REST Spring Boot 3 (Java 17) + JWT   | `mvn spring-boot:run` → http://localhost:8080 |
| `web/`     | Angular 18 (admin, cocina, mesero)       | `npm start` → http://localhost:4200           |
| `mobile/`  | Flutter (app del mesero con escáner QR)  | ver `mobile/ANDROID_SETUP.md`                 |

## Cómo correrlo (en este orden)

**1. Backend** (JDK 17 y Maven):
```
cd backend
mvn spring-boot:run
```
La primera vez crea la base de datos (H2, archivo en `backend/data/`) y carga usuarios, 8 mesas, 12 productos y una semana de ventas de ejemplo para las gráficas. Para usar MySQL: `mvn spring-boot:run -Dspring-boot.run.profiles=mysql`.

**2. Web** (Node 18.19+ o 20):
```
cd web
npm install
npm start
```

**3. Móvil**: sigue `mobile/ANDROID_SETUP.md` (crear proyecto con `flutter create`, permisos y `--dart-define=API_URL=...`).

## Usuarios de prueba

| Usuario  | Contraseña  | Rol    | Entra a                                |
|----------|-------------|--------|----------------------------------------|
| `admin`  | `admin123`  | ADMIN  | Dashboard, productos, mesas y QR (+ cocina y mesero) |
| `cocina` | `cocina123` | COCINA | Tablero de cocina                      |
| `mesero` | `mesero123` | MESERO | Toma de órdenes (web y móvil)          |

Cámbialas antes de publicar nada: son de demostración.

## Flujo completo para probar

1. Entra como **admin** en la web → *Mesas y QR* → imprime o muestra en pantalla el QR de la mesa 1 (contiene el texto `BARBACOA-MESA-1`).
2. En la **app móvil** entra como `mesero`, toca el botón flotante central y escanea ese QR. El servidor crea la orden de la mesa 1 automáticamente (si ya había una abierta, devuelve esa).
3. Agrega productos con “+” y toca **Enviar a cocina**.
4. En la web, como **cocina**, aparece el pedido (se actualiza solo cada 5 s): *Empezar a preparar* → *Marcar como listo*.
5. En el móvil, el mesero actualiza el estado (botón de refrescar), ve **Lista para entregar** y toca *Marcar entregado*. La mesa queda libre y la venta cuenta en el dashboard del admin.

Estados de un pedido: `ABIERTO → PENDIENTE → EN_PREPARACION → LISTO → ENTREGADO` (o `CANCELADO` desde ABIERTO/PENDIENTE). Las reglas de quién puede hacer cada cambio viven en el backend (`PedidoService.permitido`), no en los clientes.

## API

| Método y ruta                         | Rol                 | Descripción |
|---------------------------------------|---------------------|-------------|
| `POST /api/auth/login`                | público             | Devuelve `token`, `nombre`, `rol` |
| `GET /api/productos`                  | cualquiera          | Menú (admin ve también los agotados) |
| `POST /api/productos` · `PUT /api/productos/{id}` | ADMIN | Crear / editar (incluye `disponible`) |
| `GET /api/mesas` · `GET /api/mesas/qr/{codigo}` | cualquiera | Lista y búsqueda por QR |
| `POST /api/mesas`                     | ADMIN               | Crea la mesa y su código QR |
| `POST /api/pedidos`                   | MESERO, ADMIN       | Abre la orden: `{"codigoQr":"..."}` (móvil) o `{"mesaId":1}` (web) |
| `GET /api/pedidos?estados=PENDIENTE,LISTO` | cualquiera     | Lista filtrada por estado |
| `POST /api/pedidos/{id}/items` · `DELETE /api/pedidos/{id}/items/{itemId}` | MESERO, ADMIN | Agregar / quitar productos |
| `PATCH /api/pedidos/{id}/estado`      | según rol           | `{"estado":"LISTO"}` |
| `GET /api/dashboard`                  | ADMIN               | KPIs y datos de las gráficas |

Los errores llegan como `{"error": "mensaje"}` con el código HTTP correspondiente.

## Cómo encaja con tu documento (Entregable 2)

- **Consumo de la API REST**: `mobile/lib/services/api_service.dart` (único punto de contacto con Spring Boot, con manejo de timeout, red caída y 401).
- **Lógica de negocio**: crear orden por QR, agregar productos, cambiar estados y liberar mesa (`order_provider.dart` en el móvil; reglas en `PedidoService` del backend).
- **Manejo de estados con Provider**: `AuthProvider` y `OrderProvider`.
- **Práctica 5 (código seguro)**: `login_screen.dart` valida campos vacíos, usa `obscureText`, muestra mensajes genéricos y no imprime credenciales en consola. En el servidor: contraseñas con BCrypt, JWT con expiración y roles verificados en cada endpoint.
- **Práctica 6 (Mesero ↔ Cocina)**: el mesero (dispositivo A) envía con *Enviar a cocina*; el servidor Spring Boot es el intermediario y la cocina (dispositivo B, web) lo ve en ≤5 s por sondeo periódico.
- **Diseño Americano**: `home_screen.dart` (AppBar + BottomAppBar con FAB central, sin Drawers).
- **Persistencia local**: el JWT se guarda en SharedPreferences.

## Decisiones y límites (para ser honestos en la entrega)

- La “tiempo real” es **sondeo cada 5 segundos**, no WebSockets. Es simple y confiable; si quieres subir de nivel, el siguiente paso natural es STOMP/WebSocket en Spring.
- No se borran productos: se marcan como *agotado* (así no se rompen ventas pasadas).
- No hay pruebas automáticas ni pagos/cobro; “entregado” cierra la orden y cuenta como venta.
- La web usa CSS propio (sin PrimeNG) para tener menos dependencias que se rompan entre versiones.
- Logo: en la web edita `login.component.ts`; en el móvil copia `assets/logo.png` y descomenta `assets` en `pubspec.yaml`.
- En producción: HTTPS, `JWT_SECRET` propio, MySQL, quitar la consola H2 y `usesCleartextTraffic`.

## Subirlo a tus repos

Como quieres empezar limpio, lo más ordenado es una rama nueva en cada repo (así no pierdes lo anterior):
```
git checkout -b reinicio
# borra el contenido viejo, copia la carpeta correspondiente, y:
git add -A && git commit -m "Reconstrucción desde cero" && git push -u origin reinicio
```
`Barbacoa-Os` ← `backend/` y `web/` · `barbacoa-movil-` ← contenido de `mobile/` (después de `flutter create`).
