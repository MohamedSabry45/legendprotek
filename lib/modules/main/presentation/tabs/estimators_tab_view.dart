import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:reservation_workshop/config/routes/routes_name.dart';
import 'package:reservation_workshop/core/network/local/cache_helper.dart';
import 'package:reservation_workshop/core/utils/strings/prefkeys.dart';
import 'package:reservation_workshop/core/widgets/login_required_view.dart';
import 'package:reservation_workshop/modules/customer/presentation/cubits/customer_info_cubit/customer_info_cubit.dart';
import 'package:reservation_workshop/modules/customer/presentation/cubits/customer_info_cubit/customer_info_state.dart';
import 'package:reservation_workshop/modules/job_estimators/presentation/cubits/job_estimators_cubit.dart';
import 'package:reservation_workshop/modules/job_estimators/presentation/cubits/job_estimators_state.dart';
import 'package:reservation_workshop/modules/job_estimators/presentation/screens/job_estimator_details_args.dart';
import 'package:reservation_workshop/modules/job_estimators/presentation/widgets/job_estimator_card.dart';
import 'package:reservation_workshop/modules/branch/presentation/cubits/branch_cubit/branch_cubit.dart';
import 'package:reservation_workshop/core/components/toasters.dart';
import 'package:reservation_workshop/modules/service/presentation/cubits/service_cubit/service_cubit.dart';
import 'package:reservation_workshop/modules/job_estimators/presentation/cubits/create_job_estimator_cubit/create_job_estimator_cubit.dart';
import 'package:reservation_workshop/modules/job_estimators/presentation/widgets/create_job_estimator_dialog.dart';

class EstimatorsTabView extends StatefulWidget {
  const EstimatorsTabView({super.key});

  @override
  State<EstimatorsTabView> createState() => _EstimatorsTabViewState();
}

class _EstimatorsTabViewState extends State<EstimatorsTabView> {
  Future<void> _openCreateEstimatorDialog() async {
    final existingBranchCubit = context.read<BranchCubit>();
    final existingCustomerCubit = context.read<CustomerInfoCubit>();
    final existingServiceCubit = context.read<ServiceCubit>();

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return MultiBlocProvider(
          providers: [
            BlocProvider.value(value: existingBranchCubit),
            BlocProvider.value(value: existingCustomerCubit),
            BlocProvider.value(value: existingServiceCubit),
            BlocProvider<CreateJobEstimatorCubit>(create: (_) => CreateJobEstimatorCubit()),
          ],
          child: CreateJobEstimatorDialog(
            onCreated: () {
              final s = existingCustomerCubit.state;
              if (s is CustomerInfoSuccess) {
                context.read<JobEstimatorsCubit>().load(customerId: s.info.id);
              }
            },
          ),
        );
      },
    );
  }
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final isGuest = CacheHelper.getData<bool>(key: PrefKeys.kIsGuestMode) ?? false;
      if (isGuest) return;
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
    final isGuest = CacheHelper.getData<bool>(key: PrefKeys.kIsGuestMode) ?? false;
    if (isGuest) {
      return const LoginRequiredView();
    }
    final textTheme = Theme.of(context).textTheme;
    return BlocConsumer<CustomerInfoCubit, CustomerInfoState>(
      listener: (context, state) {
        if (state is CustomerInfoSuccess) {
          context.read<JobEstimatorsCubit>().load(customerId: state.info.id);
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
                    style: textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ),
              );
            }
            final items = state is JobEstimatorsSuccess ? state.estimators : const [];

            String last4FromPhone(String phone) {
              String digitsOnly = phone.replaceAll(RegExp(r'[^0-9]'), '');
              if (digitsOnly.length > 4) {
                digitsOnly = digitsOnly.substring(digitsOnly.length - 4);
              }
              return digitsOnly.padLeft(4, '0');
            }

            final last4 = customerState is CustomerInfoSuccess ? last4FromPhone(customerState.info.mobile) : '0000';

            return Stack(
              children: [
                if (items.isEmpty)
                  Center(
                    child: Text(
                      'tabs.empty_estimators'.tr(),
                      style: textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    padding: const EdgeInsets.fromLTRB(0, 8, 0, 100),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = items[index];
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
                  ),
                Positioned(
                  right: 0,
                  bottom: 8,
                  child: FloatingActionButton(
                    heroTag: 'create_estimator_fab_tab',
                    backgroundColor: const Color(0xFFD4AF37),
                    onPressed: _openCreateEstimatorDialog,
                    child: const Icon(Icons.add, color: Colors.black),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
