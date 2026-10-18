import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:somine_app/core/utils/html_body_decoder.dart';

void main() {
  const html =
      '<html><head><meta charset="utf-8"><title>Café</title></head></html>';

  test('UTF-8 page without charset header keeps accents', () {
    final res = http.Response.bytes(
      utf8.encode(html),
      200,
      headers: {'content-type': 'text/html'},
    );
    expect(decodeHtmlBody(res), contains('Café'));
  });

  test('header charset wins', () {
    final res = http.Response.bytes(
      latin1.encode('<title>Café</title>'),
      200,
      headers: {'content-type': 'text/html; charset=ISO-8859-1'},
    );
    expect(decodeHtmlBody(res), contains('Café'));
  });

  test('meta charset is sniffed when header is silent', () {
    final res = http.Response.bytes(
      latin1.encode('<meta charset="iso-8859-1"><title>Café</title>'),
      200,
    );
    expect(decodeHtmlBody(res), contains('Café'));
  });
}
