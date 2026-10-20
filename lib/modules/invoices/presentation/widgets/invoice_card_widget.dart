import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:reservation_workshop/config/style/app_spacing.dart';
import 'package:reservation_workshop/core/widgets/app_card.dart';

import '../../data/models/sell_invoice_model.dart';

class InvoiceCardWidget extends StatelessWidget {
  final SellInvoiceModel invoice;
  final VoidCallback onTap;

  const InvoiceCardWidget({
    super.key,
    required this.invoice,
    required this.onTap,
  });

  static String localizedStatus(String raw) {
    final v = raw.trim();
    if (v.isEmpty) return '-';
    final key = 'invoices.status_${v.toLowerCase().replaceAll(' ', '_')}';
    final tr = key.tr();
    return tr == key ? v : tr;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.zero,
        child: AppCard(
          borderRadius: 0,
          backgroundColor: Colors.white,
          borderColor: Colors.grey.shade300,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      invoice.invoiceNo.trim().isEmpty
                          ? 'invoices.number_fallback'.tr(
                              args: [invoice.id.toString()],
                            )
                          : invoice.invoiceNo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4AF37).withOpacity(0.15),
                      borderRadius: BorderRadius.zero,
                    ),
                    child: Text(
                      localizedStatus(invoice.paymentStatus),
                      style: const TextStyle(
                        color: const Color(0xFFD4AF37),
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                invoice.transactionDate.trim().isEmpty ? '-' : invoice.transactionDate,
                style: textTheme.bodySmall?.copyWith(
                  color: Colors.black54,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      localizedStatus(invoice.status),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyMedium?.copyWith(
                        color: Colors.black,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Text(
                    '${invoice.finalTotal.toStringAsFixed(2)}',
                    style: textTheme.titleSmall?.copyWith(
                      color: const Color(0xFFD4AF37),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
