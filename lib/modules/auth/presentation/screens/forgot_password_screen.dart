import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:reservation_workshop/config/routes/routes_name.dart';
import 'package:reservation_workshop/core/components/toasters.dart';
import 'package:reservation_workshop/core/functions/validationform.dart';

import 'package:reservation_workshop/modules/auth/presentation/cubits/forgot_password_cubit/forgot_password_cubit.dart'
    as forgot_password_cubit;

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController _mobileController = TextEditingController();

  bool _didPrefill = false;
  bool _dialogShown = false;

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
    // Close any lingering loading dialog when returning to this screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_dialogShown) {
        _stopBlockingDialog();
      }
    });
  }

  void _stopBlockingDialog() {
    if (_dialogShown) {
      Navigator.of(context, rootNavigator: true).maybePop();
      _dialogShown = false;
    }
  }

  @override
  void dispose() {
    _mobileController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = forgot_password_cubit.ForgotPasswordCubit.get(context);

    return BlocListener<
      forgot_password_cubit.ForgotPasswordCubit,
      forgot_password_cubit.ForgotPasswordState
    >(
      listener: (context, state) {
        // Close dialog if state is not loading but dialog is shown
        if (!(state is forgot_password_cubit.ForgotPasswordLoading) &&
            _dialogShown) {
          _stopBlockingDialog();
        }

        if (state is forgot_password_cubit.ForgotPasswordSuccess) {
          if (_dialogShown) {
            Navigator.of(context, rootNavigator: true).maybePop();
            _dialogShown = false;
          }
          Toasters.success('auth.otp_sent'.tr());
          Navigator.pushNamed(
            context,
            RoutesName.resetPasswordScreen,
            arguments: {'mobile': state.mobile},
          );
          return;
        }

        if (state is forgot_password_cubit.ForgotPasswordError) {
          if (_dialogShown) {
            Navigator.of(context, rootNavigator: true).maybePop();
            _dialogShown = false;
          }
          Toasters.errorFrom(state.message, fallbackKey: 'auth.forgot_failed');
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
              child: SizedBox(
                height:
                    MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top -
                    kToolbarHeight,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Card(
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
                                  'auth.forgot_password_title'.tr(),
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 12),
                                // Hint
                                Text(
                                  'auth.forgot_password_hint'.tr(),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white70,
                                    height: 1.3,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 24),
                                // Mobile Input - White background with border
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
                                    controller: _mobileController,
                                    keyboardType: TextInputType.phone,
                                    textDirection: ui.TextDirection.ltr,
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
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 16,
                                          ),
                                    ),
                                    validator: ValidationForm.nameValidator,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                // Submit Button - Red
                                SizedBox(
                                  width: double.infinity,
                                  height: 52,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      if (formKey.currentState!.validate()) {
                                        cubit.forgotPassword(
                                          mobile: _mobileController.text,
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
                                      'auth.forgot_password_submit'.tr(),
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
                    ],
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
