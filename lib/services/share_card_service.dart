import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

import '../widgets/share_card_widget.dart';

class ShareCardService {
  ShareCardService._();

  static final ScreenshotController _controller = ScreenshotController();

  static Future<void> shareDailyCard({
    required BuildContext context,
    required ShareCardPayload payload,
  }) async {
    final sharePositionOrigin = _shareOriginForContext(context);
    try {
      final pngBytes = await _captureCard(
        context: context,
        payload: payload,
      );
      if (pngBytes.isEmpty) {
        throw StateError('Share card capture returned empty bytes.');
      }

      final file = await _writeTempFile(
        pngBytes,
        title: payload.title,
      );
      if (!await file.exists()) {
        throw StateError('Share card file was not created: ${file.path}');
      }

      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'image/png')],
        subject: payload.title,
        sharePositionOrigin: sharePositionOrigin,
      );
    } catch (error, stackTrace) {
      debugPrint('ShareCardService.shareDailyCard failed: $error');
      debugPrintStack(
        label: 'ShareCardService.shareDailyCard stack trace',
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  static Future<Uint8List> _captureCard({
    required BuildContext context,
    required ShareCardPayload payload,
  }) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    final card = MediaQuery(
      data: mediaQuery.copyWith(
        size: const Size(1080, 1350),
        devicePixelRatio: 1,
        textScaler: const TextScaler.linear(1),
      ),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Theme(
          data: theme,
          child: DefaultTextStyle(
            style: theme.textTheme.bodyMedium ?? const TextStyle(),
            child: Material(
              type: MaterialType.transparency,
              child: Center(
                child: ShareCardWidget(
                  payload: payload,
                  isDark: theme.brightness == Brightness.dark,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    return _controller.captureFromWidget(
      InheritedTheme.captureAll(context, card),
      pixelRatio: 1,
      delay: const Duration(milliseconds: 80),
    );
  }

  static Future<File> _writeTempFile(
    Uint8List bytes, {
    required String title,
  }) async {
    final directory = await getTemporaryDirectory();
    final safeTitle = _sanitizeFileName(title);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${directory.path}/duaya_${safeTitle}_$timestamp.png');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  static Rect _shareOriginForContext(BuildContext context) {
    final renderObject = context.findRenderObject();
    if (renderObject is RenderBox && renderObject.hasSize) {
      final offset = renderObject.localToGlobal(Offset.zero);
      return offset & renderObject.size;
    }
    return const Rect.fromLTWH(0, 0, 1, 1);
  }

  static String _sanitizeFileName(String title) {
    final normalized = title.toLowerCase().trim().replaceAll(' ', '_');
    return normalized.replaceAll(RegExp(r'[^a-z0-9_]+'), '').replaceAll(
          RegExp(r'_+'),
          '_',
        );
  }
}
