import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../data/models/models.dart';
import '../data/repositories/app_repository.dart';

class PdfReportService {
  final AppRepository repo;
  PdfReportService(this.repo);

  static const _navy = PdfColor.fromInt(0xFF002147);
  static const _navySoft = PdfColor.fromInt(0xFFE8EEF5);
  static const _muted = PdfColor.fromInt(0xFF6B7280);
  static const _green = PdfColor.fromInt(0xFF059669);

  String _symbol(String currency) {
    switch (currency) {
      case 'QAR':
        return 'QAR ';
      case 'USD':
        return 'USD ';
      default:
        return 'INR ';
    }
  }

  pw.Widget _brandHeader({
    required String companyName,
    required String reportLabel,
    required String generatedAt,
  }) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          width: 36,
          height: 36,
          decoration: pw.BoxDecoration(
            color: _navy,
            borderRadius: pw.BorderRadius.circular(6),
          ),
          alignment: pw.Alignment.center,
          child: pw.Text(
            'D',
            style: pw.TextStyle(
              color: PdfColors.white,
              fontWeight: pw.FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        pw.SizedBox(width: 10),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                companyName.toUpperCase(),
                style: pw.TextStyle(
                  color: _navy,
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  letterSpacing: 0.4,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'Building Your Vision',
                style: const pw.TextStyle(color: _muted, fontSize: 10),
              ),
            ],
          ),
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              'Generated $generatedAt',
              style: const pw.TextStyle(color: _muted, fontSize: 9),
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              reportLabel,
              style: const pw.TextStyle(color: _muted, fontSize: 9),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _sectionBar(String title, {pw.Widget? trailing}) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      color: _navySoft,
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Text(
              title,
              style: pw.TextStyle(
                color: _navy,
                fontWeight: pw.FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Future<Uint8List> buildQuotationReportBytes({
    required String companyName,
    required String currency,
    required List<Quotation> quotations,
  }) async {
    // currency reserved for future priced quotation lines
    final _ = currency;
    final generatedAt = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());
    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(36, 36, 36, 40),
        build: (context) => [
          _brandHeader(
            companyName: companyName,
            reportLabel: 'Quotation Report',
            generatedAt: generatedAt,
          ),
          pw.SizedBox(height: 22),
          pw.Text(
            'Quotation Report',
            style: pw.TextStyle(
              fontSize: 22,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.black,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            'Period: All time • Items: ${quotations.length}',
            style: const pw.TextStyle(color: _muted, fontSize: 11),
          ),
          pw.SizedBox(height: 10),
          pw.Divider(color: PdfColors.grey300, thickness: 0.8),
          pw.SizedBox(height: 12),
          pw.Wrap(
            spacing: 24,
            runSpacing: 10,
            children: [
              _stat('Quotations selected', '${quotations.length}'),
              _stat('Report lines', '${quotations.length}'),
            ],
          ),
          pw.SizedBox(height: 18),
          _sectionBar('Quotation items'),
          pw.SizedBox(height: 8),
          if (quotations.isEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 8),
              child: pw.Text(
                'No quotations selected.',
                style: const pw.TextStyle(color: _muted, fontSize: 11),
              ),
            )
          else
            ...quotations.asMap().entries.map((e) {
              final i = e.key + 1;
              final q = e.value;
              return pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 8),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Container(
                      width: 22,
                      height: 22,
                      alignment: pw.Alignment.center,
                      decoration: pw.BoxDecoration(
                        color: _navySoft,
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Text(
                        '$i',
                        style: pw.TextStyle(
                          color: _navy,
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    pw.SizedBox(width: 10),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            q.title,
                            style: const pw.TextStyle(fontSize: 11),
                          ),
                          if (q.createdAt.isNotEmpty)
                            pw.Text(
                              q.createdAt,
                              style: const pw.TextStyle(
                                color: _muted,
                                fontSize: 9,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          pw.SizedBox(height: 16),
          _sectionBar(
            'TOTAL QUOTATIONS',
            trailing: pw.Text(
              '${quotations.length}',
              style: pw.TextStyle(
                color: _green,
                fontWeight: pw.FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          pw.SizedBox(height: 14),
          pw.Text(
            '* Quotation report generated from selected Admin quotation items.',
            style: const pw.TextStyle(color: _muted, fontSize: 8),
          ),
        ],
      ),
    );

    return doc.save();
  }

  pw.Widget _stat(String label, String value) {
    return pw.SizedBox(
      width: 200,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label, style: const pw.TextStyle(color: _muted, fontSize: 10)),
          pw.SizedBox(height: 2),
          pw.Text(
            value,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Future<Uint8List> buildFullReportBytes({
    required String companyName,
    required String currency,
  }) async {
    final stats = await repo.getDashboardStats();
    final materials = await repo.materialUsageReport();
    final labour = await repo.labourCostTotal();
    final money = NumberFormat.currency(symbol: _symbol(currency), decimalDigits: 2);
    final generatedAt = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());

    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(36, 36, 36, 40),
        build: (context) => [
          _brandHeader(
            companyName: companyName,
            reportLabel: 'Business Report',
            generatedAt: generatedAt,
          ),
          pw.SizedBox(height: 22),
          pw.Text(
            'Construction Report',
            style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            'Period: All time • Project: All projects',
            style: const pw.TextStyle(color: _muted, fontSize: 11),
          ),
          pw.SizedBox(height: 10),
          pw.Divider(color: PdfColors.grey300, thickness: 0.8),
          pw.SizedBox(height: 12),
          pw.Wrap(
            spacing: 24,
            runSpacing: 10,
            children: [
              _stat('Total projects', '${stats.totalProjects}'),
              _stat('Ongoing', '${stats.ongoingProjects}'),
              _stat('Completed', '${stats.completedProjects}'),
              _stat('Pending payments', money.format(stats.pendingPayments)),
              _stat('Labour total', money.format(labour)),
            ],
          ),
          pw.SizedBox(height: 18),
          _sectionBar('Material usage'),
          pw.SizedBox(height: 8),
          if (materials.isEmpty)
            pw.Text(
              'No material movement in this period.',
              style: const pw.TextStyle(color: _muted, fontSize: 11),
            )
          else
            ...materials.entries.map((e) => _kv(e.key, e.value.toStringAsFixed(1))),
          pw.SizedBox(height: 16),
          _sectionBar(
            'COST OF MATERIAL USED',
            trailing: pw.Text(
              money.format(0),
              style: pw.TextStyle(
                color: _green,
                fontWeight: pw.FontWeight.bold,
                fontSize: 12,
              ),
            ),
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
    final bytes = await buildFullReportBytes(
      companyName: companyName,
      currency: currency,
    );
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }

  pw.Widget _kv(String k, String v) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(k, style: const pw.TextStyle(fontSize: 11)),
          pw.Text(v, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
        ],
      ),
    );
  }
}
