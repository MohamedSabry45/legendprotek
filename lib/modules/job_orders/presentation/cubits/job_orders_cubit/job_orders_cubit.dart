import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:reservation_workshop/core/network/local/cache_helper.dart';
import 'package:reservation_workshop/core/utils/strings/prefkeys.dart';

import '../../../data/datasources/job_orders_remote_datasource.dart';
import 'job_orders_state.dart';

class JobOrdersCubit extends Cubit<JobOrdersState> {
  JobOrdersCubit() : super(JobOrdersInitial());

  static JobOrdersCubit get(context) => BlocProvider.of<JobOrdersCubit>(context);

  late final JobOrdersRemoteDataSource _remote = JobOrdersRemoteDataSource();

  Future<bool> _isGuestMode() async {
    return await CacheHelper.getDataAsync<bool>(key: PrefKeys.kIsGuestMode) ?? false;
  }

  Future<void> load() async {
    if (isClosed) return;
    emit(JobOrdersLoading());
    try {
      if (await _isGuestMode()) {
        if (isClosed) return;
        emit(JobOrdersSuccess([]));
        return;
      }
      final orders = await _remote.getCustomerJobOrders();
      if (isClosed) return;
      emit(JobOrdersSuccess(orders));
    } catch (e) {
      if (isClosed) return;
      emit(JobOrdersError(e.toString()));
    }
  }
}
