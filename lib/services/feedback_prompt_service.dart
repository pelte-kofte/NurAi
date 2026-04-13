import '../data/local_preferences_service.dart';

class FeedbackPromptService {
  FeedbackPromptService._();

  static const int minimumCompanionCompletions = 3;
  static const int minimumActiveDays = 5;
  static const Duration dismissCooldown = Duration(days: 14);

  static bool canShowPrompt() {
    if (LocalPreferencesService.feedbackPromptCompleted) return false;
    if (LocalPreferencesService.feedbackPromptRated) return false;

    final meetsCompanionThreshold =
        LocalPreferencesService.companionFlowCompletionCount >=
            minimumCompanionCompletions;
    final meetsActiveDayThreshold =
        LocalPreferencesService.feedbackPromptActiveDays >= minimumActiveDays;
    if (!meetsCompanionThreshold && !meetsActiveDayThreshold) return false;

    final lastShownAt = LocalPreferencesService.lastFeedbackPromptShownAt;
    if (lastShownAt == null) return true;

    return DateTime.now().difference(lastShownAt) >= dismissCooldown;
  }
}
