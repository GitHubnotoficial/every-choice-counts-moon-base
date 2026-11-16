// Agrega transiciones Morph (con Fade de respaldo) y animaciones de entrada automáticas a la presentación.
// Uso: node tools/animar_presentacion.js <carpeta del .pptx descomprimido>
// Criterios (buenas prácticas): una sola familia de efectos en todo el deck (Float In suave + Fade en imágenes),
// todo arranca solo tras la transición (sin clics), duraciones cortas (0,5 s), entrada escalonada
// tarjeta por tarjeta en orden de lectura, y el fondo quieto.
const fs = require('fs');
const path = require('path');
const dir = process.argv[2];
const EMU = 914400;

// ---- Textos actualizados (el juego cambió desde que se hizo la presentación) ----
const EDITS = {
  'slide6.xml': [
    ['Radiation studies, SDO images of the Sun', 'DONKI live space weather, SDO Sun images'],
    ['Half-buried habitat; the Sun turns gold in a solar flare', 'When the real Sun is active, flares hit the base more often'],
  ],
  'slide7.xml': [
    ['Realistic hands-on tasks and 6 emergencies', 'Hands-on tasks, 16 emergencies'],
    ['3D models made by our team', 'Live NASA space weather, radio delay'],
    ['More emergencies and Moon sites', 'More Moon sites and missions'],
  ],
};

const TRANSITION =
  '<mc:AlternateContent xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006">' +
  '<mc:Choice xmlns:p159="http://schemas.microsoft.com/office/powerpoint/2015/09/main" Requires="p159">' +
  '<p:transition xmlns:p14="http://schemas.microsoft.com/office/powerpoint/2010/main" spd="slow" p14:dur="900"><p159:morph option="byObject"/></p:transition>' +
  '</mc:Choice><mc:Fallback><p:transition spd="med"><p:fade/></p:transition></mc:Fallback></mc:AlternateContent>';

function shapesOf(xml) {
  const out = [];
  const re = /<p:(sp|pic)>([\s\S]*?)<\/p:\1>/g;
  let m;
  while ((m = re.exec(xml))) {
    const body = m[2];
    const id = +/<p:cNvPr id="(\d+)"/.exec(body)[1];
    const off = /<a:off x="(-?\d+)" y="(-?\d+)"\/><a:ext cx="(\d+)" cy="(\d+)"/.exec(body);
    if (!off) continue;
    const [x, y, w, h] = off.slice(1).map(Number);
    const text = [...body.matchAll(/<a:t>([^<]*)<\/a:t>/g)].map(a => a[1]).join('').trim();
    out.push({ kind: m[1], id, x, y, w, h, text });
  }
  return out;
}

let ctn = 0;
const nid = () => ++ctn;
function floatIn(spid, delay, first) {
  const t = (inner) => `<p:tgtEl><p:spTgt spid="${spid}"/></p:tgtEl>`;
  return `<p:par><p:cTn id="${nid()}" presetID="42" presetClass="entr" presetSubtype="0" fill="hold" grpId="0" nodeType="${first ? 'afterEffect' : 'withEffect'}">` +
    `<p:stCondLst><p:cond delay="${delay}"/></p:stCondLst><p:childTnLst>` +
    `<p:set><p:cBhvr><p:cTn id="${nid()}" dur="1" fill="hold"><p:stCondLst><p:cond delay="0"/></p:stCondLst></p:cTn>${t()}<p:attrNameLst><p:attrName>style.visibility</p:attrName></p:attrNameLst></p:cBhvr><p:to><p:strVal val="visible"/></p:to></p:set>` +
    `<p:animEffect transition="in" filter="fade"><p:cBhvr><p:cTn id="${nid()}" dur="500"/>${t()}</p:cBhvr></p:animEffect>` +
    `<p:anim calcmode="lin" valueType="num"><p:cBhvr><p:cTn id="${nid()}" dur="500" fill="hold"/>${t()}<p:attrNameLst><p:attrName>ppt_x</p:attrName></p:attrNameLst></p:cBhvr><p:tavLst><p:tav tm="0"><p:val><p:strVal val="#ppt_x"/></p:val></p:tav><p:tav tm="100000"><p:val><p:strVal val="#ppt_x"/></p:val></p:tav></p:tavLst></p:anim>` +
    `<p:anim calcmode="lin" valueType="num"><p:cBhvr><p:cTn id="${nid()}" dur="500" decel="100000" fill="hold"/>${t()}<p:attrNameLst><p:attrName>ppt_y</p:attrName></p:attrNameLst></p:cBhvr><p:tavLst><p:tav tm="0"><p:val><p:strVal val="#ppt_y+0.06"/></p:val></p:tav><p:tav tm="100000"><p:val><p:strVal val="#ppt_y"/></p:val></p:tav></p:tavLst></p:anim>` +
    `</p:childTnLst></p:cTn></p:par>`;
}

function timingFor(shapes) {
  // Fondo (imagen y velo que cubren toda la diapositiva) queda quieto
  const full = s => s.w >= 9 * EMU && s.h >= 5 * EMU;
  const items = shapes.filter(s => !full(s));
  // Tarjetas: rectángulos sin texto de más de 2 in²
  const cards = items.filter(s => s.kind === 'sp' && !s.text && (s.w * s.h) / (EMU * EMU) > 2);
  const inside = (c, s) => s.x + s.w / 2 >= c.x && s.x + s.w / 2 <= c.x + c.w && s.y + s.h / 2 >= c.y && s.y + s.h / 2 <= c.y + c.h;
  cards.sort((a, b) => (Math.abs(a.y - b.y) < 0.3 * EMU ? a.x - b.x : a.y - b.y));
  const groups = cards.map(c => ({ c, kids: [] }));
  const loose = [];
  for (const s of items) {
    if (cards.includes(s)) continue;
    const g = groups.find(g => inside(g.c, s));
    if (g) g.kids.push(s); else loose.push(s);
  }
  const byRead = (a, b) => (Math.abs(a.y - b.y) < 0.15 * EMU ? a.x - b.x : a.y - b.y);
  loose.sort(byRead);
  groups.forEach(g => g.kids.sort(byRead));
  const firstCardY = cards.length ? Math.min(...cards.map(c => c.y)) : Infinity;
  const before = loose.filter(s => s.y < firstCardY);
  const after = loose.filter(s => s.y >= firstCardY);

  const seq = []; // [spid, delay]
  let t = 250;
  for (const s of before) { seq.push([s.id, t]); t += 160; }
  for (const g of groups) {
    seq.push([g.c.id, t]);
    let k = t + 90;
    for (const s of g.kids) { seq.push([s.id, k]); k += 70; }
    t += 260;
  }
  for (const s of after) { seq.push([s.id, t]); t += 140; }
  if (!seq.length) return '';

  ctn = 0;
  const root = nid(), main = nid(), click = nid(), grp = nid();
  const effects = seq.map(([id, d], i) => floatIn(id, d, i === 0)).join('');
  const bld = shapes.filter(s => s.kind === 'sp' && seq.some(q => q[0] === s.id))
    .map(s => `<p:bldP spid="${s.id}" grpId="0"${s.text ? ' animBg="1"' : ''}/>`).join('');
  return `<p:timing><p:tnLst><p:par><p:cTn id="${root}" dur="indefinite" restart="never" nodeType="tmRoot"><p:childTnLst>` +
    `<p:seq concurrent="1" nextAc="seek"><p:cTn id="${main}" dur="indefinite" nodeType="mainSeq"><p:childTnLst>` +
    `<p:par><p:cTn id="${click}" fill="hold"><p:stCondLst><p:cond delay="indefinite"/><p:cond evt="onBegin" delay="0"><p:tn val="${main}"/></p:cond></p:stCondLst><p:childTnLst>` +
    `<p:par><p:cTn id="${grp}" fill="hold"><p:stCondLst><p:cond delay="0"/></p:stCondLst><p:childTnLst>${effects}</p:childTnLst></p:cTn></p:par>` +
    `</p:childTnLst></p:cTn></p:par>` +
    `</p:childTnLst></p:cTn><p:prevCondLst><p:cond evt="onPrev" delay="0"><p:tgtEl><p:sldTgt/></p:tgtEl></p:cond></p:prevCondLst>` +
    `<p:nextCondLst><p:cond evt="onNext" delay="0"><p:tgtEl><p:sldTgt/></p:tgtEl></p:cond></p:nextCondLst></p:seq>` +
    `</p:childTnLst></p:cTn></p:par></p:tnLst>${bld ? `<p:bldLst>${bld}</p:bldLst>` : ''}</p:timing>`;
}

const slidesDir = path.join(dir, 'ppt', 'slides');
for (const f of fs.readdirSync(slidesDir).filter(n => /^slide\d+\.xml$/.test(n)).sort((a, b) => parseInt(a.slice(5)) - parseInt(b.slice(5)))) {
  const p = path.join(slidesDir, f);
  let xml = fs.readFileSync(p, 'utf8');
  for (const [a, b] of EDITS[f] || []) {
    if (!xml.includes(a)) console.log(`  AVISO ${f}: no encontré "${a}"`);
    xml = xml.split(a).join(b);
  }
  // Quitar transición/animación previas (si se corre dos veces)
  xml = xml.replace(/<mc:AlternateContent xmlns:mc="[^"]*"><mc:Choice[^>]*Requires="p159">[\s\S]*?<\/mc:AlternateContent>/g, '')
    .replace(/<p:transition[\s\S]*?<\/p:transition>|<p:transition[^>]*\/>/g, '')
    .replace(/<p:timing>[\s\S]*?<\/p:timing>/g, '');
  const shapes = shapesOf(xml);
  const timing = timingFor(shapes);
  const anchor = xml.includes('</p:clrMapOvr>') ? '</p:clrMapOvr>' : '</p:cSld>';
  xml = xml.replace(anchor, anchor + TRANSITION + timing);
  fs.writeFileSync(p, xml);
  console.log(`${f}: ${shapes.length} piezas, ${(timing.match(/presetID="42"/g) || []).length} animadas`);
}
