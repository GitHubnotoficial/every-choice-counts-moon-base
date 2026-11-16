// Narración en inglés con voz neural de Microsoft Edge (gratis). Salida: voz.mp3
const { MsEdgeTTS, OUTPUT_FORMAT } = require('msedge-tts');
const fs = require('fs');
const TEXT = "Four kids. One Moon base. Every choice counts. Captain, Engineer, Life Support, Botanist: choose your gear, launch, and land at a real Artemis site near the lunar south pole. Build the base. Grow food. Keep the air flowing. And watch the sky: solar flares and storms come from real NASA space weather data. Every Choice Counts: Moon Base. Train like an astronaut.";
(async () => {
  const tts = new MsEdgeTTS();
  await tts.setMetadata(process.argv[2] || 'en-US-AndrewMultilingualNeural', OUTPUT_FORMAT.AUDIO_24KHZ_96KBITRATE_MONO_MP3);
  const { audioStream } = tts.toStream(TEXT, { rate: '+4%' });
  const out = fs.createWriteStream('voz.mp3');
  audioStream.pipe(out);
  audioStream.on('end', () => { out.end(); console.log('ok'); });
})();
