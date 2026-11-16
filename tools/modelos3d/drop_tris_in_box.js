// Borra de un .glb los triángulos de ciertas mallas cuyo centro cae dentro de una caja.
// Uso: node tools/modelos3d/drop_tris_in_box.js entrada.glb salida.glb "^Luz$" xmin ymin zmin xmax ymax zmax
// (no aplica transformaciones de nodo: pensado para mallas en coordenadas del modelo)
const fs = require('fs');
const [, , inp, out, pattern, ...b] = process.argv;
const [x0, y0, z0, x1, y1, z1] = b.map(Number);
const re = new RegExp(pattern);
const f = Buffer.from(fs.readFileSync(inp));
const jl = f.readUInt32LE(12);
const j = JSON.parse(f.slice(20, 20 + jl));
const binStart = 20 + jl + 8;
const view = (acc) => { const bv = j.bufferViews[acc.bufferView]; return binStart + (bv.byteOffset || 0) + (acc.byteOffset || 0); };
let dropped = 0;
j.meshes.forEach(m => {
  if (!re.test(m.name || '')) return;
  m.primitives.forEach(p => {
    const pa = j.accessors[p.attributes.POSITION], po = view(pa);
    const P = v => [0, 1, 2].map(c => f.readFloatLE(po + (v * 3 + c) * 4));
    const inBox = c => c[0] > x0 && c[0] < x1 && c[1] > y0 && c[1] < y1 && c[2] > z0 && c[2] < z1;
    if (p.indices == null) {
      // Sin índices: se colapsan los 3 vértices del triángulo en un punto (queda invisible)
      for (let t = 0; t < pa.count / 3; t++) {
        const a = P(t * 3), b = P(t * 3 + 1), c = P(t * 3 + 2);
        if (inBox([0, 1, 2].map(k => (a[k] + b[k] + c[k]) / 3))) {
          dropped++;
          for (const v of [t * 3 + 1, t * 3 + 2]) for (let k = 0; k < 3; k++) f.writeFloatLE(a[k], po + (v * 3 + k) * 4);
        }
      }
      return;
    }
    const ia = j.accessors[p.indices], io = view(ia);
    const sz = ia.componentType === 5125 ? 4 : 2;
    const rd = k => sz === 4 ? f.readUInt32LE(io + k * sz) : f.readUInt16LE(io + k * sz);
    const wr = (k, v) => sz === 4 ? f.writeUInt32LE(v, io + k * sz) : f.writeUInt16LE(v, io + k * sz);
    const keep = [];
    for (let t = 0; t < ia.count / 3; t++) {
      const v = [rd(t * 3), rd(t * 3 + 1), rd(t * 3 + 2)];
      const c = [0, 1, 2].map(k => (P(v[0])[k] + P(v[1])[k] + P(v[2])[k]) / 3);
      if (inBox(c)) dropped++; else keep.push(...v);
    }
    keep.forEach((v, k) => wr(k, v));
    ia.count = keep.length;
  });
});
let js = Buffer.from(JSON.stringify(j));
js = Buffer.concat([js, Buffer.alloc((4 - (js.length % 4)) % 4, 0x20)]);
const bin = f.slice(binStart, binStart + f.readUInt32LE(20 + jl));
const h = Buffer.alloc(12); h.writeUInt32LE(0x46546c67, 0); h.writeUInt32LE(2, 4); h.writeUInt32LE(12 + 8 + js.length + 8 + bin.length, 8);
const c1 = Buffer.alloc(8); c1.writeUInt32LE(js.length, 0); c1.writeUInt32LE(0x4e4f534a, 4);
const c2 = Buffer.alloc(8); c2.writeUInt32LE(bin.length, 0); c2.writeUInt32LE(0x004e4942, 4);
fs.writeFileSync(out, Buffer.concat([h, c1, js, c2, bin]));
console.log('Triángulos borrados:', dropped);
