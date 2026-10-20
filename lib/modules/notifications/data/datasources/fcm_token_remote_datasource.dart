import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:reservation_workshop/constants/app_constants.dart';
import 'package:reservation_workshop/core/network/api_endpoints.dart';
import 'package:reservation_workshop/core/network/local/cache_helper.dart';
import 'package:reservation_workshop/core/utils/strings/prefkeys.dart';
import 'package:reservation_workshop/modules/notifications/data/models/fcm_token_model.dart';

class FcmTokenRemoteDataSource {
  final http.Client _client;

  FcmTokenRemoteDataSource({http.Client? client})
      : _client = client ?? http.Client();

  Future<FcmTokenModel> registerToken({
    required String fcmToken,
    String? deviceInfo,
  }) async {
    final baseUrl = AppConstants.kBaseUrl.trim();
    final token = AppConstants.token ??
        CacheHelper.getData<String>(key: PrefKeys.kAccessToken);

    if (token == null || token.trim().isEmpty) {
      throw Exception('Unauthorized');
    }

    final uri = Uri.parse('$baseUrl${ApiEndpoints.fcmTokens}');

    final res = await _client.post(
      uri,
      headers: <String, String>{
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(<String, dynamic>{
        'fcm_token': fcmToken,
        if (deviceInfo != null && deviceInfo.trim().isNotEmpty)
          'device_info': deviceInfo,
      }),
    );

    final decoded = _decodeJson(res.body);

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Request failed');
    }

    if (decoded is Map) {
      return FcmTokenModel.fromJson(Map<String, dynamic>.from(decoded));
    }

    return FcmTokenModel(success: true, message: '');
  }

  /// Fetches (or receives) the current FCM token and registers it with the
  /// backend when a user is logged in. Fails silently.
  static Future<void> registerCurrentToken({String? fcmToken}) async {
    try {
      final auth = AppConstants.token ??
          CacheHelper.getData<String>(key: PrefKeys.kAccessToken);
      if (auth == null || auth.trim().isEmpty) return;

      final token =
          (fcmToken ?? await FirebaseMessaging.instance.getToken())?.trim();
      if (token == null || token.isEmpty) return;

      await FcmTokenRemoteDataSource().registerToken(
        fcmToken: token,
        deviceInfo: _deviceInfo(),
      );
      debugPrint('✅ FCM token registered with backend');
    } catch (e) {
      debugPrint('❌ Failed to register FCM token => $e');
    }
  }

  static String _deviceInfo() {
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return 'iOS Device';
      case TargetPlatform.android:
        return 'Android Device';
      default:
        return 'Flutter Device';
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
