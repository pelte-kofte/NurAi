import 'package:flutter_test/flutter_test.dart';
import 'package:nurai/data/reflection_items_service.dart';

void main() {
  test('daily reflection selection stays stable throughout the same day', () {
    final morning = ReflectionItemsService.pickDailySessionItems(
      ReflectionItemsService.fallbackItems,
      date: DateTime(2026, 10, 30, 8, 15),
    );
    final evening = ReflectionItemsService.pickDailySessionItems(
      ReflectionItemsService.fallbackItems,
      date: DateTime(2026, 10, 30, 21, 45),
    );

    expect(morning, hasLength(3));
    expect(evening, hasLength(3));
    expect(
      evening.map((item) => item.type),
      orderedEquals(morning.map((item) => item.type)),
    );
  });
}
