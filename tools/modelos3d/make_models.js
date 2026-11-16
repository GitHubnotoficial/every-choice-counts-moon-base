// Genera 3 modelos low-poly estilo caricatura en .glb, sin dependencias.
// Uso: node tools/modelos3d/make_models.js
// Salida: assets/claude/*.glb y assets/claude/preview.html
// Ejes: Y arriba, frente hacia +Z, metros. Pivote = centro de la base (0,0,0).
const fs = require('fs');
const path = require('path');

// ---------- Paleta (sRGB -> lineal para glTF) ----------
function lin(hex) {
  const n = parseInt(hex.slice(1), 16);
  return [(n >> 16) & 255, (n >> 8) & 255, n & 255].map(c => {
    c /= 255;
    return c <= 0.04045 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4);
  });
}
const PAL = {
  purple: '#5B2A86', lavender: '#B9A3E3', pink: '#FF9CC8', sky: '#8FD3FF',
  yellow: '#FFD23F', white: '#F7F5FF', red: '#E63946',
};
const MATS = {
  purple: { c: PAL.purple }, lavender: { c: PAL.lavender }, pink: { c: PAL.pink },
  sky: { c: PAL.sky }, yellow: { c: PAL.yellow }, white: { c: PAL.white }, red: { c: PAL.red },
  skyGlow: { c: PAL.sky, e: 0.8 }, yellowGlow: { c: PAL.yellow, e: 0.8 }, redGlow: { c: PAL.red, e: 0.8 },
  glass: { c: PAL.white, a: 0.35 },
  water: { c: PAL.sky, a: 0.55 },
  bubble: { c: PAL.white, a: 0.7, e: 0.3 },
  o2gas: { c: PAL.pink, a: 0.45 },
  h2gas: { c: PAL.sky, a: 0.45 },
};

// ---------- Vectores ----------
const add = (a, b) => [a[0] + b[0], a[1] + b[1], a[2] + b[2]];
const sub = (a, b) => [a[0] - b[0], a[1] - b[1], a[2] - b[2]];
const mul = (a, s) => [a[0] * s, a[1] * s, a[2] * s];
const dot = (a, b) => a[0] * b[0] + a[1] * b[1] + a[2] * b[2];
const cross = (a, b) => [a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0]];
const norm = a => { const l = Math.hypot(a[0], a[1], a[2]) || 1; return [a[0] / l, a[1] / l, a[2] / l]; };

// ---------- Malla ----------
// Mesh = { v: [[pos, nrm]...], t: [[i,j,k]...] }
function mesh() { return { v: [], t: [] }; }
// Triángulo con orientación automática según la normal sugerida
function tri(m, p, n, hint) {
  const fn = cross(sub(p[1], p[0]), sub(p[2], p[0]));
  if (dot(fn, hint) < 0) { p = [p[0], p[2], p[1]]; n = [n[0], n[2], n[1]]; }
  const b = m.v.length;
  for (let i = 0; i < 3; i++) m.v.push([p[i], n[i]]);
  m.t.push([b, b + 1, b + 2]);
}
// Polígono convexo plano (abanico), normal plana hacia "hint"
function poly(m, pts, hint) {
  let fn = norm(cross(sub(pts[1], pts[0]), sub(pts[2], pts[0])));
  if (dot(fn, hint) < 0) fn = mul(fn, -1);
  for (let i = 1; i < pts.length - 1; i++) tri(m, [pts[0], pts[i], pts[i + 1]], [fn, fn, fn], fn);
}
// Quad suave (normales por vértice)
function quadS(m, p, n) {
  const h = norm(add(add(n[0], n[1]), add(n[2], n[3])));
  tri(m, [p[0], p[1], p[2]], [n[0], n[1], n[2]], h);
  tri(m, [p[0], p[2], p[3]], [n[0], n[2], n[3]], h);
}

// Caja con bordes biselados (centrada en el origen)
function cbox(w, h, d, b = 0.04) {
  const m = mesh();
  const H = [w / 2, h / 2, d / 2];
  b = Math.min(b, H[0] * 0.9, H[1] * 0.9, H[2] * 0.9);
  const P = (s, ax) => [0, 1, 2].map(i => i === ax ? s[i] * H[i] : s[i] * (H[i] - b));
  const S = [-1, 1];
  // caras
  for (let ax = 0; ax < 3; ax++) for (const s of S) {
    const u = (ax + 1) % 3, v = (ax + 2) % 3;
    const pts = [[-1, -1], [1, -1], [1, 1], [-1, 1]].map(([a, c]) => {
      const sg = [0, 0, 0]; sg[ax] = s; sg[u] = a; sg[v] = c; return P(sg, ax);
    });
    const hn = [0, 0, 0]; hn[ax] = s; poly(m, pts, hn);
  }
  // aristas
  for (let a = 0; a < 3; a++) for (let c = a + 1; c < 3; c++) {
    const e = 3 - a - c;
    for (const sa of S) for (const sc of S) {
      const sg = e2 => { const g = [0, 0, 0]; g[a] = sa; g[c] = sc; g[e] = e2; return g; };
      const pts = [P(sg(-1), a), P(sg(-1), c), P(sg(1), c), P(sg(1), a)];
      const hn = [0, 0, 0]; hn[a] = sa; hn[c] = sc; poly(m, pts, hn);
    }
  }
  // esquinas
  for (const x of S) for (const y of S) for (const z of S) {
    const s = [x, y, z]; poly(m, [P(s, 0), P(s, 1), P(s, 2)], s);
  }
  return m;
}

// Tronco de cono vertical, y de 0 a h. opts: smooth, top, bot, inward, a0
function frustum(rb, rt, h, seg, o = {}) {
  const { smooth = true, top = true, bot = true, inward = false, a0 = 0 } = o;
  const m = mesh(); const sgn = inward ? -1 : 1;
  const ring = (r, y) => Array.from({ length: seg }, (_, i) => {
    const a = a0 + (i / seg) * Math.PI * 2; return [r * Math.cos(a), y, r * Math.sin(a)];
  });
  const B = ring(rb, 0), T = ring(rt, h);
  const nAt = i => { const a = a0 + (i / seg) * Math.PI * 2; return mul(norm([Math.cos(a) * h, rb - rt, Math.sin(a) * h]), sgn); };
  for (let i = 0; i < seg; i++) {
    const j = (i + 1) % seg;
    if (smooth) {
      const ni = nAt(i), nj = nAt(j);
      if (rt < 1e-6) tri(m, [B[i], B[j], T[i]], [ni, nj, norm(add(ni, nj))], norm(add(ni, nj)));
      else quadS(m, [B[i], B[j], T[j], T[i]], [ni, nj, nj, ni]);
    } else {
      const hn = nAt(i + 0.5);
      if (rt < 1e-6) poly(m, [B[i], B[j], T[i]], hn); else poly(m, [B[i], B[j], T[j], T[i]], hn);
    }
  }
  if (top && rt > 1e-6) poly(m, T, [0, sgn, 0]);
  if (bot && rb > 1e-6) poly(m, B, [0, -sgn, 0]);
  return m;
}
// Anillo plano horizontal (corona) entre r1 y r2, a altura 0, mirando arriba
function annulus(r1, r2, seg) {
  const m = mesh();
  for (let i = 0; i < seg; i++) {
    const a = (i / seg) * Math.PI * 2, b = ((i + 1) / seg) * Math.PI * 2;
    poly(m, [[r1 * Math.cos(a), 0, r1 * Math.sin(a)], [r2 * Math.cos(a), 0, r2 * Math.sin(a)],
      [r2 * Math.cos(b), 0, r2 * Math.sin(b)], [r1 * Math.cos(b), 0, r1 * Math.sin(b)]], [0, 1, 0]);
  }
  return m;
}
// Esfera (o media esfera superior) centrada en el origen
function sphere(r, lat, lon, hemi = false) {
  const m = mesh(); const th = hemi ? Math.PI / 2 : Math.PI;
  const P = (i, j) => { const t = (i / lat) * th, p = (j / lon) * Math.PI * 2;
    const n = [Math.sin(t) * Math.cos(p), Math.cos(t), Math.sin(t) * Math.sin(p)]; return [mul(n, r), n]; };
  for (let i = 0; i < lat; i++) for (let j = 0; j < lon; j++) {
    const a = P(i, j), b = P(i, j + 1), c = P(i + 1, j + 1), d = P(i + 1, j);
    if (i === 0) tri(m, [a[0], c[0], d[0]], [a[1], c[1], d[1]], norm(add(c[1], d[1])));
    else quadS(m, [a[0], b[0], c[0], d[0]], [a[1], b[1], c[1], d[1]]);
  }
  return m;
}
// Suaviza un camino (Catmull-Rom)
function smoothPath(pts, sub = 4) {
  const out = [];
  for (let i = 0; i < pts.length - 1; i++) {
    const p0 = pts[Math.max(i - 1, 0)], p1 = pts[i], p2 = pts[i + 1], p3 = pts[Math.min(i + 2, pts.length - 1)];
    for (let k = 0; k < sub; k++) {
      const t = k / sub, t2 = t * t, t3 = t2 * t;
      out.push([0, 1, 2].map(c => 0.5 * (2 * p1[c] + (-p0[c] + p2[c]) * t + (2 * p0[c] - 5 * p1[c] + 4 * p2[c] - p3[c]) * t2 + (-p0[c] + 3 * p1[c] - 3 * p2[c] + p3[c]) * t3)));
    }
  }
  out.push(pts[pts.length - 1]);
  return out;
}
// Tubo a lo largo de un camino (manguera / tubería)
function tube(pts, r, sides = 8, caps = true) {
  const m = mesh(); const n = pts.length;
  const T = pts.map((p, i) => norm(sub(pts[Math.min(i + 1, n - 1)], pts[Math.max(i - 1, 0)])));
  let N = Math.abs(T[0][1]) < 0.9 ? norm(cross(T[0], [0, 1, 0])) : norm(cross(T[0], [1, 0, 0]));
  const rings = [];
  for (let i = 0; i < n; i++) {
    N = norm(sub(N, mul(T[i], dot(N, T[i]))));
    const Bv = cross(T[i], N);
    rings.push(Array.from({ length: sides }, (_, k) => {
      const a = (k / sides) * Math.PI * 2; const d = add(mul(N, Math.cos(a)), mul(Bv, Math.sin(a)));
      return [add(pts[i], mul(d, r)), d];
    }));
  }
  for (let i = 0; i < n - 1; i++) for (let k = 0; k < sides; k++) {
    const k2 = (k + 1) % sides, A = rings[i][k], B = rings[i][k2], C = rings[i + 1][k2], D = rings[i + 1][k];
    quadS(m, [A[0], B[0], C[0], D[0]], [A[1], B[1], C[1], D[1]]);
  }
  if (caps) {
    poly(m, rings[0].map(x => x[0]), mul(T[0], -1));
    poly(m, rings[n - 1].map(x => x[0]), T[n - 1]);
  }
  return m;
}

// ---------- Transformaciones ----------
function rot(ax, ang) {
  const c = Math.cos(ang), s = Math.sin(ang);
  if (ax === 'x') return p => [p[0], c * p[1] - s * p[2], s * p[1] + c * p[2]];
  if (ax === 'y') return p => [c * p[0] + s * p[2], p[1], -s * p[0] + c * p[2]];
  return p => [c * p[0] - s * p[1], s * p[0] + c * p[1], p[2]];
}
// ops: lista de ['x'|'y'|'z', ángulo] aplicadas en orden, luego traslación t
function xf(m, t = [0, 0, 0], ops = []) {
  const fs_ = ops.map(([a, g]) => rot(a, g));
  const R = p => fs_.reduce((q, f) => f(q), p);
  return { v: m.v.map(([p, n]) => [add(R(p), t), R(n)]), t: m.t };
}

// ---------- Modelo ----------
class Model {
  constructor(name) { this.name = name; this.groups = {}; }
  add(mat, m, t, ops) {
    if (!MATS[mat]) throw new Error('material ' + mat);
    const g = this.groups[mat] || (this.groups[mat] = { v: [], t: [] });
    const mm = xf(m, t, ops); const b = g.v.length;
    g.v.push(...mm.v); g.t.push(...mm.t.map(([i, j, k]) => [i + b, j + b, k + b]));
  }
  tris() { return Object.values(this.groups).reduce((s, g) => s + g.t.length, 0); }
  allV() { return Object.values(this.groups).flatMap(g => g.v.map(v => v[0])); }
}

// ---------- Escritor GLB ----------
function writeGLB(model, file) {
  const bufs = []; let off = 0;
  const bufferViews = [], accessors = [], primitives = [], materials = [];
  const push = (buf, target) => {
    const pad = (4 - (buf.length % 4)) % 4; const b = Buffer.concat([buf, Buffer.alloc(pad)]);
    bufferViews.push({ buffer: 0, byteOffset: off, byteLength: buf.length, target });
    bufs.push(b); off += b.length; return bufferViews.length - 1;
  };
  for (const [mat, g] of Object.entries(model.groups)) {
    const M = MATS[mat]; const col = lin(M.c);
    const mt = { name: 'SO_' + mat, pbrMetallicRoughness: { baseColorFactor: [...col, M.a ?? 1], metallicFactor: 0.0, roughnessFactor: 0.55 } };
    if (M.e) mt.emissiveFactor = col.map(c => c * M.e);
    if (M.a) mt.alphaMode = 'BLEND';
    materials.push(mt);
    const P = new Float32Array(g.v.length * 3), N = new Float32Array(g.v.length * 3);
    const mn = [Infinity, Infinity, Infinity], mx = [-Infinity, -Infinity, -Infinity];
    g.v.forEach(([p, n], i) => { const nn = norm(n);
      for (let c = 0; c < 3; c++) { P[i * 3 + c] = p[c]; N[i * 3 + c] = nn[c]; mn[c] = Math.min(mn[c], p[c]); mx[c] = Math.max(mx[c], p[c]); } });
    const I = g.v.length < 65536 ? new Uint16Array(g.t.flat()) : new Uint32Array(g.t.flat());
    const pv = push(Buffer.from(P.buffer), 34962), nv = push(Buffer.from(N.buffer), 34962), iv = push(Buffer.from(I.buffer), 34963);
    accessors.push({ bufferView: pv, componentType: 5126, count: g.v.length, type: 'VEC3', min: mn, max: mx });
    accessors.push({ bufferView: nv, componentType: 5126, count: g.v.length, type: 'VEC3' });
    accessors.push({ bufferView: iv, componentType: I instanceof Uint16Array ? 5123 : 5125, count: I.length, type: 'SCALAR' });
    const a = accessors.length;
    primitives.push({ attributes: { POSITION: a - 3, NORMAL: a - 2 }, indices: a - 1, material: materials.length - 1, mode: 4 });
  }
  const bin = Buffer.concat(bufs);
  const gltf = {
    asset: { version: '2.0', generator: 'Shackleton One make_models.js' },
    scene: 0, scenes: [{ nodes: [0] }], nodes: [{ name: model.name, mesh: 0 }],
    meshes: [{ name: model.name, primitives }], materials, accessors, bufferViews,
    buffers: [{ byteLength: bin.length }],
  };
  let js = Buffer.from(JSON.stringify(gltf)); js = Buffer.concat([js, Buffer.alloc((4 - (js.length % 4)) % 4, 0x20)]);
  const total = 12 + 8 + js.length + 8 + bin.length;
  const h = Buffer.alloc(12); h.writeUInt32LE(0x46546c67, 0); h.writeUInt32LE(2, 4); h.writeUInt32LE(total, 8);
  const c1 = Buffer.alloc(8); c1.writeUInt32LE(js.length, 0); c1.writeUInt32LE(0x4e4f534a, 4);
  const c2 = Buffer.alloc(8); c2.writeUInt32LE(bin.length, 0); c2.writeUInt32LE(0x004e4942, 4);
  fs.writeFileSync(file, Buffer.concat([h, c1, js, c2, bin]));
}

const D = Math.PI / 180;

// =====================================================================
// MODELO 1: planta de oxígeno de regolito
// =====================================================================
function oxygenPlant() {
  const M = new Model('Lunar_Regolith_Oxygen_Plant');
  // Base
  M.add('purple', cbox(4.6, 0.3, 3.4, 0.1), [0, 0.15, 0]);
  M.add('yellow', cbox(4.1, 0.05, 0.14, 0.02), [0, 0.325, 1.52]);
  M.add('yellow', cbox(4.1, 0.05, 0.14, 0.02), [0, 0.325, -1.52]);
  for (const sx of [-1, 1]) for (const sz of [-1, 1]) M.add('red', cbox(0.22, 0.07, 0.22, 0.03), [sx * 2.1, 0.335, sz * 1.45]);
  // Cuerpo de proceso
  const bx = -0.7;
  M.add('white', cbox(2.6, 1.9, 2.3, 0.2), [bx, 1.25, 0]);
  M.add('purple', cbox(2.72, 0.26, 2.42, 0.08), [bx, 0.45, 0]);
  M.add('lavender', cbox(2.72, 0.34, 2.42, 0.1), [bx, 1.9, 0]);
  for (const sx of [-1, 1]) for (const sz of [-1, 1]) M.add('purple', cbox(0.24, 1.9, 0.24, 0.06), [bx + sx * 1.3, 1.25, sz * 1.15]);
  M.add('pink', cbox(0.06, 0.9, 1.4, 0.02), [bx - 1.32, 1.15, 0]);
  M.add('sky', cbox(1.6, 0.8, 0.06, 0.02), [bx, 1.15, -1.17]);
  // Panel de control al frente
  M.add('purple', cbox(1.3, 0.8, 0.1, 0.04), [bx - 0.3, 1.2, 1.18]);
  M.add('skyGlow', cbox(1.0, 0.42, 0.04, 0.01), [bx - 0.3, 1.3, 1.24]);
  [['yellowGlow', -0.35], ['redGlow', 0], ['skyGlow', 0.35]].forEach(([c, dx]) => M.add(c, sphere(0.07, 4, 8), [bx - 0.3 + dx, 0.97, 1.25]));
  M.add('pink', cbox(0.6, 0.8, 0.06, 0.02), [bx + 0.8, 1.2, 1.17]);
  M.add('red', frustum(0.09, 0.09, 0.08, 10), [bx + 0.8, 1.42, 1.19], [['x', 90 * D]]);
  M.add('yellow', cbox(0.42, 0.26, 0.04, 0.02), [bx + 0.8, 1.0, 1.21]);
  // Tolva (embudo)
  M.add('purple', frustum(0.42, 0.42, 0.35, 12), [bx, 2.2, 0]);
  M.add('white', frustum(0.44, 1.25, 1.15, 16, { top: false, bot: false }), [bx, 2.55, 0]);
  M.add('lavender', frustum(0.4, 1.17, 1.12, 16, { top: false, bot: false, inward: true }), [bx, 2.58, 0]);
  M.add('yellow', frustum(1.3, 1.3, 0.16, 16, { top: false, bot: true }), [bx, 3.6, 0]);
  M.add('yellow', annulus(1.17, 1.3, 16), [bx, 3.76, 0]);
  for (const sx of [-1, 1]) for (const sz of [-1, 1])
    M.add('purple', tube([[bx + sx * 1.0, 2.15, sz * 0.8], [bx + sx * 0.64, 3.25, sz * 0.64]], 0.06, 6));
  // Chimenea
  const cx = bx - 0.85, cz = -0.7;
  M.add('purple', frustum(0.44, 0.38, 0.3, 12), [cx, 2.2, cz]);
  M.add('white', frustum(0.3, 0.26, 3.4, 12, { top: false, bot: false }), [cx, 2.5, cz]);
  M.add('yellow', frustum(0.31, 0.31, 0.18, 12, { top: false, bot: false }), [cx, 3.7, cz]);
  M.add('red', frustum(0.3, 0.3, 0.2, 12, { top: false, bot: false }), [cx, 4.9, cz]);
  M.add('red', frustum(0.29, 0.29, 0.2, 12, { top: false, bot: false }), [cx, 5.35, cz]);
  M.add('purple', frustum(0.36, 0.36, 0.18, 12), [cx, 5.85, cz]);
  // Reactor / cámara de proceso
  const rx = 1.45, rz = 0.1;
  M.add('purple', frustum(0.95, 0.95, 0.2, 16), [rx, 0.3, rz]);
  M.add('lavender', frustum(0.82, 0.82, 1.6, 16, { top: false, bot: false }), [rx, 0.5, rz]);
  M.add('purple', frustum(0.88, 0.88, 0.16, 16, { top: false, bot: false }), [rx, 0.85, rz]);
  M.add('purple', frustum(0.88, 0.88, 0.16, 16, { top: false, bot: false }), [rx, 2.0, rz]);
  M.add('white', sphere(0.82, 4, 16, true), [rx, 2.1, rz]);
  M.add('purple', frustum(0.16, 0.16, 0.3, 10), [rx, 2.8, rz]);
  M.add('pink', cbox(0.66, 0.74, 0.12, 0.05), [rx, 1.45, rz + 0.8]);
  M.add('skyGlow', cbox(0.5, 0.58, 0.08, 0.04), [rx, 1.45, rz + 0.86]);
  // Tuberías
  M.add('pink', tube(smoothPath([[bx + 0.3, 2.4, 0], [bx + 1.1, 2.55, 0], [0.9, 3.3, rz], [rx, 3.45, rz], [rx, 3.05, rz]], 5), 0.12, 10));
  M.add('purple', frustum(0.19, 0.19, 0.08, 10), [rx, 3.0, rz]);
  const a = 35 * D, sx0 = rx + 0.8 * Math.cos(a), sz0 = rz + 0.8 * Math.sin(a);
  M.add('sky', tube(smoothPath([[sx0, 1.2, sz0], [sx0 + 0.25, 1.1, sz0 + 0.35], [2.05, 0.75, 1.3], [1.65, 0.62, 1.38], [1.42, 0.62, 1.38]], 5), 0.1, 10));
  M.add('sky', frustum(0.15, 0.15, 0.55, 12), [1.35, 0.3, 1.38]);
  M.add('yellow', frustum(0.25, 0.25, 0.06, 12), [1.35, 0.88, 1.38]);
  M.add('purple', frustum(0.05, 0.05, 0.08, 6), [1.35, 0.85, 1.38]);
  M.add('pink', tube([[bx + 1.25, 0.85, -0.55], [rx - 0.5, 0.85, -0.55]], 0.13, 10));
  M.add('purple', frustum(0.2, 0.2, 0.07, 12), [0.75, 0.85, -0.55], [['z', 90 * D]]);
  return M;
}

// =====================================================================
// MODELO 2: estación de recarga de oxígeno y agua
// =====================================================================
function refillStation() {
  const M = new Model('Oxygen_Water_Refill_Station');
  M.add('purple', cbox(2.3, 0.22, 1.4, 0.06), [0, 0.11, 0]);
  M.add('lavender', cbox(2.0, 0.45, 1.1, 0.08), [0, 0.445, 0]);
  for (const x of [-0.6, -0.2, 0.2, 0.6]) M.add('yellow', cbox(0.12, 0.34, 0.03, 0.01), [x, 0.445, 0.56], [['z', 0.6]]);
  // Gabinete
  M.add('white', cbox(1.9, 1.9, 0.95, 0.14), [0, 1.62, 0]);
  for (const s of [-1, 1]) M.add('purple', cbox(0.16, 2.0, 1.05, 0.05), [s * 1.0, 1.62, 0]);
  M.add('purple', cbox(2.25, 0.32, 1.1, 0.1), [0, 2.73, 0]);
  // Iconos: burbujas de O2 (izq) y gota de agua (der)
  M.add('pink', sphere(0.075, 4, 8), [-0.66, 2.71, 0.56]);
  M.add('pink', sphere(0.055, 4, 8), [-0.52, 2.77, 0.56]);
  M.add('pink', sphere(0.04, 4, 8), [-0.42, 2.69, 0.56]);
  M.add('skyGlow', sphere(0.08, 4, 8), [0.55, 2.69, 0.56]);
  M.add('skyGlow', frustum(0.08, 0, 0.13, 8, { bot: false }), [0.55, 2.69, 0.56]);
  // Divisor y paneles de cada lado
  M.add('purple', cbox(0.1, 1.25, 0.06, 0.02), [0, 1.32, 0.49]);
  M.add('pink', cbox(0.8, 1.2, 0.04, 0.02), [-0.47, 1.32, 0.49]);
  M.add('sky', cbox(0.8, 1.2, 0.04, 0.02), [0.47, 1.32, 0.49]);
  // Pantalla central y botones
  M.add('purple', cbox(0.95, 0.42, 0.06, 0.03), [0, 2.32, 0.5]);
  M.add('skyGlow', cbox(0.8, 0.3, 0.03, 0.01), [0, 2.33, 0.53]);
  for (const x of [-0.3, -0.1, 0.1]) M.add('yellow', frustum(0.045, 0.045, 0.05, 8), [x, 2.0, 0.47], [['x', 90 * D]]);
  M.add('red', frustum(0.06, 0.06, 0.06, 8), [0.32, 2.0, 0.47], [['x', 90 * D]]);
  // Indicadores de tanque (tubo de vidrio + nivel)
  for (const [s, fill, ring] of [[-1, 'pink', 'red'], [1, 'skyGlow', 'sky']]) {
    const x = s * 0.47;
    M.add('white', cbox(0.3, 0.85, 0.06, 0.02), [x, 1.5, 0.52]);
    M.add(fill, frustum(0.085, 0.085, 0.5, 10), [x, 1.15, 0.56]);
    M.add('glass', frustum(0.1, 0.1, 0.7, 10), [x, 1.15, 0.56]);
    M.add('purple', frustum(0.12, 0.12, 0.05, 10), [x, 1.1, 0.56]);
    M.add('purple', frustum(0.12, 0.12, 0.05, 10), [x, 1.85, 0.56]);
    // Puerto de conexión
    M.add(ring, frustum(0.13, 0.13, 0.08, 12), [x, 0.92, 0.51], [['x', 90 * D]]);
    M.add('purple', frustum(0.075, 0.075, 0.12, 10), [x, 0.92, 0.51], [['x', 90 * D]]);
    // Soporte, boquilla y manguera
    const hx = s * 1.14;
    M.add('purple', cbox(0.12, 0.3, 0.25, 0.03), [hx, 1.48, 0.2]);
    const nx = s * 1.27;
    M.add(s < 0 ? 'pink' : 'sky', frustum(0.065, 0.065, 0.3, 10), [nx, 1.36, 0.2]);
    M.add(s < 0 ? 'red' : 'purple', frustum(0.04, 0.075, 0.18, 10), [nx, 1.18, 0.2]);
    M.add('yellow', frustum(0.03, 0.03, 0.05, 8), [nx, 1.13, 0.2]);
    M.add(s < 0 ? 'red' : 'sky', tube(smoothPath([[x, 0.92, 0.62], [x + s * 0.05, 0.82, 0.82], [s * 0.9, 0.78, 0.88],
      [s * 1.32, 0.98, 0.62], [s * 1.42, 1.5, 0.32], [s * 1.33, 1.76, 0.2], [nx, 1.67, 0.2]], 4), 0.045, 8));
  }
  return M;
}

// =====================================================================
// MODELO 3: reactor de energía con aletas radiadoras
// =====================================================================
function powerReactor() {
  const M = new Model('Space_Power_Reactor');
  // Plataforma
  M.add('purple', frustum(3.75, 3.6, 0.4, 8, { smooth: false, a0: 22.5 * D }), [0, 0, 0]);
  M.add('lavender', frustum(2.9, 2.8, 0.3, 8, { smooth: false, a0: 22.5 * D }), [0, 0.4, 0]);
  for (let k = 0; k < 8; k++) {
    const a = k * 45 * D;
    M.add(k % 2 ? 'red' : 'yellow', cbox(0.55, 0.07, 0.3, 0.03), [3.25 * Math.cos(a), 0.435, -3.25 * Math.sin(a)], [['y', a]]);
  }
  // Cuerpo
  M.add('white', frustum(1.45, 1.45, 4.1, 16, { top: false, bot: false }), [0, 0.7, 0]);
  for (const y of [1.0, 2.75, 4.45]) M.add('purple', frustum(1.53, 1.53, 0.25, 16), [0, y, 0]);
  M.add('lavender', sphere(1.45, 4, 16, true), [0, 4.8, 0]);
  M.add('purple', frustum(0.5, 0.5, 0.3, 12), [0, 6.05, 0]);
  M.add('skyGlow', frustum(0.35, 0.35, 0.15, 12), [0, 6.35, 0]);
  M.add('yellowGlow', sphere(0.13, 4, 8), [0, 6.62, 0]);
  // Ventanas de energía (frente y atrás)
  for (const s of [-1, 1]) for (const y of [2.05, 3.65]) M.add('skyGlow', cbox(0.42, 1.0, 0.14, 0.05), [0, y, s * 1.43]);
  // Luces indicadoras en la banda superior
  for (let k = 0; k < 8; k++) { const a = (k * 45 + 22.5) * D; M.add('skyGlow', sphere(0.09, 4, 8), [1.56 * Math.cos(a), 4.575, 1.56 * Math.sin(a)]); }
  // Aletas radiadoras (4 en diagonal)
  for (let k = 0; k < 4; k++) {
    const ops = [['y', (45 + k * 90) * D]];
    const fin = (mat, m, r, y) => M.add(mat, xf(m, [r, y, 0]), [0, 0, 0], ops);
    fin('purple', cbox(2.3, 3.6, 0.2, 0.06), 2.55, 2.5);
    fin('sky', cbox(1.9, 3.1, 0.26, 0.04), 2.6, 2.5);
    for (const y of [1.5, 2.25, 3.0, 3.75]) fin('lavender', cbox(1.95, 0.09, 0.3, 0.02), 2.6, y);
    fin('pink', cbox(0.18, 3.6, 0.3, 0.05), 3.7, 2.5);
    fin('purple', cbox(0.34, 0.3, 0.34, 0.05), 3.45, 0.55);
    fin('redGlow', sphere(0.1, 4, 8), 3.7, 4.36);
  }
  // Tuberías grandes a los lados (+X y -X)
  for (const s of [-1, 1]) {
    M.add('pink', tube(smoothPath([[s * 1.4, 3.4, 0], [s * 2.1, 3.4, 0], [s * 2.65, 3.0, 0], [s * 2.75, 1.8, 0], [s * 2.75, 0.95, 0]], 5), 0.22, 12));
    M.add('purple', frustum(0.3, 0.3, 0.1, 12), [s * 1.5, 3.4, 0], [['z', 90 * D]]);
    M.add('purple', cbox(0.62, 0.5, 0.62, 0.08), [s * 2.75, 0.65, 0]);
    M.add('purple', frustum(0.3, 0.3, 0.08, 12), [s * 2.75, 0.9, 0]);
    // Panel lateral con aviso
    M.add('lavender', cbox(0.14, 1.2, 0.9, 0.05), [s * 1.45, 1.95, 0]);
    M.add('yellow', cbox(0.16, 0.18, 0.7, 0.03), [s * 1.47, 2.35, 0]);
  }
  // Módulo de control al frente
  M.add('lavender', cbox(1.2, 1.1, 0.8, 0.1), [0, 1.25, 1.75]);
  M.add('purple', cbox(0.95, 0.6, 0.05, 0.03), [0, 1.42, 2.16]);
  M.add('skyGlow', cbox(0.8, 0.45, 0.04, 0.01), [0, 1.42, 2.19]);
  M.add('red', cbox(1.22, 0.08, 0.82, 0.02), [0, 0.95, 1.75]);
  for (const x of [-0.3, -0.1]) M.add('yellow', frustum(0.055, 0.055, 0.05, 8), [x, 0.82, 2.14], [['x', 90 * D]]);
  M.add('red', frustum(0.07, 0.07, 0.06, 8), [0.3, 0.82, 2.14], [['x', 90 * D]]);
  return M;
}

// =====================================================================
// MODELO 4: tanque de electrólisis (agua -> O2 + H2), decoración de Soporte Vital
// Izquierda = oxígeno (rosa, 1 parte), derecha = hidrógeno (celeste, 2 partes):
// el H2 sale con el doble de burbujas y su globo es el doble de volumen (H2O).
// =====================================================================
function electrolysisTank() {
  const M = new Model('Electrolysis_Water_Tank');
  // Base y zócalo
  M.add('purple', cbox(3.2, 0.25, 1.5, 0.08), [0, 0.125, 0]);
  M.add('yellow', cbox(2.9, 0.04, 0.1, 0.02), [0, 0.27, 0.66]);
  // Tanque de vidrio con agua
  M.add('lavender', cbox(2.0, 0.12, 1.1, 0.04), [-0.3, 0.31, 0]);
  M.add('water', cbox(1.8, 1.0, 0.9, 0.05), [-0.3, 0.87, 0]);
  M.add('glass', cbox(1.9, 1.3, 1.0, 0.08), [-0.3, 1.02, 0]);
  for (const sx of [-1, 1]) for (const sz of [-1, 1]) M.add('purple', cbox(0.1, 1.32, 0.1, 0.03), [-0.3 + sx * 0.93, 1.03, sz * 0.48]);
  M.add('purple', cbox(2.0, 0.1, 1.1, 0.04), [-0.3, 1.72, 0]);
  // Electrodos (salen del fondo) y tubos colectores
  const sides = [
    { x: -0.8, gas: 'o2gas', tip: 'red', balloon: 'pink', r: 0.36, nb: 6, hose: 'red' },
    { x: 0.2, gas: 'h2gas', tip: 'purple', balloon: 'sky', r: 0.45, nb: 12, hose: 'sky' },
  ];
  sides.forEach((S, si) => {
    M.add('white', frustum(0.05, 0.05, 0.35, 8), [S.x, 0.37, 0]);
    M.add(S.tip, cbox(0.28, 0.12, 0.28, 0.03), [S.x, 0.74, 0]);
    // Tubo de vidrio que recoge el gas (desde dentro del agua hasta arriba)
    M.add('glass', frustum(0.18, 0.18, 1.95, 12, { top: false, bot: false }), [S.x, 0.9, 0]);
    M.add(S.gas, frustum(0.16, 0.16, si ? 0.9 : 0.45, 12), [S.x, 2.4 - (si ? 0.9 : 0.45), 0]);
    M.add('purple', frustum(0.22, 0.22, 0.1, 12), [S.x, 1.77, 0]);
    M.add('purple', frustum(0.22, 0.16, 0.14, 12), [S.x, 2.85, 0]);
    // Globo con el gas
    M.add(S.balloon, frustum(0.06, 0.12, 0.18, 8), [S.x, 2.99, 0]);
    M.add(S.balloon, sphere(S.r, 8, 16), [S.x, 3.15 + S.r * 0.95, 0]);
    M.add('white', sphere(S.r * 0.18, 3, 6), [S.x - S.r * 0.4, 3.15 + S.r * 1.35, S.r * 0.55]);
    // Burbujas: suben del electrodo por el agua y dentro del tubo
    for (let k = 0; k < S.nb; k++) {
      const t = (k + 0.5) / S.nb;
      const y = 0.88 + t * (si ? 1.25 : 1.5);
      const ang = k * 2.4;
      const rr = 0.05 + ((k * 7) % 4) * 0.015;
      M.add('bubble', sphere(rr, 4, 8), [S.x + Math.cos(ang) * 0.08, y, Math.sin(ang) * 0.08]);
    }
    // Enchufe en el frente del zócalo y cable a la batería
    M.add(S.tip, cbox(0.16, 0.12, 0.08, 0.02), [S.x, 0.31, 0.58]);
  });
  // Batería
  M.add('yellow', cbox(0.7, 0.75, 0.6, 0.08), [1.15, 0.625, 0]);
  M.add('purple', cbox(0.72, 0.18, 0.62, 0.04), [1.15, 0.85, 0]);
  M.add('red', frustum(0.07, 0.07, 0.12, 8), [1.0, 0.94, 0]);
  M.add('purple', frustum(0.07, 0.07, 0.12, 8), [1.3, 0.94, 0]);
  M.add('skyGlow', cbox(0.36, 0.2, 0.04, 0.01), [1.15, 0.55, 0.31]);
  M.add('red', tube(smoothPath([[1.0, 1.05, 0], [1.0, 1.25, 0.15], [0.8, 0.55, 0.62], [0.2, 0.3, 0.68], [-0.8, 0.3, 0.68], [-0.8, 0.31, 0.62]], 4), 0.03, 6));
  M.add('purple', tube(smoothPath([[1.3, 1.05, 0], [1.35, 1.2, 0.2], [1.2, 0.55, 0.6], [0.6, 0.32, 0.64], [0.2, 0.31, 0.62]], 4), 0.03, 6));
  // Fórmula con bolitas al frente: 1 rosa (O) y 2 celestes (H)
  M.add('lavender', cbox(0.8, 0.3, 0.06, 0.02), [1.15, 0.4, 0.34]);
  M.add('pink', sphere(0.08, 3, 8), [0.95, 0.4, 0.38]);
  M.add('sky', sphere(0.06, 3, 8), [1.2, 0.4, 0.38]);
  M.add('sky', sphere(0.06, 3, 8), [1.38, 0.4, 0.38]);
  return M;
}

// ---------- Validación y salida ----------
const outDir = path.join(__dirname, '..', '..', 'assets', 'claude');
fs.mkdirSync(outDir, { recursive: true });
const models = [oxygenPlant(), refillStation(), powerReactor(), electrolysisTank()];
let ok = true;
for (const M of models) {
  const V = M.allV();
  const mn = [0, 1, 2].map(c => Math.min(...V.map(p => p[c])));
  const mx = [0, 1, 2].map(c => Math.max(...V.map(p => p[c])));
  const ground = V.filter(p => Math.abs(p[1]) < 1e-4);
  const gx = [Math.min(...ground.map(p => p[0])), Math.max(...ground.map(p => p[0]))];
  const gz = [Math.min(...ground.map(p => p[2])), Math.max(...ground.map(p => p[2]))];
  const gc = [(gx[0] + gx[1]) / 2, (gz[0] + gz[1]) / 2];
  const tris = M.tris();
  const pass = tris < 5000 && Math.abs(mn[1]) < 1e-4 && Math.hypot(gc[0], gc[1]) < 1e-3;
  ok = ok && pass;
  console.log(`${M.name}: ${tris} triángulos | tamaño ${(mx[0] - mn[0]).toFixed(2)} x ${(mx[1] - mn[1]).toFixed(2)} x ${(mx[2] - mn[2]).toFixed(2)} m | minY=${mn[1].toFixed(4)} | centro base=(${gc[0].toFixed(3)}, ${gc[1].toFixed(3)}) | ${pass ? 'OK' : 'FALLA'}`);
  writeGLB(M, path.join(outDir, M.name + '.glb'));
}
// Vista previa (three.js) con los GLB embebidos
const b64 = models.map(M => fs.readFileSync(path.join(outDir, M.name + '.glb')).toString('base64'));
fs.writeFileSync(path.join(outDir, 'preview.html'), `<!doctype html><html><head><meta charset="utf-8"><title>Vista previa modelos</title>
<style>body{margin:0;background:#20163a}canvas{display:block}</style>
<script type="importmap">{"imports":{"three":"https://cdn.jsdelivr.net/npm/three@0.160.0/build/three.module.js","three/addons/":"https://cdn.jsdelivr.net/npm/three@0.160.0/examples/jsm/"}}</script></head><body>
<script type="module">
import * as THREE from 'three';import {GLTFLoader} from 'three/addons/loaders/GLTFLoader.js';import {OrbitControls} from 'three/addons/controls/OrbitControls.js';
const R=new THREE.WebGLRenderer({antialias:true});R.setSize(innerWidth,innerHeight);R.outputColorSpace=THREE.SRGBColorSpace;document.body.appendChild(R.domElement);
const S=new THREE.Scene();S.background=new THREE.Color(0x20163a);const C=new THREE.PerspectiveCamera(40,innerWidth/innerHeight,0.1,200);C.position.set(0,7,19);
const O=new OrbitControls(C,R.domElement);O.target.set(0,2.5,0);O.update();
S.add(new THREE.HemisphereLight(0xffffff,0x554477,1.6));const d=new THREE.DirectionalLight(0xffffff,2.2);d.position.set(5,10,7);S.add(d);
const g=new THREE.Mesh(new THREE.PlaneGeometry(40,40),new THREE.MeshStandardMaterial({color:0x8a8499}));g.rotation.x=-Math.PI/2;S.add(g);
const data=${JSON.stringify(b64)};const xs=[-7,0,7.5,-3.5];const L=new GLTFLoader();
data.forEach((b,i)=>{const u=Uint8Array.from(atob(b),c=>c.charCodeAt(0)).buffer;L.parse(u,'',gl=>{gl.scene.position.x=xs[i];if(i===3)gl.scene.position.z=5;S.add(gl.scene);});});
(function a(){requestAnimationFrame(a);R.render(S,C);})();
</script></body></html>`);
console.log(ok ? 'Todo OK' : 'HAY FALLAS');
