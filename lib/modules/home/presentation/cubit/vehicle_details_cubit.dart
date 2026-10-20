import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/datasources/vehicle_details_remote_datasource.dart';
import 'vehicle_details_state.dart';

class VehicleDetailsCubit extends Cubit<VehicleDetailsState> {
  VehicleDetailsCubit({required this.id}) : super(VehicleDetailsInitial());

  final int id;
  late final VehicleDetailsRemoteDataSource _remote = VehicleDetailsRemoteDataSource();

  Future<void> load() async {
    if (isClosed) return;
    emit(VehicleDetailsLoading());
    try {
      final details = await _remote.getVehicleDetails(id: id);
      if (isClosed) return;
      emit(VehicleDetailsSuccess(details));
    } catch (e) {
      if (isClosed) return;
      emit(VehicleDetailsError(e.toString()));
    }
  }
}
