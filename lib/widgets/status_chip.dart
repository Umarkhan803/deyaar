import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class StatusChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final Color? color;

  const StatusChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final bg = selected
        ? (color ?? AppColors.primaryBlue)
        : Theme.of(context).cardTheme.color;
    final fg = selected ? Colors.white : Theme.of(context).colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: selected,
        label: Text(label),
        onSelected: onTap == null ? null : (_) => onTap!(),
        selectedColor: bg,
        backgroundColor: Theme.of(context).cardTheme.color,
        labelStyle: TextStyle(
          color: selected ? Colors.white : fg,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        checkmarkColor: Colors.white,
        side: BorderSide(
          color: selected
              ? (color ?? AppColors.primaryBlue)
              : (Theme.of(context).dividerColor),
        ),
      ),
    );
  }
}

class BadgePill extends StatelessWidget {
  final String label;
  final Color? background;
  final Color? foreground;

  const BadgePill({
    super.key,
    required this.label,
    this.background,
    this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background ?? AppColors.primaryBlue.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: foreground ?? AppColors.primaryBlue,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
