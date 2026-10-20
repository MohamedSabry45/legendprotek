import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:reservation_workshop/config/style/app_spacing.dart';
import 'package:reservation_workshop/core/widgets/app_card.dart';

import '../../data/models/sell_invoice_model.dart';
import '../widgets/invoice_card_widget.dart';
import 'invoice_details_args.dart';

class InvoiceDetailsScreen extends StatelessWidget {
  const InvoiceDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final invoice = args is InvoiceDetailsArgs ? args.invoice : null;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Text(
          'invoices.details_title'.tr(),
          style: const TextStyle(
            color: Color(0xFFD4AF37),
            fontWeight: FontWeight.w900,
          ),
        ),
        foregroundColor: const Color(0xFFD4AF37),
        iconTheme: const IconThemeData(color: Color(0xFFD4AF37)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: invoice == null
              ? Center(
                  child: Text(
                    'invoices.no_invoice_selected'.tr(),
                    style: const TextStyle(color: Colors.white70),
                  ),
                )
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: _Body(invoice: invoice),
                  ),
                ),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final SellInvoiceModel invoice;

  const _Body({required this.invoice});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final invoiceNo = invoice.invoiceNo.trim().isEmpty ? '-' : invoice.invoiceNo.trim();
    final transactionDate = invoice.transactionDate.trim().isEmpty ? '-' : invoice.transactionDate.trim();
    final paymentMethod = '-';
    final paymentRef = '-';
    final paymentStatus = InvoiceCardWidget.localizedStatus(
      invoice.paymentStatus,
    );
    final status = InvoiceCardWidget.localizedStatus(invoice.status);

    final subtotal = invoice.totalBeforeTax;
    final discount = invoice.discountAmount;
    final tax = invoice.taxAmount;
    final total = invoice.finalTotal;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppCard(
            backgroundColor: const Color(0xFF050505),
            borderColor: const Color(0xFF0A0A0A),
            borderRadius: 0,
            padding: const EdgeInsets.all(0),
            child: ClipRRect(
              borderRadius: BorderRadius.zero,
              child: Table(
                border: TableBorder.symmetric(
                  inside: BorderSide(color: const Color(0xFF0A0A0A)),
                ),
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                children: [
                  _headerRow([
                    'invoices.no'.tr(),
                    'invoices.transaction_date'.tr(),
                    'invoices.payment_method'.tr(),
                  ]),
                  _valueRow([
                    invoiceNo,
                    transactionDate,
                    paymentMethod,
                  ], textTheme),
                  _headerRow([
                    'invoices.payment_status'.tr(),
                    'invoices.status'.tr(),
                    'invoices.payment_ref'.tr(),
                  ]),
                  _valueRow([paymentStatus, status, paymentRef], textTheme),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: invoice.invoiceUrl.trim().isEmpty
                  ? null
                  : () async {
                      final url = invoice.invoiceUrl.trim();
                      final uri = Uri.tryParse(url);
                      if (uri == null) return;
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    },
              icon: const Icon(Icons.open_in_new),
              label: Text(
                'invoices.open_invoice'.tr(),
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4AF37),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'invoices.items'.tr(),
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppCard(
            backgroundColor: const Color(0xFF050505),
            borderColor: const Color(0xFF0A0A0A),
            borderRadius: 0,
            padding: const EdgeInsets.all(0),
            child: ClipRRect(
              borderRadius: BorderRadius.zero,
              child: Table(
                border: TableBorder.symmetric(
                  inside: BorderSide(color: const Color(0xFF0A0A0A)),
                ),
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                children: [
                  _headerRow([
                    'invoices.item'.tr(),
                    'invoices.qty'.tr(),
                    'invoices.total'.tr(),
                  ]),
                  for (final l in invoice.sellLines)
                    _valueRow(
                      [
                        (l.productName.trim().isEmpty ? (l.note.trim().isEmpty ? '-' : l.note) : l.productName.trim()),
                        _n(l.quantity),
                        _n(l.quantity * l.unitPriceIncTax),
                      ],
                      textTheme,
                      center: true,
                      firstAlignStart: true,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'invoices.summary'.tr(),
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppCard(
            backgroundColor: const Color(0xFF050505),
            borderColor: const Color(0xFF0A0A0A),
            borderRadius: 0,
            padding: const EdgeInsets.all(0),
            child: ClipRRect(
              borderRadius: BorderRadius.zero,
              child: Table(
                border: TableBorder.symmetric(
                  inside: BorderSide(color: const Color(0xFF0A0A0A)),
                ),
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                children: [
                  _headerRow([
                    'invoices.subtotal'.tr(),
                    'invoices.discount'.tr(),
                    'invoices.tax'.tr(),
                    'invoices.total'.tr(),
                  ]),
                  _valueRow([
                    _n(subtotal),
                    _n(discount),
                    _n(tax),
                    _n(total),
                  ], textTheme, center: true),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xxxl),
        ],
      ),
    );
  }

  static TableRow _headerRow(List<String> titles) {
    return TableRow(
      decoration: BoxDecoration(color: const Color(0xFF0A0A0A)),
      children: [
        for (final t in titles)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            child: Text(
              t,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: const Color(0xFFD4AF37),
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  static TableRow _valueRow(
    List<String> values,
    TextTheme textTheme, {
    bool center = false,
    bool firstAlignStart = false,
  }) {
    return TableRow(
      decoration: const BoxDecoration(color: Color(0xFF050505)),
      children: [
        for (var i = 0; i < values.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            child: Text(
              values[i].trim().isEmpty ? '-' : values[i],
              textAlign: (firstAlignStart && i == 0)
                  ? TextAlign.start
                  : (center ? TextAlign.center : TextAlign.center),
              style: textTheme.bodySmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                height: 1.2,
              ),
            ),
          ),
      ],
    );
  }

  static String _n(num v) {
    final asDouble = v.toDouble();
    if ((asDouble - asDouble.roundToDouble()).abs() < 0.000001) {
      return asDouble.toStringAsFixed(0);
    }
    return asDouble.toStringAsFixed(2);
  }
}
