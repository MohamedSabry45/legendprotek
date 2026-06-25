import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:http/http.dart' as http;

import 'package:reservation_workshop/constants/app_constants.dart';
import 'package:reservation_workshop/core/network/api_endpoints.dart';

import '../models/auth_session_model.dart';
import '../models/check_phone_result_model.dart';
import '../models/social_auth_response_model.dart';

class SocialAuthOwnershipRequiredException implements Exception {
  final int existingUserId;
  final String phone;
  final String message;
  final Map<String, dynamic> existingUser;
  final Map<String, dynamic> pendingSocialUser;

  SocialAuthOwnershipRequiredException({
    required this.existingUserId,
    required this.phone,
    required this.message,
    required this.existingUser,
    required this.pendingSocialUser,
  });

  @override
  String toString() => message;
}

class AuthRemoteDataSource {
  final http.Client _client;

  AuthRemoteDataSource({http.Client? client}) : _client = client ?? http.Client();

  String _redact(String v, {int head = 6}) {
    final s = (v).trim();
    if (s.isEmpty) return '(empty)';
    if (s.length <= head) return '***(${s.length})';
    return '${s.substring(0, head)}…(${s.length})';
  }

  Future<CheckPhoneResultModel> checkPhone({required String mobile}) async {
    final baseUrl = AppConstants.kBaseUrl.trim();
    final uri = Uri.parse('$baseUrl${ApiEndpoints.checkPhone}').replace(
      queryParameters: <String, String>{
        'mobile': mobile.trim(),
      },
    );

    final res = await _client.get(uri);
    final decoded = _decodeJson(res.body);

    if (res.statusCode < 200 || res.statusCode >= 300) {
      final isSoftDeleted = decoded['is_soft_deleted'] == true || decoded['is_soft_deleted']?.toString() == 'true';
      if (isSoftDeleted) {
        return CheckPhoneResultModel.fromJson(decoded);
      }
      throw Exception(_extractMessage(decoded) ?? 'Request failed');
    }

    final success = decoded['success'] == true || decoded['success']?.toString() == 'true';
    if (!success) {
      final isSoftDeleted = decoded['is_soft_deleted'] == true || decoded['is_soft_deleted']?.toString() == 'true';
      if (isSoftDeleted) {
        return CheckPhoneResultModel.fromJson(decoded);
      }
      throw Exception(_extractMessage(decoded) ?? 'Request failed');
    }

    return CheckPhoneResultModel.fromJson(decoded);
  }

  Future<AuthSessionModel> register({
    required String name,
    required String mobile,
    required String password,
  }) async {
    final baseUrl = AppConstants.kBaseUrl.trim();
    final uri = Uri.parse('$baseUrl${ApiEndpoints.signupEmail}');

    final payload = <String, dynamic>{
      'name': name,
      'mobile': mobile,
      'password': password,
    };

    final res = await _client.post(
      uri,
      headers: const <String, String>{
        'Content-Type': 'application/json',
      },
      body: jsonEncode(payload),
    );
    final decoded = _decodeJson(res.body);

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(_extractMessage(decoded) ?? 'Request failed');
    }

    final success = decoded['success'] == true || decoded['success']?.toString() == 'true';
    if (!success) {
      throw Exception(_extractMessage(decoded) ?? 'Request failed');
    }

    return AuthSessionModel.fromJson(decoded);
  }

  Future<SocialAuthResponseModel> socialCustomerLogin({
    required String accessToken,
    required String uniqueId,
    required String email,
    required String medium,
    String? name,
    String? identityToken,
    String? authorizationCode,
  }) async {
    final baseUrl = AppConstants.kBaseUrl.trim();
    final uri = Uri.parse('$baseUrl${ApiEndpoints.socialCustomerLogin}');

    final med = medium.trim();
    final token = accessToken.trim();
    final uid = uniqueId.trim();
    final em = email.trim();
    final nm = (name ?? '').trim();
    final idToken = (identityToken ?? '').trim();
    final authCode = (authorizationCode ?? '').trim();

    final payload = <String, dynamic>{
      'medium': med,
      'unique_id': uid,
      'email': em,
    };

    if (nm.isNotEmpty) {
      payload['name'] = nm;
    }

    if (med == 'apple') {
      if (authCode.isNotEmpty) payload['authorization_code'] = authCode;
      if (idToken.isNotEmpty) payload['identity_token'] = idToken;
      // Only add name if not empty (backend rejects empty strings)
      if (nm.isNotEmpty) payload['name'] = nm;
    } else {
      if (token.isNotEmpty) payload['token'] = token;
      if (nm.isNotEmpty) payload['name'] = nm;
    }

    debugPrint('socialCustomerLogin uri=$uri');
    debugPrint('socialCustomerLogin request medium=$med unique_id=${_redact(uid)} email=${em.isEmpty ? '(empty)' : _redact(em)} token=${_redact(token)} authorization_code=${_redact(authCode)} identity_token=${_redact(idToken)} name=${nm.isEmpty ? '(empty)' : '(provided)'}');
    debugPrint('socialCustomerLogin FULL PAYLOAD (for Postman): ${jsonEncode(payload)}');

    final res = await _client.post(
      uri,
      headers: const <String, String>{
        'Content-Type': 'application/json',
      },
      body: jsonEncode(payload),
    );

    debugPrint('socialCustomerLogin status=${res.statusCode}');
    debugPrint('socialCustomerLogin body=${res.body}');

    final decoded = _decodeJson(res.body);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      final isSoftDeleted = decoded['is_soft_deleted'] == true || decoded['is_soft_deleted']?.toString() == 'true';
      if (isSoftDeleted) {
        return SocialAuthResponseModel.fromJson(decoded);
      }
      throw Exception(_extractMessage(decoded) ?? 'Request failed');
    }

    return SocialAuthResponseModel.fromJson(decoded);
  }

  Future<SocialAuthResponseModel> updateSocialMobile({
    required String email,
    required String name,
    required String phone,
    required String medium,
    required String uniqueId,
    int? userId,
  }) async {
    final baseUrl = AppConstants.kBaseUrl.trim();
    final uri = Uri.parse('$baseUrl${ApiEndpoints.updateSocialMobile}');

    final res = await _client.post(
      uri,
      headers: const <String, String>{
        'Content-Type': 'application/json',
      },
      body: jsonEncode(<String, dynamic>{
        'email': email,
        'name': name,
        'phone': phone,
        'medium': medium,
        'unique_id': uniqueId,
        'user_id': userId,
      }),
    );

    final decoded = _decodeJson(res.body);

    final phoneAlreadyLinked = decoded['phone_already_linked'] == true ||
        decoded['phone_already_linked']?.toString() == 'true' ||
        decoded['action']?.toString() == 'confirm_ownership';

    if (phoneAlreadyLinked) {
      final existingUserId = int.tryParse(decoded['existing_user']?['id']?.toString() ?? '');
      if (existingUserId != null && existingUserId > 0) {
        throw SocialAuthOwnershipRequiredException(
          existingUserId: existingUserId,
          phone: phone.trim(),
          message: _extractMessage(decoded) ?? 'Phone already linked to another account',
          existingUser: decoded['existing_user'] is Map<String, dynamic>
              ? decoded['existing_user'] as Map<String, dynamic>
              : <String, dynamic>{},
          pendingSocialUser: decoded['pending_social_user'] is Map<String, dynamic>
              ? decoded['pending_social_user'] as Map<String, dynamic>
              : <String, dynamic>{},
        );
      }
    }

    if (res.statusCode < 200 || res.statusCode >= 300) {
      final isSoftDeleted = decoded['is_soft_deleted'] == true || decoded['is_soft_deleted']?.toString() == 'true';
      if (isSoftDeleted) {
        return SocialAuthResponseModel.fromJson(decoded);
      }
      throw Exception(_extractMessage(decoded) ?? 'Request failed');
    }

    return SocialAuthResponseModel.fromJson(decoded);
  }

  Future<SocialAuthResponseModel> sendPhoneVerificationOtp({
    required String phone,
    required String email,
    String? name,
    String? medium,
    String? uniqueId,
    int? userId,
  }) async {
    final baseUrl = AppConstants.kBaseUrl.trim();
    final uri = Uri.parse('$baseUrl${ApiEndpoints.sendPhoneVerificationOtp}');

    final payload = <String, dynamic>{
      'phone': phone.trim(),
      'email': email.trim(),
    };

    if (name != null && name.trim().isNotEmpty) {
      payload['name'] = name.trim();
    }
    if (medium != null && medium.trim().isNotEmpty) {
      payload['medium'] = medium.trim();
    }
    if (uniqueId != null && uniqueId.trim().isNotEmpty) {
      payload['unique_id'] = uniqueId.trim();
    }
    if (userId != null) {
      payload['user_id'] = userId;
    }

    debugPrint('sendPhoneVerificationOtp uri=$uri');
    debugPrint('sendPhoneVerificationOtp request phone=${_redact(phone)} email=${email.isEmpty ? '(empty)' : _redact(email)} medium=${medium ?? '(null)'} unique_id=${uniqueId != null ? _redact(uniqueId) : '(null)'} name=${name != null ? (name.isEmpty ? '(empty)' : '(provided)') : '(null)'} user_id=${userId ?? '(null)'}');
    debugPrint('sendPhoneVerificationOtp FULL PAYLOAD: ${jsonEncode(payload)}');

    final res = await _client.post(
      uri,
      headers: const <String, String>{
        'Content-Type': 'application/json',
      },
      body: jsonEncode(payload),
    );

    debugPrint('sendPhoneVerificationOtp status=${res.statusCode}');
    debugPrint('sendPhoneVerificationOtp response=${res.body}');

    final decoded = _decodeJson(res.body);

    final phoneAlreadyLinked = decoded['phone_already_linked'] == true ||
        decoded['phone_already_linked']?.toString() == 'true' ||
        decoded['action']?.toString() == 'confirm_ownership';

    if (phoneAlreadyLinked) {
      final existingUserId = int.tryParse(decoded['existing_user']?['id']?.toString() ?? '');
      if (existingUserId != null && existingUserId > 0) {
        throw SocialAuthOwnershipRequiredException(
          existingUserId: existingUserId,
          phone: phone.trim(),
          message: _extractMessage(decoded) ?? 'Phone already linked to another account',
          existingUser: decoded['existing_user'] is Map<String, dynamic>
              ? decoded['existing_user'] as Map<String, dynamic>
              : <String, dynamic>{},
          pendingSocialUser: decoded['pending_social_user'] is Map<String, dynamic>
              ? decoded['pending_social_user'] as Map<String, dynamic>
              : <String, dynamic>{},
        );
      }
    }

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(_extractMessage(decoded) ?? 'Request failed');
    }

    return SocialAuthResponseModel.fromJson(decoded);
  }

  Future<SocialAuthResponseModel> verifyPhoneAndSetMobile({
    required String phone,
    required String otp,
    required String email,
    required String name,
    required String medium,
    required String uniqueId,
    int? userId,
  }) async {
    final baseUrl = AppConstants.kBaseUrl.trim();
    final uri = Uri.parse('$baseUrl${ApiEndpoints.verifyPhoneAndSetMobile}');

    final res = await _client.post(
      uri,
      headers: const <String, String>{
        'Content-Type': 'application/json',
      },
      body: jsonEncode(<String, dynamic>{
        'phone': phone.trim(),
        'otp': otp.trim(),
        'email': email.trim(),
        'name': name.trim(),
        'medium': medium.trim(),
        'unique_id': uniqueId.trim(),
        'user_id': userId,
      }),
    );

    final decoded = _decodeJson(res.body);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      final isSoftDeleted = decoded['is_soft_deleted'] == true || decoded['is_soft_deleted']?.toString() == 'true';
      if (isSoftDeleted) {
        return SocialAuthResponseModel.fromJson(decoded);
      }
      throw Exception(_extractMessage(decoded) ?? 'Request failed');
    }

    return SocialAuthResponseModel.fromJson(decoded);
  }

  Future<void> restoreDeletedAccount({required int userId}) async {
    final baseUrl = AppConstants.kBaseUrl.trim();
    final uri = Uri.parse('$baseUrl${ApiEndpoints.restoreDeletedAccount}');

    final res = await _client.post(
      uri,
      headers: const <String, String>{
        'Content-Type': 'application/json',
      },
      body: jsonEncode(<String, dynamic>{
        'user_id': userId,
      }),
    );

    final decoded = _decodeJson(res.body);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(_extractMessage(decoded) ?? 'Request failed');
    }

    final success = decoded['success'] == true || decoded['success']?.toString() == 'true';
    if (!success) {
      throw Exception(_extractMessage(decoded) ?? 'Request failed');
    }
  }

  Future<AuthSessionModel> login({
    required String mobile,
    required String password,
  }) async {
    final baseUrl = AppConstants.kBaseUrl.trim();
    final uri = Uri.parse('$baseUrl${ApiEndpoints.login}');

    final deviceType = kIsWeb
        ? 'web'
        : defaultTargetPlatform == TargetPlatform.android
            ? 'android'
            : defaultTargetPlatform == TargetPlatform.iOS
                ? 'ios'
                : 'unknown';

    final payload = <String, dynamic>{
      'mobile': mobile.trim(),
      'password': password,
      'device_type': deviceType,
    };

    debugPrint('login uri=$uri');
    debugPrint('login FULL PAYLOAD (for Postman): ${jsonEncode(payload)}');

    final res = await _client.post(
      uri,
      headers: const <String, String>{
        'Content-Type': 'application/json',
      },
      body: jsonEncode(payload),
    );

    final decoded = _decodeJson(res.body);

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(_extractMessage(decoded) ?? 'Request failed');
    }

    final success = decoded['success'] == true || decoded['success']?.toString() == 'true';
    if (!success) {
      throw Exception(_extractMessage(decoded) ?? 'Request failed');
    }

    return AuthSessionModel.fromJson(decoded);
  }

  Map<String, dynamic> _decodeJson(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) return decoded;
      return <String, dynamic>{};
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  String? _extractMessage(Map<String, dynamic> decoded) {
    final msg = decoded['message']?.toString();
    if (msg != null && msg.trim().isNotEmpty) return msg;
    return null;
  }

  Future<Map<String, dynamic>> sendOwnershipOtp({
    required int existingUserId,
    required String phone,
  }) async {
    final baseUrl = AppConstants.kBaseUrl.trim();
    final uri = Uri.parse('$baseUrl${ApiEndpoints.sendOwnershipOtp}');

    final res = await _client.post(
      uri,
      headers: const <String, String>{
        'Content-Type': 'application/json',
      },
      body: jsonEncode(<String, dynamic>{
        'existing_user_id': existingUserId,
        'phone': phone.trim(),
      }),
    );

    final decoded = _decodeJson(res.body);
    return decoded;
  }

  Future<SocialAuthResponseModel> verifyAndMergeAccounts({
    required int existingUserId,
    required String phone,
    required String otp,
    required String socialEmail,
    required String medium,
    required String uniqueId,
  }) async {
    final baseUrl = AppConstants.kBaseUrl.trim();
    final uri = Uri.parse('$baseUrl${ApiEndpoints.verifyAndMergeAccounts}');

    final res = await _client.post(
      uri,
      headers: const <String, String>{
        'Content-Type': 'application/json',
      },
      body: jsonEncode(<String, dynamic>{
        'existing_user_id': existingUserId,
        'phone': phone.trim(),
        'otp': otp.trim(),
        'social_email': socialEmail.trim(),
        'medium': medium.trim(),
        'unique_id': uniqueId.trim(),
      }),
    );

    final decoded = _decodeJson(res.body);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(_extractMessage(decoded) ?? 'Request failed');
    }

    final success = decoded['success'] == true || decoded['success']?.toString() == 'true';
    if (!success) {
      throw Exception(_extractMessage(decoded) ?? 'Request failed');
    }

    return SocialAuthResponseModel.fromJson(decoded);
  }

  Future<void> forgotPassword({required String mobile}) async {
    final baseUrl = AppConstants.kBaseUrl.trim();
    final uri = Uri.parse('$baseUrl${ApiEndpoints.forgotPassword}');

    final res = await _client.post(
      uri,
      headers: const <String, String>{
        'Content-Type': 'application/json',
      },
      body: jsonEncode(<String, dynamic>{
        'mobile': mobile.trim(),
      }),
    );

    final decoded = _decodeJson(res.body);

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(_extractMessage(decoded) ?? 'Request failed');
    }

    final success = decoded['success'] == true || decoded['success']?.toString() == 'true';
    if (!success) {
      throw Exception(_extractMessage(decoded) ?? 'Request failed');
    }
  }

  Future<void> resetPassword({
    required String mobile,
    required String otp,
    required String newPassword,
  }) async {
    final baseUrl = AppConstants.kBaseUrl.trim();
    final uri = Uri.parse('$baseUrl${ApiEndpoints.resetPassword}');

    final res = await _client.post(
      uri,
      headers: const <String, String>{
        'Content-Type': 'application/json',
      },
      body: jsonEncode(<String, dynamic>{
        'mobile': mobile.trim(),
        'otp': otp.trim(),
        'new_password': newPassword,
      }),
    );

    final decoded = _decodeJson(res.body);

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(_extractMessage(decoded) ?? 'Request failed');
    }

    final success = decoded['success'] == true || decoded['success']?.toString() == 'true';
    if (!success) {
      throw Exception(_extractMessage(decoded) ?? 'Request failed');
    }
  }
}
