import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class ProgressRing extends StatelessWidget {
  final double value;
  final double size;
  final String? centerLabel;
  final String? centerSub;
  final Color? color;

  const ProgressRing({
    super.key,
    required this.value,
    this.size = 88,
    this.centerLabel,
    this.centerSub,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final v = value.clamp(0, 100) / 100;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: v,
              strokeWidth: 8,
              backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.15),
              color: color ?? AppColors.primaryBlue,
              strokeCap: StrokeCap.round,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                centerLabel ?? '${value.round()}%',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              if (centerSub != null)
                Text(
                  centerSub!,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.muted,
                        fontWeight: FontWeight.w600,
                      ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
