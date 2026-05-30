import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../../core/formatters.dart';
import '../../core/pay_calc.dart';
import 'company_invoice.dart';
import 'invoice_widget.dart';

class ExportService {
  ExportService._();

  static Future<File> _writeBytes(Uint8List bytes, String filename) async {
    final dir = await getTemporaryDirectory();
    final f = File('${dir.path}/$filename');
    await f.writeAsBytes(bytes, flush: true);
    return f;
  }

  static Future<void> sharePng(
    Uint8List bytes, {
    required String filename,
  }) async {
    final file = await _writeBytes(bytes, filename);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'image/png')],
        text: 'Tally - monthly statement',
      ),
    );
  }

  static Future<void> sharePdf(
    Uint8List bytes, {
    required String filename,
    String text = 'Tally - monthly statement',
  }) async {
    final file = await _writeBytes(bytes, filename);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'application/pdf')],
        text: text,
      ),
    );
  }

  /// Build a PDF version of the invoice using the pdf package (more reliable
  /// than rasterizing a widget for documents).
  static Future<Uint8List> buildPdf(InvoiceData data) async {
    final doc = pw.Document();
    final ink = PdfColors.black;
    final muted = PdfColor.fromHex('666666');
    final cream = PdfColor.fromHex('F5EFE3');
    final honey = PdfColor.fromHex('F2C94C');

    const wd = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final pays = data.entries
        .map(
          (e) => PayCalc.payForEntry(
            entry: e,
            monthEntries: data.entries,
            hourlyFullDayPay: data.hourlyFullDayPay,
            fullDayHours: data.fullDayHours,
          ),
        )
        .toList();
    final entriesTotal = pays.fold<double>(0, (a, b) => a + b);
    final extrasNet = data.extras.fold<double>(0, (a, e) => a + e.signedAmount);
    final total = entriesTotal + extrasNet;
    final totalMinutes = data.entries.fold<int>(
      0,
      (a, e) => a + e.totalMinutes,
    );

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (ctx) {
          return pw.Container(
            color: cream,
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      children: [
                        pw.Text(
                          'tally',
                          style: pw.TextStyle(
                            fontSize: 32,
                            fontWeight: pw.FontWeight.bold,
                            fontStyle: pw.FontStyle.italic,
                            color: ink,
                          ),
                        ),
                        pw.SizedBox(width: 8),
                        pw.Container(
                          width: 18,
                          height: 22,
                          decoration: pw.BoxDecoration(color: honey),
                        ),
                      ],
                    ),
                    pw.Spacer(),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'STATEMENT',
                          style: pw.TextStyle(
                            fontSize: 9,
                            color: muted,
                            letterSpacing: 2,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          '${data.monthLabel} ${data.year}',
                          style: pw.TextStyle(
                            fontSize: 24,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 18),
                pw.Container(height: 0.8, color: PdfColor.fromHex('CCCCCC')),
                pw.SizedBox(height: 16),
                if (data.displayName != null) ...[
                  pw.Text(
                    'FOR',
                    style: pw.TextStyle(
                      fontSize: 8,
                      color: muted,
                      letterSpacing: 2,
                    ),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    data.displayName!,
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 16),
                ],
                pw.Table(
                  columnWidths: const {
                    0: pw.FlexColumnWidth(4),
                    1: pw.FlexColumnWidth(2),
                    2: pw.FlexColumnWidth(2),
                  },
                  children: [
                    pw.TableRow(
                      decoration: pw.BoxDecoration(
                        border: pw.Border(
                          bottom: pw.BorderSide(
                            color: PdfColor.fromHex('CCCCCC'),
                          ),
                        ),
                      ),
                      children: [
                        _cell('DATE', muted, header: true),
                        _cell('HOURS', muted, header: true, right: true),
                        _cell('PAY', muted, header: true, right: true),
                      ],
                    ),
                    for (var i = 0; i < data.entries.length; i++)
                      pw.TableRow(
                        children: [
                          _cell(
                            '${wd[data.entries[i].date.weekday - 1]} ${data.entries[i].date.day.toString().padLeft(2, '0')} ${data.monthLabel.substring(0, 3)}',
                            ink,
                          ),
                          _cell(
                            formatHM(data.entries[i].totalMinutes),
                            ink,
                            right: true,
                          ),
                          _cell(formatMoney(pays[i]), ink, right: true),
                        ],
                      ),
                  ],
                ),
                pw.SizedBox(height: 8),
                pw.Container(height: 0.8, color: PdfColor.fromHex('CCCCCC')),
                pw.SizedBox(height: 6),
                pw.Row(
                  children: [
                    pw.Text(
                      'Subtotal (${data.entries.length} days, ${formatHM(totalMinutes)})',
                      style: pw.TextStyle(fontSize: 12, color: muted),
                    ),
                    pw.Spacer(),
                    pw.Text(
                      formatMoney(entriesTotal),
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (data.extras.isNotEmpty) ...[
                  pw.SizedBox(height: 12),
                  pw.Text(
                    'EXTRAS',
                    style: pw.TextStyle(
                      fontSize: 9,
                      color: muted,
                      letterSpacing: 2,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  for (final e in data.extras)
                    pw.Row(
                      children: [
                        pw.Expanded(
                          flex: 4,
                          child: pw.Text(
                            e.label,
                            style: pw.TextStyle(fontSize: 12),
                          ),
                        ),
                        pw.Expanded(
                          flex: 2,
                          child: pw.Text(
                            e.kind.name,
                            style: pw.TextStyle(fontSize: 11, color: muted),
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                        pw.Expanded(
                          flex: 2,
                          child: pw.Text(
                            '${e.signedAmount >= 0 ? '+' : '-'}${formatMoney(e.amount)}',
                            style: pw.TextStyle(
                              fontSize: 12,
                              fontWeight: pw.FontWeight.bold,
                            ),
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                ],
                pw.SizedBox(height: 18),
                pw.Container(height: 2, color: ink),
                pw.SizedBox(height: 10),
                pw.Row(
                  children: [
                    pw.Text(
                      'TOTAL',
                      style: pw.TextStyle(
                        fontSize: 12,
                        letterSpacing: 2,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Spacer(),
                    pw.Text(
                      formatMoney(total),
                      style: pw.TextStyle(
                        fontSize: 28,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  'Generated with Tally on ${DateTime.now().toIso8601String().substring(0, 10)}.',
                  style: pw.TextStyle(fontSize: 9, color: muted),
                ),
              ],
            ),
          );
        },
      ),
    );
    return doc.save();
  }

  static Future<Uint8List> buildCompanyInvoicePdf(
    CompanyInvoiceData data,
  ) async {
    final doc = pw.Document();
    final dark = PdfColor.fromHex('4A4A4A');
    final grid = PdfColor.fromHex('D8D8D8');
    final black = PdfColors.black;
    final headingStyle = pw.TextStyle(
      color: dark,
      fontSize: 31,
      fontWeight: pw.FontWeight.bold,
    );
    final sectionStyle = pw.TextStyle(
      color: dark,
      fontSize: 11.5,
      fontWeight: pw.FontWeight.bold,
    );
    final bodyStyle = pw.TextStyle(
      fontSize: 10.2,
      fontWeight: pw.FontWeight.normal,
      lineSpacing: 2.1,
    );
    final boldBodyStyle = pw.TextStyle(
      fontSize: 10.2,
      fontWeight: pw.FontWeight.bold,
      lineSpacing: 2.1,
    );

    final tableRows = <pw.TableRow>[
      pw.TableRow(
        decoration: pw.BoxDecoration(color: PdfColor.fromHex('E3E3E3')),
        children: [
          _companyCell('Description', boldBodyStyle, padding: 8),
          _companyCell(
            data.amountHeading,
            boldBodyStyle,
            padding: 8,
            align: pw.TextAlign.right,
          ),
        ],
      ),
      for (final item in data.lineItems)
        pw.TableRow(
          children: [
            _companyCell(item.description, bodyStyle),
            _companyCell(
              formatCompanyInvoiceMoney(item.amount),
              bodyStyle,
              align: pw.TextAlign.right,
            ),
          ],
        ),
      pw.TableRow(
        children: [
          _companyCell('Subtotal', boldBodyStyle, align: pw.TextAlign.right),
          _companyCell(
            formatCompanyInvoiceMoney(data.subtotal),
            boldBodyStyle,
            align: pw.TextAlign.right,
          ),
        ],
      ),
      pw.TableRow(
        children: [
          _companyCell('', bodyStyle, minHeight: 16),
          _companyCell('', bodyStyle, minHeight: 16),
        ],
      ),
    ];

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(40, 34, 40, 30),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Align(
                alignment: pw.Alignment.topRight,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('INVOICE', style: headingStyle),
                    pw.SizedBox(height: 18),
                    pw.Text(
                      'Invoice number: ${data.invoiceNumber}',
                      style: bodyStyle,
                    ),
                    pw.SizedBox(height: 12),
                    pw.Text(
                      'Invoice date: ${data.invoiceDateLabel}',
                      style: bodyStyle,
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 34),
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: _invoiceBlock(
                      title: 'FROM',
                      lines: data.fromLines,
                      sectionStyle: sectionStyle,
                      bodyStyle: bodyStyle,
                    ),
                  ),
                  pw.SizedBox(width: 32),
                  pw.Expanded(
                    child: _invoiceBlock(
                      title: 'BILL TO',
                      lines: data.billToLines,
                      sectionStyle: sectionStyle,
                      bodyStyle: bodyStyle,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 52),
              pw.Text('SERVICES', style: sectionStyle),
              pw.SizedBox(height: 8),
              pw.Table(
                border: pw.TableBorder.all(color: grid, width: 0.7),
                columnWidths: const {
                  0: pw.FlexColumnWidth(4.7),
                  1: pw.FlexColumnWidth(1.8),
                },
                children: tableRows,
              ),
              pw.SizedBox(height: 22),
              pw.Container(
                color: dark,
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 9,
                ),
                child: pw.Row(
                  children: [
                    pw.Expanded(
                      flex: 4,
                      child: pw.Text(
                        'TOTAL DUE',
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                        ),
                        textAlign: pw.TextAlign.right,
                      ),
                    ),
                    pw.SizedBox(width: 12),
                    pw.Container(width: 0.7, height: 18, color: black),
                    pw.SizedBox(width: 12),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text(
                        data.totalDueLabel,
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                        ),
                        textAlign: pw.TextAlign.right,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 30),
              pw.Text('PAYMENT DETAILS', style: sectionStyle),
              pw.SizedBox(height: 10),
              for (final field in data.paymentDetails) ...[
                pw.RichText(
                  text: pw.TextSpan(
                    children: [
                      pw.TextSpan(
                        text: '${field.label}: ',
                        style: boldBodyStyle,
                      ),
                      pw.TextSpan(text: field.value, style: bodyStyle),
                    ],
                  ),
                ),
                pw.SizedBox(height: 8),
              ],
            ],
          );
        },
      ),
    );

    return doc.save();
  }

  static pw.Widget _cell(
    String text,
    PdfColor color, {
    bool right = false,
    bool header = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: header ? 9 : 12,
          letterSpacing: header ? 2 : 0,
          color: color,
          fontWeight: header ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
        textAlign: right ? pw.TextAlign.right : pw.TextAlign.left,
      ),
    );
  }

  static pw.Widget _invoiceBlock({
    required String title,
    required List<String> lines,
    required pw.TextStyle sectionStyle,
    required pw.TextStyle bodyStyle,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(title, style: sectionStyle),
        pw.SizedBox(height: 12),
        for (final line in lines) ...[
          pw.Text(line, style: bodyStyle),
          pw.SizedBox(height: 4),
        ],
      ],
    );
  }

  static pw.Widget _companyCell(
    String text,
    pw.TextStyle style, {
    pw.TextAlign align = pw.TextAlign.left,
    double padding = 7,
    double minHeight = 0,
  }) {
    return pw.Container(
      constraints: minHeight == 0
          ? null
          : pw.BoxConstraints(minHeight: minHeight),
      padding: pw.EdgeInsets.symmetric(horizontal: padding, vertical: 6),
      alignment: align == pw.TextAlign.right
          ? pw.Alignment.centerRight
          : pw.Alignment.centerLeft,
      child: pw.Text(text, style: style, textAlign: align),
    );
  }
}
