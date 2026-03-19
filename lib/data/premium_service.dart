import 'dart:async';

import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PremiumService {
  PremiumService._();

  static const monthlyProductId = 'com.nilico.duaya.premium.monthly';
  static const _keyEntitled = 'premium_entitled';

  static final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  static SharedPreferences? _prefs;
  static StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;
  static bool _isInitialized = false;

  static final isPremium = ValueNotifier<bool>(false);
  static final isLoading = ValueNotifier<bool>(false);
  static final productNotifier = ValueNotifier<ProductDetails?>(null);
  static final errorMessage = ValueNotifier<String?>(null);

  static bool get isDebugUnlockAvailable => !kReleaseMode;
  static ProductDetails? get product => productNotifier.value;

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
    isPremium.value = _prefs?.getBool(_keyEntitled) ?? false;

    if (_isInitialized) {
      return;
    }

    _purchaseSubscription = _inAppPurchase.purchaseStream.listen(
      _handlePurchaseUpdates,
      onError: (_) {
        isLoading.value = false;
        errorMessage.value = 'Purchases are unavailable right now.';
      },
    );
    _isInitialized = true;
    await loadProducts();
    unawaited(_refreshFromStore());
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
    try {
      final isAvailable = await _inAppPurchase.isAvailable();
      if (!isAvailable) {
        productNotifier.value = null;
        errorMessage.value = 'Purchases are unavailable right now.';
        return;
      }

      final response = await _inAppPurchase.queryProductDetails({
        monthlyProductId,
      });

      if (response.error != null) {
        productNotifier.value = null;
        errorMessage.value = response.error!.message;
        return;
      }

      if (response.productDetails.isEmpty ||
          response.notFoundIDs.contains(monthlyProductId)) {
        productNotifier.value = null;
        errorMessage.value = 'Subscription is not available right now.';
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
        productNotifier.value = null;
        errorMessage.value = 'Subscription is not available right now.';
        return;
      }

      productNotifier.value = monthlyProduct;
      errorMessage.value = null;
    } catch (_) {
      productNotifier.value = null;
      errorMessage.value = 'Purchases are unavailable right now.';
    }
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
      errorMessage.value = 'Purchase could not be started.';
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
      await _inAppPurchase.restorePurchases();
    } catch (_) {
      if (!silent) {
        isLoading.value = false;
        errorMessage.value = 'Restore failed. Please try again.';
      }
    }
  }

  static Future<void> restorePurchasesStub() async {
    await restorePurchases();
  }

  static Future<void> _handlePurchaseUpdates(
    List<PurchaseDetails> purchases,
  ) async {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          isLoading.value = true;
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _setPremium(true);
          isLoading.value = false;
          errorMessage.value = null;
          break;
        case PurchaseStatus.error:
          isLoading.value = false;
          errorMessage.value =
              purchase.error?.message ?? 'Purchase failed. Please try again.';
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
  }

  static Future<void> _setPremium(bool value) async {
    await _prefs?.setBool(_keyEntitled, value);
    isPremium.value = value;
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
