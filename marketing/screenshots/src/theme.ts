import { loadFont as loadOutfit } from '@remotion/google-fonts/Outfit';
import { loadFont as loadPoppins } from '@remotion/google-fonts/Poppins';

// Landing sitesiyle aynı aile: başlıklar Outfit, gövde Poppins (api/src/SomineWeb).
export const { fontFamily: display } = loadOutfit('normal', { weights: ['600', '700', '800'], subsets: ['latin', 'latin-ext'] });
export const { fontFamily } = loadPoppins('normal', { weights: ['400', '500', '600'], subsets: ['latin', 'latin-ext'] });

// mobile/lib/core/design/app_colors.dart (Air) + app_theme.dart (Midnight, Vibe).
export const color = {
  mint: '#E8F1EF', white: '#FFFFFF', ink: '#2D312F', body: '#4F5A5E', sage: '#688E8B', sageDeep: '#4E7470', aqua: '#95C5C1',
  midnight: '#0B1220', midnightTop: '#13233A', neon: '#2DD4BF', neonBlue: '#0EA5E9',
  vibe: '#101A26', vibeTop: '#2A1A2E', vibeRed: '#E86B8A',
};

export type Mood = 'air' | 'midnight' | 'vibe';

export const backdrop: Record<Mood, string> = {
  air: `radial-gradient(120% 60% at 50% 0%, #FFFFFF 0%, #F2F8F6 40%, ${color.mint} 100%)`,
  midnight: `radial-gradient(110% 55% at 50% 0%, ${color.midnightTop} 0%, #0E1828 45%, ${color.midnight} 100%)`,
  vibe: `radial-gradient(90% 45% at 50% 8%, #4A2038 0%, ${color.vibeTop} 35%, ${color.vibe} 100%)`,
};

export const textColor: Record<Mood, { title: string; sub: string; accent: string }> = {
  air: { title: color.ink, sub: color.body, accent: color.sageDeep },
  midnight: { title: '#F1F5F9', sub: '#B8C4D4', accent: color.neon },
  vibe: { title: '#F5F5F5', sub: '#D3C4CF', accent: color.vibeRed },
};

// Outfit'in 'tt' gibi bitişik harfleri (ligature) başlıkta tuhaf duruyor: kapalı.
export const headline = { fontFamily: display, fontWeight: 800, letterSpacing: '-0.01em', lineHeight: 1.05, fontVariantLigatures: 'none', fontFeatureSettings: '"liga" 0, "dlig" 0', textWrap: 'balance' } as const;
