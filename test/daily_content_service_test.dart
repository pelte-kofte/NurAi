import 'package:flutter_test/flutter_test.dart';
import 'package:nurai/data/daily_content_service.dart';

void main() {
  group('DailyContentService reminder index', () {
    test('same date is stable', () {
      final date = DateTime(2026, 3, 1);
      final first = DailyContentService.reminderIndexForDate(date, 17);
      final second = DailyContentService.reminderIndexForDate(date, 17);
      expect(first, second);
    });

    test('different dates can produce different indices', () {
      final base = DateTime(2026, 3, 1);
      final baseIndex = DailyContentService.reminderIndexForDate(base, 17);

      var foundDifferent = false;
      for (var offset = 1; offset <= 40; offset++) {
        final candidate = base.add(Duration(days: offset));
        final candidateIndex =
            DailyContentService.reminderIndexForDate(candidate, 17);
        if (candidateIndex != baseIndex) {
          foundDifferent = true;
          break;
        }
      }
      expect(foundDifferent, isTrue);
    });
  });
}
