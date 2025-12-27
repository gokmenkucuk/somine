// Demo İçerik Listesi - Manuel Tanımlı
const demoMockData = [
  // ========== MÜZİK ==========
  {'cat': 'muzik', 'url': 'https://www.youtube.com/watch?v=LniRqZ0P5cQ', 'title': 'Favori Şarkım', 'imageType': 'youtube', 'imageId': 'LniRqZ0P5cQ'},
  {'cat': 'muzik', 'url': 'https://www.youtube.com/watch?v=eKQuwAmIVKA', 'title': 'Akustik Cover', 'imageType': 'youtube', 'imageId': 'eKQuwAmIVKA'},
  {'cat': 'muzik', 'url': 'https://www.youtube.com/watch?v=a1kAW7UaRXM', 'title': 'Chill Playlist', 'imageType': 'youtube', 'imageId': 'a1kAW7UaRXM'},
  {'cat': 'muzik', 'url': 'https://www.youtube.com/watch?v=hhw90xpY7MI&t=5s', 'title': 'Live Performans', 'imageType': 'youtube', 'imageId': 'hhw90xpY7MI'},
  {'cat': 'muzik', 'url': 'https://www.youtube.com/watch?v=L3cFRU-piHU', 'title': 'Yeni Keşif', 'imageType': 'youtube', 'imageId': 'L3cFRU-piHU'},
  {'cat': 'muzik', 'url': 'https://www.instagram.com/p/CqDArZ3jrXm/?utm_source=ig_web_copy_link&igsh=MzRlODBiNWFlZA==', 'title': 'Konser Anısı', 'imageType': 'local', 'imageId': '336971050_899368541321636_7238265054542234252_n.jpg'},

  // ========== SEYAHAT ==========
  {'cat': 'seyahat', 'url': 'https://www.youtube.com/watch?v=XBOv2tFE5gw', 'title': 'Gezi Rehberi', 'imageType': 'youtube', 'imageId': 'XBOv2tFE5gw'},
  {'cat': 'seyahat', 'url': 'https://www.instagram.com/reel/DSNs_bUDjwx/?utm_source=ig_web_copy_link&igsh=NTc4MTIwNjQ2YQ==', 'title': 'Tatil Anısı', 'imageType': 'local', 'imageId': '590411277_18552782458048321_3343128809874398212_n.jpg'},
  {'cat': 'seyahat', 'url': 'https://www.youtube.com/watch?v=UZphSM4u29k&t=3s', 'title': 'Vlog', 'imageType': 'youtube', 'imageId': 'UZphSM4u29k'},
  {'cat': 'seyahat', 'url': 'https://www.youtube.com/watch?v=B0YhBfHk7lg', 'title': 'Gizli Cennet', 'imageType': 'youtube', 'imageId': 'B0YhBfHk7lg'},
  {'cat': 'seyahat', 'url': 'https://www.instagram.com/reel/DO6oTuxCmqc/?utm_source=ig_web_copy_link&igsh=MzRlODBiNWFlZA==', 'title': 'Keşfet', 'imageType': 'clean', 'imageId': 'instagram'},
  {'cat': 'seyahat', 'url': 'https://www.instagram.com/reel/DPlXtvrDCzw/?utm_source=ig_web_copy_link&igsh=MzRlODBiNWFlZA==', 'title': 'Plaj Keyfi', 'imageType': 'local', 'imageId': '604944784_18072107825592655_5491669218034656074_n.jpg'},
  {'cat': 'seyahat', 'url': 'https://www.youtube.com/shorts/UzCTazYfS0c', 'title': 'Kısa Video', 'imageType': 'youtube', 'imageId': 'UzCTazYfS0c'},

  // ========== RESTAURANT ==========
  {'cat': 'restaurant', 'url': 'https://www.instagram.com/reel/DOmAnXSABOu/?utm_source=ig_web_copy_link&igsh=MzRlODBiNWFlZA==', 'title': 'Lezzet Durağı', 'imageType': 'local', 'imageId': '548511380_17906309481237591_7807588766603122130_n.jpg'},
  {'cat': 'restaurant', 'url': 'https://www.instagram.com/perlosburger/', 'title': 'Perlos Burger', 'imageType': 'clean', 'imageId': 'instagram'},
  {'cat': 'restaurant', 'url': 'https://www.instagram.com/p/DSKusERjNnl', 'title': 'Yeni Mekan', 'imageType': 'local', 'imageId': 'SKusERjNnl.png'},

  // ========== TASARIM ==========
  {'cat': 'tasarim', 'url': 'https://tr.pinterest.com/pin/703756188753159/', 'title': 'Ev Dekorasyonu', 'imageType': 'pinterest', 'imageId': ''},
  {'cat': 'tasarim', 'url': 'https://tr.pinterest.com/pin/2814818512354724/', 'title': 'Modern Tasarım', 'imageType': 'pinterest', 'imageId': ''},
  {'cat': 'tasarim', 'url': 'https://tr.pinterest.com/pin/85990674130764531/', 'title': 'Minimalist', 'imageType': 'pinterest', 'imageId': ''},
  {'cat': 'tasarim', 'url': 'https://tr.pinterest.com/pin/4503668373824349/', 'title': 'İlham Kaynağı', 'imageType': 'pinterest', 'imageId': ''},

  // ========== DOĞUM GÜNÜ ==========
  {'cat': 'dogumgunu', 'url': 'https://tr.pinterest.com/pin/68749089272/', 'title': 'Parti Fikirleri', 'imageType': 'pinterest', 'imageId': ''},
  {'cat': 'dogumgunu', 'url': 'https://tr.pinterest.com/pin/703756186595154/', 'title': 'Dekorasyon', 'imageType': 'pinterest', 'imageId': ''},
  {'cat': 'dogumgunu', 'url': 'https://tr.pinterest.com/pin/140806234300039/', 'title': 'Pasta Fikirleri', 'imageType': 'pinterest', 'imageId': ''},

  // ========== YAZILIM ==========
  {'cat': 'yazilim', 'url': 'https://x.com/acerionsjournal/status/1991481023717154898?s=48', 'title': 'Acerion Yazılım', 'imageType': 'clean', 'imageId': 'x'},
  {'cat': 'yazilim', 'url': 'https://x.com/pelingpt/status/1991798835664810405?s=48', 'title': 'PelinGPT AI', 'imageType': 'clean', 'imageId': 'x'},
  {'cat': 'yazilim', 'url': 'https://x.com/eddyikd2/status/1994912658987127073?s=48', 'title': 'Yazılım İpuçları', 'imageType': 'clean', 'imageId': 'x'},
];
