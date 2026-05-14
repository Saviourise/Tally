import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screenshot/screenshot.dart';

import '../../core/providers.dart';
import '../../theme/tally_typography.dart';
import '../../widgets/honey_button.dart';
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
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
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
    final bytes = await _screenshotCtrl.capture(pixelRatio: 3);
    if (bytes != null) {
      await ExportService.sharePng(bytes, filename: _filename('png'));
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _sharePdf() async {
    setState(() => _busy = true);
    final bytes = await ExportService.buildPdf(_buildData());
    await ExportService.sharePdf(Uint8List.fromList(bytes), filename: _filename('pdf'));
    if (mounted) setState(() => _busy = false);
  }

  String _filename(String ext) {
    final m = ref.read(selectedMonthProvider);
    return 'tally-${m.year}-${m.month.toString().padLeft(2, '0')}.$ext';
  }

  @override
  Widget build(BuildContext context) {
    final ink = Theme.of(context).colorScheme.onSurface;
    final data = _buildData();
    return Scaffold(
      appBar: AppBar(
        title: Text('Export', style: TallyType.title(ink)),
      ),
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
                  label: _busy ? 'Preparing…' : 'Share PNG',
                  icon: Icons.image_rounded,
                  expanded: true,
                  onPressed: _busy ? null : _sharePng,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: HoneyButton(
                  label: _busy ? 'Preparing…' : 'Share PDF',
                  icon: Icons.picture_as_pdf_rounded,
                  expanded: true,
                  onPressed: _busy ? null : _sharePdf,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
