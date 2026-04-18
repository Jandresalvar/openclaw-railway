#!/bin/sh
set -e
# Fix volume permissions at runtime before starting gateway
mkdir -p /home/node/.openclaw
chown -R node:node /home/node/.openclaw
exec su -s /bin/sh node -c 'cd /app && exec node openclaw.mjs gateway --allow-unconfigured'
