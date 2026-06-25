import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:reservation_workshop/config/routes/routes_name.dart';
import 'package:reservation_workshop/core/components/dialogs/prograss_delay_dialog.dart';
import 'package:reservation_workshop/core/components/toasters.dart';
import 'package:reservation_workshop/core/functions/validationform.dart';
import 'package:reservation_workshop/modules/auth/presentation/cubits/register_cubit/register_cubit.dart';
import 'package:reservation_workshop/modules/auth/presentation/cubits/register_cubit/register_state.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

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
    super.dispose();
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
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                  child: Form(
                    key: formKey,
                    child: Column(
                      children: [
                        const SizedBox(height: 16),
                        // Logo
                        Image.asset(
                          'assets/images/logo.png',
                          height: 100,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 28),
                        // Name Input - White background with border
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF0A0A0A),
                            border: Border.all(color: const Color(0xFF0A0A0A), width: 2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TextFormField(
                            controller: _nameController,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                            decoration: InputDecoration(
                              hintText: 'auth.register_name_hint'.tr(),
                              hintStyle: const TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                              filled: true,
                              fillColor: const Color(0xFF0A0A0A),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            ),
                            validator: ValidationForm.nameValidator,
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Mobile Input - White background with border
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF0A0A0A),
                            border: Border.all(color: const Color(0xFF0A0A0A), width: 2),
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
                              hintText: 'auth.register_mobile_hint'.tr(),
                              hintStyle: const TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                              filled: true,
                              fillColor: const Color(0xFF0A0A0A),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            ),
                            validator: ValidationForm.nameValidator,
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Password Input - White background with border
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF0A0A0A),
                            border: Border.all(color: const Color(0xFF0A0A0A), width: 2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TextFormField(
                            controller: _passwordController,
                            obscureText: _isObscured,
                            maxLines: 1,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                            decoration: InputDecoration(
                              hintText: 'auth.register_password_hint'.tr(),
                              hintStyle: const TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                              filled: true,
                              fillColor: const Color(0xFF050505),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isObscured ? Icons.visibility_off : Icons.visibility,
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
                        const SizedBox(height: 24),
                        // Register Button - Red
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: () {
                              if (formKey.currentState!.validate()) {
                                cubit.register(
                                  name: _nameController.text,
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
                              'auth.register_button'.tr(),
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
