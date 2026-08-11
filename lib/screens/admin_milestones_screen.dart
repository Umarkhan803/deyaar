import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/models.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state.dart';

/// Admin milestone templates — appear on every project's milestone checklist.
class AdminMilestonesScreen extends StatefulWidget {
  const AdminMilestonesScreen({super.key});

  @override
  State<AdminMilestonesScreen> createState() => _AdminMilestonesScreenState();
}

class _AdminMilestonesScreenState extends State<AdminMilestonesScreen> {
  final _input = TextEditingController();

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    await context.read<AppProvider>().saveAdminMilestone(AdminMilestone(title: text));
    _input.clear();
    if (!mounted) return;
    FocusScope.of(context).unfocus();
  }

  Future<void> _edit(AdminMilestone m) async {
    final controller = TextEditingController(text: m.title);
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit milestone'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Milestone'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isEmpty) return;
              Navigator.pop(ctx, true);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (saved == true && mounted) {
      await context.read<AppProvider>().saveAdminMilestone(
            AdminMilestone(
              id: m.id,
              title: controller.text.trim(),
              sortOrder: m.sortOrder,
              createdAt: m.createdAt,
            ),
          );
    }
    controller.dispose();
  }

  Future<void> _delete(AdminMilestone m) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete milestone?'),
        content: Text(
          '"${m.title}" will be removed from admin and from unfinished project checklists.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (ok == true && m.id != null && mounted) {
      await context.read<AppProvider>().removeAdminMilestone(m.id!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = context.watch<AppProvider>().adminMilestones;

    return Scaffold(
      appBar: AppBar(title: const Text('Milestones')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: _input,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _add(),
                    decoration: const InputDecoration(
                      labelText: 'Milestone item',
                      hintText: 'e.g. Foundation, Roof…',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: ElevatedButton.icon(
                    onPressed: _add,
                    icon: const Icon(Icons.add),
                    label: const Text('Add'),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              'These items appear on every project’s milestone checklist.',
              style: TextStyle(color: Theme.of(context).hintColor, fontSize: 13),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: items.isEmpty
                ? const EmptyState(
                    message: 'No milestones yet. Add one above.',
                    icon: Icons.flag_outlined,
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final m = items[i];
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
                            m.title,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'Edit',
                                onPressed: () => _edit(m),
                                icon: const Icon(Icons.edit_outlined),
                              ),
                              IconButton(
                                tooltip: 'Delete',
                                onPressed: () => _delete(m),
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
