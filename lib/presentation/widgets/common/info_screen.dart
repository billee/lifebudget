import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Reusable full-screen info page (Privacy, Terms, Tips, About, etc.)
class InfoScreen extends StatelessWidget {
  final String title;
  final String body;

  const InfoScreen({super.key, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: const TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Text(
          body,
          style: const TextStyle(
            fontSize: 15,
            height: 1.6,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
