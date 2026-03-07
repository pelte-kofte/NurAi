import 'package:flutter_test/flutter_test.dart';
import 'package:nurai/data/daily_content_service.dart';

void main() {
  group('DailyContentService rotation state', () {
    test('keeps same selection within the same date', () {
      final state = DailyContentService.nextRotationStateForTesting(
        dateKey: null,
        currentIndex: null,
        remainingIndices: const [],
        poolLength: null,
        cycle: 0,
        nextDateKey: '2026-03-01',
        rotationKey: 'reminder_tr',
        nextPoolLength: 5,
      );

      final repeated = DailyContentService.nextRotationStateForTesting(
        dateKey: state['dateKey'] as String?,
        currentIndex: state['currentIndex'] as int?,
        remainingIndices:
            (state['remainingIndices'] as List).cast<int>().toList(),
        poolLength: state['poolLength'] as int?,
        cycle: state['cycle'] as int? ?? 0,
        nextDateKey: '2026-03-01',
        rotationKey: 'reminder_tr',
        nextPoolLength: 5,
      );

      expect(repeated['currentIndex'], state['currentIndex']);
      expect(repeated['remainingIndices'], state['remainingIndices']);
    });

    test('does not repeat until the pool is exhausted', () {
      var state = DailyContentService.nextRotationStateForTesting(
        dateKey: null,
        currentIndex: null,
        remainingIndices: const [],
        poolLength: null,
        cycle: 0,
        nextDateKey: '2026-03-01',
        rotationKey: 'quote_en',
        nextPoolLength: 5,
      );

      final seen = <int>{state['currentIndex'] as int};
      for (var day = 2; day <= 5; day++) {
        state = DailyContentService.nextRotationStateForTesting(
          dateKey: state['dateKey'] as String?,
          currentIndex: state['currentIndex'] as int?,
          remainingIndices:
              (state['remainingIndices'] as List).cast<int>().toList(),
          poolLength: state['poolLength'] as int?,
          cycle: state['cycle'] as int? ?? 0,
          nextDateKey: '2026-03-0$day',
          rotationKey: 'quote_en',
          nextPoolLength: 5,
        );
        expect(seen.add(state['currentIndex'] as int), isTrue);
      }
    });

    test(
        'avoids consecutive repeat across reshuffles when pool is larger than one',
        () {
      final afterExhaustion = DailyContentService.nextRotationStateForTesting(
        dateKey: '2026-03-05',
        currentIndex: 2,
        remainingIndices: const [],
        poolLength: 3,
        cycle: 1,
        nextDateKey: '2026-03-06',
        rotationKey: 'reminder_en',
        nextPoolLength: 3,
      );

      expect(afterExhaustion['currentIndex'], isNot(2));
    });

    test('single-item pools can repeat', () {
      final state = DailyContentService.nextRotationStateForTesting(
        dateKey: '2026-03-01',
        currentIndex: 0,
        remainingIndices: const [],
        poolLength: 1,
        cycle: 0,
        nextDateKey: '2026-03-02',
        rotationKey: 'quote_tr',
        nextPoolLength: 1,
      );

      expect(state['currentIndex'], 0);
      expect(state['remainingIndices'], isEmpty);
    });
  });
}
