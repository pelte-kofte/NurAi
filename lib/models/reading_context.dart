/// The type of reading session.
enum ReadingContextType { explore, hatim, juz }

/// Identifies which reading context is active.
/// Each context stores its own independent progress.
class ReadingContext {
  final ReadingContextType type;
  final int? juzNumber;

  const ReadingContext.explore()
      : type = ReadingContextType.explore,
        juzNumber = null;

  const ReadingContext.hatim()
      : type = ReadingContextType.hatim,
        juzNumber = null;

  const ReadingContext.juz(int number)
      : type = ReadingContextType.juz,
        juzNumber = number;

  /// SharedPreferences key prefix for this context's progress.
  String get _prefix {
    switch (type) {
      case ReadingContextType.explore:
        return 'progress_explore';
      case ReadingContextType.hatim:
        return 'progress_hatim';
      case ReadingContextType.juz:
        return 'progress_juz_$juzNumber';
    }
  }

  String get surahKey => '${_prefix}_surah';
  String get ayahKey => '${_prefix}_ayah';
}
