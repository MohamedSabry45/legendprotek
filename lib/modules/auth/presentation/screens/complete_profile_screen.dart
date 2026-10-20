import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:reservation_workshop/config/routes/routes_name.dart';
import 'package:reservation_workshop/core/components/dialogs/prograss_delay_dialog.dart';
import 'package:reservation_workshop/core/components/toasters.dart';
import 'package:reservation_workshop/core/functions/validationform.dart';
import 'package:reservation_workshop/modules/auth/presentation/cubits/auth_otp_cubit/auth_otp_cubit.dart';
import 'package:reservation_workshop/modules/auth/presentation/cubits/auth_otp_cubit/auth_otp_state.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isObscured = true;
  bool _isObscured2 = true;

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _confirmValidator(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'common.required'.tr();
    if (v != _passwordController.text.trim())
      return 'auth.passwords_do_not_match'.tr();
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final cubit = AuthOtpCubit.get(context);

    return BlocListener<AuthOtpCubit, AuthOtpState>(
      listener: (context, state) {
        if (state is CompleteProfileLoading) {
          showPrograssDelayDialog(context);
          return;
        }

        if (state is CompleteProfileSuccess) {
          Navigator.of(context, rootNavigator: true).pop();
          Toasters.success('account.update_success'.tr());
          Navigator.pushNamedAndRemoveUntil(
            context,
            RoutesName.mainScreen,
            (route) => false,
          );
          return;
        }

        if (state is AuthOtpError) {
          Navigator.of(context, rootNavigator: true).maybePop();
          Toasters.errorFrom(
            state.message,
            fallbackKey: 'auth.complete_profile_failed',
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
                      crossAxisAlignment: CrossAxisAlignment.stretch,
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
                          'auth.complete_profile_title'.tr(),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        // Subtitle
                        Text(
                          'auth.complete_profile_subtitle'.tr(),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.white70,
                            height: 1.3,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        // Name Input
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
                            controller: _nameController,
                            validator: ValidationForm.nameValidator,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                              fontSize: 16,
                            ),
                            decoration: InputDecoration(
                              hintText: 'auth.register_name_hint'.tr(),
                              prefixIcon: const Icon(
                                Icons.person_outline,
                                color: Colors.black54,
                              ),
                              filled: true,
                              fillColor: const Color(0xFF050505),
                              hintStyle: const TextStyle(
                                color: Colors.white70,
                                fontWeight: FontWeight.w500,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Password Input
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
                            controller: _passwordController,
                            validator: ValidationForm.passwordValidator,
                            obscureText: _isObscured,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                              fontSize: 16,
                            ),
                            decoration: InputDecoration(
                              hintText: 'auth.login_password_hint'.tr(),
                              prefixIcon: const Icon(
                                Icons.lock_outline,
                                color: Colors.white70,
                              ),
                              filled: true,
                              fillColor: const Color(0xFF050505),
                              hintStyle: const TextStyle(
                                color: Colors.white70,
                                fontWeight: FontWeight.w500,
                              ),
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
                          ),
                        ),
                        const SizedBox(height: 16),
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
                            validator: _confirmValidator,
                            obscureText: _isObscured2,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                              fontSize: 16,
                            ),
                            decoration: InputDecoration(
                              hintText: 'auth.confirm_password_hint'.tr(),
                              prefixIcon: const Icon(
                                Icons.lock_outline,
                                color: Colors.white70,
                              ),
                              filled: true,
                              fillColor: const Color(0xFF050505),
                              hintStyle: const TextStyle(
                                color: Colors.white70,
                                fontWeight: FontWeight.w500,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isObscured2
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: Colors.white70,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isObscured2 = !_isObscured2;
                                  });
                                },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        // Submit Button - Red
                        SizedBox(
                          height: 52,
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              if (formKey.currentState!.validate()) {
                                cubit.completeProfile(
                                  name: _nameController.text,
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
                              'auth.complete_setup'.tr(),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
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
