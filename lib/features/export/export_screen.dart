import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screenshot/screenshot.dart';

import '../../core/providers.dart';
import '../../theme/tally_typography.dart';
import '../../widgets/honey_button.dart';
import 'company_invoice.dart';
import 'export_service.dart';
import 'invoice_widget.dart';

class ExportScreen extends ConsumerStatefulWidget {
  const ExportScreen({super.key});

  @override
  ConsumerState<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends ConsumerState<ExportScreen> {
  final _screenshotCtrl = ScreenshotController();
  bool _busy = false;

  static const monthLabels = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  InvoiceData _buildData() {
    final settings = ref.read(settingsProvider);
    final month = ref.read(selectedMonthProvider);
    final entries = ref.read(monthEntriesProvider).value ?? const [];
    final extras = ref.read(monthExtrasProvider).value ?? const [];
    final user = ref.read(authStateProvider).value;
    return InvoiceData(
      monthLabel: monthLabels[month.month - 1],
      year: month.year,
      entries: entries,
      extras: extras,
      hourlyFullDayPay: settings.hourlyFullDayPay,
      fullDayHours: settings.fullDayHours,
      displayName: user?.displayName,
    );
  }

  Future<void> _sharePng() async {
    setState(() => _busy = true);
    try {
      final bytes = await _screenshotCtrl.capture(pixelRatio: 3);
      if (bytes != null) {
        await ExportService.sharePng(bytes, filename: _filename('png'));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _sharePdf() async {
    setState(() => _busy = true);
    try {
      final bytes = await ExportService.buildPdf(_buildData());
      await ExportService.sharePdf(
        Uint8List.fromList(bytes),
        filename: _filename('pdf'),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _shareCompanyInvoice() async {
    setState(() => _busy = true);
    try {
      final settings = ref.read(settingsProvider);
      final user = ref.read(authStateProvider).value;
      final missing = CompanyInvoiceData.missingRequiredFields(settings);
      if (missing.isNotEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Set ${missing.join(', ')} in Settings before generating the company invoice.',
              ),
            ),
          );
        }
        return;
      }

      final invoiceDate = DateTime.now();
      final sequenceKey = CompanyInvoiceData.invoiceSequenceKey(invoiceDate);
      final nextSequence =
          (settings.invoiceSequenceByMonth[sequenceKey] ?? 0) + 1;
      final invoiceNumber = CompanyInvoiceData.invoiceNumberFor(
        invoiceDate,
        nextSequence,
      );
      final month = ref.read(selectedMonthProvider);
      final entries = ref.read(monthEntriesProvider).value ?? const [];
      final extras = ref.read(monthExtrasProvider).value ?? const [];
      final data = CompanyInvoiceData.fromMonthlyStatement(
        invoiceDate: invoiceDate,
        invoiceNumber: invoiceNumber,
        settings: settings,
        monthLabel: monthLabels[month.month - 1],
        year: month.year,
        entries: entries,
        extras: extras,
        displayName: user?.displayName,
      );
      final bytes = await ExportService.buildCompanyInvoicePdf(data);
      await ExportService.sharePdf(
        Uint8List.fromList(bytes),
        filename: _companyFilename(invoiceNumber),
        text: 'Tally - company invoice $invoiceNumber',
      );

      final uid = ref.read(currentUidProvider);
      if (uid != null) {
        final repo = ref.read(settingsRepoProvider);
        final latest = await repo.read(uid);
        final updatedSequences = Map<String, int>.from(
          latest.invoiceSequenceByMonth,
        );
        final current = updatedSequences[sequenceKey] ?? 0;
        if (nextSequence > current) {
          updatedSequences[sequenceKey] = nextSequence;
          await repo.write(
            uid,
            latest.copyWith(invoiceSequenceByMonth: updatedSequences),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _filename(String ext) {
    final m = ref.read(selectedMonthProvider);
    return 'tally-${m.year}-${m.month.toString().padLeft(2, '0')}.$ext';
  }

  String _companyFilename(String invoiceNumber) =>
      'company-invoice-${invoiceNumber.toLowerCase()}.pdf';

  @override
  Widget build(BuildContext context) {
    final ink = Theme.of(context).colorScheme.onSurface;
    final data = _buildData();
    final settings = ref.watch(settingsProvider);
    final missing = CompanyInvoiceData.missingRequiredFields(settings);
    final companyInvoiceReady = missing.isEmpty;
    return Scaffold(
      appBar: AppBar(title: Text('Export', style: TallyType.title(ink))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
        children: [
          Text(
            'PREVIEW',
            style: TallyType.label(ink.withValues(alpha: 0.55), size: 11),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 24,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: FittedBox(
                fit: BoxFit.fitWidth,
                child: Screenshot(
                  controller: _screenshotCtrl,
                  child: InvoiceWidget(data: data),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: HoneyButton(
                  label: _busy ? 'Preparing...' : 'Share PNG',
                  icon: Icons.image_rounded,
                  expanded: true,
                  onPressed: _busy ? null : _sharePng,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: HoneyButton(
                  label: _busy ? 'Preparing...' : 'Share PDF',
                  icon: Icons.picture_as_pdf_rounded,
                  expanded: true,
                  onPressed: _busy ? null : _sharePdf,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            'COMPANY INVOICE',
            style: TallyType.label(ink.withValues(alpha: 0.55), size: 11),
          ),
          const SizedBox(height: 8),
          Text(
            'Uses the Cozm invoice layout, your Settings details, today\'s invoice date, and an auto-incremented monthly invoice number.',
            style: TallyType.body(ink.withValues(alpha: 0.7), size: 13),
          ),
          if (!companyInvoiceReady) ...[
            const SizedBox(height: 8),
            Text(
              'Required before this is enabled: ${missing.join(', ')}.',
              style: TallyType.body(ink.withValues(alpha: 0.65), size: 12),
            ),
          ],
          const SizedBox(height: 12),
          HoneyButton(
            label: _busy ? 'Preparing...' : 'Generate company invoice',
            icon: Icons.business_center_rounded,
            expanded: true,
            onPressed: _busy || !companyInvoiceReady
                ? null
                : _shareCompanyInvoice,
          ),
        ],
      ),
    );
  }
}
