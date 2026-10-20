import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:reservation_workshop/config/style/app_colors.dart';
import 'package:reservation_workshop/core/functions/localization_helper.dart';
import 'package:reservation_workshop/core/widgets/app_card.dart';
import 'package:reservation_workshop/core/components/toasters.dart';
import 'package:reservation_workshop/modules/bookings/domain/entities/booking.dart';
import 'package:reservation_workshop/modules/bookings/presentation/cubits/bookings_cubit/bookings_cubit.dart';
import 'package:reservation_workshop/modules/bookings/presentation/cubits/bookings_cubit/bookings_state.dart';

class HomeLastBookingSection extends StatelessWidget {
  const HomeLastBookingSection({super.key});

  Booking? _latestBooking(List<Booking> items) {
    if (items.isEmpty) return null;

    DateTime? parse(String s) {
      final v = s.trim();
      if (v.isEmpty) return null;
      return DateTime.tryParse(v);
    }

    Booking best = items.first;
    DateTime? bestDt = parse(best.bookingStart);

    for (final b in items.skip(1)) {
      final dt = parse(b.bookingStart);
      if (dt == null) continue;
      if (bestDt == null || dt.isAfter(bestDt)) {
        best = b;
        bestDt = dt;
      }
    }

    return best;
  }

  String _formatBookingDate(String raw) {
    final v = raw.trim();
    final dt = DateTime.tryParse(v);
    if (dt == null) return v.isEmpty ? '-' : v;
    String two(int n) => n.toString().padLeft(2, '0');
    return '${dt.year}-${two(dt.month)}-${two(dt.day)}  ${two(dt.hour)}:${two(dt.minute)}';
  }

  Color _statusBg(String status) {
    final s = status.trim().toLowerCase();
    if (s.contains('cancel') || s.contains('رفض') || s.contains('ملغي')) return const Color(0xFFFFE5E5);
    if (s.contains('done') || s.contains('completed') || s.contains('تم')) return const Color(0xFFE8FFF3);
    if (s.contains('pending') || s.contains('معلق') || s.contains('انتظار')) return const Color(0xFFFFF7E6);
    return AppColors.brandPrimarySoft2;
  }

  Color _statusFg(String status) {
    final s = status.trim().toLowerCase();
    if (s.contains('cancel') || s.contains('رفض') || s.contains('ملغي')) return const Color(0xFFB42318);
    if (s.contains('done') || s.contains('completed') || s.contains('تم')) return const Color(0xFF16A34A);
    if (s.contains('pending') || s.contains('معلق') || s.contains('انتظار')) return const Color(0xFFB45309);
    return AppColors.brandPrimary;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BookingsCubit, BookingsState>(
      builder: (context, state) {
        if (state is BookingsLoading) {
          return const SizedBox(
            height: 90,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (state is BookingsError) {
          return AppCard(
            padding: const EdgeInsets.all(16),
            backgroundColor: Colors.white,
            borderRadius: 0,
            borderColor: Colors.grey.shade300,
            boxShadow: const [
              BoxShadow(
                color: Color(0x1F000000),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
            child: Text(
              Toasters.displayMessage(state.message),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
          );
        }

        final bookings = state is BookingsSuccess ? state.bookings : const <Booking>[];
        final last = _latestBooking(bookings);

        if (last == null) {
          return AppCard(
            padding: const EdgeInsets.all(16),
            backgroundColor: Colors.white,
            borderRadius: 0,
            borderColor: Colors.grey.shade300,
            boxShadow: const [
              BoxShadow(
                color: Color(0x1F000000),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
            child: Row(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.zero,
                  ),
                  child: Icon(Icons.event_busy, color: Colors.grey.shade600, size: 34),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    t(context, 'home.no_bookings_yet', ar: 'لا توجد حجوزات بعد', en: 'No bookings yet'),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Colors.black54,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        final status = last.bookingStatus.trim().isEmpty ? '-' : last.bookingStatus.trim();
        final service = last.service.trim().isEmpty ? '-' : last.service.trim();
        final branch = (last.location ?? '').trim().isEmpty ? '-' : (last.location ?? '').trim();
        final dateText = _formatBookingDate(last.bookingStart);
        final bookingNo = (last.jobSheetNo ?? '').trim().isEmpty ? '-' : (last.jobSheetNo ?? '').trim();
        final carText = '${last.brand} ${last.model}'.trim().isEmpty ? '-' : '${last.brand} ${last.model}'.trim();

        final bg = _statusBg(status);
        final fg = _statusFg(status);

        return AppCard(
          padding: const EdgeInsets.all(12),
          backgroundColor: Colors.white,
          borderRadius: 0,
          borderColor: Colors.grey.shade300,
          boxShadow: const [
            BoxShadow(
              color: Color(0x1F000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      t(context, 'home.last_booking_title', ar: 'آخر حجز', en: 'Last booking'),
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.black),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.zero,
                    ),
                    child: Text(
                      status,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: fg),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _CompactInfoCell(
                      icon: Icons.directions_car_filled_outlined,
                      label: t(context, 'home.label_car', ar: 'السيارة', en: 'Car'),
                      value: carText,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _CompactInfoCell(
                      icon: Icons.confirmation_number_outlined,
                      label: t(context, 'home.label_booking_no', ar: 'رقم الحجز', en: 'Booking no.'),
                      value: bookingNo,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: _CompactInfoCell(
                      icon: Icons.build_circle_outlined,
                      label: t(context, 'home.label_service', ar: 'الخدمة', en: 'Service'),
                      value: service,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _CompactInfoCell(
                      icon: Icons.location_on_outlined,
                      label: t(context, 'home.label_branch', ar: 'الفرع', en: 'Branch'),
                      value: branch,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              _CompactInfoRow(
                icon: Icons.calendar_today_outlined,
                label: t(context, 'home.label_date', ar: 'التاريخ', en: 'Date'),
                value: dateText,
              ),
              const SizedBox(height: 2),
            ],
          ),
        );
      },
    );
  }
}

class _CompactInfoRow extends StatelessWidget {
  const _CompactInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.black54),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: Colors.black54,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: Colors.black,
              height: 1.2,
            ),
          ),
        ),
      ],
    );
  }
}

class _CompactInfoCell extends StatelessWidget {
  const _CompactInfoCell({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.zero,
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.black54),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
