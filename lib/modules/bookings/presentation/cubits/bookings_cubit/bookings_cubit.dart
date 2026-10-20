import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:reservation_workshop/core/network/local/cache_helper.dart';
import 'package:reservation_workshop/core/utils/strings/prefkeys.dart';

import '../../../data/datasources/bookings_remote_datasource.dart';
import 'bookings_state.dart';

class BookingsCubit extends Cubit<BookingsState> {
  BookingsCubit() : super(BookingsInitial());

  static BookingsCubit get(context) => BlocProvider.of<BookingsCubit>(context);

  late final BookingsRemoteDataSource _remote = BookingsRemoteDataSource();

  Future<bool> _isGuestMode() async {
    return await CacheHelper.getDataAsync<bool>(key: PrefKeys.kIsGuestMode) ?? false;
  }

  Future<void> load() async {
    if (isClosed) return;
    emit(BookingsLoading());
    try {
      if (await _isGuestMode()) {
        if (isClosed) return;
        emit(BookingsSuccess(const []));
        return;
      }
      final bookings = await _remote.getCustomerBookings();
      if (isClosed) return;
      emit(BookingsSuccess(bookings));
    } catch (e) {
      if (isClosed) return;
      emit(BookingsError(e.toString()));
    }
  }
}
