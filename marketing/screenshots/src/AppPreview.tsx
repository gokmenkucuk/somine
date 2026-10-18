import { AbsoluteFill, Easing, Img, interpolate, OffthreadVideo, Sequence, staticFile, useCurrentFrame } from 'remotion';
import type { CalculateMetadataFunction } from 'remotion';
import type { Locale } from './copy';
import { previewConfig, type ClipConfig } from './preview.config';
import { backdrop, color, fontFamily, headline } from './theme';

// App Store önizlemesi (886x1920, 30 fps). Görüntü tamamen kullanıcının gerçek
// uygulama kaydıdır (Apple 2.3.4); Remotion yalnız kısa başlık, geçiş ve
// kapanış kartı ekler. Klipler ve süreler: src/preview.config.ts
export type PreviewProps = { locale: Locale; available?: boolean[] };

const { fps, width: W, height: H } = previewConfig;
const OUTRO = Math.round(previewConfig.outroSeconds * fps);

const clipFrames = (c: ClipConfig) =>
  Math.max(1, Math.round((((c.end ?? c.start + previewConfig.fallbackSeconds) - c.start) / c.speed) * fps));

const timeline = () => {
  let from = 0;
  return previewConfig.clips.map((clip) => {
    const length = clipFrames(clip);
    const item = { clip, from, length };
    from += length;
    return item;
  });
};

const src = (locale: Locale, file: string) => staticFile(`recordings/${locale}/${file}`);

// Hangi kayıtların gerçekten var olduğunu render/önizleme öncesinde kontrol eder.
export const previewMetadata: CalculateMetadataFunction<PreviewProps> = async ({ props }) => {
  const available = await Promise.all(
    previewConfig.clips.map(async (c) => {
      try {
        const res = await fetch(src(props.locale, c.file), { method: 'HEAD' });
        return res.ok && !(res.headers.get('content-type') ?? '').includes('text/html');
      } catch {
        return false;
      }
    }),
  );
  const items = timeline();
  const last = items[items.length - 1];
  return { durationInFrames: last.from + last.length + OUTRO, props: { ...props, available } };
};

// Kayıt alanı: kaynak 1206x2622 / 1320x2868 → kırpmadan (contain) ölçeklenir.
const cardW = 760;
const cardH = Math.round((cardW * 2868) / 1320);

const Caption = ({ text, full }: { text: string; full: boolean }) => {
  const frame = useCurrentFrame();
  const enter = interpolate(frame, [0, 10], [0, 1], { extrapolateRight: 'clamp', easing: Easing.bezier(0.16, 1, 0.3, 1) });
  if (full) {
    return (
      <div style={{ position: 'absolute', left: 60, right: 60, bottom: 120, padding: '26px 30px', borderRadius: 999, background: color.ink, color: '#FFFFFF',
        fontFamily, fontSize: 44, fontWeight: 600, textAlign: 'center', opacity: enter, translate: `0px ${(1 - enter) * 30}px` }}>{text}</div>
    );
  }
  return (
    <div style={{ position: 'absolute', top: 92, left: 40, right: 40, textAlign: 'center', ...headline, fontSize: 64, color: color.ink,
      opacity: enter, translate: `0px ${(1 - enter) * 24}px` }}>{text}</div>
  );
};

const Placeholder = ({ locale, file }: { locale: Locale; file: string }) => (
  <AbsoluteFill style={{ background: '#DCE8E5', alignItems: 'center', justifyContent: 'center', padding: 60, textAlign: 'center', fontFamily, color: color.body }}>
    <div style={{ fontSize: 40, fontWeight: 600 }}>{locale === 'tr' ? 'Kayıt bekleniyor' : 'Recording missing'}</div>
    <div style={{ marginTop: 20, fontSize: 28 }}>public/recordings/{locale}/{file}</div>
  </AbsoluteFill>
);

const Clip = ({ locale, clip, ok }: { locale: Locale; clip: ClipConfig; ok: boolean }) => {
  const frame = useCurrentFrame();
  const fade = interpolate(frame, [0, 6], [0, 1], { extrapolateRight: 'clamp' });
  return (
    <AbsoluteFill style={{ opacity: fade }}>
      {ok ? (
        <OffthreadVideo src={src(locale, clip.file)} startFrom={Math.round(clip.start * fps)} playbackRate={clip.speed} muted
          style={{ width: '100%', height: '100%', objectFit: 'contain' }} />
      ) : (
        <Placeholder locale={locale} file={clip.file} />
      )}
    </AbsoluteFill>
  );
};

const Outro = ({ locale }: { locale: Locale }) => {
  const frame = useCurrentFrame();
  const fade = interpolate(frame, [0, 12], [0, 1], { extrapolateRight: 'clamp' });
  return (
    <AbsoluteFill style={{ background: backdrop.air, alignItems: 'center', justifyContent: 'center', gap: 56, opacity: fade, fontFamily }}>
      <Img src={staticFile('appicon.png')} style={{ width: 240, height: 240, borderRadius: 56, boxShadow: '0 30px 80px rgba(60,100,95,0.3)' }} />
      <Img src={staticFile('logo-transparent.png')} style={{ height: 120 }} />
      <div style={{ ...headline, fontSize: 60, color: color.ink, textAlign: 'center', paddingInline: 80 }}>{previewConfig.outro[locale]}</div>
    </AbsoluteFill>
  );
};

export const AppPreview = ({ locale, available }: PreviewProps) => {
  const items = timeline();
  const end = items[items.length - 1].from + items[items.length - 1].length;
  const full = previewConfig.layout === 'full';
  const box = full
    ? { top: 0, left: 0, width: W, height: H, borderRadius: 0 }
    : { top: 240, left: (W - cardW) / 2, width: cardW, height: cardH, borderRadius: 64,
        border: '3px solid rgba(255,255,255,0.95)', boxShadow: '0 40px 110px rgba(60,100,95,0.3)' };
  return (
    <AbsoluteFill style={{ background: backdrop.air }}>
      <div style={{ position: 'absolute', overflow: 'hidden', background: color.mint, ...box }}>
        {items.map(({ clip, from, length }, i) => (
          <Sequence key={clip.file} from={from} durationInFrames={length} premountFor={fps}>
            <Clip locale={locale} clip={clip} ok={available?.[i] ?? false} />
          </Sequence>
        ))}
      </div>
      {items.map(({ clip, from, length }) => (
        <Sequence key={`c-${clip.file}`} from={from} durationInFrames={length}>
          <Caption text={clip.caption[locale]} full={full} />
        </Sequence>
      ))}
      <Sequence from={end} durationInFrames={OUTRO}>
        <Outro locale={locale} />
      </Sequence>
    </AbsoluteFill>
  );
};
