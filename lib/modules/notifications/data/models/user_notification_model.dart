class UserNotificationModel {
  UserNotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.userId,
    this.referenceId,
    this.isRead = false,
    this.readAt,
    this.data,
    this.createdAt,
  });

  final String id;
  final int? userId;
  final String type;
  final String title;
  final String body;
  final int? referenceId;
  final bool isRead;
  final String? readAt;
  final Map<String, dynamic>? data;
  final String? createdAt;

  UserNotificationModel copyWith({
    bool? isRead,
    String? readAt,
  }) {
    return UserNotificationModel(
      id: id,
      type: type,
      title: title,
      body: body,
      userId: userId,
      referenceId: referenceId,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      data: data,
      createdAt: createdAt,
    );
  }

  factory UserNotificationModel.fromJson(Map<String, dynamic> json) {
    int? toInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      return int.tryParse(v.toString());
    }

    final readAt = json['read_at']?.toString();
    final isRead = json['is_read'] == true ||
        json['is_read']?.toString() == 'true' ||
        (readAt != null && readAt.trim().isNotEmpty);

    return UserNotificationModel(
      id: json['id']?.toString() ?? '',
      userId: toInt(json['user_id']),
      type: json['type']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      referenceId: toInt(json['reference_id']),
      isRead: isRead,
      readAt: readAt,
      data: (json['data'] is Map)
          ? Map<String, dynamic>.from(json['data'] as Map)
          : null,
      createdAt: json['created_at']?.toString(),
    );
  }
}

class UserNotificationsPage {
  UserNotificationsPage({
    required this.notifications,
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  final List<UserNotificationModel> notifications;
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  bool get hasMore => currentPage < lastPage;

  factory UserNotificationsPage.fromJson(Map<String, dynamic> json) {
    int toInt(dynamic v, {int fallback = 0}) {
      if (v is int) return v;
      return int.tryParse(v?.toString() ?? '') ?? fallback;
    }

    final meta = (json['meta'] is Map)
        ? Map<String, dynamic>.from(json['meta'] as Map)
        : const <String, dynamic>{};

    final items = (json['data'] is List)
        ? (json['data'] as List)
            .whereType<Map>()
            .map(
              (e) => UserNotificationModel.fromJson(
                Map<String, dynamic>.from(e),
              ),
            )
            .toList()
        : const <UserNotificationModel>[];

    return UserNotificationsPage(
      notifications: items,
      currentPage: toInt(meta['current_page'], fallback: 1),
      lastPage: toInt(meta['last_page'], fallback: 1),
      perPage: toInt(meta['per_page'], fallback: 20),
      total: toInt(meta['total'], fallback: items.length),
    );
  }
}
