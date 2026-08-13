import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/models.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/date_field.dart';
import '../widgets/empty_state.dart';

/// Shared dialog for recording a wage payment (labour module only).
Future<bool> showRecordWagePaymentDialog(BuildContext context, Worker w) async {
  final app = context.read<AppProvider>();
  final amount = TextEditingController(
    text: w.dailyWageDefault > 0 ? w.dailyWageDefault.toStringAsFixed(0) : '',
  );
  var date = Formatters.todayIso();
  int? projectId =
      w.assignedProjectIds.isNotEmpty ? w.assignedProjectIds.first : null;
  final notes = TextEditingController();
  var saved = false;

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
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Amount *'),
              ),
              const SizedBox(height: 10),
              DateField(
                label: 'Date *',
                value: date,
                onChanged: (v) => setModal(() => date = v),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<int?>(
                // ignore: deprecated_member_use
                value: projectId,
                decoration: const InputDecoration(labelText: 'Project *'),
                items: [
                  ...app.projects.map(
                    (p) => DropdownMenuItem(value: p.id, child: Text(p.name)),
                  ),
                ],
                onChanged: (v) => setModal(() => projectId = v),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: notes,
                decoration:
                    const InputDecoration(labelText: 'Notes (optional)'),
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
              final value = double.tryParse(amount.text.trim()) ?? 0;
              if (value <= 0) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Enter a valid amount')),
                );
                return;
              }
              if (projectId == null) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Select a project')),
                );
                return;
              }
              await app.saveWagePayment(
                WagePayment(
                  workerId: w.id!,
                  amount: value,
                  date: date,
                  note: notes.text.trim(),
                  projectId: projectId,
                ),
              );
              saved = true;
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    ),
  );
  return saved;
}

class WorkerDetailScreen extends StatefulWidget {
  final Worker worker;
  final VoidCallback onEdit;

  const WorkerDetailScreen({
    super.key,
    required this.worker,
    required this.onEdit,
  });

  @override
  State<WorkerDetailScreen> createState() => _WorkerDetailScreenState();
}

class _WorkerDetailScreenState extends State<WorkerDetailScreen> {
  double _totalPaid = 0;

  Worker get w => widget.worker;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final total =
        await context.read<AppProvider>().repo.getWorkerTotalPaid(w.id!);
    if (!mounted) return;
    setState(() => _totalPaid = total);
  }

  @override
  Widget build(BuildContext context) {
    final currency = context.watch<AppProvider>().settings.currency;

    return Scaffold(
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
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
                          title: const Text('Mobile'),
                          subtitle: Text(w.phone.isEmpty ? '—' : w.phone),
                        ),
                        ListTile(
                          leading: const Icon(Icons.payments_outlined),
                          title: const Text('Daily Wage'),
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
                          title: const Text('Total Paid'),
                          subtitle: Text(
                            Formatters.money(_totalPaid, currency: currency),
                          ),
                        ),
                        ListTile(
                          leading: const Icon(Icons.calendar_today_outlined),
                          title: const Text('Joining Date'),
                          subtitle: Text(Formatters.dateDisplay(w.joiningDate)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.fact_check_outlined),
                      ),
                      title: const Text('Attendance History'),
                      subtitle: const Text(
                        "View this worker's daily attendance",
                      ),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                WorkerAttendanceHistoryScreen(worker: w),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.payments_outlined),
                      ),
                      title: const Text('Payment History'),
                      subtitle: const Text('Record and view wage payments'),
                      onTap: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                WorkerPaymentHistoryScreen(worker: w),
                          ),
                        );
                        await _load();
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: widget.onEdit,
                    child: const Text('Edit worker'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () async {
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
                      if (ok == true && context.mounted && w.id != null) {
                        await context.read<AppProvider>().removeWorker(w.id!);
                        if (context.mounted) Navigator.pop(context);
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                    ),
                    child: const Text('Delete worker'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class WorkerPaymentHistoryScreen extends StatefulWidget {
  final Worker worker;
  const WorkerPaymentHistoryScreen({super.key, required this.worker});

  @override
  State<WorkerPaymentHistoryScreen> createState() =>
      _WorkerPaymentHistoryScreenState();
}

class _WorkerPaymentHistoryScreenState
    extends State<WorkerPaymentHistoryScreen> {
  List<WagePayment> _payments = [];
  bool _loading = true;

  Worker get w => widget.worker;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list =
        await context.read<AppProvider>().repo.getWagePayments(workerId: w.id);
    if (!mounted) return;
    setState(() {
      _payments = list;
      _loading = false;
    });
  }

  Future<void> _record() async {
    final ok = await showRecordWagePaymentDialog(context, w);
    if (ok) await _load();
  }

  Future<void> _delete(WagePayment p) async {
    if (p.id == null) return;
    final currency = context.read<AppProvider>().settings.currency;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete payment?'),
        content: Text(
          '${Formatters.dateDisplay(p.date)} · ${Formatters.money(p.amount, currency: currency)}',
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
    if (ok == true && mounted) {
      await context.read<AppProvider>().removeWagePayment(p.id!);
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = context.watch<AppProvider>().settings.currency;
    final total = _payments.fold<double>(0, (a, b) => a + b.amount);

    return Scaffold(
      appBar: AppBar(title: Text(w.name)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _record,
        icon: const Icon(Icons.add),
        label: const Text('Record Payment'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              children: [
                Card(
                  color: AppColors.primaryBlue.withValues(alpha: 0.85),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: DefaultTextStyle(
                      style: const TextStyle(color: Colors.white),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Payment Summary',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Total Paid',
                                      style: TextStyle(
                                        color: Colors.white
                                            .withValues(alpha: 0.85),
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      Formatters.money(
                                        total,
                                        currency: currency,
                                      ),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 22,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Payments: ${_payments.length}',
                                      style: TextStyle(
                                        color: Colors.white
                                            .withValues(alpha: 0.85),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Daily Wage',
                                    style: TextStyle(
                                      color:
                                          Colors.white.withValues(alpha: 0.85),
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    Formatters.money(
                                      w.dailyWageDefault,
                                      currency: currency,
                                    ),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Payment Timeline',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 10),
                if (_payments.isEmpty)
                  const EmptyState(
                    message:
                        'No payments yet.\nTap Record Payment to add one.',
                    icon: Icons.payments_outlined,
                  )
                else
                  ..._payments.map((p) {
                    final project = (p.projectName ?? '').trim().isEmpty
                        ? 'No project'
                        : p.projectName!;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(
                          Formatters.dateDisplay(p.date),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(project),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              Formatters.money(p.amount, currency: currency),
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: AppColors.primaryBlue,
                              ),
                            ),
                            IconButton(
                              tooltip: 'Delete',
                              onPressed: () => _delete(p),
                              icon: const Icon(
                                Icons.delete_outline,
                                color: AppColors.warning,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
              ],
            ),
    );
  }
}

/// View-only attendance history — marking is done in Labour Overview.
class WorkerAttendanceHistoryScreen extends StatefulWidget {
  final Worker worker;
  const WorkerAttendanceHistoryScreen({super.key, required this.worker});

  @override
  State<WorkerAttendanceHistoryScreen> createState() =>
      _WorkerAttendanceHistoryScreenState();
}

class _WorkerAttendanceHistoryScreenState
    extends State<WorkerAttendanceHistoryScreen> {
  List<Attendance> _rows = [];
  bool _loading = true;

  Worker get w => widget.worker;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list =
        await context.read<AppProvider>().repo.getAttendance(workerId: w.id);
    if (!mounted) return;
    setState(() {
      _rows = list;
      _loading = false;
    });
  }

  Color _statusColor(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return AppColors.success;
      case AttendanceStatus.absent:
        return AppColors.danger;
      case AttendanceStatus.half:
        return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = _rows.length;
    final present =
        _rows.where((a) => a.status == AttendanceStatus.present).length;
    final absent =
        _rows.where((a) => a.status == AttendanceStatus.absent).length;
    final half = _rows.where((a) => a.status == AttendanceStatus.half).length;

    return Scaffold(
      appBar: AppBar(title: Text(w.name)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              children: [
                Card(
                  color: const Color(0xFF5C4033),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Attendance Summary',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _AttStat(
                              value: '$total',
                              label: 'Total',
                              color: AppColors.primaryBlue,
                            ),
                            _AttStat(
                              value: '$present',
                              label: 'Present',
                              color: const Color(0xFFFFCCBC),
                            ),
                            _AttStat(
                              value: '$absent',
                              label: 'Absent',
                              color: const Color(0xFFFFAB91),
                            ),
                            _AttStat(
                              value: '$half',
                              label: 'Half',
                              color: const Color(0xFFFFE082),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'History',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 10),
                if (_rows.isEmpty)
                  const EmptyState(
                    message:
                        'No attendance records yet.\nMark attendance from Labour Overview.',
                    icon: Icons.fact_check_outlined,
                  )
                else
                  ..._rows.map((a) {
                    final project = (a.projectName ?? '').trim().isEmpty
                        ? 'No project'
                        : a.projectName!;
                    final color = _statusColor(a.status);
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        title: Text(
                          Formatters.dateDisplay(a.date),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(project),
                        trailing: Text(
                          a.status.name.toUpperCase(),
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                    );
                  }),
              ],
            ),
    );
  }
}

class _AttStat extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _AttStat({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: color.withValues(alpha: 0.9),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
