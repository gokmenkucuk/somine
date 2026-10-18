import { AbsoluteFill, Img, staticFile } from 'remotion';
import type { Locale, Slot } from './copy';
import { premiumLabel } from './copy';
import { backdrop, color, display, fontFamily, headline, textColor } from './theme';

export type StoreShotProps = { slot: Slot; locale: Locale };

const SCREEN_W = 1000;
const SCREEN_H = Math.round((SCREEN_W * 2868) / 1320);

export const PremiumBadge = ({ mood, scale = 1 }: { mood: Slot['mood']; scale?: number }) => (
  <div style={{
    display: 'inline-flex', alignItems: 'center', gap: 14 * scale, padding: `${14 * scale}px ${34 * scale}px`, borderRadius: 999,
    background: mood === 'air' ? color.ink : 'rgba(255,255,255,0.12)', border: mood === 'air' ? 'none' : '2px solid rgba(255,255,255,0.35)',
    color: '#FFFFFF', fontFamily: display, fontWeight: 700, fontSize: 40 * scale, letterSpacing: '0.02em',
  }}>
    <svg width={34 * scale} height={34 * scale} viewBox="0 0 24 24" fill={mood === 'vibe' ? color.vibeRed : mood === 'midnight' ? color.neon : '#F6C343'}>
      <path d="M12 2l2.9 6.26L22 9.27l-5.2 4.85L18.18 21 12 17.6 5.82 21l1.38-6.88L2 9.27l7.1-1.01z" />
    </svg>
    {premiumLabel['tr']}
  </div>
);

// 1320x2868 App Store görseli: üstte başlık + tek satır destek, altında çerçevesiz,
// köşeleri yuvarlatılmış gerçek uygulama ekranı (simülatörden 1320x2868).
export const StoreShot = ({ slot, locale }: StoreShotProps) => {
  const [title, sub] = slot[locale];
  const t = textColor[slot.mood];
  const dark = slot.mood !== 'air';
  return (
    <AbsoluteFill style={{ background: backdrop[slot.mood], fontFamily, alignItems: 'center' }}>
      <div style={{ position: 'absolute', top: slot.premium ? 84 : 150, left: 80, right: 80, display: 'flex', flexDirection: 'column', alignItems: 'center', textAlign: 'center' }}>
        {slot.premium ? <div style={{ marginBottom: 34 }}><PremiumBadge mood={slot.mood} scale={1.15} /></div> : null}
        <div style={{ ...headline, fontSize: 118, color: t.title }}>{title}</div>
        <div style={{ marginTop: 32, fontSize: 50, fontWeight: 500, lineHeight: 1.3, color: t.sub }}>{sub}</div>
      </div>
      <div style={{
        position: 'absolute', top: 612, width: SCREEN_W, height: SCREEN_H, borderRadius: 92, overflow: 'hidden',
        boxShadow: dark ? '0 50px 140px rgba(0,0,0,0.55)' : '0 50px 140px rgba(60, 100, 95, 0.28)',
        border: dark ? '3px solid rgba(255,255,255,0.14)' : '3px solid rgba(255,255,255,0.9)',
      }}>
        <Img src={staticFile(`raw/${locale}-${slot.id}.png`)} style={{ width: '100%', display: 'block' }} />
      </div>
    </AbsoluteFill>
  );
};
