import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:reservation_workshop/core/network/local/cache_helper.dart';
import 'package:reservation_workshop/core/utils/strings/prefkeys.dart';

import 'package:reservation_workshop/modules/menu/data/datasources/business_location_remote_datasource.dart';
import 'package:reservation_workshop/modules/menu/data/models/business_location_model.dart';

import 'business_location_state.dart';

class BusinessLocationCubit extends Cubit<BusinessLocationState> {
  BusinessLocationCubit() : super(BusinessLocationInitial());

  static BusinessLocationCubit get(context) =>
      BlocProvider.of<BusinessLocationCubit>(context);

  final BusinessLocationRemoteDataSource _remote =
      BusinessLocationRemoteDataSource();
  BusinessLocation? _cachedLocation;

  BusinessLocation? get cachedLocation => _cachedLocation;

  Future<bool> _isGuestMode() async {
    return await CacheHelper.getDataAsync<bool>(key: PrefKeys.kIsGuestMode) ??
        false;
  }

  void _safeEmit(BusinessLocationState state) {
    if (isClosed) return;
    try {
      emit(state);
    } on StateError {
      return;
    }
  }

  Future<void> fetchBusinessLocation() async {
    if (isClosed) return;
    if (_cachedLocation != null) {
      _safeEmit(BusinessLocationSuccess(_cachedLocation!));
      return;
    }

    _safeEmit(BusinessLocationLoading());
    try {
      if (await _isGuestMode()) {
        _safeEmit(
          BusinessLocationError('Guest mode - contact info not available'),
        );
        return;
      }
      final location = await _remote.getBusinessLocation();
      _cachedLocation = location;
      if (isClosed) return;
      _safeEmit(BusinessLocationSuccess(location));
    } catch (e) {
      if (isClosed) return;
      _safeEmit(BusinessLocationError(e.toString()));
    }
  }

  void clearCache() {
    _cachedLocation = null;
  }
}
