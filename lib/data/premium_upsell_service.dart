import 'local_preferences_service.dart';
import 'premium_service.dart';

class PremiumUpsellService {
  PremiumUpsellService._();

  static const int minimumAppOpenCount = 3;
  static const Duration minimumTimeOnHome = Duration(seconds: 45);
  static const Duration dismissCooldown = Duration(days: 7);

  static bool get isBlockedForCurrentUser => PremiumService.isPremium.value;

  static bool canShowUpsell({
    required bool launchedFromNotification,
    required bool hasActiveModalRoute,
  }) {
    if (isBlockedForCurrentUser) return false;
    if (launchedFromNotification) return false;
    if (hasActiveModalRoute) return false;
    if (LocalPreferencesService.premiumUpsellShownThisSession) return false;
    if (LocalPreferencesService.appOpenCount < minimumAppOpenCount) {
      return false;
    }

    final now = DateTime.now();
    final lastShownAt = LocalPreferencesService.lastPremiumUpsellShownAt;
    if (_isSameDay(lastShownAt, now)) return false;

    final lastDismissedAt =
        LocalPreferencesService.lastPremiumUpsellDismissedAt;
    if (lastDismissedAt != null &&
        now.difference(lastDismissedAt) < dismissCooldown) {
      return false;
    }

    return true;
  }

  static Future<void> markShown() async {
    await LocalPreferencesService.setLastPremiumUpsellShownAt(DateTime.now());
  }

  static Future<void> markDismissed() async {
    await LocalPreferencesService.setLastPremiumUpsellDismissedAt(
      DateTime.now(),
    );
  }

  static bool _isSameDay(DateTime? left, DateTime right) {
    if (left == null) return false;
    return left.year == right.year &&
        left.month == right.month &&
        left.day == right.day;
  }
}
