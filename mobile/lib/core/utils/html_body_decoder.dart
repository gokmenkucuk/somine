import 'dart:convert';

import 'package:http/http.dart' as http;

/// HTML yanıtını doğru karakter kümesiyle çözer.
///
/// `response.body`, Content-Type başlığında charset yoksa Latin-1 varsayar;
/// UTF-8 sayfalarda "Café" → "CafÃ©" bozulmasına yol açar. Sıra: başlıktaki
/// charset → sayfanın `<meta charset>` bildirimi → UTF-8.
String decodeHtmlBody(http.Response response) {
  final bytes = response.bodyBytes;
  final charset =
      _charsetFrom(response.headers['content-type']) ??
      _sniffMetaCharset(bytes);
  final encoding = charset == null ? null : Encoding.getByName(charset);
  if (encoding != null && encoding != utf8) {
    return encoding.decode(bytes);
  }
  return utf8.decode(bytes, allowMalformed: true);
}

String? _charsetFrom(String? contentType) {
  if (contentType == null) return null;
  final match = RegExp(
    r'charset\s*=\s*"?([\w.:-]+)',
    caseSensitive: false,
  ).firstMatch(contentType);
  return match?.group(1)?.toLowerCase();
}

String? _sniffMetaCharset(List<int> bytes) {
  final head = latin1.decode(
    bytes.length > 4096 ? bytes.sublist(0, 4096) : bytes,
  );
  final match = RegExp(
    r'''<meta[^>]+charset\s*=\s*["']?([\w.:-]+)''',
    caseSensitive: false,
  ).firstMatch(head);
  return match?.group(1)?.toLowerCase();
}
