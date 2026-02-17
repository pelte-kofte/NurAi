import 'package:flutter_test/flutter_test.dart';
import 'package:nurai/data/adhan_notification_service.dart';
import 'package:nurai/data/local_preferences_service.dart';

void main() {
  group('buildAdhanNotificationBody', () {
    test('keeps base body when reminder is absent', () {
      LocalPreferencesService.language.value = 'en';
      final body = buildAdhanNotificationBody(
        'Fajr',
        '05:30',
        cityName: 'Istanbul',
      );

      expect(body, contains('Fajr'));
      expect(body, contains('05:30'));
      expect(body, isNot(contains('Gentle Reminder')));
    });

    test('appends gentle reminder when provided', () {
      LocalPreferencesService.language.value = 'en';
      final body = buildAdhanNotificationBody(
        'Fajr',
        '05:30',
        cityName: 'Istanbul',
        optionalReminder: 'Start your day with gratitude.',
      );

      expect(body, contains('Fajr'));
      expect(body, contains('05:30'));
      expect(body, contains('Gentle Reminder: Start your day with gratitude.'));
    });
  });
}
