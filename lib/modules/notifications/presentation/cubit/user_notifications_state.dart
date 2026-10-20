import 'package:reservation_workshop/modules/notifications/data/models/user_notification_model.dart';

abstract class UserNotificationsState {
  const UserNotificationsState();
}

class UserNotificationsInitial extends UserNotificationsState {
  const UserNotificationsInitial();
}

class UserNotificationsLoading extends UserNotificationsState {
  const UserNotificationsLoading();
}

class UserNotificationsSuccess extends UserNotificationsState {
  const UserNotificationsSuccess({
    required this.notifications,
    required this.currentPage,
    required this.lastPage,
    required this.total,
    this.isLoadingMore = false,
  });

  final List<UserNotificationModel> notifications;
  final int currentPage;
  final int lastPage;
  final int total;
  final bool isLoadingMore;

  bool get hasMore => currentPage < lastPage;
  int get unreadCount => notifications.where((n) => !n.isRead).length;

  UserNotificationsSuccess copyWith({
    List<UserNotificationModel>? notifications,
    int? currentPage,
    int? lastPage,
    int? total,
    bool? isLoadingMore,
  }) {
    return UserNotificationsSuccess(
      notifications: notifications ?? this.notifications,
      currentPage: currentPage ?? this.currentPage,
      lastPage: lastPage ?? this.lastPage,
      total: total ?? this.total,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

class UserNotificationsError extends UserNotificationsState {
  const UserNotificationsError(this.message);

  final String message;
}
