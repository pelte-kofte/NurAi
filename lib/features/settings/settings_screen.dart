import 'package:flutter/material.dart';
import '../../data/local_preferences_service.dart';
import '../../data/prayer_location_service.dart';
import '../../data/premium_service.dart';
import '../../data/user_profile_service.dart';
import '../../data/widget_payload_service.dart';
import '../../l10n/app_strings.dart';
import '../../models/prayer_location.dart';
import '../notes/notes_screen.dart';
import '../premium/paywall_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, this.scrollController});

  final ScrollController? scrollController;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const Color _mutedIconColor = Color(0xFF8FA9A7);

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
          _buildSectionTitle(S.get('profile')),
          ValueListenableBuilder<String?>(
            valueListenable: UserProfileService.displayNameNotifier,
            builder: (context, displayName, _) {
              return _buildRow(
                title: S.get('display_name'),
                value: _profileNameLabel(displayName),
                onTap: _showNameEditorSheet,
              );
            },
          ),
          ValueListenableBuilder<bool>(
            valueListenable: PremiumService.isPremium,
            builder: (context, isPremium, _) {
              return _buildLockRow(
                title: S.get('my_notes'),
                icon: Icons.note_alt_outlined,
                locked: !isPremium,
                onTap: () => _openNotesOrPaywall(isPremium),
              );
            },
          ),
          const SizedBox(height: 14),
          _buildSectionTitle(
            S.get('prayer_times'),
            icon: Icons.access_time_rounded,
          ),
          _buildRow(
            title: S.get('location'),
            icon: Icons.location_on_outlined,
            value: _prayerLocationModeLabel(
              LocalPreferencesService.prayerLocation.value.mode,
            ),
            onTap: () => _showPrayerLocationPicker(),
          ),
          if (LocalPreferencesService.prayerLocation.value.mode ==
              PrayerLocationMode.current)
            Padding(
              padding: const EdgeInsets.only(top: 2, bottom: 12),
              child: Text(
                S.get('location_privacy_note'),
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFFB5AEA8),
                  height: 1.4,
                ),
              ),
            ),
          const SizedBox(height: 6),
          _buildRow(
            title: S.get('language'),
            icon: Icons.translate_rounded,
            value: _languageLabel(LocalPreferencesService.language.value),
            onTap: () => _showLanguagePicker(),
          ),
          _buildRow(
            title: S.get('appearance'),
            icon: Icons.tune_rounded,
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

  Widget _buildSectionTitle(String title, {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 4),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: _mutedIconColor),
            const SizedBox(width: 8),
          ],
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF7A746F),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow({
    required String title,
    IconData? icon,
    String? value,
    required VoidCallback onTap,
  }) {
    final chevron = Directionality.of(context) == TextDirection.rtl
        ? Icons.chevron_left_rounded
        : Icons.chevron_right_rounded;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 17, color: _mutedIconColor),
              const SizedBox(width: 10),
            ],
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
            Icon(
              chevron,
              size: 18,
              color: const Color(0xFFB5AEA8),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLockRow({
    required String title,
    IconData? icon,
    required bool locked,
    required VoidCallback onTap,
  }) {
    final chevron = Directionality.of(context) == TextDirection.rtl
        ? Icons.chevron_left_rounded
        : Icons.chevron_right_rounded;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 17, color: _mutedIconColor),
              const SizedBox(width: 10),
            ],
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
            if (locked)
              const Padding(
                padding: EdgeInsets.only(right: 6),
                child: Icon(
                  Icons.lock_outline_rounded,
                  size: 16,
                  color: Color(0xFFB5AEA8),
                ),
              ),
            Icon(
              chevron,
              size: 18,
              color: const Color(0xFFB5AEA8),
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
    if (trimmed == null || trimmed.isEmpty) return S.get('name_not_set');
    return trimmed;
  }

  String _languageLabel(String code) {
    switch (code) {
      case 'ar':
        return S.get('language_ar');
      case 'de':
        return S.get('language_de');
      case 'fr':
        return S.get('language_fr');
      case 'en':
        return S.get('language_en');
      case 'tr':
        return S.get('language_tr');
      default:
        return code;
    }
  }

  String _themeModeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return S.get('light');
      case ThemeMode.dark:
        return S.get('dark');
      default:
        return S.get('system');
    }
  }

  String _prayerLocationModeLabel(PrayerLocationMode mode) {
    switch (mode) {
      case PrayerLocationMode.current:
        return S.get('use_current_location');
      case PrayerLocationMode.city:
        return S.get('select_city');
    }
  }

  void _showPrayerLocationPicker() {
    _showOptionSheet(
      title: S.get('location'),
      options: [
        _Option(S.get('use_current_location'), 'current'),
        _Option(S.get('select_city'), 'city'),
      ],
      current: LocalPreferencesService.prayerLocation.value.mode.name,
      onSelect: (value) async {
        if (value == 'current') {
          final result = await PrayerLocationService.useCurrentLocation();
          if (!mounted) return;
          if (result != PrayerLocationActionResult.success) {
            _showStubDialog(_locationErrorMessage(result));
          }
          setState(() {});
          return;
        }

        await PrayerLocationService.selectCityPlaceholder();
        if (!mounted) return;
        _showStubDialog(S.get('city_placeholder'));
        setState(() {});
      },
    );
  }

  String _locationErrorMessage(PrayerLocationActionResult result) {
    switch (result) {
      case PrayerLocationActionResult.serviceDisabled:
        return S.get('location_service_disabled');
      case PrayerLocationActionResult.permissionDenied:
        return S.get('location_permission_denied');
      case PrayerLocationActionResult.permissionDeniedForever:
        return S.get('location_permission_denied_forever');
      case PrayerLocationActionResult.unavailableOnWeb:
        return S.get('location_unavailable_web');
      case PrayerLocationActionResult.failed:
        return S.get('location_read_failed');
      case PrayerLocationActionResult.success:
        return S.get('ok');
    }
  }

  void _openNotesOrPaywall(bool isPremium) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => isPremium ? const NotesScreen() : const PaywallScreen(),
      ),
    );
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
              Text(
                S.get('display_name'),
                style: const TextStyle(
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
                  hintText: S.get('name_hint'),
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
                    child: Text(
                      S.get('clear'),
                      style: const TextStyle(
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
                    child: Text(
                      S.get('save'),
                      style: const TextStyle(
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
      options: [
        _Option(S.get('language_tr'), 'tr'),
        _Option(S.get('language_en'), 'en'),
        _Option(S.get('language_ar'), 'ar'),
        _Option(S.get('language_de'), 'de'),
        _Option(S.get('language_fr'), 'fr'),
      ],
      current: LocalPreferencesService.language.value,
      onSelect: (val) {
        LocalPreferencesService.setLanguage(val);
        WidgetPayloadService.writeNextPrayerPayload();
        setState(() {});
      },
    );
  }

  void _showThemePicker() {
    _showOptionSheet(
      title: S.get('appearance'),
      options: [
        _Option(S.get('system'), 'system'),
        _Option(S.get('light'), 'light'),
        _Option(S.get('dark'), 'dark'),
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
