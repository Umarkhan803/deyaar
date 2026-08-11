import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? accent;
  final Color? background;

  const StatTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.accent,
    this.background,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = accent ?? AppColors.primaryBlue;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: background ??
            (isDark ? AppColors.darkCard : Colors.white),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: isDark ? 0.22 : 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.text(context),
                ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted(context),
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }
}
