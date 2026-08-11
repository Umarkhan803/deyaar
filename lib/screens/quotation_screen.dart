import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/models.dart';
import '../providers/app_provider.dart';
import '../services/pdf_report_service.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state.dart';
import 'reports_screen.dart';

/// Quotation list — todo-style add / edit / delete.
class QuotationScreen extends StatefulWidget {
  const QuotationScreen({super.key});

  @override
  State<QuotationScreen> createState() => _QuotationScreenState();
}

class _QuotationScreenState extends State<QuotationScreen> {
  final _input = TextEditingController();

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    await context.read<AppProvider>().saveQuotation(Quotation(title: text));
    _input.clear();
    if (!mounted) return;
    FocusScope.of(context).unfocus();
  }

  Future<void> _edit(Quotation q) async {
    final controller = TextEditingController(text: q.title);
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit quotation'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Quotation'),
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
      await context.read<AppProvider>().saveQuotation(
            Quotation(
              id: q.id,
              title: controller.text.trim(),
              createdAt: q.createdAt,
            ),
          );
    }
    controller.dispose();
  }

  Future<void> _delete(Quotation q) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete quotation?'),
        content: Text(q.title),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (ok == true && q.id != null && mounted) {
      await context.read<AppProvider>().removeQuotation(q.id!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = context.watch<AppProvider>().quotations;

    return Scaffold(
      appBar: AppBar(title: const Text('Quotation')),
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
                      labelText: 'Quotation item',
                      hintText: 'Type a quotation line…',
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
          const Divider(height: 1),
          Expanded(
            child: items.isEmpty
                ? const EmptyState(
                    message: 'No quotations yet. Add one above.',
                    icon: Icons.request_quote_outlined,
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final q = items[i];
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
                            q.title,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: q.createdAt.isEmpty ? null : Text(q.createdAt),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'Edit',
                                onPressed: () => _edit(q),
                                icon: const Icon(Icons.edit_outlined),
                              ),
                              IconButton(
                                tooltip: 'Delete',
                                onPressed: () => _delete(q),
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

/// Multi-select quotations and export PDF (merged with Cost of Construction).
class QuotationReportScreen extends StatefulWidget {
  const QuotationReportScreen({super.key});

  @override
  State<QuotationReportScreen> createState() => _QuotationReportScreenState();
}

class _QuotationReportScreenState extends State<QuotationReportScreen> {
  final Set<int> _selected = {};
  final _note = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final items = app.quotations;
    final costItems = app.costConstructionItems;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quotation Report'),
        actions: [
          if (items.isNotEmpty)
            TextButton(
              onPressed: () {
                setState(() {
                  if (_selected.length == items.length) {
                    _selected.clear();
                  } else {
                    _selected
                      ..clear()
                      ..addAll(items.where((q) => q.id != null).map((q) => q.id!));
                  }
                });
              },
              child: Text(
                _selected.length == items.length ? 'Clear' : 'Select all',
              ),
            ),
        ],
      ),
      body: items.isEmpty && costItems.isEmpty
          ? const EmptyState(
              message:
                  'Add quotations and cost lines under Admin before exporting.',
              icon: Icons.request_quote_outlined,
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              children: [
                Text(
                  'Select quotations',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Choose items to include in the PDF.',
                  style: TextStyle(color: AppColors.textMuted(context)),
                ),
                const SizedBox(height: 12),
                if (items.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No quotations yet. Add some under Admin → Quotation.'),
                    ),
                  )
                else
                  Card(
                    child: Column(
                      children: items.map((q) {
                        final id = q.id!;
                        final checked = _selected.contains(id);
                        return CheckboxListTile(
                          value: checked,
                          onChanged: (v) {
                            setState(() {
                              if (v == true) {
                                _selected.add(id);
                              } else {
                                _selected.remove(id);
                              }
                            });
                          },
                          title: Text(q.title),
                          subtitle:
                              q.createdAt.isEmpty ? null : Text(q.createdAt),
                          secondary: Icon(
                            checked
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                            color: checked
                                ? AppColors.primaryBlue
                                : AppColors.textMuted(context),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                if (costItems.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text(
                    'Cost of construction',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Preview from Admin → Cost of Construction (merged into PDF).',
                    style: TextStyle(color: AppColors.textMuted(context)),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Cost of construction:',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontStyle: FontStyle.italic,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                          const SizedBox(height: 10),
                          ...costItems.map((item) {
                            final line = item.value.trim().isEmpty
                                ? item.label
                                : '${item.label} = ${item.value}';
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                line,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Text(
                  'Note / description',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Optional text included at the end of the PDF.',
                  style: TextStyle(color: AppColors.textMuted(context)),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _note,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Note',
                    hintText:
                        'e.g. Duration for the construction of whole building will be 3 to 4 months…',
                    alignLabelWithHint: true,
                  ),
                ),
              ],
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: ElevatedButton.icon(
            onPressed: _busy || (_selected.isEmpty && costItems.isEmpty)
                ? null
                : _export,
            icon: const Icon(Icons.picture_as_pdf_outlined),
            label: Text(
              _busy
                  ? 'Exporting…'
                  : 'Export PDF${_selected.isEmpty ? '' : ' (${_selected.length})'}',
            ),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _export() async {
    setState(() => _busy = true);
    try {
      final app = context.read<AppProvider>();
      final selected = _selected.isEmpty
          ? <Quotation>[]
          : await app.repo.getQuotationsByIds(_selected.toList());
      final bytes = await PdfReportService(app.repo).buildQuotationReportBytes(
        companyName: app.settings.companyName,
        currency: app.settings.currency,
        quotations: selected,
        costItems: app.costConstructionItems,
        note: _note.text.trim(),
      );
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PdfPreviewScreen(
            bytes: bytes,
            title: 'Quotation Report',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

