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
    String? reportLabel,
    String? generatedAt,
    pw.ImageProvider? logo,
  }) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (logo != null)
          pw.Container(
            width: 42,
            height: 42,
            child: pw.Image(logo, fit: pw.BoxFit.contain),
          )
        else
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
        if (generatedAt != null || reportLabel != null)
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              if (generatedAt != null)
                pw.Text(
                  'Generated $generatedAt',
                  style: const pw.TextStyle(color: _muted, fontSize: 9),
                ),
              if (reportLabel != null) ...[
                pw.SizedBox(height: 2),
                pw.Text(
                  reportLabel,
                  style: const pw.TextStyle(color: _muted, fontSize: 9),
                ),
              ],
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
          ?trailing,
        ],
      ),
    );
  }

  Future<Uint8List> buildQuotationReportBytes({
    required String companyName,
    required String currency,
    required List<Quotation> quotations,
    List<CostConstructionItem> costItems = const [],
    String note = '',
  }) async {
    final _ = currency;
    final doc = pw.Document();
    pw.ImageProvider? logo;
    pw.ImageProvider? watermark;
    try {
      logo = await imageFromAssetBundle('assets/brand/logo.png');
    } catch (_) {
      logo = null;
    }
    try {
      // Full brand mark (dark navy) used faintly as page watermark.
      watermark = await imageFromAssetBundle('assets/brand/logo.jpeg');
    } catch (_) {
      watermark = logo;
    }

    final generatedAt = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());

    // Use admin-stored label/value as-is (no project resolution on export).
    final resolvedCost = costItems
        .map((item) => (label: item.label, value: item.value.trim()))
        .toList();

    // Professional serif for quotation / cost documents (falls back offline).
    late final pw.Font baseFont;
    late final pw.Font boldFont;
    late final pw.Font italicFont;
    late final pw.Font boldItalicFont;
    try {
      baseFont = await PdfGoogleFonts.sourceSerif4Regular();
      boldFont = await PdfGoogleFonts.sourceSerif4Bold();
      italicFont = await PdfGoogleFonts.sourceSerif4Italic();
      boldItalicFont = await PdfGoogleFonts.sourceSerif4BoldItalic();
    } catch (_) {
      baseFont = pw.Font.times();
      boldFont = pw.Font.timesBold();
      italicFont = pw.Font.timesItalic();
      boldItalicFont = pw.Font.timesBoldItalic();
    }

    doc.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.fromLTRB(40, 48, 40, 44),
          theme: pw.ThemeData.withFont(
            base: baseFont,
            bold: boldFont,
            italic: italicFont,
            boldItalic: boldItalicFont,
          ),
          buildBackground: (context) {
            final wm = watermark;
            if (wm == null) return pw.SizedBox();
            return pw.FullPage(
              ignoreMargins: true,
              child: pw.Center(
                child: pw.Opacity(
                  // Dark navy logo, lightly transparent over white page.
                  opacity: 0.14,
                  child: pw.Image(
                    wm,
                    width: 360,
                    fit: pw.BoxFit.contain,
                  ),
                ),
              ),
            );
          },
        ),
        build: (context) => [
          _brandHeader(
            companyName: companyName,
            reportLabel: 'Quotation Report',
            generatedAt: generatedAt,
            logo: logo,
          ),
          pw.SizedBox(height: 14),
          pw.Divider(color: PdfColors.grey400, thickness: 0.9),
          pw.SizedBox(height: 16),
          pw.Text(
            'Quotation Report',
            style: pw.TextStyle(
              color: _navy,
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 14),
          pw.Divider(color: PdfColors.grey300, thickness: 0.8),
          pw.SizedBox(height: 14),
          if (quotations.isEmpty)
            pw.Text(
              'No quotation items.',
              style: const pw.TextStyle(color: _muted, fontSize: 11),
            )
          else
            ...quotations.asMap().entries.map(
              (entry) {
                final n = entry.key + 1;
                final q = entry.value;
                return pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 10),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.SizedBox(
                        width: 28,
                        child: pw.Text(
                          '$n.',
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                      pw.Expanded(
                        child: pw.Text(
                          q.title,
                          style: const pw.TextStyle(
                            fontSize: 12,
                            lineSpacing: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          if (resolvedCost.isNotEmpty) ...[
            pw.SizedBox(height: 22),
            pw.Text(
              'Cost of construction:',
              style: pw.TextStyle(
                color: _navy,
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                fontStyle: pw.FontStyle.italic,
                decoration: pw.TextDecoration.underline,
              ),
            ),
            pw.SizedBox(height: 10),
            ...resolvedCost.map(
              (line) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 8),
                child: pw.RichText(
                  text: pw.TextSpan(
                    children: [
                      pw.TextSpan(
                        text: line.label,
                        style: pw.TextStyle(
                          fontSize: 11.5,
                          fontWeight: pw.FontWeight.bold,
                          fontStyle: pw.FontStyle.italic,
                          color: PdfColors.black,
                        ),
                      ),
                      if (line.value.isNotEmpty)
                        pw.TextSpan(
                          text: ' = ${line.value}',
                          style: pw.TextStyle(
                            fontSize: 11.5,
                            fontWeight: pw.FontWeight.bold,
                            fontStyle: pw.FontStyle.italic,
                            color: PdfColors.black,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
          if (note.trim().isNotEmpty) ...[
            pw.SizedBox(height: 18),
            pw.Text(
              note.trim(),
              style: pw.TextStyle(
                fontSize: 11.5,
                fontWeight: pw.FontWeight.bold,
                fontStyle: pw.FontStyle.italic,
                lineSpacing: 1.35,
              ),
            ),
          ],
        ],
      ),
    );

    return doc.save();
  }

  String _fmtNum(double value) {
    if (value == value.roundToDouble()) {
      return NumberFormat('#,##0').format(value);
    }
    return NumberFormat('#,##0.##').format(value);
  }

  Future<Uint8List> buildBillReportBytes({
    required String companyName,
    required String currency,
    required Bill bill,
  }) async {
    final doc = pw.Document();
    pw.ImageProvider? logo;
    pw.ImageProvider? watermark;
    try {
      logo = await imageFromAssetBundle('assets/brand/logo.png');
    } catch (_) {
      logo = null;
    }
    try {
      watermark = await imageFromAssetBundle('assets/brand/logo.jpeg');
    } catch (_) {
      watermark = logo;
    }

    final generatedAt = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());
    final money = NumberFormat.currency(symbol: _symbol(currency), decimalDigits: 0);
    final moneyDec =
        NumberFormat.currency(symbol: _symbol(currency), decimalDigits: 2);

    String moneyFmt(double v) =>
        v == v.roundToDouble() ? money.format(v) : moneyDec.format(v);

    late final pw.Font baseFont;
    late final pw.Font boldFont;
    late final pw.Font italicFont;
    late final pw.Font boldItalicFont;
    try {
      baseFont = await PdfGoogleFonts.sourceSerif4Regular();
      boldFont = await PdfGoogleFonts.sourceSerif4Bold();
      italicFont = await PdfGoogleFonts.sourceSerif4Italic();
      boldItalicFont = await PdfGoogleFonts.sourceSerif4BoldItalic();
    } catch (_) {
      baseFont = pw.Font.times();
      boldFont = pw.Font.timesBold();
      italicFont = pw.Font.timesItalic();
      boldItalicFont = pw.Font.timesBoldItalic();
    }

    const headerBg = PdfColor.fromInt(0xFFE8F5E9);
    const gridColor = PdfColor.fromInt(0xFFCCCCCC);

    pw.Widget cell(
      String text, {
      pw.FontWeight? weight,
      pw.Alignment align = pw.Alignment.centerLeft,
      int flex = 1,
      bool header = false,
    }) {
      return pw.Expanded(
        flex: flex,
        child: pw.Container(
          alignment: align,
          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 7),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: gridColor, width: 0.5),
            color: header ? headerBg : null,
          ),
          child: pw.Text(
            text,
            style: pw.TextStyle(
              fontSize: header ? 10 : 9.5,
              fontWeight: weight ??
                  (header ? pw.FontWeight.bold : pw.FontWeight.normal),
            ),
          ),
        ),
      );
    }

    pw.Widget headerRow() {
      return pw.Row(
        children: [
          cell('SI', align: pw.Alignment.center, flex: 1, header: true),
          cell('Description', flex: 5, header: true),
          cell('Unit', align: pw.Alignment.center, flex: 2, header: true),
          cell('Qty', align: pw.Alignment.center, flex: 2, header: true),
          cell('Rate (${_symbol(currency).trim()})',
              align: pw.Alignment.centerRight, flex: 2, header: true),
          cell('Amount (${_symbol(currency).trim()})',
              align: pw.Alignment.centerRight, flex: 3, header: true),
        ],
      );
    }

    pw.Widget dataRow(int si, BillItem item) {
      return pw.Row(
        children: [
          cell('$si', align: pw.Alignment.center, flex: 1),
          cell(item.description, flex: 5),
          cell(item.unit, align: pw.Alignment.center, flex: 2),
          cell(_fmtNum(item.qty), align: pw.Alignment.center, flex: 2),
          cell(moneyFmt(item.rate), align: pw.Alignment.centerRight, flex: 2),
          cell(moneyFmt(item.amount),
              align: pw.Alignment.centerRight, flex: 3),
        ],
      );
    }

    doc.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.fromLTRB(36, 44, 36, 40),
          theme: pw.ThemeData.withFont(
            base: baseFont,
            bold: boldFont,
            italic: italicFont,
            boldItalic: boldItalicFont,
          ),
          buildBackground: (context) {
            final wm = watermark;
            if (wm == null) return pw.SizedBox();
            return pw.FullPage(
              ignoreMargins: true,
              child: pw.Center(
                child: pw.Opacity(
                  opacity: 0.14,
                  child: pw.Image(
                    wm,
                    width: 360,
                    fit: pw.BoxFit.contain,
                  ),
                ),
              ),
            );
          },
        ),
        build: (context) => [
          _brandHeader(
            companyName: companyName,
            reportLabel: 'Bill Report',
            generatedAt: generatedAt,
            logo: logo,
          ),
          pw.SizedBox(height: 14),
          pw.Divider(color: PdfColors.grey400, thickness: 0.9),
          pw.SizedBox(height: 12),
          pw.Text(
            bill.name,
            style: pw.TextStyle(
              color: _navy,
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 16),
          pw.Text(
            'Work Summary',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          headerRow(),
          if (bill.items.isEmpty)
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: gridColor, width: 0.5),
              ),
              child: pw.Text(
                'No line items.',
                style: const pw.TextStyle(color: _muted, fontSize: 10),
              ),
            )
          else
            ...bill.items.asMap().entries.map(
                  (e) => dataRow(e.key + 1, e.value),
                ),
          pw.SizedBox(height: 8),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              'Total: ${moneyFmt(bill.totalAmount)}',
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          if (bill.note.trim().isNotEmpty) ...[
            pw.SizedBox(height: 18),
            pw.Text(
              bill.note.trim(),
              style: pw.TextStyle(
                fontSize: 11.5,
                fontWeight: pw.FontWeight.bold,
                fontStyle: pw.FontStyle.italic,
                lineSpacing: 1.35,
              ),
            ),
          ],
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
