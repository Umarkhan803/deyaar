import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/models.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/date_field.dart';
import '../widgets/empty_state.dart';

class PaymentsScreen extends StatelessWidget {
  const PaymentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final currency = app.settings.currency;

    return Scaffold(
      appBar: AppBar(title: const Text('Payments')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(context),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          if (app.reminders.isNotEmpty)
            Container(
              width: double.infinity,
              color: AppColors.sky,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Text(
                '${app.reminders.length} payment reminder(s) due',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          Expanded(
            child: app.payments.isEmpty
                ? const EmptyState(
                    message: 'No payments recorded.',
                    icon: Icons.account_balance_wallet_outlined,
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: app.payments.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final p = app.payments[i];
                      return Card(
                        child: ListTile(
                          leading: Icon(
                            p.type == PaymentType.advance
                                ? Icons.trending_up
                                : Icons.receipt_long,
                            color: AppColors.navy,
                          ),
                          title: Text(
                            '${p.type.label} · ${Formatters.money(p.amount, currency: currency)}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            '${p.projectName ?? 'Project'} · ${Formatters.dateDisplay(p.date)}'
                            '${p.dueDate != null && p.dueDate!.isNotEmpty ? '\nReminder ${Formatters.dateDisplay(p.dueDate!)}' : ''}'
                            '${p.note.isNotEmpty ? '\n${p.note}' : ''}',
                          ),
                          isThreeLine: true,
                          onTap: () => _openForm(context, payment: p),
                          onLongPress: () async {
                            if (p.id != null) await app.removePayment(p.id!);
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _openForm(BuildContext context, {Payment? payment}) async {
    final app = context.read<AppProvider>();
    if (app.projects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a project first')),
      );
      return;
    }

    int projectId = payment?.projectId ?? app.projects.first.id!;
    var type = payment?.type ?? PaymentType.receipt;
    var date = payment?.date ?? Formatters.todayIso();
    var dueDate = payment?.dueDate ?? '';
    final amount = TextEditingController(
      text: payment == null ? '' : payment.amount.toString(),
    );
    final note = TextEditingController(text: payment?.note ?? '');

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 8,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  payment == null ? 'Add payment' : 'Edit payment',
                  style: Theme.of(ctx).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: projectId,
                  decoration: const InputDecoration(labelText: 'Project'),
                  items: app.projects
                      .map((p) => DropdownMenuItem(value: p.id, child: Text(p.name)))
                      .toList(),
                  onChanged: (v) => setModal(() => projectId = v ?? projectId),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<PaymentType>(
                  initialValue: type,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: PaymentType.values
                      .map((t) => DropdownMenuItem(value: t, child: Text(t.label)))
                      .toList(),
                  onChanged: (v) => setModal(() => type = v ?? type),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: amount,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Amount'),
                ),
                const SizedBox(height: 10),
                DateField(label: 'Date', value: date, onChanged: (v) => setModal(() => date = v)),
                const SizedBox(height: 10),
                DateField(
                  label: 'Reminder due date',
                  value: dueDate,
                  onChanged: (v) => setModal(() => dueDate = v),
                  optional: true,
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: note,
                  decoration: const InputDecoration(labelText: 'Note / receipt detail'),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    await app.savePayment(Payment(
                      id: payment?.id,
                      projectId: projectId,
                      type: type,
                      amount: double.tryParse(amount.text) ?? 0,
                      date: date,
                      note: note.text.trim(),
                      dueDate: dueDate.isEmpty ? null : dueDate,
                    ));
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('Save'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
