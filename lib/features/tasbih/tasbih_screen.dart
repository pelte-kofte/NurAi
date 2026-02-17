import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/local_preferences_service.dart';
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
    if (LocalPreferencesService.hapticsEnabled.value) {
      HapticFeedback.lightImpact();
    }
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
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFFBF6F2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(
          S.get('tasbih_custom_dhikr'),
          style: const TextStyle(
            fontFamily: 'Merriweather',
            fontSize: 18,
            color: Color(0xFF2B2725),
          ),
        ),
        content: TextField(
          controller: controller,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            hintText: S.get('tasbih_enter_dhikr'),
            filled: true,
            fillColor: const Color(0xFFFDF9F6),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
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
      ),
    );
    controller.dispose();
    if (value == null || value.trim().isEmpty) return null;
    return value.trim();
  }

  Future<int?> _askCustomGoal() async {
    final controller = TextEditingController(text: '33');
    final value = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFFBF6F2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(
          S.get('tasbih_custom_goal'),
          style: const TextStyle(
            fontFamily: 'Merriweather',
            fontSize: 18,
            color: Color(0xFF2B2725),
          ),
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            hintText: S.get('tasbih_enter_goal'),
            filled: true,
            fillColor: const Color(0xFFFDF9F6),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
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
      ),
    );
    controller.dispose();
    return value;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF6F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFBF6F2),
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          S.get('tasbih'),
          style: const TextStyle(
            fontFamily: 'Merriweather',
            fontSize: 20,
            fontWeight: FontWeight.w400,
            color: Color(0xFF2B2725),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF9F6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEDE6E1)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  S.get('tasbih_dhikr'),
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: Color(0xFF7A746F),
                  ),
                ),
              ),
              DropdownButton<String>(
                value: _selectedDhikrKey,
                items: _dhikrOptions
                    .map(
                      (e) => DropdownMenuItem<String>(
                        value: e.key,
                        child: Text(e.label),
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
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: Color(0xFF7A746F),
                  ),
                ),
              ),
              DropdownButton<int>(
                value: _goalOptions.contains(_goal) ? _goal : _customGoalValue,
                items: _goalOptions
                    .map(
                      (e) => DropdownMenuItem<int>(
                        value: e,
                        child: Text(
                            e == _customGoalValue ? S.get('custom') : '$e'),
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF9F6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEDE6E1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            _currentDhikrLabel,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Merriweather',
              fontSize: 20,
              color: Color(0xFF2B2725),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$_currentCount / $_goal',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 34,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2B2725),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTapArea() {
    return Expanded(
      child: GestureDetector(
        onTap: _increment,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFFF7F0EA),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFEDE6E1)),
          ),
          child: Center(
            child: Text(
              S.get('tasbih_tap_to_count'),
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Color(0xFF7A746F),
              ),
            ),
          ),
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
