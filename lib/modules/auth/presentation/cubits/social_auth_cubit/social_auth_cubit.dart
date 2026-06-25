import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:reservation_workshop/constants/app_constants.dart';
import 'package:reservation_workshop/core/network/local/cache_helper.dart';
import 'package:reservation_workshop/core/utils/strings/prefkeys.dart';

import '../../../data/datasources/auth_remote_datasource.dart';
import 'social_auth_state.dart';

class SocialAuthCubit extends Cubit<SocialAuthState> {
  SocialAuthCubit() : super(SocialAuthInitial());

  static SocialAuthCubit get(context) => BlocProvider.of<SocialAuthCubit>(context);

  final AuthRemoteDataSource _remote = AuthRemoteDataSource();

  _PendingOp? _pendingOp;
  _LastSocialLogin? _lastSocialLogin;

  void _safeEmit(SocialAuthState state) {
    if (isClosed) return;
    try {
      emit(state);
    } on StateError {
      return;
    }
  }

  Future<void> restoreDeletedAccount({required int userId}) async {
    if (isClosed) return;
    _safeEmit(SocialAuthLoading());
    try {
      await _remote.restoreDeletedAccount(userId: userId);
      if (isClosed) return;

      final last = _lastSocialLogin;
      if (last != null) {
        await socialLogin(
          accessToken: last.accessToken,
          uniqueId: last.uniqueId,
          email: last.email,
          medium: last.medium,
          name: last.name,
          identityToken: last.identityToken,
          authorizationCode: last.authorizationCode,
        );
        return;
      }

      final op = _pendingOp;
      _pendingOp = null;

      if (op is _PendingSocialLogin) {
        await socialLogin(
          accessToken: op.accessToken,
          uniqueId: op.uniqueId,
          email: op.email,
          medium: op.medium,
          name: op.name,
          identityToken: op.identityToken,
          authorizationCode: op.authorizationCode,
        );
        return;
      }

      if (op is _PendingUpdateMobile) {
        if ((op.otp ?? '').trim().isNotEmpty) {
          await verifyPhoneAndSetMobile(
            email: op.email,
            name: op.name,
            phone: op.phone,
            otp: op.otp!,
            medium: op.medium,
            uniqueId: op.uniqueId,
            userId: op.userId,
          );
        } else {
          await sendPhoneOtp(
            email: op.email,
            name: op.name,
            phone: op.phone,
            medium: op.medium,
            uniqueId: op.uniqueId,
            userId: op.userId,
          );
        }
        return;
      }

      if (isClosed) return;
      _safeEmit(SocialAuthError('Request failed'));
    } catch (e) {
      if (isClosed) return;
      _safeEmit(SocialAuthError(e.toString()));
    }
  }

  Future<void> socialLogin({
    required String accessToken,
    required String uniqueId,
    required String email,
    required String medium,
    String? name,
    String? identityToken,
    String? authorizationCode,
  }) async {
    if (isClosed) return;
    _safeEmit(SocialAuthLoading());

    _lastSocialLogin = _LastSocialLogin(
      accessToken: accessToken,
      uniqueId: uniqueId,
      email: email,
      medium: medium,
      name: name,
      identityToken: identityToken,
      authorizationCode: authorizationCode,
    );

    _pendingOp = _PendingSocialLogin(
      accessToken: accessToken,
      uniqueId: uniqueId,
      email: email,
      medium: medium,
      name: name,
      identityToken: identityToken,
      authorizationCode: authorizationCode,
    );

    final t = accessToken.trim();
    final uid = uniqueId.trim();
    final em = email.trim();
    final med = medium.trim();

    final idToken = (identityToken ?? '').trim();
    final authCode = (authorizationCode ?? '').trim();

    if (uid.isEmpty || med.isEmpty) {
      if (isClosed) return;
      _safeEmit(SocialAuthError('Required'));
      return;
    }

    if (med != 'apple' && t.isEmpty) {
      if (isClosed) return;
      _safeEmit(SocialAuthError('Required'));
      return;
    }

    if (med == 'apple' && idToken.isEmpty && authCode.isEmpty) {
      if (isClosed) return;
      _safeEmit(SocialAuthError('Invalid Apple credential data'));
      return;
    }

    try {
      debugPrint('[SOCIAL_LOGIN] Calling socialCustomerLogin with: medium=$med, uniqueId=$uid, email=$em, accessToken=${t.isNotEmpty ? 'present' : 'empty'}, name=${name ?? '(null)'}');

      final res = await _remote.socialCustomerLogin(
        accessToken: t,
        uniqueId: uid,
        email: em,
        medium: med,
        name: name,
        identityToken: idToken,
        authorizationCode: authCode,
      );

      debugPrint('[SOCIAL_LOGIN] Response: success=${res.success}, phoneExist=${res.phoneExist}, isNewUser=${res.isNewUser}, isSoftDeleted=${res.isSoftDeleted}, token=${res.token.isNotEmpty ? 'present' : 'empty'}, userId=${res.userId}, action=${res.action}, message=${res.message}');

      if (isClosed) return;

      if (res.isSoftDeleted && (res.userId ?? 0) > 0) {
        if (isClosed) return;
        _safeEmit(
          SocialAuthRestoreRequired(
            userId: res.userId!,
            message: res.message.isNotEmpty ? res.message : 'Account has been deleted. Please restore it to continue.',
          ),
        );
        return;
      }

      if (res.success != true) {
        if (isClosed) return;
        final errorMsg = res.message.isNotEmpty ? res.message : 'Request failed';
        // Check if it's Apple login with invalid authorization code
        if (med == 'apple' && errorMsg.toLowerCase().contains('invalid apple authorization')) {
          _safeEmit(SocialAuthError('Apple login failed. Please use phone number to login instead.'));
        } else {
          _safeEmit(SocialAuthError(errorMsg));
        }
        return;
      }

      debugPrint('[APPLE_LOGIN] [A5] backend ok: isNewUser=${res.isNewUser} phoneExist=${res.phoneExist} token=${res.token.isNotEmpty ? 'present' : 'empty'}');

      // If token is present, login directly regardless of isNewUser or phoneExist
      if (res.token.trim().isNotEmpty) {
        AppConstants.token = res.token;
        await CacheHelper.saveData(key: PrefKeys.kAccessToken, value: res.token);
        if (isClosed) return;
        _safeEmit(SocialAuthSuccess(res.token));
        return;
      }

      final resolvedEmail = em.isNotEmpty ? em : (res.user?.email ?? '').trim();
      final resolvedName = (name ?? '').trim().isNotEmpty ? (name ?? '').trim() : (res.user?.name ?? '').trim();

      if (isClosed) return;
      _safeEmit(
        SocialAuthNeedPhone(
          email: resolvedEmail,
          name: resolvedName,
          medium: med,
          uniqueId: uid,
          userId: res.user?.id,
        ),
      );
    } catch (e, s) {
      if (isClosed) return;
      _safeEmit(SocialAuthError(e.toString()));
    }
  }

  Future<void> updateMobile({
    required String email,
    required String name,
    required String phone,
    required String medium,
    required String uniqueId,
    int? userId,
  }) async {
    await sendPhoneOtp(
      email: email,
      name: name,
      phone: phone,
      medium: medium,
      uniqueId: uniqueId,
      userId: userId,
    );
  }

  Future<void> sendPhoneOtp({
    required String email,
    required String name,
    required String phone,
    required String medium,
    required String uniqueId,
    int? userId,
  }) async {
    if (isClosed) return;
    emit(SocialAuthLoading());

    _pendingOp = _PendingUpdateMobile(
      email: email,
      name: name,
      phone: phone,
      otp: null,
      medium: medium,
      uniqueId: uniqueId,
      userId: userId,
    );

    final em = email.trim();
    final n = name.trim();
    final p = phone.trim();
    final med = medium.trim();
    final uid = uniqueId.trim();

    if (em.isEmpty || n.isEmpty || p.isEmpty || med.isEmpty || uid.isEmpty) {
      if (isClosed) return;
      _safeEmit(SocialAuthError('Required'));
      return;
    }

    try {
      final res = await _remote.sendPhoneVerificationOtp(
        phone: p,
        email: em,
        name: n,
        medium: med,
        uniqueId: uid,
        userId: userId,
      );

      if (isClosed) return;

      if (res.isSoftDeleted && (res.userId ?? 0) > 0) {
        _safeEmit(
          SocialAuthRestoreRequired(
            userId: res.userId!,
            message: res.message.isNotEmpty ? res.message : 'Account has been deleted. Please restore it to continue.',
          ),
        );
        return;
      }

      if (res.success != true) {
        _safeEmit(SocialAuthError(res.message.isNotEmpty ? res.message : 'Request failed'));
        return;
      }

      if (res.token.trim().isNotEmpty) {
        AppConstants.token = res.token;
        await CacheHelper.saveData(key: PrefKeys.kAccessToken, value: res.token);
        if (isClosed) return;
        _safeEmit(SocialAuthSuccess(res.token));
        return;
      }

      if (isClosed) return;
      _safeEmit(SocialAuthError(res.message.isNotEmpty ? res.message : 'Request failed'));
    } on SocialAuthOwnershipRequiredException catch (e) {
      _safeEmit(
        SocialAuthOwnershipRequired(
          existingUserId: e.existingUserId,
          phone: e.phone,
          message: e.message,
          existingUser: e.existingUser,
          pendingSocialUser: e.pendingSocialUser,
        ),
      );
    } catch (e, s) {
      if (isClosed) return;
      _safeEmit(SocialAuthError(e.toString()));
    }
  }

  Future<void> verifyPhoneAndSetMobile({
    required String email,
    required String name,
    required String phone,
    required String otp,
    required String medium,
    required String uniqueId,
    int? userId,
  }) async {
    if (isClosed) return;
    emit(SocialAuthLoading());

    _pendingOp = _PendingUpdateMobile(
      email: email,
      name: name,
      phone: phone,
      otp: otp,
      medium: medium,
      uniqueId: uniqueId,
      userId: userId,
    );

    final em = email.trim();
    final n = name.trim();
    final p = phone.trim();
    final o = otp.trim();
    final med = medium.trim();
    final uid = uniqueId.trim();

    if (em.isEmpty || n.isEmpty || p.isEmpty || o.isEmpty || med.isEmpty || uid.isEmpty) {
      if (isClosed) return;
      _safeEmit(SocialAuthError('Required'));
      return;
    }

    try {
      final res = await _remote.verifyPhoneAndSetMobile(
        phone: p,
        otp: o,
        email: em,
        name: n,
        medium: med,
        uniqueId: uid,
        userId: userId,
      );

      if (isClosed) return;

      if (res.isSoftDeleted && (res.userId ?? 0) > 0) {
        _safeEmit(
          SocialAuthRestoreRequired(
            userId: res.userId!,
            message: res.message.isNotEmpty ? res.message : 'Account has been deleted. Please restore it to continue.',
          ),
        );
        return;
      }

      if (res.success != true) {
        _safeEmit(SocialAuthError(res.message.isNotEmpty ? res.message : 'Request failed'));
        return;
      }

      if (res.token.trim().isNotEmpty) {
        AppConstants.token = res.token;
        await CacheHelper.saveData(key: PrefKeys.kAccessToken, value: res.token);
        if (isClosed) return;
        _safeEmit(SocialAuthSuccess(res.token));
        return;
      }

      if (isClosed) return;
      _safeEmit(SocialAuthError(res.message.isNotEmpty ? res.message : 'Request failed'));
    } catch (e, s) {
      if (isClosed) return;
      _safeEmit(SocialAuthError(e.toString()));
    }
  }

  Future<void> sendOwnershipOtp({
    required int existingUserId,
    required String phone,
    required String email,
    required String name,
    required String medium,
    required String uniqueId,
  }) async {
    if (isClosed) return;
    _safeEmit(SocialAuthLoading());

    try {
      await _remote.sendOwnershipOtp(
        existingUserId: existingUserId,
        phone: phone,
      );
      if (isClosed) return;

      _safeEmit(
        SocialAuthOwnershipOtpSent(
          existingUserId: existingUserId,
          phone: phone,
          email: email,
          name: name,
          medium: medium,
          uniqueId: uniqueId,
        ),
      );
    } catch (e, s) {
      if (isClosed) return;
      _safeEmit(SocialAuthError(e.toString()));
    }
  }

  Future<void> verifyAndMergeAccounts({
    required int existingUserId,
    required String phone,
    required String otp,
    required String socialEmail,
    required String medium,
    required String uniqueId,
  }) async {
    if (isClosed) return;
    _safeEmit(SocialAuthLoading());

    final em = socialEmail.trim();
    final p = phone.trim();
    final o = otp.trim();
    final med = medium.trim();
    final uid = uniqueId.trim();

    if (em.isEmpty || p.isEmpty || o.isEmpty || med.isEmpty || uid.isEmpty) {
      if (isClosed) return;
      _safeEmit(SocialAuthError('Required'));
      return;
    }

    try {
      final res = await _remote.verifyAndMergeAccounts(
        existingUserId: existingUserId,
        phone: p,
        otp: o,
        socialEmail: em,
        medium: med,
        uniqueId: uid,
      );

      if (isClosed) return;

      if (res.success != true) {
        _safeEmit(SocialAuthError(res.message.isNotEmpty ? res.message : 'Request failed'));
        return;
      }

      if (res.token.trim().isNotEmpty) {
        AppConstants.token = res.token;
        await CacheHelper.saveData(key: PrefKeys.kAccessToken, value: res.token);
        if (isClosed) return;
        _safeEmit(SocialAuthSuccess(res.token));
        return;
      }

      if (isClosed) return;
      _safeEmit(SocialAuthError(res.message.isNotEmpty ? res.message : 'Request failed'));
    } catch (e, s) {
      if (isClosed) return;
      _safeEmit(SocialAuthError(e.toString()));
    }
  }
}

abstract class _PendingOp {}

class _LastSocialLogin {
  final String accessToken;
  final String uniqueId;
  final String email;
  final String medium;
  final String? name;
  final String? identityToken;
  final String? authorizationCode;

  _LastSocialLogin({
    required this.accessToken,
    required this.uniqueId,
    required this.email,
    required this.medium,
    required this.name,
    required this.identityToken,
    required this.authorizationCode,
  });
}

class _PendingSocialLogin extends _PendingOp {
  final String accessToken;
  final String uniqueId;
  final String email;
  final String medium;
  final String? name;
  final String? identityToken;
  final String? authorizationCode;

  _PendingSocialLogin({
    required this.accessToken,
    required this.uniqueId,
    required this.email,
    required this.medium,
    required this.name,
    required this.identityToken,
    required this.authorizationCode,
  });
}

class _PendingUpdateMobile extends _PendingOp {
  final String email;
  final String name;
  final String phone;
  final String? otp;
  final String medium;
  final String uniqueId;
  final int? userId;

  _PendingUpdateMobile({
    required this.email,
    required this.name,
    required this.phone,
    required this.otp,
    required this.medium,
    required this.uniqueId,
    required this.userId,
  });
}
