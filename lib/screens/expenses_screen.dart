import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/models.dart';
import '../providers/app_provider.dart';
import '../utils/formatters.dart';
import '../widgets/date_field.dart';
import '../widgets/empty_state.dart';
import '../widgets/form_actions.dart';

class ExpensesScreen extends StatefulWidget {
  final bool openAdd;
  const ExpensesScreen({super.key, this.openAdd = false});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  bool _opened = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_opened && widget.openAdd) {
        _opened = true;
        _openForm(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final currency = app.settings.currency;

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(context),
        child: const Icon(Icons.add),
      ),
      body: app.expenses.isEmpty
          ? const EmptyState(
              message: 'No expenses recorded.',
              icon: Icons.receipt_long_outlined,
            )
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: app.expenses.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final e = app.expenses[i];
                return Card(
                  child: ListTile(
                    title: Text(
                      '${e.category.label} · ${Formatters.money(e.amount, currency: currency)}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      '${e.projectName ?? 'General'} · ${Formatters.dateDisplay(e.date)}'
                      '${e.note.isNotEmpty ? '\n${e.note}' : ''}',
                    ),
                    isThreeLine: e.note.isNotEmpty,
                    onTap: () => _openForm(context, expense: e),
                    onLongPress: () async {
                      if (e.id != null) await app.removeExpense(e.id!);
                    },
                  ),
                );
              },
            ),
    );
  }

  Future<void> _openForm(BuildContext context, {Expense? expense}) async {
    final app = context.read<AppProvider>();
    int? projectId = expense?.projectId;
    var category = expense?.category ?? ExpenseCategory.misc;
    var date = expense?.date ?? Formatters.todayIso();
    final amount = TextEditingController(
      text: expense == null ? '' : expense.amount.toString(),
    );
    final note = TextEditingController(text: expense?.note ?? '');

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => Scaffold(
          appBar: AppBar(
            title: Text(expense == null ? 'Add Expense' : 'Edit Expense'),
          ),
          body: StatefulBuilder(
            builder: (ctx, setModal) => ListView(
              padding: const EdgeInsets.all(16),
              children: [
                DropdownButtonFormField<int?>(
                  // ignore: deprecated_member_use
                  value: projectId,
                  decoration: const InputDecoration(labelText: 'Project'),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('General / no project'),
                    ),
                    ...app.projects.map(
                      (p) => DropdownMenuItem(value: p.id, child: Text(p.name)),
                    ),
                  ],
                  onChanged: (v) => setModal(() => projectId = v),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<ExpenseCategory>(
                  // ignore: deprecated_member_use
                  value: category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: ExpenseCategory.values
                      .map(
                        (c) => DropdownMenuItem(value: c, child: Text(c.label)),
                      )
                      .toList(),
                  onChanged: (v) => setModal(() => category = v ?? category),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amount,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Amount'),
                ),
                const SizedBox(height: 12),
                DateField(
                  label: 'Date',
                  value: date,
                  onChanged: (v) => setModal(() => date = v),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: note,
                  decoration: const InputDecoration(labelText: 'Note'),
                ),
                const SizedBox(height: 24),
                FormActions(
                  primaryLabel: 'Save Expense',
                  onCancel: () => Navigator.pop(ctx),
                  onPrimary: () async {
                    await app.saveExpense(
                      Expense(
                        id: expense?.id,
                        projectId: projectId,
                        category: category,
                        amount: double.tryParse(amount.text) ?? 0,
                        date: date,
                        note: note.text.trim(),
                      ),
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
}
