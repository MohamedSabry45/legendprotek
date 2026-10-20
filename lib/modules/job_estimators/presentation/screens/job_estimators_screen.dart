import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:reservation_workshop/modules/customer/presentation/cubits/customer_info_cubit/customer_info_cubit.dart';
import 'package:reservation_workshop/modules/customer/presentation/cubits/customer_info_cubit/customer_info_state.dart';

import 'package:reservation_workshop/config/routes/routes_name.dart';
import '../cubits/job_estimators_cubit.dart';
import 'package:reservation_workshop/core/components/toasters.dart';

import '../cubits/job_estimators_state.dart';
import '../widgets/job_estimator_card.dart';
import '../screens/job_estimator_details_args.dart';

class JobEstimatorsScreen extends StatefulWidget {
  const JobEstimatorsScreen({super.key});

  @override
  State<JobEstimatorsScreen> createState() => _JobEstimatorsScreenState();
}

class _JobEstimatorsScreenState extends State<JobEstimatorsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final customerState = context.read<CustomerInfoCubit>().state;
      if (customerState is! CustomerInfoSuccess) {
        context.read<CustomerInfoCubit>().load();
      }
      final s = context.read<CustomerInfoCubit>().state;
      if (s is CustomerInfoSuccess) {
        context.read<JobEstimatorsCubit>().load(customerId: s.info.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF050505),
        elevation: 0,
        title: Text(
          'job_estimators.title'.tr(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: BlocConsumer<CustomerInfoCubit, CustomerInfoState>(
          listener: (context, state) {
            if (state is CustomerInfoSuccess) {
              context.read<JobEstimatorsCubit>().load(
                customerId: state.info.id,
              );
            }
          },
          builder: (context, customerState) {
            return BlocBuilder<JobEstimatorsCubit, JobEstimatorsState>(
              builder: (context, state) {
                if (state is JobEstimatorsLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is JobEstimatorsError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        Toasters.displayMessage(state.message),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  );
                }
                final items = state is JobEstimatorsSuccess
                    ? state.estimators
                    : const [];
                if (items.isEmpty) {
                  return Center(
                    child: Text(
                      'job_estimators.empty'.tr(),
                      style: const TextStyle(
                        fontSize: 12,
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
                    final item = items[index];
                    final phone = customerState is CustomerInfoSuccess
                        ? customerState.info.mobile
                        : '';
                    String digitsOnly = phone.replaceAll(RegExp(r'[^0-9]'), '');
                    if (digitsOnly.length > 4) {
                      digitsOnly = digitsOnly.substring(digitsOnly.length - 4);
                    }
                    final last4 = digitsOnly.padLeft(4, '0');
                    return JobEstimatorCard(
                      item: item,
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          RoutesName.jobEstimatorDetailsScreen,
                          arguments: JobEstimatorDetailsArgs(
                            id: item.id,
                            phoneLast4: last4,
                          ),
                        );
                      },
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
