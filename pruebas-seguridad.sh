#!/bin/bash
# Pruebas de seguridad de Barbacoa OS (Practica 10).
# Mandan las operaciones DIRECTO a la API, sin pasar por la app ni la web.
#
# Uso (Git Bash):
#   export API='https://TU-API.onrender.com/api'
#   export PASS_A='clave_de_mesero' PASS_B='clave_de_mesero2' PASS_COCINA='clave_de_cocina'
#   bash pruebas-seguridad.sh
#
# Supuestos: existen las mesas con id 1 y 2, el producto con id 1 y las mesas 1 y 2 estan libres.

API="${API:-http://localhost:8080/api}"
: "${PASS_A:?Define PASS_A}" "${PASS_B:?Define PASS_B}" "${PASS_COCINA:?Define PASS_COCINA}"
FALLAS=0
TMP="$(mktemp)"

# llamar METODO RUTA TOKEN [CUERPO]  ->  deja el codigo HTTP en $CODE y la respuesta en $BODY
llamar() {
  local metodo="$1" ruta="$2" token="$3" cuerpo="$4"
  local args=(-s -o "$TMP" -w '%{http_code}' -X "$metodo" "$API$ruta" -H 'Content-Type: application/json')
  [ -n "$token" ] && args+=(-H "Authorization: Bearer $token")
  [ -n "$cuerpo" ] && args+=(-d "$cuerpo")
  CODE=$(curl "${args[@]}")
  BODY=$(cat "$TMP")
}
login()    { llamar POST /auth/login "" "{\"username\":\"$1\",\"password\":\"$2\"}"; }
token()    { echo "$BODY" | sed -E 's/.*"token" *: *"([^"]+)".*/\1/'; }
idpedido() { echo "$BODY" | sed -E 's/^\{ *"id" *: *([0-9]+).*/\1/'; }
verificar() {   # ID ESPERADO DESCRIPCION
  local r="OK   "
  if [ "$CODE" != "$2" ]; then r="FALLA"; FALLAS=$((FALLAS + 1)); fi
  printf '%-7s esperado=%s obtenido=%s  %s  %s\n' "$1" "$2" "$CODE" "$r" "$3"
}

echo "== Pruebas de seguridad Barbacoa OS =="
echo "API: $API"
echo

login mesero "$PASS_A";           verificar SEG-01 200 "A inicia sesion (mesero)";      TA=$(token)
login mesero2 "$PASS_B";          TB=$(token)
login cocina "$PASS_COCINA";      TC=$(token)
login mesero "clave-incorrecta";  verificar SEG-02 401 "Contrasena incorrecta"

llamar POST /pedidos "$TA" '{"mesaId":1}';  verificar SEG-03 200 "A abre su pedido (mesa 1)"; P1=$(idpedido)
llamar POST /pedidos "$TA" '{"mesaId":2}';  P2=$(idpedido)   # pedido de apoyo para probar cancelar
llamar POST "/pedidos/$P1/items" "$TA" '{"productoId":1,"cantidad":1}'
verificar SEG-04 200 "A agrega un producto a su pedido"

llamar GET "/pedidos/$P1" "$TB";                                   verificar SEG-05 403 "B lee el pedido de A"
llamar POST "/pedidos/$P1/items" "$TB" '{"productoId":1,"cantidad":1}'
verificar SEG-06 403 "B agrega un producto al pedido de A"
llamar PATCH "/pedidos/$P2/estado" "$TB" '{"estado":"CANCELADO"}'; verificar SEG-07 403 "B cancela un pedido de A"
llamar POST /pedidos "$TB" '{"mesaId":1}';                         verificar SEG-08 403 "B abre la mesa 1 (atendida por A)"

llamar GET /pedidos "";                                            verificar SEG-09 401 "Peticion sin token"
llamar GET /dashboard "$TA";                                       verificar SEG-10 403 "Mesero consulta el dashboard (solo ADMIN)"

llamar PATCH "/pedidos/$P1/estado" "$TA" '{"estado":"PENDIENTE"}'  # A envia a cocina (preparacion)
llamar PATCH "/pedidos/$P1/estado" "$TA" '{"estado":"LISTO"}';     verificar SEG-11 403 "Mesero intenta marcar LISTO (accion de cocina)"
llamar PATCH "/pedidos/$P1/estado" "$TC" '{"estado":"EN_PREPARACION"}'
verificar SEG-12 200 "Cocina inicia la preparacion del pedido de A"

# Limpieza (no cuenta como prueba): termina el flujo para dejar las mesas libres
llamar PATCH "/pedidos/$P1/estado" "$TC" '{"estado":"LISTO"}'
llamar PATCH "/pedidos/$P1/estado" "$TA" '{"estado":"ENTREGADO"}'
llamar PATCH "/pedidos/$P2/estado" "$TA" '{"estado":"CANCELADO"}'

echo
if [ "$FALLAS" -eq 0 ]; then echo "Resultado: todas las pruebas pasaron."; else echo "Resultado: $FALLAS prueba(s) con FALLA."; fi
rm -f "$TMP"
