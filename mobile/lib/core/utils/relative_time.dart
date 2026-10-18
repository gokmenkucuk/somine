import 'package:flutter/widgets.dart';
import 'package:timeago/timeago.dart' as timeago;

/// "3 gün önce" / "3 days ago" — uygulamanın aktif diline göre biçimlendirir.
///
/// timeago'nun locale'i tek tek çağrılarda geçilmeli; aksi halde kütüphane
/// varsayılanına ('en') veya sabitlenmiş bir dile düşer.
String formatRelativeTime(BuildContext context, DateTime date) {
  return timeago.format(
    date,
    locale: Localizations.localeOf(context).languageCode,
  );
}
