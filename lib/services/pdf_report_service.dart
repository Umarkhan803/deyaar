import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../data/repositories/app_repository.dart';

class PdfReportService {
  final AppRepository repo;
  PdfReportService(this.repo);

  String _symbol(String currency) {
    switch (currency) {
      case 'QAR':
        return 'QAR ';
      case 'USD':
        return 'USD ';
      default:
        // Avoid ₹ glyph which often renders as boxes in default PDF fonts.
        return 'INR ';
    }
  }

  Future<Uint8List> buildFullReportBytes({
    required String companyName,
    required String currency,
  }) async {
    final stats = await repo.getDashboardStats();
    final materials = await repo.materialUsageReport();
    final labour = await repo.labourCostTotal();
    final expenses = await repo.expensesByCategory();
    final projects = await repo.getProjects();
    final money = NumberFormat.currency(symbol: _symbol(currency), decimalDigits: 0);

    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  companyName,
                  style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Construction Management Report',
                  style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700),
                ),
                pw.Text(
                  'Generated ${DateFormat('dd MMM yyyy HH:mm').format(DateTime.now())}',
                  style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey600),
                ),
                pw.Divider(thickness: 1.5),
              ],
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text('Summary', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          _kv('Total projects', '${stats.totalProjects}'),
          _kv('Ongoing', '${stats.ongoingProjects}'),
          _kv('Completed', '${stats.completedProjects}'),
          _kv('Pending payments', money.format(stats.pendingPayments)),
          _kv('Total received', money.format(stats.totalReceived)),
          _kv('Total expenses', money.format(stats.totalExpenses)),
          _kv('Profit / Loss', money.format(stats.profitLoss)),
          pw.SizedBox(height: 16),
          pw.Text('Labour costs', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          _kv('Labour total', money.format(labour)),
          pw.SizedBox(height: 16),
          pw.Text('Expenses by category', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          if (expenses.isEmpty)
            pw.Text('No expenses recorded')
          else
            ...expenses.entries.map((e) => _kv(e.key, money.format(e.value))),
          pw.SizedBox(height: 16),
          pw.Text('Material usage', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          if (materials.isEmpty)
            pw.Text('No materials recorded')
          else
            ...materials.entries.map((e) => _kv(e.key, e.value.toStringAsFixed(1))),
          pw.SizedBox(height: 16),
          pw.Text('Projects', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          pw.TableHelper.fromTextArray(
            headers: ['Name', 'Status', 'Progress', 'Client'],
            data: projects
                .map((p) => [
                      p.name,
                      p.status.label,
                      '${p.progress.toStringAsFixed(0)}%',
                      p.clientName ?? '-',
                    ])
                .toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellStyle: const pw.TextStyle(fontSize: 10),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
          ),
        ],
      ),
    );

    return doc.save();
  }

  Future<void> exportFullReport({
    required String companyName,
    required String currency,
  }) async {
    final bytes = await buildFullReportBytes(companyName: companyName, currency: currency);
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }

  pw.Widget _kv(String k, String v) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(k),
          pw.Text(v, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }
}
