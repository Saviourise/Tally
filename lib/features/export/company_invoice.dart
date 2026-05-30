import 'package:intl/intl.dart';

import '../../core/formatters.dart';
import '../../core/pay_calc.dart';
import '../../data/models/entry.dart';
import '../../data/models/extra.dart';
import '../../data/models/user_settings.dart';

class CompanyInvoiceLineItem {
  const CompanyInvoiceLineItem({
    required this.description,
    required this.amount,
  });

  final String description;
  final double amount;
}

class CompanyInvoicePaymentField {
  const CompanyInvoicePaymentField({required this.label, required this.value});

  final String label;
  final String value;
}

class CompanyInvoiceData {
  const CompanyInvoiceData({
    required this.invoiceNumber,
    required this.invoiceDateLabel,
    required this.fromLines,
    required this.billToLines,
    required this.amountHeading,
    required this.totalDueLabel,
    required this.lineItems,
    required this.subtotal,
    required this.paymentDetails,
  });

  final String invoiceNumber;
  final String invoiceDateLabel;
  final List<String> fromLines;
  final List<String> billToLines;
  final String amountHeading;
  final String totalDueLabel;
  final List<CompanyInvoiceLineItem> lineItems;
  final double subtotal;
  final List<CompanyInvoicePaymentField> paymentDetails;

  factory CompanyInvoiceData.fromMonthlyStatement({
    required DateTime invoiceDate,
    required String invoiceNumber,
    required UserSettings settings,
    required String monthLabel,
    required int year,
    required List<Entry> entries,
    required List<Extra> extras,
    String? displayName,
  }) {
    final monthlyFee = entries
        .map(
          (e) => PayCalc.payForEntry(
            entry: e,
            monthEntries: entries,
            hourlyFullDayPay: settings.hourlyFullDayPay,
            fullDayHours: settings.fullDayHours,
          ),
        )
        .fold<double>(0, (sum, amount) => sum + amount);
    final expenseTotal = extras
        .where((extra) => extra.kind == ExtraKind.payment)
        .fold<double>(0, (sum, extra) => sum + extra.amount);
    final deductionTotal = extras
        .where((extra) => extra.kind == ExtraKind.fee)
        .fold<double>(0, (sum, extra) => sum + extra.amount);

    final lineItems = <CompanyInvoiceLineItem>[
      CompanyInvoiceLineItem(
        description: 'Monthly fee - for $monthLabel $year',
        amount: monthlyFee,
      ),
      CompanyInvoiceLineItem(
        description: 'Expenses - please attach copy of expenses',
        amount: expenseTotal,
      ),
    ];
    if (deductionTotal > 0) {
      lineItems.add(
        CompanyInvoiceLineItem(
          description: 'Adjustments / deductions',
          amount: -deductionTotal,
        ),
      );
    }

    final senderName = settings.contractorName.trim().isNotEmpty
        ? settings.contractorName.trim()
        : (displayName ?? '').trim();
    final senderLines = [
      senderName,
      settings.contractorAddressLine1.trim(),
      settings.contractorAddressLine2.trim(),
      settings.contractorAddressLine3.trim(),
      settings.contractorPostcode.trim(),
    ].where((line) => line.isNotEmpty).toList();

    final billToLines = [
      settings.companyName.trim(),
      settings.companyAddressLine1.trim(),
      settings.companyAddressLine2.trim(),
      settings.companyAddressLine3.trim(),
      if (settings.companyNumber.trim().isNotEmpty)
        'Company no.: ${settings.companyNumber.trim()}',
    ];

    final paymentAccountName = settings.paymentAccountName.trim().isNotEmpty
        ? settings.paymentAccountName.trim()
        : senderName;
    final paymentDetails = [
      CompanyInvoicePaymentField(
        label: 'Account name',
        value: paymentAccountName,
      ),
      CompanyInvoicePaymentField(
        label: 'Sort code',
        value: settings.paymentSortCode.trim(),
      ),
      CompanyInvoicePaymentField(
        label: 'Account number',
        value: settings.paymentAccountNumber.trim(),
      ),
      if (settings.paymentSwiftCode.trim().isNotEmpty)
        CompanyInvoicePaymentField(
          label: 'Swift code',
          value: settings.paymentSwiftCode.trim(),
        ),
      if (settings.paymentBankName.trim().isNotEmpty)
        CompanyInvoicePaymentField(
          label: 'Bank name',
          value: settings.paymentBankName.trim(),
        ),
      if (settings.paymentBankAddress.trim().isNotEmpty)
        CompanyInvoicePaymentField(
          label: 'Bank address',
          value: settings.paymentBankAddress.trim(),
        ),
      const CompanyInvoicePaymentField(
        label: 'Reference',
        value: 'Invoice number (as above)',
      ),
    ];

    final currencyValue = settings.currency.trim().isEmpty
        ? '£'
        : settings.currency.trim();
    final currencySymbol = _currencySymbol(currencyValue);
    final amountHeading = 'Amount ($currencySymbol)';
    final subtotal = lineItems.fold<double>(
      0,
      (sum, item) => sum + item.amount,
    );
    final totalDueLabel =
        '$currencySymbol ${formatCompanyInvoiceMoney(subtotal)}';

    return CompanyInvoiceData(
      invoiceNumber: invoiceNumber,
      invoiceDateLabel: DateFormat('d MMMM yyyy').format(invoiceDate),
      fromLines: senderLines,
      billToLines: billToLines,
      amountHeading: amountHeading,
      totalDueLabel: totalDueLabel,
      lineItems: lineItems,
      subtotal: subtotal,
      paymentDetails: paymentDetails,
    );
  }

  static String invoiceSequenceKey(DateTime invoiceDate) =>
      '${invoiceDate.year.toString().padLeft(4, '0')}-${invoiceDate.month.toString().padLeft(2, '0')}';

  static String invoiceNumberFor(DateTime invoiceDate, int sequence) {
    final year = invoiceDate.year.toString().padLeft(4, '0');
    final month = invoiceDate.month.toString().padLeft(2, '0');
    final count = sequence.toString().padLeft(3, '0');
    return 'INV-$year$month-$count';
  }

  static List<String> missingRequiredFields(UserSettings settings) {
    final missing = <String>[];
    if (settings.companyName.trim().isEmpty) missing.add('company name');
    if (settings.companyAddressLine1.trim().isEmpty) {
      missing.add('company address line 1');
    }
    if (settings.contractorName.trim().isEmpty) missing.add('your name');
    if (settings.contractorAddressLine1.trim().isEmpty) {
      missing.add('your address line 1');
    }
    if (settings.contractorPostcode.trim().isEmpty) missing.add('postcode');
    if (settings.paymentAccountName.trim().isEmpty) {
      missing.add('account name');
    }
    if (settings.paymentSortCode.trim().isEmpty) missing.add('sort code');
    if (settings.paymentAccountNumber.trim().isEmpty) {
      missing.add('account number');
    }
    return missing;
  }
}

String formatCompanyInvoiceMoney(double value) {
  final normalized = formatMoneyPlain(value);
  if (!normalized.contains('.')) return normalized;
  var trimmed = normalized;
  while (trimmed.endsWith('0')) {
    trimmed = trimmed.substring(0, trimmed.length - 1);
  }
  if (trimmed.endsWith('.')) {
    trimmed = trimmed.substring(0, trimmed.length - 1);
  }
  return trimmed;
}

String _currencySymbol(String currencyCode) {
  final value = currencyCode.trim();
  if (value.isEmpty) return '£';
  if (RegExp(r'[^A-Za-z]').hasMatch(value)) return value;
  try {
    return NumberFormat.simpleCurrency(
      name: value.toUpperCase(),
    ).currencySymbol;
  } catch (_) {
    return value;
  }
}
