import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/models.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/date_field.dart';
import 'transaction_photos_screen.dart';
import 'worker_attendance_history_screen.dart';
import 'worker_payment_history_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Record Payment dialog — shows contract balance hint for contract workers
// ─────────────────────────────────────────────────────────────────────────────
Future<bool> showRecordWagePaymentDialog(
  BuildContext context,
  Worker worker, {
  double? currentTotalPaid, // pass in so we can compute live balance
}) async {
  final app = context.read<AppProvider>();

  // If not passed in, fetch it now
  double alreadyPaid = currentTotalPaid ?? 0;
  if (currentTotalPaid == null) {
    alreadyPaid = await app.repo.getWorkerTotalPaid(worker.id!);
  }

  // Guard: context may be gone after the await above
  if (!context.mounted) return false;

  final amountCtrl = TextEditingController(
    text: worker.wageType == WageType.daily && worker.dailyWageDefault > 0
        ? worker.dailyWageDefault.toStringAsFixed(0)
        : '',
  );
  final noteCtrl = TextEditingController();
  var date = Formatters.todayIso();
  int? projectId = worker.assignedProjectIds.isNotEmpty
      ? worker.assignedProjectIds.first
      : null;
  var saved = false;

  await showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setDialogState) {
        // Live balance for contract workers
        final enteredAmount =
            double.tryParse(amountCtrl.text.trim()) ?? 0;
        final balance =
            worker.contractAmount - alreadyPaid - enteredAmount;

        return AlertDialog(
          title: Row(
            children: [
              const Expanded(child: Text('Record Payment')),
              if (worker.wageType == WageType.contract)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Contract',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.warning,
                    ),
                  ),
                ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Contract balance card
                if (worker.wageType == WageType.contract) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: balance < 0
                          ? AppColors.danger.withValues(alpha: 0.08)
                          : AppColors.success.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: balance < 0
                            ? AppColors.danger.withValues(alpha: 0.3)
                            : AppColors.success.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _BalanceRow(
                          label: 'Contract Amount',
                          value: Formatters.money(worker.contractAmount),
                        ),
                        _BalanceRow(
                          label: 'Paid So Far',
                          value: Formatters.money(alreadyPaid),
                          valueColor: AppColors.danger,
                        ),
                        if (enteredAmount > 0)
                          _BalanceRow(
                            label: 'This Payment',
                            value: '- ${Formatters.money(enteredAmount)}',
                            valueColor: AppColors.danger,
                          ),
                        const Divider(height: 10),
                        _BalanceRow(
                          label: 'Remaining Balance',
                          value: Formatters.money(balance.abs()),
                          valueColor: balance < 0
                              ? AppColors.danger
                              : AppColors.success,
                          bold: true,
                          prefix: balance < 0 ? 'Overpaid  ' : '',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                TextField(
                  controller: amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true),
                  decoration: const InputDecoration(labelText: 'Amount *'),
                  onChanged: (_) => setDialogState(() {}),
                ),
                const SizedBox(height: 10),
                DateField(
                  label: 'Date *',
                  value: date,
                  onChanged: (v) => setDialogState(() => date = v),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<int?>(
                  initialValue: projectId,
                  decoration:
                      const InputDecoration(labelText: 'Project *'),
                  items: app.projects
                      .map((proj) => DropdownMenuItem<int?>(
                            value: proj.id,
                            child: Text(proj.name),
                          ))
                      .toList(),
                  onChanged: (v) =>
                      setDialogState(() => projectId = v),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: noteCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                      labelText: 'Note (optional)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final value =
                    double.tryParse(amountCtrl.text.trim()) ?? 0;
                if (value <= 0 || projectId == null) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                        content: Text(
                            'Enter an amount and select a project')),
                  );
                  return;
                }
                await app.saveWagePayment(
                  WagePayment(
                    workerId: worker.id!,
                    amount: value,
                    date: date,
                    note: noteCtrl.text.trim(),
                    projectId: projectId,
                  ),
                );
                saved = true;
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    ),
  );
  return saved;
}

// ─────────────────────────────────────────────────────────────────────────────
// Small helper widget for the balance rows
// ─────────────────────────────────────────────────────────────────────────────
class _BalanceRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool bold;
  final String prefix;

  const _BalanceRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.bold = false,
    this.prefix = '',
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
              color: bold ? null : AppColors.textMuted(context),
            ),
          ),
          Text(
            '$prefix$value',
            style: TextStyle(
              fontSize: 12,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Transaction Photos — navigate to dedicated full screen (like site photos)
// ─────────────────────────────────────────────────────────────────────────────
void openTransactionPhotosScreen(BuildContext context, Worker worker) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => TransactionPhotosScreen(worker: worker),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// WorkerDetailScreen
// ─────────────────────────────────────────────────────────────────────────────
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

  Worker get worker => widget.worker;

  @override
  void initState() {
    super.initState();
    _loadTotalPaid();
  }

  Future<void> _loadTotalPaid() async {
    final total =
        await context.read<AppProvider>().repo.getWorkerTotalPaid(worker.id!);
    if (mounted) setState(() => _totalPaid = total);
  }

  Future<void> _recordPayment() async {
    if (await showRecordWagePaymentDialog(
      context,
      worker,
      currentTotalPaid: _totalPaid,
    )) {
      await _loadTotalPaid();
    }
  }

  Future<void> _deleteWorker() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete worker?'),
        content: Text(
          'Delete ${worker.name}? Attendance and wage payments for this worker will also be removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete',
                style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted && worker.id != null) {
      await context.read<AppProvider>().removeWorker(worker.id!);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = context.watch<AppProvider>().settings.currency;
    final isContract = worker.wageType == WageType.contract;
    final balance = worker.contractAmount - _totalPaid;

    return Scaffold(
      appBar: AppBar(title: Text(worker.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.phone),
                  title: const Text('Mobile'),
                  subtitle: Text(
                      worker.phone.isEmpty ? 'Not provided' : worker.phone),
                ),
                ListTile(
                  leading: const Icon(Icons.work_outline),
                  title: const Text('Trade'),
                  subtitle: Text(
                      worker.trade.isEmpty ? 'Worker' : worker.trade),
                ),
                // Wage type row
                ListTile(
                  leading: const Icon(Icons.category_outlined),
                  title: const Text('Wage Type'),
                  subtitle: Text(worker.wageType.label),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isContract
                          ? AppColors.warning.withValues(alpha: 0.15)
                          : AppColors.primaryBlue.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isContract ? 'CONTRACT' : 'DAILY',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isContract
                            ? AppColors.warning
                            : AppColors.primaryBlue,
                      ),
                    ),
                  ),
                ),
                if (isContract) ...[
                  // Contract amount
                  ListTile(
                    leading: const Icon(Icons.receipt_long_outlined),
                    title: const Text('Contract Amount'),
                    subtitle: Text(
                        Formatters.money(worker.contractAmount,
                            currency: currency)),
                  ),
                  // Total paid
                  ListTile(
                    leading: const Icon(Icons.account_balance_wallet_outlined),
                    title: const Text('Total Paid'),
                    subtitle: Text(
                        Formatters.money(_totalPaid, currency: currency)),
                  ),
                  // Balance
                  ListTile(
                    leading: Icon(
                      balance < 0
                          ? Icons.warning_amber_outlined
                          : Icons.savings_outlined,
                      color:
                          balance < 0 ? AppColors.danger : AppColors.success,
                    ),
                    title: Text(
                      balance < 0 ? 'Overpaid' : 'Remaining Balance',
                      style: TextStyle(
                        color: balance < 0
                            ? AppColors.danger
                            : AppColors.success,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Text(
                      Formatters.money(balance.abs(), currency: currency),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: balance < 0
                            ? AppColors.danger
                            : AppColors.success,
                      ),
                    ),
                  ),
                ] else ...[
                  // Daily wage worker
                  ListTile(
                    leading: const Icon(Icons.payments_outlined),
                    title: const Text('Daily Wage'),
                    subtitle: Text(Formatters.money(worker.dailyWageDefault,
                        currency: currency)),
                  ),
                  ListTile(
                    leading:
                        const Icon(Icons.account_balance_wallet_outlined),
                    title: const Text('Total Paid'),
                    subtitle: Text(
                        Formatters.money(_totalPaid, currency: currency)),
                  ),
                ],
                ListTile(
                  leading: const Icon(Icons.calendar_today_outlined),
                  title: const Text('Joining Date'),
                  subtitle: Text(Formatters.dateDisplay(worker.joiningDate)),
                ),
                if (worker.notes.isNotEmpty)
                  ListTile(
                    leading: const Icon(Icons.notes_outlined),
                    title: const Text('Note'),
                    subtitle: Text(worker.notes),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _recordPayment,
            icon: const Icon(Icons.add),
            label: const Text('Record Payment'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () =>
                openTransactionPhotosScreen(context, worker),
            icon: const Icon(Icons.photo_library_outlined),
            label: const Text('Transaction Photos'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: widget.onEdit,
            child: const Text('Edit worker'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    WorkerAttendanceHistoryScreen(worker: worker),
              ),
            ),
            icon: const Icon(Icons.calendar_month_outlined),
            label: const Text('Attendance History'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    WorkerPaymentHistoryScreen(worker: worker),
              ),
            ),
            icon: const Icon(Icons.payments_outlined),
            label: const Text('Payment History'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: _deleteWorker,
            style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger),
            child: const Text('Delete worker'),
          ),
        ],
      ),
    );
  }
}
