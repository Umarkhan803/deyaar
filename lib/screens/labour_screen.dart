import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/models.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/date_field.dart';
import '../widgets/empty_state.dart';
import '../widgets/form_actions.dart';

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
                  onCancel: () => Navigator.pop(ctx),
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
                      return;
                    }
                    if (selectedProjects.isEmpty) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(
                          content: Text('Assign at least one project'),
                        ),
                      );
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
                        assignedProjectIds: selectedProjects.toList(),
                      ),
                      projectIds: selectedProjects.toList(),
                    );
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openWorkerDetail(BuildContext context, Worker w) async {
    final totalPaid = await context.read<AppProvider>().repo.getWorkerTotalPaid(
      w.id!,
    );
    if (!context.mounted) return;
    final currency = context.read<AppProvider>().settings.currency;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 180,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    color: AppColors.primaryBlue.withValues(alpha: 0.25),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),
                        CircleAvatar(
                          radius: 36,
                          backgroundColor: AppColors.primaryBlue,
                          child: Text(
                            w.name.isNotEmpty ? w.name[0].toUpperCase() : '?',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          w.name,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(w.trade.isEmpty ? 'Worker' : w.trade),
                      ],
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Worker Information',
                        style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Card(
                        child: Column(
                          children: [
                            ListTile(
                              leading: const Icon(Icons.phone),
                              title: Text('Mobile'),
                              subtitle: Text(w.phone.isEmpty ? '—' : w.phone),
                            ),
                            ListTile(
                              leading: const Icon(Icons.payments_outlined),
                              title: Text('Daily Wage'),
                              subtitle: Text(
                                Formatters.money(
                                  w.dailyWageDefault,
                                  currency: currency,
                                ),
                              ),
                            ),
                            ListTile(
                              leading: const Icon(
                                Icons.account_balance_wallet_outlined,
                              ),
                              title: Text('Total Paid'),
                              subtitle: Text(
                                Formatters.money(totalPaid, currency: currency),
                              ),
                            ),
                            ListTile(
                              leading: const Icon(
                                Icons.calendar_today_outlined,
                              ),
                              title: Text('Joining Date'),
                              subtitle: Text(
                                Formatters.dateDisplay(w.joiningDate),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Card(
                        child: ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.payments_outlined),
                          ),
                          title: const Text('Payment History'),
                          subtitle: const Text(
                            'Record and view wage payments.',
                          ),
                          onTap: () => _recordPayment(ctx, w),
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _workerForm(context, worker: w);
                        },
                        child: const Text('Edit worker'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _recordPayment(BuildContext context, Worker w) async {
    final app = context.read<AppProvider>();
    final amount = TextEditingController(
      text: w.dailyWageDefault.toStringAsFixed(0),
    );
    var date = Formatters.todayIso();
    int? projectId;
    final notes = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => AlertDialog(
          title: const Text('Record Payment'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: amount,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Amount'),
                ),
                const SizedBox(height: 10),
                DateField(
                  label: 'Date',
                  value: date,
                  onChanged: (v) => setModal(() => date = v),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<int?>(
                  // ignore: deprecated_member_use
                  value: projectId,
                  decoration: const InputDecoration(
                    labelText: 'Project (optional)',
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Not linked to a project'),
                    ),
                    ...app.projects.map(
                      (p) => DropdownMenuItem(value: p.id, child: Text(p.name)),
                    ),
                  ],
                  onChanged: (v) => setModal(() => projectId = v),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: notes,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                await app.saveWagePayment(
                  WagePayment(
                    workerId: w.id!,
                    amount: double.tryParse(amount.text) ?? 0,
                    date: date,
                    note: notes.text.trim(),
                    projectId: projectId,
                  ),
                );
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkersTab extends StatelessWidget {
  final void Function(Worker) onOpen;
  final VoidCallback onAdd;
  const _WorkersTab({required this.onOpen, required this.onAdd});

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
            subtitle: Text(
              '${w.displayId} · ${w.trade.isEmpty ? 'Worker' : w.trade}\n${Formatters.money(w.dailyWageDefault, currency: currency)}/day',
            ),
            isThreeLine: true,
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
