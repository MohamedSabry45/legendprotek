import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:reservation_workshop/config/style/app_colors.dart';
import 'package:reservation_workshop/core/components/toasters.dart';
import 'package:reservation_workshop/core/network/local/cache_helper.dart';
import 'package:reservation_workshop/core/utils/strings/prefkeys.dart';
import 'package:reservation_workshop/modules/branch/domain/entities/branch.dart';
import 'package:reservation_workshop/modules/branch/presentation/cubits/branch_cubit/branch_cubit.dart';
import 'package:reservation_workshop/modules/branch/presentation/cubits/branch_cubit/branch_state.dart';
import 'package:reservation_workshop/modules/customer/domain/entities/customer_car.dart';
import 'package:reservation_workshop/modules/customer/presentation/cubits/customer_info_cubit/customer_info_cubit.dart';
import 'package:reservation_workshop/modules/customer/presentation/cubits/customer_info_cubit/customer_info_state.dart';
import 'package:reservation_workshop/modules/main/presentation/widgets/booking_dropdown_field.dart';
import 'package:reservation_workshop/modules/service/domain/entities/service.dart';
import 'package:reservation_workshop/modules/service/presentation/cubits/service_cubit/service_cubit.dart';
import 'package:reservation_workshop/modules/service/presentation/cubits/service_cubit/service_state.dart';

import '../cubits/create_job_estimator_cubit/create_job_estimator_cubit.dart';
import '../cubits/create_job_estimator_cubit/create_job_estimator_state.dart';

class CreateJobEstimatorDialog extends StatefulWidget {
  const CreateJobEstimatorDialog({super.key, required this.onCreated});

  final VoidCallback onCreated;

  @override
  State<CreateJobEstimatorDialog> createState() =>
      _CreateJobEstimatorDialogState();
}

class _CreateJobEstimatorDialogState extends State<CreateJobEstimatorDialog> {
  int? _selectedBranchId;
  int? _selectedCarId;
  int? _selectedServiceId;

  final TextEditingController _vehicleDetailsController =
      TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  bool _sendSms = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      final customerState = context.read<CustomerInfoCubit>().state;
      if (customerState is! CustomerInfoSuccess) {
        context.read<CustomerInfoCubit>().load();
      }

      final branchState = context.read<BranchCubit>().state;
      if (branchState is! BranchSuccess) {
        context.read<BranchCubit>().load();
      }

      final carId = await CacheHelper.getDataAsync<int>(
        key: PrefKeys.kSelectedCarId,
      );
      if (!mounted) return;
      setState(() => _selectedCarId = carId);
    });
  }

  @override
  void dispose() {
    _vehicleDetailsController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  num? _parseAmount(String value) {
    final cleaned = value.trim().replaceAll(',', '.');
    if (cleaned.isEmpty) return null;
    return num.tryParse(cleaned);
  }

  @override
  Widget build(BuildContext context) {
    final customerState = context.watch<CustomerInfoCubit>().state;
    final contactId = customerState is CustomerInfoSuccess
        ? customerState.info.id
        : 0;
    final cars = customerState is CustomerInfoSuccess
        ? customerState.info.cars
        : const <CustomerCar>[];
    const dialogTextColor = Colors.white;
    const inputFillColor = Color(0xFFF7F8FA);

    return Directionality(
      textDirection: Directionality.of(context),
      child: BlocConsumer<CreateJobEstimatorCubit, CreateJobEstimatorState>(
        listener: (context, state) {
          if (state is CreateJobEstimatorSuccess) {
            widget.onCreated();
            final estimateNo = state.estimateNo.toString().trim();
            Toasters.success(
              estimateNo.isEmpty
                  ? 'job_estimators.create.success_title'.tr()
                  : '${'job_estimators.create.success_title'.tr()} — ${'job_estimators.create.estimate_no'.tr()} $estimateNo',
            );
            Navigator.pop(context);
          }
          if (state is CreateJobEstimatorError) {
            Toasters.errorFrom(
              state.message,
              fallbackKey: 'job_estimators.create.failed_title',
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is CreateJobEstimatorLoading;

          return AlertDialog(
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 20,
            ),
            backgroundColor: AppColors.brandDark,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            titlePadding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            actionsPadding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            actionsAlignment: MainAxisAlignment.end,
            actionsOverflowButtonSpacing: 12,
            title: Text(
              'job_estimators.dialog.title'.tr(),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: dialogTextColor,
              ),
            ),
            content: SizedBox(
              width: 520,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    BookingDropdownField<int>(
                      label: 'job_estimators.dialog.car'.tr(),
                      isRequired: true,
                      value: _selectedCarId,
                      labelColor: dialogTextColor,
                      textColor: Colors.black,
                      fillColor: inputFillColor,
                      dropdownColor: inputFillColor,
                      iconColor: Colors.black,
                      items: cars
                          .map(
                            (c) => DropdownMenuItem<int>(
                              value: c.id,
                              child: Text(
                                '${c.device} ${c.model} ${(c.plateNumber ?? '').trim()}'
                                    .trim(),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (id) {
                        setState(() => _selectedCarId = id);
                      },
                    ),
                    const SizedBox(height: 12),
                    BlocBuilder<BranchCubit, BranchState>(
                      builder: (context, branchState) {
                        final branches = branchState is BranchSuccess
                            ? branchState.branches
                            : const <Branch>[];

                        return BookingDropdownField<int>(
                          label: 'job_estimators.dialog.branch'.tr(),
                          isRequired: true,
                          value: _selectedBranchId,
                          labelColor: dialogTextColor,
                          textColor: Colors.black,
                          fillColor: inputFillColor,
                          dropdownColor: inputFillColor,
                          iconColor: Colors.black,
                          items: branches
                              .map(
                                (b) => DropdownMenuItem<int>(
                                  value: b.id,
                                  child: Text(b.name),
                                ),
                              )
                              .toList(),
                          onChanged: (id) {
                            setState(() {
                              _selectedBranchId = id;
                              _selectedServiceId = null;
                            });
                            if (id == null) {
                              context.read<ServiceCubit>().clear();
                              return;
                            }
                            context.read<ServiceCubit>().load(locationId: id);
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    BlocBuilder<ServiceCubit, ServiceState>(
                      builder: (context, serviceState) {
                        final services = serviceState is ServiceSuccess
                            ? serviceState.services
                            : const <Service>[];
                        return BookingDropdownField<int>(
                          label: 'job_estimators.dialog.service_type'.tr(),
                          value: _selectedServiceId,
                          labelColor: dialogTextColor,
                          textColor: Colors.black,
                          fillColor: inputFillColor,
                          dropdownColor: inputFillColor,
                          iconColor: Colors.black,
                          items: services
                              .map(
                                (s) => DropdownMenuItem<int>(
                                  value: s.id,
                                  child: Text(s.name),
                                ),
                              )
                              .toList(),
                          onChanged: (id) {
                            setState(() => _selectedServiceId = id);
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _vehicleDetailsController,
                      maxLines: 4,
                      maxLength: 1000,
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: InputDecoration(
                        labelText: 'job_estimators.dialog.vehicle_details'.tr(),
                        labelStyle: const TextStyle(
                          color: dialogTextColor,
                          fontWeight: FontWeight.w700,
                        ),
                        filled: true,
                        fillColor: inputFillColor,
                        counterStyle: const TextStyle(color: dialogTextColor),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFE6E8EC),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFE6E8EC),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF0070F0),
                            width: 1.2,
                          ),
                        ),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              SizedBox(
                height: 44,
                child: TextButton(
                  onPressed: isLoading
                      ? null
                      : () {
                          Navigator.pop(context);
                        },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    minimumSize: const Size(110, 44),
                  ),
                  child: Text(
                    'job_estimators.dialog.cancel'.tr(),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: dialogTextColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                height: 44,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    minimumSize: const Size(140, 44),
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                  ),
                  onPressed: isLoading
                      ? null
                      : () {
                          final carId = _selectedCarId;
                          final branchId = _selectedBranchId;

                          if (contactId <= 0) {
                            Toasters.errorKey(
                              'job_estimators.create.errors.customer_not_available',
                            );
                            return;
                          }
                          if (carId == null) {
                            Toasters.errorKey(
                              'job_estimators.create.errors.select_car',
                            );
                            return;
                          }
                          if (branchId == null) {
                            Toasters.errorKey(
                              'job_estimators.create.errors.select_branch',
                            );
                            return;
                          }

                          final amount = _parseAmount(_amountController.text);
                          if (amount != null && amount < 0) {
                            Toasters.errorKey(
                              'job_estimators.create.errors.amount_invalid',
                            );
                            return;
                          }

                          context.read<CreateJobEstimatorCubit>().create(
                            contactId: contactId,
                            deviceId: carId,
                            locationId: branchId,
                            serviceTypeId: _selectedServiceId,
                            vehicleDetails: _vehicleDetailsController.text,
                            amount: amount,
                            sendNotificationValue: _sendSms ? 1 : 0,
                          );
                        },
                  child: isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'job_estimators.dialog.add'.tr(),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
