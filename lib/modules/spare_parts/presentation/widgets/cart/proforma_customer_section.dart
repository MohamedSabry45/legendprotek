import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:reservation_workshop/config/style/app_colors.dart';

class ProformaCustomerSection extends StatelessWidget {
  final TextEditingController contactIdController;
  final TextEditingController transactionDateController;
  final VoidCallback onPickTransactionDate;

  const ProformaCustomerSection({
    super.key,
    required this.contactIdController,
    required this.transactionDateController,
    required this.onPickTransactionDate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: AppColors.brandOutline.withOpacity(0.35)),
    );

    InputDecoration decorate({Widget? suffixIcon}) {
      return InputDecoration(
        filled: true,
        fillColor: AppColors.white2,
        hintStyle: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.brandDark),
        border: baseBorder,
        enabledBorder: baseBorder,
        focusedBorder: baseBorder.copyWith(
          borderSide: const BorderSide(color: AppColors.brandPrimary, width: 1.6),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        suffixIcon: suffixIcon,
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.brandOutline.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.brandPrimarySoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.person_outline, color: AppColors.brandPrimary),
              ),
              const SizedBox(width: 10),
              Text(
                'Customer',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppColors.brandDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Transaction date',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: AppColors.brandDark,
            ),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: onPickTransactionDate,
            borderRadius: BorderRadius.circular(14),
            child: IgnorePointer(
              child: TextFormField(
                controller: transactionDateController,
                decoration: decorate(suffixIcon: const Icon(Icons.calendar_today_outlined)),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.brandDark,
                ),
                validator: (v) {
                  if ((v ?? '').trim().isEmpty) return 'common.required'.tr();
                  return null;
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
