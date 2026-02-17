import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../data/adhan_notification_service.dart';
import '../data/local_preferences_service.dart';
import '../l10n/app_strings.dart';

class QuickActionsPopover {
  QuickActionsPopover._();

  static OverlayEntry? _entry;

  static bool get isShowing => _entry != null;

  static void toggle({
    required BuildContext context,
    required GlobalKey anchorKey,
    required VoidCallback onQibla,
    required VoidCallback onAdhanTimes,
    required VoidCallback onTasbih,
  }) {
    if (isShowing) {
      hide();
      return;
    }

    _show(
      context: context,
      anchorKey: anchorKey,
      onQibla: onQibla,
      onAdhanTimes: onAdhanTimes,
      onTasbih: onTasbih,
    );
  }

  static void hide() {
    _entry?.remove();
    _entry = null;
  }

  static void _show({
    required BuildContext context,
    required GlobalKey anchorKey,
    required VoidCallback onQibla,
    required VoidCallback onAdhanTimes,
    required VoidCallback onTasbih,
  }) {
    final overlay = Overlay.of(context, rootOverlay: true);
    final renderBox =
        anchorKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final anchorPos = renderBox.localToGlobal(Offset.zero);
    final anchorSize = renderBox.size;
    final screen = MediaQuery.of(context).size;

    const popoverWidth = 280.0;
    const popoverHeight = 270.0;
    const gap = 8.0;
    const edgePadding = 16.0;

    double left = anchorPos.dx;
    if (left + popoverWidth > screen.width - edgePadding) {
      left = screen.width - edgePadding - popoverWidth;
    }
    if (left < edgePadding) {
      left = edgePadding;
    }

    double top = anchorPos.dy + anchorSize.height + gap;
    if (top + popoverHeight > screen.height - edgePadding) {
      top = anchorPos.dy - popoverHeight - gap;
      if (top < edgePadding) {
        top = edgePadding;
      }
    }

    _entry = OverlayEntry(
      builder: (_) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: hide,
            ),
          ),
          Positioned(
            left: left,
            top: top,
            child: Material(
              color: Colors.transparent,
              child: _PopoverContent(
                width: popoverWidth,
                onQibla: () {
                  hide();
                  onQibla();
                },
                onAdhanTimes: () {
                  hide();
                  onAdhanTimes();
                },
                onTasbih: () {
                  hide();
                  onTasbih();
                },
              ),
            ),
          ),
        ],
      ),
    );

    overlay.insert(_entry!);
  }
}

class _PopoverContent extends StatefulWidget {
  const _PopoverContent({
    required this.width,
    required this.onQibla,
    required this.onAdhanTimes,
    required this.onTasbih,
  });

  final double width;
  final VoidCallback onQibla;
  final VoidCallback onAdhanTimes;
  final VoidCallback onTasbih;

  @override
  State<_PopoverContent> createState() => _PopoverContentState();
}

class _PopoverContentState extends State<_PopoverContent> {
  String? _statusText;

  Future<void> _onToggleAdhan(bool value) async {
    if (!value) {
      await AdhanNotificationService.disable();
      if (!mounted) return;
      setState(() {
        _statusText = null;
      });
      return;
    }

    final result = await AdhanNotificationService.enable();
    if (!mounted) return;
    switch (result) {
      case AdhanEnableResult.enabled:
        setState(() {
          _statusText = S.get('prayer_notif_scheduled');
        });
        break;
      case AdhanEnableResult.notificationPermissionDenied:
        await _showPermissionSheet(
          title: S.get('prayer_notif_permission_title'),
          body: S.get('prayer_notif_permission_body'),
          openSettingsLabel: S.get('prayer_notif_open_settings'),
          secondaryLabel: null,
          onSecondary: null,
        );
        break;
      case AdhanEnableResult.locationServiceDisabled:
      case AdhanEnableResult.locationPermissionDenied:
      case AdhanEnableResult.locationPermissionDeniedForever:
      case AdhanEnableResult.locationFailed:
      case AdhanEnableResult.locationMissing:
        await _showPermissionSheet(
          title: S.get('prayer_location_needed_title'),
          body: S.get('prayer_location_needed_body'),
          openSettingsLabel: S.get('prayer_notif_open_settings'),
          secondaryLabel: S.get('prayer_choose_city_instead'),
          onSecondary: () {
            Navigator.of(context).pop();
            QuickActionsPopover.hide();
            widget.onAdhanTimes();
          },
        );
        break;
      case AdhanEnableResult.unavailableOnWeb:
        setState(() {
          _statusText = S.get('location_unavailable_web');
        });
        break;
    }
    setState(() {});
  }

  Future<void> _showPermissionSheet({
    required String title,
    required String body,
    required String openSettingsLabel,
    required String? secondaryLabel,
    required VoidCallback? onSecondary,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      backgroundColor: const Color(0xFFFBF6F2),
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
                title,
                style: const TextStyle(
                  fontFamily: 'Merriweather',
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF2B2725),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                body,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF7A746F),
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
                  child: Text(openSettingsLabel),
                ),
              ),
              if (secondaryLabel != null && onSecondary != null) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: onSecondary,
                    child: Text(secondaryLabel),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x14000000)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              S.get('quick_actions'),
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF7A746F),
                letterSpacing: 0.6,
              ),
            ),
          ),
          GestureDetector(
            onTap: widget.onQibla,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.explore_rounded,
                      size: 18, color: Color(0xFF7BAEAC)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      S.get('qibla'),
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF2B2725),
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded,
                      size: 16, color: Color(0xFFB5AEA8)),
                ],
              ),
            ),
          ),
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(vertical: 2),
            color: const Color(0x1A000000),
          ),
          GestureDetector(
            onTap: widget.onAdhanTimes,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  const Icon(
                    Icons.schedule_rounded,
                    size: 18,
                    color: Color(0xFF7BAEAC),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      S.get('adhan_times'),
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF2B2725),
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: Color(0xFFB5AEA8),
                  ),
                ],
              ),
            ),
          ),
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(vertical: 6),
            color: const Color(0xFFEDE6E1),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: ValueListenableBuilder<bool>(
              valueListenable: LocalPreferencesService.adhanEnabled,
              builder: (context, enabled, _) => Row(
                children: [
                  Expanded(
                    child: Text(
                      S.get('adhan_alarms'),
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF2B2725),
                      ),
                    ),
                  ),
                  CupertinoSwitch(
                    value: enabled,
                    onChanged: _onToggleAdhan,
                    activeTrackColor: const Color(0xFFB57A5A),
                  ),
                ],
              ),
            ),
          ),
          if (_statusText != null) ...[
            const SizedBox(height: 4),
            Text(
              _statusText!,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: Color(0xFF7A746F),
              ),
            ),
          ],
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(vertical: 6),
            color: const Color(0xFFEDE6E1),
          ),
          GestureDetector(
            onTap: widget.onTasbih,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  const Icon(
                    Icons.touch_app_rounded,
                    size: 18,
                    color: Color(0xFF7BAEAC),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      S.get('tasbih'),
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF2B2725),
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: Color(0xFFB5AEA8),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
