import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/models.dart';
import '../providers/app_provider.dart';
import '../widgets/empty_state.dart';
import '../widgets/form_actions.dart';

class SuppliersScreen extends StatelessWidget {
  const SuppliersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Suppliers')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(context),
        child: const Icon(Icons.add),
      ),
      body: app.suppliers.isEmpty
          ? const EmptyState(
              message: 'No suppliers yet.',
              icon: Icons.local_shipping_outlined,
            )
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: app.suppliers.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final s = app.suppliers[i];
                return Card(
                  child: ListTile(
                    title: Text(
                      s.name,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      [
                        if (s.phone.isNotEmpty) s.phone,
                        if (s.notes.isNotEmpty) s.notes,
                      ].join(' · '),
                    ),
                    onTap: () => _openForm(context, supplier: s),
                    onLongPress: () async {
                      if (s.id != null) await app.removeSupplier(s.id!);
                    },
                  ),
                );
              },
            ),
    );
  }

  Future<void> _openForm(BuildContext context, {Supplier? supplier}) async {
    final name = TextEditingController(text: supplier?.name ?? '');
    final phone = TextEditingController(text: supplier?.phone ?? '');
    final notes = TextEditingController(text: supplier?.notes ?? '');

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => Scaffold(
          appBar: AppBar(
            title: Text(supplier == null ? 'Add Supplier' : 'Edit Supplier'),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Supplier name *'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notes,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Notes'),
              ),
              const SizedBox(height: 24),
              FormActions(
                primaryLabel: 'Save Supplier',
                onCancel: () => Navigator.pop(ctx),
                onPrimary: () async {
                  if (name.text.trim().isEmpty) return;
                  await context.read<AppProvider>().saveSupplier(
                    Supplier(
                      id: supplier?.id,
                      name: name.text.trim(),
                      phone: phone.text.trim(),
                      notes: notes.text.trim(),
                    ),
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
