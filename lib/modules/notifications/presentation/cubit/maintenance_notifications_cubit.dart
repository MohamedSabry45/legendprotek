import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:reservation_workshop/core/network/local/cache_helper.dart';
import 'package:reservation_workshop/core/utils/strings/prefkeys.dart';

import 'package:reservation_workshop/modules/notifications/data/datasources/maintenance_notifications_remote_datasource.dart';
import 'package:reservation_workshop/modules/notifications/presentation/cubit/maintenance_notifications_state.dart';

class MaintenanceNotificationsCubit extends Cubit<MaintenanceNotificationsState> {
  MaintenanceNotificationsCubit() : super(const MaintenanceNotificationsInitial());

  late final MaintenanceNotificationsRemoteDataSource _remote = MaintenanceNotificationsRemoteDataSource();

  Future<bool> _isGuestMode() async {
    return await CacheHelper.getDataAsync<bool>(key: PrefKeys.kIsGuestMode) ?? false;
  }

  Future<void> load({String status = 'all'}) async {
    emit(const MaintenanceNotificationsLoading());
    try {
      if (await _isGuestMode()) {
        if (isClosed) return;
        emit(MaintenanceNotificationsSuccess([]));
        return;
      }
      final items = await _remote.getMaintenanceNotifications(status: status);
      if (isClosed) return;
      emit(MaintenanceNotificationsSuccess(items));
    } catch (e) {
      if (isClosed) return;
      emit(MaintenanceNotificationsError(e.toString()));
    }
  }

  Future<void> refresh() => load(status: 'all');

  Future<void> markRead({required List<String> notificationIds}) async {
    if (notificationIds.isEmpty) return;

    try {
      await _remote.markRead(notificationIds: notificationIds);
      if (isClosed) return;
      await refresh();
    } catch (e) {
      if (isClosed) return;
      emit(MaintenanceNotificationsError(e.toString()));
    }
  }

  Future<void> markAllRead() async {
    try {
      await _remote.markAllRead();
      if (isClosed) return;
      await refresh();
    } catch (e) {
      if (isClosed) return;
      emit(MaintenanceNotificationsError(e.toString()));
    }
  }
}
