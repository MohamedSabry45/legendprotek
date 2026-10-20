import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:reservation_workshop/constants/app_constants.dart';
import 'package:reservation_workshop/core/network/api_endpoints.dart';
import 'package:reservation_workshop/core/network/local/cache_helper.dart';
import 'package:reservation_workshop/core/utils/strings/prefkeys.dart';
import 'package:reservation_workshop/modules/notifications/data/models/user_notification_model.dart';

class UserNotificationsRemoteDataSource {
  final http.Client _client;

  UserNotificationsRemoteDataSource({http.Client? client})
      : _client = client ?? http.Client();

  String _token() {
    final token = AppConstants.token ??
        CacheHelper.getData<String>(key: PrefKeys.kAccessToken);
    if (token == null || token.trim().isEmpty) {
      throw Exception('Unauthorized');
    }
    return token;
  }

  Map<String, String> _headers({bool withBody = false}) => <String, String>{
        'Authorization': 'Bearer ${_token()}',
        'Accept': 'application/json',
        if (withBody) 'Content-Type': 'application/json',
      };

  Future<UserNotificationsPage> getUserNotifications({
    int page = 1,
    int perPage = 20,
    String? type,
    bool? isRead,
    String? afterId,
  }) async {
    final baseUrl = AppConstants.kBaseUrl.trim();

    final params = <String, String>{
      'page': page.toString(),
      'per_page': perPage.clamp(1, 100).toString(),
      if (type != null && type.trim().isNotEmpty) 'type': type.trim(),
      if (isRead != null) 'is_read': isRead ? 'true' : 'false',
      if (afterId != null && afterId.trim().isNotEmpty)
        'after_id': afterId.trim(),
    };

    final uri =
        Uri.parse('$baseUrl${ApiEndpoints.userNotifications}').replace(
      queryParameters: params,
    );

    final res = await _client.get(uri, headers: _headers());
    final decoded = _decodeJson(res.body);

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Request failed');
    }

    if (decoded is Map) {
      return UserNotificationsPage.fromJson(
        Map<String, dynamic>.from(decoded),
      );
    }

    return UserNotificationsPage(
      notifications: const [],
      currentPage: 1,
      lastPage: 1,
      perPage: perPage,
      total: 0,
    );
  }

  Future<int> getUnreadCount() async {
    final baseUrl = AppConstants.kBaseUrl.trim();
    final uri =
        Uri.parse('$baseUrl${ApiEndpoints.userNotificationsUnreadCount}');

    final res = await _client.get(uri, headers: _headers());
    final decoded = _decodeJson(res.body);

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Request failed');
    }

    if (decoded is Map && decoded['unread_count'] != null) {
      return int.tryParse(decoded['unread_count'].toString()) ?? 0;
    }

    return 0;
  }

  Future<void> markRead(String id) async {
    final baseUrl = AppConstants.kBaseUrl.trim();
    final uri =
        Uri.parse('$baseUrl${ApiEndpoints.userNotificationRead(id: id)}');

    final res = await _client.patch(uri, headers: _headers(withBody: true));

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Request failed');
    }
  }

  Future<void> markAllRead() async {
    final baseUrl = AppConstants.kBaseUrl.trim();
    final uri = Uri.parse('$baseUrl${ApiEndpoints.userNotificationsReadAll}');

    final res = await _client.patch(uri, headers: _headers(withBody: true));

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Request failed');
    }
  }

  Future<void> deleteNotification(String id) async {
    final baseUrl = AppConstants.kBaseUrl.trim();
    final uri = Uri.parse('$baseUrl${ApiEndpoints.userNotification(id: id)}');

    final res = await _client.delete(uri, headers: _headers());

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Request failed');
    }
  }

  dynamic _decodeJson(String body) {
    try {
      return jsonDecode(body);
    } catch (_) {
      return null;
    }
  }
}
