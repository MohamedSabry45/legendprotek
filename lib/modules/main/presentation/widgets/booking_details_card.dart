import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:reservation_workshop/modules/main/presentation/widgets/notification_card.dart';

class BookingDetailsCard extends StatelessWidget {
  const BookingDetailsCard({
    super.key,
    required this.model,
    required this.onBack,
    required this.onConfirm,
    this.canConfirm = true,
  });

  final NotificationCardModel? model;
  final VoidCallback onBack;
  final VoidCallback onConfirm;
  final bool canConfirm;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 320,
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        decoration: BoxDecoration(
          color: const Color(0xFF050505),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.25)),
          boxShadow: const [
            BoxShadow(
              color: Color.fromARGB(51, 0, 0, 0),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            /// ===== HEADER =====
            Container(
              height: 46,
              width: double.infinity,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Color(0xFF0A0A0A),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Text(
                'booking.details_title'.tr(),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),

            /// ===== CONTENT =====
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
              child: Column(
                children: [
                  _DetailRow('booking.date'.tr(), model?.dateTime),
                  _gap(),
                  _DetailRow('booking.service'.tr(), model?.service),
                  _gap(),
                  _DetailRow('booking.brand'.tr(), model?.car),
                  _gap(),
                  _DetailRow('booking.model'.tr(), model?.carModel),
                  _gap(),
                  _DetailRow('booking.plate'.tr(), model?.plate),
                  _gap(),
                  _DetailRow('booking.location'.tr(), model?.branch),
                  _gap(),
                  _DetailRow('booking.notes'.tr(), model?.area),
                ],
              ),
            ),

            const Divider(height: 1, color: Color(0xFFE5E7EB)),

            /// ===== CUSTOMER INFO =====
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Column(
                children: [
                  _DetailRow('booking.name'.tr(), model?.name),
                  _gap(),
                  _DetailRow('booking.phone'.tr(), model?.phone),
                ],
              ),
            ),

            /// ===== ACTIONS =====
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: ElevatedButton(
                        onPressed: onBack,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0A0A0A),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: const BorderSide(
                              color: Color(0xFFD4AF37),
                              width: 1.2,
                            ),
                          ),
                        ),
                        child: Text(
                          'booking.back'.tr(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: ElevatedButton(
                        onPressed: canConfirm ? onConfirm : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD4AF37),
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'booking.confirm'.tr(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _gap() => const SizedBox(height: 12);
}

/// ===== ROW ITEM =====
class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value);

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white70,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value?.isNotEmpty == true ? value! : '-',
            textAlign: TextAlign.end,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
