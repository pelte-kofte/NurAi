import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../l10n/app_strings.dart';

class TasbihScreen extends StatefulWidget {
  const TasbihScreen({super.key});

  @override
  State<TasbihScreen> createState() => _TasbihScreenState();
}

class _TasbihScreenState extends State<TasbihScreen> {
  static const String _keyDhikr = 'tasbih_dhikr_key';
  static const String _keyCustomDhikr = 'tasbih_custom_dhikr';
  static const String _keyGoal = 'tasbih_goal_value';
  static const String _keyCount = 'tasbih_current_count';
  static const String _customDhikrKey = 'custom';
  static const int _customGoalValue = -1;

  static const List<_DhikrOption> _baseDhikrs = [
    _DhikrOption(key: 'subhanallah', label: 'Subhanallah'),
    _DhikrOption(key: 'alhamdulillah', label: 'Alhamdulillah'),
    _DhikrOption(key: 'allahu_akbar', label: 'Allahu Akbar'),
    _DhikrOption(key: 'la_ilaha_illallah', label: 'La ilaha illallah'),
    _DhikrOption(key: 'salawat', label: 'Salawat'),
  ];

  String _selectedDhikrKey = _baseDhikrs.first.key;
  String _customDhikr = '';
  int _goal = 33;
  int _currentCount = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  List<_DhikrOption> get _dhikrOptions => [
        ..._baseDhikrs,
        _DhikrOption(
          key: _customDhikrKey,
          label: _customDhikr.trim().isEmpty
              ? '${S.get('custom')}...'
              : _customDhikr.trim(),
        ),
      ];

  List<int> get _goalOptions => const [33, 99, 100, _customGoalValue];

  String get _currentDhikrLabel {
    if (_selectedDhikrKey == _customDhikrKey) {
      return _customDhikr.trim().isEmpty
          ? '${S.get('custom')}...'
          : _customDhikr;
    }
    return _baseDhikrs
        .firstWhere(
          (d) => d.key == _selectedDhikrKey,
          orElse: () => _baseDhikrs.first,
        )
        .label;
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    final dhikr = prefs.getString(_keyDhikr) ?? _baseDhikrs.first.key;
    final customDhikr = prefs.getString(_keyCustomDhikr) ?? '';
    final goal = prefs.getInt(_keyGoal) ?? 33;
    final current = prefs.getInt(_keyCount) ?? 0;

    if (!mounted) return;
    setState(() {
      _selectedDhikrKey = dhikr;
      _customDhikr = customDhikr;
      _goal = goal <= 0 ? 33 : goal;
      _currentCount = current < 0 ? 0 : current;
      _loading = false;
    });
  }

  Future<void> _saveState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyDhikr, _selectedDhikrKey);
    await prefs.setString(_keyCustomDhikr, _customDhikr);
    await prefs.setInt(_keyGoal, _goal);
    await prefs.setInt(_keyCount, _currentCount);
  }

  Future<void> _increment() async {
    HapticFeedback.lightImpact();
    setState(() => _currentCount += 1);
    await _saveState();
  }

  Future<void> _reset() async {
    setState(() => _currentCount = 0);
    await _saveState();
  }

  Future<void> _onDhikrChanged(String? key) async {
    if (key == null) return;
    if (key == _customDhikrKey) {
      final custom = await _askCustomDhikr();
      if (custom == null) return;
      setState(() {
        _customDhikr = custom;
        _selectedDhikrKey = _customDhikrKey;
      });
      await _saveState();
      return;
    }
    setState(() => _selectedDhikrKey = key);
    await _saveState();
  }

  Future<void> _onGoalChanged(int? value) async {
    if (value == null) return;
    if (value == _customGoalValue) {
      final custom = await _askCustomGoal();
      if (custom == null) return;
      setState(() {
        _goal = custom;
        if (_currentCount > _goal) {
          _currentCount = _goal;
        }
      });
      await _saveState();
      return;
    }
    setState(() {
      _goal = value;
      if (_currentCount > _goal) {
        _currentCount = _goal;
      }
    });
    await _saveState();
  }

  Future<String?> _askCustomDhikr() async {
    final controller = TextEditingController(text: _customDhikr);
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
            S.get('tasbih_custom_dhikr'),
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
              onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
              child: Text(S.get('save')),
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
                Navigator.of(ctx).pop(parsed);
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
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
          : Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSelectors(),
                  const SizedBox(height: 16),
                  _buildCounterCard(),
                  const SizedBox(height: 14),
                  _buildTapArea(),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: _reset,
                      icon: const Icon(Icons.refresh_rounded),
                      label: Text(S.get('tasbih_reset')),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSelectors() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  S.get('tasbih_dhikr'),
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: colorScheme.onSurfaceVariant,
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
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  S.get('tasbih_goal'),
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              _buildDropdownField<int>(
                value: _goalOptions.contains(_goal) ? _goal : _customGoalValue,
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
      ),
    );
  }

  Widget _buildCounterCard() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            _currentDhikrLabel,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Merriweather',
              fontSize: 20,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$_currentCount / $_goal',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 34,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTapArea() {
    final colorScheme = Theme.of(context).colorScheme;
    return Expanded(
      child: GestureDetector(
        onTap: _increment,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colorScheme.outline),
          ),
          child: Center(
            child: Text(
              S.get('tasbih_tap_to_count'),
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
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
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colorScheme.outline),
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
}

class _DhikrOption {
  const _DhikrOption({
    required this.key,
    required this.label,
  });

  final String key;
  final String label;
}
