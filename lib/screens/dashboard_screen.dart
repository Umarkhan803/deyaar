import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/app_header.dart';
import 'projects_screen.dart';
import 'settings_screen.dart';
import 'site_overview_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning,';
    if (hour < 17) return 'Good afternoon,';
    return 'Good evening,';
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final s = app.stats;
    final currency = app.settings.currency;
    final net = s.profitLoss;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E252E) : AppColors.surface;
    final pendingBg = const Color(0xFFE53935);

    return RefreshIndicator(
      color: AppColors.primaryBlue,
      onRefresh: app.refreshAll,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          AppHeader(
            onSearch: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const ProjectsScreen(focusSearch: true),
              ),
            ),
            onSettings: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
          const SizedBox(height: 22),
          Text(
            _greeting(),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white70 : AppColors.slate,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                width: 4,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: isDark ? 0.9 : 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Dashboard Overview',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Material(
                color: AppColors.primaryBlue.withValues(alpha: 0.85),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const LabourOverviewScreen(),
                    ),
                  ),
                  child: const SizedBox(
                    width: 44,
                    height: 44,
                    child: Icon(Icons.groups_rounded, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 1.12,
            children: [
              _OverviewCard(
                background: cardBg,
                icon: Icons.architecture,
                iconBg: AppColors.primaryBlue,
                badge: 'ALL',
                value: '${s.totalProjects}',
                label: 'Total Projects',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ProjectsScreen()),
                ),
              ),
              _OverviewCard(
                background: cardBg,
                icon: Icons.bolt_rounded,
                iconBg: AppColors.primaryBlue,
                badge: 'IN HAND',
                value: '${s.ongoingProjects}',
                label: 'Ongoing',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ProjectsScreen()),
                ),
              ),
              _OverviewCard(
                background: cardBg,
                icon: Icons.verified_rounded,
                iconBg: AppColors.primaryBlue,
                value: '${s.completedProjects}',
                label: 'Completed',
              ),
              _OverviewCard(
                background: pendingBg,
                icon: Icons.payments_outlined,
                iconBg: Colors.white.withValues(alpha: 0.25),
                value: Formatters.money(s.pendingPayments, currency: currency),
                label: 'Pending',
                valueColor: Colors.white,
                labelColor: Colors.white.withValues(alpha: 0.9),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(20),
              border: isDark ? null : Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Financial Summary',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _FinanceColumn(
                        icon: Icons.arrow_upward_rounded,
                        value: Formatters.money(
                          s.totalReceived,
                          currency: currency,
                        ),
                        label: 'Revenue',
                      ),
                    ),
                    Expanded(
                      child: _FinanceColumn(
                        icon: Icons.arrow_downward_rounded,
                        value: Formatters.money(
                          s.totalExpenses,
                          currency: currency,
                        ),
                        label: 'Expenses',
                      ),
                    ),
                    Expanded(
                      child: _FinanceColumn(
                        icon: Icons.savings_outlined,
                        value: net >= 0
                            ? Formatters.money(net, currency: currency)
                            : '-${Formatters.money(net.abs(), currency: currency)}',
                        label: net >= 0 ? 'Net Profit' : 'Net Loss',
                        valueColor: net >= 0
                            ? AppColors.success
                            : const Color(0xFFFF8A80),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewCard extends StatelessWidget {
  final Color background;
  final IconData icon;
  final Color iconBg;
  final String? badge;
  final String value;
  final String label;
  final Color? valueColor;
  final Color? labelColor;
  final VoidCallback? onTap;

  const _OverviewCard({
    required this.background,
    required this.icon,
    required this.iconBg,
    this.badge,
    required this.value,
    required this.label,
    this.valueColor,
    this.labelColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: iconBg,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: Colors.white, size: 18),
                  ),
                  const Spacer(),
                  if (badge != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        badge!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                ],
              ),
              const Spacer(),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: valueColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color:
                      labelColor ??
                      (Theme.of(context).brightness == Brightness.dark
                          ? Colors.white70
                          : AppColors.slate),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FinanceColumn extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color? valueColor;

  const _FinanceColumn({
    required this.icon,
    required this.value,
    required this.label,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).brightness == Brightness.dark
        ? Colors.white70
        : AppColors.slate;
    return Column(
      children: [
        Icon(icon, size: 18, color: muted),
        const SizedBox(height: 8),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: valueColor,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: muted),
        ),
      ],
    );
  }
}
