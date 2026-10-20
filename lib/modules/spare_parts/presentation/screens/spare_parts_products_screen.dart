import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:reservation_workshop/config/style/app_colors.dart';
import 'package:reservation_workshop/core/components/toasters.dart';
import 'package:reservation_workshop/modules/spare_parts/domain/entities/taxonomy_category.dart';
import 'package:reservation_workshop/modules/spare_parts/domain/entities/spare_product.dart';
import 'package:reservation_workshop/modules/customer/presentation/cubits/customer_info_cubit/customer_info_cubit.dart';
import 'package:reservation_workshop/modules/spare_parts/presentation/cubits/cart_cubit/cart_cubit_exports.dart';
import 'package:reservation_workshop/modules/spare_parts/presentation/cubits/products_cubit/products_cubit.dart';
import 'package:reservation_workshop/modules/spare_parts/presentation/cubits/products_cubit/products_state.dart';
import 'package:reservation_workshop/modules/spare_parts/presentation/screens/spare_parts_cart_screen.dart';

class SparePartsProductsScreen extends StatefulWidget {
  final TaxonomyCategory category;

  const SparePartsProductsScreen({super.key, required this.category});

  @override
  State<SparePartsProductsScreen> createState() =>
      _SparePartsProductsScreenState();
}

class _SparePartsProductsScreenState extends State<SparePartsProductsScreen> {
  TaxonomyCategory? _selectedSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        context.read<ProductsCubit>().load(
          perPage: 30,
          businessId: 1,
          locationId: 1,
        );
      } catch (_) {}
    });
  }

  void _selectSub(TaxonomyCategory? sub) {
    setState(() => _selectedSub = sub);
  }

  void _addToCart(SpareProduct product) {
    final variationId = product.id;
    context.read<CartCubit>().addProduct(
      product: product,
      variationId: variationId,
    );
  }

  void _openCart() {
    CustomerInfoCubit? customerInfo;
    try {
      customerInfo = context.read<CustomerInfoCubit>();
    } catch (_) {
      customerInfo = null;
    }

    try {
      Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute<void>(
          builder: (_) => MultiBlocProvider(
            providers: [
              BlocProvider<CartCubit>.value(value: context.read<CartCubit>()),
              if (customerInfo != null)
                BlocProvider<CustomerInfoCubit>.value(value: customerInfo),
            ],
            child: const SparePartsCartScreen(),
          ),
        ),
      );
    } catch (e) {
      Toasters.errorFrom(e);
    }
  }

  Future<void> _openCompatibilitySheet(SpareProduct product) async {
    final theme = Theme.of(context);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        final items = product.compatibility;
        return SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              12,
              16,
              16 + MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: AppColors.brandDark,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Compatibility',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: AppColors.grey7,
                  ),
                ),
                const SizedBox(height: 12),
                if (items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 18),
                    child: Text(
                      'No compatibility data found',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.grey7,
                      ),
                    ),
                  )
                else
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.white3,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.brandOutline),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          headingRowHeight: 44,
                          dataRowMinHeight: 44,
                          dataRowMaxHeight: 64,
                          columnSpacing: 16,
                          headingTextStyle: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: AppColors.brandDark,
                          ),
                          dataTextStyle: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.brandDark,
                          ),
                          columns: [
                            DataColumn(label: Text('spare_parts.brand'.tr())),
                            DataColumn(label: Text('spare_parts.model'.tr())),
                            DataColumn(label: Text('spare_parts.from'.tr())),
                            DataColumn(label: Text('spare_parts.to'.tr())),
                          ],
                          rows: items
                              .map(
                                (c) => DataRow(
                                  cells: [
                                    DataCell(Text(c.brand)),
                                    DataCell(Text(c.model)),
                                    DataCell(
                                      Text(c.fromYear?.toString() ?? '-'),
                                    ),
                                    DataCell(Text(c.toYear?.toString() ?? '-')),
                                  ],
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Set<int> _collectIds(TaxonomyCategory root) {
    final ids = <int>{};
    final stack = <TaxonomyCategory>[root];
    while (stack.isNotEmpty) {
      final current = stack.removeLast();
      ids.add(current.id);
      if (current.subCategories.isNotEmpty) {
        stack.addAll(current.subCategories);
      }
    }
    return ids;
  }

  List<SpareProduct> _filter({required List<SpareProduct> products}) {
    final allowed = _selectedSub == null
        ? _collectIds(widget.category)
        : _collectIds(_selectedSub!);
    return products.where((p) {
      final subId = p.subCategoryId;
      if (subId != null) {
        return allowed.contains(subId);
      }

      // منتجات بدون sub-category: نعرضها فقط على مستوى الكاتيجوري (All)
      // وده مهم خصوصًا لكتير من منتجات Spare Parts اللي sub_category=null.
      if (_selectedSub != null) return false;
      return p.categoryId != null && p.categoryId == widget.category.id;
    }).toList();
  }

  String _formatPrice(double value) {
    final i = value.round();
    final s = i.toString();
    final buf = StringBuffer();
    for (int idx = 0; idx < s.length; idx++) {
      final fromEnd = s.length - idx;
      buf.write(s[idx]);
      if (fromEnd > 1 && fromEnd % 3 == 1) {
        buf.write(',');
      }
    }
    final raw = buf.toString();
    return raw.endsWith(',') ? raw.substring(0, raw.length - 1) : raw;
  }

  @override
  Widget build(BuildContext context) {
    final category = widget.category;
    final items = category.subCategories;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
        title: Text(
          category.name,
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w900,
          ),
        ),
        actions: [
          BlocBuilder<CartCubit, CartState>(
            builder: (context, state) {
              final count = state is CartUpdated ? state.totalQuantity : 0;
              return _CartActionButton(
                count: count,
                pulseTick: count,
                onTap: _openCart,
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: AspectRatio(
                aspectRatio: 343 / 140,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    widget.category.logo != null &&
                            widget.category.logo!.isNotEmpty
                        ? Image.network(
                            widget.category.logo!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Image.asset(
                                'assets/images/bummy.jpg',
                                fit: BoxFit.cover,
                              );
                            },
                          )
                        : Image.asset(
                            'assets/images/bummy.jpg',
                            fit: BoxFit.cover,
                          ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withOpacity(0.3),
                            Colors.black.withOpacity(0.00),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 12,
                      right: 12,
                      bottom: 10,
                      child: Text(
                        category.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _SubChip(
                      label: 'All',
                      selected: _selectedSub == null,
                      onTap: () => _selectSub(null),
                    ),
                    ...items.map((item) {
                      final selected = _selectedSub?.id == item.id;
                      return Padding(
                        padding: const EdgeInsetsDirectional.only(start: 10),
                        child: _SubChip(
                          label: item.name,
                          selected: selected,
                          onTap: () => _selectSub(item),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: BlocBuilder<ProductsCubit, ProductsState>(
              builder: (context, state) {
                if (state is ProductsLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is ProductsError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Something went wrong',
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            Toasters.displayMessage(state.message),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.grey7,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () => context.read<ProductsCubit>().load(
                              perPage: 30,
                              businessId: 1,
                              locationId: 1,
                            ),
                            child: Text('common.retry'.tr()),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final all = state is ProductsSuccess
                    ? state.products
                    : const <SpareProduct>[];
                final filtered = _filter(products: all);
                if (filtered.isEmpty) {
                  return const Center(
                    child: Text(
                      'No products found',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final p = filtered[index];
                    return InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () => _openCompatibilitySheet(p),
                      child: _ProductCard(
                        title: p.name,
                        sku: p.sku,
                        brand: p.brandName,
                        price: _formatPrice(p.defaultSellPrice),
                        qty: p.qtyAvailable,
                        imageUrl: p.imageUrl,
                        onAdd: () => _addToCart(p),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SubChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SubChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.brandPrimarySoft2 : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade300),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: Colors.black87,
            ),
          ),
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final String title;
  final String sku;
  final String? brand;
  final String price;
  final double qty;
  final String? imageUrl;
  final VoidCallback onAdd;

  const _ProductCard({
    required this.title,
    required this.sku,
    required this.brand,
    required this.price,
    required this.qty,
    this.imageUrl,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final qtyText = qty.toStringAsFixed(2);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: 3,
      shadowColor: Colors.black.withOpacity(0.08),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Product Image - Larger and more prominent
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.white2,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    bottomLeft: Radius.circular(20),
                  ),
                  border: Border.all(color: Colors.grey.shade200, width: 0.5),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    bottomLeft: Radius.circular(20),
                  ),
                  child: imageUrl != null && imageUrl!.isNotEmpty
                      ? Image.network(
                          imageUrl!,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                              ),
                              child: const Icon(
                                Icons.build_outlined,
                                color: Colors.black87,
                                size: 32,
                              ),
                            );
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: AppColors.white2,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(20),
                                  bottomLeft: Radius.circular(20),
                                ),
                              ),
                              child: Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      AppColors.brandPrimary.withOpacity(0.6),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        )
                      : Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                          ),
                          child: const Icon(
                            Icons.build_outlined,
                            color: Colors.black87,
                            size: 32,
                          ),
                        ),
                ),
              ),

              // Product Details
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title and Price
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: AppColors.brandDark,
                                height: 1.2,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.brandPrimary,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.brandPrimary.withOpacity(
                                    0.3,
                                  ),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Text(
                              '$price EGP',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Part Number
                      _InfoRow(
                        label: 'Part Number',
                        value: sku,
                        labelColor: AppColors.grey7,
                      ),

                      const SizedBox(height: 8),

                      // Brand
                      _InfoRow(
                        label: 'Brand',
                        value: (brand ?? '').trim().isEmpty
                            ? '-'
                            : brand!.trim(),
                        labelColor: AppColors.grey7,
                      ),

                      const Spacer(),

                      // Add button only
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [_AddButton(onTap: onAdd)],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color labelColor;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            '$label:',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: labelColor,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: Colors.black87,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}

class _AddButton extends StatefulWidget {
  final VoidCallback onTap;

  const _AddButton({required this.onTap});

  @override
  State<_AddButton> createState() => _AddButtonState();
}

class _AddButtonState extends State<_AddButton> {
  bool _pressed = false;

  Future<void> _animate() async {
    if (!mounted) return;
    setState(() => _pressed = true);
    await Future<void>.delayed(const Duration(milliseconds: 140));
    if (!mounted) return;
    setState(() => _pressed = false);
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        widget.onTap();
        _animate();
      },
      child: AnimatedScale(
        scale: _pressed ? 1.15 : 1.0,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutBack,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.brandPrimary,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.brandPrimary.withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(
            Icons.add_shopping_cart_outlined,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }
}

class _CartActionButton extends StatelessWidget {
  final int count;
  final int pulseTick;
  final VoidCallback onTap;

  const _CartActionButton({
    required this.count,
    required this.pulseTick,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 6),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        transitionBuilder: (child, anim) {
          final curved = CurvedAnimation(
            parent: anim,
            curve: Curves.easeOutBack,
          );
          return ScaleTransition(
            scale: Tween<double>(begin: 1.0, end: 1.15).animate(curved),
            child: child,
          );
        },
        child: Stack(
          key: ValueKey<int>(pulseTick),
          clipBehavior: Clip.none,
          children: [
            IconButton(
              onPressed: onTap,
              icon: const Icon(Icons.shopping_cart_outlined),
            ),
            if (count > 0)
              PositionedDirectional(
                top: 6,
                end: 6,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  transitionBuilder: (child, anim) {
                    return ScaleTransition(scale: anim, child: child);
                  },
                  child: Container(
                    key: ValueKey<int>(count),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.brandPrimary,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: AppColors.white.withOpacity(0.9),
                        width: 1.2,
                      ),
                    ),
                    child: Text(
                      count > 99 ? '99+' : '$count',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
