import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../data/models/models.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/app_header.dart';
import 'materials_screen.dart';
import 'labour_screen.dart';
import 'daily_attendance_screen.dart';

/// Labour Overview — workers, attendance entry, and payroll snapshot.
class LabourOverviewScreen extends StatelessWidget {
  const LabourOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final currency = app.settings.currency;
    final today = Formatters.todayIso();
    final todayRecords = app.attendance.where((a) => a.date == today).toList();
    final present = todayRecords
        .where(
          (a) =>
              a.status == AttendanceStatus.present ||
              a.status == AttendanceStatus.half,
        )
        .length;
    final absent = todayRecords
        .where((a) => a.status == AttendanceStatus.absent)
        .length;
    final total = app.workers.length;
    final presentPct = total == 0 ? 0.0 : present / total;

    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final monthStart = DateTime(now.year, now.month, 1);
    final fmt = DateFormat('yyyy-MM-dd');

    return Scaffold(
      body: FutureBuilder<List<double>>(
        future: Future.wait([
          app.repo.wagesBetween(fmt.format(weekStart), today),
          app.repo.wagesBetween(fmt.format(monthStart), today),
        ]),
        builder: (context, snap) {
          final week = snap.data?[0] ?? 0;
          final month = snap.data?[1] ?? 0;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            children: [
              AppHeader(
                onBack: Navigator.of(context).canPop()
                    ? () => Navigator.pop(context)
                    : null,
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Labour Overview',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'DEYAAR CONSTRUCTIONS',
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                color: AppColors.textMuted(context),
                                letterSpacing: 0.6,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            const LabourScreen(initialTab: 0, openAdd: true),
                      ),
                    ),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Worker'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      title: 'Active Workers',
                      value: '$total',
                      subtitle: '$total total registered',
                      icon: Icons.groups_outlined,
                      iconColor: AppColors.primaryBlue,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatCard(
                      title: 'Present Today',
                      value: '$present',
                      subtitle: '${(presentPct * 100).round()}% of active force',
                      icon: Icons.person_outline,
                      iconColor: AppColors.primaryBlue,
                      progress: presentPct,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _StatCard(
                title: 'On Leave / Absent',
                value: '$absent',
                subtitle: absent == 0
                    ? 'All workers accounted for'
                    : '$absent marked absent today',
                icon: Icons.person_off_outlined,
                iconColor: AppColors.danger,
              ),
              const SizedBox(height: 20),
              Text(
                'Financial Overview',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _WageCard(
                      label: 'Wages This Week',
                      value: Formatters.money(week, currency: currency),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _WageCard(
                      label: 'Wages This Month',
                      value: Formatters.money(month, currency: currency),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 2.2,
                children: [
                  _ActionTile(
                    label: 'Attendance',
                    icon: Icons.fact_check_outlined,
                    highlighted: true,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const DailyAttendanceScreen(),
                      ),
                    ),
                  ),
                  _ActionTile(
                    label: 'Payroll',
                    icon: Icons.payments_outlined,
                    highlighted: false,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const LabourScreen(initialTab: 1),
                      ),
                    ),
                  ),
                  _ActionTile(
                    label: 'Workers',
                    icon: Icons.engineering_outlined,
                    highlighted: false,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const LabourScreen(initialTab: 0),
                      ),
                    ),
                  ),
                  _ActionTile(
                    label: 'Materials',
                    icon: Icons.inventory_2_outlined,
                    highlighted: false,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const MaterialsScreen(),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final double? progress;

  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMuted(context),
                        ),
                  ),
                ),
                CircleAvatar(
                  radius: 16,
                  backgroundColor: iconColor.withValues(alpha: 0.15),
                  child: Icon(icon, size: 18, color: iconColor),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted(context),
                  ),
            ),
            if (progress != null) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: progress!.clamp(0, 1),
                  minHeight: 6,
                  backgroundColor:
                      AppColors.primaryBlue.withValues(alpha: 0.12),
                  color: AppColors.primaryBlue,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _WageCard extends StatelessWidget {
  final String label;
  final String value;
  const _WageCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.textMuted(context),
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool highlighted;
  final VoidCallback onTap;

  const _ActionTile({
    required this.label,
    required this.icon,
    required this.highlighted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = highlighted ? AppColors.primaryBlue : Theme.of(context).cardColor;
    final fg = highlighted ? Colors.white : AppColors.text(context);
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: fg),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: fg,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
