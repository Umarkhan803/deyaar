import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/module_tile.dart';
import 'admin_milestones_screen.dart';
import 'quotation_screen.dart';

/// Admin hub — Quotation, Milestones and future admin tools.
class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Text(
            'Admin',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Manage quotations, milestones and admin tools',
            style: TextStyle(color: Theme.of(context).hintColor),
          ),
          const SizedBox(height: 16),
          ModuleTile(
            title: 'Quotation',
            subtitle: 'Add, edit and manage quotation items',
            icon: Icons.request_quote_outlined,
            accent: AppColors.primaryBlue,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const QuotationScreen()),
            ),
          ),
          const SizedBox(height: 10),
          ModuleTile(
            title: 'Milestones',
            subtitle: 'Add items shown on every project milestone list',
            icon: Icons.flag_outlined,
            accent: AppColors.primaryBlue,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AdminMilestonesScreen()),
            ),
          ),
        ],
      ),
    );
  }
}
