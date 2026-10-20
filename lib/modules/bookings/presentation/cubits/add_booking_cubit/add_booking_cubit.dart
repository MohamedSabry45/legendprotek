import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:reservation_workshop/core/network/local/cache_helper.dart';
import 'package:reservation_workshop/core/utils/strings/prefkeys.dart';

import '../../../data/datasources/add_booking_remote_datasource.dart';
import 'add_booking_state.dart';

class AddBookingCubit extends Cubit<AddBookingState> {
  AddBookingCubit() : super(AddBookingInitial());

  static AddBookingCubit get(context) => BlocProvider.of<AddBookingCubit>(context);

  late final AddBookingRemoteDataSource _remote = AddBookingRemoteDataSource();

  Future<bool> _isGuestMode() async {
    return await CacheHelper.getDataAsync<bool>(key: PrefKeys.kIsGuestMode) ?? false;
  }

  Future<void> addBooking({
    required String bookingStart,
    required int locationId,
    required String bookingNote,
    required int serviceId,
    required int deviceId,
  }) async {
    if (await _isGuestMode()) {
      if (isClosed) return;
      emit(AddBookingGuestNotAllowed());
      return;
    }
    if (isClosed) return;
    emit(AddBookingLoading());
    try {
      final msg = await _remote.addBooking(
        bookingStart: bookingStart,
        locationId: locationId,
        bookingNote: bookingNote,
        serviceId: serviceId,
        deviceId: deviceId,
      );
      if (isClosed) return;
      emit(AddBookingSuccess(msg));
    } catch (e) {
      if (isClosed) return;
      emit(AddBookingError(e.toString()));
    }
  }
}
