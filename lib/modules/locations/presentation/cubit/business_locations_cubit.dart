import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:reservation_workshop/core/network/local/cache_helper.dart';
import 'package:reservation_workshop/core/utils/strings/prefkeys.dart';

import '../../data/datasources/business_locations_remote_datasource.dart';
import 'business_locations_state.dart';

class BusinessLocationsCubit extends Cubit<BusinessLocationsState> {
  BusinessLocationsCubit() : super(BusinessLocationsInitial());

  static BusinessLocationsCubit get(context) => BlocProvider.of<BusinessLocationsCubit>(context);

  late final BusinessLocationsRemoteDataSource _remote = BusinessLocationsRemoteDataSource();

  Future<bool> _isGuestMode() async {
    return await CacheHelper.getDataAsync<bool>(key: PrefKeys.kIsGuestMode) ?? false;
  }

  Future<void> load() async {
    if (isClosed) return;
    emit(BusinessLocationsLoading());
    try {
      if (await _isGuestMode()) {
        if (isClosed) return;
        emit(BusinessLocationsSuccess([]));
        return;
      }
      final items = await _remote.getBusinessLocations();
      if (isClosed) return;
      emit(BusinessLocationsSuccess(items));
    } catch (e) {
      if (isClosed) return;
      emit(BusinessLocationsError(e.toString()));
    }
  }
}
