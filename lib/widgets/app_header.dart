import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AppHeader extends StatelessWidget {
  final VoidCallback? onSearch;
  final VoidCallback? onSettings;
  final VoidCallback? onBack;
  final Widget? trailing;
  final bool showBrand;
  final String? title;

  const AppHeader({
    super.key,
    this.onSearch,
    this.onSettings,
    this.onBack,
    this.trailing,
    this.showBrand = true,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
      child: Row(
        children: [
          if (onBack != null)
            IconButton(onPressed: onBack, icon: const Icon(Icons.arrow_back)),
          if (showBrand) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/brand/logo.png',
                width: 36,
                height: 36,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    const Icon(Icons.apartment, color: AppColors.primaryBlue),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title ?? 'Deyaar Constructions',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Building Your Vision',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.primaryBlue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ] else
            Expanded(
              child: Text(
                title ?? '',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
          if (onSearch != null)
            IconButton(
              onPressed: onSearch,
              icon: const Icon(Icons.search, color: AppColors.primaryBlue),
            ),
          if (onSettings != null)
            IconButton(
              onPressed: onSettings,
              icon: const Icon(
                Icons.settings_outlined,
                color: AppColors.primaryBlue,
              ),
            ),
          ?trailing,
        ],
      ),
    );
  }
}
