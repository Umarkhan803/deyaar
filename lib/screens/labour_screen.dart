import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/models.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/date_field.dart';
import '../widgets/empty_state.dart';
import '../widgets/form_actions.dart';
import 'daily_attendance_screen.dart';
import 'worker_history_screens.dart';

class LabourScreen extends StatefulWidget {
  final int initialTab;
  final bool openAdd;
  const LabourScreen({super.key, this.initialTab = 0, this.openAdd = false});

  @override
  State<LabourScreen> createState() => _LabourScreenState();
}

class _LabourScreenState extends State<LabourScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  bool _openedAdd = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 1),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_openedAdd && widget.openAdd) {
        _openedAdd = true;
        _workerForm(context);
      }
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Labour'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Workers'),
            Tab(text: 'Attendance'),
          ],
        ),
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _tabs,
        builder: (context, _) {
          // Only show FAB on Workers tab
          if (_tabs.index != 0) return const SizedBox.shrink();
          return FloatingActionButton(
            onPressed: () => _workerForm(context),
            child: const Icon(Icons.add),
          );
        },
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _WorkersTab(
            onOpen: (w) => _openWorkerDetail(context, w),
            onAdd: () => _workerForm(context),
          ),
          // Attendance tab — embedded (no back button / no outer AppHeader)
          const DailyAttendanceScreen(embedded: true),
        ],
      ),
    );
  }

  Future<void> _workerForm(BuildContext context, {Worker? worker}) async {
    final app = context.read<AppProvider>();

    final name = TextEditingController(text: worker?.name ?? '');
    final phone = TextEditingController(text: worker?.phone ?? '');
    final trade = TextEditingController(text: worker?.trade ?? '');
    final wage = TextEditingController(
      text: worker == null
          ? ''
          : (worker.dailyWageDefault > 0
              ? worker.dailyWageDefault.toString()
              : ''),
    );
    final contractAmountCtrl = TextEditingController(
      text: worker == null
          ? ''
          : (worker.contractAmount > 0
              ? worker.contractAmount.toString()
              : ''),
    );
    final experience = TextEditingController(text: worker?.experience ?? '');
    final address = TextEditingController(text: worker?.address ?? '');
    final notes = TextEditingController(text: worker?.notes ?? '');

    var joining = worker?.joiningDate.isNotEmpty == true
        ? worker!.joiningDate
        : Formatters.todayIso();

    final selectedProjects = <int>{
      ...?worker?.assignedProjectIds,
      if (worker?.id != null)
        ...await app.repo.getWorkerProjectIds(worker!.id!),
    };

    WageType wageType = worker?.wageType ?? WageType.daily;

    if (!context.mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => Scaffold(
          appBar: AppBar(
            title: Text(worker == null ? 'Add Worker' : 'Edit Worker'),
          ),
          body: StatefulBuilder(
            builder: (ctx, setModal) => ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ── Basic info ──────────────────────────────────────────
                TextField(
                  controller: name,
                  decoration: const InputDecoration(labelText: 'Name *'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Phone *'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: trade,
                  decoration: const InputDecoration(labelText: 'Trade *'),
                ),
                const SizedBox(height: 16),

                // ── Wage type selector ──────────────────────────────────
                Text(
                  'Wage Type *',
                  style: Theme.of(ctx).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _WageTypeChip(
                        label: 'Daily Wages',
                        icon: Icons.today_outlined,
                        selected: wageType == WageType.daily,
                        onTap: () => setModal(() => wageType = WageType.daily),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _WageTypeChip(
                        label: 'Contract',
                        icon: Icons.receipt_long_outlined,
                        selected: wageType == WageType.contract,
                        onTap: () =>
                            setModal(() => wageType = WageType.contract),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Conditional wage field ──────────────────────────────
                if (wageType == WageType.daily) ...[
                  TextField(
                    controller: wage,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Daily Wage *',
                      prefixIcon: Icon(Icons.today_outlined),
                      helperText: 'Amount paid per day present',
                    ),
                  ),
                ] else ...[
                  TextField(
                    controller: contractAmountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Contract Amount *',
                      prefixIcon: Icon(Icons.receipt_long_outlined),
                      helperText: 'Total agreed contract value',
                    ),
                  ),
                ],
                const SizedBox(height: 16),

                // ── Project assignment ──────────────────────────────────
                Text(
                  'Assign Projects *',
                  style: Theme.of(ctx).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Select one or more projects for this worker',
                  style: Theme.of(ctx).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                if (app.projects.isEmpty)
                  const Text(
                    'No projects yet. Create a project first.',
                    style: TextStyle(color: AppColors.danger),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: app.projects.map((proj) {
                      final selected = selectedProjects.contains(proj.id);
                      return FilterChip(
                        label: Text(proj.name),
                        selected: selected,
                        onSelected: (v) => setModal(() {
                          if (v) {
                            selectedProjects.add(proj.id!);
                          } else {
                            selectedProjects.remove(proj.id);
                          }
                        }),
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 16),

                // ── Optional fields ─────────────────────────────────────
                TextField(
                  controller: experience,
                  decoration: const InputDecoration(
                      labelText: 'Experience (optional)'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: address,
                  decoration:
                      const InputDecoration(labelText: 'Address (optional)'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notes,
                  maxLines: 3,
                  decoration:
                      const InputDecoration(labelText: 'Note (optional)'),
                ),
                const SizedBox(height: 12),
                DateField(
                  label: 'Joining date',
                  value: joining,
                  onChanged: (v) => setModal(() => joining = v),
                ),
                const SizedBox(height: 28),

                FormActions(
                  primaryLabel: 'Save Worker',
                  onCancel: () {
                    _disposeControllers([
                      contractAmountCtrl,
                      name, phone, trade, wage,
                      experience, address, notes,
                    ]);
                    Navigator.pop(ctx);
                  },
                  onPrimary: () async {
                    // Validation
                    if (name.text.trim().isEmpty ||
                        phone.text.trim().isEmpty ||
                        trade.text.trim().isEmpty) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(
                            content: Text('Name, phone and trade are required')),
                      );
                      return;
                    }
                    if (wageType == WageType.daily &&
                        (double.tryParse(wage.text) ?? 0) <= 0) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(
                            content: Text('Enter a valid daily wage')),
                      );
                      return;
                    }
                    if (wageType == WageType.contract &&
                        (double.tryParse(contractAmountCtrl.text) ?? 0) <= 0) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(
                            content: Text('Enter a valid contract amount')),
                      );
                      return;
                    }
                    if (selectedProjects.isEmpty) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(
                            content: Text('Assign at least one project')),
                      );
                      return;
                    }

                    await context.read<AppProvider>().saveWorker(
                          Worker(
                            id: worker?.id,
                            name: name.text.trim(),
                            phone: phone.text.trim(),
                            trade: trade.text.trim(),
                            // daily wage: 0 for contract workers
                            dailyWageDefault: wageType == WageType.daily
                                ? (double.tryParse(wage.text) ?? 0)
                                : 0,
                            // contract amount: 0 for daily workers
                            contractAmount: wageType == WageType.contract
                                ? (double.tryParse(contractAmountCtrl.text) ??
                                    0)
                                : 0,
                            wageType: wageType,
                            experience: experience.text.trim(),
                            address: address.text.trim(),
                            notes: notes.text.trim(),
                            joiningDate: joining,
                            assignedProjectIds: selectedProjects.toList(),
                          ),
                          projectIds: selectedProjects.toList(),
                        );

                    if (ctx.mounted) {
                      _disposeControllers([
                        contractAmountCtrl,
                        name, phone, trade, wage,
                        experience, address, notes,
                      ]);
                      Navigator.pop(ctx);
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
    // Safety dispose if back-button was used
    _disposeControllers([
      contractAmountCtrl,
      name, phone, trade, wage,
      experience, address, notes,
    ]);
  }

  void _disposeControllers(List<TextEditingController> ctrls) {
    for (final c in ctrls) {
      try {
        c.dispose();
      } catch (_) {}
    }
  }

  Future<void> _openWorkerDetail(BuildContext context, Worker w) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WorkerDetailScreen(
          worker: w,
          onEdit: () async {
            Navigator.pop(context);
            await _workerForm(context, worker: w);
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Wage type selection chip
// ─────────────────────────────────────────────────────────────────────────────
class _WageTypeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _WageTypeChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primaryBlue.withValues(alpha: 0.12)
              : Theme.of(context).cardColor,
          border: Border.all(
            color: selected
                ? AppColors.primaryBlue
                : AppColors.textMuted(context).withValues(alpha: 0.3),
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: selected
                  ? AppColors.primaryBlue
                  : AppColors.textMuted(context),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight:
                      selected ? FontWeight.w700 : FontWeight.w400,
                  color: selected
                      ? AppColors.primaryBlue
                      : AppColors.textMuted(context),
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Workers tab
// ─────────────────────────────────────────────────────────────────────────────
class _WorkersTab extends StatelessWidget {
  final void Function(Worker) onOpen;
  final VoidCallback onAdd;
  const _WorkersTab({required this.onOpen, required this.onAdd});

  Future<void> _confirmDelete(BuildContext context, Worker w) async {
    if (w.id == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete worker?'),
        content: Text(
          'Delete ${w.name}? Attendance and wage payments for this worker will also be removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete',
                style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await context.read<AppProvider>().removeWorker(w.id!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final currency = app.settings.currency;
    if (app.workers.isEmpty) {
      return EmptyState(
        message: 'No workers yet.',
        icon: Icons.engineering_outlined,
        actionLabel: 'Add worker',
        onAction: onAdd,
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      itemCount: app.workers.length,
      separatorBuilder: (_, __) => const SizedBox(height: 4),
      itemBuilder: (_, i) {
        final w = app.workers[i];
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.primaryBlue,
              child: Text(
                w.name.isNotEmpty ? w.name[0].toUpperCase() : '?',
                style: const TextStyle(color: Colors.white),
              ),
            ),
            title: Text(
              w.name,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    '${w.displayId} · ${w.trade.isEmpty ? 'Worker' : w.trade}'),
                if (w.wageType == WageType.contract) ...[
                  Text(
                    '${w.wageType.label}: ${Formatters.money(w.contractAmount, currency: currency)}',
                  ),
                ] else ...[
                  Text(
                    '${w.wageType.label}: ${Formatters.money(w.dailyWageDefault, currency: currency)}/day',
                  ),
                ],
                if (w.notes.isNotEmpty)
                  Text(
                    w.notes,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: AppColors.textMuted(context)),
                  ),
              ],
            ),
            isThreeLine: w.notes.isNotEmpty,
            trailing: IconButton(
              tooltip: 'Delete worker',
              onPressed: () => _confirmDelete(context, w),
              icon: const Icon(Icons.delete_outline, color: AppColors.danger),
            ),
            onTap: () => onOpen(w),
          ),
        );
      },
    );
  }
}
