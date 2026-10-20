import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:reservation_workshop/config/routes/routes_name.dart';
import 'package:reservation_workshop/core/components/dialogs/prograss_delay_dialog.dart';
import 'package:reservation_workshop/core/components/toasters.dart';
import 'package:reservation_workshop/core/functions/validationform.dart';
import 'package:reservation_workshop/modules/auth/presentation/cubits/social_auth_cubit/social_auth_cubit.dart';
import 'package:reservation_workshop/modules/auth/presentation/cubits/social_auth_cubit/social_auth_state.dart';

class SocialUpdateMobileScreen extends StatefulWidget {
  const SocialUpdateMobileScreen({super.key});

  @override
  State<SocialUpdateMobileScreen> createState() =>
      _SocialUpdateMobileScreenState();
}

class _SocialUpdateMobileScreenState extends State<SocialUpdateMobileScreen> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController _phoneController = TextEditingController();
  bool _dialogShown = false;

  Future<void> _confirmRestoreDeletedAccount({
    required int userId,
    required String message,
  }) async {
    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0B0F1A),
          title: Text(
            'auth.restore_account'.tr(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            message.trim().isEmpty
                ? 'auth.restore_account_message'.tr()
                : message,
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(
                'menu.no'.tr(),
                style: const TextStyle(color: Colors.white70),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 181, 7, 7),
              ),
              child: Text('menu.yes'.tr()),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      await SocialAuthCubit.get(context).restoreDeletedAccount(userId: userId);
    }
  }

  Future<void> _confirmOwnership({
    required int existingUserId,
    required String phone,
    required String message,
    required Map<String, dynamic> existingUser,
    required Map<String, dynamic> pendingSocialUser,
    required String email,
    required String name,
    required String medium,
    required String uniqueId,
  }) async {
    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0B0F1A),
          title: Text(
            'auth.is_this_your_account_title'.tr(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message.isNotEmpty
                    ? message
                    : 'auth.phone_already_linked_message'.tr(),
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'auth.existing_account_label'.tr(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      existingUser['name']?.toString() ?? '',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    Text(
                      existingUser['phone']?.toString() ??
                          existingUser['mobile']?.toString() ??
                          '',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'auth.pending_social_account_label'.tr(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      pendingSocialUser['name']?.toString() ?? name,
                      style: const TextStyle(color: Colors.white70),
                    ),
                    Text(
                      pendingSocialUser['email']?.toString() ?? email,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(
                'menu.no'.tr(),
                style: const TextStyle(color: Colors.white70),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 181, 7, 7),
              ),
              child: Text('menu.yes'.tr()),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      await SocialAuthCubit.get(context).sendOwnershipOtp(
        existingUserId: existingUserId,
        phone: phone,
        email: email,
        name: name,
        medium: medium,
        uniqueId: uniqueId,
      );
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final map = args is Map ? args : const <String, dynamic>{};

    final email = map['email']?.toString() ?? '';
    final name = map['name']?.toString() ?? '';
    final medium = map['medium']?.toString() ?? '';
    final uniqueId = map['unique_id']?.toString() ?? '';
    final userIdRaw = map['user_id'];
    final userId = userIdRaw == null
        ? null
        : int.tryParse(userIdRaw.toString());

    final cubit = SocialAuthCubit.get(context);

    return BlocListener<SocialAuthCubit, SocialAuthState>(
      listener: (context, state) {
        if (state is SocialAuthLoading) {
          showPrograssDelayDialog(context);
          _dialogShown = true;
          return;
        }

        if (state is SocialAuthSuccess) {
          if (_dialogShown) {
            Navigator.of(context, rootNavigator: true).maybePop();
            _dialogShown = false;
          }
          Future.delayed(const Duration(milliseconds: 300), () {
            Navigator.pushNamedAndRemoveUntil(
              context,
              RoutesName.homeScreen,
              (route) => false,
            );
          });
          return;
        }

        if (state is SocialAuthRestoreRequired) {
          if (_dialogShown) {
            Navigator.of(context, rootNavigator: true).maybePop();
            _dialogShown = false;
          }
          Future.microtask(() {
            if (!mounted) return;
            _confirmRestoreDeletedAccount(
              userId: state.userId,
              message: Toasters.cleanError(state.message) ??
                  'auth.restore_account_message'.tr(),
            );
          });
          return;
        }

        if (state is SocialAuthOwnershipRequired) {
          print(
            '🔍 SocialUpdateMobileScreen - Received SocialAuthOwnershipRequired state',
          );
          if (_dialogShown) {
            Navigator.of(context, rootNavigator: true).maybePop();
            _dialogShown = false;
          }
          Future.microtask(() {
            if (!mounted) return;
            print('🔍 SocialUpdateMobileScreen - Calling _confirmOwnership');
            _confirmOwnership(
              existingUserId: state.existingUserId,
              phone: state.phone,
              message: Toasters.cleanError(state.message) ??
                  'auth.restore_account_message'.tr(),
              existingUser: state.existingUser,
              pendingSocialUser: state.pendingSocialUser,
              email: email,
              name: name,
              medium: medium,
              uniqueId: uniqueId,
            );
          });
          return;
        }

        if (state is SocialAuthOwnershipOtpSent) {
          if (_dialogShown) {
            Navigator.of(context, rootNavigator: true).maybePop();
            _dialogShown = false;
          }
          Navigator.pushNamed(
            context,
            RoutesName.socialPhoneOtpScreen,
            arguments: <String, dynamic>{
              'flow': 'merge',
              'existing_user_id': state.existingUserId,
              'email': state.email,
              'name': state.name,
              'phone': state.phone,
              'medium': state.medium,
              'unique_id': state.uniqueId,
            },
          );
          return;
        }

        if (state is SocialAuthError) {
          if (_dialogShown) {
            Navigator.of(context, rootNavigator: true).maybePop();
            _dialogShown = false;
          }
          Toasters.errorFrom(
            state.message,
            fallbackKey: 'auth.update_mobile_failed',
          );
          return;
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black, Color(0xFF050505), Color(0xFF0A0A0A)],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 18,
                  ),
                  child: Form(
                    key: formKey,
                    child: Column(
                      children: [
                        const SizedBox(height: 16),
                        // Logo
                        Image.asset(
                          'assets/images/logo.png',
                          height: 120,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 28),
                        // Title
                        Text(
                          'auth.enter_mobile_title'.tr(),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        // Subtitle
                        Text(
                          'auth.enter_mobile_subtitle'.tr(),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.white70,
                            height: 1.3,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        // Phone Input
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF050505),
                            border: Border.all(
                              color: const Color(0xFF0A0A0A),
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            textDirection: ui.TextDirection.ltr,
                            validator: ValidationForm.nameValidator,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                            decoration: InputDecoration(
                              hintText: 'auth.mobile_hint'.tr(),
                              hintStyle: const TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                              filled: true,
                              fillColor: const Color(0xFF050505),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              prefixIcon: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 12),
                                child: Icon(
                                  Icons.phone_android,
                                  color: Colors.white70,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Login Button
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: () {
                              if (formKey.currentState!.validate()) {
                                cubit.sendPhoneOtp(
                                  email: email,
                                  name: name,
                                  phone: _phoneController.text,
                                  medium: medium,
                                  uniqueId: uniqueId,
                                  userId: userId,
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFD4AF37),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'auth.oauth_login'.tr(),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
