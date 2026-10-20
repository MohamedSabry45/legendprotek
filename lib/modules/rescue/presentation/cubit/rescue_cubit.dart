import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:reservation_workshop/core/network/local/cache_helper.dart';
import 'package:reservation_workshop/core/utils/strings/prefkeys.dart';
import 'package:reservation_workshop/modules/branch/data/datasources/branch_remote_datasource.dart';
import 'package:reservation_workshop/modules/branch/data/models/branch_model.dart';
import 'package:reservation_workshop/modules/branch/domain/entities/branch.dart';
import 'package:reservation_workshop/modules/service/data/models/service_model.dart';
import 'package:reservation_workshop/modules/customer/presentation/cubits/customer_info_cubit/customer_info_cubit.dart';
import 'package:reservation_workshop/modules/customer/presentation/cubits/customer_info_cubit/customer_info_state.dart';
import 'package:reservation_workshop/modules/service/data/datasources/service_remote_datasource.dart';
import 'package:reservation_workshop/modules/service/domain/entities/service.dart';

import '../../data/datasources/rescue_remote_datasource.dart';
import '../../data/models/pickup_request_model.dart';
import 'rescue_state.dart';

class RescueCubit extends Cubit<RescueState> {
  RescueCubit() : super(RescueInitial());

  late final RescueRemoteDataSource _remote = RescueRemoteDataSource();
  late final BranchRemoteDataSource _branchRemote = BranchRemoteDataSource();
  late final ServiceRemoteDataSource _serviceRemote = ServiceRemoteDataSource();

  Future<bool> _isGuestMode() async {
    return await CacheHelper.getDataAsync<bool>(key: PrefKeys.kIsGuestMode) ??
        false;
  }

  Future<void> load({required CustomerInfoCubit customerInfoCubit}) async {
    if (isClosed) return;
    emit(RescueLoading());
    try {
      final isGuest = await _isGuestMode();
      if (customerInfoCubit.state is! CustomerInfoSuccess) {
        await customerInfoCubit.load();
      }

      final customerState = customerInfoCubit.state;
      if (customerState is! CustomerInfoSuccess) {
        throw Exception('Failed to load customer info');
      }

      final cars = customerState.info.cars;
      final branches = isGuest ? <Branch>[] : await _branchRemote.getBranches();

      if (isClosed) return;
      emit(
        RescueLoaded(
          cars: cars,
          branches: branches,
          services: const [],
          isSubmitting: false,
          isGuest: isGuest,
        ),
      );
    } catch (e) {
      if (isClosed) return;
      emit(RescueError(e.toString()));
    }
  }

  Future<void> loadServices({required int locationId}) async {
    final current = state;
    if (current is! RescueLoaded) return;

    try {
      final services = await _isGuestMode()
          ? <Service>[]
          : await _serviceRemote.getServices(locationId: locationId);
      if (isClosed) return;
      emit(
        RescueLoaded(
          cars: current.cars,
          branches: current.branches,
          services: services,
          isSubmitting: current.isSubmitting,
          isGuest: current.isGuest,
        ),
      );
    } catch (e) {
      if (isClosed) return;
      emit(RescueError(e.toString()));
    }
  }

  Future<void> submit({required PickupRequestModel request}) async {
    if (await _isGuestMode()) {
      if (isClosed) return;
      emit(RescueGuestNotAllowed());
      return;
    }
    final current = state;
    if (current is! RescueLoaded) return;

    if (isClosed) return;
    emit(
      RescueLoaded(
        cars: current.cars,
        branches: current.branches,
        services: current.services,
        isSubmitting: true,
        isGuest: current.isGuest,
      ),
    );

    try {
      final res = await _remote.customerPickupRequest(request: request);
      if (res.success) {
        if (isClosed) return;
        emit(RescueSuccess(res.message));
      } else {
        if (isClosed) return;
        emit(RescueError(res.message));
      }
    } catch (e) {
      if (isClosed) return;
      emit(RescueError(e.toString()));
    }
  }
}
