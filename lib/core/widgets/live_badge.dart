import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Badge rouge « EN DIRECT » avec point clignotant.
class LiveBadge extends StatefulWidget {
  const LiveBadge({super.key, this.onTap, this.compact = false});

  final VoidCallback? onTap;
  final bool compact;

  @override
  State<LiveBadge> createState() => _LiveBadgeState();
}

class _LiveBadgeState extends State<LiveBadge> with SingleTickerProviderStateMixin {
  late final AnimationController _blink = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
    lowerBound: 0.25,
  )..repeat(reverse: true);

  @override
  void dispose() {
    _blink.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final badge = Container(
      padding: EdgeInsets.symmetric(horizontal: widget.compact ? 8 : 12, vertical: widget.compact ? 4 : 6),
      decoration: BoxDecoration(color: AppColors.live, borderRadius: BorderRadius.circular(4)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FadeTransition(
            opacity: _blink,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            ),
          ),
          const SizedBox(width: 6),
          Text('EN DIRECT', style: AppTheme.condensed(size: widget.compact ? 14 : 17).copyWith(letterSpacing: 2)),
        ],
      ),
    );

    if (widget.onTap == null) return badge;
    return Semantics(
      button: true,
      label: 'Regarder le direct',
      child: InkWell(onTap: widget.onTap, borderRadius: BorderRadius.circular(4), child: badge),
    );
  }
}
