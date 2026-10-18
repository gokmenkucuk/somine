import { Config } from '@remotion/cli/config';

// Ekran görüntülerindeki küçük metin bulanıklaşmasın: kayıpsız kareler, düşük CRF.
Config.setVideoImageFormat('png');
Config.setCrf(14);
Config.setPixelFormat('yuv420p');
