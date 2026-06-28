import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/config/seasonal_config.dart';
import '../../core/ads/banner_ad_widget.dart';
import '../../data/adhan_notification_service.dart';
import '../../data/local_preferences_service.dart';
import '../../data/premium_service.dart';
import '../../data/user_profile_service.dart';
import '../../data/widget_payload_service.dart';
import '../../data/iftar_live_activity_service.dart';
import '../../l10n/app_strings.dart';
import '../../services/feedback_service.dart';
import '../../widgets/premium_experience_widgets.dart';
import '../notes/notes_screen.dart';
import 'premium_page.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, this.scrollController});

  final ScrollController? scrollController;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static final Uri _privacyPolicyUrl = Uri.parse(
    'https://duaya-app.web.app/privacy.html',
  );
  static final Uri _termsOfUseUrl = Uri.parse(
    'https://duaya-app.web.app/terms.html',
  );

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final surface = colorScheme.surface;
    return Material(
      color: surface,
      child: ListView(
        controller: widget.scrollController,
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              S.get('settings'),
              style: TextStyle(
                fontFamily: 'Merriweather',
                fontSize: 20,
                fontWeight: FontWeight.w400,
                color: colorScheme.onSurface,
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
          _buildRow(
            title: S.get('my_notes'),
            icon: Icons.note_alt_outlined,
            onTap: _openNotes,
          ),
          ValueListenableBuilder<bool>(
            valueListenable: PremiumService.isPremium,
            builder: (context, isPremium, _) {
              return Column(
                children: [
                  _buildRow(
                    title: S.get('premium_app_title'),
                    icon: Icons.workspace_premium_outlined,
                    value: isPremium ? S.get('premium_status_active') : null,
                    onTap: _openPremiumPage,
                  ),
                  if (isPremium) ...[
                    const SizedBox(height: 10),
                    PremiumActiveCard(
                      onTap: _openPremiumPage,
                      primaryActionLabel: S.get(
                        'premium_success_action_notifications',
                      ),
                      onPrimaryAction: _showDailyReminderTimePicker,
                    ),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 14),
          const SizedBox(height: 6),
          _buildRow(
            title: S.get('language'),
            icon: Icons.translate_rounded,
            value: _languageLabel(LocalPreferencesService.language.value),
            onTap: () => _showLanguagePicker(),
          ),
          ValueListenableBuilder<ThemeMode>(
            valueListenable: LocalPreferencesService.themeMode,
            builder: (context, mode, _) {
              return _buildRow(
                title: S.get('appearance'),
                icon: Icons.tune_rounded,
                value: _themeModeLabel(mode),
                onTap: () => _showThemePicker(),
              );
            },
          ),
          ValueListenableBuilder<bool>(
            valueListenable: LocalPreferencesService.minimalModeEnabled,
            builder: (context, enabled, _) {
              return _buildSwitchRow(
                title: S.get('minimal_mode'),
                value: enabled,
                onChanged: LocalPreferencesService.setMinimalModeEnabled,
              );
            },
          ),
          ValueListenableBuilder<bool>(
            valueListenable: LocalPreferencesService.adhanEnabled,
            builder: (context, enabled, _) {
              return _buildSwitchRow(
                title: S.get('prayer_time_notifications'),
                description: S.get('prayer_time_notifications_subtitle'),
                value: enabled,
                onChanged: _onTogglePrayerTimeNotifications,
              );
            },
          ),
          ValueListenableBuilder<bool>(
            valueListenable:
                LocalPreferencesService.spiritualNotificationsEnabled,
            builder: (context, enabled, _) {
              return _buildSwitchRow(
                title: S.get('daily_reminder'),
                description: S.get('daily_reminder_subtitle'),
                value: enabled,
                onChanged: _onToggleDailyReminder,
              );
            },
          ),
          ValueListenableBuilder<bool>(
            valueListenable:
                LocalPreferencesService.spiritualNotificationsEnabled,
            builder: (context, enabled, _) {
              if (!enabled) return const SizedBox.shrink();
              return ValueListenableBuilder<TimeOfDay>(
                valueListenable: LocalPreferencesService.dailyReminderTime,
                builder: (context, time, _) {
                  return _buildRow(
                    title: S.get('daily_reminder_time'),
                    icon: Icons.bedtime_outlined,
                    value: MaterialLocalizations.of(context)
                        .formatTimeOfDay(time, alwaysUse24HourFormat: true),
                    onTap: _showDailyReminderTimePicker,
                  );
                },
              );
            },
          ),
          ValueListenableBuilder<bool>(
            valueListenable: LocalPreferencesService.readingReminderEnabled,
            builder: (context, enabled, _) {
              return _buildSwitchRow(
                title: S.get('reading_reminder'),
                description: S.get('reading_reminder_subtitle'),
                value: enabled,
                onChanged: _onToggleReadingReminder,
              );
            },
          ),
          ValueListenableBuilder<bool>(
            valueListenable: LocalPreferencesService.readingReminderEnabled,
            builder: (context, enabled, _) {
              if (!enabled) return const SizedBox.shrink();
              return ValueListenableBuilder<TimeOfDay>(
                valueListenable: LocalPreferencesService.readingReminderTime,
                builder: (context, time, _) {
                  return _buildRow(
                    title: S.get('reading_reminder_time'),
                    icon: Icons.menu_book_outlined,
                    value: MaterialLocalizations.of(context)
                        .formatTimeOfDay(time, alwaysUse24HourFormat: true),
                    onTap: _showReadingReminderTimePicker,
                  );
                },
              );
            },
          ),
          if (SeasonalConfig.isRamadanSeason && !kIsWeb && Platform.isIOS)
            ValueListenableBuilder<bool>(
              valueListenable: IftarLiveActivityService.isSupported,
              builder: (context, isSupported, _) {
                if (!isSupported) return const SizedBox.shrink();
                return _buildSwitchRow(
                  title: S.get('iftar_countdown_toggle'),
                  value: LocalPreferencesService.iftarLiveActivityEnabled.value,
                  onChanged: _onToggleIftarCountdown,
                );
              },
            ),
          if (SeasonalConfig.isRamadanSeason && !kIsWeb && Platform.isIOS)
            ValueListenableBuilder<bool>(
              valueListenable: IftarLiveActivityService.isSupported,
              builder: (context, isSupported, _) {
                if (!isSupported) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 2, bottom: 8),
                  child: Text(
                    S.get('iftar_countdown_hint'),
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: colorScheme.onSurface.withValues(alpha: 0.62),
                      height: 1.35,
                    ),
                  ),
                );
              },
            ),
          const SizedBox(height: 24),
          _buildRow(
            title: S.get('send_feedback'),
            onTap: _showFeedbackSheet,
          ),
          _buildSectionTitle(S.get('legal')),
          _buildRow(
            title: S.get('privacy_policy'),
            onTap: () => _openExternalUrl(_privacyPolicyUrl),
          ),
          _buildRow(
            title: S.get('terms'),
            onTap: () => _openExternalUrl(_termsOfUseUrl),
          ),
          ValueListenableBuilder<bool>(
            valueListenable: PremiumService.isPremium,
            builder: (context, isPremium, _) {
              if (isPremium) {
                return const SizedBox.shrink();
              }
              return const BannerAdWidget();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, {IconData? icon}) {
    final mutedIconColor = Theme.of(context).colorScheme.tertiary;
    final sectionTextColor =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.72);
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 4),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: mutedIconColor),
            const SizedBox(width: 8),
          ],
          Text(
            title,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: sectionTextColor,
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
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final mutedIconColor = Theme.of(context).colorScheme.tertiary;
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
              Icon(icon, size: 17, color: mutedIconColor),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: onSurface,
                ),
              ),
            ),
            if (value != null)
              Text(
                value,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: onSurface.withValues(alpha: 0.74),
                ),
              ),
            const SizedBox(width: 4),
            Icon(
              chevron,
              size: 18,
              color: onSurface.withValues(alpha: 0.55),
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
    String? description,
  }) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: onSurface,
                  ),
                ),
                if (description != null && description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w400,
                      color: onSurface.withValues(alpha: 0.66),
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            height: 28,
            child: Switch.adaptive(
              value: value,
              onChanged: onChanged,
              activeTrackColor: Theme.of(context).colorScheme.primary,
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
      case 'en':
        return S.get('language_en');
      case 'tr':
        return S.get('language_tr');
      default:
        return S.get('language_en');
    }
  }

  String _themeModeLabel(ThemeMode mode) {
    return mode == ThemeMode.dark ? S.get('dark') : S.get('light');
  }

  void _openNotes() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const NotesScreen(),
      ),
    );
  }

  void _openPremiumPage() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const PremiumPage(),
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
      backgroundColor: Theme.of(context).colorScheme.surface,
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
                style: TextStyle(
                  fontFamily: 'Merriweather',
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                  color: Theme.of(ctx).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                textInputAction: TextInputAction.done,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: Theme.of(ctx).colorScheme.onSurface,
                ),
                decoration: InputDecoration(
                  hintText: S.get('name_hint'),
                  hintStyle: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Theme.of(ctx)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.62),
                  ),
                  filled: true,
                  fillColor: Theme.of(ctx).colorScheme.surfaceContainerHighest,
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
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Theme.of(ctx)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.72),
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
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.primary,
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
        _Option(S.get('light'), 'light'),
        _Option(S.get('dark'), 'dark'),
      ],
      current: switch (LocalPreferencesService.themeMode.value) {
        ThemeMode.dark => 'dark',
        ThemeMode.light => 'light',
        _ => 'light',
      },
      onSelect: (val) {
        final mode = switch (val) {
          'dark' => ThemeMode.dark,
          _ => ThemeMode.light,
        };
        LocalPreferencesService.setThemeMode(mode);
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
      backgroundColor: Theme.of(context).colorScheme.surface,
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
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(ctx)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.72),
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
                                color: Theme.of(ctx).colorScheme.onSurface,
                              ),
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              Icons.check_rounded,
                              size: 18,
                              color: Theme.of(context).colorScheme.primary,
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

  Future<void> _showIftarLiveActivityTip() async {
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                S.get('iftar_live_activity_tip_title'),
                style: TextStyle(
                  fontFamily: 'Merriweather',
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                  color: Theme.of(ctx).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                S.get('iftar_live_activity_tip_body'),
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Theme.of(ctx)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.72),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () async {
                    await Geolocator.openAppSettings();
                    if (ctx.mounted) Navigator.of(ctx).pop();
                  },
                  child: Text(S.get('open_ios_settings')),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(S.get('ok')),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _onToggleIftarCountdown(bool enabled) async {
    if (!enabled) {
      await LocalPreferencesService.setIftarLiveActivityEnabled(false);
      await IftarLiveActivityService.scheduleIftarNotifications();
      await IftarLiveActivityService.maybeStartOrUpdate();
      if (!mounted) return;
      setState(() {});
      return;
    }

    if (!LocalPreferencesService.iftarPermissionPromptShown.value) {
      await LocalPreferencesService.setIftarPermissionPromptShown(true);
      if (!mounted) return;
      await _showIftarLiveActivityTip();
    }

    final permissionGranted =
        await AdhanNotificationService.requestPermissions();
    if (!permissionGranted) {
      if (!mounted) return;
      await _showNotificationSoundSettingsCta();
      setState(() {});
      return;
    }

    await LocalPreferencesService.setIftarLiveActivityEnabled(true);
    await IftarLiveActivityService.scheduleIftarNotifications();
    await IftarLiveActivityService.maybeStartOrUpdate();
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _onTogglePrayerTimeNotifications(bool enabled) async {
    if (!enabled) {
      await LocalPreferencesService.setEzanAlarmSoundEnabled(false);
      await AdhanNotificationService.disable();
      if (!mounted) return;
      setState(() {});
      return;
    }

    await LocalPreferencesService.setEzanAlarmSoundEnabled(true);
    final result = await AdhanNotificationService.enable();
    switch (result) {
      case AdhanEnableResult.enabled:
        break;
      case AdhanEnableResult.notificationPermissionDenied:
        await LocalPreferencesService.setEzanAlarmSoundEnabled(false);
        if (!mounted) return;
        await _showNotificationSoundSettingsCta();
        break;
      case AdhanEnableResult.locationServiceDisabled:
      case AdhanEnableResult.locationPermissionDenied:
      case AdhanEnableResult.locationPermissionDeniedForever:
      case AdhanEnableResult.locationFailed:
      case AdhanEnableResult.locationMissing:
        await LocalPreferencesService.setEzanAlarmSoundEnabled(false);
        if (!mounted) return;
        await _showPrayerLocationSettingsCta();
        break;
      case AdhanEnableResult.unavailableOnWeb:
        await LocalPreferencesService.setEzanAlarmSoundEnabled(false);
        break;
    }

    if (!mounted) return;
    setState(() {});
  }

  Future<void> _onToggleDailyReminder(bool enabled) async {
    if (!enabled) {
      await LocalPreferencesService.setSpiritualNotificationsEnabled(false);
      await AdhanNotificationService.cancelScheduledSpiritualNotifications();
      await LocalPreferencesService.setNightCompanionReminderEnabled(false);
      await AdhanNotificationService.cancelNightCompanionReminder();
      if (!mounted) return;
      setState(() {});
      return;
    }

    final permissionGranted =
        await AdhanNotificationService.requestPermissions();
    if (!permissionGranted) {
      if (!mounted) return;
      await _showSpiritualNotificationPermissionCta();
      setState(() {});
      return;
    }

    await LocalPreferencesService.setSpiritualNotificationsEnabled(true);
    await LocalPreferencesService.setNightCompanionReminderEnabled(false);
    await AdhanNotificationService.cancelNightCompanionReminder();
    await AdhanNotificationService.syncSpiritualNotifications();
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _showDailyReminderTimePicker() async {
    final initialTime = LocalPreferencesService.dailyReminderTime.value;
    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        if (child == null) return const SizedBox.shrink();
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child,
        );
      },
    );
    if (picked == null) return;
    await LocalPreferencesService.setDailyReminderTime(picked);
    await AdhanNotificationService.cancelNightCompanionReminder();
    if (LocalPreferencesService.spiritualNotificationsEnabled.value) {
      await AdhanNotificationService.syncSpiritualNotifications();
    }
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _onToggleReadingReminder(bool enabled) async {
    if (!enabled) {
      await LocalPreferencesService.setReadingReminderEnabled(false);
      await AdhanNotificationService.cancelReadingReminder();
      if (!mounted) return;
      setState(() {});
      return;
    }

    final permissionGranted =
        await AdhanNotificationService.requestPermissions();
    if (!permissionGranted) {
      if (!mounted) return;
      await _showSpiritualNotificationPermissionCta();
      setState(() {});
      return;
    }

    await LocalPreferencesService.setReadingReminderEnabled(true);
    await AdhanNotificationService.syncReadingReminder();
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _showReadingReminderTimePicker() async {
    final initialTime = LocalPreferencesService.readingReminderTime.value;
    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        if (child == null) return const SizedBox.shrink();
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child,
        );
      },
    );
    if (picked == null) return;
    await LocalPreferencesService.setReadingReminderTime(picked);
    if (LocalPreferencesService.readingReminderEnabled.value) {
      await AdhanNotificationService.syncReadingReminder();
    }
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _showFeedbackSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final colorScheme = Theme.of(ctx).colorScheme;
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildFeedbackAction(
                context: ctx,
                title: S.get('feedback_email_action'),
                icon: Icons.mail_outline_rounded,
                onTap: () async {
                  Navigator.of(ctx).pop();
                  final result = await FeedbackService.composeFeedbackEmail();
                  if (!mounted || result == FeedbackLaunchResult.launched) {
                    return;
                  }
                  _showFeedbackFailure(S.get('feedback_email_failed'));
                },
              ),
              _buildFeedbackAction(
                context: ctx,
                title: S.get('feedback_rate_action'),
                icon: Icons.star_outline_rounded,
                onTap: () async {
                  Navigator.of(ctx).pop();
                  final result = await FeedbackService.requestRating();
                  if (!mounted || result == FeedbackLaunchResult.launched) {
                    return;
                  }
                  _showFeedbackFailure(S.get('feedback_review_failed'));
                },
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                style: TextButton.styleFrom(
                  foregroundColor:
                      colorScheme.onSurface.withValues(alpha: 0.76),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  S.get('cancel'),
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFeedbackAction({
    required BuildContext context,
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: colorScheme.onSurface.withValues(alpha: 0.42),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showFeedbackFailure(String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
          content: Text(
            message,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      );
  }

  Future<void> _showNotificationSoundSettingsCta() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                S.get('prayer_notif_permission_title'),
                style: TextStyle(
                  fontFamily: 'Merriweather',
                  fontSize: 19,
                  fontWeight: FontWeight.w400,
                  color: Theme.of(ctx).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                S.get('prayer_notif_permission_body'),
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: Theme.of(ctx)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.72),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () async {
                    await Geolocator.openAppSettings();
                    if (ctx.mounted) Navigator.of(ctx).pop();
                  },
                  child: Text(S.get('open_ios_settings')),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(S.get('ok')),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showPrayerLocationSettingsCta() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                S.get('prayer_location_needed_title'),
                style: TextStyle(
                  fontFamily: 'Merriweather',
                  fontSize: 19,
                  fontWeight: FontWeight.w400,
                  color: Theme.of(ctx).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                S.get('prayer_location_needed_body'),
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: Theme.of(ctx)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.72),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () async {
                    await Geolocator.openAppSettings();
                    if (ctx.mounted) Navigator.of(ctx).pop();
                  },
                  child: Text(S.get('prayer_notif_open_settings')),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(S.get('ok')),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showSpiritualNotificationPermissionCta() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                S.get('spiritual_notif_permission_title'),
                style: TextStyle(
                  fontFamily: 'Merriweather',
                  fontSize: 19,
                  fontWeight: FontWeight.w400,
                  color: Theme.of(ctx).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                S.get('spiritual_notif_permission_body'),
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: Theme.of(ctx)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.72),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () async {
                    await Geolocator.openAppSettings();
                    if (ctx.mounted) Navigator.of(ctx).pop();
                  },
                  child: Text(S.get('open_ios_settings')),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(S.get('ok')),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openExternalUrl(Uri uri) async {
    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (launched || !mounted) return;
    _showFeedbackFailure(S.get('link_open_failed'));
  }
}

class _Option {
  const _Option(this.label, this.value);
  final String label;
  final String value;
}
