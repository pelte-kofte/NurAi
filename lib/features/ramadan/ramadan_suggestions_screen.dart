import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/ramadan_suggestions_service.dart';
import '../../l10n/app_strings.dart';

class RamadanSuggestionsScreen extends StatefulWidget {
  const RamadanSuggestionsScreen({super.key});

  @override
  State<RamadanSuggestionsScreen> createState() =>
      _RamadanSuggestionsScreenState();
}

class _RamadanSuggestionsScreenState extends State<RamadanSuggestionsScreen> {
  RamadanSuggestionsBundle? _bundle;
  List<RamadanSuggestionFavorite> _favorites = const [];
  bool _isLoading = true;
  bool _showFavorites = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final bundle = await RamadanSuggestionsService.getTodayBundle();
    final favorites = await RamadanSuggestionsService.getFavorites();
    if (!mounted) return;
    setState(() {
      _bundle = bundle;
      _favorites = favorites;
      _isLoading = false;
    });
  }

  Future<void> _refreshToday() async {
    await RamadanSuggestionsService.refreshToday();
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          S.get('ramadan_suggestions_refreshed'),
          style: const TextStyle(fontFamily: 'Inter'),
        ),
      ),
    );
  }

  Future<void> _toggleFavorite(RamadanSuggestionItem item) async {
    await RamadanSuggestionsService.toggleFavorite(item);
    final favorites = await RamadanSuggestionsService.getFavorites();
    if (!mounted) return;
    setState(() {
      _favorites = favorites;
    });
  }

  Future<void> _removeFavorite(RamadanSuggestionFavorite favorite) async {
    await RamadanSuggestionsService.removeFavorite(favorite);
    final favorites = await RamadanSuggestionsService.getFavorites();
    if (!mounted) return;
    setState(() {
      _favorites = favorites;
    });
  }

  void _shareItem(RamadanSuggestionItem item) {
    final header = S.get(item.headerKey);
    final secondary = (item.secondary ?? '').trim();
    final message = secondary.isEmpty
        ? '$header\n\n${item.text}'
        : '$header\n\n${item.text}\n\n$secondary';
    Share.share(message);
  }

  bool _isFavorite(RamadanSuggestionItem item) {
    return _favorites.any((f) => f.matches(item));
  }

  RamadanSuggestionItem _favoriteToItem(RamadanSuggestionFavorite favorite) {
    final headerKey = switch (favorite.type) {
      RamadanSuggestionType.dua => 'ramadan_suggestion_card_dua',
      RamadanSuggestionType.ayet => 'ramadan_suggestion_card_ayet',
      RamadanSuggestionType.iyilik => 'ramadan_suggestion_card_iyilik',
    };
    return RamadanSuggestionItem(
      type: favorite.type,
      headerKey: headerKey,
      text: favorite.text,
      secondary: favorite.secondary,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF6F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFBF6F2),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_rounded,
            size: 20,
            color: Color(0xFF7A746F),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          S.get('ramadan_suggestions_title'),
          style: const TextStyle(
            fontFamily: 'Merriweather',
            fontSize: 20,
            fontWeight: FontWeight.w400,
            color: Color(0xFF2B2725),
          ),
        ),
        actions: [
          IconButton(
            tooltip: S.get('ramadan_suggestions_refresh'),
            onPressed: _refreshToday,
            icon: const Icon(
              Icons.autorenew_rounded,
              color: Color(0xFF7BAEAC),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Text(
                S.get('prayer_times_loading'),
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: Color(0xFF7A746F),
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              children: [
                Text(
                  S.get('ramadan_suggestions_subtitle'),
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF7A746F),
                  ),
                ),
                const SizedBox(height: 12),
                _buildModeSwitch(),
                const SizedBox(height: 12),
                if (_showFavorites) _buildFavorites() else _buildTodayCards(),
              ],
            ),
    );
  }

  Widget _buildModeSwitch() {
    return Row(
      children: [
        _modeButton(
          label: S.get('ramadan_suggestions_tab_today'),
          selected: !_showFavorites,
          onTap: () => setState(() => _showFavorites = false),
        ),
        const SizedBox(width: 8),
        _modeButton(
          label: S.get('ramadan_suggestions_tab_favorites'),
          selected: _showFavorites,
          onTap: () => setState(() => _showFavorites = true),
        ),
      ],
    );
  }

  Widget _modeButton({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEAF3F2) : const Color(0xFFFDF9F6),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? const Color(0xFF7BAEAC) : const Color(0xFFEDE6E1),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: selected ? const Color(0xFF5F918F) : const Color(0xFF7A746F),
          ),
        ),
      ),
    );
  }

  Widget _buildTodayCards() {
    final bundle = _bundle;
    if (bundle == null) return const SizedBox.shrink();
    return Column(
      children: [
        _SuggestionCard(
          item: bundle.dua,
          favorite: _isFavorite(bundle.dua),
          onToggleFavorite: () => _toggleFavorite(bundle.dua),
          onShare: () => _shareItem(bundle.dua),
        ),
        const SizedBox(height: 10),
        _SuggestionCard(
          item: bundle.ayet,
          favorite: _isFavorite(bundle.ayet),
          onToggleFavorite: () => _toggleFavorite(bundle.ayet),
          onShare: () => _shareItem(bundle.ayet),
        ),
        const SizedBox(height: 10),
        _SuggestionCard(
          item: bundle.iyilik,
          favorite: _isFavorite(bundle.iyilik),
          onToggleFavorite: () => _toggleFavorite(bundle.iyilik),
          onShare: () => _shareItem(bundle.iyilik),
        ),
      ],
    );
  }

  Widget _buildFavorites() {
    if (_favorites.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFFDF9F6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFEDE6E1)),
        ),
        child: Text(
          S.get('ramadan_suggestions_favorites_empty'),
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: Color(0xFF7A746F),
          ),
        ),
      );
    }

    return Column(
      children: _favorites.map((favorite) {
        final item = _favoriteToItem(favorite);
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _SuggestionCard(
            item: item,
            favorite: true,
            onToggleFavorite: () => _removeFavorite(favorite),
            onShare: () => _shareItem(item),
          ),
        );
      }).toList(growable: false),
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({
    required this.item,
    required this.favorite,
    required this.onToggleFavorite,
    required this.onShare,
  });

  final RamadanSuggestionItem item;
  final bool favorite;
  final VoidCallback onToggleFavorite;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF9F6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEDE6E1), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  S.get(item.headerKey),
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF7A746F),
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              IconButton(
                onPressed: onToggleFavorite,
                splashRadius: 18,
                icon: Icon(
                  favorite ? Icons.star_rounded : Icons.star_border_rounded,
                  size: 19,
                  color: const Color(0xFF7BAEAC),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            item.text,
            style: const TextStyle(
              fontFamily: 'Merriweather',
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Color(0xFF2B2725),
              height: 1.5,
            ),
          ),
          if ((item.secondary ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              item.secondary!,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: Color(0xFF7A746F),
              ),
            ),
          ],
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onShare,
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF7A746F),
                visualDensity: VisualDensity.compact,
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              ),
              icon: const Icon(Icons.ios_share_rounded, size: 15),
              label: Text(
                S.get('ramadan_suggestions_share'),
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
