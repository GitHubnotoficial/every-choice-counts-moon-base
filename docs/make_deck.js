// Genera la presentación de Space Apps (7 diapositivas) y una vista previa PNG por diapositiva.
// Uso: node make_deck.js <carpeta del proyecto>
const path = require("path");
const fs = require("fs");
const pptxgen = require("pptxgenjs");
const sharp = require("sharp");

const ROOT = process.argv[2];
const A = (f) => path.join(ROOT, "assets", "slides", f);
const OUT = path.join(ROOT, "docs", "Every_Choice_Counts_Moon_Base.pptx");
const PREV = path.join(__dirname, "preview");
fs.mkdirSync(PREV, { recursive: true });

const W = 10, H = 5.625;
const COL = {
  space: "1A1240", panel: "150E36", lav: "D9D2F5", white: "FFFFFF", gold: "FFD43B", muted: "B8B0E0",
  cap: "E8341C", eng: "FFC93C", life: "2F7BFF", bot: "3DD68C",
};
const HEAD = "Arial", BODY = "Calibri";

// ---------- modelo de diapositivas (se dibuja en pptx y en la vista previa) ----------
const slides = [];
const S = () => { const s = { els: [], notes: "" }; slides.push(s); return s; };
const img = (s, file, x, y, w, h, o = {}) => s.els.push({ t: "img", file, x, y, w, h, ...o });
const rect = (s, x, y, w, h, fill, transp = 0, o = {}) => s.els.push({ t: "rect", x, y, w, h, fill, transp, ...o });
const text = (s, x, y, w, h, runs, o = {}) => s.els.push({ t: "text", x, y, w, h, runs: typeof runs === "string" ? [{ text: runs }] : runs, ...o });
const bg = (s, file, dim) => { img(s, file, 0, 0, W, H, { cover: true }); if (dim) rect(s, 0, 0, W, H, "000000", 100 - dim); };

// 1) Título
{
  const s = S();
  bg(s, "bg23.jpg", 20);
  rect(s, 0.45, 0.45, 6.2, 4.75, COL.panel, 14, { radius: 0.12 });
  text(s, 0.75, 0.65, 5.1, 0.5, "NASA SPACE APPS CHALLENGE 2026", { size: 12, bold: true, color: COL.gold, font: HEAD, cs: 2 });
  text(s, 0.75, 1.05, 5.1, 1.35, "Every Choice Counts: Moon Base", { size: 34, bold: true, color: COL.white, font: HEAD });
  text(s, 0.75, 2.4, 5.6, 0.7, [{ text: "Challenge: ", bold: true, color: COL.gold }, { text: "Build a Junior Astronaut Mission Trainer", color: COL.white }], { size: 15 });
  text(s, 0.75, 3.2, 5.1, 0.35, "TEAM MEMBERS", { size: 11, bold: true, color: COL.muted, font: HEAD, cs: 2 });
  text(s, 0.75, 3.6, 2.55, 1.5, [
    { text: "Larry Jesus Sánchez Silva" }, { text: "Ramón Araujo" }, { text: "Yamir Jhosue Soteldo León" },
  ], { size: 13, color: COL.white, list: true });
  text(s, 3.3, 3.6, 3.15, 1.5, [
    { text: "Isaac Gerardo Daniel Romero Alviarez" }, { text: "María Celeste Salinas Viloria" }, { text: "Letizia Mariel Fernández Carmona" },
  ], { size: 13, color: COL.white, list: true });
  s.notes = "Team Every Choice Counts: Moon Base. Challenge: Build a Junior Astronaut Mission Trainer. A co-op Roblox game for kids 7 to 12.";
}

// 2) Qué es: texto + captura real grande
{
  const s = S();
  bg(s, "bg25.jpg", 55);
  text(s, 0.5, 0.4, 4.5, 0.6, "Plan. Land. Survive.", { size: 26, bold: true, color: COL.white, font: HEAD });
  text(s, 0.5, 1.1, 4.3, 1.3, "A co-op Roblox game: a crew of kids (ages 7–12) prepares a mission on Earth, lands at the Moon's south pole and keeps its base alive for 7 lunar days.", { size: 14, color: COL.lav });
  text(s, 0.5, 2.45, 4.3, 1.4, [
    { text: "No single right answer: every choice has pros and cons" },
    { text: "Each player runs one system, so the crew must talk" },
    { text: "Real space facts appear after every choice" },
  ], { size: 14, color: COL.white, list: true });
  const stats = [["4", "crew roles"], ["4", "phases"], ["7", "lunar days"], ["1–4", "players"]];
  stats.forEach(([n, l], i) => {
    const x = 0.5 + i * 1.08;
    text(s, x, 4.05, 1.05, 0.55, n, { size: 26, bold: true, color: COL.gold, font: HEAD });
    text(s, x, 4.6, 1.05, 0.4, l, { size: 12, color: COL.muted });
  });
  rect(s, 5.05, 0.75, 4.5, 3.75, COL.panel, 0, { radius: 0.1 });
  img(s, "base_wide.jpg", 5.15, 0.85, 4.3, 3.0, { cover: true });
  text(s, 5.2, 3.95, 4.2, 0.5, "Our Moon base in Roblox: lander, habitat, greenhouse and life support", { size: 12, color: COL.muted });
  s.notes = "What it is: a cooperative mission trainer. Kids choose, live with the consequences and learn why NASA plans the way it does.";
}

// 3) Recorrido por fases, cada una con su captura y un ejemplo
{
  const s = S();
  bg(s, "bg21.jpg", 55);
  text(s, 0.5, 0.3, 9, 0.65, "The player's journey", { size: 30, bold: true, color: COL.white, font: HEAD });
  text(s, 0.5, 0.88, 9, 0.4, "About 25 minutes. What you choose in one phase changes the next one.", { size: 14, color: COL.lav });
  const ph = [
    ["PHASE 0 · EARTH", "Pick your gear", "shot_phase0.jpg", "Inspect 3D models, stay under the ship's weight limit, launch.", "Example: Starship carries 240, but arrives a day late."],
    ["PHASE 1 · LANDING", "Land and place", "base_wide.jpg", "Pick 1 of 5 real south-pole sites, then place your module.", "Example: a half-buried habitat cuts radiation in half."],
    ["PHASE 2 · BUILD", "Build the base", "shot_base.jpg", "Hold E for real tasks: tilt panels, change filters, drill ice.", "Example: plant seeds, then watch the sprouts grow."],
    ["PHASE 3 · SURVIVE", "Survive 7 days", "crater2.jpg", "Keep air, water, food and radiation safe. Solve emergencies.", "Example: melt ice in the crater to refill air and water."],
  ];
  ph.forEach(([k, t, f, d, ex], i) => {
    const x = 0.5 + i * 2.3;
    rect(s, x, 1.4, 2.1, 3.9, COL.panel, 8, { radius: 0.1 });
    img(s, f, x + 0.08, 1.48, 1.94, 1.0, { cover: true });
    text(s, x + 0.15, 2.58, 1.85, 0.3, k, { size: 10, bold: true, color: COL.gold, font: HEAD, cs: 1 });
    text(s, x + 0.15, 2.88, 1.85, 0.35, t, { size: 15, bold: true, color: COL.white, font: HEAD });
    text(s, x + 0.15, 3.25, 1.85, 1.0, d, { size: 12, color: COL.lav });
    text(s, x + 0.15, 4.3, 1.85, 0.95, ex, { size: 12, color: COL.gold });
  });
  s.notes = "User experience: four phases, each with a timer. The crew wins together or loses together. If everyone runs out of oxygen, the mission ends.";
}

// 4) Roles: foto del cuarto con los modelos 3D de cada opción
{
  const s = S();
  bg(s, "bg26.jpg", 55);
  text(s, 0.5, 0.3, 9, 0.65, "Four roles, real hardware", { size: 30, bold: true, color: COL.white, font: HEAD });
  text(s, 0.5, 0.88, 9, 0.4, "Each role picks one option in its own room. 3D models made by our team.", { size: 14, color: COL.lav });
  const roles = [
    [COL.cap, "CAPTAIN", "shot_phase0.jpg", "Light lander · Cargo lander · Starship HLS", "Bigger ship = more cargo, but Starship lands a day late."],
    [COL.eng, "ENGINEER", "room_eng.jpg", "Solar panels · Panels + batteries · Fission reactor", "Solar needs sunlight; the reactor works in the shadow."],
    [COL.life, "LIFE SUPPORT", "room_life.jpg", "Electrolyzer · Recycler · Full tanks · Regolith O₂ plant", "The recycler saves water, like the ISS (98%)."],
    [COL.bot, "BOTANIST", "room_bot.jpg", "Regolith kit · Hydroponic racks · Packaged food", "Hydroponics grow faster than Moon soil."],
  ];
  roles.forEach(([c, n, f, opts, ex], i) => {
    const x = 0.5 + (i % 2) * 4.6, y = 1.42 + Math.floor(i / 2) * 1.98;
    rect(s, x, y, 4.4, 1.82, COL.panel, 8, { radius: 0.1 });
    img(s, f, x + 0.1, y + 0.1, 1.75, 1.62, { cover: true });
    text(s, x + 2.0, y + 0.1, 2.3, 0.35, n, { size: 15, bold: true, color: c, font: HEAD });
    text(s, x + 2.0, y + 0.45, 2.3, 0.7, opts, { size: 12, color: COL.white });
    text(s, x + 2.0, y + 1.12, 2.3, 0.65, ex, { size: 12, color: COL.gold });
  });
  s.notes = "Roles map to real mission jobs. Suits and doors are color-coded: red, yellow, blue and green.";
}

// 5) Dentro del juego: lo que el jugador ve en la Luna
{
  const s = S();
  bg(s, "bg27.jpg", 70);
  text(s, 0.5, 0.3, 9, 0.65, "Inside the game", { size: 30, bold: true, color: COL.white, font: HEAD });
  text(s, 0.5, 0.88, 9, 0.4, "Real screenshots from our Roblox build", { size: 14, color: COL.lav });
  const shots = [
    ["habitat2.jpg", "Inside the habitat", "Radiation sensor, CO₂ filter and a storm shelter made of water bags"],
    ["crater2.jpg", "The ice crater", "Hold E to melt ice: it refills the crew's oxygen and water"],
    ["earth.jpg", "Earth in the sky", "Seen low on the horizon, like from the real lunar south pole"],
  ];
  shots.forEach(([f, t, d], i) => {
    const x = 0.5 + i * 3.05;
    rect(s, x, 1.45, 2.85, 3.85, COL.panel, 8, { radius: 0.1 });
    img(s, f, x + 0.08, 1.53, 2.69, 1.9, { cover: true });
    text(s, x + 0.18, 3.55, 2.5, 0.35, t, { size: 15, bold: true, color: COL.white, font: HEAD });
    text(s, x + 0.18, 3.95, 2.5, 1.2, d, { size: 13, color: COL.lav });
  });
  s.notes = "Demo: show the live game here. Walk from Mission Control to the launch, landing, building tasks and one emergency, like a solar flare.";
}

// 6) Datos abiertos de la NASA → lo que pasa en el juego
{
  const s = S();
  bg(s, "bg24.jpg", 65);
  text(s, 0.5, 0.3, 9, 0.65, "Built on NASA open data", { size: 30, bold: true, color: COL.white, font: HEAD });
  text(s, 0.5, 0.88, 9, 0.4, "Every choice and fact comes from a real mission or study", { size: 14, color: COL.lav });
  text(s, 0.65, 1.32, 4.3, 0.3, "NASA SOURCE", { size: 10, bold: true, color: COL.muted, font: HEAD, cs: 2 });
  text(s, 5.05, 1.32, 4.3, 0.3, "IN THE GAME", { size: 10, bold: true, color: COL.muted, font: HEAD, cs: 2 });
  const rows = [
    ["Artemis III regions, LRO lighting", "5 real landing sites with real sunlight (Shackleton rim 85%, Faustini 18%)"],
    ["LCROSS: ice in shadowed craters", "The ice crater refills oxygen and water"],
    ["ISS water recycling (98%), CaRD oxygen from soil (2023)", "Life Support choices and their trade-offs"],
    ["KRUSTY fission test (2018), ISS solar power", "Engineer choices: power for the long shadow"],
    ["ISS Veggie lettuce (2015), plants in Apollo soil (2022)", "Botanist trays: hydroponics grow faster"],
    ["Radiation studies, SDO images of the Sun", "Half-buried habitat; the Sun turns gold in a solar flare"],
  ];
  rows.forEach(([d, g], i) => {
    const y = 1.62 + i * 0.6;
    rect(s, 0.5, y, 9, 0.52, COL.panel, 10, { radius: 0.08 });
    text(s, 0.65, y + 0.03, 4.3, 0.46, d, { size: 12, bold: true, color: COL.gold, valign: "middle" });
    text(s, 5.05, y + 0.03, 4.35, 0.46, g, { size: 12, color: COL.white, valign: "middle" });
  });
  s.notes = "NASA data: sources are listed in the project repository (docs/06-fuentes.md). Game numbers like weights and timers are simplified for kids.";
}

// 7) Impacto y siguientes pasos
{
  const s = S();
  bg(s, "bg28.jpg", 45);
  rect(s, 0.45, 0.45, 4.4, 4.75, COL.panel, 12, { radius: 0.12 });
  text(s, 0.75, 0.6, 3.9, 0.6, "What kids learn", { size: 26, bold: true, color: COL.white, font: HEAD });
  text(s, 0.75, 1.3, 3.9, 3.0, [
    { text: "Trade-offs: ", bold: true, color: COL.gold }, { text: "more cargo, more power or more safety, never all three", br: true },
    { text: "Systems thinking: ", bold: true, color: COL.gold }, { text: "power, air, water and food depend on each other", br: true },
    { text: "Teamwork: ", bold: true, color: COL.gold }, { text: "no one can win alone", br: true },
    { text: "Real science: ", bold: true, color: COL.gold }, { text: "facts from NASA missions after every choice" },
  ], { size: 14, color: COL.white, paras: true });
  text(s, 0.75, 4.45, 3.9, 0.5, "Every choice counts.", { size: 20, bold: true, color: COL.gold, font: HEAD });
  rect(s, 5.15, 0.45, 4.4, 4.75, COL.panel, 12, { radius: 0.12 });
  text(s, 5.45, 0.6, 3.9, 0.6, "Where we are", { size: 26, bold: true, color: COL.white, font: HEAD });
  text(s, 5.45, 1.3, 3.9, 1.6, [
    { text: "Playable from start to end: 4 phases, 4 roles" },
    { text: "Realistic hands-on tasks and 6 emergencies" },
    { text: "3D models made by our team" },
  ], { size: 14, color: COL.white, list: true });
  text(s, 5.45, 2.95, 3.9, 0.45, "NEXT", { size: 12, bold: true, color: COL.gold, font: HEAD, cs: 2 });
  text(s, 5.45, 3.3, 3.9, 1.6, [
    { text: "More emergencies and Moon sites" },
    { text: "Spanish version" },
    { text: "Play tests with kids and teachers" },
  ], { size: 14, color: COL.white, list: true });
  s.notes = "Close: Every choice counts. Thank you.";
}

// ---------- salida PPTX ----------
async function buildPptx() {
  const pres = new pptxgen();
  pres.layout = "LAYOUT_16x9";
  pres.title = "Every Choice Counts: Moon Base";
  pres.theme = { headFontFace: HEAD, bodyFontFace: BODY };
  for (const sd of slides) {
    const sl = pres.addSlide();
    sl.background = { color: COL.space };
    for (const e of sd.els) {
      if (e.t === "img") {
        const o = { path: A(e.file), x: e.x, y: e.y, w: e.w, h: e.h };
        if (e.cover) o.sizing = { type: "cover", w: e.w, h: e.h };
        if (e.radius) o.rounding = false;
        sl.addImage(o);
      } else if (e.t === "rect") {
        sl.addShape(e.radius ? pres.shapes.ROUNDED_RECTANGLE : pres.shapes.RECTANGLE, {
          x: e.x, y: e.y, w: e.w, h: e.h, fill: { color: e.fill, transparency: e.transp }, line: { type: "none" },
          ...(e.radius ? { rectRadius: e.radius } : {}),
        });
      } else if (e.t === "dot") {
        sl.addShape(pres.shapes.OVAL, { x: e.x, y: e.y, w: e.d, h: e.d, fill: { color: e.fill }, line: { color: "FFFFFF", width: 1.5 } });
      } else if (e.t === "text") {
        const base = { fontFace: e.font || BODY, fontSize: e.size, color: e.color, bold: !!e.bold };
        let runs;
        if (e.list) {
          runs = e.runs.map((r, i) => ({ text: r.text, options: { ...base, bullet: { indent: 12 }, paraSpaceAfter: 6, breakLine: i < e.runs.length - 1 } }));
        } else if (e.paras) {
          runs = e.runs.map((r) => ({ text: r.text, options: { ...base, bold: !!r.bold, color: r.color || e.color, breakLine: !!r.br, paraSpaceAfter: r.br ? 10 : 0 } }));
        } else {
          runs = e.runs.map((r) => ({ text: r.text, options: { ...base, bold: r.bold ?? !!e.bold, color: r.color || e.color } }));
        }
        sl.addText(runs, {
          x: e.x, y: e.y, w: e.w, h: e.h, margin: 0, valign: e.valign || "top", isTextBox: true,
          ...(e.cs ? { charSpacing: e.cs } : {}),
        });
      }
    }
    if (sd.notes) sl.addNotes(sd.notes);
  }
  await pres.writeFile({ fileName: OUT });
}

// ---------- vista previa aproximada (SVG → PNG) para revisar tamaños y desbordes ----------
const DPI = 120;
const px = (v) => Math.round(v * DPI);
const esc = (t) => t.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
function wrap(str, maxChars) {
  const words = str.split(" "); const lines = []; let cur = "";
  for (const w of words) { if ((cur + " " + w).trim().length > maxChars) { if (cur) lines.push(cur); cur = w; } else cur = (cur + " " + w).trim(); }
  if (cur) lines.push(cur); return lines;
}
const warnings = [];
async function preview() {
  for (let i = 0; i < slides.length; i++) {
    let svg = `<svg xmlns="http://www.w3.org/2000/svg" width="${px(W)}" height="${px(H)}"><rect width="100%" height="100%" fill="#${COL.space}"/>`;
    for (const e of slides[i].els) {
      if (e.t === "img") {
        const b64 = fs.readFileSync(A(e.file)).toString("base64");
        svg += `<image href="data:image/jpeg;base64,${b64}" x="${px(e.x)}" y="${px(e.y)}" width="${px(e.w)}" height="${px(e.h)}" preserveAspectRatio="xMidYMid slice"/>`;
      } else if (e.t === "rect") {
        svg += `<rect x="${px(e.x)}" y="${px(e.y)}" width="${px(e.w)}" height="${px(e.h)}" rx="${px(e.radius || 0) * 0.6}" fill="#${e.fill}" fill-opacity="${(100 - e.transp) / 100}"/>`;
      } else if (e.t === "dot") {
        svg += `<circle cx="${px(e.x + e.d / 2)}" cy="${px(e.y + e.d / 2)}" r="${px(e.d / 2)}" fill="#${e.fill}" stroke="#fff" stroke-width="2"/>`;
      } else if (e.t === "text") {
        const fpx = e.size / 72 * DPI; const lh = fpx * 1.2;
        const cw = (e.font === HEAD || e.bold) ? 0.56 : 0.5; // ancho medio por carácter
        const maxChars = Math.floor(px(e.w) / (fpx * cw));
        let lines = [];
        if (e.list) e.runs.forEach((r) => wrap("• " + r.text, maxChars).forEach((l, k) => lines.push({ l, gap: k === 0 && lines.length ? 6 : 0 })));
        else if (e.paras) { let p = ""; e.runs.forEach((r) => { p += r.text; if (r.br || r === e.runs[e.runs.length - 1]) { wrap(p, maxChars).forEach((l, k) => lines.push({ l, gap: k === 0 && lines.length ? 10 : 0 })); p = ""; } }); }
        else wrap(e.runs.map((r) => r.text).join(""), maxChars).forEach((l) => lines.push({ l, gap: 0 }));
        let y = px(e.y) + fpx;
        const totalH = lines.reduce((a, b) => a + lh + b.gap / 72 * DPI, 0);
        if (totalH > px(e.h) + 2) warnings.push(`Slide ${i + 1}: text may overflow (${Math.round(totalH)}px > ${px(e.h)}px): "${e.runs[0].text.slice(0, 40)}"`);
        if (e.valign === "middle") y += (px(e.h) - totalH) / 2;
        for (const ln of lines) {
          y += ln.gap / 72 * DPI;
          svg += `<text x="${px(e.x)}" y="${y}" font-family="Arial" font-size="${fpx}" font-weight="${e.bold ? 700 : 400}" fill="#${e.color}">${esc(ln.l)}</text>`;
          y += lh;
        }
      }
    }
    svg += "</svg>";
    await sharp(Buffer.from(svg)).jpeg({ quality: 80 }).toFile(path.join(PREV, `slide-${i + 1}.jpg`));
  }
}

(async () => {
  await buildPptx();
  await preview();
  console.log("OK", OUT);
  console.log(warnings.join("\n") || "no overflow warnings");
})();
