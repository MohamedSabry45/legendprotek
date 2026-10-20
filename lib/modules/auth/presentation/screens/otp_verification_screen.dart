import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:reservation_workshop/config/routes/routes_name.dart';
import 'package:reservation_workshop/config/style/text_styles.dart';
import 'package:reservation_workshop/core/components/app_textfield.dart';
import 'package:reservation_workshop/core/components/dialogs/prograss_delay_dialog.dart';
import 'package:reservation_workshop/core/components/toasters.dart';
import 'package:reservation_workshop/core/functions/validationform.dart';
import 'package:reservation_workshop/core/widgets/otp_code_input.dart';
import 'package:reservation_workshop/core/widgets/app_single_button.dart';
import 'package:reservation_workshop/core/widgets/logo_image_widget.dart';
import 'package:reservation_workshop/core/widgets/splash_image_widget.dart';
import 'package:reservation_workshop/modules/auth/presentation/cubits/register_cubit/register_cubit.dart';
import 'package:reservation_workshop/modules/auth/presentation/cubits/register_cubit/register_state.dart';

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({super.key});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  /// OTP (5 digits)
  final TextEditingController _otpController = TextEditingController();

  bool _isObscured = true;
  bool _didPrefill = false;

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
    _nameController.dispose();
    _mobileController.dispose();
    _passwordController.dispose();
    _otpController.dispose();

    super.dispose();
  }

  // ================= OTP =================
  Widget buildCodeInputs() {
    return OtpCodeInput(
      controller: _otpController,
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
    final cubit = RegisterCubit.get(context);

    return BlocListener<RegisterCubit, RegisterState>(
      listener: (context, state) {
        if (state is RegisterLoading) {
          showPrograssDelayDialog(context);
          return;
        }

        if (state is RegisterSuccess) {
          Navigator.of(context, rootNavigator: true).maybePop();
          Toasters.success('auth.register_success'.tr());
          Navigator.pushNamedAndRemoveUntil(
            context,
            RoutesName.homeScreen,
            (route) => false,
          );
          return;
        }

        if (state is RegisterError) {
          Navigator.of(context, rootNavigator: true).maybePop();
          Toasters.errorFrom(
            state.message,
            fallbackKey: 'auth.register_failed',
          );
          return;
        }
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: LayoutBuilder(
          builder: (context, constraints) {
            final bool isWide = constraints.maxWidth >= 900;

            final form = Form(
              key: formKey,
              child: Column(
                children: [
                  AppTextFormField(
                    hintText: 'auth.register_name_hint'.tr(),
                    controller: _nameController,
                    validator: ValidationForm.nameValidator,
                  ),
                  const SizedBox(height: 20),

                  AppTextFormField(
                    hintText: 'auth.register_mobile_hint'.tr(),
                    controller: _mobileController,
                    validator: ValidationForm.nameValidator,
                  ),
                  const SizedBox(height: 20),

                  AppTextFormField(
                    hintText: 'auth.register_password_hint'.tr(),
                    obscureText: _isObscured,
                    maxLines: 1,
                    controller: _passwordController,
                    validator: ValidationForm.passwordValidator,
                    fixIcon: IconButton(
                      icon: Icon(
                        _isObscured ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _isObscured = !_isObscured;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 24),

                  /// ===== OTP =====
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'auth.register_code_hint'.tr(),
                        style: AppTextStyle.cairoBold16Black,
                      ),
                      const SizedBox(height: 12),
                      buildCodeInputs(),
                    ],
                  ),

                  const SizedBox(height: 28),

                  AppSingleButton(
                    height: 50,
                    width: isWide
                        ? MediaQuery.of(context).size.width / 3
                        : double.infinity,
                    onPressed: () {
                      if (formKey.currentState!.validate()) {
                        cubit.register(
                          name: _nameController.text,
                          mobile: _mobileController.text,
                          password: _passwordController.text,
                        );
                      }
                    },
                    text: 'auth.register_button'.tr(),
                    color: const Color(0xFFD4AF37),
                  ),
                ],
              ),
            );

            if (isWide) {
              return Row(
                children: [
                  SizedBox(
                    width: constraints.maxWidth / 2,
                    child: Center(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const LogoImageWidget(),
                            Text(
                              'auth.welcome_title'.tr(),
                              style: AppTextStyle.cairoBold36Black,
                            ),
                            const SizedBox(height: 30),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 50,
                              ),
                              child: Card(
                                color: Colors.black,
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 18,
                                  ),
                                  child: form,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SplashImageWidget(),
                ],
              );
            }

            return SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 24,
                  ),
                  child: Column(
                    children: [
                      const LogoImageWidget(),
                      const SizedBox(height: 12),
                      Text(
                        'auth.welcome_title'.tr(),
                        style: AppTextStyle.cairoBold36Black,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      Card(
                        color: Colors.black,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 18,
                          ),
                          child: form,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
