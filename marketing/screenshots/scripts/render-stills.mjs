// Tüm App Store karelerini render eder, alfa kanalını atar (App Store alfa kabul
// etmez) ve docs/app-store/screenshots/{tr,en}/ altına yazar; sonra kontak sayfası.
import { execFileSync } from 'node:child_process';
import { mkdirSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const project = join(here, '..');
const docs = join(project, '..', '..', 'docs', 'app-store', 'screenshots');
// src/copy.ts `fileName` ile aynı olmalı.
const names = {
  '01-feed': { tr: '01-akis', en: '01-feed' },
  '02-add': { tr: '02-kaydet', en: '02-save' },
  '03-reminder': { tr: '03-hatirlatici', en: '03-reminder' },
  '04-collections': { tr: '04-koleksiyonlar', en: '04-collections' },
  '05-share': { tr: '05-paylas', en: '05-share' },
  '06-vault': { tr: '06-gizli-kasa', en: '06-vault' },
  '07-search': { tr: '07-arama', en: '07-search' },
};
const ids = Object.keys(names);
const only = process.argv[2];

for (const locale of ['tr', 'en']) {
  mkdirSync(join(docs, locale), { recursive: true });
  for (const id of ids) {
    if (only && !id.startsWith(only)) continue;
    const out = join(docs, locale, `${names[id][locale]}.png`);
    execFileSync('npx', ['remotion', 'still', 'src/index.ts', `${locale}-${id}`, out, '--image-format=png', '--log=error'], { cwd: project, stdio: 'inherit' });
    execFileSync('python3', [join(here, 'flatten.py'), out], { stdio: 'inherit' });
  }
}
execFileSync('python3', [join(here, 'contact_sheet.py')], { stdio: 'inherit' });
