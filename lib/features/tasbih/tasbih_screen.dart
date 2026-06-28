import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/asmaul_husna_service.dart';
import '../../l10n/app_strings.dart';
import '../../theme/app_theme.dart';

class TasbihScreen extends StatefulWidget {
  const TasbihScreen({super.key});

  @override
  State<TasbihScreen> createState() => _TasbihScreenState();
}

class _TasbihScreenState extends State<TasbihScreen>
    with TickerProviderStateMixin {
  static const String _keyDhikr = 'tasbih_dhikr_key';
  static const String _keyCustomDhikrs = 'tasbih_custom_dhikr_items';
  static const String _keyCustomDhikr = 'tasbih_custom_dhikr';
  static const String _keyGoal = 'tasbih_goal_value';
  static const String _keyCount = 'tasbih_current_count';
  static const String _keyAsmaId = 'tasbih_asma_id';
  static const String _keyAsmaMode = 'tasbih_asma_mode';
  static const String _asmaDhikrKey = 'asmaul_husna';
  static const String _customDhikrActionKey = 'custom_action';
  static const String _customDhikrPrefix = 'custom:';
  static const int _customGoalValue = -1;

  static const List<_DhikrOption> _baseDhikrs = [
    _DhikrOption(key: 'subhanallah', label: 'Subhanallah'),
    _DhikrOption(key: 'alhamdulillah', label: 'Alhamdulillah'),
    _DhikrOption(key: 'allahu_akbar', label: 'Allahu Akbar'),
    _DhikrOption(key: 'la_ilaha_illallah', label: 'La ilaha illallah'),
    _DhikrOption(key: 'salawat', label: 'Salawat'),
  ];

  String _selectedDhikrKey = _baseDhikrs.first.key;
  List<String> _customDhikrs = const [];
  List<AsmaulHusnaName> _asmaNames = const [];
  String? _selectedAsmaId;
  _AsmaTasbihMode _asmaMode = _AsmaTasbihMode.single;
  int _goal = 33;
  int _currentCount = 0;
  bool _loading = true;
  late final AnimationController _tapPulseController;
  late final AnimationController _completionGlowController;
  bool _didShowCompletionMessage = false;
  StateSetter? _settingsSheetSetState;

  @override
  void initState() {
    super.initState();
    _tapPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
      reverseDuration: const Duration(milliseconds: 320),
    );
    _completionGlowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _loadState();
  }

  @override
  void dispose() {
    _tapPulseController.dispose();
    _completionGlowController.dispose();
    super.dispose();
  }

  List<_DhikrOption> get _dhikrOptions => [
        ..._baseDhikrs,
        _DhikrOption(
          key: _asmaDhikrKey,
          label: S.get('tasbih_dhikr_asmaul_husna'),
        ),
        ..._customDhikrs.map(
          (dhikr) => _DhikrOption(
            key: _customKeyFor(dhikr),
            label: dhikr,
          ),
        ),
        _DhikrOption(
          key: _customDhikrActionKey,
          label: S.get('custom'),
        ),
      ];

  List<int> get _goalOptions => const [33, 99, 100, _customGoalValue];

  String get _languageCode => AsmaulHusnaService.currentLanguageCode();

  bool get _isAsmaSelected => _selectedDhikrKey == _asmaDhikrKey;

  bool get _isAsmaMemorizationMode =>
      _isAsmaSelected && _asmaMode == _AsmaTasbihMode.memorization;

  bool get _isCustomDhikrSelected =>
      _selectedDhikrKey.startsWith(_customDhikrPrefix);

  String? get _selectedCustomDhikr {
    if (!_isCustomDhikrSelected) return null;
    return _selectedDhikrKey.substring(_customDhikrPrefix.length);
  }

  int get _effectiveGoal {
    if (!_isAsmaMemorizationMode || _asmaNames.isEmpty) return _goal;
    return _asmaNames.length.clamp(1, _asmaNames.length);
  }

  int get _activeAsmaIndex {
    if (_asmaNames.isEmpty) return 0;
    if (_isAsmaMemorizationMode) {
      return _currentCount.clamp(0, _asmaNames.length - 1);
    }
    final selectedId = _selectedAsmaId;
    final index = _asmaNames.indexWhere((item) => item.id == selectedId);
    return index >= 0 ? index : 0;
  }

  AsmaulHusnaName? get _selectedAsma {
    final selectedId = _selectedAsmaId;
    if (selectedId == null) return _asmaNames.isEmpty ? null : _asmaNames.first;
    for (final item in _asmaNames) {
      if (item.id == selectedId) return item;
    }
    return _asmaNames.isEmpty ? null : _asmaNames.first;
  }

  AsmaulHusnaName? get _activeAsma {
    if (_asmaNames.isEmpty) return null;
    return _asmaNames[_activeAsmaIndex];
  }

  String get _currentDhikrLabel {
    if (_isAsmaSelected) {
      final asma = _isAsmaMemorizationMode ? _activeAsma : _selectedAsma;
      if (asma == null) return S.get('tasbih_dhikr_asmaul_husna');
      return _isAsmaMemorizationMode
          ? asma.localizedName(_languageCode)
          : asma.localizedDhikr(_languageCode);
    }
    if (_isCustomDhikrSelected) {
      return _selectedCustomDhikr ?? S.get('custom');
    }
    return _baseDhikrs
        .firstWhere(
          (d) => d.key == _selectedDhikrKey,
          orElse: () => _baseDhikrs.first,
        )
        .label;
  }

  String? get _currentDhikrMeaningText {
    final asma = _isAsmaMemorizationMode ? _activeAsma : null;
    if (asma == null) return null;
    return asma.localizedMeaning(_languageCode);
  }

  String? get _currentArabicText {
    if (_isAsmaSelected) {
      final asma = _isAsmaMemorizationMode ? _activeAsma : _selectedAsma;
      return asma?.nameArabic;
    }
    return null;
  }

  String? get _transliterationText {
    if (_isAsmaSelected) {
      final asma = _isAsmaMemorizationMode ? _activeAsma : _selectedAsma;
      if (asma == null) return null;
      return _isAsmaMemorizationMode
          ? asma.localizedName(_languageCode)
          : asma.localizedDhikr(_languageCode);
    }
    return _currentDhikrLabel;
  }

  String? get _nextAsmaPreview {
    if (!_isAsmaMemorizationMode || _asmaNames.isEmpty) return null;
    if (_currentCount >= _effectiveGoal) return null;
    final nextIndex = (_activeAsmaIndex + 1).clamp(0, _asmaNames.length - 1);
    if (nextIndex == _activeAsmaIndex) return null;
    final next = _asmaNames[nextIndex];
    return '${next.nameArabic} • ${next.localizedName(_languageCode)}';
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    final asmaNames = await AsmaulHusnaService.getAllNames();
    final storedDhikr = prefs.getString(_keyDhikr) ?? _baseDhikrs.first.key;
    final legacyCustomDhikr = prefs.getString(_keyCustomDhikr)?.trim() ?? '';
    final storedCustomDhikrs = prefs
            .getStringList(_keyCustomDhikrs)
            ?.map((item) => item.trim())
            .where((item) => item.isNotEmpty)
            .toSet()
            .toList() ??
        <String>[];
    if (legacyCustomDhikr.isNotEmpty &&
        !storedCustomDhikrs.contains(legacyCustomDhikr)) {
      storedCustomDhikrs.add(legacyCustomDhikr);
    }
    storedCustomDhikrs.sort();
    final goal = prefs.getInt(_keyGoal) ?? 33;
    final current = prefs.getInt(_keyCount) ?? 0;
    final savedAsmaId = prefs.getString(_keyAsmaId);
    final savedAsmaMode = prefs.getString(_keyAsmaMode);
    final fallbackAsmaId = asmaNames.isEmpty ? null : asmaNames.first.id;
    final hasDhikrOption = [
      ..._baseDhikrs.map((item) => item.key),
      _asmaDhikrKey,
      ...storedCustomDhikrs.map(_customKeyFor),
      _customDhikrActionKey,
      'custom',
    ].contains(storedDhikr);
    var selectedDhikr = hasDhikrOption ? storedDhikr : _baseDhikrs.first.key;
    if (selectedDhikr == 'custom') {
      selectedDhikr = legacyCustomDhikr.isNotEmpty
          ? _customKeyFor(legacyCustomDhikr)
          : _baseDhikrs.first.key;
    }
    final asmaMode = _AsmaTasbihModeParser.fromStorage(savedAsmaMode);
    final normalizedGoal = _normalizeGoal(
      value: goal <= 0 ? 33 : goal,
      isAsmaMemorizationMode: selectedDhikr == _asmaDhikrKey &&
          asmaMode == _AsmaTasbihMode.memorization,
      asmaCount: asmaNames.length,
    );

    if (!mounted) return;
    _updateState(() {
      _asmaNames = asmaNames;
      _selectedDhikrKey = selectedDhikr;
      _customDhikrs = storedCustomDhikrs;
      _asmaMode = asmaMode;
      _goal = normalizedGoal;
      _currentCount = current.clamp(0, normalizedGoal);
      _selectedAsmaId = asmaNames.any((item) => item.id == savedAsmaId)
          ? savedAsmaId
          : fallbackAsmaId;
      _loading = false;
    });
  }

  Future<void> _saveState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyDhikr, _selectedDhikrKey);
    await prefs.setStringList(_keyCustomDhikrs, _customDhikrs);
    await prefs.setString(_keyCustomDhikr, _selectedCustomDhikr ?? '');
    await prefs.setInt(_keyGoal, _goal);
    await prefs.setInt(_keyCount, _currentCount);
    await prefs.setString(_keyAsmaMode, _asmaMode.storageValue);
    if (_selectedAsmaId != null) {
      await prefs.setString(_keyAsmaId, _selectedAsmaId!);
    } else {
      await prefs.remove(_keyAsmaId);
    }
  }

  Future<void> _increment() async {
    if (_currentCount >= _effectiveGoal) return;
    final nextCount = (_currentCount + 1).clamp(0, _effectiveGoal);
    _tapPulseController.forward(from: 0).then((_) {
      if (mounted) {
        _tapPulseController.reverse();
      }
    });
    if (nextCount == _effectiveGoal) {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.lightImpact();
    }
    setState(() => _currentCount = nextCount);
    await _saveState();
    if (nextCount == _effectiveGoal) {
      _completionGlowController.forward(from: 0);
      _showCompletionMessage();
    }
  }

  Future<void> _reset() async {
    _completionGlowController.stop();
    _completionGlowController.value = 0;
    setState(() {
      _currentCount = 0;
      _didShowCompletionMessage = false;
    });
    await _saveState();
  }

  void _showCompletionMessage() {
    if (_didShowCompletionMessage || !mounted) return;
    _didShowCompletionMessage = true;
    final localeCode = Localizations.localeOf(context).languageCode;
    final message = localeCode == 'tr'
        ? 'Tamamlandi. Bir an durup nefesini hisset.'
        : 'Completed. Take a quiet breath before moving on.';
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
  }

  Future<void> _onDhikrChanged(String? key) async {
    if (key == null) return;
    if (key == _customDhikrActionKey) {
      final custom = await _askCustomDhikr();
      if (custom == null) return;
      _updateState(() {
        _customDhikrs = {..._customDhikrs, custom}.toList()..sort();
        _selectedDhikrKey = _customKeyFor(custom);
        _asmaMode = _AsmaTasbihMode.single;
        _goal = _normalizeGoal(
          value: _goal,
          isAsmaMemorizationMode: false,
          asmaCount: _asmaNames.length,
        );
      });
      await _saveState();
      return;
    }
    _updateState(() {
      _selectedDhikrKey = key;
      if (key == _asmaDhikrKey &&
          _selectedAsmaId == null &&
          _asmaNames.isNotEmpty) {
        _selectedAsmaId = _asmaNames.first.id;
      }
      if (key != _asmaDhikrKey) {
        _asmaMode = _AsmaTasbihMode.single;
      }
      _goal = _normalizeGoal(
        value: _goal,
        isAsmaMemorizationMode:
            key == _asmaDhikrKey && _asmaMode == _AsmaTasbihMode.memorization,
        asmaCount: _asmaNames.length,
      );
      if (_currentCount > _goal) {
        _currentCount = _goal;
      }
    });
    await _saveState();
  }

  Future<void> _onAsmaModeChanged(_AsmaTasbihMode mode) async {
    if (_asmaMode == mode) return;
    _updateState(() {
      _asmaMode = mode;
      _currentCount = 0;
      _goal = _normalizeGoal(
        value: _goal,
        isAsmaMemorizationMode: mode == _AsmaTasbihMode.memorization,
        asmaCount: _asmaNames.length,
      );
      if (_selectedAsmaId == null && _asmaNames.isNotEmpty) {
        _selectedAsmaId = _asmaNames.first.id;
      }
    });
    await _saveState();
  }

  Future<void> _onAsmaChanged(String? id) async {
    if (id == null) return;
    _updateState(() => _selectedAsmaId = id);
    await _saveState();
  }

  Future<void> _goToNextAsma() async {
    if (_asmaNames.isEmpty) return;
    final currentIndex =
        _asmaNames.indexWhere((item) => item.id == _selectedAsmaId);
    final nextIndex =
        currentIndex < 0 ? 0 : (currentIndex + 1) % _asmaNames.length;
    _updateState(() => _selectedAsmaId = _asmaNames[nextIndex].id);
    await _saveState();
  }

  Future<void> _onGoalChanged(int? value) async {
    if (value == null) return;
    if (value == _customGoalValue) {
      final custom = await _askCustomGoal();
      if (custom == null) return;
      _updateState(() {
        _goal = _normalizeGoal(
          value: custom,
          isAsmaMemorizationMode: _isAsmaMemorizationMode,
          asmaCount: _asmaNames.length,
        );
        if (_currentCount > _goal) {
          _currentCount = _goal;
        }
      });
      await _saveState();
      return;
    }
    _updateState(() {
      _goal = _normalizeGoal(
        value: value,
        isAsmaMemorizationMode: _isAsmaMemorizationMode,
        asmaCount: _asmaNames.length,
      );
      if (_currentCount > _goal) {
        _currentCount = _goal;
      }
    });
    await _saveState();
  }

  Future<String?> _askCustomDhikr() async {
    final controller = TextEditingController(text: _selectedCustomDhikr ?? '');
    final value = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final colorScheme = theme.colorScheme;
        return AlertDialog(
          backgroundColor: theme.scaffoldBackgroundColor,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: Text(
            S.get('tasbih_custom_dhikr_input_title'),
            style: TextStyle(
              fontFamily: 'Merriweather',
              fontSize: 18,
              color: colorScheme.onSurface,
            ),
          ),
          content: TextField(
            controller: controller,
            textInputAction: TextInputAction.done,
            style: TextStyle(
              fontFamily: 'Inter',
              color: colorScheme.onSurface,
            ),
            decoration: _inputDecoration(
              ctx,
              hintText: S.get('tasbih_enter_dhikr'),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(S.get('cancel')),
            ),
            TextButton(
              onPressed: () {
                final trimmed = controller.text.trim();
                if (trimmed.isEmpty) return;
                Navigator.of(ctx).pop(trimmed);
              },
              child: Text(S.get('tasbih_save_dhikr')),
            ),
          ],
        );
      },
    );
    controller.dispose();
    if (value == null || value.trim().isEmpty) return null;
    return value.trim();
  }

  Future<int?> _askCustomGoal() async {
    final controller = TextEditingController(text: '33');
    final value = await showDialog<int>(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final colorScheme = theme.colorScheme;
        return AlertDialog(
          backgroundColor: theme.scaffoldBackgroundColor,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: Text(
            S.get('tasbih_custom_goal'),
            style: TextStyle(
              fontFamily: 'Merriweather',
              fontSize: 18,
              color: colorScheme.onSurface,
            ),
          ),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: TextStyle(
              fontFamily: 'Inter',
              color: colorScheme.onSurface,
            ),
            decoration: _inputDecoration(
              ctx,
              hintText: S.get('tasbih_enter_goal'),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(S.get('cancel')),
            ),
            TextButton(
              onPressed: () {
                final parsed = int.tryParse(controller.text.trim());
                if (parsed == null || parsed <= 0) {
                  Navigator.of(ctx).pop();
                  return;
                }
                Navigator.of(ctx).pop(
                  _normalizeGoal(
                    value: parsed,
                    isAsmaMemorizationMode: _isAsmaMemorizationMode,
                    asmaCount: _asmaNames.length,
                  ),
                );
              },
              child: Text(S.get('save')),
            ),
          ],
        );
      },
    );
    controller.dispose();
    return value;
  }

  int _normalizeGoal({
    required int value,
    required bool isAsmaMemorizationMode,
    required int asmaCount,
  }) {
    final normalized = value <= 0 ? 33 : value;
    if (!isAsmaMemorizationMode || asmaCount <= 0) return normalized;
    return 99.clamp(1, asmaCount);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final completed = _currentCount >= _effectiveGoal;
    final remaining = (_effectiveGoal - _currentCount).clamp(0, _effectiveGoal);

    if (!completed && _didShowCompletionMessage) {
      _didShowCompletionMessage = false;
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          S.get('tasbih'),
          style: TextStyle(
            fontFamily: 'Merriweather',
            fontSize: 20,
            fontWeight: FontWeight.w400,
            color: colorScheme.onSurface,
          ),
        ),
      ),
      body: _loading
          ? Center(
              child: CircularProgressIndicator(color: colorScheme.primary),
            )
          : DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.18),
                  radius: 1.08,
                  colors: [
                    Colors.white.withValues(alpha: 0.92),
                    const Color(0xFFF7F1E8),
                    theme.scaffoldBackgroundColor,
                  ],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
                child: Column(
                  children: [
                    _buildFocusHeader(completed: completed),
                    const SizedBox(height: 18),
                    Expanded(
                      child: _buildCountingSanctuary(
                        completed: completed,
                        remaining: remaining,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildUtilityBar(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildFocusHeader({required bool completed}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.94),
            completed
                ? AppColors.emphasisAccent.withValues(alpha: 0.08)
                : const Color(0xFFF5EEE5),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: completed
              ? AppColors.emphasisAccent.withValues(alpha: 0.24)
              : const Color(0xFFE7DED2),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0B8F7E6E),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          if (_currentArabicText != null) ...[
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: Text(
                _currentArabicText!,
                key: ValueKey<String>('arabic:${_currentArabicText!}'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 38,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF26211D),
                  height: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: Text(
              _transliterationText ?? _currentDhikrLabel,
              key: ValueKey<String>(
                'translit:${_transliterationText ?? _currentDhikrLabel}',
              ),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily:
                    _currentArabicText == null ? 'Merriweather' : 'Inter',
                fontSize: _currentArabicText == null ? 24 : 15,
                fontWeight: _currentArabicText == null
                    ? FontWeight.w400
                    : FontWeight.w600,
                color: completed
                    ? AppColors.emphasisAccent
                    : const Color(0xFF645A53),
                height: 1.35,
              ),
            ),
          ),
          if (_currentDhikrMeaningText != null) ...[
            const SizedBox(height: 8),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: Text(
                _currentDhikrMeaningText!,
                key: ValueKey<String>('meaning:${_currentDhikrMeaningText!}'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF8A7F75),
                  height: 1.5,
                ),
              ),
            ),
          ],
          if (_isAsmaMemorizationMode &&
              !completed &&
              _nextAsmaPreview != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.62),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '${S.get('tasbih_next_name')}: $_nextAsmaPreview',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF70655D),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCountingSanctuary({
    required bool completed,
    required int remaining,
  }) {
    final progress = _effectiveGoal <= 0
        ? 0.0
        : (_currentCount / _effectiveGoal).clamp(0.0, 1.0);

    return GestureDetector(
      onTap: _increment,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _tapPulseController,
          _completionGlowController,
        ]),
        builder: (context, _) {
          final scale = 1 - (_tapPulseController.value * 0.018);
          return Transform.scale(
            scale: scale,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.9),
                    completed
                        ? AppColors.turquoiseAccent.withValues(alpha: 0.18)
                        : const Color(0xFFF5EFE7),
                  ],
                ),
                borderRadius: BorderRadius.circular(34),
                border: Border.all(
                  color: completed
                      ? AppColors.emphasisAccent.withValues(alpha: 0.28)
                      : const Color(0xFFE8DED2),
                ),
                boxShadow: [
                  BoxShadow(
                    color: completed
                        ? AppColors.turquoiseAccentStrong
                            .withValues(alpha: 0.18)
                        : const Color(0x0A8F7E6E),
                    blurRadius: completed ? 34 : 20,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    top: 28,
                    right: 26,
                    child: IgnorePointer(
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              completed
                                  ? AppColors.emphasisAccent.withValues(
                                      alpha: 0.24,
                                    )
                                  : AppColors.turquoiseAccent.withValues(
                                      alpha: 0.18,
                                    ),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Center(
                        child: Container(
                          width: 314,
                          height: 314,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                completed
                                    ? AppColors.emphasisAccent.withValues(
                                        alpha: 0.10 +
                                            (_completionGlowController.value *
                                                0.10),
                                      )
                                    : AppColors.indigoAccent.withValues(
                                        alpha: 0.025 +
                                            (_tapPulseController.value * 0.035),
                                      ),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Center(
                        child: Container(
                          width: 242,
                          height: 242,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                Colors.white.withValues(
                                  alpha: completed
                                      ? 0.26 +
                                          (_completionGlowController.value *
                                              0.08)
                                      : 0.22 +
                                          (_tapPulseController.value * 0.05),
                                ),
                                Colors.white.withValues(alpha: 0.04),
                                Colors.transparent,
                              ],
                              stops: const [0.0, 0.54, 1.0],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 24,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 290,
                          height: 290,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              TweenAnimationBuilder<double>(
                                tween: Tween<double>(begin: 0, end: progress),
                                duration: const Duration(milliseconds: 520),
                                curve: Curves.easeOutQuart,
                                builder: (context, value, _) {
                                  return SizedBox(
                                    width: 262,
                                    height: 262,
                                    child: CircularProgressIndicator(
                                      value: value,
                                      strokeWidth: 8.5,
                                      backgroundColor: const Color(0xFFEDE5DB),
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        completed
                                            ? AppColors.turquoiseAccentStrong
                                            : AppColors.indigoAccent.withValues(
                                                alpha: 0.92,
                                              ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                              Container(
                                width: 228,
                                height: 228,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Colors.white.withValues(alpha: 0.94),
                                      completed
                                          ? AppColors.turquoiseAccent
                                              .withValues(
                                              alpha: 0.24,
                                            )
                                          : const Color(0xFFF2EBE2),
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: completed
                                          ? AppColors.turquoiseAccentStrong
                                              .withValues(alpha: 0.16)
                                          : const Color(0x0A9D9488),
                                      blurRadius: completed ? 28 : 20,
                                      offset: const Offset(0, 10),
                                    ),
                                    BoxShadow(
                                      color: Colors.white.withValues(
                                        alpha: completed ? 0.42 : 0.34,
                                      ),
                                      blurRadius: 2,
                                      spreadRadius: -1,
                                      offset: const Offset(0, -2),
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 22),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    AnimatedSwitcher(
                                      duration:
                                          const Duration(milliseconds: 180),
                                      transitionBuilder: (child, animation) {
                                        return FadeTransition(
                                          opacity: animation,
                                          child: ScaleTransition(
                                            scale: Tween<double>(
                                              begin: 0.94,
                                              end: 1,
                                            ).animate(animation),
                                            child: child,
                                          ),
                                        );
                                      },
                                      child: Text(
                                        '$_currentCount',
                                        key: ValueKey<int>(_currentCount),
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: completed ? 88 : 84,
                                          fontWeight: FontWeight.w700,
                                          color: completed
                                              ? const Color(0xFF203432)
                                              : const Color(0xFF1F1A17),
                                          letterSpacing: -2.2,
                                          height: 1,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    Text(
                                      '$_currentCount / $_effectiveGoal',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 17,
                                        fontWeight: FontWeight.w600,
                                        color: completed
                                            ? AppColors.turquoiseAccentStrong
                                                .withValues(alpha: 0.9)
                                            : const Color(0xFF6B625A),
                                        letterSpacing: 0.1,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      completed
                                          ? (_isAsmaMemorizationMode
                                              ? S.get('tasbih_completed')
                                              : S.get('tasbih_target_reached'))
                                          : '$remaining',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: completed ? 13 : 28,
                                        fontWeight: completed
                                            ? FontWeight.w600
                                            : FontWeight.w500,
                                        color: completed
                                            ? AppColors.emphasisAccent
                                            : const Color(0xFF877D73),
                                        letterSpacing: completed ? 0.15 : -0.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          completed
                              ? (_isAsmaMemorizationMode
                                  ? S.get('tasbih_completed')
                                  : S.get('tasbih_target_reached'))
                              : (_isAsmaMemorizationMode
                                  ? S.get('tasbih_tap_for_next_name')
                                  : S.get('tasbih_tap_to_count')),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: completed
                                ? AppColors.turquoiseAccentStrong
                                    .withValues(alpha: 0.92)
                                : const Color(0xFF5E564F),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildUtilityBar() {
    return Row(
      children: [
        Expanded(
          child: _SecondaryActionButton(
            icon: Icons.refresh_rounded,
            label: S.get('tasbih_reset'),
            onTap: _reset,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SecondaryActionButton(
            icon: Icons.tune_rounded,
            label: S.get('tasbih_dhikr'),
            onTap: _openSettingsSheet,
          ),
        ),
      ],
    );
  }

  Future<void> _openSettingsSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, modalSetState) {
            _settingsSheetSetState = modalSetState;
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  8,
                  20,
                  24 + MediaQuery.of(context).viewInsets.bottom,
                ),
                child: SingleChildScrollView(
                  child: _buildSelectors(),
                ),
              ),
            );
          },
        );
      },
    );
    _settingsSheetSetState = null;
    if (mounted) {
      setState(() {});
    }
  }

  void _updateState(VoidCallback fn) {
    if (mounted) {
      setState(fn);
    } else {
      fn();
    }
    final modalSetState = _settingsSheetSetState;
    if (modalSetState != null) {
      modalSetState(() {});
    }
  }

  String _customKeyFor(String value) => '$_customDhikrPrefix$value';

  Widget _buildSelectors() {
    final colorScheme = Theme.of(context).colorScheme;
    final isAsmaSelected = _isAsmaSelected;
    final isAsmaMemorizationMode = _isAsmaMemorizationMode;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.94),
            const Color(0xFFF5EEE6),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE7DED2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            S.get('tasbih_dhikr'),
            style: const TextStyle(
              fontFamily: 'Merriweather',
              fontSize: 19,
              fontWeight: FontWeight.w400,
              color: Color(0xFF2B2622),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  S.get('tasbih_dhikr'),
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: Color(0xFF7A7068),
                  ),
                ),
              ),
              _buildDropdownField<String>(
                value: _selectedDhikrKey,
                items: _dhikrOptions
                    .map(
                      (e) => DropdownMenuItem<String>(
                        value: e.key,
                        child: Text(
                          e.label,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: _onDhikrChanged,
              ),
            ],
          ),
          if (isAsmaSelected && _asmaNames.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              S.get('tasbih_asma_mode'),
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: Color(0xFF7A7068),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildAsmaModeChip(
                    mode: _AsmaTasbihMode.single,
                    label: S.get('tasbih_asma_mode_single'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildAsmaModeChip(
                    mode: _AsmaTasbihMode.memorization,
                    label: S.get('tasbih_asma_mode_memorization'),
                  ),
                ),
              ],
            ),
            if (!isAsmaMemorizationMode) ...[
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      S.get('tasbih_asma_name'),
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        color: Color(0xFF7A7068),
                      ),
                    ),
                  ),
                  Flexible(
                    child: _buildDropdownField<String>(
                      value: _selectedAsma?.id ?? _asmaNames.first.id,
                      items: _asmaNames
                          .map(
                            (e) => DropdownMenuItem<String>(
                              value: e.id,
                              child: Text(
                                '${e.nameArabic} • ${e.localizedName(_languageCode)}',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: _onAsmaChanged,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _goToNextAsma,
                    tooltip: S.get('tasbih_next_name'),
                    icon: const Icon(Icons.arrow_forward_rounded),
                  ),
                ],
              ),
            ],
          ],
          if (!isAsmaMemorizationMode) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    S.get('tasbih_goal'),
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: Color(0xFF7A7068),
                    ),
                  ),
                ),
                _buildDropdownField<int>(
                  value:
                      _goalOptions.contains(_goal) ? _goal : _customGoalValue,
                  items: _goalOptions
                      .map(
                        (e) => DropdownMenuItem<int>(
                          value: e,
                          child: Text(
                            e == _customGoalValue ? S.get('custom') : '$e',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: _onGoalChanged,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(
    BuildContext context, {
    required String hintText,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final outline = colorScheme.outline;
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(
        fontFamily: 'Inter',
        color: colorScheme.onSurfaceVariant,
      ),
      labelStyle: TextStyle(
        fontFamily: 'Inter',
        color: colorScheme.onSurfaceVariant,
      ),
      floatingLabelStyle: TextStyle(
        fontFamily: 'Inter',
        color: colorScheme.primary,
      ),
      filled: true,
      fillColor: colorScheme.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
      ),
    );
  }

  Widget _buildDropdownField<T>({
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: (_asmaMode == _AsmaTasbihMode.memorization ||
                _selectedDhikrKey == _asmaDhikrKey)
            ? AppColors.emphasisAccent.withValues(alpha: 0.08)
            : Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: (_asmaMode == _AsmaTasbihMode.memorization ||
                  _selectedDhikrKey == _asmaDhikrKey)
              ? AppColors.emphasisAccent.withValues(alpha: 0.18)
              : const Color(0xFFE4DBD0),
        ),
      ),
      child: DropdownButton<T>(
        value: value,
        items: items,
        onChanged: onChanged,
        underline: const SizedBox.shrink(),
        dropdownColor: colorScheme.surface,
        iconEnabledColor: colorScheme.onSurfaceVariant,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          color: colorScheme.onSurface,
        ),
      ),
    );
  }

  Widget _buildAsmaModeChip({
    required _AsmaTasbihMode mode,
    required String label,
  }) {
    final selected = _asmaMode == mode;
    return InkWell(
      onTap: () => _onAsmaModeChanged(mode),
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.emphasisAccent.withValues(alpha: 0.18)
              : Colors.white.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? AppColors.emphasisAccent.withValues(alpha: 0.38)
                : const Color(0xFFE4DBD0),
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected
                ? AppColors.emphasisAccent
                : Theme.of(context).colorScheme.onSurface.withValues(
                      alpha: 0.74,
                    ),
          ),
        ),
      ),
    );
  }
}

class _SecondaryActionButton extends StatelessWidget {
  const _SecondaryActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: 0.84),
              const Color(0xFFF4EDE4),
            ],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE4DBD0)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: const Color(0xFF675D55)),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF413A35),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DhikrOption {
  const _DhikrOption({
    required this.key,
    required this.label,
  });

  final String key;
  final String label;
}

enum _AsmaTasbihMode {
  single,
  memorization,
}

extension _AsmaTasbihModeStorage on _AsmaTasbihMode {
  String get storageValue => switch (this) {
        _AsmaTasbihMode.single => 'single',
        _AsmaTasbihMode.memorization => 'memorization',
      };
}

class _AsmaTasbihModeParser {
  static _AsmaTasbihMode fromStorage(String? value) {
    return value == 'memorization'
        ? _AsmaTasbihMode.memorization
        : _AsmaTasbihMode.single;
  }
}
