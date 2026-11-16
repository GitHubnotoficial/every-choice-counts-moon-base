// Quita de un .glb los nodos cuyas mallas coinciden con una expresión regular y compacta el archivo.
// Uso: node tools/modelos3d/strip_meshes.js entrada.glb salida.glb "^(Entry ramp|Ramp )" [imagen_nueva.jpg|png]
// Si se da imagen_nueva, reemplaza la imagen 0 (para aligerar texturas pesadas).
const fs = require('fs');
const [, , inp, out, pattern, newImage] = process.argv;
const re = new RegExp(pattern);
const f = fs.readFileSync(inp);
const jl = f.readUInt32LE(12);
const j = JSON.parse(f.slice(20, 20 + jl));
const binStart = 20 + jl + 8;
const bin = f.slice(binStart, binStart + f.readUInt32LE(20 + jl));

// 1) Nodos a quitar
const drop = new Set();
j.nodes.forEach((n, i) => { if (n.mesh != null && re.test(j.meshes[n.mesh].name || '') && !(n.children || []).length) drop.add(i); });
const removedNames = [...drop].map(i => j.meshes[j.nodes[i].mesh].name);

// 2) Reindexar nodos
const nodeMap = new Map(); const nodes = [];
j.nodes.forEach((n, i) => { if (!drop.has(i)) { nodeMap.set(i, nodes.length); nodes.push(n); } });
nodes.forEach(n => { if (n.children) n.children = n.children.filter(c => !drop.has(c)).map(c => nodeMap.get(c)); });
j.scenes.forEach(s => { s.nodes = s.nodes.filter(c => !drop.has(c)).map(c => nodeMap.get(c)); });
j.nodes = nodes;

// 3) Mallas usadas
const meshMap = new Map(); const meshes = [];
nodes.forEach(n => { if (n.mesh != null) { if (!meshMap.has(n.mesh)) { meshMap.set(n.mesh, meshes.length); meshes.push(j.meshes[n.mesh]); } n.mesh = meshMap.get(n.mesh); } });
j.meshes = meshes;

// 4) Accessors y bufferViews usados, buffer nuevo
const accMap = new Map(); const accessors = []; const bvMap = new Map(); const bufferViews = []; const parts = []; let off = 0;
const useBV = bv => {
  if (bvMap.has(bv)) return bvMap.get(bv);
  const v = j.bufferViews[bv]; const data = bin.slice(v.byteOffset || 0, (v.byteOffset || 0) + v.byteLength);
  const pad = (4 - (data.length % 4)) % 4; parts.push(data, Buffer.alloc(pad));
  const nv = { ...v, byteOffset: off }; off += data.length + pad; bufferViews.push(nv);
  bvMap.set(bv, bufferViews.length - 1); return bufferViews.length - 1;
};
const useAcc = a => {
  if (accMap.has(a)) return accMap.get(a);
  const acc = { ...j.accessors[a] }; if (acc.bufferView != null) acc.bufferView = useBV(acc.bufferView);
  accessors.push(acc); accMap.set(a, accessors.length - 1); return accessors.length - 1;
};
meshes.forEach(m => m.primitives.forEach(p => {
  for (const k of Object.keys(p.attributes)) p.attributes[k] = useAcc(p.attributes[k]);
  if (p.indices != null) p.indices = useAcc(p.indices);
}));
// Imágenes (texturas) incrustadas
(j.images || []).forEach((im, i) => {
  if (im.bufferView == null) return;
  if (i === 0 && newImage) {
    const data = fs.readFileSync(newImage);
    const pad = (4 - (data.length % 4)) % 4; parts.push(data, Buffer.alloc(pad));
    bufferViews.push({ buffer: 0, byteOffset: off, byteLength: data.length }); off += data.length + pad;
    im.bufferView = bufferViews.length - 1;
    im.mimeType = newImage.toLowerCase().endsWith('.png') ? 'image/png' : 'image/jpeg';
  } else im.bufferView = useBV(im.bufferView);
});
j.accessors = accessors; j.bufferViews = bufferViews;
const nbin = Buffer.concat(parts); j.buffers = [{ byteLength: nbin.length }];

let js = Buffer.from(JSON.stringify(j)); js = Buffer.concat([js, Buffer.alloc((4 - (js.length % 4)) % 4, 0x20)]);
const h = Buffer.alloc(12); h.writeUInt32LE(0x46546c67, 0); h.writeUInt32LE(2, 4); h.writeUInt32LE(12 + 8 + js.length + 8 + nbin.length, 8);
const c1 = Buffer.alloc(8); c1.writeUInt32LE(js.length, 0); c1.writeUInt32LE(0x4e4f534a, 4);
const c2 = Buffer.alloc(8); c2.writeUInt32LE(nbin.length, 0); c2.writeUInt32LE(0x004e4942, 4);
fs.writeFileSync(out, Buffer.concat([h, c1, js, c2, nbin]));

// Resumen
let mn = [Infinity, Infinity, Infinity], mx = [-Infinity, -Infinity, -Infinity], tris = 0;
meshes.forEach(m => m.primitives.forEach(p => { const a = accessors[p.attributes.POSITION];
  for (let c = 0; c < 3; c++) { mn[c] = Math.min(mn[c], a.min[c]); mx[c] = Math.max(mx[c], a.max[c]); }
  tris += p.indices != null ? accessors[p.indices].count / 3 : a.count / 3; }));
console.log('Quitadas', removedNames.length, 'piezas:', removedNames.join(', '));
console.log('Quedan', meshes.length, 'mallas,', tris, 'triángulos');
console.log('Caja:', mn.map(x => x.toFixed(2)).join(', '), '→', mx.map(x => x.toFixed(2)).join(', '));
