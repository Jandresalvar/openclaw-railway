#!/bin/sh
# Reporte diario Monday - TODO deterministico aqui. Uso: monday_report.sh "<Nombre saludo>"
# Fetch dinamico de todos los grupos "/ Mes Actual", calcula y arma el reporte COMPLETO.
# Imprime "HTTP_CODE=<code>" y, si 200, el mensaje final listo (Haiku solo lo relaya).
NAME="${1:-Andrés}"
BOARD=9726722624
COLS='[\"date_mkzd7g01\", \"text_mkzdyt0s\", \"text_mktdwrqa\", \"text_mktd5pkn\"]'
DIR=$(dirname "$0")

# 1) Listar todos los grupos (respuesta minuscula: solo id+title)
ALL=$(curl -s -w "\n%{http_code}" -X POST https://api.monday.com/v2 -H "Authorization: $MONDAY_API_KEY" -H "Content-Type: application/json" -d "{\"query\": \"{ boards(ids: [$BOARD]) { groups { id title } } }\"}")
CODE1=$(printf '%s' "$ALL" | tail -1)
LIST=$(printf '%s' "$ALL" | sed '$d')

# 2) node filtra los grupos "/ Mes Actual" y arma la lista de IDs (comillas escapadas para el JSON)
IDS=$(printf '%s' "$LIST" | node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>{try{const d=JSON.parse(s);const ids=d.data.boards[0].groups.filter(g=>g.title.trim().endsWith("/ Mes Actual")).map(g=>"\\\""+g.id+"\\\"").join(", ");process.stdout.write(ids);}catch(e){}});')

if [ "$CODE1" != "200" ] || [ -z "$IDS" ]; then
  echo "HTTP_CODE=$CODE1"
  echo "ERROR: no se pudieron resolver los grupos Mes Actual"
  exit 0
fi

# 3) Query acotada a esos grupos + 4 columnas
RESP=$(curl -s -w "\n%{http_code}" -X POST https://api.monday.com/v2 -H "Authorization: $MONDAY_API_KEY" -H "Content-Type: application/json" -d "{\"query\": \"{ boards(ids: [$BOARD]) { groups(ids: [$IDS]) { id title items_page(limit: 50) { items { name column_values(ids: $COLS) { text column { title } } } } } } }\"}")
CODE2=$(printf '%s' "$RESP" | tail -1)
BODY=$(printf '%s' "$RESP" | sed '$d')

if [ "$CODE2" != "200" ] || [ -z "$BODY" ] || printf '%s' "$BODY" | grep -q '"errors"'; then
  echo "HTTP_CODE=$CODE2"
  echo "ERROR: la consulta de datos fallo"
  exit 0
fi

# 4) node calcula y arma el reporte COMPLETO (fecha ayer NY, filtrado, sumas, %). Haiku solo lo relaya.
OUT=$(printf '%s' "$BODY" | NAME="$NAME" node "$DIR/monday_format.mjs" 2>/dev/null)
if [ -z "$OUT" ]; then
  echo "HTTP_CODE=500"
  echo "ERROR: no se pudo formatear el reporte"
  exit 0
fi
echo "HTTP_CODE=200"
printf '%s\n' "$OUT"
