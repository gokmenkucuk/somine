// Mağaza başlık görseli (3840x1646, alfasız) -> docs/app-store/header/{tr,en}/somine-header.png
import { execFileSync } from 'node:child_process';
import { mkdirSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const project = join(here, '..');
const docs = join(project, '..', '..', 'docs', 'app-store', 'header');
for (const locale of ['tr', 'en']) {
  const dir = join(docs, locale);
  mkdirSync(dir, { recursive: true });
  const out = join(dir, 'somine-header.png');
  execFileSync('npx', ['remotion', 'still', 'src/index.ts', `${locale}-header`, out, '--image-format=png', '--log=error'], { cwd: project, stdio: 'inherit' });
  execFileSync('python3', [join(here, 'flatten.py'), out], { stdio: 'inherit' });
}
