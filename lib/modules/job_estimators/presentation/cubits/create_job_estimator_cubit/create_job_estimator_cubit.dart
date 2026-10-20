import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/datasources/create_job_estimator_remote_datasource.dart';
import 'create_job_estimator_state.dart';

class CreateJobEstimatorCubit extends Cubit<CreateJobEstimatorState> {
  CreateJobEstimatorCubit() : super(CreateJobEstimatorInitial());

  final CreateJobEstimatorRemoteDataSource _remote = CreateJobEstimatorRemoteDataSource();

  Future<void> create({
    required int contactId,
    required int deviceId,
    required int locationId,
    int? serviceTypeId,
    String? vehicleDetails,
    num? amount,
    int sendNotificationValue = 0,
  }) async {
    emit(CreateJobEstimatorLoading());
    try {
      final res = await _remote.createJobEstimator(
        contactId: contactId,
        deviceId: deviceId,
        locationId: locationId,
        serviceTypeId: serviceTypeId,
        vehicleDetails: vehicleDetails,
        amount: amount,
        sendNotificationValue: sendNotificationValue,
      );

      if (isClosed) return;
      emit(
        CreateJobEstimatorSuccess(
          id: res.id,
          estimateNo: res.estimateNo,
        ),
      );
    } catch (e) {
      if (isClosed) return;
      emit(CreateJobEstimatorError(e.toString()));
    }
  }
}
