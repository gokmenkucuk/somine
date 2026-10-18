import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

/// "5 Ağu" / "Aug 5" — ay adı ve sıralama uygulamanın diline göre.
///
/// Elle yazılmış ay kısaltması dizileri yalnız tek dilde doğru olduğu için
/// tarih biçimlendirme tek noktadan intl'e bırakıldı.
String formatShortDate(
  BuildContext context,
  DateTime date, {
  bool withYear = false,
}) {
  final locale = Localizations.localeOf(context).toString();
  return withYear
      ? DateFormat.yMMMd(locale).format(date)
      : DateFormat.MMMd(locale).format(date);
}
