import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import '../services/pdf_report_service.dart';
import '../theme/app_theme.dart';

enum ReportKind {
  materialUsage,
  labourCost,
  projectExpenses,
  profitLoss,
  businessSummary,
}

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  ReportKind _kind = ReportKind.materialUsage;
  String _period = 'all';
  int? _projectId;
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Choose a report', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          ...ReportKind.values.map((k) {
            final meta = _meta(k);
            final selected = _kind == k;
            return Card(
              color: selected ? AppColors.primaryBlue.withValues(alpha: 0.18) : null,
              child: RadioListTile<ReportKind>(
                value: k,
                // ignore: deprecated_member_use
                groupValue: _kind,
                onChanged: (v) => setState(() => _kind = v ?? _kind),
                title: Text(meta.$1, style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(meta.$2),
                secondary: Icon(meta.$3, color: AppColors.primaryBlue),
              ),
            );
          }),
          const SizedBox(height: 12),
          Text('Period', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final e in const [
                ('all', 'All time'),
                ('today', 'Today'),
                ('week', 'This week'),
                ('month', 'This month'),
              ])
                ChoiceChip(
                  label: Text(e.$2),
                  selected: _period == e.$1,
                  onSelected: (_) => setState(() => _period = e.$1),
                ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int?>(
            // ignore: deprecated_member_use
            value: _projectId,
            decoration: const InputDecoration(labelText: 'Project'),
            items: [
              const DropdownMenuItem(value: null, child: Text('All projects')),
              ...app.projects.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))),
            ],
            onChanged: (v) => setState(() => _projectId = v),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _busy ? null : _generate,
              icon: const Icon(Icons.bar_chart),
              label: Text(_busy ? 'Generating…' : 'Generate Report'),
            ),
          ),
        ],
      ),
    );
  }

  (String, String, IconData) _meta(ReportKind k) {
    switch (k) {
      case ReportKind.materialUsage:
        return ('Material Usage', 'Quantity purchased, used and remaining per material', Icons.inventory_2_outlined);
      case ReportKind.labourCost:
        return ('Labour Cost', 'Wages paid, attendance and cost per project', Icons.groups_outlined);
      case ReportKind.projectExpenses:
        return ('Project Expenses', 'Spend by heading, category and project', Icons.receipt_long_outlined);
      case ReportKind.profitLoss:
        return ('Profit / Loss', 'Contract value against payments received and costs', Icons.show_chart);
      case ReportKind.businessSummary:
        return ('Business Summary', 'Portfolio-wide position at a glance', Icons.bar_chart);
    }
  }

  Future<void> _generate() async {
    setState(() => _busy = true);
    try {
      final app = context.read<AppProvider>();
      final bytes = await PdfReportService(app.repo).buildFullReportBytes(
        companyName: app.settings.companyName,
        currency: app.settings.currency,
      );
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PdfPreviewScreen(
            bytes: bytes,
            title: _meta(_kind).$1,
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class PdfPreviewScreen extends StatelessWidget {
  final Uint8List bytes;
  final String title;
  const PdfPreviewScreen({super.key, required this.bytes, required this.title});

  Future<void> _download(BuildContext context) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'deyaar_${DateTime.now().millisecondsSinceEpoch}.pdf'));
    await file.writeAsBytes(bytes);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Saved: ${file.path}')),
    );
    await Printing.sharePdf(bytes: bytes, filename: p.basename(file.path));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            tooltip: 'Download',
            onPressed: () => _download(context),
            icon: const Icon(Icons.download_outlined),
          ),
          IconButton(
            tooltip: 'Share',
            onPressed: () => Printing.sharePdf(bytes: bytes, filename: 'deyaar_report.pdf'),
            icon: const Icon(Icons.share_outlined),
          ),
        ],
      ),
      body: PdfPreview(
        build: (_) async => bytes,
        allowPrinting: true,
        allowSharing: true,
        canChangeOrientation: false,
        canChangePageFormat: false,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _download(context),
        icon: const Icon(Icons.download),
        label: const Text('Download'),
      ),
    );
  }
}
