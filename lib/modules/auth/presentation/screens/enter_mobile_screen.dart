import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:reservation_workshop/config/routes/routes_name.dart';
import 'package:reservation_workshop/core/components/dialogs/prograss_delay_dialog.dart';
import 'package:reservation_workshop/core/components/toasters.dart';
import 'package:reservation_workshop/core/network/local/cache_helper.dart';
import 'package:reservation_workshop/core/utils/strings/prefkeys.dart';
import 'package:reservation_workshop/modules/auth/presentation/actions/enter_mobile_actions.dart';
import 'package:reservation_workshop/modules/auth/presentation/cubits/check_phone_cubit/check_phone_cubit.dart';
import 'package:reservation_workshop/modules/auth/presentation/cubits/check_phone_cubit/check_phone_state.dart';
import 'package:reservation_workshop/modules/auth/presentation/cubits/social_auth_cubit/social_auth_cubit.dart';
import 'package:reservation_workshop/modules/auth/presentation/cubits/social_auth_cubit/social_auth_state.dart';

class EnterMobileScreen extends StatefulWidget {
  const EnterMobileScreen({super.key});

  @override
  State<EnterMobileScreen> createState() => _EnterMobileScreenState();
}

class _EnterMobileScreenState extends State<EnterMobileScreen> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController _mobileController = TextEditingController();
  bool _dialogShown = false;
  bool _rememberMe = false;
  String _selectedCountryCode = '+20';

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
  void initState() {
    super.initState();
    // Close any lingering loading dialog when returning to this screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_dialogShown) {
        _stopBlockingDialog();
      }
    });
  }

  @override
  void dispose() {
    _mobileController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CheckPhoneCubit>(
      create: (_) => CheckPhoneCubit(),
      child: Builder(
        builder: (context) {
          final cubit = context.read<CheckPhoneCubit>();

          return MultiBlocListener(
            listeners: [
              BlocListener<CheckPhoneCubit, CheckPhoneState>(
                listener: (context, state) {
                  // Close dialog if state is not loading but dialog is shown
                  if (!(state is CheckPhoneLoading) && _dialogShown) {
                    _stopBlockingDialog();
                  }

                  if (state is CheckPhoneRestoreRequired) {
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
                        retryMobile: state.mobile,
                        restoreDeletedAccount: (userId) => SocialAuthCubit.get(
                          context,
                        ).restoreDeletedAccount(userId: userId),
                        retryCheckPhone: (mobile) => CheckPhoneCubit.get(
                          context,
                        ).checkPhone(mobile: mobile),
                      );
                    });
                    return;
                  }

                  if (state is CheckPhoneSuccess) {
                    if (_dialogShown) {
                      Navigator.of(context, rootNavigator: true).maybePop();
                      _dialogShown = false;
                    }

                    if (state.result.userFound) {
                      Navigator.pushNamed(
                        context,
                        RoutesName.loginScreen,
                        arguments: <String, dynamic>{
                          'mobile': state.mobile,
                          'name': state.result.name,
                        },
                      );
                      return;
                    }

                    Navigator.pushNamed(
                      context,
                      RoutesName.registerScreen,
                      arguments: <String, dynamic>{'mobile': state.mobile},
                    );
                    return;
                  }

                  if (state is CheckPhoneError) {
                    if (_dialogShown) {
                      Navigator.of(context, rootNavigator: true).maybePop();
                      _dialogShown = false;
                    }
                    Toasters.errorFrom(
                      state.message,
                      fallbackKey: 'auth.check_phone_failed',
                    );
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
                    debugPrint(
                      '[APPLE_LOGIN] [A6] navigating to homeScreen',
                    );
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
                        retryCheckPhone: (mobile) => CheckPhoneCubit.get(
                          context,
                        ).checkPhone(mobile: mobile),
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
                    colors: [
                      Colors.black,
                      Color(0xFF050505),
                      Color(0xFF0A0A0A),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
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
                              // Logo - Bigger size
                              Image.asset(
                                'assets/images/logo.png',
                                height: 150,
                                fit: BoxFit.contain,
                              ),
                              const SizedBox(height: 28),
                              // Phone Number Input - Dark background with white text
                              Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0A0A0A),
                                  border: Border.all(
                                    color: const Color(0xFF050505),
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    // Fixed Egypt Country Code
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 16,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF050505),
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(12),
                                          bottomLeft: Radius.circular(12),
                                        ),
                                        border: Border(
                                          right: BorderSide(
                                            color: const Color(0xFF30363D),
                                          ),
                                        ),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            '🇪🇬',
                                            style: TextStyle(fontSize: 20),
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            '+20',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Phone Input - White text on dark background
                                    Expanded(
                                      child: TextFormField(
                                        controller: _mobileController,
                                        keyboardType: TextInputType.phone,
                                        textDirection: ui.TextDirection.ltr,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.white,
                                        ),
                                        decoration: InputDecoration(
                                          hintText: 'auth.phone_number'.tr(),
                                          hintStyle: const TextStyle(
                                            color: Colors.white54,
                                            fontSize: 16,
                                          ),
                                          filled: true,
                                          fillColor: const Color(0xFF1C2128),
                                          border: InputBorder.none,
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 16,
                                              ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              // Remember Me Checkbox - White text
                              Row(
                                children: [
                                  SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: Checkbox(
                                      value: _rememberMe,
                                      onChanged: (value) {
                                        setState(() {
                                          _rememberMe = value ?? false;
                                        });
                                      },
                                      activeColor: Colors.green,
                                      side: BorderSide(
                                        color: Colors.green.shade400,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'auth.remember_me'.tr(),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 32),
                              // Get OTP Button
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton(
                                  onPressed: () {
                                    if (formKey.currentState?.validate() ??
                                        true) {
                                      final mobileText =
                                          _mobileController.text.startsWith('0')
                                          ? _mobileController.text.substring(1)
                                          : _mobileController.text;
                                      final fullNumber =
                                          '$_selectedCountryCode$mobileText';
                                      cubit.checkPhone(mobile: fullNumber);
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
                                    'auth.send_otp'.tr(),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 32),
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
                                      style: const TextStyle(
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
                              const SizedBox(height: 32),
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
                                    side: BorderSide(
                                      color: Colors.grey.shade400,
                                    ),
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
                                        errorBuilder:
                                            (context, error, stackTrace) {
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
                                      side: const BorderSide(
                                        color: Colors.black,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Image.asset(
                                          'assets/images/apple_logo.png',
                                          height: 24,
                                          width: 24,
                                          errorBuilder:
                                              (context, error, stackTrace) {
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
                              const SizedBox(height: 32),
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
                                child: Text(
                                  'auth.continue_as_guest'.tr(),
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 28),
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
        },
      ),
    );
  }
}
