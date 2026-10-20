import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:reservation_workshop/core/components/toasters.dart';
import 'package:reservation_workshop/core/widgets/app_card.dart';

import '../../data/models/job_order_spare_part_model.dart';
import '../cubits/job_order_details_cubit/job_order_details_cubit.dart';

class SparePartsApprovalWidget extends StatefulWidget {
  const SparePartsApprovalWidget({
    super.key,
    required this.items,
    this.token,
    this.onApprove,
  });

  final List<JobOrderSparePartModel> items;
  final String? token;
  final Future<void> Function(List<int> productIds)? onApprove;

  @override
  State<SparePartsApprovalWidget> createState() =>
      _SparePartsApprovalWidgetState();
}

class _SparePartsApprovalWidgetState extends State<SparePartsApprovalWidget> {
  bool _isApproving = false;
  late final Set<int> _originallyApproved = {
    for (final e in widget.items)
      if (e.clientApproval == 1) e.id,
  };

  JobOrderSparePartModel _withApproval(
    JobOrderSparePartModel it,
    int approval,
  ) {
    return JobOrderSparePartModel(
      id: it.id,
      jobOrderId: it.jobOrderId,
      productId: it.productId,
      deliveredStatus: it.deliveredStatus,
      outForDeliver: it.outForDeliver,
      clientApproval: approval,
      inventoryDelivery: it.inventoryDelivery,
      price: it.price,
      purchasePrice: it.purchasePrice,
      createdAt: it.createdAt,
      quantity: it.quantity,
      supplierId: it.supplierId,
      productStatus: it.productStatus,
      notes: it.notes,
      updatedAt: it.updatedAt,
      jobEstimatorId: it.jobEstimatorId,
      productName: it.productName,
      sku: it.sku,
      productCategoryId: it.productCategoryId,
      productCategoryName: it.productCategoryName,
    );
  }

  double get _total {
    var sum = 0.0;
    for (final e in widget.items) {
      sum += e.lineTotal;
    }
    return sum;
  }

  double get _selectedTotal {
    var sum = 0.0;
    for (final e in widget.items) {
      if (e.clientApproval == 1) {
        sum += e.lineTotal;
      }
    }
    return sum;
  }

  String _formatMoney(double v) {
    final asInt = v.roundToDouble() == v;
    return asInt ? v.toStringAsFixed(0) : v.toStringAsFixed(2);
  }

  Color _priorityColor(String raw) {
    final v = raw.trim().toLowerCase();
    if (v == 'urgent' || v == 'red') return const Color(0xFFEF4444);
    if (v == 'advisory' || v == 'orange' || v == 'yellow')
      return const Color(0xFFF59E0B);
    return const Color(0xFF111827);
  }

  Widget _priorityDot(String raw) {
    return Center(
      child: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: _priorityColor(raw),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Widget _tab(String value, String label) {
    return const SizedBox.shrink();
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.items;

    final approveItems = widget.items
        .where((e) => e.clientApproval == 1)
        .toList();
    final canApprove = approveItems.isNotEmpty && !_isApproving;

    final canApproveAll =
        !_isApproving && widget.items.any((e) => e.clientApproval != 1);
    final canDeselectAll =
        !_isApproving && widget.items.any((e) => e.clientApproval == 1);

    final title = 'job_order.spare_parts_approval.title'.tr();
    final selectAllLabel = 'job_order.spare_parts_approval.select_all'.tr();
    final deselectAllLabel = 'job_order.spare_parts_approval.deselect_all'.tr();
    final legendNormal = 'job_order.spare_parts_approval.legend.normal'.tr();
    final legendAdvisory = 'job_order.spare_parts_approval.legend.advisory'
        .tr();
    final legendUrgent = 'job_order.spare_parts_approval.legend.urgent'.tr();
    final colItem = 'job_order.spare_parts_approval.columns.item'.tr();
    final colPriority = 'job_order.spare_parts_approval.columns.priority'.tr();
    final colQty = 'job_order.spare_parts_approval.columns.qty'.tr();
    final colTotal = 'job_order.spare_parts_approval.columns.total'.tr();
    final emptyLabel = 'job_order.spare_parts_approval.empty'.tr();
    final approveTotalLabel = 'job_order.spare_parts_approval.approve_total'
        .tr();
    final approvingLabel = 'job_order.spare_parts_approval.approving'.tr();
    final approveSuccessLabel = 'job_order.spare_parts_approval.approve_success'
        .tr();
    final approveFailedLabel = 'job_order.spare_parts_approval.approve_failed'
        .tr();
    final selectedTotalLabel = 'job_order.spare_parts_approval.selected_total'
        .tr(args: [_formatMoney(_selectedTotal)]);

    return AppCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 16,
      borderColor: const Color(0xFFEFF1F5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.start,
            children: [
              SizedBox(
                height: 36,
                child: FilledButton(
                  onPressed: canApproveAll
                      ? () {
                          setState(() {
                            for (var i = 0; i < widget.items.length; i++) {
                              final it = widget.items[i];
                              if (it.clientApproval != 1) {
                                widget.items[i] = _withApproval(it, 1);
                              }
                            }
                          });
                        }
                      : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check, size: 16, color: Colors.white),
                      const SizedBox(width: 6),
                      Text(
                        selectAllLabel,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                height: 36,
                child: OutlinedButton(
                  onPressed: canDeselectAll
                      ? () {
                          setState(() {
                            for (var i = 0; i < widget.items.length; i++) {
                              final it = widget.items[i];
                              if (it.clientApproval == 1) {
                                widget.items[i] = _withApproval(it, 0);
                              }
                            }
                          });
                        }
                      : null,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.black),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    deselectAllLabel,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _legendDot(const Color(0xFF111827), legendNormal),
              const SizedBox(width: 14),
              _legendDot(const Color(0xFFF59E0B), legendAdvisory),
              const SizedBox(width: 14),
              _legendDot(const Color(0xFFEF4444), legendUrgent),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 34,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Center(
                    child: Text(
                      colItem,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      colPriority,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      colQty,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      colTotal,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          if (filtered.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F8FA),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE6E8EC)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      emptyLabel,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Column(
              children: [
                ...filtered.map((e) {
                  final lineTotal = e.lineTotal;
                  final isApproved = e.clientApproval == 1;
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Color(0xFFE6E8EC)),
                      ),
                    ),
                    child: Row(
                      children: [
                        InkWell(
                          onTap: () {
                            setState(() {
                              final idx = widget.items.indexWhere(
                                (x) => x.id == e.id,
                              );
                              if (idx == -1) return;
                              widget.items[idx] = _withApproval(
                                e,
                                isApproved ? 0 : 1,
                              );
                            });
                          },
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.black,
                                width: 1.6,
                              ),
                              borderRadius: BorderRadius.circular(6),
                              color: isApproved
                                  ? Colors.black
                                  : Colors.transparent,
                            ),
                            child: isApproved
                                ? const Icon(
                                    Icons.check,
                                    size: 16,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            e.productName.trim().isEmpty ? '-' : e.productName,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        Expanded(child: _priorityDot(e.productStatus)),
                        Expanded(
                          child: Text(
                            e.quantityValue == 0
                                ? '-'
                                : _formatMoney(e.quantityValue),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            _formatMoney(lineTotal),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: !canApprove
                            ? null
                            : () async {
                                final toApprove = approveItems
                                    .where(
                                      (e) =>
                                          !_originallyApproved.contains(e.id),
                                    )
                                    .toList();
                                if (toApprove.isEmpty) {
                                  Toasters.show(
                                    'job_order.spare_parts_approval.already_approved'
                                        .tr(),
                                  );
                                  return;
                                }
                                setState(() => _isApproving = true);
                                try {
                                  final productIds = toApprove
                                      .map((e) => e.productId)
                                      .toSet()
                                      .toList();
                                  if (widget.onApprove != null) {
                                    await widget.onApprove!(productIds);
                                  } else {
                                    final jobOrderId =
                                        toApprove.first.jobOrderId;
                                    debugPrint(
                                      'approveProducts -> job_order_id=$jobOrderId product_ids=$productIds',
                                    );
                                    await context
                                        .read<JobOrderDetailsCubit>()
                                        .approveProducts(
                                          jobOrderId: jobOrderId,
                                          productIds: productIds,
                                          token: widget.token,
                                        );
                                  }
                                  if (!mounted) return;
                                  _originallyApproved.addAll(
                                    toApprove.map((e) => e.id),
                                  );
                                  Toasters.success(approveSuccessLabel);
                                } catch (e) {
                                  if (!mounted) return;
                                  Toasters.error(approveFailedLabel);
                                } finally {
                                  if (mounted)
                                    setState(() => _isApproving = false);
                                }
                              },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: canApprove
                                ? Colors.black
                                : const Color(0xFF9CA3AF),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            _isApproving ? approvingLabel : approveTotalLabel,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      selectedTotalLabel,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }
}
