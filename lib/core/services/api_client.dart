import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:somine_app/core/exceptions/network_exceptions.dart';

class ApiClient {
  final http.Client _inner;
  static const _defaultTimeout = Duration(seconds: 15);
  static const _uploadTimeout = Duration(seconds: 60);

  ApiClient([http.Client? inner]) : _inner = inner ?? http.Client();

  Future<http.Response> get(
    Uri url, {
    Map<String, String>? headers,
  }) async {
    return _inner
        .get(url, headers: headers)
        .timeout(_defaultTimeout, onTimeout: () {
      throw TimeoutException('GET $url timed out',
          userMessage: 'Bağlantı zaman aşımına uğradı. Lütfen tekrar deneyin.');
    });
  }

  Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    return _inner
        .post(url, headers: headers, body: body, encoding: encoding)
        .timeout(_defaultTimeout, onTimeout: () {
      throw TimeoutException('POST $url timed out',
          userMessage: 'Bağlantı zaman aşımına uğradı. Lütfen tekrar deneyin.');
    });
  }

  Future<http.Response> put(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    return _inner
        .put(url, headers: headers, body: body, encoding: encoding)
        .timeout(_defaultTimeout, onTimeout: () {
      throw TimeoutException('PUT $url timed out',
          userMessage: 'Bağlantı zaman aşımına uğradı. Lütfen tekrar deneyin.');
    });
  }

  Future<http.Response> patch(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    return _inner
        .patch(url, headers: headers, body: body, encoding: encoding)
        .timeout(_defaultTimeout, onTimeout: () {
      throw TimeoutException('PATCH $url timed out',
          userMessage: 'Bağlantı zaman aşımına uğradı. Lütfen tekrar deneyin.');
    });
  }

  Future<http.Response> delete(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    return _inner
        .delete(url, headers: headers, body: body, encoding: encoding)
        .timeout(_defaultTimeout, onTimeout: () {
      throw TimeoutException('DELETE $url timed out',
          userMessage: 'Bağlantı zaman aşımına uğradı. Lütfen tekrar deneyin.');
    });
  }

  Future<http.Response> upload(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    return _inner
        .post(url, headers: headers, body: body, encoding: encoding)
        .timeout(_uploadTimeout, onTimeout: () {
      throw TimeoutException('Upload to $url timed out',
          userMessage: 'Yükleme zaman aşımına uğradı. Lütfen tekrar deneyin.');
    });
  }

  void close() {
    _inner.close();
  }
}
