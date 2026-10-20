import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:reservation_workshop/constants/app_constants.dart';
import 'package:reservation_workshop/core/network/local/cache_helper.dart';
import 'package:reservation_workshop/core/utils/strings/prefkeys.dart';
import 'package:reservation_workshop/modules/notifications/data/datasources/user_notifications_remote_datasource.dart';

class UserNotificationsBadgeCubit extends Cubit<int> {
  UserNotificationsBadgeCubit() : super(0);

  late final UserNotificationsRemoteDataSource _remote =
      UserNotificationsRemoteDataSource();

  Timer? _timer;
  bool _polling = false;

  void start() {
    _timer ??= Timer.periodic(
      const Duration(seconds: 15),
      (_) => refresh(),
    );
    refresh();
  }

  Future<void> refresh() async {
    if (_polling) return;
    _polling = true;
    try {
      final token = AppConstants.token ??
          CacheHelper.getData<String>(key: PrefKeys.kAccessToken);
      if (token == null || token.trim().isEmpty) {
        if (isClosed) return;
        emit(0);
        return;
      }
      final count = await _remote.getUnreadCount();
      if (isClosed) return;
      emit(count);
    } catch (_) {
    } finally {
      _polling = false;
    }
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  Future<void> close() {
    stop();
    return super.close();
  }
}
