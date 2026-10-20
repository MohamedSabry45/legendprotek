import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:reservation_workshop/config/routes/routes_name.dart';
import 'package:reservation_workshop/core/components/dialogs/prograss_delay_dialog.dart';
import 'package:reservation_workshop/core/components/toasters.dart';
import 'package:reservation_workshop/core/functions/validationform.dart';
import 'package:reservation_workshop/core/network/local/cache_helper.dart';
import 'package:reservation_workshop/core/utils/strings/prefkeys.dart';
import 'package:reservation_workshop/modules/auth/presentation/actions/enter_mobile_actions.dart';
import 'package:reservation_workshop/modules/auth/presentation/cubits/login_cubit/login_cubit.dart';
import 'package:reservation_workshop/modules/auth/presentation/cubits/login_cubit/login_state.dart';
import 'package:reservation_workshop/modules/auth/presentation/cubits/social_auth_cubit/social_auth_cubit.dart';
import 'package:reservation_workshop/modules/auth/presentation/cubits/social_auth_cubit/social_auth_state.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isObscured = true;
  bool _dialogShown = false;

  bool _didPrefill = false;

  void _startBlockingDialog() {
    showPrograssDelayDialog(context);
    _dialogShown = true;
  }

  void _stopBlockingDialog() {
    if (_dialogShown) {
      Navigator.of(context, rootNavigator: true).maybePop();
      _dialogShown = false;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didPrefill) return;
    _didPrefill = true;

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      final mobile = args['mobile']?.toString();
      if (mobile != null && mobile.trim().isNotEmpty) {
        _mobileController.text = mobile;
      }
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_dialogShown) {
        _stopBlockingDialog();
      }
    });
  }

  @override
  void dispose() {
    _mobileController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authCubit = LoginCubit.get(context);

    return MultiBlocListener(
      listeners: [
        BlocListener<LoginCubit, LoginState>(
          listener: (context, state) {
            if (state is LoginLoading) {
              showPrograssDelayDialog(context);
              return;
            }

            if (state is LoginSuccess) {
              Navigator.of(context, rootNavigator: true).maybePop();
              Toasters.success('auth.login_success'.tr());
              Future.delayed(const Duration(seconds: 1), () {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  RoutesName.homeScreen,
                  (route) => false,
                );
              });
              return;
            }

            if (state is LoginError) {
              Navigator.of(context, rootNavigator: true).maybePop();
              if (Toasters.isNetworkError(state.message)) {
                Toasters.error('common.network_error'.tr());
              } else {
                Toasters.error('auth.invalid_credentials'.tr());
              }
              return;
            }
          },
        ),
        BlocListener<SocialAuthCubit, SocialAuthState>(
          listener: (context, state) {
            if (state is SocialAuthLoading) {
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

            if (state is SocialAuthNeedPhone) {
              if (_dialogShown) {
                Navigator.of(context, rootNavigator: true).maybePop();
                _dialogShown = false;
              }
              Navigator.pushNamed(
                context,
                RoutesName.socialUpdateMobileScreen,
                arguments: <String, dynamic>{
                  'email': state.email,
                  'name': state.name,
                  'medium': state.medium,
                  'unique_id': state.uniqueId,
                  'user_id': state.userId,
                },
              );
              return;
            }

            if (state is SocialAuthRestoreRequired) {
              if (_dialogShown) {
                Navigator.of(context, rootNavigator: true).maybePop();
                _dialogShown = false;
              }
              Future.microtask(() {
                if (!mounted) return;
                EnterMobileActions.confirmRestoreDeletedAccount(
                  context: context,
                  userId: state.userId,
                  message: Toasters.cleanError(state.message) ??
                      'auth.restore_account_message'.tr(),
                  restoreDeletedAccount: (userId) => SocialAuthCubit.get(
                    context,
                  ).restoreDeletedAccount(userId: userId),
                  retryCheckPhone: (mobile) async {},
                );
              });
              return;
            }

            if (state is SocialAuthError) {
              if (_dialogShown) {
                Navigator.of(context, rootNavigator: true).maybePop();
                _dialogShown = false;
              }
              Toasters.errorFrom(
                state.message,
                fallbackKey: 'auth.social_failed',
              );
              return;
            }
          },
        ),
      ],
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
                        // Email Input - White background with border
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(
                              color: Colors.grey.shade300,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TextFormField(
                            controller: _mobileController,
                            keyboardType: TextInputType.phone,
                            textDirection: ui.TextDirection.ltr,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.black,
                            ),
                            decoration: InputDecoration(
                              hintText: 'auth.login_username_hint'.tr(),
                              hintStyle: const TextStyle(
                                color: Colors.black54,
                                fontSize: 16,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                            ),
                            validator: ValidationForm.nameValidator,
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Password Input - White background with border
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(
                              color: Colors.grey.shade300,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TextFormField(
                            controller: _passwordController,
                            obscureText: _isObscured,
                            maxLines: 1,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.black,
                            ),
                            decoration: InputDecoration(
                              hintText: 'auth.login_password_hint'.tr(),
                              hintStyle: const TextStyle(
                                color: Colors.black54,
                                fontSize: 16,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isObscured
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: Colors.black54,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isObscured = !_isObscured;
                                  });
                                },
                              ),
                            ),
                            validator: ValidationForm.passwordValidator,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Forgot Password - White text
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              Navigator.pushNamed(
                                context,
                                RoutesName.forgotPasswordScreen,
                                arguments: {'mobile': _mobileController.text},
                              );
                            },
                            child: Text(
                              'auth.forgot_password'.tr(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Login Button - Red
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: () {
                              if (formKey.currentState!.validate()) {
                                authCubit.login(
                                  mobile: _mobileController.text,
                                  password: _passwordController.text,
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
                              'auth.login_button'.tr(),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Register - White text
                        Align(
                          alignment: Alignment.center,
                          child: TextButton(
                            onPressed: () {
                              Navigator.pushNamed(
                                context,
                                RoutesName.registerScreen,
                              );
                            },
                            child: Text(
                              'auth.register_button'.tr(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        // or divider - White text for visibility on dark
                        Row(
                          children: [
                            Expanded(
                              child: Divider(color: Colors.grey.shade600),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Text(
                                'auth.or'.tr(),
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // Continue with Google Button
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: OutlinedButton(
                            onPressed: () =>
                                EnterMobileActions.signInWithGoogle(
                                  context: context,
                                  onStartLoading: _startBlockingDialog,
                                  onStopLoading: _stopBlockingDialog,
                                ),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color.fromARGB(
                                255,
                                230,
                                228,
                                228,
                              ),
                              side: BorderSide(color: Colors.grey.shade400),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(
                                  'assets/images/google.png',
                                  height: 24,
                                  width: 24,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(
                                      Icons.g_mobiledata,
                                      size: 24,
                                      color: const Color(0xFFD4AF37),
                                    );
                                  },
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'auth.continue_google'.tr(),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (!kIsWeb && Platform.isIOS) ...[
                          const SizedBox(height: 12),
                          // Continue with Apple Button
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: OutlinedButton(
                              onPressed: () =>
                                  EnterMobileActions.signInWithApple(
                                    context: context,
                                    onStartLoading: _startBlockingDialog,
                                    onStopLoading: _stopBlockingDialog,
                                  ),
                              style: OutlinedButton.styleFrom(
                                backgroundColor: Colors.black,
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: Colors.black),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.asset(
                                    'assets/images/apple_logo.png',
                                    height: 24,
                                    width: 24,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Icon(
                                        Icons.apple,
                                        size: 24,
                                        color: Colors.white,
                                      );
                                    },
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'auth.continue_apple'.tr(),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        // Continue as Guest - White text
                        GestureDetector(
                          onTap: () async {
                            await CacheHelper.clearSession();
                            await CacheHelper.saveData(
                              key: PrefKeys.kIsGuestMode,
                              value: true,
                            );
                            if (mounted) {
                              Navigator.pushNamedAndRemoveUntil(
                                context,
                                RoutesName.homeScreen,
                                (route) => false,
                              );
                            }
                          },
                          child: Center(
                            child: Text(
                              'auth.continue_as_guest'.tr(),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
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
