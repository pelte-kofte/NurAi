import 'package:flutter/material.dart';

class DuasScreen extends StatelessWidget {
  const DuasScreen({super.key});

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
          'Kısa Dualar',
          style: TextStyle(
            fontFamily: 'Merriweather',
            fontSize: 20,
            fontWeight: FontWeight.w400,
            color: Color(0xFF2B2725),
          ),
        ),
      ),
      body: const Center(
        child: Text(
          'Yakında eklenecek',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Color(0xFF7A746F),
          ),
        ),
      ),
    );
  }
}
