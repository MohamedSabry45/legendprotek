import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/datasources/job_order_details_remote_datasource.dart';
import '../../../data/models/job_order_details_response_model.dart';
import '../../../data/models/job_order_status_model.dart';
import 'job_order_details_state.dart';

class JobOrderDetailsCubit extends Cubit<JobOrderDetailsState> {
  JobOrderDetailsCubit() : super(JobOrderDetailsInitial());

  static JobOrderDetailsCubit get(context) =>
      BlocProvider.of<JobOrderDetailsCubit>(context);

  late final JobOrderDetailsRemoteDataSource _remote =
      JobOrderDetailsRemoteDataSource();

  Future<void> load({
    required int jobOrderId,
    required String phoneLast4,
  }) async {
    emit(JobOrderDetailsLoading());
    try {
      final JobOrderDetailsResponseModel details = await _remote
          .getJobOrderDetails(jobOrderId: jobOrderId, phoneLast4: phoneLast4);
      final List<JobOrderStatusModel> statuses = await _remote.getStatuses();

      if (isClosed) return;
      emit(JobOrderDetailsSuccess(details: details, statuses: statuses));
    } catch (e) {
      if (isClosed) return;
      emit(JobOrderDetailsError(e.toString()));
    }
  }

  Future<String> approveProducts({
    required int jobOrderId,
    required List<int> productIds,
    String? token,
  }) {
    return _remote.saveProduct(
      jobOrderId: jobOrderId,
      productIds: productIds,
      token: token,
    );
  }
}
