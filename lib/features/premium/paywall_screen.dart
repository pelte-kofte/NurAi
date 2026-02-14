import 'package:flutter/material.dart';
import '../../data/premium_service.dart';
import '../../l10n/app_strings.dart';

class PaywallScreen extends StatelessWidget {
  const PaywallScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF6F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFBF6F2),
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          S.get('premium_title'),
          style: const TextStyle(
            fontFamily: 'Merriweather',
            fontSize: 20,
            fontWeight: FontWeight.w400,
            color: Color(0xFF2B2725),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 14, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _feature(S.get('premium_feature_ayah_notes')),
            _feature(S.get('premium_feature_notes_list')),
            _feature(S.get('premium_feature_sync_soon')),
            const SizedBox(height: 20),
            Text(
              S.get('premium_disclaimer'),
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: Color(0xFFB5AEA8),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              S.get('premium_local_notes_disclaimer'),
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: Color(0xFFB5AEA8),
              ),
            ),
            const Spacer(),
            if (PremiumService.isDebugUnlockAvailable) ...[
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () async {
                    await PremiumService.setPremiumDebug(true);
                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFF7BAEAC),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(S.get('premium_unlock')),
                ),
              ),
              const SizedBox(height: 8),
            ],
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () async {
                  await PremiumService.restorePurchasesStub();
                  if (!context.mounted) return;
                  await showDialog<void>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: const Color(0xFFFBF6F2),
                      content: Text(
                        S.get('premium_restore_not_available'),
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF7A746F),
                          height: 1.4,
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: Text(S.get('ok')),
                        ),
                      ],
                    ),
                  );
                },
                child: Text(
                  S.get('premium_restore'),
                  style: const TextStyle(color: Color(0xFF7A746F)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _feature(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 3),
            child: Icon(
              Icons.check_circle_outline_rounded,
              size: 16,
              color: Color(0xFF7BAEAC),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Color(0xFF2B2725),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
