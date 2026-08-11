import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/module_tile.dart';
import 'admin_milestones_screen.dart';
import 'cost_construction_screen.dart';
import 'quotation_screen.dart';

/// Admin hub — Quotation, Milestones, Cost of Construction.
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
                  color: AppColors.text(context),
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Manage quotations, milestones and cost templates',
            style: TextStyle(color: AppColors.textMuted(context)),
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
          const SizedBox(height: 10),
          ModuleTile(
            title: 'Cost of Construction',
            subtitle: 'Dynamic key/value lines merged into quotation PDF',
            icon: Icons.calculate_outlined,
            accent: AppColors.primaryBlue,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CostConstructionScreen()),
            ),
          ),
        ],
      ),
    );
  }
}
