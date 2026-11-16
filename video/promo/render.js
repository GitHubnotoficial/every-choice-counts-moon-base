// render.js: graba index.html cuadro por cuadro con Chrome y arma el MP4 con ffmpeg (+ narración si hay voz.mp3)
// Uso: node render.js [preview]   (preview = 1 cuadro por segundo, para revisar)
const puppeteer = require('puppeteer-core');
const ffmpeg = require('ffmpeg-static');
const { spawn, spawnSync } = require('child_process');
const fs = require('fs');
const path = require('path');

const CHROME = 'C:/Program Files/Google/Chrome/Application/chrome.exe';
const FPS = 30;
const preview = process.argv[2] === 'preview';

(async () => {
  const b = await puppeteer.launch({ executablePath: CHROME, headless: 'new', args: ['--allow-file-access-from-files'] });
  const p = await b.newPage();
  await p.setViewport({ width: 1280, height: 720 });
  await p.goto('file:///' + path.resolve(__dirname, 'index.html').replace(/\\/g, '/'), { waitUntil: 'networkidle0' });
  await p.evaluate(() => document.fonts.ready);
  // Largo total: el de la narración si existe (+0,8 s), si no 30 s
  let total = 30;
  const voz = path.join(__dirname, 'voz.mp3');
  if (fs.existsSync(voz)) {
    const r = spawnSync(ffmpeg, ['-i', voz], { encoding: 'utf8' });
    const m = /Duration: (\d+):(\d+):([\d.]+)/.exec(r.stderr || '');
    if (m) total = Math.min(30, +m[1] * 3600 + +m[2] * 60 + +m[3] + 0.8);
    await p.evaluate((T) => { const k = T / 30; window.CUTS = window.CUTS.map(c => +(c * k).toFixed(2)); }, total);
  }
  if (preview) {
    fs.mkdirSync(path.join(__dirname, 'prev'), { recursive: true });
    for (let s = 0; s < total; s += 1) {
      await p.evaluate((t) => window.setTime(t), s + 0.5);
      await p.screenshot({ path: path.join(__dirname, 'prev', String(s).padStart(2, '0') + '.jpg'), type: 'jpeg', quality: 80 });
    }
    await b.close(); console.log('preview listo', total); return;
  }
  const out = path.join(__dirname, 'video_sin_audio.mp4');
  const ff = spawn(ffmpeg, ['-y', '-loglevel', 'error', '-f', 'image2pipe', '-framerate', String(FPS), '-c:v', 'mjpeg', '-i', '-',
    '-c:v', 'libx264', '-pix_fmt', 'yuv420p', '-crf', '20', '-preset', 'veryfast', out]);
  const frames = Math.round(total * FPS);
  for (let f = 0; f < frames; f++) {
    await p.evaluate((t) => window.setTime(t), f / FPS);
    const buf = await p.screenshot({ type: 'jpeg', quality: 88 });
    if (!ff.stdin.write(buf)) await new Promise(r => ff.stdin.once('drain', r));
    if (f % 90 === 0) console.log('cuadro', f, '/', frames);
  }
  ff.stdin.end();
  await new Promise(r => ff.on('close', r));
  await b.close();
  // Mezclar la narración
  const final = path.join(__dirname, 'Every_Choice_Counts_Moon_Base_promo.mp4');
  const args = fs.existsSync(voz)
    ? ['-y', '-loglevel', 'error', '-i', out, '-i', voz, '-c:v', 'copy', '-c:a', 'aac', '-b:a', '192k', '-af', 'adelay=300|300', '-t', String(total),
       '-metadata', 'comment=Narration: AI voice generated with ElevenLabs (Brian). Gameplay captured in Roblox.', '-movflags', '+faststart', final]
    : ['-y', '-loglevel', 'error', '-i', out, '-c:v', 'copy', '-metadata', 'comment=Gameplay captured in Roblox.', final];
  const r = spawnSync(ffmpeg, args, { encoding: 'utf8' });
  console.log('final', r.status, (r.stderr || '').slice(-400), final, total);
})();
