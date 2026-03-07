import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/asmaul_husna_favorites_service.dart';
import '../../data/asmaul_husna_service.dart';
import '../../l10n/app_strings.dart';
import '../../services/share_card_service.dart';
import '../../widgets/share_card_widget.dart';

class AsmaulHusnaScreen extends StatefulWidget {
  const AsmaulHusnaScreen({super.key});

  @override
  State<AsmaulHusnaScreen> createState() => _AsmaulHusnaScreenState();
}

class _AsmaulHusnaScreenState extends State<AsmaulHusnaScreen> {
  final TextEditingController _searchController = TextEditingController();

  List<AsmaulHusnaName> _allNames = const [];
  Set<String> _favoriteIds = <String>{};
  bool _loading = true;
  bool _showFavoritesOnly = false;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_handleSearchChanged);
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_handleSearchChanged)
      ..dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final names = await AsmaulHusnaService.getAllNames();
    final favorites = await AsmaulHusnaFavoritesService.getFavoriteIds();
    if (!mounted) return;
    setState(() {
      _allNames = names;
      _favoriteIds = favorites;
      _loading = false;
    });
  }

  Future<void> _reloadFavorites() async {
    final favorites = await AsmaulHusnaFavoritesService.getFavoriteIds();
    if (!mounted) return;
    setState(() => _favoriteIds = favorites);
  }

  void _handleSearchChanged() {
    setState(() => _query = _searchController.text);
  }

  Future<void> _toggleFavorite(AsmaulHusnaName item) async {
    final isNowFavorite = await AsmaulHusnaFavoritesService.toggle(item.id);
    if (!mounted) return;
    setState(() {
      if (isNowFavorite) {
        _favoriteIds.add(item.id);
      } else {
        _favoriteIds.remove(item.id);
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          S.get(
            isNowFavorite ? 'asma_favorite_added' : 'asma_favorite_removed',
          ),
        ),
      ),
    );
  }

  List<AsmaulHusnaName> _filteredItems(String languageCode) {
    final filtered = _allNames.where(
      (item) =>
          (!_showFavoritesOnly || _favoriteIds.contains(item.id)) &&
          item.matchesQuery(_query, languageCode),
    );
    return filtered.toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final languageCode = Localizations.localeOf(context).languageCode;
    final items = _filteredItems(languageCode);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          S.get('asma_screen_title'),
          style: TextStyle(
            fontFamily: 'Merriweather',
            fontSize: 20,
            fontWeight: FontWeight.w400,
            color: colorScheme.onSurface,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        S.get('asma_explore_subtitle'),
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: colorScheme.onSurface.withValues(alpha: 0.72),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _searchController,
                        textInputAction: TextInputAction.search,
                        decoration: InputDecoration(
                          hintText: S.get('asma_search_hint'),
                          prefixIcon:
                              const Icon(Icons.search_rounded, size: 20),
                          filled: true,
                          fillColor: colorScheme.surfaceContainerHighest,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 13,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        children: [
                          ChoiceChip(
                            label: Text(S.get('asma_filter_all')),
                            selected: !_showFavoritesOnly,
                            onSelected: (_) =>
                                setState(() => _showFavoritesOnly = false),
                          ),
                          ChoiceChip(
                            label: Text(S.get('asma_filter_favorites')),
                            selected: _showFavoritesOnly,
                            onSelected: (_) =>
                                setState(() => _showFavoritesOnly = true),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: items.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Text(
                              _showFavoritesOnly
                                  ? S.get('asma_favorites_empty')
                                  : S.get('asma_empty_state'),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: colorScheme.onSurface
                                    .withValues(alpha: 0.7),
                                height: 1.5,
                              ),
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
                          itemCount: items.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final item = items[index];
                            final isFavorite = _favoriteIds.contains(item.id);
                            return _AsmaListTile(
                              item: item,
                              languageCode: languageCode,
                              isFavorite: isFavorite,
                              onFavoriteTap: () => _toggleFavorite(item),
                              onTap: () async {
                                await Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => AsmaulHusnaDetailScreen(
                                      item: item,
                                      initialIsFavorite: isFavorite,
                                    ),
                                  ),
                                );
                                await _reloadFavorites();
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

class _AsmaListTile extends StatelessWidget {
  const _AsmaListTile({
    required this.item,
    required this.languageCode,
    required this.isFavorite,
    required this.onTap,
    required this.onFavoriteTap,
  });

  final AsmaulHusnaName item;
  final String languageCode;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onFavoriteTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.fromLTRB(18, 18, 16, 18),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.32),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.nameArabic,
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                        fontFamily: 'Amiri',
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.localizedName(languageCode),
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface.withValues(alpha: 0.84),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.localizedMeaning(languageCode),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: colorScheme.onSurface.withValues(alpha: 0.68),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onFavoriteTap,
                tooltip: S.get('today_card_add_to_favorites'),
                icon: Icon(
                  isFavorite ? Icons.favorite_rounded : Icons.favorite_border,
                  size: 20,
                  color: isFavorite
                      ? colorScheme.primary
                      : colorScheme.onSurface.withValues(alpha: 0.55),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AsmaulHusnaDetailScreen extends StatefulWidget {
  const AsmaulHusnaDetailScreen({
    super.key,
    required this.item,
    required this.initialIsFavorite,
  });

  final AsmaulHusnaName item;
  final bool initialIsFavorite;

  @override
  State<AsmaulHusnaDetailScreen> createState() =>
      _AsmaulHusnaDetailScreenState();
}

class _AsmaulHusnaDetailScreenState extends State<AsmaulHusnaDetailScreen> {
  late bool _isFavorite = widget.initialIsFavorite;

  String get _languageCode => Localizations.localeOf(context).languageCode;

  Future<void> _toggleFavorite() async {
    final isNowFavorite =
        await AsmaulHusnaFavoritesService.toggle(widget.item.id);
    if (!mounted) return;
    setState(() => _isFavorite = isNowFavorite);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          S.get(
            isNowFavorite ? 'asma_favorite_added' : 'asma_favorite_removed',
          ),
        ),
      ),
    );
  }

  Future<void> _shareItem() async {
    try {
      await ShareCardService.shareDailyCard(
        context: context,
        payload: ShareCardPayload(
          title: S.get('asma_screen_title'),
          arabicText: widget.item.nameArabic,
          content:
              '${widget.item.localizedName(_languageCode)}\n${widget.item.localizedMeaning(_languageCode)}',
          type: ShareCardType.asma,
          localeCode: _languageCode,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.get('daily_card_share_failed'))),
      );
    }
  }

  Future<void> _copyItem() async {
    final text = [
      widget.item.nameArabic,
      widget.item.localizedName(_languageCode),
      widget.item.localizedMeaning(_languageCode),
      widget.item.localizedReflection(_languageCode),
      widget.item.localizedDhikr(_languageCode),
    ].where((value) => value.trim().isNotEmpty).join('\n');
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(S.get('asma_copied'))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          widget.item.localizedName(_languageCode),
          style: TextStyle(
            fontFamily: 'Merriweather',
            fontSize: 18,
            fontWeight: FontWeight.w400,
            color: colorScheme.onSurface,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _copyItem,
            tooltip: S.get('asma_detail_copy'),
            icon: const Icon(Icons.copy_rounded, size: 20),
          ),
          IconButton(
            onPressed: _shareItem,
            tooltip: S.get('asma_detail_share'),
            icon: const Icon(Icons.ios_share_rounded, size: 20),
          ),
          IconButton(
            onPressed: _toggleFavorite,
            tooltip: S.get('today_card_add_to_favorites'),
            icon: Icon(
              _isFavorite ? Icons.favorite_rounded : Icons.favorite_border,
              size: 20,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(22, 28, 22, 22),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    widget.item.nameArabic,
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 40,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.item.localizedName(_languageCode),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface.withValues(alpha: 0.85),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    widget.item.localizedMeaning(_languageCode),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Merriweather',
                      fontSize: 20,
                      fontWeight: FontWeight.w400,
                      color: colorScheme.onSurface,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _DetailSection(
              label: S.get('asma_reflection_label'),
              body: widget.item.localizedReflection(_languageCode),
            ),
            const SizedBox(height: 16),
            _DetailSection(
              label: S.get('asma_dhikr_label'),
              body: widget.item.localizedDhikr(_languageCode),
              emphasize: true,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _copyItem,
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    label: Text(S.get('asma_detail_copy')),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _shareItem,
                    icon: const Icon(Icons.ios_share_rounded, size: 18),
                    label: Text(S.get('asma_detail_share')),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({
    required this.label,
    required this.body,
    this.emphasize = false,
  });

  final String label;
  final String body;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.26),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colorScheme.secondary,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            body,
            style: TextStyle(
              fontFamily: emphasize ? 'Inter' : 'Merriweather',
              fontSize: emphasize ? 15 : 15.5,
              fontWeight: emphasize ? FontWeight.w600 : FontWeight.w400,
              color: colorScheme.onSurface,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}
