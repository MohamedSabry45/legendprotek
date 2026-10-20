import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'dart:ui' as ui;

import 'package:reservation_workshop/config/style/app_colors.dart';
import 'package:reservation_workshop/core/components/dialogs/prograss_delay_dialog.dart';
import 'package:reservation_workshop/core/components/toasters.dart';
import 'package:reservation_workshop/core/widgets/app_card.dart';
import 'package:reservation_workshop/modules/customer/presentation/cubits/customer_info_cubit/customer_info_cubit.dart';
import 'package:reservation_workshop/modules/customer/presentation/cubits/customer_info_cubit/customer_info_state.dart';

import '../../data/models/loyalty_points_model.dart';
import '../cubit/loyalty_points_cubit.dart';
import '../cubit/loyalty_points_state.dart';

class LoyaltyPointsScreen extends StatefulWidget {
  const LoyaltyPointsScreen({super.key});

  @override
  State<LoyaltyPointsScreen> createState() => _LoyaltyPointsScreenState();
}

class _LoyaltyPointsScreenState extends State<LoyaltyPointsScreen> {
  bool _requested = false;
  bool _redeemFlowInProgress = false;
  bool _silentReloadInProgress = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<CustomerInfoCubit>().load();
    });
  }

  void _tryRequestPoints(CustomerInfoState customerState) {
    if (_requested) return;
    if (customerState is! CustomerInfoSuccess) return;

    final contactId = _contactIdFromMobile(customerState.info.mobile);
    if (contactId == null) {
      Toasters.errorKey('points.contact_id_extract_failed');
      return;
    }

    _requested = true;
    context.read<LoyaltyPointsCubit>().load(contactId: contactId);
  }

  int? _contactIdFromMobile(String mobile) {
    final digits = mobile.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 3) return null;
    final last3 = digits.substring(digits.length - 3);
    return int.tryParse(last3);
  }

  int? _currentContactId() {
    final cs = context.read<CustomerInfoCubit>().state;
    if (cs is CustomerInfoSuccess) {
      return _contactIdFromMobile(cs.info.mobile);
    }
    return null;
  }

  void _reloadPoints() {
    final contactId = _currentContactId();
    if (contactId == null) {
      return;
    }
    context.read<LoyaltyPointsCubit>().load(contactId: contactId);
  }

  Future<void> _showRedeemDialog(LoyaltyPointsData data) async {
    final pointsController = TextEditingController();
    final minOrder = double.tryParse(data.minOrderTotalForRedeem) ?? 0;
    final orderController = TextEditingController();

    final amountPerPoint = double.tryParse(data.amountPerPoint) ?? 0;

    final pointsError = ValueNotifier<String?>(null);

    bool adjustingPoints = false;

    void syncOrderTotal() {
      if (adjustingPoints) return;
      final points = int.tryParse(pointsController.text.trim()) ?? 0;

      if (points > data.redeemablePoints) {
        adjustingPoints = true;
        pointsController.text = data.redeemablePoints.toString();
        pointsController.selection = TextSelection.fromPosition(
          TextPosition(offset: pointsController.text.length),
        );
        adjustingPoints = false;
        pointsError.value = 'points.max_points_allowed'.tr(
          args: [data.redeemablePoints.toString()],
        );
        return;
      }

      if (pointsError.value != null) {
        pointsError.value = null;
      }

      if (points <= 0 || amountPerPoint <= 0) {
        if (orderController.text.isNotEmpty) {
          orderController.text = '';
        }
        return;
      }

      final computed = points * amountPerPoint;
      final next = computed.toStringAsFixed(2);
      if (orderController.text != next) {
        orderController.text = next;
      }
    }

    pointsController.addListener(syncOrderTotal);
    syncOrderTotal();

    final res = await showDialog<_RedeemParams>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;

        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 24,
          ),
          backgroundColor: Colors.transparent,
          child: Directionality(
            textDirection: context.locale.languageCode == 'ar'
                ? ui.TextDirection.rtl
                : ui.TextDirection.ltr,
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.only(bottom: bottomInset),
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 420),
                    decoration: BoxDecoration(
                      color: const Color(0xFF050505),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 28,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              padding: const EdgeInsets.fromLTRB(
                                18,
                                18,
                                12,
                                14,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0A0A0A),
                                border: Border(
                                  bottom: BorderSide(
                                    color: const Color(0xFF050505),
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: AppColors.brandPrimarySoft,
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: const Icon(
                                      Icons.workspace_premium_outlined,
                                      color: AppColors.brandPrimary,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'points.redeem_title'.tr(),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () => Navigator.of(ctx).pop(),
                                    icon: const Icon(
                                      Icons.close_rounded,
                                      size: 22,
                                      color: Colors.white70,
                                    ),
                                    splashRadius: 20,
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                18,
                                16,
                                18,
                                18,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  TextField(
                                    controller: pointsController,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                    decoration: InputDecoration(
                                      hintText: 'points.points_hint'.tr(),
                                      filled: true,
                                      fillColor: const Color(0xFF1C2128),
                                      hintStyle: const TextStyle(
                                        color: Colors.white70,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                  ),
                                  ValueListenableBuilder<String?>(
                                    valueListenable: pointsError,
                                    builder: (context, value, _) {
                                      if (value == null) {
                                        return const SizedBox(height: 0);
                                      }
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Text(
                                          value,
                                          style: const TextStyle(
                                            color: AppColors.brandPrimary,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 12,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  TextField(
                                    controller: orderController,
                                    readOnly: true,
                                    enableInteractiveSelection: false,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: InputDecoration(
                                      hintText: 'points.order_total_hint'.tr(),
                                      helperText: (minOrder > 0)
                                          ? 'points.min_order'.tr(
                                              args: [
                                                minOrder.toStringAsFixed(2),
                                              ],
                                            )
                                          : null,
                                      helperStyle: const TextStyle(
                                        color: Colors.white70,
                                      ),
                                      filled: true,
                                      fillColor: const Color(0xFF1C2128),
                                      hintStyle: const TextStyle(
                                        color: Colors.white70,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: () =>
                                              Navigator.of(ctx).pop(),
                                          style: OutlinedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 12,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                            ),
                                            foregroundColor: Colors.white,
                                            side: const BorderSide(
                                              color: Color(0xFF30363D),
                                            ),
                                          ),
                                          child: Text('points.cancel'.tr()),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () {
                                            final points = int.tryParse(
                                              pointsController.text.trim(),
                                            );
                                            final orderTotal =
                                                double.tryParse(
                                                  orderController.text.trim(),
                                                ) ??
                                                0;

                                            if (points == null || points <= 0) {
                                              Toasters.errorKey(
                                                'points.enter_valid_points',
                                              );
                                              return;
                                            }

                                            if (points >
                                                data.redeemablePoints) {
                                              Toasters.errorKey(
                                                'points.points_exceed',
                                              );
                                              return;
                                            }

                                            if (amountPerPoint <= 0) {
                                              Toasters.errorKey(
                                                'points.calc_failed',
                                              );
                                              return;
                                            }

                                            if (orderTotal <= 0) {
                                              Toasters.errorKey(
                                                'points.calc_failed',
                                              );
                                              return;
                                            }

                                            if (minOrder > 0 &&
                                                orderTotal < minOrder) {
                                              Toasters.errorKey(
                                                'points.order_less_than_min',
                                              );
                                              return;
                                            }

                                            Navigator.of(ctx).pop(
                                              _RedeemParams(
                                                points: points,
                                                orderTotal: orderTotal,
                                              ),
                                            );
                                          },
                                          style: ElevatedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 12,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                            ),
                                            backgroundColor:
                                                AppColors.brandPrimary,
                                            foregroundColor: Colors.white,
                                          ),
                                          child: Text('points.confirm'.tr()),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
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
          ),
        );
      },
    );

    pointsController.dispose();
    orderController.dispose();
    pointsError.dispose();

    if (res == null) return;

    if (!mounted) return;
    _redeemFlowInProgress = true;
    context.read<LoyaltyPointsCubit>().redeem(
      pointsToRedeem: res.points,
      orderTotal: res.orderTotal,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<CustomerInfoCubit, CustomerInfoState>(
          listener: (context, state) {
            if (state is CustomerInfoError) {
              Toasters.errorFrom(state.message);
            }
            _tryRequestPoints(state);
          },
        ),
        BlocListener<LoyaltyPointsCubit, LoyaltyPointsState>(
          listener: (context, state) {
            if (state is LoyaltyPointsLoading ||
                state is LoyaltyPointsRedeemLoading) {
              if (!_silentReloadInProgress) {
                showPrograssDelayDialog(context);
              }
              return;
            }

            Navigator.of(context, rootNavigator: true).maybePop();

            if (_silentReloadInProgress) {
              if (state is LoyaltyPointsSuccess) {
                _silentReloadInProgress = false;
              } else if (state is LoyaltyPointsError) {
                _silentReloadInProgress = false;
              }
              return;
            }

            if (_redeemFlowInProgress) {
              if (state is LoyaltyPointsSuccess) {
                _redeemFlowInProgress = false;
                Toasters.successKey('points.redeem_success');
                _silentReloadInProgress = true;
                _reloadPoints();
                return;
              }

              if (state is LoyaltyPointsError) {
                _redeemFlowInProgress = false;
                Toasters.errorFrom(
                  state.message,
                  fallbackKey: 'points.redeem_failed',
                );
                return;
              }
            }
          },
        ),
      ],
      child: Directionality(
        textDirection: context.locale.languageCode == 'ar'
            ? ui.TextDirection.rtl
            : ui.TextDirection.ltr,
        child: Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text(
              'points.title'.tr(),
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            foregroundColor: Colors.white,
            iconTheme: const IconThemeData(color: Colors.white),
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
              top: false,
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                child: BlocBuilder<CustomerInfoCubit, CustomerInfoState>(
                  builder: (context, customerState) {
                    _tryRequestPoints(customerState);

                    return BlocBuilder<LoyaltyPointsCubit, LoyaltyPointsState>(
                      builder: (context, pointsState) {
                        final cubit = context.read<LoyaltyPointsCubit>();
                        final data = cubit.cachedData;

                        if (customerState is CustomerInfoLoading ||
                            customerState is CustomerInfoInitial) {
                          return const _LoadingView();
                        }

                        if (pointsState is LoyaltyPointsError && data == null) {
                          return _ErrorView(
                            message: pointsState.message,
                            onRetry: () {
                              _requested = false;
                              context.read<CustomerInfoCubit>().load();
                            },
                          );
                        }

                        if (pointsState is LoyaltyPointsLoading ||
                            pointsState is LoyaltyPointsInitial) {
                          return const _LoadingView();
                        }

                        if (data == null || data.totalPoints == 0) {
                          return _EmptyView();
                        }

                        return RefreshIndicator(
                          onRefresh: () async {
                            final cs = context.read<CustomerInfoCubit>().state;
                            if (cs is CustomerInfoSuccess) {
                              final contactId = _contactIdFromMobile(
                                cs.info.mobile,
                              );
                              if (contactId != null) {
                                await context.read<LoyaltyPointsCubit>().load(
                                  contactId: contactId,
                                );
                              }
                            }
                          },
                          child: ListView(
                            children: [
                              AppCard(
                                padding: const EdgeInsets.all(18),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 54,
                                      height: 54,
                                      decoration: BoxDecoration(
                                        color: AppColors.brandPrimarySoft,
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                      child: const Icon(
                                        Icons.workspace_premium_outlined,
                                        color: AppColors.brandPrimary,
                                        size: 28,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'points.balance_title'.tr(),
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w800,
                                              color: Colors.white70,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                '${data.totalPoints}',
                                                style: const TextStyle(
                                                  fontSize: 34,
                                                  fontWeight: FontWeight.w900,
                                                  color: AppColors.brandDark,
                                                  height: 1,
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Padding(
                                                padding: EdgeInsets.only(
                                                  bottom: 3,
                                                ),
                                                child: Text(
                                                  'points.point_singular'.tr(),
                                                  style: const TextStyle(
                                                    color: Colors.white70,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: _StatCard(
                                      icon: Icons.check_circle_outline,
                                      title: 'points.redeemable'.tr(),
                                      value: '${data.redeemablePoints}',
                                      subtitle: 'points.point_singular'.tr(),
                                      color: AppColors.brandPrimary,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _StatCard(
                                      icon: Icons.payments_outlined,
                                      title: 'points.equals'.tr(),
                                      value: data.redeemableAmount
                                          .toStringAsFixed(0),
                                      subtitle: 'points.currency'.tr(),
                                      color: AppColors.brandDark,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _StatCard(
                                      icon: Icons.shopping_bag_outlined,
                                      title: 'points.used'.tr(),
                                      value: '${data.pointsUsed}',
                                      subtitle: 'points.point_singular'.tr(),
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _StatCard(
                                      icon: Icons.access_time,
                                      title: 'points.expired'.tr(),
                                      value: '${data.pointsExpired}',
                                      subtitle: 'points.point_singular'.tr(),
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              AppCard(
                                padding: const EdgeInsets.all(18),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: AppColors.brandPrimarySoft,
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.redeem_outlined,
                                            color: AppColors.brandPrimary,
                                            size: 22,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            'points.redeem_title'.tr(),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w900,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      data.enableRp
                                          ? 'points.redeem_description_enabled'
                                                .tr()
                                          : 'points.redeem_description_disabled'
                                                .tr(),
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        height: 1.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        onPressed:
                                            (!data.enableRp ||
                                                data.redeemablePoints <= 0)
                                            ? null
                                            : () => _showRedeemDialog(data),
                                        style: ElevatedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 14,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
                                          ),
                                          backgroundColor:
                                              AppColors.brandPrimary,
                                          foregroundColor: Colors.white,
                                          disabledBackgroundColor:
                                              Colors.black12,
                                          disabledForegroundColor:
                                              Colors.black38,
                                          elevation: 0,
                                        ),
                                        child: Text('points.redeem_title'.tr()),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
  });

  final IconData icon;

  final String title;
  final String value;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: color,
                  height: 1,
                ),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Container(
          height: 140,
          decoration: BoxDecoration(
            color: const Color(0xFF21262D),
            borderRadius: BorderRadius.circular(22),
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(child: _LoadingBox(height: 100)),
            const SizedBox(width: 12),
            Expanded(child: _LoadingBox(height: 100)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _LoadingBox(height: 100)),
            const SizedBox(width: 12),
            Expanded(child: _LoadingBox(height: 100)),
          ],
        ),
        const SizedBox(height: 18),
        const _LoadingBox(height: 160),
      ],
    );
  }
}

class _LoadingBox extends StatelessWidget {
  const _LoadingBox({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFF21262D),
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF21262D),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.brandPrimary.withOpacity(0.3),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(
              Icons.workspace_premium_outlined,
              color: AppColors.brandPrimary,
              size: 36,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'points.load_failed'.tr(),
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 18,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              height: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                backgroundColor: AppColors.brandPrimary,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              child: Text(
                'points.retry'.tr(),
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF050505),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.brandPrimary.withOpacity(0.3),
                    blurRadius: 22,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.workspace_premium_outlined,
                color: AppColors.brandPrimary,
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'points.no_points'.tr(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'points.no_points_subtitle'.tr(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RedeemParams {
  final int points;
  final double orderTotal;

  const _RedeemParams({required this.points, required this.orderTotal});
}
