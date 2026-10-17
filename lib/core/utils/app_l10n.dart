import 'dart:ui';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';

/// BuildContext'i olmayan katmanlar (bildirim planlama gibi servisler) için
/// aktif dilin çevirileri.
///
/// Çözümleme MaterialApp'in kuralıyla aynı: cihaz dili destekleniyorsa o,
/// desteklenmiyorsa ilk desteklenen dil. Context varsa bunun yerine
/// `AppLocalizations.of(context)!` kullanılmalı — o, uygulamanın gerçekten
/// çözdüğü locale'i verir.
AppLocalizations get appL10n {
  final deviceLocale = PlatformDispatcher.instance.locale;
  final supported = AppLocalizations.supportedLocales;
  final match = supported.firstWhere(
    (locale) => locale.languageCode == deviceLocale.languageCode,
    orElse: () => supported.first,
  );
  return lookupAppLocalizations(match);
}
