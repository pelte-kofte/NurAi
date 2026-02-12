import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../data/adhan_notification_service.dart';
import '../data/local_preferences_service.dart';

class QuickActionsPopover {
  QuickActionsPopover._();

  static OverlayEntry? _entry;
  static LocalHistoryEntry? _historyEntry;

  static bool get isShowing => _entry != null;

  static void toggle({
    required BuildContext context,
    required GlobalKey anchorKey,
    required VoidCallback onQibla,
    required VoidCallback onPermissionDenied,
  }) {
    if (isShowing) {
      hide();
      return;
    }

    _show(
      context: context,
      anchorKey: anchorKey,
      onQibla: onQibla,
      onPermissionDenied: onPermissionDenied,
    );
  }

  static void hide() {
    final historyEntry = _historyEntry;
    _historyEntry = null;
    historyEntry?.remove();

    _entry?.remove();
    _entry = null;
  }

  static void _show({
    required BuildContext context,
    required GlobalKey anchorKey,
    required VoidCallback onQibla,
    required VoidCallback onPermissionDenied,
  }) {
    final overlay = Overlay.of(context);
    final renderBox = anchorKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final route = ModalRoute.of(context);
    if (route != null) {
      _historyEntry = LocalHistoryEntry(
        onRemove: () {
          _entry?.remove();
          _entry = null;
          _historyEntry = null;
        },
      );
      route.addLocalHistoryEntry(_historyEntry!);
    }

    final anchorPos = renderBox.localToGlobal(Offset.zero);
    final anchorSize = renderBox.size;
    final screen = MediaQuery.of(context).size;

    const popoverWidth = 280.0;
    const popoverHeight = 170.0;
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
                onPermissionDenied: () {
                  hide();
                  onPermissionDenied();
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
    required this.onPermissionDenied,
  });

  final double width;
  final VoidCallback onQibla;
  final VoidCallback onPermissionDenied;

  @override
  State<_PopoverContent> createState() => _PopoverContentState();
}

class _PopoverContentState extends State<_PopoverContent> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF9F6),
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x142B2725),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: Text(
              'Hızlı İşlemler',
              style: TextStyle(
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
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.explore_rounded, size: 18, color: Color(0xFF7A746F)),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Kıble Bulucu',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF2B2725),
                      ),
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFFB5AEA8)),
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
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Ezan Bildirimleri',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF2B2725),
                    ),
                  ),
                ),
                CupertinoSwitch(
                  value: LocalPreferencesService.adhanEnabled.value,
                  onChanged: (value) async {
                    if (value) {
                      final granted = await AdhanNotificationService.requestPermissions();
                      if (!granted) {
                        widget.onPermissionDenied();
                        return;
                      }

                      await LocalPreferencesService.setAdhanEnabled(true);
                      await AdhanNotificationService.schedulePrayerNotifications();
                      setState(() {});
                      return;
                    }

                    await LocalPreferencesService.setAdhanEnabled(false);
                    await AdhanNotificationService.cancelAll();
                    setState(() {});
                  },
                  activeTrackColor: const Color(0xFFB57A5A),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
