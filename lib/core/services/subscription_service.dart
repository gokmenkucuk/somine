import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:somine_app/core/config/api_config.dart';
import 'package:somine_app/core/services/backend_auth_service.dart';

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
  CustomerInfo? _customerInfo;
  final BackendAuthService _backendAuthService = BackendAuthService();
  final http.Client _httpClient = http.Client();
  SubscriptionTier _backendTier = SubscriptionTier.starter;

  /// Initialize RevenueCat
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await Purchases.setLogLevel(LogLevel.debug);

      PurchasesConfiguration configuration = PurchasesConfiguration(_apiKey);
      await Purchases.configure(configuration);

      _customerInfo = await Purchases.getCustomerInfo();
      await _refreshBackendStatus();
      _isInitialized = true;

      debugPrint('RevenueCat initialized successfully');
    } catch (e) {
      debugPrint('RevenueCat initialization error: $e');
    }
  }

  /// Set user ID for RevenueCat (call after login)
  Future<void> setUserId(String userId) async {
    try {
      await Purchases.logIn(userId);
      _customerInfo = await Purchases.getCustomerInfo();
      await _refreshBackendStatus(platform: _platformName);
    } catch (e) {
      debugPrint('RevenueCat setUserId error: $e');
    }
  }

  /// Check if user has premium subscription
  bool get isPremium {
    if (_backendAuthService.isEnabled && _backendTier == SubscriptionTier.curator) {
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

    final entitlement = _customerInfo!.entitlements.active['So Mine Premium'] ?? 
                        _customerInfo!.entitlements.active['Premium'];
                        
    if (entitlement == null) return "";
    
    final id = entitlement.productIdentifier.toLowerCase();
    if (id.contains('week') || id.contains('hafta')) return "Haftalık";
    if (id.contains('month') || id.contains('aylik')) return "Aylık";
    if (id.contains('annual') || id.contains('year') || id.contains('yillik')) return "Yıllık";
    if (id.contains('life') || id.contains('omur')) return "Ömür Boyu";
    
    return "Premium";
  }

  /// Get available packages
  Future<List<Package>> getOfferings() async {
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
    try {
      _customerInfo = await Purchases.restorePurchases();
      debugPrint('--- REVENUECAT CUSTOMER INFO ---');
      debugPrint('Active Entitlements: ${_customerInfo?.entitlements.active.keys.toList()}');
      debugPrint('All Entitlements: ${_customerInfo?.entitlements.all.keys.toList()}');
      debugPrint('--------------------------------');
      await _verifyWithBackend();
      return isPremium;
    } catch (e) {
      debugPrint('Restore error: $e');
      return false;
    }
  }

  /// Starter tier limits
  static const int maxCollectionsStarter = 3;
  static const int maxItemsPerCollectionStarter = 20;

  /// Check if can create more collections
  bool canCreateCollection(int currentCount) {
    if (isPremium) return true;
    return currentCount < maxCollectionsStarter;
  }

  /// Check if can add more items to collection
  bool canAddItem(int currentItemCount) {
    if (isPremium) return true;
    return currentItemCount < maxItemsPerCollectionStarter;
  }

  /// Get remaining collections for Starter
  int remainingCollections(int currentCount) {
    if (isPremium) return -1; // Unlimited
    return maxCollectionsStarter - currentCount;
  }

  /// Get remaining items for collection
  int remainingItems(int currentItemCount) {
    if (isPremium) return -1; // Unlimited
    return maxItemsPerCollectionStarter - currentItemCount;
  }

  Future<void> logout() async {
    try {
      await Purchases.logOut();
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

    final response = await _httpClient.post(
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
      'Subscription backend verify failed: ${response.statusCode} ${response.body}',
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

    final response = await _httpClient.get(
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
      'Subscription backend status failed: ${response.statusCode} ${response.body}',
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
      'Authorization': 'Bearer $accessToken',
    };
  }
}
