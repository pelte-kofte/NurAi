import 'package:flutter/material.dart';
import '../../data/local_preferences_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
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
        title: const Text(
          'Ayarlar',
          style: TextStyle(
            fontFamily: 'Merriweather',
            fontSize: 20,
            fontWeight: FontWeight.w400,
            color: Color(0xFF2B2725),
          ),
        ),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        children: [
          _buildRow(
            title: 'Dil',
            value: _languageLabel(LocalPreferencesService.language.value),
            onTap: () => _showLanguagePicker(),
          ),
          _buildRow(
            title: 'Görünüş',
            value: _themeModeLabel(LocalPreferencesService.themeMode.value),
            onTap: () => _showThemePicker(),
          ),
          _buildSwitchRow(
            title: 'Haptik geri bildirim',
            value: LocalPreferencesService.hapticsEnabled.value,
            onChanged: (v) {
              LocalPreferencesService.setHapticsEnabled(v);
              setState(() {});
            },
          ),
          const SizedBox(height: 24),
          _buildRow(
            title: 'Geri bildirim gönder',
            onTap: () => _showStubDialog('Geri bildirim özelliği yakında eklenecek.'),
          ),
          _buildRow(
            title: 'Gizlilik Politikası',
            onTap: () => _showStubDialog('Bağlantı eklenecek.'),
          ),
          _buildRow(
            title: 'Kullanım Şartları',
            onTap: () => _showStubDialog('Bağlantı eklenecek.'),
          ),
        ],
      ),
    );
  }

  Widget _buildRow({
    required String title,
    String? value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF2B2725),
                ),
              ),
            ),
            if (value != null)
              Text(
                value,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF7A746F),
                ),
              ),
            const SizedBox(width: 4),
            const Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: Color(0xFFB5AEA8),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchRow({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: Color(0xFF2B2725),
              ),
            ),
          ),
          SizedBox(
            height: 28,
            child: Switch.adaptive(
              value: value,
              onChanged: onChanged,
              activeTrackColor: const Color(0xFFB57A5A),
            ),
          ),
        ],
      ),
    );
  }

  String _languageLabel(String code) {
    switch (code) {
      case 'en':
        return 'English';
      default:
        return 'Türkçe';
    }
  }

  String _themeModeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Açık';
      case ThemeMode.dark:
        return 'Koyu';
      default:
        return 'Sistem';
    }
  }

  void _showLanguagePicker() {
    _showOptionSheet(
      title: 'Dil',
      options: const [
        _Option('Türkçe', 'tr'),
        _Option('English', 'en'),
      ],
      current: LocalPreferencesService.language.value,
      onSelect: (val) {
        LocalPreferencesService.setLanguage(val);
        setState(() {});
      },
    );
  }

  void _showThemePicker() {
    _showOptionSheet(
      title: 'Görünüş',
      options: const [
        _Option('Sistem', 'system'),
        _Option('Açık', 'light'),
        _Option('Koyu', 'dark'),
      ],
      current: switch (LocalPreferencesService.themeMode.value) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        _ => 'system',
      },
      onSelect: (val) {
        final mode = switch (val) {
          'light' => ThemeMode.light,
          'dark' => ThemeMode.dark,
          _ => ThemeMode.system,
        };
        LocalPreferencesService.setThemeMode(mode);
        setState(() {});
      },
    );
  }

  void _showOptionSheet({
    required String title,
    required List<_Option> options,
    required String current,
    required ValueChanged<String> onSelect,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFFBF6F2),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF7A746F),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 16),
                ...options.map((opt) {
                  final isSelected = opt.value == current;
                  return GestureDetector(
                    onTap: () {
                      Navigator.of(ctx).pop();
                      onSelect(opt.value);
                    },
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              opt.label,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 15,
                                fontWeight: isSelected
                                    ? FontWeight.w500
                                    : FontWeight.w400,
                                color: const Color(0xFF2B2725),
                              ),
                            ),
                          ),
                          if (isSelected)
                            const Icon(
                              Icons.check_rounded,
                              size: 18,
                              color: Color(0xFFB57A5A),
                            ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showStubDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFFFBF6F2),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          content: Text(
            message,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Color(0xFF7A746F),
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text(
                'Tamam',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFFB57A5A),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Option {
  const _Option(this.label, this.value);
  final String label;
  final String value;
}

