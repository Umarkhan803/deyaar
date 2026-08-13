import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/models.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/empty_state.dart';
import '../widgets/progress_ring.dart';

class MaterialsScreen extends StatelessWidget {
  const MaterialsScreen({super.key});

  Future<void> _confirmDelete(BuildContext context, MaterialItem m) async {
    if (m.id == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete material?'),
        content: Text(m.displayName),
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
      await context.read<AppProvider>().removeMaterial(m.id!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final currency = app.settings.currency;

    return Scaffold(
      appBar: AppBar(title: const Text('Materials')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(context),
        child: const Icon(Icons.add),
      ),
      body: app.materials.isEmpty
          ? const EmptyState(
              message: 'No materials yet.',
              icon: Icons.inventory_2_outlined,
            )
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: app.materials.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final m = app.materials[i];
                final total = m.openingStock > 0
                    ? m.openingStock
                    : m.qtyPurchased;
                final usedPct = (total <= 0 ? 0.0 : (m.qtyUsed / total * 100))
                    .clamp(0.0, 100.0)
                    .toDouble();
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                m.displayName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                m.projectName ?? 'No project',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(height: 8),
                              Text('Used ${m.qtyUsed} / $total ${m.unit}'),
                              Text('Remaining: ${m.remaining}'),
                              Text(
                                'Cost: ${Formatters.money(m.cost, currency: currency)}',
                              ),
                              if (m.supplierName != null)
                                Text('Supplier: ${m.supplierName}'),
                            ],
                          ),
                        ),
                        Column(
                          children: [
                            ProgressRing(value: usedPct, size: 64),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: 'Edit',
                                  onPressed: () =>
                                      _openForm(context, item: m),
                                  icon: const Icon(Icons.edit_outlined),
                                ),
                                IconButton(
                                  tooltip: 'Delete',
                                  onPressed: () =>
                                      _confirmDelete(context, m),
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: AppColors.danger,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Future<void> _openForm(BuildContext context, {MaterialItem? item}) async {
    final app = context.read<AppProvider>();
    final name = TextEditingController(text: item?.name ?? '');
    final unit = TextEditingController(text: item?.unit ?? '');
    final opening = TextEditingController(
      text: item == null ? '0' : item.openingStock.toString(),
    );
    final low = TextEditingController(
      text: item == null ? '0' : item.lowStockAlert.toString(),
    );
    final price = TextEditingController(
      text: item == null ? '' : item.purchasePrice.toString(),
    );
    final used = TextEditingController(
      text: item == null ? '0' : item.qtyUsed.toString(),
    );
    final remarks = TextEditingController(text: item?.remarks ?? '');
    var type = item?.type ?? StockMaterial.cement;
    int? projectId =
        item?.projectId ??
        (app.projects.isNotEmpty ? app.projects.first.id : null);
    int? supplierId = item?.supplierId;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => Scaffold(
          appBar: AppBar(
            title: Text(item == null ? 'Add Material' : 'Edit Material'),
          ),
          body: StatefulBuilder(
            builder: (ctx, setModal) => ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextField(
                  controller: name,
                  decoration: const InputDecoration(labelText: 'Material name'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<StockMaterial>(
                  // ignore: deprecated_member_use
                  value: type,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: StockMaterial.values
                      .map(
                        (t) => DropdownMenuItem(value: t, child: Text(t.label)),
                      )
                      .toList(),
                  onChanged: (v) => setModal(() => type = v ?? type),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int?>(
                  // ignore: deprecated_member_use
                  value: projectId,
                  decoration: const InputDecoration(labelText: 'Project'),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('No project'),
                    ),
                    ...app.projects.map(
                      (p) => DropdownMenuItem(value: p.id, child: Text(p.name)),
                    ),
                  ],
                  onChanged: (v) => setModal(() => projectId = v),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: unit,
                  decoration: const InputDecoration(
                    labelText: 'Unit of measure',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: opening,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Opening stock',
                    helperText:
                        'Quantity on site before any entries were recorded. Enter 0 if none.',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: used,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Quantity used'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: low,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Low stock alert level',
                    helperText: 'Warn when stock drops to this level',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: price,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Purchase price per unit',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int?>(
                  // ignore: deprecated_member_use
                  value: supplierId,
                  decoration: const InputDecoration(
                    labelText: 'Supplier (optional)',
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('None')),
                    ...app.suppliers.map(
                      (s) => DropdownMenuItem(value: s.id, child: Text(s.name)),
                    ),
                  ],
                  onChanged: (v) => setModal(() => supplierId = v),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: remarks,
                  decoration: const InputDecoration(
                    labelText: 'Remarks (optional)',
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final openQty = double.tryParse(opening.text) ?? 0;
                      final unitPrice = double.tryParse(price.text) ?? 0;
                      await app.saveMaterial(
                        MaterialItem(
                          id: item?.id,
                          projectId: projectId,
                          type: type,
                          name: name.text.trim(),
                          unit: unit.text.trim(),
                          openingStock: openQty,
                          qtyPurchased: openQty,
                          qtyUsed: double.tryParse(used.text) ?? 0,
                          lowStockAlert: double.tryParse(low.text) ?? 0,
                          purchasePrice: unitPrice,
                          cost: openQty * unitPrice,
                          supplierId: supplierId,
                          remarks: remarks.text.trim(),
                        ),
                      );
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    child: Text(item == null ? 'Add Material' : 'Save'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
