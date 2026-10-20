import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'dart:ui' as ui;

import 'package:reservation_workshop/config/style/app_colors.dart';
import 'package:reservation_workshop/core/components/toasters.dart';
import 'package:reservation_workshop/core/widgets/app_card.dart';
import 'package:reservation_workshop/core/widgets/logo_image_widget.dart';
import 'package:reservation_workshop/modules/job_estimators/presentation/cubits/job_estimator_details_cubit.dart';
import 'package:reservation_workshop/modules/job_estimators/presentation/cubits/job_estimator_details_state.dart';
import 'package:reservation_workshop/modules/job_order_details/data/models/job_order_media_model.dart';
import 'package:reservation_workshop/modules/job_order_details/data/models/job_order_spare_part_model.dart';
import 'package:reservation_workshop/modules/job_order_details/presentation/widgets/job_order_attachments_widget.dart';
import 'package:reservation_workshop/modules/job_order_details/presentation/widgets/spare_parts_approval_widget.dart';

import 'job_estimator_details_args.dart';

class JobEstimatorDetailsScreen extends StatelessWidget {
  const JobEstimatorDetailsScreen({super.key});

  Widget _fieldBox(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.grey7,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF0A0A0A),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE6E8EC)),
          ),
          child: Text(
            value.trim().isEmpty ? '-' : value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w900,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _topBar() {
    return Container(
      height: 48,
      color: Colors.black,
      alignment: Alignment.center,
      child: Text(
        'common.customer_portal'.tr(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: Color(0xFF0A0A0A),
        ),
      ),
    );
  }

  Widget _plateWidget(String plate) {
    final cleaned = plate.trim();
    final letters = StringBuffer();
    final numbers = StringBuffer();

    for (final codePoint in cleaned.runes) {
      final ch = String.fromCharCode(codePoint);

      final isDigit = RegExp(r'[0-9\u0660-\u0669]').hasMatch(ch);
      if (isDigit) {
        numbers.write(ch);
        continue;
      }

      final isLetter = RegExp(r'[A-Za-z\u0600-\u06FF]').hasMatch(ch);
      if (isLetter) {
        letters.write(ch);
      }
    }

    return Container(
      width: 160,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE6E8EC)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0A0A0A),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF0A0A0A)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 24,
              decoration: const BoxDecoration(
                color: AppColors.brandPrimary,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(10),
                ),
              ),
              child: const Row(
                children: [
                  Expanded(
                    child: Center(
                      child: Text(
                        'EGYPT',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'مصر',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 32,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      border: Border(
                        right: BorderSide(color: Colors.black, width: 1),
                      ),
                    ),
                    child: Text(
                      numbers.toString().trim().isEmpty
                          ? '-'
                          : numbers.toString().trim(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    height: 32,
                    alignment: Alignment.center,
                    child: Text(
                      letters.toString().trim().isEmpty
                          ? '-'
                          : letters.toString().trim(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<JobOrderMediaModel> _parseMediaList(
    Object? raw, {
    required bool isVideo,
  }) {
    if (raw is! List) return const <JobOrderMediaModel>[];
    return raw
        .whereType<Map>()
        .map(
          (e) => JobOrderMediaModel.fromJson(
            Map<String, dynamic>.from(e),
            isVideo: isVideo,
          ),
        )
        .where((m) => m.url.trim().isNotEmpty)
        .toList();
  }

  List<JobOrderMediaModel> _extractMedia(Map<String, dynamic> map) {
    final media = <JobOrderMediaModel>[
      ..._parseMediaList(map['tagged_images'], isVideo: false),
      ..._parseMediaList(map['booking_images'], isVideo: false),
      ..._parseMediaList(map['images'], isVideo: false),
      ..._parseMediaList(map['media'], isVideo: false),
      ..._parseMediaList(map['attachments'], isVideo: false),
      ..._parseMediaList(map['videos'], isVideo: true),
    ];
    final seen = <String>{};
    return media.where((m) => seen.add(m.url)).toList();
  }

  JobOrderSparePartModel _mapLine(Map<String, dynamic> json) {
    int asInt(dynamic v) => int.tryParse(v?.toString() ?? '') ?? 0;

    return JobOrderSparePartModel(
      id: asInt(json['line_id'] ?? json['id']),
      jobOrderId: asInt(json['job_order_id']),
      productId: asInt(json['product_id']),
      deliveredStatus: asInt(json['delivered_status']),
      outForDeliver: asInt(json['out_for_deliver']),
      clientApproval: asInt(json['client_approval']),
      inventoryDelivery: asInt(json['inventory_delivery']),
      price: json['end_user_price']?.toString() ?? json['price']?.toString() ?? '0',
      purchasePrice: json['purchase_price']?.toString(),
      createdAt: json['created_at']?.toString() ?? '',
      quantity: json['quantity']?.toString() ?? '0',
      supplierId: null,
      productStatus: json['product_status']?.toString() ?? '',
      notes: json['notes']?.toString(),
      updatedAt: json['updated_at']?.toString() ?? '',
      jobEstimatorId: null,
      productName: json['part_name']?.toString() ??
          json['product_name']?.toString() ??
          '',
      sku: json['part_sku']?.toString() ?? json['sku']?.toString() ?? '',
      productCategoryId: null,
      productCategoryName: null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final JobEstimatorDetailsArgs? detailsArgs = args is JobEstimatorDetailsArgs
        ? args
        : null;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      if (detailsArgs == null) return;
      final cubit = context.read<JobEstimatorDetailsCubit>();
      if (cubit.state is! JobEstimatorDetailsInitial) return;
      cubit.load(id: detailsArgs.id, phoneLast4: detailsArgs.phoneLast4);
    });

    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          _topBar(),
          Expanded(
            child:
                BlocBuilder<JobEstimatorDetailsCubit, JobEstimatorDetailsState>(
              builder: (context, state) {
                if (detailsArgs == null) {
                  return Center(
                    child: Text(
                      'job_order.details.invalid_data'.tr(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.grey7,
                      ),
                    ),
                  );
                }

                if (state is JobEstimatorDetailsLoading ||
                    state is JobEstimatorDetailsInitial) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is JobEstimatorDetailsError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        Toasters.displayMessage(state.message),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.grey7,
                        ),
                      ),
                    ),
                  );
                }

                if (state is! JobEstimatorDetailsSuccess) {
                  return const SizedBox.shrink();
                }

                final map = state.data;
                final estimator =
                    (map['estimator'] as Map?)?.cast<String, dynamic>() ??
                    const <String, dynamic>{};
                final meta =
                    (map['meta'] as Map?)?.cast<String, dynamic>() ??
                    const <String, dynamic>{};

                final customerName =
                    estimator['customer_name']?.toString() ?? '-';
                final estimateNo =
                    estimator['estimate_no']?.toString() ?? '-';
                final createdAt =
                    estimator['created_at']?.toString() ?? '-';
                final color = estimator['color']?.toString() ?? '-';
                final brand = estimator['brand']?.toString() ?? '-';
                final model = estimator['model']?.toString() ?? '-';
                final year =
                    estimator['manufacturing_year']?.toString() ?? '-';
                final chassis =
                    estimator['chassis_number']?.toString() ?? '-';
                final plate = estimator['plate_number']?.toString() ??
                    (meta['plate_number']?.toString() ?? '');
                final service =
                    estimator['service_name']?.toString() ?? '-';
                final branch =
                    estimator['location_name']?.toString() ?? '-';

                final linesList = (map['lines'] as List?) ?? const [];
                final parts = linesList
                    .whereType<Map>()
                    .map((e) => _mapLine(e.cast<String, dynamic>()))
                    .toList();

                final seenMediaUrls = <String>{};
                final media = [
                  ..._extractMedia(map),
                  ..._extractMedia(estimator),
                ].where((m) => seenMediaUrls.add(m.url)).toList();

                return Directionality(
                  textDirection: context.locale.languageCode == 'ar'
                      ? ui.TextDirection.rtl
                      : ui.TextDirection.ltr,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 6),
                        const LogoImageWidget(),
                        const SizedBox(height: 10),
                        JobOrderAttachmentsWidget(media: media),
                        if (media.isNotEmpty) const SizedBox(height: 14),
                        AppCard(
                          padding: const EdgeInsets.all(16),
                          borderRadius: 16,
                          backgroundColor: const Color(0xFF050505),
                          borderColor: const Color(0xFF0A0A0A),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _sectionTitle(
                                'job_estimators.details.customer_section'
                                    .tr(),
                              ),
                              const SizedBox(height: 8),
                              _fieldBox(
                                'job_estimators.details.customer_name'.tr(),
                                customerName,
                              ),
                              const SizedBox(height: 10),
                              _fieldBox(
                                'job_estimators.create.estimate_no'.tr(),
                                estimateNo,
                              ),
                              const SizedBox(height: 10),
                              _fieldBox(
                                'job_estimators.details.created_at'.tr(),
                                createdAt,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        AppCard(
                          padding: const EdgeInsets.all(16),
                          borderRadius: 16,
                          backgroundColor: const Color(0xFF050505),
                          borderColor: const Color(0xFF0A0A0A),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _sectionTitle(
                                'job_estimators.details.vehicle_section'.tr(),
                              ),
                              const SizedBox(height: 8),
                              _fieldBox(
                                'job_order.details.car_name'.tr(),
                                brand,
                              ),
                              const SizedBox(height: 10),
                              _fieldBox(
                                'job_order.details.model'.tr(),
                                model,
                              ),
                              const SizedBox(height: 10),
                              _fieldBox(
                                'job_order.details.year'.tr(),
                                year,
                              ),
                              const SizedBox(height: 10),
                              _fieldBox(
                                'job_estimators.color'.tr(),
                                color,
                              ),
                              const SizedBox(height: 10),
                              _fieldBox(
                                'job_order.details.chassis'.tr(),
                                chassis,
                              ),
                              const SizedBox(height: 10),
                              _fieldBox(
                                'job_order.details.service'.tr(),
                                service,
                              ),
                              const SizedBox(height: 10),
                              _fieldBox('job_estimators.branch'.tr(), branch),
                              const SizedBox(height: 10),
                              _fieldBox(
                                'job_order.details.plate'.tr(),
                                plate,
                              ),
                              const SizedBox(height: 14),
                              Center(child: _plateWidget(plate)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        SparePartsApprovalWidget(
                          items: parts,
                          onApprove: (productIds) async {
                            await context
                                .read<JobEstimatorDetailsCubit>()
                                .approveProducts(
                                  estimatorId: detailsArgs.id,
                                  productIds: productIds,
                                );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
