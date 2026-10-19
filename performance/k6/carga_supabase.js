// Prueba de carga contra la API REST de Supabase (PostgREST).
// Repite las mismas consultas de lectura que hace la app (lib/repositories)
// con la clave publicable, es decir, como un visitante anónimo. No escribe nada.
//
// Ejecutar desde la raíz del proyecto:
//   k6 run performance/k6/carga_supabase.js
// Cambiar el número de usuarios virtuales (por defecto 10):
//   k6 run -e USUARIOS=20 performance/k6/carga_supabase.js
//
// Ojo: el plan gratuito de Supabase tiene límites; empieza con pocos usuarios.

import http from 'k6/http';
import { check, group, sleep } from 'k6';

const config = JSON.parse(open('../../config/local.json'));
const URL = (__ENV.SUPABASE_URL || config.SUPABASE_URL).trim();
const KEY = (__ENV.SUPABASE_KEY || config.SUPABASE_PUBLISHABLE_KEY).trim();
const USUARIOS = Number(__ENV.USUARIOS || 10);

const headers = { apikey: KEY, Authorization: `Bearer ${KEY}` };

// Mismo select/filtro/orden que usa cada repositorio en fetchActivos().
const CONSULTAS = {
  lugares: 'lugares?select=*,categorias(nombre)&activo=eq.true&order=created_at.desc',
  actividades: 'actividades?select=*,categorias(nombre)&activo=eq.true&order=created_at.desc',
  eventos: 'eventos?select=*,categorias(nombre)&activo=eq.true&order=fecha_inicio.asc',
  hoteles: 'hoteles?select=*,categorias(nombre)&activo=eq.true&order=created_at.desc',
  restaurantes: 'restaurantes?select=*,categorias(nombre)&activo=eq.true&order=nombre.asc',
};

export const options = {
  stages: [
    { duration: '30s', target: USUARIOS }, // subida gradual
    { duration: '1m', target: USUARIOS },  // carga sostenida
    { duration: '20s', target: 0 },        // bajada
  ],
  thresholds: {
    http_req_failed: ['rate<0.01'],          // menos del 1% de errores
    http_req_duration: ['p(95)<800'],        // 95% de respuestas en menos de 800 ms
    'http_req_duration{tabla:lugares}': ['p(95)<800'],
    'http_req_duration{tabla:eventos}': ['p(95)<800'],
  },
};

export default function () {
  for (const [tabla, consulta] of Object.entries(CONSULTAS)) {
    group(tabla, () => {
      const res = http.get(`${URL}/rest/v1/${consulta}`, { headers, tags: { tabla } });
      check(res, {
        'status 200': (r) => r.status === 200,
        'devuelve una lista': (r) => Array.isArray(r.json()),
      });
    });
  }
  // Tiempo que un usuario real tarda entre pantalla y pantalla.
  sleep(1);
}

export function handleSummary(data) {
  return {
    'performance/resultados/k6_resumen.json': JSON.stringify(data, null, 2),
    stdout: textoResumen(data),
  };
}

function textoResumen(data) {
  const d = data.metrics.http_req_duration.values;
  const f = data.metrics.http_req_failed.values;
  const r = data.metrics.http_reqs.values;
  return [
    '',
    '===== Resumen de la prueba de carga =====',
    `Usuarios virtuales máx.: ${USUARIOS}`,
    `Peticiones totales:      ${r.count} (${r.rate.toFixed(1)}/s)`,
    `Tiempo promedio:         ${d.avg.toFixed(0)} ms`,
    `p(90) / p(95):           ${d['p(90)'].toFixed(0)} ms / ${d['p(95)'].toFixed(0)} ms`,
    `Máximo:                  ${d.max.toFixed(0)} ms`,
    `Tasa de error:           ${(f.rate * 100).toFixed(2)} %`,
    '',
  ].join('\n');
}
