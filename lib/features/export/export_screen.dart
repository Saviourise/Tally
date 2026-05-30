import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screenshot/screenshot.dart';

import '../../core/providers.dart';
import '../../data/models/entry.dart';
import '../../data/models/user_settings.dart';
import '../../theme/tally_typography.dart';
import '../../widgets/honey_button.dart';
import 'company_invoice.dart';
import 'export_service.dart';
import 'invoice_statement_scope.dart';
import 'invoice_widget.dart';

class ExportScreen extends ConsumerStatefulWidget {
  const ExportScreen({super.key});

  @override
  ConsumerState<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends ConsumerState<ExportScreen> {
  final _screenshotCtrl = ScreenshotController();
  bool _busy = false;
  bool _savingInvoiceSent = false;

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

  List<Entry> _buildStatementEntries({
    required DateTime month,
    required UserSettings settings,
    required List<Entry> monthEntries,
    required List<Entry> previousMonthEntries,
  }) {
    return buildInvoiceStatementEntries(
      month: month,
      monthEntries: monthEntries,
      previousMonthEntries: previousMonthEntries,
      invoiceCarryForwardStartByMonth:
          settings.invoiceCarryForwardStartByMonth,
    );
  }

  InvoiceData _buildData({
    required UserSettings settings,
    required DateTime month,
    required List<Entry> entries,
    required String? displayName,
  }) {
    final extras = ref.read(monthExtrasProvider).value ?? const [];
    return InvoiceData(
      monthLabel: monthLabels[month.month - 1],
      year: month.year,
      entries: entries,
      extras: extras,
      hourlyFullDayPay: settings.hourlyFullDayPay,
      fullDayHours: settings.fullDayHours,
      displayName: displayName,
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
      final settings = ref.read(settingsProvider);
      final month = ref.read(selectedMonthProvider);
      final previousMonth = DateTime(month.year, month.month - 1, 1);
      final monthEntries =
          await ref.read(monthEntriesByDateProvider(month).future);
      final previousMonthEntries = await ref.read(
        monthEntriesByDateProvider(previousMonth).future,
      );
      final statementEntries = _buildStatementEntries(
        month: month,
        settings: settings,
        monthEntries: monthEntries,
        previousMonthEntries: previousMonthEntries,
      );
      final user = ref.read(authStateProvider).value;
      final bytes = await ExportService.buildPdf(
        _buildData(
          settings: settings,
          month: month,
          entries: statementEntries,
          displayName: user?.displayName,
        ),
      );
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
      final previousMonth = DateTime(month.year, month.month - 1, 1);
      final monthEntries =
          await ref.read(monthEntriesByDateProvider(month).future);
      final previousMonthEntries = await ref.read(
        monthEntriesByDateProvider(previousMonth).future,
      );
      final entries = _buildStatementEntries(
        month: month,
        settings: settings,
        monthEntries: monthEntries,
        previousMonthEntries: previousMonthEntries,
      );
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

  Future<void> _markInvoiceSentForMonth() async {
    final uid = ref.read(currentUidProvider);
    if (uid == null) return;

    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month, 1);
    final selectedMonth = ref.read(selectedMonthProvider);
    final normalizedSelectedMonth = DateTime(
      selectedMonth.year,
      selectedMonth.month,
      1,
    );
    if (normalizedSelectedMonth != currentMonth) return;

    setState(() => _savingInvoiceSent = true);
    try {
      final repo = ref.read(settingsRepoProvider);
      final latest = await repo.read(uid);
      final monthKey = invoiceStatementMonthKey(normalizedSelectedMonth);
      if (latest.invoiceCarryForwardStartByMonth.containsKey(monthKey)) {
        return;
      }

      final todayEntry = await ref.read(entryRepoProvider).readDay(uid, now);
      final carryForwardStart = invoiceCarryForwardStartForSentMonth(
        answeredAt: now,
        hasLoggedForAnsweredDay: (todayEntry?.totalMinutes ?? 0) > 0,
      );
      final updatedCarryForwardStarts = Map<String, String>.from(
        latest.invoiceCarryForwardStartByMonth,
      );
      updatedCarryForwardStarts[monthKey] =
          carryForwardStart.toIso8601String();
      await repo.write(
        uid,
        latest.copyWith(
          invoiceCarryForwardStartByMonth: updatedCarryForwardStarts,
        ),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Invoice marked as sent. Remaining days will roll into next month.',
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save invoice sent status. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _savingInvoiceSent = false);
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
    final month = ref.watch(selectedMonthProvider);
    final settings = ref.watch(settingsProvider);
    final monthEntries = ref.watch(monthEntriesByDateProvider(month)).value ??
        const <Entry>[];
    final previousMonth = DateTime(month.year, month.month - 1, 1);
    final previousMonthEntries =
        ref.watch(monthEntriesByDateProvider(previousMonth)).value ??
            const <Entry>[];
    final statementEntries = _buildStatementEntries(
      month: month,
      settings: settings,
      monthEntries: monthEntries,
      previousMonthEntries: previousMonthEntries,
    );
    final data = _buildData(
      settings: settings,
      month: month,
      entries: statementEntries,
      displayName: ref.watch(authStateProvider).value?.displayName,
    );
    final missing = CompanyInvoiceData.missingRequiredFields(settings);
    final companyInvoiceReady = missing.isEmpty;
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month, 1);
    final normalizedSelectedMonth = DateTime(month.year, month.month, 1);
    final monthKey = invoiceStatementMonthKey(normalizedSelectedMonth);
    final invoiceMarkedSent =
        settings.invoiceCarryForwardStartByMonth.containsKey(monthKey);
    final showInvoiceSentPrompt =
        normalizedSelectedMonth == currentMonth &&
        !invoiceMarkedSent;
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
          if (invoiceMarkedSent) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.22),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    size: 18,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Invoice sent for ${monthLabels[month.month - 1]} ${month.year}. Remaining entries roll into the next month.',
                      style: TallyType.body(
                        ink.withValues(alpha: 0.82),
                        size: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],
          if (showInvoiceSentPrompt) ...[
            Text(
              'INVOICE SENT FOR THE MONTH',
              style: TallyType.label(ink.withValues(alpha: 0.55), size: 11),
            ),
            const SizedBox(height: 8),
            Text(
              'Mark this once the month is invoiced. Any remaining days from today onward move into next month. If today is not logged yet, today moves too.',
              style: TallyType.body(ink.withValues(alpha: 0.7), size: 13),
            ),
            const SizedBox(height: 12),
            HoneyButton(
              label: _savingInvoiceSent ? 'Saving...' : 'Yes, invoice sent',
              icon: Icons.check_circle_rounded,
              expanded: true,
              onPressed: _busy || _savingInvoiceSent
                  ? null
                  : _markInvoiceSentForMonth,
            ),
            const SizedBox(height: 22),
          ],
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
          if (invoiceMarkedSent) ...[
            const SizedBox(height: 8),
            Text(
              'Company invoice generation is disabled for this month because it has already been marked as sent.',
              style: TallyType.body(ink.withValues(alpha: 0.65), size: 12),
            ),
          ],
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
            onPressed: _busy || !companyInvoiceReady || invoiceMarkedSent
                ? null
                : _shareCompanyInvoice,
          ),
        ],
      ),
    );
  }
}
