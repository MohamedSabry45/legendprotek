import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:reservation_workshop/core/network/local/cache_helper.dart';
import 'package:reservation_workshop/core/utils/strings/prefkeys.dart';

import '../../data/datasources/job_estimators_remote_datasource.dart';
import '../../data/models/job_estimator_model.dart';
import 'job_estimators_state.dart';

class JobEstimatorsCubit extends Cubit<JobEstimatorsState> {
  JobEstimatorsCubit() : super(JobEstimatorsInitial());

  static JobEstimatorsCubit of(context) => BlocProvider.of<JobEstimatorsCubit>(context);

  final JobEstimatorsRemoteDataSource _remote = JobEstimatorsRemoteDataSource();

  Future<bool> _isGuestMode() async {
    return await CacheHelper.getDataAsync<bool>(key: PrefKeys.kIsGuestMode) ?? false;
  }

  Future<void> load({required int customerId}) async {
    emit(JobEstimatorsLoading());
    try {
      if (await _isGuestMode()) {
        if (isClosed) return;
        emit(JobEstimatorsSuccess([]));
        return;
      }
      final List<JobEstimatorModel> list = await _remote.getJobEstimators(customerId: customerId);
      if (isClosed) return;
      emit(JobEstimatorsSuccess(list));
    } catch (e) {
      if (isClosed) return;
      emit(JobEstimatorsError(e.toString()));
    }
  }
}
