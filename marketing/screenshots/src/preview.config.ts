// App Preview klip yapılandırması — tek dosyadan ayarlanır.
//
// Kayıtlar: public/recordings/<locale>/<file> (kullanıcının gerçek hesapla
// oynadığı simülatör/cihaz kaydı; 1206x2622 veya 1320x2868). Dosya yoksa
// kompozisyon o klip yerine yer tutucu gösterir.
//
//  start / end : kaynak kayıttaki saniye aralığı (end = null → klip sonu yerine
//                `fallbackSeconds` kadar al)
//  speed       : oynatma hızı (1 = normal, 1.5 = %50 hızlı). Klip süresi
//                (end - start) / speed olur.
//  caption     : klibin üstündeki kısa başlık (storyboard, docs/app-store/screenshots-plan.md)
//
// Toplam süre App Store sınırı için 15–30 sn olmalı; kapanış kartı dahil.
import type { Locale } from './copy';

export type ClipConfig = {
  file: string;
  start: number;
  end: number | null;
  speed: number;
  caption: Record<Locale, string>;
  /** Dile göre farklı kesim (kayıtlar ayrı çekildiği için). Verilmezse üstteki değerler. */
  byLocale?: Partial<Record<Locale, { start: number; end: number | null; speed: number }>>;
};

/** Klibin o dildeki kesimini döndürür. */
export const clipFor = (clip: ClipConfig, locale: Locale): ClipConfig => ({ ...clip, ...(clip.byLocale?.[locale] ?? {}) });

export const previewConfig = {
  fps: 30,
  width: 886,
  height: 1920,
  /** 'card': üstte başlık bandı + altta kayıt kartı (UI'nin hiçbir yeri örtülmez).
   *  'full': kayıt tüm kareyi doldurur (kırpmadan), başlık altta hap olarak. */
  layout: 'card' as 'card' | 'full',
  /** end: null olan klipler için kullanılacak süre (sn). */
  fallbackSeconds: 4.5,
  /** Kapanış kartı süresi (sn). */
  outroSeconds: 3,
  outro: {
    tr: 'Kaydettiklerin sana geri gelsin',
    en: 'Your saves, back when you need them',
  } as Record<Locale, string>,
  clips: [
    // Kayıtlar: kullanıcının gsoreview hesabıyla oynadığı simülatör çekimleri.
    // TR: take-05 (kaydet+hatırlatıcı), take-06 (koleksiyonlar+paylaşım). EN: take-03, take-04.
    // Arama klibi çıkarıldı: arama ekranındaki kaynak çipleri üçüncü taraf logoları gösteriyor.
    { file: '01-save.mp4', start: 24, end: 36, speed: 2, caption: { tr: 'Her yerden kaydet', en: 'Save from anywhere' },
      byLocale: { en: { start: 9.5, end: 29.8, speed: 3 } } },
    { file: '02-reminder.mp4', start: 36, end: 42, speed: 1, caption: { tr: 'Hatırlatıcıyı kur', en: 'Set a reminder' },
      byLocale: { en: { start: 29.8, end: 35.9, speed: 1 } } },
    { file: '03-collections.mp4', start: 16, end: 22.5, speed: 1.2, caption: { tr: 'Hepsi düzenli', en: 'All in order' },
      byLocale: { en: { start: 10.5, end: 17.5, speed: 1.2 } } },
    { file: '05-share.mp4', start: 47.8, end: 59.5, speed: 2, caption: { tr: 'Arkadaşınla paylaş', en: 'Share with friends' },
      byLocale: { en: { start: 20.7, end: 24.7, speed: 1 } } },
  ] as ClipConfig[],
};
