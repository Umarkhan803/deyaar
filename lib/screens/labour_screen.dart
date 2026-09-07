import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/models.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/date_field.dart';
import '../widgets/empty_state.dart';
import '../widgets/form_actions.dart';
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
    final app = context.watch<AppProvider>();
    final currency = app.settings.currency;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Labour'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Workers'),
            Tab(text: 'Payroll'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_tabs.index == 0) {
            _workerForm(context);
          } else if (app.workers.isNotEmpty) {
            _recordPayment(context, app.workers.first);
          }
        },
        child: const Icon(Icons.add),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _WorkersTab(
            onOpen: (w) => _openWorkerDetail(context, w),
            onAdd: () => _workerForm(context),
          ),
          _PayrollTab(
            currency: currency,
            onPay: (w) => _recordPayment(context, w),
          ),
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
      text: worker == null ? '' : worker.dailyWageDefault.toString(),
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

    WageType _wageType = worker?.wageType ?? WageType.daily;

    if (!context.mounted) return;
    final contractAmountController = TextEditingController(
      text: worker == null ? '' : worker.contractAmount.toString(),
    );
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
                TextField(
                  controller: name,
                  decoration: const InputDecoration(labelText: 'Name *'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Number *'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: trade,
                  decoration: const InputDecoration(labelText: 'Trade *'),
                ),
                const SizedBox(height: 12),
                // Wage Type Dropdown
                DropdownButtonFormField<WageType>(
                  value: _wageType,
                  decoration: const InputDecoration(labelText: 'Wage Type'),
                  items: [
                    DropdownMenuItem(
                      value: WageType.daily,
                      child: Text(WageType.daily.label),
                    ),
                    DropdownMenuItem(
                      value: WageType.contract,
                      child: Text(WageType.contract.label),
                    ),
                  ],
                  onChanged: (WageType? value) {
                    if (value != null) {
                      setModal(() {
                        _wageType = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),
                ...(_wageType == WageType.contract
                    ? [
                        const SizedBox(height: 12),
                        TextField(
                          controller: contractAmountController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(labelText: 'Contract Amount'),
                        ),
                        const SizedBox(height: 12),
                      ]
                    : []),
                TextField(
                  controller: wage,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Daily wages *'),
                ),
                const SizedBox(height: 12),
                Text(
                  'Assign projects *',
                  style: Theme.of(
                    ctx,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
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
                    children: app.projects.map((p) {
                      final selected = selectedProjects.contains(p.id);
                      return FilterChip(
                        label: Text(p.name),
                        selected: selected,
                        onSelected: (v) => setModal(() {
                          if (v) {
                            selectedProjects.add(p.id!);
                          } else {
                            selectedProjects.remove(p.id);
                          }
                        }),
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 12),
                TextField(
                  controller: experience,
                  decoration: const InputDecoration(
                    labelText: 'Experience (optional)',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: address,
                  decoration: const InputDecoration(
                    labelText: 'Address (optional)',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notes,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Note (optional)',
                  ),
                ),
                const SizedBox(height: 12),
                DateField(
                  label: 'Joining date',
                  value: joining,
                  onChanged: (v) => setModal(() => joining = v),
                ),
                const SizedBox(height: 24),
                FormActions(
                  primaryLabel: 'Save Worker',
                  onCancel: () {
                    contractAmountController.dispose();
                    Navigator.pop(ctx);
                  },
                  onPrimary: () async {
                    if (name.text.trim().isEmpty ||
                        phone.text.trim().isEmpty ||
                        trade.text.trim().isEmpty ||
                        (double.tryParse(wage.text) ?? 0) <= 0) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Name, number, trade and daily wages are required',
                          ),
                        ),
                      );
                      contractAmountController.dispose();
                      return;
                    }
                    if (selectedProjects.isEmpty) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(
                          content: Text('Assign at least one project'),
                        ),
                      );
                      contractAmountController.dispose();
                      return;
                    }
                    await context.read<AppProvider>().saveWorker(
                      Worker(
                        id: worker?.id,
                        name: name.text.trim(),
                        phone: phone.text.trim(),
                        trade: trade.text.trim(),
                        dailyWageDefault: double.tryParse(wage.text) ?? 0,
                        experience: experience.text.trim(),
                        address: address.text.trim(),
                        notes: notes.text.trim(),
                        joiningDate: joining,
                        contractAmount: double.tryParse(contractAmountController.text) ?? 0,
                        wageType: _wageType,
                        assignedProjectIds: selectedProjects.toList(),
                      ),
                      projectIds: selectedProjects.toList(),
                    );
                    if (ctx.mounted) {
                      contractAmountController.dispose();
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
    contractAmountController.dispose();
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

  Future<void> _recordPayment(BuildContext context, Worker w) async {
    await showRecordWagePaymentDialog(context, w);
  }
}

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
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.danger),
            ),
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
      separatorBuilder: (_, _) => const SizedBox(height: 4),
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
                Text('${w.displayId} · ${w.trade.isEmpty ? 'Worker' : w.trade}'),
                if (w.wageType == WageType.contract) ...[
                  Text('${w.wageType.label}: ${Formatters.money(w.contractAmount, currency: currency)}'),
                  if (w.notes.isNotEmpty)
                    Text(w.notes, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: AppColors.textMuted(context))),
                ] else ...[
                  Text('${w.wageType.label}: ${Formatters.money(w.dailyWageDefault, currency: currency)}/day'),
                  if (w.notes.isNotEmpty)
                    Text(w.notes, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: AppColors.textMuted(context))),
                ],
              ],
            ),
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

class _PayrollTab extends StatelessWidget {
  final String currency;
  final void Function(Worker) onPay;
  const _PayrollTab({required this.currency, required this.onPay});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final paid = app.wagePayments.fold<double>(0, (a, b) => a + b.amount);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Payroll Management',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      const Text('TOTAL PENDING'),
                      Text(
                        Formatters.money(0, currency: currency),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      const Text('TOTAL PAID (MTD)'),
                      Text(
                        Formatters.money(paid, currency: currency),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Weekly Wages',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        if (app.workers.isEmpty)
          const EmptyState(
            message: 'No workers on payroll.',
            icon: Icons.payments_outlined,
          )
        else
          ...app.workers.map((w) {
            final workerPaid = app.wagePayments
                .where((p) => p.workerId == w.id)
                .fold<double>(0, (a, b) => a + b.amount);
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  child: Text(
                    w.name.isNotEmpty ? w.name[0].toUpperCase() : '?',
                  ),
                ),
                title: Text(
                  '${w.name} #${w.displayId.replaceFirst('EMP-', 'W-')}',
                ),
                subtitle: Text(w.trade.isEmpty ? 'Worker' : w.trade),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      Formatters.money(workerPaid, currency: currency),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    TextButton(
                      onPressed: () => onPay(w),
                      child: const Text('Paid'),
                    ),
                  ],
                ),
                isThreeLine: true,
              ),
            );
          }),
      ],
    );
  }
}

