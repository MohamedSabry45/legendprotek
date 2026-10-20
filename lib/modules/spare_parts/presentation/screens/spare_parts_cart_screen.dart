import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:reservation_workshop/config/style/app_colors.dart';
import 'package:reservation_workshop/core/components/toasters.dart';
import 'package:reservation_workshop/modules/customer/presentation/cubits/customer_info_cubit/customer_info_cubit.dart';
import 'package:reservation_workshop/modules/customer/presentation/cubits/customer_info_cubit/customer_info_state.dart';
import 'package:reservation_workshop/modules/spare_parts/data/datasources/sell_proforma_remote_datasource.dart';
import 'package:reservation_workshop/modules/spare_parts/domain/entities/spare_cart_item.dart';
import 'package:reservation_workshop/modules/spare_parts/presentation/cubits/cart_cubit/cart_cubit_exports.dart';
import 'package:reservation_workshop/modules/branch/presentation/cubits/branch_cubit/branch_cubit.dart';

import '../widgets/cart/cart_items_list.dart';
import '../widgets/cart/cart_summary_card.dart';
import '../widgets/cart/proforma_customer_section.dart';
import '../widgets/cart/shipping_section.dart';
import '../widgets/cart/proforma_submit_bar.dart';

class SparePartsCartScreen extends StatefulWidget {
  const SparePartsCartScreen({super.key});

  @override
  State<SparePartsCartScreen> createState() => _SparePartsCartScreenState();
}

class _SparePartsCartScreenState extends State<SparePartsCartScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _contactIdController;
  late final TextEditingController _transactionDateController;

  late final TextEditingController _shippingDetailsController;
  late final TextEditingController _shippingAddressController;
  late final TextEditingController _shippingStatusController;
  late final TextEditingController _deliveredToController;

  String? _shippingType;
  int? _branchId;

  bool _submitting = false;

  @override
  void initState() {
    super.initState();

    _contactIdController = TextEditingController();
    _transactionDateController = TextEditingController(
      text: _defaultTransactionDate(),
    );

    _shippingDetailsController = TextEditingController(
      text: 'Standard delivery',
    );
    _shippingAddressController = TextEditingController();
    _shippingStatusController = TextEditingController(text: 'packed');
    _deliveredToController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        final cubit = BlocProvider.of<CustomerInfoCubit>(context);
        final state = cubit.state;
        if (state is CustomerInfoSuccess) {
          _contactIdController.text = state.info.id.toString();
        }
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _contactIdController.dispose();
    _transactionDateController.dispose();
    _shippingDetailsController.dispose();
    _shippingAddressController.dispose();
    _shippingStatusController.dispose();
    _deliveredToController.dispose();
    super.dispose();
  }

  String _defaultTransactionDate() {
    final now = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${now.year}-${two(now.month)}-${two(now.day)} ${two(now.hour)}:${two(now.minute)}:00';
  }

  Future<void> _pickTransactionDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );

    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now),
    );

    if (time == null || !mounted) return;

    String two(int v) => v.toString().padLeft(2, '0');
    final dt = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    _transactionDateController.text =
        '${dt.year}-${two(dt.month)}-${two(dt.day)} ${two(dt.hour)}:${two(dt.minute)}:00';
    setState(() {});
  }

  Future<void> _submit() async {
    if (_submitting) return;

    final cartState = context.read<CartCubit>().state;
    if (cartState is! CartUpdated || cartState.items.isEmpty) {
      Toasters.errorKey('spare_parts.cart_empty');
      return;
    }

    if (!(_formKey.currentState?.validate() ?? false)) return;

    final contactId = int.tryParse(_contactIdController.text.trim()) ?? 0;
    if (contactId <= 0) {
      Toasters.errorKey('spare_parts.invalid_contact');
      return;
    }

    final body = <String, dynamic>{
      'sells': [
        {
          'contact_id': contactId,
          'transaction_date': _transactionDateController.text.trim(),
          'shipping_type': _shippingType ?? 'delivery',
          if (_branchId != null) 'branch_id': _branchId,
          'shipping_details': _shippingDetailsController.text.trim(),
          'shipping_address': _shippingAddressController.text.trim(),
          'shipping_status': _shippingStatusController.text.trim(),
          'delivered_to': _deliveredToController.text.trim(),
          'products': cartState.items
              .map(
                (i) => {
                  'product_id': i.product.id,
                  'variation_id': i.variationId,
                  'quantity': i.quantity,
                  'unit_price': i.unitPrice,
                  'discount_amount': i.discountAmount,
                  'discount_type': i.discountType,
                },
              )
              .toList(),
        },
      ],
    };

    setState(() => _submitting = true);
    try {
      final remote = SellProformaRemoteDataSource();
      final res = await remote.createProforma(body: body);

      if (!mounted) return;

      final invoiceUrl = res.isNotEmpty ? res.first.invoiceUrl : '';
      final invoiceNo = res.isNotEmpty ? res.first.invoiceNo : '';

      Toasters.successKey('spare_parts.proforma_created');
      await showDialog<void>(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title: Text('spare_parts.proforma_created'.tr()),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('spare_parts.invoice'.tr(args: [invoiceNo])),
                const SizedBox(height: 8),
                Text(
                  invoiceUrl.isEmpty
                      ? 'spare_parts.no_invoice_url'.tr()
                      : invoiceUrl,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('common.ok'.tr()),
              ),
            ],
          );
        },
      );

      context.read<CartCubit>().clear();
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      Toasters.errorFrom(e, fallbackKey: 'spare_parts.create_failed');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'spare_parts.cart_title'.tr(),
          style: TextStyle(fontWeight: FontWeight.w900, color: Colors.black87),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: MultiBlocProvider(
        providers: [BlocProvider(create: (_) => BranchCubit())],
        child: Form(
          key: _formKey,
          child: BlocBuilder<CartCubit, CartState>(
            builder: (context, cartState) {
              final items = cartState is CartUpdated
                  ? cartState.items
                  : const <SpareCartItem>[];

              return Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                      children: [
                        if (items.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: AppColors.brandPrimarySoft,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Icon(
                                    Icons.shopping_cart_outlined,
                                    color: AppColors.brandPrimary,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'spare_parts.cart_empty'.tr(),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      color: Colors.black87,
                                      height: 1.2,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          CartItemsList(items: items),
                        const SizedBox(height: 12),
                        ProformaCustomerSection(
                          contactIdController: _contactIdController,
                          transactionDateController: _transactionDateController,
                          onPickTransactionDate: _pickTransactionDate,
                        ),
                        const SizedBox(height: 12),
                        ShippingSection(
                          shippingDetailsController: _shippingDetailsController,
                          shippingAddressController: _shippingAddressController,
                          shippingStatusController: _shippingStatusController,
                          deliveredToController: _deliveredToController,
                          initialShippingType: _shippingType,
                          initialBranchId: _branchId,
                          onShippingTypeChanged: (v) =>
                              setState(() => _shippingType = v),
                          onBranchChanged: (v) => setState(() => _branchId = v),
                        ),
                        const SizedBox(height: 12),
                        CartSummaryCard(
                          totalQuantity: cartState is CartUpdated
                              ? cartState.totalQuantity
                              : 0,
                          subtotal: cartState is CartUpdated
                              ? cartState.subtotal
                              : 0,
                          total: cartState is CartUpdated ? cartState.total : 0,
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                  ProformaSubmitBar(
                    enabled: items.isNotEmpty && !_submitting,
                    submitting: _submitting,
                    total: cartState is CartUpdated ? cartState.total : 0,
                    onSubmit: _submit,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
