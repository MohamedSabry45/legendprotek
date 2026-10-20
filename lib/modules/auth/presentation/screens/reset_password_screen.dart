import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:reservation_workshop/config/routes/routes_name.dart';
import 'package:reservation_workshop/core/components/dialogs/prograss_delay_dialog.dart';
import 'package:reservation_workshop/core/components/toasters.dart';
import 'package:reservation_workshop/core/functions/validationform.dart';
import 'package:reservation_workshop/core/widgets/otp_code_input.dart';

import 'package:reservation_workshop/modules/auth/presentation/cubits/reset_password_cubit/reset_password_cubit.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _didPrefill = false;
  bool _dialogShown = false;
  bool _isObscured = true;
  bool _isConfirmObscured = true;

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
  void dispose() {
    _mobileController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Widget buildCodeInputs() {
    return OtpCodeInput(
      controller: _otpController,
      focusedBorderColor: const Color(0xFFD4AF37),
      validator: (value) {
        if (value == null || value.length != 5) {
          return 'auth.otp_required'.tr();
        }
        return null;
      },
    );
  }

  String getCodeValue() {
    return _otpController.text;
  }

  @override
  Widget build(BuildContext context) {
    final cubit = ResetPasswordCubit.get(context);

    return BlocListener<ResetPasswordCubit, ResetPasswordState>(
      listener: (context, state) {
        if (state is ResetPasswordLoading) {
          showPrograssDelayDialog(context);
          _dialogShown = true;
          return;
        }

        if (state is ResetPasswordSuccess) {
          if (_dialogShown) {
            Navigator.of(context, rootNavigator: true).maybePop();
            _dialogShown = false;
          }
          Toasters.success('auth.reset_success'.tr());
          Navigator.pushNamedAndRemoveUntil(
            context,
            RoutesName.loginScreen,
            (route) => false,
            arguments: {'mobile': _mobileController.text},
          );
          return;
        }

        if (state is ResetPasswordError) {
          if (_dialogShown) {
            Navigator.of(context, rootNavigator: true).maybePop();
            _dialogShown = false;
          }
          Toasters.errorFrom(state.message, fallbackKey: 'auth.reset_failed');
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
                          'auth.reset_password_title'.tr(),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        // Mobile Input
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
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                            ),
                            validator: ValidationForm.nameValidator,
                          ),
                        ),
                        const SizedBox(height: 20),
                        // OTP Code
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'auth.register_code_hint'.tr(),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 12),
                            buildCodeInputs(),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // New Password Input
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
                            controller: _newPasswordController,
                            obscureText: _isObscured,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                            decoration: InputDecoration(
                              hintText: 'auth.new_password_hint'.tr(),
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
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isObscured
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: Colors.white70,
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
                        const SizedBox(height: 20),
                        // Confirm Password Input
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
                            controller: _confirmPasswordController,
                            obscureText: _isConfirmObscured,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                            decoration: InputDecoration(
                              hintText: 'auth.confirm_password_hint'.tr(),
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
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isConfirmObscured
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: Colors.white70,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isConfirmObscured = !_isConfirmObscured;
                                  });
                                },
                              ),
                            ),
                            validator: (value) {
                              if (value != _newPasswordController.text) {
                                return 'auth.passwords_do_not_match'.tr();
                              }
                              return ValidationForm.passwordValidator(value);
                            },
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Submit Button
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: () {
                              if (formKey.currentState!.validate()) {
                                cubit.resetPassword(
                                  mobile: _mobileController.text,
                                  otp: getCodeValue(),
                                  newPassword: _newPasswordController.text,
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
                              'auth.reset_password_submit'.tr(),
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
