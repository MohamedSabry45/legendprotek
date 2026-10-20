import 'dart:async';
import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;

import 'package:reservation_workshop/constants/app_constants.dart';
import 'package:reservation_workshop/core/network/api_endpoints.dart';
import 'package:reservation_workshop/core/network/local/cache_helper.dart';
import 'package:reservation_workshop/core/utils/strings/prefkeys.dart';
import 'package:reservation_workshop/modules/notifications/data/datasources/fcm_token_remote_datasource.dart';

import 'auth_otp_state.dart';

class AuthOtpCubit extends Cubit<AuthOtpState> {
  AuthOtpCubit() : super(AuthOtpInitial());

  static AuthOtpCubit get(context) => BlocProvider.of<AuthOtpCubit>(context);

  String? _mobile;
  String? get mobile => _mobile;

  Future<void> sendOtp({required String mobile}) async {
    if (isClosed) return;
    emit(SendOtpLoading());
    _mobile = mobile.trim();

    if ((_mobile ?? '').isEmpty) {
      if (isClosed) return;
      emit(AuthOtpError('Required'));
      return;
    }

    if (AppConstants.mockAuth) {
      await Future<void>.delayed(const Duration(milliseconds: 400));
      if (isClosed) return;
      emit(SendOtpSuccess());
      return;
    }

    final baseUrl = AppConstants.kBaseUrl;
    if (baseUrl.trim().isEmpty) {
      if (isClosed) return;
      emit(AuthOtpError('Base URL is not configured'));
      return;
    }

    try {
      final uri = Uri.parse('$baseUrl${ApiEndpoints.sendOtp}');
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'mobile': _mobile}),
      );

      if (res.statusCode >= 200 && res.statusCode < 300) {
        if (isClosed) return;
        emit(SendOtpSuccess());
        return;
      }

      if (isClosed) return;
      emit(AuthOtpError(_extractErrorMessage(res.body) ?? 'Error'));
    } catch (e) {
      if (isClosed) return;
      emit(AuthOtpError(e.toString()));
    }
  }

  Future<void> verifyOtp({required String otp}) async {
    if (isClosed) return;
    emit(VerifyOtpLoading());

    final m = _mobile?.trim() ?? '';
    if (m.isEmpty) {
      if (isClosed) return;
      emit(AuthOtpError('Mobile is missing'));
      return;
    }

    final baseUrl = AppConstants.kBaseUrl;
    if (baseUrl.trim().isEmpty) {
      if (isClosed) return;
      emit(AuthOtpError('Base URL is not configured'));
      return;
    }

    final o = otp.trim();
    if (o.isEmpty) {
      if (isClosed) return;
      emit(AuthOtpError('Required'));
      return;
    }

    if (AppConstants.mockAuth) {
      await Future<void>.delayed(const Duration(milliseconds: 400));
      final isFirst = o == '0000';
      const token = 'mock_token';
      AppConstants.token = token;
      await CacheHelper.saveData(key: PrefKeys.kAccessToken, value: token);
      if (isClosed) return;
      emit(VerifyOtpSuccess(isFirstLogin: isFirst));
      return;
    }

    try {
      final uri = Uri.parse('$baseUrl${ApiEndpoints.verifyOtp}');
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'mobile': m, 'otp': o}),
      );

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final decoded = _tryDecodeJson(res.body) ?? const <String, dynamic>{};
        final token = decoded['token']?.toString();
        final isFirst = decoded['is_first_login'] == true || decoded['is_first_login']?.toString() == 'true';

        if (token != null && token.trim().isNotEmpty) {
          AppConstants.token = token;
          await CacheHelper.saveData(key: PrefKeys.kAccessToken, value: token);
          unawaited(FcmTokenRemoteDataSource.registerCurrentToken());
        }

        if (isClosed) return;
        emit(VerifyOtpSuccess(isFirstLogin: isFirst));
        return;
      }

      if (isClosed) return;
      emit(AuthOtpError(_extractErrorMessage(res.body) ?? 'Error'));
    } catch (e) {
      if (isClosed) return;
      emit(AuthOtpError(e.toString()));
    }
  }

  Future<void> completeProfile({required String name, required String password}) async {
    if (isClosed) return;
    emit(CompleteProfileLoading());

    final baseUrl = AppConstants.kBaseUrl;
    if (baseUrl.trim().isEmpty) {
      if (isClosed) return;
      emit(AuthOtpError('Base URL is not configured'));
      return;
    }

    final n = name.trim();
    final p = password.trim();

    if (n.isEmpty || p.isEmpty) {
      if (isClosed) return;
      emit(AuthOtpError('Required'));
      return;
    }

    if (AppConstants.mockAuth) {
      await Future<void>.delayed(const Duration(milliseconds: 400));
      const token = 'mock_token';
      AppConstants.token = token;
      await CacheHelper.saveData(key: PrefKeys.kAccessToken, value: token);
      if (isClosed) return;
      emit(CompleteProfileSuccess());
      return;
    }

    try {
      final token = AppConstants.token ?? CacheHelper.getData<String>(key: PrefKeys.kAccessToken);
      final headers = <String, String>{
        'Content-Type': 'application/json',
        if (token != null && token.trim().isNotEmpty) 'Authorization': 'Bearer $token',
      };

      final uri = Uri.parse('$baseUrl${ApiEndpoints.completeProfile}');
      final res = await http.post(
        uri,
        headers: headers,
        body: jsonEncode({'name': n, 'password': p}),
      );

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final decoded = _tryDecodeJson(res.body);
        final newToken = decoded?['token']?.toString();
        if (newToken != null && newToken.trim().isNotEmpty) {
          AppConstants.token = newToken;
          await CacheHelper.saveData(key: PrefKeys.kAccessToken, value: newToken);
          unawaited(FcmTokenRemoteDataSource.registerCurrentToken());
        }
        if (isClosed) return;
        emit(CompleteProfileSuccess());
        return;
      }

      if (isClosed) return;
      emit(AuthOtpError(_extractErrorMessage(res.body) ?? 'Error'));
    } catch (e) {
      if (isClosed) return;
      emit(AuthOtpError(e.toString()));
    }
  }

  Map<String, dynamic>? _tryDecodeJson(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) return decoded;
      return null;
    } catch (_) {
      return null;
    }
  }

  String? _extractErrorMessage(String body) {
    final decoded = _tryDecodeJson(body);
    final msg = decoded?['message']?.toString();
    if (msg != null && msg.trim().isNotEmpty) return msg;
    return null;
  }
}
