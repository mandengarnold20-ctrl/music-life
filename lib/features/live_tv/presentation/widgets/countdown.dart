import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

/// Compte à rebours jusqu'au prochain direct (jours / heures / minutes / secondes).
class Countdown extends StatefulWidget {
  const Countdown({super.key, required this.target});

  final DateTime target;

  @override
  State<Countdown> createState() => _CountdownState();
}

class _CountdownState extends State<Countdown> {
  late Duration _left = _remaining();
  Timer? _timer;

  Duration _remaining() {
    final d = widget.target.difference(DateTime.now());
    return d.isNegative ? Duration.zero : d;
  }

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _left = _remaining());
      if (_left == Duration.zero) _timer?.cancel();
    });
  }

  @override
  void didUpdateWidget(Countdown old) {
    super.didUpdateWidget(old);
    if (old.target != widget.target) setState(() => _left = _remaining());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_left == Duration.zero) {
      return Text('Le direct va commencer…', style: AppTheme.condensed(size: 26));
    }
    final parts = <(String, int)>[
      ('JOURS', _left.inDays),
      ('HEURES', _left.inHours % 24),
      ('MIN', _left.inMinutes % 60),
      ('SEC', _left.inSeconds % 60),
    ];
    return Semantics(
      label: 'Prochain direct dans ${_left.inDays} jours, ${_left.inHours % 24} heures, ${_left.inMinutes % 60} minutes',
      excludeSemantics: true,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (final (label, value) in parts)
            Container(
              width: 70,
              margin: const EdgeInsets.symmetric(horizontal: 5),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.lilac.withValues(alpha: 0.35)),
              ),
              child: Column(
                children: [
                  Text(value.toString().padLeft(2, '0'), style: AppTheme.condensed(size: 34)),
                  const SizedBox(height: 4),
                  Text(label, style: const TextStyle(fontSize: 10, letterSpacing: 1.5, color: AppColors.mist)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
