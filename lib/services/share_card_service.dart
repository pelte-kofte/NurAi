import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

enum ShareCardType {
  ayah,
  hadith,
  quote,
  reminder,
  asma,
}

class ShareCardPayload {
  const ShareCardPayload({
    required this.title,
    required this.content,
    required this.type,
    this.reference,
    this.arabicText,
    this.localeCode,
  });

  final String title;
  final String content;
  final ShareCardType type;
  final String? reference;
  final String? arabicText;
  final String? localeCode;
}

class ShareCardService {
  ShareCardService._();

  static Future<void> shareDailyCard({
    required BuildContext context,
    ShareCardPayload? payload,
    String? title,
    String? content,
    ShareCardType? type,
    String? reference,
    String? arabicText,
    String? localeCode,
  }) async {
    final resolvedPayload = payload ??
        ShareCardPayload(
          title: title!,
          content: content!,
          type: type!,
          reference: reference,
          arabicText: arabicText,
          localeCode: localeCode,
        );

    final sharePositionOrigin = _shareOriginForContext(context);
    try {
      // Image-based share cards can be restored later after a full redesign.
      await Share.share(
        _buildShareText(resolvedPayload),
        subject: resolvedPayload.title,
        sharePositionOrigin: sharePositionOrigin,
      );
    } catch (error, stackTrace) {
      assert(() {
        debugPrint('ShareCardService.shareDailyCard failed: $error');
        debugPrintStack(
          label: 'ShareCardService.shareDailyCard stack trace',
          stackTrace: stackTrace,
        );
        return true;
      }());
      rethrow;
    }
  }

  static Rect _shareOriginForContext(BuildContext context) {
    final renderObject = context.findRenderObject();
    if (renderObject is RenderBox && renderObject.hasSize) {
      final offset = renderObject.localToGlobal(Offset.zero);
      return offset & renderObject.size;
    }
    return const Rect.fromLTWH(0, 0, 1, 1);
  }

  static String _buildShareText(ShareCardPayload payload) {
    final sections = <String>[
      _normalizeBlock(payload.title),
      _normalizeBlock(payload.arabicText),
      _normalizeBlock(payload.content),
      _normalizeBlock(payload.reference),
      _shareAttribution(payload.localeCode),
    ];
    return sections.where((section) => section.isNotEmpty).join('\n\n');
  }

  static String _normalizeBlock(String? value) {
    if (value == null) return '';
    return value
        .trim()
        .replaceAll(RegExp(r'\r\n?'), '\n')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n');
  }

  static String _shareAttribution(String? localeCode) {
    return localeCode?.toLowerCase() == 'tr'
        ? 'Duada ile paylaşıldı'
        : 'Shared via Duada';
  }
}
