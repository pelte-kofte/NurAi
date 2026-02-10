import 'package:flutter/material.dart';
import '../../data/collective_reading_service.dart';
import '../../models/reading_context.dart';
import '../reading/ayah_reading_screen.dart';

/// Screen for selecting a Juz intention for collective reading.
/// This is NOT a reading screen — Juz is a background intention only.
class CollectiveReadingScreen extends StatefulWidget {
  const CollectiveReadingScreen({super.key});

  @override
  State<CollectiveReadingScreen> createState() =>
      _CollectiveReadingScreenState();
}

class _CollectiveReadingScreenState extends State<CollectiveReadingScreen> {
  int? _selectedJuz;
  bool _isCompleted = false;
  bool _justSelected = false;

  @override
  void initState() {
    super.initState();
    _selectedJuz = CollectiveReadingService.getSelectedJuz();
    _isCompleted = CollectiveReadingService.isCompleted();
  }

  Future<void> _selectJuz(int juzNumber) async {
    await CollectiveReadingService.selectJuz(juzNumber);
    setState(() {
      _selectedJuz = juzNumber;
      _isCompleted = false;
      _justSelected = true;
    });
  }

  Future<void> _markCompleted() async {
    await CollectiveReadingService.markCompleted();
    setState(() {
      _isCompleted = true;
    });
  }

  Future<void> _clearSelection() async {
    await CollectiveReadingService.clearSelection();
    setState(() {
      _selectedJuz = null;
      _isCompleted = false;
      _justSelected = false;
    });
  }

  void _navigateToReading() {
    if (_selectedJuz == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AyahReadingScreen(
          surahNumber: 0, // unused in juz mode
          surahName: '',  // unused in juz mode
          readingContext: ReadingContext.juz(_selectedJuz!),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF6F2),
      appBar: AppBar(
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
        title: const Text(
          'Cüz Niyeti',
          style: TextStyle(
            fontFamily: 'Merriweather',
            fontSize: 20,
            fontWeight: FontWeight.w400,
            color: Color(0xFF2B2725),
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildExplanation(),
            const SizedBox(height: 32),
            if (_selectedJuz != null && !_isCompleted) ...[
              _buildActiveIntention(),
              const SizedBox(height: 16),
              _buildReadingBridge(),
              const SizedBox(height: 32),
            ] else if (_selectedJuz != null && _isCompleted) ...[
              _buildActiveIntention(),
              const SizedBox(height: 32),
            ],
            _buildJuzSelector(),
            const SizedBox(height: 24),
            _buildMicroCopy(),
          ],
        ),
      ),
    );
  }

  Widget _buildExplanation() {
    return const Text(
      'Bir cüz seçerek sessiz bir niyet edinebilirsiniz. '
      'Okumalarınız bu niyetle birlikte kaydedilir.',
      style: TextStyle(
        fontFamily: 'Merriweather',
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: Color(0xFF7A746F),
        height: 1.6,
      ),
    );
  }

  Widget _buildActiveIntention() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF4EFEA),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$_selectedJuz. Cüz',
            style: const TextStyle(
              fontFamily: 'Merriweather',
              fontSize: 18,
              fontWeight: FontWeight.w400,
              color: Color(0xFF2B2725),
            ),
          ),
          const SizedBox(height: 8),
          if (_isCompleted) ...[
            const Text(
              'Allah kabul etsin.',
              style: TextStyle(
                fontFamily: 'Merriweather',
                fontSize: 14,
                fontWeight: FontWeight.w400,
                fontStyle: FontStyle.italic,
                color: Color(0xFF7A746F),
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _clearSelection,
              child: const Text(
                'Yeni niyet',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF7A746F),
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ] else ...[
            if (_justSelected)
              const Text(
                'Niyet edildi.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF7A746F),
                ),
              ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _markCompleted,
              child: const Text(
                'Tamamladım',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF7A746F),
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReadingBridge() {
    return GestureDetector(
      onTap: _navigateToReading,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFFDF9F6),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFEDE6E1), width: 1),
        ),
        child: const Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Okumaya başla',
                    style: TextStyle(
                      fontFamily: 'Merriweather',
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF2B2725),
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Dilediğiniz yerden okuyabilirsiniz.\n'
                    'Bu cüz niyeti okumanıza sessizce eşlik eder.',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF7A746F),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: Color(0xFF7A746F),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJuzSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _selectedJuz == null ? 'Cüz Seçin' : 'Değiştir',
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFF7A746F),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: List.generate(30, (index) {
            final juzNumber = index + 1;
            final isSelected = _selectedJuz == juzNumber;
            return GestureDetector(
              onTap: () => _selectJuz(juzNumber),
              child: Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFE8E2DC)
                      : const Color(0xFFFDF9F6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$juzNumber',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                    color: isSelected
                        ? const Color(0xFF2B2725)
                        : const Color(0xFF7A746F),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildMicroCopy() {
    return const Text(
      'Dilediğiniz sureden okuyabilirsiniz.\n'
      'Niyetiniz, okumalarınıza sessizce eşlik eder.',
      style: TextStyle(
        fontFamily: 'Inter',
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: Color(0xFFB5AEA8),
        height: 1.5,
      ),
    );
  }
}
