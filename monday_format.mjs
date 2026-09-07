// Lee el BODY JSON de Monday por stdin, arma el reporte COMPLETO (determinista).
// El nombre del saludo viene en la env var NAME. Imprime el mensaje final listo para enviar.
import fs from 'node:fs';

const NAME = process.env.NAME || 'Andrés';
const raw = fs.readFileSync(0, 'utf8');
const d = JSON.parse(raw);
const groups = d?.data?.boards?.[0]?.groups;
if (!Array.isArray(groups) || groups.length === 0) {
  process.stderr.write('NO_GROUPS');
  process.exit(2);
}

// Fecha de AYER en America/New_York (aritmética por fecha, robusta a DST)
const todayNY = new Intl.DateTimeFormat('en-CA', {
  timeZone: 'America/New_York', year: 'numeric', month: '2-digit', day: '2-digit',
}).format(new Date());
const [Y, M, D] = todayNY.split('-').map(Number);
const yDate = new Date(Date.UTC(Y, M - 1, D));
yDate.setUTCDate(yDate.getUTCDate() - 1);
const yest = yDate.toISOString().slice(0, 10); // YYYY-MM-DD

// Fecha de ayer en español, sin coma: "sábado 5 de septiembre de 2026"
const spa = new Intl.DateTimeFormat('es-ES', {
  timeZone: 'UTC', weekday: 'long', day: 'numeric', month: 'long', year: 'numeric',
}).format(yDate).replace(',', '');

const COL = {
  gen: 'Leads Link Verificacion',
  apr: 'Leads Pre-aprobados',
  den: 'Leads Pre-denegados',
  date: 'Date',
};
const num = (t) => { const n = parseFloat(String(t ?? '').replace(',', '.')); return Number.isFinite(n) ? n : 0; };
const pct = (a, b) => (b > 0 ? (a / b * 100) : 0).toFixed(1);

const blocks = groups.map((g) => {
  const items = (g.items_page?.items || []).filter((it) => {
    const cv = it.column_values || [];
    const dcell = cv.find((c) => c.column?.title === COL.date);
    return (dcell?.text || '') === yest;
  });
  const head = `📋 *Campaña ${g.title}*`;
  if (items.length === 0) return `${head}\n⚫ Campaña apagada`;
  let gen = 0, apr = 0, den = 0;
  for (const it of items) {
    for (const c of (it.column_values || [])) {
      const t = c.column?.title;
      if (t === COL.gen) gen += num(c.text);
      else if (t === COL.apr) apr += num(c.text);
      else if (t === COL.den) den += num(c.text);
    }
  }
  return [
    head,
    `📊 Leads Generados: ${gen}`,
    `✅ Leads Aprobados: ${apr}`,
    `❌ Leads Denegados: ${den}`,
    `💚 % Aprobación: ${pct(apr, gen)}%`,
    `📉 % Rechazo: ${pct(den, gen)}%`,
  ].join('\n');
});

const msg = `Hola ${NAME}, este es el reporte del progreso de los leads de todas tus campañas del ${spa}:\n\n${blocks.join('\n\n')}`;
process.stdout.write(msg);
