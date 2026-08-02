import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:somine_app/core/config/api_config.dart';
import 'package:somine_app/core/services/api_client.dart';
import 'package:somine_app/core/services/backend_auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Subscription tiers
enum SubscriptionTier {
  starter, // Free
  curator, // Premium
}

/// Subscription service for RevenueCat integration
class SubscriptionService {
  // Platform-specific API keys
  static String get _apiKey {
    if (Platform.isIOS) {
      return 'appl_AjqufxZJYezglbnyGcyilKTbOkP';
    } else if (Platform.isAndroid) {
      // TODO: Replace with your actual RevenueCat Android Public App-Specific API Key (starts with 'goog_')
      return 'test_kkWnrhYrsOAPZNKNMptpNRtsgaO';
    } else {
      throw UnsupportedError('Platform not supported');
    }
  }

  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();

  bool _isInitialized = false;
  Future<void>? _initializing;
  CustomerInfo? _customerInfo;
  final BackendAuthService _backendAuthService = BackendAuthService();
  final ApiClient _apiClient = ApiClient();
  SubscriptionTier _backendTier = SubscriptionTier.starter;

  /// Initialize RevenueCat
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Eşzamanlı çağrılarda configure'un iki kez koşmasını engelle.
    final inFlight = _initializing;
    if (inFlight != null) return inFlight;

    final future = _doInitialize();
    _initializing = future;
    try {
      await future;
    } finally {
      _initializing = null;
    }
  }

  Future<void> _doInitialize() async {
    try {
      await Purchases.setLogLevel(LogLevel.debug);

      PurchasesConfiguration configuration = PurchasesConfiguration(_apiKey);
      await Purchases.configure(configuration);
      _isInitialized = true;

      // Oturum zaten açıksa kullanıcıyı her açılışta RevenueCat'e tanıt.
      // Giriş akışı (auth_repository) yalnız TAZE oturum açılışında çalışır;
      // o akış hata alıp atlanırsa kullanıcı RevenueCat'te hiç oluşmuyordu.
      await _identifyCurrentUserSafely();

      // RevenueCat SDK'sı hata verse bile (ör. sandbox makbuz reddi) backend
      // sorgusu ÇALIŞMALI: premium gerçeği sunucuda, SDK yalnız ikincil kaynak.
      await _loadCustomerInfoSafely();

      // Cihazda satın alma var ama bu kimliğe bağlı değilse (yeniden giriş,
      // yeni cihaz, kesintiye uğramış giriş akışı) kullanıcıyı "Satın alımları
      // geri yükle"ye zorlamadan bir kez otomatik dene.
      await _autoRestoreIfNeeded();

      debugPrint('RevenueCat initialized successfully');
    } catch (e) {
      debugPrint('RevenueCat initialization error: $e');
    } finally {
      await _refreshBackendStatusSafely();
    }
  }

  Future<void> _identifyCurrentUserSafely() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null || uid.isEmpty) return;
      await Purchases.logIn(uid);
      debugPrint('RevenueCat identified as $uid');
    } catch (e) {
      debugPrint('RevenueCat identify error: $e');
    }
  }

  bool get _hasActiveEntitlement =>
      _customerInfo?.entitlements.active.isNotEmpty ?? false;

  /// Kimlik başına BİR KEZ otomatik restore. Her açılışta çağırmak Apple
  /// tarafında gereksiz istek/istem doğurur; bir kez denemek yeterli çünkü
  /// sonrasında satın alma zaten bu kimliğe bağlı kalır.
  Future<void> _autoRestoreIfNeeded() async {
    try {
      if (_hasActiveEntitlement) return;

      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null || uid.isEmpty) return;

      final prefs = await SharedPreferences.getInstance();
      final key = 'rc_auto_restore_$uid';
      if (prefs.getBool(key) == true) return;
      await prefs.setBool(key, true);

      _customerInfo = await Purchases.restorePurchases();
      debugPrint(
        'RevenueCat auto-restore tamamlandı: '
        '${_customerInfo?.entitlements.active.keys.toList()}',
      );
    } catch (e) {
      debugPrint('RevenueCat auto-restore error: $e');
    }
  }

  Future<void> _loadCustomerInfoSafely() async {
    try {
      _customerInfo = await Purchases.getCustomerInfo();
    } catch (e) {
      debugPrint('RevenueCat getCustomerInfo error: $e');
    }
  }

  Future<void> _refreshBackendStatusSafely({String? platform}) async {
    try {
      await _refreshBackendStatus(platform: platform);
    } catch (e) {
      debugPrint('Backend subscription status error: $e');
    }
  }

  /// Configure tamamlanmadan Purchases.* çağrısı native fatalError'a
  /// düşürür (Dart catch yakalayamaz); tüm dış çağrılar önce bundan geçmeli.
  Future<bool> _ensureConfigured() async {
    if (!_isInitialized) await initialize();
    return _isInitialized;
  }

  /// Set user ID for RevenueCat (call after login)
  Future<void> setUserId(String userId) async {
    if (!await _ensureConfigured()) {
      debugPrint('RevenueCat setUserId skipped: not configured');
      return;
    }
    try {
      await Purchases.logIn(userId);
      await _loadCustomerInfoSafely();
      // Yeni cihazda ilk giriş: satın alma cihazda var ama kimliğe bağlı değil.
      await _autoRestoreIfNeeded();
    } catch (e) {
      debugPrint('RevenueCat setUserId error: $e');
    } finally {
      // SDK tarafı patlasa da premium durumu sunucudan okunmalı.
      await _refreshBackendStatusSafely(platform: _platformName);
    }
  }

  /// Check if user has premium subscription
  bool get isPremium {
    if (_backendAuthService.isEnabled &&
        _backendTier == SubscriptionTier.curator) {
      return true;
    }

    if (_customerInfo == null) return false;
    // RevenueCat panelinde Entitlement ismi olarak "So Mine Premium" ayarlanmış. İhtiyaten iki durumu da kontrol edelim.
    return _customerInfo!.entitlements.active.containsKey('So Mine Premium') ||
        _customerInfo!.entitlements.active.containsKey('Premium');
  }

  /// Get current subscription tier
  SubscriptionTier get currentTier {
    return isPremium ? SubscriptionTier.curator : SubscriptionTier.starter;
  }

  /// Get active package name
  String get activePackageName {
    if (!isPremium || _customerInfo == null) return "";

    final entitlement =
        _customerInfo!.entitlements.active['So Mine Premium'] ??
        _customerInfo!.entitlements.active['Premium'];

    if (entitlement == null) return "";

    final id = entitlement.productIdentifier.toLowerCase();
    if (id.contains('week') || id.contains('hafta')) return "Haftalık";
    if (id.contains('month') || id.contains('aylik')) return "Aylık";
    if (id.contains('annual') || id.contains('year') || id.contains('yillik')) {
      return "Yıllık";
    }
    if (id.contains('life') || id.contains('omur')) return "Ömür Boyu";

    return "Premium";
  }

  /// Get available packages
  Future<List<Package>> getOfferings() async {
    if (!await _ensureConfigured()) return [];
    try {
      debugPrint('📦 Fetching RevenueCat offerings...');
      final offerings = await Purchases.getOfferings();

      debugPrint('📦 All offerings: ${offerings.all.keys.toList()}');
      debugPrint('📦 Current offering: ${offerings.current?.identifier}');

      if (offerings.current != null) {
        final packages = offerings.current!.availablePackages;
        debugPrint('📦 Available packages: ${packages.length}');
        for (var p in packages) {
          debugPrint('  - ${p.packageType}: ${p.storeProduct.priceString}');
        }
        return packages;
      } else {
        debugPrint('⚠️ No current offering found!');
      }
    } catch (e) {
      debugPrint('❌ Error fetching offerings: $e');
    }
    return [];
  }

  /// Purchase a package
  Future<bool> purchasePackage(Package package) async {
    if (!await _ensureConfigured()) return false;
    try {
      final result = await Purchases.purchasePackage(package);
      _customerInfo = result;
      await _verifyWithBackend();
      return isPremium;
    } catch (e) {
      debugPrint('Purchase error: $e');
      return false;
    }
  }

  /// Restore purchases
  Future<bool> restorePurchases() async {
    if (!await _ensureConfigured()) return false;
    try {
      _customerInfo = await Purchases.restorePurchases();
      debugPrint('--- REVENUECAT CUSTOMER INFO ---');
      debugPrint(
        'Active Entitlements: ${_customerInfo?.entitlements.active.keys.toList()}',
      );
      debugPrint(
        'All Entitlements: ${_customerInfo?.entitlements.all.keys.toList()}',
      );
      debugPrint('--------------------------------');
      await _verifyWithBackend();
      return isPremium;
    } catch (e) {
      debugPrint('Restore error: $e');
      return false;
    }
  }

  /// Starter tier limits
  static const int maxCollectionsStarter = 10;
  static const int maxTotalItemsStarter = 500;
  static const int itemWarnThresholdStarter = 450;
  static const int maxActiveRemindersStarter = 3;
  static const int maxActiveSharesStarter = 1;

  /// Check if can create more collections
  bool canCreateCollection(int currentCount) {
    if (isPremium) return true;
    return currentCount < maxCollectionsStarter;
  }

  /// Check if can add more items (toplam içerik sayısına göre)
  bool canAddItem(int totalItemCount) {
    if (isPremium) return true;
    return totalItemCount < maxTotalItemsStarter;
  }

  /// Check if can create more active reminders
  bool canCreateReminder(int activeReminderCount) {
    if (isPremium) return true;
    return activeReminderCount < maxActiveRemindersStarter;
  }

  /// Check if can create more active shares
  bool canCreateShare(int activeShareCount) {
    if (isPremium) return true;
    return activeShareCount < maxActiveSharesStarter;
  }

  /// Whether to show a soft warning as the user approaches the total item limit
  bool shouldWarnItemLimit(int totalItemCount) {
    if (isPremium) return false;
    return totalItemCount >= itemWarnThresholdStarter;
  }

  /// Get remaining collections for Starter
  int remainingCollections(int currentCount) {
    if (isPremium) return -1; // Unlimited
    return maxCollectionsStarter - currentCount;
  }

  /// Get remaining items (toplam içerik sayısına göre)
  int remainingItems(int totalItemCount) {
    if (isPremium) return -1; // Unlimited
    return maxTotalItemsStarter - totalItemCount;
  }

  Future<void> logout() async {
    try {
      if (_isInitialized) await Purchases.logOut();
    } catch (e) {
      debugPrint('RevenueCat logout error: $e');
    } finally {
      _customerInfo = null;
      _backendTier = SubscriptionTier.starter;
    }
  }

  Future<void> refreshStatus() async {
    if (_backendAuthService.isEnabled) {
      await _refreshBackendStatus(platform: _platformName);
      return;
    }

    if (!await _ensureConfigured()) return;
    try {
      _customerInfo = await Purchases.getCustomerInfo();
    } catch (e) {
      debugPrint('RevenueCat refresh status error: $e');
    }
  }

  Future<void> _verifyWithBackend() async {
    if (!_backendAuthService.isEnabled) {
      return;
    }

    final accessToken = await _backendAuthService.getValidAccessToken(
      firebaseUser: FirebaseAuth.instance.currentUser,
    );

    if (accessToken == null || accessToken.isEmpty) {
      return;
    }

    final response = await _apiClient.post(
      _buildUri('/api/subscriptions/verify'),
      headers: _jsonHeaders(accessToken),
      body: jsonEncode({'receiptData': '', 'platform': _platformName}),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      _backendTier = _tierFromStatus(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
      return;
    }

    debugPrint(
      'Subscription backend verify failed: ${response.statusCode}',
    );
  }

  Future<void> _refreshBackendStatus({String? platform}) async {
    if (!_backendAuthService.isEnabled) {
      _backendTier = currentTierFromRevenueCat;
      return;
    }

    final accessToken = await _backendAuthService.getValidAccessToken(
      firebaseUser: FirebaseAuth.instance.currentUser,
    );

    if (accessToken == null || accessToken.isEmpty) {
      _backendTier = currentTierFromRevenueCat;
      return;
    }

    final response = await _apiClient.get(
      _buildUri(
        '/api/subscriptions/status',
        queryParameters: {
          if (platform != null && platform.isNotEmpty) 'platform': platform,
        },
      ),
      headers: _jsonHeaders(accessToken),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      _backendTier = _tierFromStatus(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
      return;
    }

    debugPrint(
      'Subscription backend status failed: ${response.statusCode}',
    );
    _backendTier = currentTierFromRevenueCat;
  }

  SubscriptionTier get currentTierFromRevenueCat {
    if (_customerInfo == null) return SubscriptionTier.starter;
    return _customerInfo!.entitlements.active.containsKey('Premium')
        ? SubscriptionTier.curator
        : SubscriptionTier.starter;
  }

  SubscriptionTier _tierFromStatus(Map<String, dynamic> json) {
    final isActive = json['isActive'] as bool? ?? false;
    return isActive ? SubscriptionTier.curator : SubscriptionTier.starter;
  }

  String get _platformName {
    if (Platform.isIOS) return 'ios';
    if (Platform.isAndroid) return 'android';
    return 'unknown';
  }

  Uri _buildUri(String path, {Map<String, String>? queryParameters}) {
    final baseUrl = ApiConfig.baseUrl;
    final normalizedBase =
        baseUrl.endsWith('/')
            ? baseUrl.substring(0, baseUrl.length - 1)
            : baseUrl;
    return Uri.parse('$normalizedBase$path').replace(
      queryParameters:
          queryParameters?.isEmpty == true ? null : queryParameters,
    );
  }

  Map<String, String> _jsonHeaders(String accessToken) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (ApiConfig.apiKey.isNotEmpty) 'X-SoMine-Api-Key': ApiConfig.apiKey,
      'Authorization': 'Bearer $accessToken',
    };
  }
}
