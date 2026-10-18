import type { Mood } from './theme';

export type Locale = 'tr' | 'en';
export type Slot = { id: string; mood: Mood; premium?: boolean; tr: [string, string]; en: [string, string] };

// docs/app-store/screenshots-plan.md slot sırası. Plandaki 6. slot (widget)
// gerçek uygulama ekranıyla gösterilemediği için çıkarıldı; sonrakiler bir kaydı.
// Başlık ≤6 kelime + tek satır destek cümlesi. Fiyat ve doğrulanamaz iddia yok.
export const slots: Slot[] = [
  { id: '01-feed', mood: 'air', tr: ['Kaydettiklerin kaybolmasın', 'Linkler, mekânlar, tarifler tek yerde.'], en: ['Never lose a save again', 'Links, places and recipes in one spot.'] },
  { id: '02-add', mood: 'air', tr: ['Her uygulamadan kaydet', 'Paylaş’a dokun, koleksiyonunu seç.'], en: ['Save from any app', 'Tap Share, then pick a collection.'] },
  { id: '03-reminder', mood: 'air', tr: ['Doğru zamanda hatırlatır', 'Yarın mı, hafta sonu mu? Sen seç.'], en: ['Reminded at the right time', 'Tomorrow or this weekend, you choose.'] },
  { id: '04-collections', mood: 'air', tr: ['Her şey koleksiyonunda', 'Geziler, restoranlar, müzik ve ilham.'], en: ['Everything in its collection', 'Trips, restaurants, music and ideas.'] },
  { id: '05-share', mood: 'midnight', premium: true, tr: ['Arkadaşlarınla paylaş', 'Kişiyle ya da bağlantıyla paylaş.'], en: ['Share collections with friends', 'Send to a friend or share a link.'] },
  { id: '06-vault', mood: 'vibe', premium: true, tr: ['Gizli Kasa, Face ID ile', 'Özel koleksiyonların kilit altında.'], en: ['Private Vault with Face ID', 'Your private collections stay locked.'] },
  { id: '07-search', mood: 'air', tr: ['Aradığını hemen bul', 'Yazım hatası yapsan da bulur.'], en: ['Find anything in seconds', 'Typos included.'] },
];

export const fileName: Record<string, Record<Locale, string>> = {
  '01-feed': { tr: '01-akis', en: '01-feed' },
  '02-add': { tr: '02-kaydet', en: '02-save' },
  '03-reminder': { tr: '03-hatirlatici', en: '03-reminder' },
  '04-collections': { tr: '04-koleksiyonlar', en: '04-collections' },
  '05-share': { tr: '05-paylas', en: '05-share' },
  '06-vault': { tr: '06-gizli-kasa', en: '06-vault' },
  '07-search': { tr: '07-arama', en: '07-search' },
};

export const premiumLabel: Record<Locale, string> = { tr: 'Premium', en: 'Premium' };
