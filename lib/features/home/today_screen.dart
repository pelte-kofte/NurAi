import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/daily_ayah_service.dart';
import '../../data/daily_content_service.dart';
import '../../data/bookmark_service.dart';
import '../../data/quran_data.dart';
import '../../data/quran_turkish_meal_service.dart';
import '../../data/today_card_favorites_service.dart';
import '../../services/share_card_service.dart';
import '../../l10n/app_strings.dart';
import '../../widgets/share_card_widget.dart';

enum _TodayCardMenuAction {
  share,
  favorite,
}

class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  List<TodayCardFavorite> _favorites = const [];
  bool _showFavorites = false;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final favorites = await TodayCardFavoritesService.getFavorites();
    if (!mounted) return;
    setState(() => _favorites = favorites);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final dailyAyah = DailyAyahService.getTodayAyahWithContext(
      QuranData.instance.ayahs,
      QuranData.instance.getSurahName,
    );

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          S.get('today_screen_title'),
          style: TextStyle(
            fontFamily: 'Merriweather',
            fontSize: 20,
            fontWeight: FontWeight.w400,
            color: colorScheme.onSurface,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: Text(S.get('ramadan_suggestions_tab_today')),
                  selected: !_showFavorites,
                  onSelected: (_) => setState(() => _showFavorites = false),
                ),
                ChoiceChip(
                  label: Text(S.get('ramadan_suggestions_tab_favorites')),
                  selected: _showFavorites,
                  onSelected: (_) => setState(() => _showFavorites = true),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_showFavorites)
              _buildFavoritesList(context)
            else
              _buildTodayCards(context, dailyAyah),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayCards(BuildContext context, DailyAyah dailyAyah) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FutureBuilder<String>(
          future: DailyAyahService.getAyahReadableText(
            surah: dailyAyah.surahNumber,
            ayah: dailyAyah.ayahNumber,
            locale: Localizations.localeOf(context),
          ),
          builder: (context, snapshot) {
            final localeCode =
                Localizations.localeOf(context).languageCode.toLowerCase();
            final resolvedReadableText = snapshot.data?.trim();
            final hasReadableText =
                resolvedReadableText != null && resolvedReadableText.isNotEmpty;
            final readableText = hasReadableText
                ? resolvedReadableText
                : (localeCode == 'tr'
                    ? dailyAyah.turkishReadable
                    : (snapshot.connectionState == ConnectionState.done
                        ? S.get('meal_not_available')
                        : S.get('prayer_times_loading')));
            return _buildVerseCard(
              context,
              dailyAyah,
              readableText: readableText,
              onShare: hasReadableText || localeCode == 'tr'
                  ? () => _shareAyahCard(
                        context,
                        dailyAyah: dailyAyah,
                        readableText: readableText,
                      )
                  : null,
              onFavorite: hasReadableText || localeCode == 'tr'
                  ? () => _saveAyahFavorite(
                        context,
                        dailyAyah: dailyAyah,
                        readableText: readableText,
                      )
                  : null,
            );
          },
        ),
        const SizedBox(height: 14),
        ValueListenableBuilder<int>(
          valueListenable: DailyContentService.revision,
          builder: (context, _, __) => _buildContentCard(
            context: context,
            title: S.get('daily_hadith_title'),
            body: DailyContentService.todayHadith?.text ??
                S.get('daily_hadith_empty'),
            source: DailyContentService.todayHadith?.source,
            onShare: () => _shareDailyTextCard(
              context,
              title: S.get('daily_hadith_title'),
              body: DailyContentService.todayHadith?.text ??
                  S.get('daily_hadith_empty'),
              source: DailyContentService.todayHadith?.source,
            ),
            onFavorite: () => _saveTextFavorite(
              context,
              title: S.get('daily_hadith_title'),
              body: DailyContentService.todayHadith?.text ??
                  S.get('daily_hadith_empty'),
              source: DailyContentService.todayHadith?.source,
              type: TodayCardFavoriteType.hadith,
            ),
          ),
        ),
        const SizedBox(height: 14),
        ValueListenableBuilder<int>(
          valueListenable: DailyContentService.revision,
          builder: (context, _, __) => _buildContentCard(
            context: context,
            title: S.get('daily_word_title'),
            body: DailyContentService.todayWord?.text ??
                S.get('daily_word_empty'),
            onShare: () => _shareDailyTextCard(
              context,
              title: S.get('daily_word_title'),
              body: DailyContentService.todayWord?.text ??
                  S.get('daily_word_empty'),
            ),
            onFavorite: () => _saveTextFavorite(
              context,
              title: S.get('daily_word_title'),
              body: DailyContentService.todayWord?.text ??
                  S.get('daily_word_empty'),
              type: TodayCardFavoriteType.reminder,
            ),
          ),
        ),
        const SizedBox(height: 14),
        FutureBuilder<DailyQuoteItem>(
          future: DailyContentService.getQuoteForDate(
            DateTime.now(),
            Localizations.localeOf(context),
          ),
          builder: (context, snapshot) {
            final quote = snapshot.data;
            final hasQuote = quote?.text.trim().isNotEmpty ?? false;
            return _buildContentCard(
              context: context,
              title: S.get('daily_quote_title'),
              body: quote?.text ?? '',
              source: quote?.source,
              showQuoteOrnaments: true,
              onShare: hasQuote
                  ? () => _shareDailyTextCard(
                        context,
                        title: S.get('daily_quote_title'),
                        body: quote?.text ?? '',
                        source: quote?.source,
                      )
                  : null,
              onFavorite: hasQuote
                  ? () => _saveTextFavorite(
                        context,
                        title: S.get('daily_quote_title'),
                        body: quote?.text ?? '',
                        source: quote?.source,
                        type: TodayCardFavoriteType.quote,
                      )
                  : null,
            );
          },
        ),
      ],
    );
  }

  Widget _buildVerseCard(
    BuildContext context,
    DailyAyah dailyAyah, {
    required String readableText,
    VoidCallback? onShare,
    VoidCallback? onFavorite,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final card = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  S.get('daily_ayah'),
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.secondary,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              if (onShare != null && onFavorite != null)
                _buildOverflowButton(
                  context,
                  onShare: onShare,
                  onFavorite: onFavorite,
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            dailyAyah.arabic,
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
            style: TextStyle(
              fontFamily: 'Amiri',
              fontSize: 24,
              fontWeight: FontWeight.w400,
              color: colorScheme.onSurface,
              height: 1.8,
            ),
          ),
          const SizedBox(height: 14),
          _buildReadableLine(
            context: context,
            dailyAyah: dailyAyah,
            readableText: readableText,
            colorScheme: colorScheme,
          ),
          const SizedBox(height: 10),
          Text(
            dailyAyah.reference,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: colorScheme.onSurface.withValues(alpha: 0.72),
            ),
          ),
        ],
      ),
    );
    if (onShare == null) return card;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPress: onShare,
      child: card,
    );
  }

  Widget _buildReadableLine({
    required BuildContext context,
    required DailyAyah dailyAyah,
    required String readableText,
    required ColorScheme colorScheme,
  }) {
    final text = Text(
      readableText,
      style: TextStyle(
        fontFamily: 'Merriweather',
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: colorScheme.onSurface,
        height: 1.6,
      ),
    );

    final isTurkishLine = readableText.trim().isNotEmpty &&
        readableText.trim() == dailyAyah.turkishReadable.trim();
    if (!isTurkishLine) return text;

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => _showMealBottomSheet(context, dailyAyah),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: text,
      ),
    );
  }

  Future<void> _showMealBottomSheet(
      BuildContext context, DailyAyah dailyAyah) async {
    final meal = await QuranTurkishMealService.getTurkishMeal(
      dailyAyah.surahNumber,
      dailyAyah.ayahNumber,
    );
    if (!context.mounted) return;

    final fallback = S
        .get('meal_sheet_title_fallback')
        .replaceAll('{surah}', dailyAyah.surahNumber.toString())
        .replaceAll('{ayah}', dailyAyah.ayahNumber.toString());
    final surahName =
        QuranData.instance.getSurahName(dailyAyah.surahNumber).trim();
    final title = surahName.isEmpty
        ? fallback
        : '$surahName · ${dailyAyah.ayahNumber}. ${S.get('ayah_label')}';
    final body = (meal?.trim().isNotEmpty ?? false)
        ? meal!.trim()
        : S.get('meal_not_available');

    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                S.get('meal_label'),
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(ctx).colorScheme.secondary,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'Merriweather',
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Theme.of(ctx).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              SelectableText(
                body,
                style: TextStyle(
                  fontFamily: 'Merriweather',
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: Theme.of(ctx).colorScheme.onSurface,
                  height: 1.55,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: body));
                      if (!ctx.mounted) return;
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(content: Text(S.get('meal_copied'))),
                      );
                    },
                    child: Text(S.get('meal_copy')),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: Text(S.get('meal_close')),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContentCard({
    required BuildContext context,
    required String title,
    required String body,
    String? source,
    bool showQuoteOrnaments = false,
    VoidCallback? onShare,
    VoidCallback? onFavorite,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final cleanSource = source?.trim() ?? '';
    final card = Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10.5),
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            if (showQuoteOrnaments) ...[
              Positioned(
                left: -24,
                bottom: -28,
                child: Opacity(
                  opacity: 0.1,
                  child: Transform.rotate(
                    angle: -0.12,
                    child: Image.asset(
                      'assets/splash/splash.png',
                      width: 96,
                      height: 96,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              Positioned(
                right: -24,
                bottom: -28,
                child: Opacity(
                  opacity: 0.1,
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..scaleByDouble(-1.0, 1.0, 1.0, 1.0)
                      ..rotateZ(0.12),
                    child: Image.asset(
                      'assets/splash/splash.png',
                      width: 96,
                      height: 96,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ],
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.secondary,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                      if (onShare != null && onFavorite != null)
                        _buildOverflowButton(
                          context,
                          onShare: onShare,
                          onFavorite: onFavorite,
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    body,
                    style: TextStyle(
                      fontFamily: 'Merriweather',
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: colorScheme.onSurface,
                      height: 1.6,
                    ),
                  ),
                  if (cleanSource.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      '- $cleanSource',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: colorScheme.onSurface.withValues(alpha: 0.72),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
    if (onShare == null) return card;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPress: onShare,
      child: card,
    );
  }

  Widget _buildFavoritesList(BuildContext context) {
    if (_favorites.isEmpty) {
      final colorScheme = Theme.of(context).colorScheme;
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.outline),
        ),
        child: Text(
          S.get('today_favorites_empty'),
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: colorScheme.onSurface.withValues(alpha: 0.72),
            height: 1.5,
          ),
        ),
      );
    }

    return Column(
      children: _favorites
          .map(
            (favorite) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _buildFavoriteCard(context, favorite),
            ),
          )
          .toList(growable: false),
    );
  }

  Widget _buildFavoriteCard(BuildContext context, TodayCardFavorite favorite) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasArabic = favorite.arabicText?.trim().isNotEmpty ?? false;
    final cleanReference = favorite.reference?.trim() ?? '';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  favorite.title,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.secondary,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _shareFavorite(context, favorite),
                tooltip: S.get('ramadan_suggestions_share'),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                icon: Icon(
                  Icons.ios_share_rounded,
                  size: 18,
                  color: colorScheme.onSurface.withValues(alpha: 0.72),
                ),
              ),
            ],
          ),
          if (hasArabic) ...[
            const SizedBox(height: 10),
            Text(
              favorite.arabicText!,
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontFamily: 'Amiri',
                fontSize: 22,
                fontWeight: FontWeight.w400,
                color: colorScheme.onSurface,
                height: 1.7,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Text(
            favorite.content,
            style: TextStyle(
              fontFamily: 'Merriweather',
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: colorScheme.onSurface,
              height: 1.6,
            ),
          ),
          if (cleanReference.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              cleanReference,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: colorScheme.onSurface.withValues(alpha: 0.72),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOverflowButton(
    BuildContext context, {
    required VoidCallback onShare,
    required VoidCallback onFavorite,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return IconButton(
      onPressed: () => _showCardActionsSheet(
        context,
        onShare: onShare,
        onFavorite: onFavorite,
      ),
      tooltip: S.get('today_card_more_actions'),
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      icon: Icon(
        Icons.more_horiz_rounded,
        size: 20,
        color: colorScheme.onSurface.withValues(alpha: 0.72),
      ),
    );
  }

  Future<void> _showCardActionsSheet(
    BuildContext context, {
    required VoidCallback onShare,
    required VoidCallback onFavorite,
  }) async {
    final colorScheme = Theme.of(context).colorScheme;
    final action = await showModalBottomSheet<_TodayCardMenuAction>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        final sheetColorScheme = Theme.of(sheetContext).colorScheme;
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildActionTile(
                  context: sheetContext,
                  icon: Icons.ios_share_rounded,
                  label: S.get('ramadan_suggestions_share'),
                  onTap: () => Navigator.of(sheetContext).pop(
                    _TodayCardMenuAction.share,
                  ),
                ),
                const SizedBox(height: 4),
                _buildActionTile(
                  context: sheetContext,
                  icon: Icons.star_border_rounded,
                  label: S.get('today_card_add_to_favorites'),
                  onTap: () => Navigator.of(sheetContext).pop(
                    _TodayCardMenuAction.favorite,
                  ),
                ),
                const SizedBox(height: 4),
                Divider(
                  height: 1,
                  color: sheetColorScheme.outlineVariant.withValues(alpha: 0.4),
                ),
                const SizedBox(height: 4),
                _buildActionTile(
                  context: sheetContext,
                  icon: Icons.close_rounded,
                  label: S.get('cancel'),
                  onTap: () => Navigator.of(sheetContext).pop(),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!context.mounted || action == null) return;
    switch (action) {
      case _TodayCardMenuAction.share:
        onShare();
        break;
      case _TodayCardMenuAction.favorite:
        onFavorite();
        break;
    }
  }

  Widget _buildActionTile({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.32),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: colorScheme.onSurface.withValues(alpha: 0.82),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _shareDailyTextCard(
    BuildContext context, {
    required String title,
    required String body,
    String? source,
  }) async {
    try {
      await ShareCardService.shareDailyCard(
        context: context,
        payload: ShareCardPayload(
          title: title,
          content: body,
          reference: source,
          type: title == S.get('daily_hadith_title')
              ? ShareCardType.hadith
              : title == S.get('daily_quote_title')
                  ? ShareCardType.quote
                  : ShareCardType.reminder,
          localeCode: Localizations.localeOf(context).languageCode,
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      _showShareError(context);
    }
  }

  Future<void> _shareAyahCard(
    BuildContext context, {
    required DailyAyah dailyAyah,
    required String readableText,
  }) async {
    try {
      await ShareCardService.shareDailyCard(
        context: context,
        payload: ShareCardPayload(
          title: S.get('daily_ayah'),
          arabicText: dailyAyah.arabic,
          content: readableText,
          reference: dailyAyah.reference,
          type: ShareCardType.ayah,
          localeCode: Localizations.localeOf(context).languageCode,
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      _showShareError(context);
    }
  }

  void _showShareError(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(S.get('daily_card_share_failed'))),
    );
  }

  Future<void> _saveAyahFavorite(
    BuildContext context, {
    required DailyAyah dailyAyah,
    required String readableText,
  }) async {
    final localeCode = Localizations.localeOf(context).languageCode;
    final alreadySaved = BookmarkService.isBookmarked(
      dailyAyah.surahNumber,
      dailyAyah.ayahNumber,
    );
    if (alreadySaved) {
      _showFavoriteAlreadySaved(context);
      return;
    }

    await BookmarkService.save(dailyAyah.surahNumber, dailyAyah.ayahNumber);
    await TodayCardFavoritesService.addIfAbsent(
      TodayCardFavorite(
        type: TodayCardFavoriteType.ayah,
        title: S.get('daily_ayah'),
        content: readableText,
        arabicText: dailyAyah.arabic,
        reference: dailyAyah.reference,
        localeCode: localeCode,
        surahNumber: dailyAyah.surahNumber,
        ayahNumber: dailyAyah.ayahNumber,
        savedAtIso: DateTime.now().toIso8601String(),
      ),
    );
    await _loadFavorites();
    if (!context.mounted) return;
    _showFavoriteSaved(context);
  }

  Future<void> _saveTextFavorite(
    BuildContext context, {
    required String title,
    required String body,
    required TodayCardFavoriteType type,
    String? source,
  }) async {
    final saved = await TodayCardFavoritesService.addIfAbsent(
      TodayCardFavorite(
        type: type,
        title: title,
        content: body,
        reference: source,
        localeCode: Localizations.localeOf(context).languageCode,
        savedAtIso: DateTime.now().toIso8601String(),
      ),
    );
    await _loadFavorites();
    if (!context.mounted) return;
    if (saved) {
      _showFavoriteSaved(context);
    } else {
      _showFavoriteAlreadySaved(context);
    }
  }

  void _showFavoriteSaved(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(S.get('today_card_favorite_added'))),
    );
  }

  void _showFavoriteAlreadySaved(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(S.get('today_card_favorite_exists'))),
    );
  }

  Future<void> _shareFavorite(
    BuildContext context,
    TodayCardFavorite favorite,
  ) async {
    try {
      await ShareCardService.shareDailyCard(
        context: context,
        payload: ShareCardPayload(
          title: favorite.title,
          content: favorite.content,
          reference: favorite.reference,
          arabicText: favorite.arabicText,
          localeCode: favorite.localeCode ??
              Localizations.localeOf(context).languageCode,
          type: switch (favorite.type) {
            TodayCardFavoriteType.ayah => ShareCardType.ayah,
            TodayCardFavoriteType.hadith => ShareCardType.hadith,
            TodayCardFavoriteType.reminder => ShareCardType.reminder,
            TodayCardFavoriteType.quote => ShareCardType.quote,
          },
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      _showShareError(context);
    }
  }
}
