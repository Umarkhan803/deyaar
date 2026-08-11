import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/models.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state.dart';

/// Admin Cost of Construction — dynamic key/value lines for quotation PDF.
/// Value may use placeholders: {area} {rate} {total} {duration} {project}
class CostConstructionScreen extends StatefulWidget {
  const CostConstructionScreen({super.key});

  @override
  State<CostConstructionScreen> createState() => _CostConstructionScreenState();
}

class _CostConstructionScreenState extends State<CostConstructionScreen> {
  final _label = TextEditingController();
  final _value = TextEditingController();

  @override
  void dispose() {
    _label.dispose();
    _value.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final label = _label.text.trim();
    if (label.isEmpty) return;
    await context.read<AppProvider>().saveCostConstructionItem(
          CostConstructionItem(label: label, value: _value.text.trim()),
        );
    _label.clear();
    _value.clear();
    if (!mounted) return;
    FocusScope.of(context).unfocus();
  }

  Future<void> _edit(CostConstructionItem item) async {
    final labelCtrl = TextEditingController(text: item.label);
    final valueCtrl = TextEditingController(text: item.value);
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit cost line'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: labelCtrl,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Key / label'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: valueCtrl,
              decoration: const InputDecoration(
                labelText: 'Value',
                hintText: 'e.g. 600 sft or Rs. 13,20,000/-',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              if (labelCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx, true);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (saved == true && mounted) {
      await context.read<AppProvider>().saveCostConstructionItem(
            CostConstructionItem(
              id: item.id,
              label: labelCtrl.text.trim(),
              value: valueCtrl.text.trim(),
              sortOrder: item.sortOrder,
              createdAt: item.createdAt,
            ),
          );
    }
    labelCtrl.dispose();
    valueCtrl.dispose();
  }

  Future<void> _delete(CostConstructionItem item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete cost line?'),
        content: Text(item.label),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (ok == true && item.id != null && mounted) {
      await context.read<AppProvider>().removeCostConstructionItem(item.id!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = context.watch<AppProvider>().costConstructionItems;

    return Scaffold(
      appBar: AppBar(title: const Text('Cost of Construction')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _label,
                  decoration: const InputDecoration(
                    labelText: 'Key / label',
                    hintText: 'e.g. Cost of Construction /sft',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _value,
                  decoration: const InputDecoration(
                    labelText: 'Value',
                    hintText: 'e.g. 600 sft · Rs. 2200/- · Rs. 13,20,000/-',
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: _add,
                    icon: const Icon(Icons.add),
                    label: const Text('Add'),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Key and value are shown as-is on Quotation Report and in the PDF '
                  '(e.g. “600 sft”, “Rs. 2200/-”).',
                  style: TextStyle(
                    color: Theme.of(context).hintColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: items.isEmpty
                ? const EmptyState(
                    message: 'No cost lines yet. Add key/value pairs above.',
                    icon: Icons.calculate_outlined,
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final item = items[i];
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                AppColors.primaryBlue.withValues(alpha: 0.15),
                            child: Text(
                              '${i + 1}',
                              style: const TextStyle(
                                color: AppColors.primaryBlue,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          title: Text(
                            item.label,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(
                            item.value.isEmpty ? '(no value)' : item.value,
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'Edit',
                                onPressed: () => _edit(item),
                                icon: const Icon(Icons.edit_outlined),
                              ),
                              IconButton(
                                tooltip: 'Delete',
                                onPressed: () => _delete(item),
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: AppColors.danger,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
