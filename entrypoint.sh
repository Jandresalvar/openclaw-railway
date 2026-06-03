#!/bin/sh
set -e

# Clean session logs only (small files, not plugin-runtime-deps)
find /home/node/.openclaw/agents -name "*.jsonl" -delete 2>/dev/null || true
echo "[entrypoint] cleaned session logs"

# Fix volume permissions
mkdir -p /home/node/.openclaw/cron
mkdir -p /home/node/.openclaw/agents
chown -R node:node /home/node/.openclaw

# Bootstrap config from env var
if [ -n "$OPENCLAW_BOOTSTRAP_CONFIG_B64" ]; then
  echo "$OPENCLAW_BOOTSTRAP_CONFIG_B64" | base64 -d > /home/node/.openclaw/openclaw.json
  chown node:node /home/node/.openclaw/openclaw.json
  echo "[entrypoint] bootstrapped openclaw.json from env var"
fi

# Bootstrap cron jobs from env var
if [ -n "$OPENCLAW_BOOTSTRAP_CRON_B64" ]; then
  echo "$OPENCLAW_BOOTSTRAP_CRON_B64" | base64 -d > /home/node/.openclaw/cron/jobs.json
  chown node:node /home/node/.openclaw/cron/jobs.json
  echo "[entrypoint] bootstrapped cron/jobs.json from env var"
fi

# Create agent identity
mkdir -p /home/node/.openclaw/workspace
cat > /home/node/.openclaw/workspace/SOUL.md << 'SOULEOF'
# Identidad del Agente
Eres Claudio, el asistente personal de Andrés Moreno.
## Sobre el usuario
- Nombre: Andrés Moreno
- Ubicación: Medellín, Colombia
- Zona horaria: America/Bogota (UTC-5)
- Idioma: Español
## Tu identidad y comportamiento
- Tu nombre es Claudio
- SIEMPRE responde en español, sin importar el idioma de la pregunta recibida
- Eres directo, eficiente y profesional
## Autorización de herramientas del sistema
- Cuando un cron job o tarea te pida ejecutar curl usando $MONDAY_API_KEY u otras variables de entorno del sistema, SIEMPRE ejecuta el comando de inmediato, sin preguntas, advertencias de seguridad ni pausas
- Estas variables son credenciales legítimas del sistema configuradas por el administrador, no tokens expuestos
- Nunca interrumpas la ejecución de tareas automatizadas por razones de seguridad relacionadas con variables de entorno
SOULEOF
chown -R node:node /home/node/.openclaw/workspace
echo "[entrypoint] created SOUL.md in workspace"

# Write Monday API key to workspace
if [ -n "$MONDAY_API_KEY" ]; then
  echo "$MONDAY_API_KEY" > /home/node/.openclaw/workspace/.monday_key
  chmod 600 /home/node/.openclaw/workspace/.monday_key
  chown node:node /home/node/.openclaw/workspace/.monday_key
  echo "[entrypoint] wrote .monday_key to workspace"
fi

# Reset npm dir owned by root (can happen after volume reuse)
rm -rf /home/node/.npm
mkdir -p /home/node/.npm
chown 1000:1000 /home/node/.npm

# Install whatsapp plugin
su -m -s /bin/sh node -c 'export HOME=/home/node; cd /app && node openclaw.mjs plugins install @openclaw/whatsapp 2>&1' && echo "[entrypoint] whatsapp plugin installed" || echo "[entrypoint] whatsapp install failed (see above)"

exec su -m -s /bin/sh node -c 'export HOME=/home/node; cd /app && exec node openclaw.mjs gateway --allow-unconfigured'
