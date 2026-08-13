import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../data/models/models.dart';
import '../providers/app_provider.dart';
import '../services/pdf_report_service.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/empty_state.dart';
import 'reports_screen.dart';

/// List of saved work-summary bills.
class BillsScreen extends StatelessWidget {
  const BillsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bills = context.watch<AppProvider>().bills;

    return Scaffold(
      appBar: AppBar(title: const Text('Bills')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const BillEditScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Create bill'),
      ),
      body: bills.isEmpty
          ? EmptyState(
              message: 'No bills yet.\nCreate a work summary bill to get started.',
              icon: Icons.receipt_long_outlined,
              actionLabel: 'Create bill',
              onAction: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const BillEditScreen()),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              itemCount: bills.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final bill = bills[index];
                final currency = context.read<AppProvider>().settings.currency;
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          AppColors.primaryBlue.withValues(alpha: 0.15),
                      child: const Icon(
                        Icons.receipt_long_outlined,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                    title: Text(
                      bill.name,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      [
                        if (bill.updatedAt.isNotEmpty) bill.updatedAt,
                        '${bill.items.length} item${bill.items.length == 1 ? '' : 's'}',
                        Formatters.money(bill.totalAmount, currency: currency),
                      ].join(' · '),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      if (bill.id == null) return;
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => BillReviewScreen(billId: bill.id!),
                        ),
                      );
                    },
                    onLongPress: () => _confirmDelete(context, bill),
                  ),
                );
              },
            ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Bill bill) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete bill?'),
        content: Text(bill.name),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (ok == true && bill.id != null && context.mounted) {
      await context.read<AppProvider>().removeBill(bill.id!);
    }
  }
}

/// Create / edit bill with dynamic line items.
class BillEditScreen extends StatefulWidget {
  final Bill? bill;
  const BillEditScreen({super.key, this.bill});

  @override
  State<BillEditScreen> createState() => _BillEditScreenState();
}

class _BillEditScreenState extends State<BillEditScreen> {
  late final TextEditingController _name;
  late final TextEditingController _note;
  late List<_LineEditors> _lines;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final bill = widget.bill;
    _name = TextEditingController(text: bill?.name ?? '');
    _note = TextEditingController(text: bill?.note ?? '');
    if (bill != null && bill.items.isNotEmpty) {
      _lines = bill.items.map(_LineEditors.fromItem).toList();
    } else {
      _lines = [_LineEditors()];
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _note.dispose();
    for (final line in _lines) {
      line.dispose();
    }
    super.dispose();
  }

  void _addLine() => setState(() => _lines.add(_LineEditors()));

  void _removeLine(int index) {
    if (_lines.length <= 1) return;
    setState(() {
      _lines[index].dispose();
      _lines.removeAt(index);
    });
  }

  double get _total =>
      _lines.fold<double>(0, (sum, line) => sum + line.amount);

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a bill name')),
      );
      return;
    }
    final items = <BillItem>[];
    for (var i = 0; i < _lines.length; i++) {
      final line = _lines[i];
      final desc = line.description.text.trim();
      if (desc.isEmpty && line.qty == 0 && line.rate == 0) continue;
      items.add(
        BillItem(
          description: desc.isEmpty ? 'Item ${i + 1}' : desc,
          unit: line.unit.text.trim(),
          qty: line.qty,
          rate: line.rate,
          sortOrder: i,
        ),
      );
    }
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one line item')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final existing = widget.bill;
      final id = await context.read<AppProvider>().saveBill(
            Bill(
              id: existing?.id,
              name: name,
              note: _note.text.trim(),
              createdAt: existing?.createdAt ?? '',
              items: items,
            ),
          );
      if (!mounted) return;
      if (existing != null) {
        Navigator.of(context).pop(id);
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => BillReviewScreen(billId: id)),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = context.watch<AppProvider>().settings.currency;
    final editing = widget.bill != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(editing ? 'Edit bill' : 'Create bill'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: Text(_saving ? 'Saving…' : 'Save'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
        children: [
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Bill name',
              hintText: 'e.g. Site A — Work Summary',
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Text(
                'Line items',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _addLine,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add row'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ..._lines.asMap().entries.map((entry) {
            final i = entry.key;
            final line = entry.value;
            return _LineItemCard(
              index: i,
              line: line,
              currency: currency,
              canRemove: _lines.length > 1,
              onChanged: () => setState(() {}),
              onRemove: () => _removeLine(i),
            );
          }),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Total: ${Formatters.money(_total, currency: currency)}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Note / duration',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Optional text shown at the end of the PDF (e.g. construction duration).',
            style: TextStyle(color: AppColors.textMuted(context)),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _note,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Note',
              hintText:
                  'Duration for the construction of whole building will be 3 to 4 months…',
              alignLabelWithHint: true,
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: ElevatedButton.icon(
            onPressed: _saving ? null : _save,
            icon: const Icon(Icons.save_outlined),
            label: Text(_saving ? 'Saving…' : 'Save & review'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
          ),
        ),
      ),
    );
  }
}

class _LineEditors {
  final description = TextEditingController();
  final unit = TextEditingController();
  final qtyCtrl = TextEditingController();
  final rateCtrl = TextEditingController();

  _LineEditors();

  factory _LineEditors.fromItem(BillItem item) {
    final e = _LineEditors();
    e.description.text = item.description;
    e.unit.text = item.unit;
    e.qtyCtrl.text = _numText(item.qty);
    e.rateCtrl.text = _numText(item.rate);
    return e;
  }

  static String _numText(double v) {
    if (v == 0) return '';
    if (v == v.roundToDouble()) return v.toStringAsFixed(0);
    return v.toString();
  }

  double get qty => double.tryParse(qtyCtrl.text.trim()) ?? 0;
  double get rate => double.tryParse(rateCtrl.text.trim()) ?? 0;
  double get amount => qty * rate;

  void dispose() {
    description.dispose();
    unit.dispose();
    qtyCtrl.dispose();
    rateCtrl.dispose();
  }
}

class _LineItemCard extends StatelessWidget {
  final int index;
  final _LineEditors line;
  final String currency;
  final bool canRemove;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  const _LineItemCard({
    required this.index,
    required this.line,
    required this.currency,
    required this.canRemove,
    required this.onChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: AppColors.navy.withValues(alpha: 0.1),
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.navy,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'SI ${index + 1}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                Text(
                  Formatters.money(line.amount, currency: currency),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                IconButton(
                  tooltip: 'Remove row',
                  onPressed: canRemove ? onRemove : null,
                  icon: Icon(
                    Icons.delete_outline,
                    color: canRemove
                        ? AppColors.danger
                        : AppColors.textMuted(context),
                  ),
                ),
              ],
            ),
            TextField(
              controller: line.description,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Description'),
              onChanged: (_) => onChanged(),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: line.unit,
                    decoration: const InputDecoration(
                      labelText: 'Unit',
                      hintText: 'Sq.ft',
                    ),
                    onChanged: (_) => onChanged(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: line.qtyCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    decoration: const InputDecoration(labelText: 'Qty'),
                    onChanged: (_) => onChanged(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: line.rateCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    decoration: const InputDecoration(labelText: 'Rate'),
                    onChanged: (_) => onChanged(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Review saved bill and export PDF.
class BillReviewScreen extends StatefulWidget {
  final int billId;
  const BillReviewScreen({super.key, required this.billId});

  @override
  State<BillReviewScreen> createState() => _BillReviewScreenState();
}

class _BillReviewScreenState extends State<BillReviewScreen> {
  Bill? _bill;
  bool _loading = true;
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final bill = await context.read<AppProvider>().getBill(widget.billId);
    if (!mounted) return;
    setState(() {
      _bill = bill;
      _loading = false;
    });
  }

  Future<void> _export() async {
    final bill = _bill;
    if (bill == null) return;
    setState(() => _exporting = true);
    try {
      final app = context.read<AppProvider>();
      final bytes = await PdfReportService(app.repo).buildBillReportBytes(
        companyName: app.settings.companyName,
        currency: app.settings.currency,
        bill: bill,
      );
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PdfPreviewScreen(
            bytes: bytes,
            title: bill.name,
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = context.watch<AppProvider>().settings.currency;
    final bill = _bill;

    return Scaffold(
      appBar: AppBar(
        title: Text(bill?.name ?? 'Bill review'),
        actions: [
          if (bill != null)
            IconButton(
              tooltip: 'Edit',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => BillEditScreen(bill: bill),
                  ),
                );
                await _load();
              },
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : bill == null
              ? const EmptyState(
                  message: 'Bill not found.',
                  icon: Icons.error_outline,
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                  children: [
                    Text(
                      'Work Summary',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 12),
                    _WorkSummaryTable(bill: bill, currency: currency),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        'Total: ${Formatters.money(bill.totalAmount, currency: currency)}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                    if (bill.note.trim().isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Text(
                        'Note',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        bill.note.trim(),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
      bottomNavigationBar: bill == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: ElevatedButton.icon(
                  onPressed: _exporting ? null : _export,
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  label: Text(_exporting ? 'Exporting…' : 'Export PDF'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                ),
              ),
            ),
    );
  }
}

class _WorkSummaryTable extends StatelessWidget {
  final Bill bill;
  final String currency;

  const _WorkSummaryTable({required this.bill, required this.currency});

  static const _headerBg = Color(0xFFE8F5E9);
  static const _border = Color(0xFFCCCCCC);
  static const _headerFg = Color(0xFF1B5E20);
  static const _cellFg = Color(0xFF212121);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cellFg = isDark ? Colors.white : _cellFg;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Table(
        border: TableBorder.all(color: _border, width: 0.8),
        defaultColumnWidth: const IntrinsicColumnWidth(),
        columnWidths: const {
          0: FixedColumnWidth(40),
          1: FixedColumnWidth(160),
          2: FixedColumnWidth(64),
          3: FixedColumnWidth(56),
          4: FixedColumnWidth(88),
          5: FixedColumnWidth(100),
        },
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: [
          TableRow(
            decoration: const BoxDecoration(color: _headerBg),
            children: [
              _h('SI'),
              _h('Description', align: TextAlign.left),
              _h('Unit'),
              _h('Qty'),
              _h('Rate'),
              _h('Amount'),
            ],
          ),
          if (bill.items.isEmpty)
            TableRow(
              children: [
                _c('—', color: cellFg),
                _c('No line items', align: TextAlign.left, color: cellFg),
                _c('', color: cellFg),
                _c('', color: cellFg),
                _c('', color: cellFg),
                _c('', color: cellFg),
              ],
            )
          else
            ...bill.items.asMap().entries.map((e) {
              final item = e.value;
              return TableRow(
                children: [
                  _c('${e.key + 1}', color: cellFg),
                  _c(item.description, align: TextAlign.left, color: cellFg),
                  _c(item.unit, color: cellFg),
                  _c(_fmt(item.qty), color: cellFg),
                  _c(
                    Formatters.money(item.rate, currency: currency),
                    align: TextAlign.right,
                    color: cellFg,
                  ),
                  _c(
                    Formatters.money(item.amount, currency: currency),
                    align: TextAlign.right,
                    color: cellFg,
                  ),
                ],
              );
            }),
        ],
      ),
    );
  }

  static String _fmt(double v) {
    if (v == v.roundToDouble()) return v.toStringAsFixed(0);
    return v.toStringAsFixed(2);
  }

  static Widget _h(String text, {TextAlign align = TextAlign.center}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Text(
        text,
        textAlign: align,
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 12,
          color: _headerFg,
        ),
      ),
    );
  }

  static Widget _c(
    String text, {
    TextAlign align = TextAlign.center,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Text(
        text,
        textAlign: align,
        softWrap: true,
        style: TextStyle(fontSize: 12, color: color, height: 1.3),
      ),
    );
  }
}
