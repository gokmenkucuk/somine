import 'package:flutter/widgets.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

/// Kategorisiz içeriklerin sessizce atandığı sistem kategorisi.
///
/// Bu ad veritabanında saklanan bir **mantık anahtarıdır**, çeviri değildir —
/// değiştirilirse mevcut kayıtlarla eşleşme kopar. Kullanıcıya gösterildiği tek
/// yerde [categoryDisplayName] ile diline çevrilir.
const String kQuickCategoryKey = 'Hızlı';

String categoryDisplayName(BuildContext context, String name) {
  if (name != kQuickCategoryKey) return name;
  return AppLocalizations.of(context)!.quickCategoryName;
}
