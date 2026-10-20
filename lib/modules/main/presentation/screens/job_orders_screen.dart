import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:reservation_workshop/config/routes/routes_name.dart';
import 'package:reservation_workshop/core/network/local/cache_helper.dart';
import 'package:reservation_workshop/core/utils/strings/prefkeys.dart';
import 'package:reservation_workshop/modules/main/presentation/widgets/job_order_card.dart';
import 'package:reservation_workshop/modules/job_orders/presentation/cubits/job_orders_cubit/job_orders_cubit.dart';
import 'package:reservation_workshop/modules/job_orders/presentation/cubits/job_orders_cubit/job_orders_state.dart';
import 'package:reservation_workshop/modules/job_order_details/presentation/screens/job_order_details_args.dart';
import 'package:reservation_workshop/core/components/toasters.dart';
import 'package:reservation_workshop/modules/job_order_details/presentation/screens/job_order_details_phone_prompt.dart';
import 'package:reservation_workshop/modules/customer/presentation/cubits/customer_info_cubit/customer_info_cubit.dart';
import 'package:reservation_workshop/modules/customer/presentation/cubits/customer_info_cubit/customer_info_state.dart';

class JobOrdersScreen extends StatelessWidget {
  const JobOrdersScreen({super.key});

  Future<String?> _ensurePhoneLast4(BuildContext context) async {
    final cached = CacheHelper.getData<String>(
      key: PrefKeys.kJobOrderPhoneLast4,
    );
    if (cached != null && cached.trim().length == 4) {
      return cached.trim();
    }

    // Try to derive last 4 digits from loaded customer info
    try {
      final customerCubit = context.read<CustomerInfoCubit>();
      CustomerInfoState customerState = customerCubit.state;

      if (customerState is! CustomerInfoSuccess) {
        await customerCubit.load();
        customerState = customerCubit.state;
      }

      if (customerState is CustomerInfoSuccess) {
        final mobile = customerState.info.mobile.trim();
        final digits = mobile
            .replaceAll(RegExp(r'[^0-9\u0660-\u0669]'), '')
            .replaceAllMapped(RegExp(r'[\u0660-\u0669]'), (m) {
              // Convert Arabic-Indic numerals to ASCII 0-9
              final code = m[0]!.codeUnitAt(0) - 0x0660;
              return code.toString();
            });
        if (digits.length >= 4) {
          final last4 = digits.substring(digits.length - 4);
          await CacheHelper.saveData(
            key: PrefKeys.kJobOrderPhoneLast4,
            value: last4,
          );
          return last4;
        }
      }
    } catch (_) {
      // Ignore and fallback to manual prompt
    }

    final last4 = await showDialog<String?>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const JobOrderDetailsPhonePrompt(),
    );
    final v = last4?.trim();
    if (v == null || v.isEmpty) return null;
    await CacheHelper.saveData(key: PrefKeys.kJobOrderPhoneLast4, value: v);
    return v;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      context.read<JobOrdersCubit>().load();
    });

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Text(
          'job_order.list_title'.tr(),
          style: const TextStyle(
            color: Color(0xFFD4AF37),
            fontWeight: FontWeight.w900,
          ),
        ),
        foregroundColor: const Color(0xFFD4AF37),
        iconTheme: const IconThemeData(color: Color(0xFFD4AF37)),
      ),
      body: SafeArea(
        child: BlocBuilder<JobOrdersCubit, JobOrdersState>(
          builder: (context, state) {
            if (state is JobOrdersLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is JobOrdersError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    Toasters.displayMessage(state.message),
                    textAlign: TextAlign.center,
                    style: textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                    ),
                  ),
                ),
              );
            }

            final orders = state is JobOrdersSuccess ? state.orders : const [];
            final items = orders
                .map(
                  (o) => JobOrderCardModel(
                    jobOrderId: o.id,
                    plateNumber: o.plateNumber,
                    jobSheetNo: o.jobSheetNo,
                    status: o.workshop == null || o.workshop!.trim().isEmpty
                        ? 'job_order.pending'.tr()
                        : o.workshop!,
                    branch: o.location,
                    carType: '${o.brand} ${o.model} ${o.manufacturingYear}'
                        .trim(),
                    bookingDate: null,
                  ),
                )
                .toList();

            if (items.isEmpty) {
              return Center(
                child: Text(
                  'job_order.empty'.tr(),
                  style: textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                  ),
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final model = items[index];
                return JobOrderCard(
                  model: model,
                  onTap: () async {
                    final phoneLast4 = await _ensurePhoneLast4(context);
                    if (phoneLast4 == null) return;
                    if (!context.mounted) return;
                    Navigator.pushNamed(
                      context,
                      RoutesName.jobOrderDetailsScreen,
                      arguments: JobOrderDetailsArgs(
                        jobOrderId: model.jobOrderId,
                        phoneLast4: phoneLast4,
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
