import 'dart:convert';
import 'dart:math';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:reservation_workshop/config/routes/routes_name.dart';
import 'package:reservation_workshop/core/network/local/cache_helper.dart';
import 'package:reservation_workshop/core/utils/strings/prefkeys.dart';
import 'package:reservation_workshop/modules/job_estimators/presentation/screens/job_estimator_details_args.dart';
import 'package:reservation_workshop/modules/job_order_details/presentation/screens/job_order_details_args.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  /// Set from main.dart so notifications can navigate without a context.
  static GlobalKey<NavigatorState>? navigatorKey;

  static const AndroidNotificationChannel _androidChannel = AndroidNotificationChannel(
    'whatsapp_like_channel',
    'Messages',
    description: 'Messages notifications',
    importance: Importance.max,
  );

  static bool _initialized = false;

  static Future<void> ensureInitialized() async {
    if (_initialized) return;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const initSettings = InitializationSettings(android: androidInit, iOS: iosInit);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      await android.createNotificationChannel(_androidChannel);
      await android.requestNotificationsPermission();
    }

    final ios = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      await ios.requestPermissions(alert: true, badge: true, sound: true);
    }

    _initialized = true;
  }

  static void _onNotificationResponse(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.trim().isEmpty) return;

    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map) {
        handleNotificationData(Map<String, dynamic>.from(decoded));
      }
    } catch (_) {}
  }

  static Future<void> show({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    await ensureInitialized();

    final androidDetails = AndroidNotificationDetails(
      _androidChannel.id,
      _androidChannel.name,
      channelDescription: _androidChannel.description,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _plugin.show(
      Random().nextInt(1 << 31),
      title,
      body,
      details,
      payload: (data == null || data.isEmpty) ? null : jsonEncode(data),
    );
  }

  static Future<void> showRemoteMessage(RemoteMessage message) async {
    final notification = message.notification;
    final android = message.notification?.android;

    if (notification == null && message.data.isEmpty) return;

    final title = notification?.title ?? message.data['title']?.toString();
    final body = notification?.body ?? message.data['body']?.toString();

    if (title == null && body == null) return;

    // Log receipt + what will be displayed
    // (kept as runtime logging only)
    // ignore: avoid_print
    print(
      '📢 Showing local notification messageId=${message.messageId} '
      'title=$title body=$body data=${message.data}',
    );

    final androidDetails = AndroidNotificationDetails(
      _androidChannel.id,
      _androidChannel.name,
      channelDescription: _androidChannel.description,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: android?.smallIcon,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _plugin.show(
      Random().nextInt(1 << 31),
      title,
      body,
      details,
      payload: message.data.isEmpty ? null : jsonEncode(message.data),
    );
  }

  /// Handles a notification tap from any source (FCM or local) and navigates
  /// based on `data['type']` + `data['reference_id']`.
  static void handleNotificationData(Map<String, dynamic> data) {
    _dispatch(data, retriesLeft: 20);
  }

  static void _dispatch(Map<String, dynamic> data, {required int retriesLeft}) {
    final nav = navigatorKey?.currentState;
    if (nav == null) {
      if (retriesLeft <= 0) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _dispatch(data, retriesLeft: retriesLeft - 1);
      });
      return;
    }
    _navigate(nav, data);
  }

  static int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }

  static Future<String?> _phoneLast4() async {
    final cached = await CacheHelper.getDataAsync<String>(
      key: PrefKeys.kJobOrderPhoneLast4,
    );
    final v = cached?.trim();
    return (v == null || v.isEmpty) ? null : v;
  }

  static Future<void> _navigate(
    NavigatorState nav,
    Map<String, dynamic> data,
  ) async {
    final type = (data['type'] ?? '').toString().trim().toLowerCase();
    final referenceId = _toInt(data['reference_id']) ??
        _toInt(data['referenceId']) ??
        _toInt(data['id']);

    switch (type) {
      case 'offer':
      case 'job_estimator':
        final id = referenceId ?? _toInt(data['job_estimator_id']);
        final phone = await _phoneLast4();
        if (id != null && phone != null) {
          nav.pushNamed(
            RoutesName.jobEstimatorDetailsScreen,
            arguments: JobEstimatorDetailsArgs(id: id, phoneLast4: phone),
          );
          return;
        }
        break;
      case 'job_order':
      case 'job_sheet':
      case 'maintenance_note':
        final id = referenceId ??
            _toInt(data['job_sheet_id']) ??
            _toInt(data['job_order_id']);
        final phone = await _phoneLast4();
        if (id != null && phone != null) {
          nav.pushNamed(
            RoutesName.jobOrderDetailsScreen,
            arguments: JobOrderDetailsArgs(jobOrderId: id, phoneLast4: phone),
          );
          return;
        }
        break;
      case 'back_in_stock':
        nav.pushNamed(RoutesName.sparePartsScreen);
        return;
    }

    nav.pushNamed(RoutesName.notificationsScreen);
  }
}
