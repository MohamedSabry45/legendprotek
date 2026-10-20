import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:reservation_workshop/core/network/local/cache_helper.dart';
import 'package:reservation_workshop/core/utils/strings/prefkeys.dart';

import '../../../data/datasources/branch_remote_datasource.dart';
import 'branch_state.dart';

class BranchCubit extends Cubit<BranchState> {
  BranchCubit() : super(BranchInitial());

  static BranchCubit get(context) => BlocProvider.of<BranchCubit>(context);

  late final BranchRemoteDataSource _remote = BranchRemoteDataSource();

  Future<bool> _isGuestMode() async {
    return await CacheHelper.getDataAsync<bool>(key: PrefKeys.kIsGuestMode) ?? false;
  }

  Future<void> load() async {
    if (isClosed) return;
    emit(BranchLoading());
    try {
      if (await _isGuestMode()) {
        if (isClosed) return;
        emit(BranchSuccess([]));
        return;
      }
      final branches = await _remote.getBranches();
      if (isClosed) return;
      emit(BranchSuccess(branches));
    } catch (e) {
      if (isClosed) return;
      emit(BranchError(e.toString()));
    }
  }
}
