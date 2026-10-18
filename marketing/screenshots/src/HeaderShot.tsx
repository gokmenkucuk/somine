import type { CSSProperties } from 'react';
import { AbsoluteFill, Img, staticFile } from 'remotion';
import type { Locale } from './copy';
import { backdrop, color, fontFamily, headline } from './theme';

export type HeaderProps = { locale: Locale };

const copy: Record<Locale, { title: string; sub: string }> = {
  tr: { title: 'Kaydettiklerin sana geri gelsin', sub: 'Her uygulamadan kaydet, koleksiyonlara ayır, doğru zamanda hatırla.' },
  en: { title: 'Your saves, back when you need them', sub: 'Save from any app, sort into collections, get reminded at the right time.' },
};

const Screen = ({ src, width, style }: { src: string; width: number; style?: CSSProperties }) => (
  <div style={{ position: 'absolute', width, height: (width * 2868) / 1320, borderRadius: width * 0.1, overflow: 'hidden',
    border: '4px solid rgba(255,255,255,0.95)', boxShadow: '0 60px 160px rgba(60, 100, 95, 0.32)', ...style }}>
    <Img src={staticFile(src)} style={{ width: '100%', display: 'block' }} />
  </div>
);

// App Store başlık görseli (3840x1646). Ana içerik ortadaki %80'lik alanda
// kalır; küçük ekranlarda kenarlar kırpılabilir. Ekranlar gerçek simülatör çekimi.
export const HeaderShot = ({ locale }: HeaderProps) => {
  const c = copy[locale];
  return (
    <AbsoluteFill style={{ background: backdrop.air, fontFamily, flexDirection: 'row', alignItems: 'center', paddingInline: 420 }}>
      <div style={{ flex: 1, display: 'flex', flexDirection: 'column', gap: 60, paddingRight: 80 }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 40 }}>
          <Img src={staticFile('appicon.png')} style={{ width: 170, height: 170, borderRadius: 40, boxShadow: '0 20px 50px rgba(60,100,95,0.25)' }} />
          <Img src={staticFile('logo-transparent.png')} style={{ height: 120 }} />
        </div>
        <div style={{ ...headline, fontSize: 150, color: color.ink, maxWidth: 1650 }}>{c.title}</div>
        <div style={{ fontSize: 60, fontWeight: 500, lineHeight: 1.35, color: color.body, maxWidth: 1500 }}>{c.sub}</div>
      </div>
      <div style={{ position: 'relative', width: 1380, height: 1646 }}>
        <Screen src={`raw/${locale}-04-collections-shelf.png`} width={500} style={{ left: 0, top: 300, rotate: '-6deg' }} />
        <Screen src={`raw/${locale}-07-search.png`} width={500} style={{ right: 0, top: 300, rotate: '6deg' }} />
        <Screen src={`raw/${locale}-01-feed.png`} width={560} style={{ left: 410, top: 170 }} />
      </div>
    </AbsoluteFill>
  );
};
