import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:reservation_workshop/config/routes/routes_name.dart';
import 'package:reservation_workshop/core/components/dialogs/prograss_delay_dialog.dart';
import 'package:reservation_workshop/core/components/toasters.dart';
import 'package:reservation_workshop/core/widgets/otp_code_input.dart';
import 'package:reservation_workshop/modules/auth/presentation/cubits/social_auth_cubit/social_auth_cubit.dart';
import 'package:reservation_workshop/modules/auth/presentation/cubits/social_auth_cubit/social_auth_state.dart';

class SocialOtpVerificationScreen extends StatefulWidget {
  const SocialOtpVerificationScreen({super.key});

  @override
  State<SocialOtpVerificationScreen> createState() =>
      _SocialOtpVerificationScreenState();
}

class _SocialOtpVerificationScreenState
    extends State<SocialOtpVerificationScreen> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  bool _didPrefill = false;
  bool _dialogShown = false;

  String _email = '';
  String _name = '';
  String _medium = '';
  String _uniqueId = '';
  int? _userId;

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

      _email = args['email']?.toString() ?? '';
      _name = args['name']?.toString() ?? '';
      _medium = args['medium']?.toString() ?? '';
      _uniqueId = args['unique_id']?.toString() ?? '';
      final userIdRaw = args['user_id'];
      _userId = userIdRaw == null ? null : int.tryParse(userIdRaw.toString());
    }
  }

  @override
  void dispose() {
    _mobileController.dispose();
    _otpController.dispose();
    super.dispose();
  }

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

  String getCodeValue() => _otpController.text;

  @override
  Widget build(BuildContext context) {
    final socialCubit = SocialAuthCubit.get(context);

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
          Navigator.pushNamedAndRemoveUntil(
            context,
            RoutesName.homeScreen,
            (route) => false,
          );
          return;
        }

        if (state is SocialAuthRestoreRequired) {
          if (_dialogShown) {
            Navigator.of(context, rootNavigator: true).maybePop();
            _dialogShown = false;
          }
          Toasters.show(
            Toasters.cleanError(state.message) ??
                'auth.restore_account_message'.tr(),
          );
          return;
        }

        if (state is SocialAuthError) {
          if (_dialogShown) {
            Navigator.of(context, rootNavigator: true).maybePop();
            _dialogShown = false;
          }
          Toasters.errorFrom(state.message, fallbackKey: 'auth.verify_failed');
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
                          'auth.enter_verification_code'.tr(),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        // Mobile Number Display
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF050505),
                            border: Border.all(
                              color: const Color(0xFF0A0A0A),
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          child: Text(
                            _mobileController.text.isEmpty
                                ? 'auth.register_mobile_hint'.tr()
                                : _mobileController.text,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // OTP Code Inputs
                        buildCodeInputs(),
                        const SizedBox(height: 24),
                        // Verify Button
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: () {
                              if (formKey.currentState!.validate()) {
                                socialCubit.verifyPhoneAndSetMobile(
                                  email: _email,
                                  name: _name,
                                  phone: _mobileController.text,
                                  otp: getCodeValue(),
                                  medium: _medium,
                                  uniqueId: _uniqueId,
                                  userId: _userId,
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
                              'auth.verify'.tr(),
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
