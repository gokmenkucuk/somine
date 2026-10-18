// Ekran görüntüsü düzeneği için sahte backend.
//
// `HttpOverrides.global` ile uygulamanın tüm dart:io HTTP trafiği bu katmandan
// geçer. Sahte alan adları (somine API'si, fixture görselleri, `.example`
// bağlantıları) burada yanıtlanır; geri kalan her şey (ör. Google Fonts)
// gerçek ağa gider. Böylece gerçek ekranlar gerçek repository kodlarıyla,
// ama yalnızca fixture verisiyle çizilir; üretim API'sine istek gitmez.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:somine_app/core/config/api_config.dart';

import 'fixture_images.g.dart';
import 'fake_platform.dart' show fixtureUid;
import 'fixtures.dart';

class FixtureBackend {
  FixtureBackend();

  /// 'tr' veya 'en' — hangi demo hesabın verisi döneceği.
  String locale = 'tr';

  /// Gizli Kasa karesinde kasa koleksiyonu raf başında görünsün diye.
  bool vaultFirst = false;

  final Map<String, Uint8List> _imageCache = {};

  String get _apiHost => Uri.parse(ApiConfig.baseUrl).host;

  bool handles(Uri uri) =>
      uri.host == _apiHost ||
      uri.host == fixtureImageHost ||
      uri.host.endsWith('.example');

  Uint8List _image(String name) => _imageCache.putIfAbsent(
    name,
    () => base64Decode(fixtureImagesBase64[name] ?? ''),
  );

  // ---------------------------------------------------------------- JSON

  DateTime get _now => DateTime.now().toUtc();

  Map<String, dynamic> _categoryJson(FixtureCategory c, int order) => {
    'id': c.id,
    'name': locale == 'tr' ? c.tr : c.en,
    'icon': c.icon,
    'color': c.color,
    'sortOrder': order,
    'isVault': c.isVault,
    'publicLinkToken': null,
    'createdAt': _now.subtract(const Duration(days: 60)).toIso8601String(),
    'updatedAt': _now.subtract(const Duration(days: 1)).toIso8601String(),
  };

  Map<String, dynamic> _itemJson(FixtureItem item, int index) => {
    'id': item.id,
    'categoryId': item.categoryId,
    'type': 0,
    'url': item.url(locale),
    'note': null,
    'imageUrl': null,
    'ogTitle': item.title(locale),
    'ogDescription': null,
    'ogImageUrl': fixtureImageUrl(item.image),
    'ogSiteName': null,
    'ogImageWidth': item.width,
    'ogImageHeight': item.height,
    'isFavorite': item.isFavorite,
    'sortOrder': 0,
    'hasReminder': item.hasReminder,
    'createdAt':
        _now.subtract(Duration(hours: 3 + index * 7)).toIso8601String(),
    'updatedAt':
        _now.subtract(Duration(hours: 3 + index * 7)).toIso8601String(),
    'lastOpenedAt': null,
  };

  List<Map<String, dynamic>> _items({String? categoryId, String? query}) {
    final result = <Map<String, dynamic>>[];
    for (var i = 0; i < fixtureItems.length; i++) {
      final item = fixtureItems[i];
      if (categoryId != null && item.categoryId != categoryId) continue;
      if (query != null && !_fuzzyMatch(item.title(locale), query)) continue;
      result.add(_itemJson(item, i));
    }
    return result;
  }

  Map<String, dynamic> _page(
    List<Map<String, dynamic>> all,
    Map<String, String> q,
  ) {
    final page = int.tryParse(q['page'] ?? '') ?? 1;
    final limit = int.tryParse(q['limit'] ?? '') ?? 20;
    final start = ((page - 1) * limit).clamp(0, all.length);
    final end = (start + limit).clamp(0, all.length);
    return {
      'items': all.sublist(start, end),
      'totalCount': all.length,
      'page': page,
      'limit': limit,
    };
  }

  // Sunucudaki unaccent + trigram aramasının kaba bir taklidi: Türkçe
  // karakterleri sadeleştirir ve kelime başına 2 harf hataya izin verir.
  static String _fold(String s) => s
      .toLowerCase()
      .replaceAll('ı', 'i')
      .replaceAll('İ', 'i')
      .replaceAll('ş', 's')
      .replaceAll('ğ', 'g')
      .replaceAll('ü', 'u')
      .replaceAll('ö', 'o')
      .replaceAll('ç', 'c')
      .replaceAll(RegExp(r"[^a-z0-9 ]"), ' ');

  static int _lev(String a, String b) {
    final d = List.generate(a.length + 1, (i) => List.filled(b.length + 1, 0));
    for (var i = 0; i <= a.length; i++) {
      d[i][0] = i;
    }
    for (var j = 0; j <= b.length; j++) {
      d[0][j] = j;
    }
    for (var i = 1; i <= a.length; i++) {
      for (var j = 1; j <= b.length; j++) {
        d[i][j] = [
          d[i - 1][j] + 1,
          d[i][j - 1] + 1,
          d[i - 1][j - 1] + (a[i - 1] == b[j - 1] ? 0 : 1),
        ].reduce((x, y) => x < y ? x : y);
      }
    }
    return d[a.length][b.length];
  }

  static bool _fuzzyMatch(String title, String query) {
    final q = _fold(query).trim();
    if (q.isEmpty) return false;
    for (final word in _fold(title).split(' ')) {
      if (word.isEmpty) continue;
      if (word.contains(q)) return true;
      final prefix = word.length > q.length ? word.substring(0, q.length) : word;
      if (_lev(prefix, q) <= 2 && q.length >= 4) return true;
    }
    return false;
  }

  Map<String, dynamic> get _friend => {
    'id': friendUserId,
    'email': 'mert@example.com',
    'displayName': friendDisplayName,
    'username': friendUsername,
    'photoBase64': null,
    'photoUrl': null,
  };

  List<Map<String, dynamic>> _outgoingShares() => [
    {
      'id': 'share-01',
      'fromUserId': fixtureUid,
      'fromUserName': 'Ayşe',
      'fromUserEmail': 'ayse@example.com',
      'toUserId': friendUserId,
      'toUserEmail': 'mert@example.com',
      'categoryId': catKas,
      'categoryName': locale == 'tr' ? 'Kaş' : 'Kaş',
      'status': 'accepted',
      'createdAt': _now.subtract(const Duration(days: 3)).toIso8601String(),
      'acceptedAt': _now.subtract(const Duration(days: 2)).toIso8601String(),
    },
  ];

  List<Map<String, dynamic>> _incomingShares() => [
    {
      'id': 'share-02',
      'fromUserId': friendUserId,
      'fromUserName': friendDisplayName,
      'fromUserEmail': 'mert@example.com',
      'toUserId': fixtureUid,
      'toUserEmail': 'ayse@example.com',
      'categoryId': 'cat-mert-amsterdam',
      'categoryName':
          locale == 'tr' ? 'Amsterdam Hafta Sonu' : 'Amsterdam Weekend',
      'status': 'pending',
      'createdAt': _now.subtract(const Duration(minutes: 12)).toIso8601String(),
    },
  ];

  // --------------------------------------------------------------- Router

  ({int status, String contentType, List<int> body}) respond(
    String method,
    Uri uri, [
    List<int> requestBody = const [],
  ]) {
    if (uri.host == fixtureImageHost) {
      final name = uri.pathSegments.isEmpty
          ? ''
          : uri.pathSegments.last.replaceAll('.jpg', '');
      final bytes = _image(name);
      if (bytes.isEmpty) return (status: 404, contentType: 'text/plain', body: const []);
      return (status: 200, contentType: 'image/jpeg', body: bytes);
    }

    if (uri.host.endsWith('.example')) {
      final isAddFlow =
          uri.path.contains(addFlowSlugTr) || uri.path.contains(addFlowSlugEn);
      final slug = uri.pathSegments.isEmpty ? '' : uri.pathSegments.last;
      final match = fixtureItems.where((i) => i.slug == slug).firstOrNull;
      final title = isAddFlow
          ? (locale == 'tr' ? addFlowTitleTr : addFlowTitleEn)
          : (match?.title(locale) ?? slug);
      final image = isAddFlow ? addFlowImage : (match?.image ?? addFlowImage);
      final html = '<!doctype html><html><head>'
          '<title>$title</title>'
          '<meta property="og:title" content="$title">'
          '<meta property="og:image" content="${fixtureImageUrl(image)}">'
          '</head><body></body></html>';
      return (status: 200, contentType: 'text/html; charset=utf-8', body: utf8.encode(html));
    }

    final path = uri.path;
    final q = uri.queryParameters;
    Object? json;
    var status = 200;

    if (method == 'GET') {
      if (path == '/api/categories') {
        final cats = [...fixtureCategories];
        if (vaultFirst) {
          final v = cats.firstWhere((c) => c.isVault);
          cats
            ..remove(v)
            ..insert(0, v);
        }
        json = [
          for (var i = 0; i < cats.length; i++) _categoryJson(cats[i], i),
        ];
      } else if (path == '/api/items') {
        json = _page(_items(categoryId: q['categoryId']), q);
      } else if (path == '/api/items/search') {
        json = _page(_items(categoryId: q['categoryId'], query: q['q']), q);
      } else if (path == '/api/items/count') {
        json = {'total': fixtureItems.length};
      } else if (path == '/api/items/favorites' ||
          path == '/api/items/deleted') {
        json = path.endsWith('favorites')
            ? _items().where((i) => i['isFavorite'] == true).toList()
            : <Object>[];
      } else if (path.startsWith('/api/items/')) {
        final id = uri.pathSegments.last;
        final i = fixtureItems.indexWhere((e) => e.id == id);
        json = i < 0 ? null : _itemJson(fixtureItems[i], i);
        if (json == null) status = 404;
      } else if (path == '/api/users/me') {
        json = {
          'id': fixtureUid,
          'email': 'ayse@example.com',
          'displayName': 'Ayşe',
          'username': 'ayse',
        };
      } else if (path == '/api/users/me/search-history') {
        json = {
          'terms': locale == 'tr'
              ? ['brugge', 'kahvaltı', 'plak']
              : ['bruges', 'breakfast', 'vinyl'],
        };
      } else if (path == '/api/users/search') {
        final term = (q['q'] ?? '').toLowerCase();
        json = term.isEmpty || 'mert@example.com'.contains(term) ||
                term.contains('mert')
            ? [_friend]
            : <Object>[];
      } else if (path == '/api/notifications') {
        json = <Object>[];
      } else if (path == '/api/shares/outgoing') {
        json = _outgoingShares();
      } else if (path == '/api/shares/incoming') {
        json = _incomingShares();
      } else if (path == '/api/shares/quota') {
        json = {'unlimited': true, 'limit': 0, 'used': 1, 'remaining': 0};
      } else if (path == '/api/reminders') {
        json = <Object>[];
      } else if (path == '/api/users/blocked') {
        json = <Object>[];
      } else if (path == '/api/subscriptions/status') {
        json = {'isPremium': true, 'tier': 'curator'};
      } else {
        debugPrint('🧪 [FixtureBackend] unhandled GET $uri');
        json = <String, Object>{};
      }
    } else if (method == 'POST' && path == '/api/reminders') {
      Map<String, dynamic> req = {};
      try {
        req = jsonDecode(utf8.decode(requestBody)) as Map<String, dynamic>;
      } catch (_) {}
      json = {
        ...req,
        'id': 'reminder-${DateTime.now().millisecondsSinceEpoch}',
        'isActive': true,
        'createdAt': _now.toIso8601String(),
      };
    } else {
      // Yazma istekleri: ekran görüntüsü akışında veri değişmez, yalnızca
      // başarılı yanıt dönülür.
      debugPrint('🧪 [FixtureBackend] $method $uri (no-op)');
      json = <String, Object>{};
    }

    return (
      status: status,
      contentType: 'application/json; charset=utf-8',
      body: utf8.encode(jsonEncode(json)),
    );
  }
}

// ======================================================================
// dart:io katmanı
// ======================================================================

class FixtureHttpOverrides extends HttpOverrides {
  FixtureHttpOverrides(this.backend);

  final FixtureBackend backend;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _RoutingHttpClient(super.createHttpClient(context), backend);
  }
}

class _RoutingHttpClient implements HttpClient {
  _RoutingHttpClient(this._real, this._backend);

  final HttpClient _real;
  final FixtureBackend _backend;

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) {
    if (_backend.handles(url)) {
      return Future.value(_FakeRequest(method, url, _backend));
    }
    return _real.openUrl(method, url);
  }

  @override
  Future<HttpClientRequest> open(
    String method,
    String host,
    int port,
    String path,
  ) => openUrl(method, Uri(scheme: 'http', host: host, port: port, path: path));

  @override
  Future<HttpClientRequest> getUrl(Uri url) => openUrl('GET', url);
  @override
  Future<HttpClientRequest> postUrl(Uri url) => openUrl('POST', url);
  @override
  Future<HttpClientRequest> putUrl(Uri url) => openUrl('PUT', url);
  @override
  Future<HttpClientRequest> deleteUrl(Uri url) => openUrl('DELETE', url);
  @override
  Future<HttpClientRequest> patchUrl(Uri url) => openUrl('PATCH', url);
  @override
  Future<HttpClientRequest> headUrl(Uri url) => openUrl('HEAD', url);
  @override
  Future<HttpClientRequest> get(String host, int port, String path) =>
      open('GET', host, port, path);
  @override
  Future<HttpClientRequest> post(String host, int port, String path) =>
      open('POST', host, port, path);
  @override
  Future<HttpClientRequest> put(String host, int port, String path) =>
      open('PUT', host, port, path);
  @override
  Future<HttpClientRequest> delete(String host, int port, String path) =>
      open('DELETE', host, port, path);
  @override
  Future<HttpClientRequest> patch(String host, int port, String path) =>
      open('PATCH', host, port, path);
  @override
  Future<HttpClientRequest> head(String host, int port, String path) =>
      open('HEAD', host, port, path);

  @override
  bool get autoUncompress => _real.autoUncompress;
  @override
  set autoUncompress(bool v) => _real.autoUncompress = v;
  @override
  Duration? get connectionTimeout => _real.connectionTimeout;
  @override
  set connectionTimeout(Duration? v) => _real.connectionTimeout = v;
  @override
  Duration get idleTimeout => _real.idleTimeout;
  @override
  set idleTimeout(Duration v) => _real.idleTimeout = v;
  @override
  int? get maxConnectionsPerHost => _real.maxConnectionsPerHost;
  @override
  set maxConnectionsPerHost(int? v) => _real.maxConnectionsPerHost = v;
  @override
  String? get userAgent => _real.userAgent;
  @override
  set userAgent(String? v) => _real.userAgent = v;

  @override
  set authenticate(
    Future<bool> Function(Uri url, String scheme, String? realm)? f,
  ) => _real.authenticate = f;
  @override
  set authenticateProxy(
    Future<bool> Function(String host, int port, String scheme, String? realm)?
    f,
  ) => _real.authenticateProxy = f;
  @override
  set badCertificateCallback(
    bool Function(X509Certificate cert, String host, int port)? callback,
  ) => _real.badCertificateCallback = callback;
  @override
  set connectionFactory(
    Future<ConnectionTask<Socket>> Function(
      Uri url,
      String? proxyHost,
      int? proxyPort,
    )?
    f,
  ) => _real.connectionFactory = f;
  @override
  set findProxy(String Function(Uri url)? f) => _real.findProxy = f;
  @override
  set keyLog(Function(String line)? callback) => _real.keyLog = callback;

  @override
  void addCredentials(Uri url, String realm, HttpClientCredentials c) =>
      _real.addCredentials(url, realm, c);
  @override
  void addProxyCredentials(
    String host,
    int port,
    String realm,
    HttpClientCredentials c,
  ) => _real.addProxyCredentials(host, port, realm, c);

  @override
  void close({bool force = false}) => _real.close(force: force);
}

class _FakeHeaders implements HttpHeaders {
  final Map<String, List<String>> _h = {};

  @override
  List<String>? operator [](String name) => _h[name.toLowerCase()];
  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) =>
      _h.putIfAbsent(name.toLowerCase(), () => []).add('$value');
  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) =>
      _h[name.toLowerCase()] = ['$value'];
  @override
  String? value(String name) => _h[name.toLowerCase()]?.join(',');
  @override
  void remove(String name, Object value) =>
      _h[name.toLowerCase()]?.remove('$value');
  @override
  void removeAll(String name) => _h.remove(name.toLowerCase());
  @override
  void forEach(void Function(String name, List<String> values) action) =>
      _h.forEach(action);
  @override
  void noFolding(String name) {}
  @override
  void clear() => _h.clear();

  @override
  ContentType? get contentType {
    final v = value(HttpHeaders.contentTypeHeader);
    return v == null ? null : ContentType.parse(v);
  }

  @override
  set contentType(ContentType? v) {
    if (v != null) set(HttpHeaders.contentTypeHeader, v.toString());
  }

  @override
  int get contentLength =>
      int.tryParse(value(HttpHeaders.contentLengthHeader) ?? '') ?? -1;
  @override
  set contentLength(int v) => set(HttpHeaders.contentLengthHeader, v);

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.isSetter) return null;
    if (invocation.isGetter) return null;
    return super.noSuchMethod(invocation);
  }
}

class _FakeRequest implements HttpClientRequest {
  _FakeRequest(this.method, this.uri, this._backend);

  @override
  final String method;
  @override
  final Uri uri;
  final FixtureBackend _backend;
  final BytesBuilder _body = BytesBuilder();
  final Completer<HttpClientResponse> _done = Completer();

  @override
  final HttpHeaders headers = _FakeHeaders();
  @override
  bool followRedirects = true;
  @override
  int maxRedirects = 5;
  @override
  bool persistentConnection = false;
  @override
  int contentLength = -1;
  @override
  bool bufferOutput = true;
  @override
  Encoding encoding = utf8;
  @override
  List<Cookie> get cookies => [];
  @override
  HttpConnectionInfo? get connectionInfo => null;

  @override
  void add(List<int> data) => _body.add(data);
  @override
  void write(Object? object) => _body.add(utf8.encode('$object'));
  @override
  void writeln([Object? object = '']) => write('$object\n');
  @override
  void writeAll(Iterable objects, [String separator = '']) =>
      write(objects.join(separator));
  @override
  void writeCharCode(int charCode) => write(String.fromCharCode(charCode));
  @override
  void addError(Object error, [StackTrace? stackTrace]) {}
  @override
  Future addStream(Stream<List<int>> stream) => stream.forEach(_body.add);
  @override
  Future flush() async {}
  @override
  void abort([Object? exception, StackTrace? stackTrace]) {}

  @override
  Future<HttpClientResponse> close() async {
    if (!_done.isCompleted) {
      final r = _backend.respond(method, uri, _body.toBytes());
      _done.complete(_FakeResponse(r.status, r.contentType, r.body));
    }
    return _done.future;
  }

  @override
  Future<HttpClientResponse> get done => _done.future;
}

class _FakeResponse extends Stream<List<int>> implements HttpClientResponse {
  _FakeResponse(this.statusCode, String contentType, List<int> body)
    : _body = body {
    headers.set(HttpHeaders.contentTypeHeader, contentType);
    headers.set(HttpHeaders.contentLengthHeader, body.length);
    headers.set(HttpHeaders.cacheControlHeader, 'max-age=31536000');
  }

  final List<int> _body;

  @override
  final int statusCode;
  @override
  final HttpHeaders headers = _FakeHeaders();

  @override
  String get reasonPhrase => statusCode == 200 ? 'OK' : 'Not Found';
  @override
  int get contentLength => _body.length;
  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;
  @override
  bool get isRedirect => false;
  @override
  List<RedirectInfo> get redirects => const [];
  @override
  bool get persistentConnection => false;
  @override
  List<Cookie> get cookies => const [];
  @override
  X509Certificate? get certificate => null;
  @override
  HttpConnectionInfo? get connectionInfo => null;

  @override
  Future<HttpClientResponse> redirect([
    String? method,
    Uri? url,
    bool? followLoops,
  ]) => throw UnsupportedError('redirect');

  @override
  Future<Socket> detachSocket() => throw UnsupportedError('detachSocket');

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) => Stream<List<int>>.value(_body).listen(
    onData,
    onError: onError,
    onDone: onDone,
    cancelOnError: cancelOnError,
  );
}
