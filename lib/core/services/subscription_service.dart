import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

/// Subscription tiers
enum SubscriptionTier {
  starter,  // Free
  curator,  // Premium
}

/// Subscription service for RevenueCat integration
class SubscriptionService {
  // Platform-specific API keys
  static String get _apiKey {
    if (Platform.isIOS) {
      return 'test_kkWnrhYrsOAPZNKNMptpNRtsgaO';
    } else if (Platform.isAndroid) {
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

  /// Initialize RevenueCat
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      await Purchases.setLogLevel(LogLevel.debug);
      
      PurchasesConfiguration configuration = PurchasesConfiguration(_apiKey);
      await Purchases.configure(configuration);
      
      _customerInfo = await Purchases.getCustomerInfo();
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
    } catch (e) {
      debugPrint('RevenueCat setUserId error: $e');
    }
  }

  /// Check if user has premium subscription
  bool get isPremium {
    if (_customerInfo == null) return false;
    // Check for "So Mine Premium" entitlement (must match RevenueCat dashboard)
    return _customerInfo!.entitlements.active.containsKey('So Mine Premium');
  }

  /// Get current subscription tier
  SubscriptionTier get currentTier {
    return isPremium ? SubscriptionTier.curator : SubscriptionTier.starter;
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
}
