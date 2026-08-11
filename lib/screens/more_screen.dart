import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/module_tile.dart';
import 'admin_screen.dart';
import 'labour_screen.dart';
import 'materials_screen.dart';
import 'payments_screen.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';
import 'site_overview_screen.dart';
import 'site_photos_screen.dart';
import 'suppliers_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      _MoreItem(
        'Admin',
        'Quotation and admin tools',
        Icons.admin_panel_settings_outlined,
        const AdminScreen(),
        AppColors.navy,
      ),
      _MoreItem(
        'Labour',
        'Workers and payroll',
        Icons.engineering_outlined,
        const LabourScreen(),
        AppColors.accentBlue,
      ),
      _MoreItem(
        'Materials',
        'Stock, purchases and usage',
        Icons.inventory_2_outlined,
        const MaterialsScreen(),
        AppColors.navy,
      ),
      _MoreItem(
        'Payments',
        'Money received and pending',
        Icons.account_balance_wallet_outlined,
        const PaymentsScreen(),
        AppColors.warning,
      ),
      _MoreItem(
        'Reports',
        'Usage, labour and quotation PDFs',
        Icons.assessment_outlined,
        const ReportsScreen(),
        AppColors.success,
      ),
      _MoreItem(
        'Site Photos',
        'Progress photos by project',
        Icons.photo_camera_outlined,
        const SitePhotosScreen(),
        AppColors.primaryBlue,
      ),
      _MoreItem(
        'Suppliers',
        'Vendor contacts for materials',
        Icons.local_shipping_outlined,
        const SuppliersScreen(),
        AppColors.cyan,
      ),
      _MoreItem(
        'Labour Overview',
        'Workers, attendance and payroll snapshot',
        Icons.groups_outlined,
        const LabourOverviewScreen(),
        AppColors.primaryBlue,
      ),
      _MoreItem(
        'Settings',
        'Security, theme, CSV import',
        Icons.settings_outlined,
        const SettingsScreen(),
        AppColors.slate,
      ),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      children: [
        Text(
          'All modules',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          'Admin, labour, materials, reports and settings',
          style: TextStyle(color: AppColors.textMuted(context)),
        ),
        const SizedBox(height: 20),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: ModuleTile(
              title: item.title,
              subtitle: item.subtitle,
              icon: item.icon,
              accent: item.accent,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => item.screen),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MoreItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget screen;
  final Color accent;
  const _MoreItem(this.title, this.subtitle, this.icon, this.screen, this.accent);
}
