import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';

import 'package:reservation_workshop/config/routes/routes_name.dart';
import 'package:reservation_workshop/config/style/app_colors.dart';
import 'package:reservation_workshop/config/style/text_styles.dart';
import 'package:reservation_workshop/core/components/app_textfield.dart';
import 'package:reservation_workshop/core/components/dialogs/prograss_delay_dialog.dart';
import 'package:reservation_workshop/core/components/toasters.dart';
import 'package:reservation_workshop/core/functions/validationform.dart';
import 'package:reservation_workshop/core/utils/strings/app_strings.dart';
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
  final List<TextEditingController> _codeControllers =
      List.generate(5, (_) => TextEditingController());
  final List<FocusNode> _codeFocusNodes =
      List.generate(5, (_) => FocusNode());

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

    for (final c in _codeControllers) {
      c.dispose();
    }
    for (final f in _codeFocusNodes) {
      f.dispose();
    }

    super.dispose();
  }

  // ================= OTP =================
  Widget buildCodeInputs() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(5, (index) {
        return Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: SizedBox(
            width: 56,
            height: 56,
            child: TextFormField(
              controller: _codeControllers[index],
              focusNode: _codeFocusNodes[index],
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 1,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              decoration: InputDecoration(
                counterText: '',
                filled: true,
                fillColor: const Color(0xFF050505),

                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: const Color(0xFF0A0A0A),
                    width: 1.5,
                  ),
                ),

                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: Colors.white,
                    width: 2,
                  ),
                ),

                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: const Color(0xFFD4AF37),
                    width: 1.5,
                  ),
                ),
              ),
              onChanged: (value) {
                if (value.isNotEmpty && index < 4) {
                  _codeFocusNodes[index + 1].requestFocus();
                } else if (value.isEmpty && index > 0) {
                  _codeFocusNodes[index - 1].requestFocus();
                }
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '';
                }
                return null;
              },
            ),
          ),
        );
      }),
    );
  }

  String getCodeValue() {
    return _codeControllers.map((c) => c.text).join();
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
          Navigator.pushNamedAndRemoveUntil(
            context,
            RoutesName.chooseCarScreen,
            (route) => false,
          );
          return;
        }

        if (state is RegisterError) {
          Navigator.of(context, rootNavigator: true).maybePop();
          Toasters.show(state.message);
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
                        _isObscured
                            ? Icons.visibility_off
                            : Icons.visibility,
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
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 50),
                              child: Card(
                                color: Colors.black,
                                elevation: 2,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
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
                      horizontal: 16, vertical: 24),
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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
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
