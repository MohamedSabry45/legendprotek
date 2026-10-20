import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:reservation_workshop/core/network/local/cache_helper.dart';
import 'package:reservation_workshop/core/utils/strings/prefkeys.dart';

import 'package:reservation_workshop/modules/notifications/data/datasources/user_notifications_remote_datasource.dart';
import 'package:reservation_workshop/modules/notifications/data/models/user_notification_model.dart';
import 'package:reservation_workshop/modules/notifications/presentation/cubit/user_notifications_state.dart';

class UserNotificationsCubit extends Cubit<UserNotificationsState> {
  UserNotificationsCubit() : super(const UserNotificationsInitial());

  late final UserNotificationsRemoteDataSource _remote =
      UserNotificationsRemoteDataSource();

  bool _mutating = false;

  Future<bool> _isGuestMode() async {
    return await CacheHelper.getDataAsync<bool>(
          key: PrefKeys.kIsGuestMode,
        ) ??
        false;
  }

  Future<void> load({String? type, bool? isRead}) async {
    emit(const UserNotificationsLoading());
    try {
      if (await _isGuestMode()) {
        if (isClosed) return;
        emit(
          const UserNotificationsSuccess(
            notifications: [],
            currentPage: 1,
            lastPage: 1,
            total: 0,
          ),
        );
        return;
      }
      final page = await _remote.getUserNotifications(
        page: 1,
        perPage: 20,
        type: type,
        isRead: isRead,
      );
      if (isClosed) return;
      emit(
        UserNotificationsSuccess(
          notifications: page.notifications,
          currentPage: page.currentPage,
          lastPage: page.lastPage,
          total: page.total,
        ),
      );
    } catch (e) {
      if (isClosed) return;
      emit(UserNotificationsError(e.toString()));
    }
  }

  Future<void> refresh() => load();

  Future<void> loadMore({String? type, bool? isRead}) async {
    final s = state;
    if (s is! UserNotificationsSuccess || !s.hasMore || s.isLoadingMore) {
      return;
    }

    emit(s.copyWith(isLoadingMore: true));
    try {
      final page = await _remote.getUserNotifications(
        page: s.currentPage + 1,
        perPage: 20,
        type: type,
        isRead: isRead,
      );

      if (isClosed) return;
      final existingIds = s.notifications.map((e) => e.id).toSet();
      final merged = <UserNotificationModel>[
        ...s.notifications,
        ...page.notifications.where((n) => !existingIds.contains(n.id)),
      ];

      emit(
        UserNotificationsSuccess(
          notifications: merged,
          currentPage: page.currentPage,
          lastPage: page.lastPage,
          total: page.total,
        ),
      );
    } catch (_) {
      if (isClosed) return;
      emit(s.copyWith(isLoadingMore: false));
    }
  }

  Future<void> markRead(String id) async {
    if (_mutating) return;
    _mutating = true;
    try {
      await _remote.markRead(id);
      if (isClosed) return;
      final s = state;
      if (s is UserNotificationsSuccess) {
        emit(
          s.copyWith(
            notifications: s.notifications
                .map(
                  (n) => n.id == id
                      ? n.copyWith(
                          isRead: true,
                          readAt: n.readAt ??
                              DateTime.now().toUtc().toIso8601String(),
                        )
                      : n,
                )
                .toList(),
          ),
        );
      }
    } catch (_) {
    } finally {
      _mutating = false;
    }
  }

  Future<void> markAllRead() async {
    try {
      await _remote.markAllRead();
      if (isClosed) return;
      final s = state;
      if (s is UserNotificationsSuccess) {
        emit(
          s.copyWith(
            notifications: s.notifications
                .map((n) => n.copyWith(isRead: true))
                .toList(),
          ),
        );
      }
    } catch (e) {
      if (isClosed) return;
      emit(UserNotificationsError(e.toString()));
    }
  }

  Future<void> remove(String id) async {
    try {
      await _remote.deleteNotification(id);
      if (isClosed) return;
      final s = state;
      if (s is UserNotificationsSuccess) {
        emit(
          s.copyWith(
            notifications:
                s.notifications.where((n) => n.id != id).toList(),
            total: s.total > 0 ? s.total - 1 : 0,
          ),
        );
      }
    } catch (_) {}
  }
}
