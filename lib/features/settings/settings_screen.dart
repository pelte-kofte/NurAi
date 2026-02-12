import 'package:flutter/material.dart';
import '../../data/local_preferences_service.dart';
import '../../data/user_profile_service.dart';
import '../../l10n/app_strings.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, this.scrollController});

  final ScrollController? scrollController;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFDF9F6),
      child: ListView(
        controller: widget.scrollController,
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              S.get('settings'),
              style: const TextStyle(
                fontFamily: 'Merriweather',
                fontSize: 20,
                fontWeight: FontWeight.w400,
                color: Color(0xFF2B2725),
              ),
            ),
          ),
          _buildSectionTitle('Profil'),
          ValueListenableBuilder<String?>(
            valueListenable: UserProfileService.displayNameNotifier,
            builder: (context, displayName, _) {
              return _buildRow(
                title: 'Hitap İsmi',
                value: _profileNameLabel(displayName),
                onTap: _showNameEditorSheet,
              );
            },
          ),
          const SizedBox(height: 14),
          _buildRow(
            title: S.get('language'),
            value: _languageLabel(LocalPreferencesService.language.value),
            onTap: () => _showLanguagePicker(),
          ),
          _buildRow(
            title: S.get('appearance'),
            value: _themeModeLabel(LocalPreferencesService.themeMode.value),
            onTap: () => _showThemePicker(),
          ),
          _buildSwitchRow(
            title: S.get('haptics'),
            value: LocalPreferencesService.hapticsEnabled.value,
            onChanged: (v) {
              LocalPreferencesService.setHapticsEnabled(v);
              setState(() {});
            },
          ),
          const SizedBox(height: 24),
          _buildRow(
            title: S.get('send_feedback'),
            onTap: () => _showStubDialog(S.get('stub_feedback')),
          ),
          _buildRow(
            title: S.get('privacy_policy'),
            onTap: () => _showStubDialog(S.get('stub_link')),
          ),
          _buildRow(
            title: S.get('terms'),
            onTap: () => _showStubDialog(S.get('stub_link')),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Color(0xFF7A746F),
          letterSpacing: 0.5,
        ),
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

  String _profileNameLabel(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return 'Belirtilmedi';
    return trimmed;
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
        return S.get('theme_light');
      case ThemeMode.dark:
        return S.get('theme_dark');
      default:
        return S.get('theme_system');
    }
  }

  void _showNameEditorSheet() {
    final controller = TextEditingController(
      text: UserProfileService.displayName ?? '',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: const Color(0xFFFBF6F2),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            8,
            24,
            MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Hitap İsmi',
                style: TextStyle(
                  fontFamily: 'Merriweather',
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF2B2725),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                textInputAction: TextInputAction.done,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF2B2725),
                ),
                decoration: InputDecoration(
                  hintText: 'İsminiz (isteğe bağlı)',
                  hintStyle: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFFB5AEA8),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFFDF9F6),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () async {
                      await UserProfileService.setDisplayName(null);
                      if (ctx.mounted) {
                        Navigator.of(ctx).pop();
                      }
                    },
                    child: const Text(
                      'Temizle',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF7A746F),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () async {
                      await UserProfileService.setDisplayName(controller.text);
                      if (ctx.mounted) {
                        Navigator.of(ctx).pop();
                      }
                    },
                    child: const Text(
                      'Kaydet',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFFB57A5A),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    ).whenComplete(controller.dispose);
  }

  void _showLanguagePicker() {
    _showOptionSheet(
      title: S.get('language'),
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
      title: S.get('appearance'),
      options: [
        _Option(S.get('theme_system'), 'system'),
        _Option(S.get('theme_light'), 'light'),
        _Option(S.get('theme_dark'), 'dark'),
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
              child: Text(
                S.get('ok'),
                style: const TextStyle(
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
