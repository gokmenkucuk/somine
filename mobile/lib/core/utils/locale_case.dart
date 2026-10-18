import 'package:flutter/widgets.dart';

/// Dart'ın `toUpperCase()`'i yerel ayardan bağımsızdır; Türkçede
/// "i" → "I" (doğrusu "İ") ve "ı" → "I" dönüşümünü bozar.
/// Bu yardımcı, Türkçe (ve Azerice) için noktalı/noktasız i'yi doğru eşler.
String localeUpperCase(String text, Locale locale) {
  final lang = locale.languageCode.toLowerCase();
  if (lang == 'tr' || lang == 'az') {
    return text.replaceAll('i', 'İ').replaceAll('ı', 'I').toUpperCase();
  }
  return text.toUpperCase();
}
