import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:reservation_workshop/core/components/toasters.dart';
import 'package:reservation_workshop/core/widgets/login_required_view.dart';
import 'package:reservation_workshop/modules/bookings/presentation/cubits/add_booking_cubit/add_booking_cubit.dart';
import 'package:reservation_workshop/modules/bookings/presentation/cubits/add_booking_cubit/add_booking_state.dart';
import 'package:reservation_workshop/modules/main/presentation/screens/booking_details_args.dart';
import 'package:reservation_workshop/modules/main/presentation/widgets/notification_card.dart';
import 'package:reservation_workshop/modules/main/presentation/widgets/booking_details_card.dart';

class BookingDetailsScreen extends StatelessWidget {
  const BookingDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;

    final BookingDetailsArgs? bookingArgs = args is BookingDetailsArgs
        ? args
        : null;
    final NotificationCardModel? model =
        bookingArgs?.model ?? (args is NotificationCardModel ? args : null);

    final canConfirm = bookingArgs != null;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Text(
          'booking.details_title'.tr(),
          style: const TextStyle(
            color: Color(0xFFD4AF37),
            fontWeight: FontWeight.w900,
          ),
        ),
        foregroundColor: const Color(0xFFD4AF37),
        iconTheme: const IconThemeData(color: Color(0xFFD4AF37)),
      ),
      body: BlocConsumer<AddBookingCubit, AddBookingState>(
        listener: (context, state) {
          if (state is AddBookingSuccess) {
            Toasters.success('booking.create_success'.tr());
            Navigator.pop(context, true);
          }
          if (state is AddBookingError) {
            Toasters.errorFrom(
              state.message,
              fallbackKey: 'booking.create_failed',
            );
          }
        },
        builder: (context, state) {
          if (state is AddBookingGuestNotAllowed) {
            return const LoginRequiredView();
          }
          final isLoading = state is AddBookingLoading;

          return SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: BookingDetailsCard(
                      model: model,
                      canConfirm: canConfirm,
                      onBack: () => Navigator.pop(context),
                      onConfirm: () {
                        if (!canConfirm || bookingArgs == null) {
                          return;
                        }
                        if (isLoading) {
                          return;
                        }

                        context.read<AddBookingCubit>().addBooking(
                          bookingStart: bookingArgs.bookingStart,
                          locationId: bookingArgs.locationId,
                          bookingNote: bookingArgs.bookingNote,
                          serviceId: bookingArgs.serviceId,
                          deviceId: bookingArgs.deviceId,
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
