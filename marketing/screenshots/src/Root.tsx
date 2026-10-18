import { Composition, Folder, Still } from 'remotion';
import { AppPreview, previewMetadata } from './AppPreview';
import { slots, type Locale } from './copy';
import { HeaderShot } from './HeaderShot';
import { StoreShot } from './StoreShot';

const locales: Locale[] = ['tr', 'en'];

export const RemotionRoot = () => (
  <>
    {locales.map((locale) => (
      <Folder key={locale} name={`AppStore-${locale}`}>
        {slots.map((slot) => (
          <Still key={slot.id} id={`${locale}-${slot.id}`} component={StoreShot} width={1320} height={2868} defaultProps={{ slot, locale }} />
        ))}
        <Still id={`${locale}-header`} component={HeaderShot} width={3840} height={1646} defaultProps={{ locale }} />
        <Composition id={`AppPreview-${locale}`} component={AppPreview} width={886} height={1920} fps={30} durationInFrames={900}
          defaultProps={{ locale }} calculateMetadata={previewMetadata} />
      </Folder>
    ))}
  </>
);
