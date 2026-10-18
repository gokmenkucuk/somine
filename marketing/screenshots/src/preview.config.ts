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
};

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
    { file: '01-save.mp4', start: 0, end: 5, speed: 1, caption: { tr: 'Her yerden kaydet', en: 'Save from anywhere' } },
    { file: '02-reminder.mp4', start: 0, end: 5, speed: 1, caption: { tr: 'Hatırlatıcıyı kur', en: 'Set a reminder' } },
    { file: '03-collections.mp4', start: 0, end: 5, speed: 1, caption: { tr: 'Hepsi düzenli', en: 'All in order' } },
    { file: '04-search.mp4', start: 0, end: 4.5, speed: 1, caption: { tr: 'Aradığını hemen bul', en: 'Find it in seconds' } },
    { file: '05-share.mp4', start: 0, end: 4.5, speed: 1, caption: { tr: 'Arkadaşınla paylaş', en: 'Share with friends' } },
  ] as ClipConfig[],
};
