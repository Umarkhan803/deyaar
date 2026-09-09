import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/models.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/app_header.dart';
import '../widgets/quick_action_tile.dart';
import 'clients_screen.dart';
import 'labour_screen.dart';
import 'projects_screen.dart';
import 'settings_screen.dart';
import 'site_photos_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning,';
    if (hour < 17) return 'Good afternoon,';
    return 'Good evening,';
  }

  List<Project> _upcomingDeadlines(List<Project> projects) {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    final withDates = projects.where((p) {
      if (p.expectedEnd.isEmpty) return false;
      if (p.status == ProjectStatus.completed) return false;
      final d = DateTime.tryParse(p.expectedEnd);
      return d != null;
    }).toList();
    withDates.sort((a, b) {
      final da = DateTime.parse(a.expectedEnd);
      final db = DateTime.parse(b.expectedEnd);
      return da.compareTo(db);
    });
    return withDates.where((p) {
      final d = DateTime.parse(p.expectedEnd);
      final end = DateTime(d.year, d.month, d.day);
      // Show overdue and upcoming (next 120 days).
      return !end.isAfter(start.add(const Duration(days: 120)));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final s = app.stats;
    final currency = app.settings.currency;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E252E) : AppColors.surface;
    final pendingBg = const Color(0xFFE53935);
    final deadlines = _upcomingDeadlines(app.projects);

    return RefreshIndicator(
      color: AppColors.primaryBlue,
      onRefresh: app.refreshAll,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 36),
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
          const SizedBox(height: 28),
          Text(
            _greeting(),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white70 : AppColors.slate,
            ),
          ),
          const SizedBox(height: 14),
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
                    MaterialPageRoute(builder: (_) => const SitePhotosScreen()),
                  ),
                  child: const SizedBox(
                    width: 44,
                    height: 44,
                    child: Icon(
                      Icons.apartment_outlined,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
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
          const SizedBox(height: 28),
          Text(
            'Quick Actions',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                QuickActionTile(
                  icon: Icons.add,
                  label: 'Project',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ProjectsScreen(openAdd: true),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                QuickActionTile(
                  icon: Icons.person_add_alt_1_outlined,
                  label: 'Client',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ClientsScreen(openAdd: true),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                QuickActionTile(
                  icon: Icons.engineering_outlined,
                  label: 'Labours',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const LabourScreen(openAdd: true),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                QuickActionTile(
                  label: 'Site',
                  icon: Icons.apartment_outlined,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SitePhotosScreen()),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Text(
                'Upcoming Deadlines',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => _addDeadline(context),
                child: const Text('Add'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (deadlines.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                border: isDark ? null : Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 36,
                    color: AppColors.textMuted(context),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'No upcoming deadlines. All caught up!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textMuted(context)),
                  ),
                ],
              ),
            )
          else
            ...deadlines.map((p) {
              final end = DateTime.parse(p.expectedEnd);
              final today = DateTime.now();
              final days = DateTime(
                end.year,
                end.month,
                end.day,
              ).difference(DateTime(today.year, today.month, today.day)).inDays;
              final overdue = days < 0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    leading: CircleAvatar(
                      backgroundColor: overdue
                          ? AppColors.dangerSoft
                          : AppColors.primaryBlue.withValues(alpha: 0.15),
                      child: Icon(
                        Icons.event_outlined,
                        color: overdue
                            ? AppColors.danger
                            : AppColors.primaryBlue,
                      ),
                    ),
                    title: Text(
                      p.name,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      overdue
                          ? 'Overdue · ${Formatters.dateDisplay(p.expectedEnd)}'
                          : days == 0
                          ? 'Due today · ${Formatters.dateDisplay(p.expectedEnd)}'
                          : 'Due in $days days · ${Formatters.dateDisplay(p.expectedEnd)}',
                    ),
                    trailing: IconButton(
                      tooltip: 'Remove deadline',
                      icon: const Icon(
                        Icons.delete_outline,
                        color: AppColors.danger,
                      ),
                      onPressed: () => _deleteDeadline(context, p),
                    ),
                    onTap: () => openProjectEditor(context, project: p),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Future<void> _deleteDeadline(BuildContext context, Project project) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove deadline?'),
        content: Text('Clear the expected end date for "${project.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    await context.read<AppProvider>().saveProject(
      project.copyWith(expectedEnd: ''),
    );
  }

  Future<void> _addDeadline(BuildContext context) async {
    final app = context.read<AppProvider>();
    final candidates = app.projects
        .where(
          (p) =>
              p.status != ProjectStatus.completed &&
              (p.expectedEnd.isEmpty ||
                  DateTime.tryParse(p.expectedEnd) == null),
        )
        .toList();
    if (candidates.isEmpty) {
      // Fall back to any non-completed project so user can update the date.
      final open = app.projects
          .where((p) => p.status != ProjectStatus.completed)
          .toList();
      if (open.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Create a project first')));
        return;
      }
      await openProjectEditor(context, project: open.first);
      return;
    }
    final selected = await showModalBottomSheet<Project>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Text(
                'Choose a project',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
            ),
            ...candidates.map(
              (p) => ListTile(
                title: Text(p.name),
                subtitle: Text(p.location.isEmpty ? p.displayId : p.location),
                onTap: () => Navigator.pop(ctx, p),
              ),
            ),
          ],
        ),
      ),
    );
    if (selected != null && context.mounted) {
      await openProjectEditor(context, project: selected);
    }
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
          padding: const EdgeInsets.all(16),
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
