// App Preview (886x1920, 30 fps, H.264, CRF 14) -> docs/app-store/preview/{tr,en}/somine-app-preview.mp4
// Girdi: public/recordings/<locale>/01-save.mp4 … 05-share.mp4 (yoksa yer tutucu).
// Klip başlangıç/bitiş/hız: src/preview.config.ts
//   node scripts/render-preview.mjs        # TR + EN
//   node scripts/render-preview.mjs tr     # yalnız TR
import { execFileSync } from 'node:child_process';
import { mkdirSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const project = join(here, '..');
const docs = join(project, '..', '..', 'docs', 'app-store', 'preview');
mkdirSync(join(project, 'out'), { recursive: true });
for (const locale of process.argv[2] ? [process.argv[2]] : ['tr', 'en']) {
  const dir = join(docs, locale);
  mkdirSync(dir, { recursive: true });
  const silent = join(project, 'out', `${locale}-preview-silent.mp4`);
  execFileSync('npx', ['remotion', 'render', 'src/index.ts', `AppPreview-${locale}`, silent, '--codec=h264', '--crf=14', '--log=error'],
    { cwd: project, stdio: 'inherit' });
  // App Store Connect önizlemede ses izi bekliyor: sessiz stereo AAC eklenir.
  execFileSync('ffmpeg', ['-v', 'error', '-y', '-i', silent, '-f', 'lavfi', '-i', 'anullsrc=channel_layout=stereo:sample_rate=44100',
    '-shortest', '-c:v', 'copy', '-c:a', 'aac', '-b:a', '256k', join(dir, 'somine-app-preview.mp4')], { stdio: 'inherit' });
  console.log('wrote', join(dir, 'somine-app-preview.mp4'));
}
