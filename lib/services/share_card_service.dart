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
    final pngBytes = await _captureCard(
      context: context,
      payload: payload,
    );
    final file = await _writeTempFile(
      pngBytes,
      title: payload.title,
    );
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'image/png')],
      subject: payload.title,
    );
  }

  static Future<Uint8List> _captureCard({
    required BuildContext context,
    required ShareCardPayload payload,
  }) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    return _controller.captureFromWidget(
      MediaQuery(
        data: mediaQuery.copyWith(
          size: const Size(1080, 1350),
          devicePixelRatio: 1,
          textScaler: const TextScaler.linear(1),
        ),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Theme(
            data: theme,
            child: Center(
              child: ShareCardWidget(
                payload: payload,
                isDark: theme.brightness == Brightness.dark,
              ),
            ),
          ),
        ),
      ),
      pixelRatio: 1,
      delay: const Duration(milliseconds: 24),
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

  static String _sanitizeFileName(String title) {
    final normalized = title.toLowerCase().trim().replaceAll(' ', '_');
    return normalized.replaceAll(RegExp(r'[^a-z0-9_]+'), '').replaceAll(
          RegExp(r'_+'),
          '_',
        );
  }
}
