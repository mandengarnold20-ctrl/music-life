import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/daily_verse.dart';

/// Encart « Verset du jour ».
class VerseCard extends StatelessWidget {
  const VerseCard({super.key, required this.verse});

  final DailyVerse verse;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 28, 20, 0),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: AppColors.accentGradient,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.menu_book_rounded, size: 20, color: AppColors.lilacPale),
              const SizedBox(width: 8),
              Text('VERSET DU JOUR', style: AppTheme.condensed(size: 18, color: AppColors.lilacPale).copyWith(letterSpacing: 3)),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            '« ${verse.text} »',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(height: 1.5, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          Text(verse.reference, style: const TextStyle(color: AppColors.mist, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
