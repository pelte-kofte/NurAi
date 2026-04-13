// ignore_for_file: avoid_print

import 'dart:async';

import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'adhan_notification_service.dart';
import 'local_preferences_service.dart';
import '../l10n/app_strings.dart';

class PremiumService {
  PremiumService._();

  static const monthlyProductId = 'com.nilico.duaya.premium.monthly';
  static const _keyEntitled = 'premium_entitled';

  static final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  static SharedPreferences? _prefs;
  static StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;
  static bool _isInitialized = false;
  static Future<void>? _initFuture;
  static Future<void>? _productLoadFuture;
  static int _productLoadRequestId = 0;
  static bool _isRestoringPurchases = false;
  static int _presentedActivationSuccessRevision = 0;

  static final isPremium = ValueNotifier<bool>(false);
  static final isLoading = ValueNotifier<bool>(false);
  static final productNotifier = ValueNotifier<ProductDetails?>(null);
  static final errorMessage = ValueNotifier<String?>(null);
  static final isProductLoading = ValueNotifier<bool>(false);
  static final showProductRetryAction = ValueNotifier<bool>(false);
  static final activationSuccessRevision = ValueNotifier<int>(0);

  static bool get isDebugUnlockAvailable => !kReleaseMode;
  static ProductDetails? get product => productNotifier.value;

  static void _log(String message) {
    assert(() {
      // Keep premium diagnostics in debug builds only.
      print('[PremiumService] $message');
      return true;
    }());
  }

  static Future<void> init() async {
    if (_initFuture != null) {
      return _initFuture!;
    }

    final completer = Completer<void>();
    _initFuture = completer.future;

    try {
      _prefs ??= await SharedPreferences.getInstance();
      isPremium.value = _prefs?.getBool(_keyEntitled) ?? false;
      _log(
        'init: storedPremium=${_prefs?.getBool(_keyEntitled)} '
        'effectivePremium=${isPremium.value}',
      );

      if (!_isInitialized) {
        _purchaseSubscription = _inAppPurchase.purchaseStream.listen(
          _handlePurchaseUpdates,
          onError: (Object error) {
            isLoading.value = false;
            errorMessage.value = S.get('premium_purchase_unavailable');
            print('PremiumService.purchaseStream error: $error');
          },
        );
        _isInitialized = true;
      }

      if (!isPremium.value) {
        unawaited(
            _syncSpiritualNotificationAccessForTier(isPremiumUser: false));
      }
      unawaited(loadProducts());
      unawaited(_refreshFromStore());
      completer.complete();
    } catch (error, stackTrace) {
      _initFuture = null;
      completer.completeError(error, stackTrace);
      rethrow;
    }
  }

  static Future<void> dispose() async {
    await _purchaseSubscription?.cancel();
    _purchaseSubscription = null;
    _isInitialized = false;
  }

  static Future<void> setPremiumDebug(bool value) async {
    await _setPremium(value);
  }

  static Future<void> loadProducts() async {
    if (_productLoadFuture != null) {
      return _productLoadFuture!;
    }

    final completer = Completer<void>();
    _productLoadFuture = completer.future;
    final requestId = ++_productLoadRequestId;

    try {
      await _loadProductsInternal(
        requestId: requestId,
        allowRetry: true,
      );
      completer.complete();
    } catch (error, stackTrace) {
      completer.completeError(error, stackTrace);
      rethrow;
    } finally {
      if (identical(_productLoadFuture, completer.future)) {
        _productLoadFuture = null;
      }
    }
  }

  static Future<void> _loadProductsInternal({
    required int requestId,
    required bool allowRetry,
  }) async {
    _setProductLoadingState(
      requestId: requestId,
      isLoadingNow: true,
      showRetryActionNow: false,
    );

    try {
      final isAvailable = await _inAppPurchase.isAvailable();
      print('PremiumService.loadProducts isAvailable: $isAvailable');
      if (!isAvailable) {
        _setProductUnavailable(
          requestId: requestId,
          reason: 'store unavailable',
          allowRetry: allowRetry,
        );
        return;
      }

      final productIds = <String>{monthlyProductId};
      print('PremiumService.loadProducts queriedProductIds: $productIds');

      final response = await _inAppPurchase.queryProductDetails(productIds);
      print(
        'PremiumService.loadProducts response: '
        'productDetails=${response.productDetails.map((product) => '${product.id}:${product.price}').toList()} '
        'notFound=${response.notFoundIDs} '
        'error=${response.error}',
      );

      if (response.error != null) {
        await _setProductUnavailable(
          requestId: requestId,
          reason: 'queryProductDetails error: ${response.error}',
          allowRetry: allowRetry,
        );
        return;
      }

      if (response.productDetails.isEmpty ||
          response.notFoundIDs.contains(monthlyProductId)) {
        await _setProductUnavailable(
          requestId: requestId,
          reason: 'empty product response for $monthlyProductId',
          allowRetry: allowRetry,
        );
        return;
      }

      ProductDetails? monthlyProduct;
      for (final product in response.productDetails) {
        if (product.id == monthlyProductId) {
          monthlyProduct = product;
          break;
        }
      }

      if (monthlyProduct == null) {
        await _setProductUnavailable(
          requestId: requestId,
          reason: 'monthly product not resolved from productDetails',
          allowRetry: allowRetry,
        );
        return;
      }

      if (requestId != _productLoadRequestId) {
        return;
      }

      productNotifier.value = monthlyProduct;
      errorMessage.value = null;
      isProductLoading.value = false;
      showProductRetryAction.value = false;
    } catch (error) {
      await _setProductUnavailable(
        requestId: requestId,
        reason: 'exception: $error',
        allowRetry: allowRetry,
      );
    }
  }

  static void _setProductLoadingState({
    required int requestId,
    required bool isLoadingNow,
    required bool showRetryActionNow,
  }) {
    if (requestId != _productLoadRequestId) {
      return;
    }
    isProductLoading.value = isLoadingNow;
    showProductRetryAction.value = showRetryActionNow;
  }

  static Future<void> _setProductUnavailable({
    required int requestId,
    required String reason,
    required bool allowRetry,
  }) async {
    if (requestId != _productLoadRequestId) {
      return;
    }

    productNotifier.value = null;
    print('PremiumService.loadProducts unavailable: $reason');

    if (allowRetry) {
      print('PremiumService.loadProducts retrying once after delay.');
      await Future<void>.delayed(const Duration(milliseconds: 1500));
      if (requestId != _productLoadRequestId) {
        return;
      }
      await _loadProductsInternal(
        requestId: requestId,
        allowRetry: false,
      );
      return;
    }

    isProductLoading.value = false;
    showProductRetryAction.value = true;
  }

  static Future<void> buyMonthly() async {
    if (isLoading.value) {
      return;
    }

    final productDetails = product;
    if (productDetails == null) {
      await loadProducts();
    }

    final resolvedProduct = product;
    if (resolvedProduct == null) {
      return;
    }

    try {
      isLoading.value = true;
      errorMessage.value = null;
      await _buyMonthlySubscription(resolvedProduct);
    } catch (_) {
      isLoading.value = false;
      errorMessage.value = S.get('premium_purchase_start_failed');
    }
  }

  static Future<void> _buyMonthlySubscription(
    ProductDetails productDetails,
  ) async {
    // The in_app_purchase package uses the non-consumable purchase API
    // for auto-renewable subscriptions as well.
    final purchaseParam = PurchaseParam(productDetails: productDetails);
    await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
  }

  static Future<void> restorePurchases() async {
    await _restorePurchases(silent: false);
  }

  static Future<void> _restorePurchases({required bool silent}) async {
    try {
      if (!silent) {
        isLoading.value = true;
        errorMessage.value = null;
      }
      _log(
        '_restorePurchases: '
        'silent=$silent '
        'premiumBefore=${isPremium.value}',
      );
      _isRestoringPurchases = true;
      await _inAppPurchase.restorePurchases();
    } catch (_) {
      _isRestoringPurchases = false;
      if (!silent) {
        isLoading.value = false;
        errorMessage.value = S.get('premium_restore_failed');
      }
    }
  }

  static Future<void> restorePurchasesStub() async {
    await restorePurchases();
  }

  static Future<void> _handlePurchaseUpdates(
    List<PurchaseDetails> purchases,
  ) async {
    _log(
      '_handlePurchaseUpdates: '
      'count=${purchases.length} '
      'isRestoring=$_isRestoringPurchases '
      'premiumBefore=${isPremium.value}',
    );
    if (purchases.isEmpty) {
      if (_isRestoringPurchases) {
        await _setPremium(false);
        _log('restore completed with no purchases; premium reset to false');
        isLoading.value = false;
        _isRestoringPurchases = false;
      }
      return;
    }

    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          isLoading.value = true;
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _setPremium(true);
          _log('purchase update marked premium=true status=${purchase.status}');
          isLoading.value = false;
          errorMessage.value = null;
          break;
        case PurchaseStatus.error:
          isLoading.value = false;
          errorMessage.value =
              purchase.error?.message ?? S.get('premium_purchase_failed');
          break;
        case PurchaseStatus.canceled:
          isLoading.value = false;
          break;
      }

      if (purchase.pendingCompletePurchase) {
        try {
          await _inAppPurchase.completePurchase(purchase);
        } catch (_) {}
      }
    }

    _isRestoringPurchases = false;
  }

  static Future<void> _setPremium(bool value) async {
    final previousValue = isPremium.value;
    await _prefs?.setBool(_keyEntitled, value);
    isPremium.value = value;
    await _syncSpiritualNotificationAccessForTier(isPremiumUser: value);
    if (!previousValue && value) {
      activationSuccessRevision.value = activationSuccessRevision.value + 1;
    }
  }

  static bool markActivationSuccessPresented(int revision) {
    if (revision <= _presentedActivationSuccessRevision) {
      return false;
    }
    _presentedActivationSuccessRevision = revision;
    return true;
  }

  static Future<void> _syncSpiritualNotificationAccessForTier({
    required bool isPremiumUser,
  }) async {
    if (isPremiumUser) return;

    final currentTimes =
        LocalPreferencesService.spiritualNotificationTimes.value;
    if (currentTimes.length <= 1) return;

    await LocalPreferencesService.setSpiritualNotificationTimes(
      [currentTimes.first],
    );
    if (LocalPreferencesService.spiritualNotificationsEnabled.value) {
      await AdhanNotificationService.syncSpiritualNotifications();
    }
  }

  static Future<void> _refreshFromStore() async {
    try {
      final isAvailable = await _inAppPurchase.isAvailable();
      if (!isAvailable) {
        return;
      }
      await _restorePurchases(silent: true);
    } catch (_) {}
  }
}
