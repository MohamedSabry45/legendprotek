import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:reservation_workshop/config/routes/routes_name.dart';
import 'package:reservation_workshop/core/components/dialogs/prograss_delay_dialog.dart';
import 'package:reservation_workshop/core/components/toasters.dart';
import 'package:reservation_workshop/constants/app_constants.dart';
import 'package:reservation_workshop/core/network/local/cache_helper.dart';
import 'package:reservation_workshop/core/utils/strings/prefkeys.dart';
import 'package:reservation_workshop/modules/customer/domain/entities/customer_car.dart';
import 'package:reservation_workshop/modules/customer/presentation/cubits/customer_info_cubit/customer_info_cubit.dart';
import 'package:reservation_workshop/modules/customer/presentation/cubits/customer_info_cubit/customer_info_state.dart';
import 'package:reservation_workshop/modules/menu/presentation/cubits/delete_account_cubit/delete_account_cubit.dart';
import 'package:reservation_workshop/modules/menu/presentation/cubits/delete_account_cubit/delete_account_state.dart';

class MenuAccountScreen extends StatefulWidget {
  const MenuAccountScreen({super.key});

  @override
  State<MenuAccountScreen> createState() => _MenuAccountScreenState();
}

class _MenuAccountScreenState extends State<MenuAccountScreen> {
  static const double _headerHeight = 200;

  final _basicInfoFormKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _carController = TextEditingController();
  final _passwordController = TextEditingController(text: '********');
  final _logoutController = TextEditingController();
  bool _didPrefillBasicInfo = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _carController.dispose();
    _passwordController.dispose();
    _logoutController.dispose();
    super.dispose();
  }

  void _prefillBasicInfoIfNeeded({
    required String name,
    required String mobile,
  }) {
    if (_didPrefillBasicInfo) return;

    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((e) => e.trim().isNotEmpty)
        .toList();
    _firstNameController.text = parts.isNotEmpty ? parts.first : '';
    _lastNameController.text = parts.length >= 2
        ? parts.sublist(1).join(' ')
        : '';
    _mobileController.text = mobile;
    _didPrefillBasicInfo = true;
  }

  InputDecoration _fieldDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.5)),
      labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
      filled: true,
      fillColor: const Color(0xFF050505),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFD4AF37), width: 1.4),
      ),
    );
  }

  Future<void> _saveBasicInfo(
    BuildContext context, {
    required int contactId,
  }) async {
    final valid = _basicInfoFormKey.currentState?.validate() ?? false;
    if (!valid) return;

    showPrograssDelayDialog(context);
    try {
      await context.read<CustomerInfoCubit>().updateBasicInfo(
        id: contactId,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        mobile: _mobileController.text.trim(),
      );

      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).maybePop();
      Toasters.successKey('account.update_success');
    } catch (e) {
      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).maybePop();
      Toasters.errorFrom(e, fallbackKey: 'account.update_failed');
    }
  }

  Future<void> _confirmDeleteAccount(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF050505),
          title: Text(
            'account.delete_account'.tr(),
            style: const TextStyle(color: Colors.white),
          ),
          content: Text(
            'account.delete_confirm'.tr(),
            style: TextStyle(color: Colors.white.withOpacity(0.8)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(
                'menu.no'.tr(),
                style: TextStyle(color: Colors.white.withOpacity(0.6)),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4AF37),
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text('menu.yes'.tr()),
            ),
          ],
        );
      },
    );

    if (confirmed == true && context.mounted) {
      context.read<DeleteAccountCubit>().deleteAccount();
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<CustomerInfoCubit>().load();
    });
  }

  Widget _item({
    required IconData icon,
    required String value,
    String? hint,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 56,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF21262D),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  if (hint != null && hint.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      hint,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Container(
              height: 36,
              width: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFD4AF37).withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 20, color: const Color(0xFFD4AF37)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAr = context.locale.languageCode == 'ar';

    return MultiBlocListener(
      listeners: [
        BlocListener<DeleteAccountCubit, DeleteAccountState>(
          listener: (context, state) {
            if (state is DeleteAccountLoading) {
              showPrograssDelayDialog(context);
              return;
            }

            Navigator.of(context, rootNavigator: true).maybePop();

            if (state is DeleteAccountSuccess) {
              Toasters.successKey('account.delete_success');
              Navigator.pushNamedAndRemoveUntil(
                context,
                RoutesName.loginScreen,
                (route) => false,
              );
              return;
            }

            if (state is DeleteAccountError) {
              Toasters.errorFrom(
                state.message,
                fallbackKey: 'account.delete_failed',
              );
              return;
            }
          },
        ),
      ],
      child: Directionality(
        textDirection: isAr ? ui.TextDirection.rtl : ui.TextDirection.ltr,
        child: Scaffold(
          backgroundColor: Colors.black,
          body: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black, Color(0xFF050505), Color(0xFF0A0A0A)],
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Back button
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Colors.white,
                      ),
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                    const SizedBox(height: 16),
                    // Title
                    Text(
                      'account.title'.tr(),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Profile picture
                    Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            height: 120,
                            width: 120,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(.3),
                              shape: BoxShape.circle,
                            ),
                          ),
                          Container(
                            height: 80,
                            width: 80,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(.5),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.person,
                              size: 42,
                              color: Colors.black,
                            ),
                          ),
                          Positioned(
                            bottom: 4,
                            right: 10,
                            child: Container(
                              height: 34,
                              width: 34,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.upload,
                                size: 18,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    // CARD WITH DATA
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF050505),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: const Color(0xFFD4AF37).withOpacity(0.3),
                        ),
                      ),
                      child: BlocBuilder<CustomerInfoCubit, CustomerInfoState>(
                        builder: (context, state) {
                          final name = state is CustomerInfoSuccess
                              ? state.info.name
                              : '-';
                          final phone = state is CustomerInfoSuccess
                              ? state.info.mobile
                              : '-';

                          final cars = state is CustomerInfoSuccess
                              ? state.info.cars
                              : <CustomerCar>[];

                          final carLabel = cars.isNotEmpty
                              ? '${cars.first.device} ${cars.first.model}'
                              : '-';

                          if (state is CustomerInfoSuccess) {
                            _prefillBasicInfoIfNeeded(
                              name: state.info.name,
                              mobile: state.info.mobile,
                            );
                            _carController.text = cars.isNotEmpty
                                ? '${cars.first.device} ${cars.first.model}'
                                : '-';
                          }

                          return Form(
                            key: _basicInfoFormKey,
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: _firstNameController,
                                        enabled: state is CustomerInfoSuccess,
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                        cursorColor: Colors.white,
                                        decoration: _fieldDecoration(
                                          label: 'account.first_name'.tr(),
                                          icon: Icons.person_outline,
                                        ),
                                        validator: (_) => null,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: TextFormField(
                                        controller: _lastNameController,
                                        enabled: state is CustomerInfoSuccess,
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                        cursorColor: Colors.white,
                                        decoration: _fieldDecoration(
                                          label: 'account.last_name'.tr(),
                                          icon: Icons.person_outline,
                                        ),
                                        validator: (_) => null,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _emailController,
                                  enabled: state is CustomerInfoSuccess,
                                  style: const TextStyle(color: Colors.white),
                                  cursorColor: Colors.white,
                                  decoration: _fieldDecoration(
                                    label: 'account.email'.tr(),
                                    icon: Icons.email_outlined,
                                  ),
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty)
                                      return null;
                                    final value = v.trim();
                                    final ok = RegExp(
                                      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                                    ).hasMatch(value);
                                    return ok ? null : 'Invalid email';
                                  },
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _mobileController,
                                  enabled: state is CustomerInfoSuccess,
                                  style: const TextStyle(color: Colors.white),
                                  cursorColor: Colors.white,
                                  decoration: _fieldDecoration(
                                    label: 'account.mobile'.tr(),
                                    icon: Icons.phone_android,
                                  ),
                                  keyboardType: TextInputType.phone,
                                  validator: (_) => null,
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _carController,
                                  enabled: false,
                                  readOnly: true,
                                  style: const TextStyle(color: Colors.white),
                                  cursorColor: Colors.white,
                                  decoration: _fieldDecoration(
                                    label: 'account.car'.tr(),
                                    icon: Icons.directions_car,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _passwordController,
                                  enabled: false,
                                  readOnly: true,
                                  obscureText: true,
                                  style: const TextStyle(color: Colors.white),
                                  cursorColor: Colors.white,
                                  decoration: _fieldDecoration(
                                    label: 'account.password'.tr(),
                                    icon: Icons.lock_outline,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                InkWell(
                                  onTap: () async {
                                    AppConstants.token = null;
                                    await CacheHelper.clearSession();
                                    await CacheHelper.saveData(
                                      key: PrefKeys.kIsGuestMode,
                                      value: true,
                                    );
                                    if (!context.mounted) return;
                                    Navigator.pushNamedAndRemoveUntil(
                                      context,
                                      RoutesName.loginScreen,
                                      (route) => false,
                                    );
                                  },
                                  child: IgnorePointer(
                                    child: TextFormField(
                                      controller: _logoutController
                                        ..text = 'account.logout'.tr(),
                                      enabled: false,
                                      readOnly: true,
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                      cursorColor: Colors.white,
                                      decoration: _fieldDecoration(
                                        label: 'account.logout'.tr(),
                                        icon: Icons.logout,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                InkWell(
                                  onTap: () => _confirmDeleteAccount(context),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    child: Text(
                                      'account.delete_account'.tr(),
                                      style: const TextStyle(
                                        color: const Color(0xFFD4AF37),
                                        fontWeight: FontWeight.w900,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  height: 48,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFD4AF37),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    onPressed: state is CustomerInfoSuccess
                                        ? () => _saveBasicInfo(
                                            context,
                                            contactId: state.info.id,
                                          )
                                        : null,
                                    child: Text(
                                      'account.save'.tr(),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
