import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/datasources/job_estimators_remote_datasource.dart';
import 'job_estimator_details_state.dart';

class JobEstimatorDetailsCubit extends Cubit<JobEstimatorDetailsState> {
  JobEstimatorDetailsCubit() : super(JobEstimatorDetailsInitial());

  static JobEstimatorDetailsCubit get(context) =>
      BlocProvider.of<JobEstimatorDetailsCubit>(context);

  final JobEstimatorsRemoteDataSource _remote = JobEstimatorsRemoteDataSource();

  Future<void> load({required int id, required String phoneLast4}) async {
    emit(JobEstimatorDetailsLoading());
    try {
      final data = await _remote.getJobEstimatorDetails(
        id: id,
        phoneLast4: phoneLast4,
      );
      if (isClosed) return;
      emit(JobEstimatorDetailsSuccess(data ?? const <String, dynamic>{}));
    } catch (e) {
      if (isClosed) return;
      emit(JobEstimatorDetailsError(e.toString()));
    }
  }

  Future<String> approveProducts({
    required int estimatorId,
    required List<int> productIds,
  }) async {
    final res = await _remote.saveEstimatorProducts(
      estimatorId: estimatorId,
      productIds: productIds,
    );
    final msg = res?['message']?.toString();
    if (msg == null || msg.trim().isEmpty) {
      throw Exception('Request failed');
    }
    return msg;
  }
}
