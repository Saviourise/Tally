import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../../core/formatters.dart';
import '../../core/pay_calc.dart';
import 'invoice_widget.dart';

class ExportService {
  ExportService._();

  static Future<File> _writeBytes(Uint8List bytes, String filename) async {
    final dir = await getTemporaryDirectory();
    final f = File('${dir.path}/$filename');
    await f.writeAsBytes(bytes, flush: true);
    return f;
  }

  static Future<void> sharePng(Uint8List bytes, {required String filename}) async {
    final file = await _writeBytes(bytes, filename);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'image/png')],
        text: 'Tally — monthly statement',
      ),
    );
  }

  static Future<void> sharePdf(Uint8List bytes, {required String filename}) async {
    final file = await _writeBytes(bytes, filename);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'application/pdf')],
        text: 'Tally — monthly statement',
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
        .map((e) => PayCalc.payForEntry(
              entry: e,
              monthEntries: data.entries,
              hourlyFullDayPay: data.hourlyFullDayPay,
              fullDayHours: data.fullDayHours,
            ))
        .toList();
    final entriesTotal = pays.fold<double>(0, (a, b) => a + b);
    final extrasNet = data.extras.fold<double>(0, (a, e) => a + e.signedAmount);
    final total = entriesTotal + extrasNet;
    final totalMinutes =
        data.entries.fold<int>(0, (a, e) => a + e.totalMinutes);

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
                    pw.Row(children: [
                      pw.Text('tally',
                          style: pw.TextStyle(
                              fontSize: 32,
                              fontWeight: pw.FontWeight.bold,
                              fontStyle: pw.FontStyle.italic,
                              color: ink)),
                      pw.SizedBox(width: 8),
                      pw.Container(
                        width: 18,
                        height: 22,
                        decoration: pw.BoxDecoration(color: honey),
                      ),
                    ]),
                    pw.Spacer(),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('STATEMENT',
                            style: pw.TextStyle(
                                fontSize: 9, color: muted, letterSpacing: 2)),
                        pw.SizedBox(height: 4),
                        pw.Text('${data.monthLabel} ${data.year}',
                            style: pw.TextStyle(
                                fontSize: 24, fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 18),
                pw.Container(
                    height: 0.8, color: PdfColor.fromHex('CCCCCC')),
                pw.SizedBox(height: 16),
                if (data.displayName != null) ...[
                  pw.Text('FOR',
                      style: pw.TextStyle(
                          fontSize: 8, color: muted, letterSpacing: 2)),
                  pw.SizedBox(height: 2),
                  pw.Text(data.displayName!,
                      style: pw.TextStyle(
                          fontSize: 14, fontWeight: pw.FontWeight.bold)),
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
                                color: PdfColor.fromHex('CCCCCC'))),
                      ),
                      children: [
                        _cell('DATE', muted, header: true),
                        _cell('HOURS', muted, header: true, right: true),
                        _cell('PAY', muted, header: true, right: true),
                      ],
                    ),
                    for (var i = 0; i < data.entries.length; i++)
                      pw.TableRow(children: [
                        _cell(
                            '${wd[data.entries[i].date.weekday - 1]} ${data.entries[i].date.day.toString().padLeft(2, '0')} ${data.monthLabel.substring(0, 3)}',
                            ink),
                        _cell(formatHM(data.entries[i].totalMinutes), ink,
                            right: true),
                        _cell(formatMoney(pays[i]), ink, right: true),
                      ]),
                  ],
                ),
                pw.SizedBox(height: 8),
                pw.Container(
                    height: 0.8, color: PdfColor.fromHex('CCCCCC')),
                pw.SizedBox(height: 6),
                pw.Row(children: [
                  pw.Text(
                    'Subtotal (${data.entries.length} days, ${formatHM(totalMinutes)})',
                    style: pw.TextStyle(fontSize: 12, color: muted),
                  ),
                  pw.Spacer(),
                  pw.Text(formatMoney(entriesTotal),
                      style: pw.TextStyle(
                          fontSize: 14, fontWeight: pw.FontWeight.bold)),
                ]),
                if (data.extras.isNotEmpty) ...[
                  pw.SizedBox(height: 12),
                  pw.Text('EXTRAS',
                      style: pw.TextStyle(
                          fontSize: 9, color: muted, letterSpacing: 2)),
                  pw.SizedBox(height: 4),
                  for (final e in data.extras)
                    pw.Row(children: [
                      pw.Expanded(
                          flex: 4,
                          child:
                              pw.Text(e.label, style: pw.TextStyle(fontSize: 12))),
                      pw.Expanded(
                          flex: 2,
                          child: pw.Text(
                              e.kind.name,
                              style: pw.TextStyle(fontSize: 11, color: muted),
                              textAlign: pw.TextAlign.right)),
                      pw.Expanded(
                          flex: 2,
                          child: pw.Text(
                            '${e.signedAmount >= 0 ? '+' : '-'}${formatMoney(e.amount)}',
                            style: pw.TextStyle(
                                fontSize: 12, fontWeight: pw.FontWeight.bold),
                            textAlign: pw.TextAlign.right,
                          )),
                    ]),
                ],
                pw.SizedBox(height: 18),
                pw.Container(height: 2, color: ink),
                pw.SizedBox(height: 10),
                pw.Row(children: [
                  pw.Text('TOTAL',
                      style: pw.TextStyle(
                          fontSize: 12,
                          letterSpacing: 2,
                          fontWeight: pw.FontWeight.bold)),
                  pw.Spacer(),
                  pw.Text(formatMoney(total),
                      style: pw.TextStyle(
                          fontSize: 28, fontWeight: pw.FontWeight.bold)),
                ]),
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

  static pw.Widget _cell(String text, PdfColor color,
      {bool right = false, bool header = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: header ? 9 : 12,
          letterSpacing: header ? 2 : 0,
          color: color,
          fontWeight:
              header ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
        textAlign: right ? pw.TextAlign.right : pw.TextAlign.left,
      ),
    );
  }
}
