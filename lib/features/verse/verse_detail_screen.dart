import 'package:flutter/material.dart';
import '../../l10n/app_strings.dart';

/// A calm, focused screen for reading and reflecting on a single ayah.
/// Designed to slow the user down and encourage contemplation.
class VerseDetailScreen extends StatelessWidget {
  const VerseDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF6F2),
      appBar: _buildAppBar(context),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              _buildArabicVerse(),
              const SizedBox(height: 28),
              _buildDivider(),
              const SizedBox(height: 28),
              _buildMeaning(context),
              const SizedBox(height: 16),
              _buildSurahReference(context),
              const SizedBox(height: 40),
              _buildReflectionCard(context),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  /// Minimal app bar with only a back button, no title, no elevation.
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
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
    );
  }

  /// Arabic verse displayed large, centered, with generous line height.
  Widget _buildArabicVerse() {
    return const Text(
      'إِنَّ مَعَ الْعُسْرِ يُسْرًا',
      textAlign: TextAlign.center,
      textDirection: TextDirection.rtl,
      style: TextStyle(
        fontFamily: 'Amiri',
        fontSize: 32,
        fontWeight: FontWeight.w400,
        color: Color(0xFF2B2725),
        height: 2.0,
      ),
    );
  }

  /// Subtle horizontal divider to separate Arabic from Turkish.
  Widget _buildDivider() {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 40),
      color: const Color(0xFFEDE6E1),
    );
  }

  /// Turkish meaning in serif font, slightly muted for calm reading.
  Widget _buildMeaning(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        AppStrings.t(context, 'verse_detail_meaning'),
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontFamily: 'Merriweather',
          fontSize: 18,
          fontWeight: FontWeight.w400,
          color: Color(0xFF2B2725),
          height: 1.7,
        ),
      ),
    );
  }

  /// Surah and verse reference, very subtle and unobtrusive.
  Widget _buildSurahReference(BuildContext context) {
    return Text(
      AppStrings.t(context, 'verse_detail_reference'),
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: Color(0xFF7A746F),
        letterSpacing: 0.3,
      ),
    );
  }

  /// Reflection prompt card inviting personal contemplation.
  Widget _buildReflectionCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF9F6),
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F2B2721),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.t(context, 'verse_detail_reflection_prompt'),
            style: const TextStyle(
              fontFamily: 'Merriweather',
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: Color(0xFF2B2725),
              height: 1.6,
            ),
          ),
          const SizedBox(height: 16),
          _buildReflectionButton(context),
        ],
      ),
    );
  }

  /// Subtle text button for leaving a note, non-demanding.
  Widget _buildReflectionButton(BuildContext context) {
    return TextButton(
      onPressed: () {},
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        AppStrings.t(context, 'verse_detail_leave_note'),
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Color(0xFFB57A5A),
          height: 1.4,
        ),
      ),
    );
  }
}
