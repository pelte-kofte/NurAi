import 'package:flutter_test/flutter_test.dart';
import 'package:nurai/data/ramadan_suggestions_service.dart';

void main() {
  group('RamadanSuggestionsService deterministic selection', () {
    test('same date returns same selection', () {
      final date = DateTime(2026, 3, 5);

      final first = RamadanSuggestionsService.deterministicBundleForDate(date);
      final second = RamadanSuggestionsService.deterministicBundleForDate(date);

      expect(first.duaIndex, second.duaIndex);
      expect(first.ayetIndex, second.ayetIndex);
      expect(first.iyilikIndex, second.iyilikIndex);
      expect(first.dua.text, second.dua.text);
      expect(first.ayet.text, second.ayet.text);
      expect(first.iyilik.text, second.iyilik.text);
    });

    test('different dates produce a different selection', () {
      final first = RamadanSuggestionsService.deterministicBundleForDate(
        DateTime(2026, 3, 5),
      );
      final second = RamadanSuggestionsService.deterministicBundleForDate(
        DateTime(2026, 3, 6),
      );

      final anyDifferent = first.duaIndex != second.duaIndex ||
          first.ayetIndex != second.ayetIndex ||
          first.iyilikIndex != second.iyilikIndex;
      expect(anyDifferent, isTrue);
    });
  });
}
