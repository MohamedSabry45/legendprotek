import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:reservation_workshop/config/style/app_colors.dart';
import 'package:reservation_workshop/core/components/toasters.dart';
import 'package:reservation_workshop/core/network/local/cache_helper.dart';
import 'package:reservation_workshop/core/utils/strings/prefkeys.dart';
import 'package:reservation_workshop/modules/customer/domain/entities/customer_car.dart';
import 'package:reservation_workshop/modules/customer/presentation/cubits/customer_info_cubit/customer_info_cubit.dart';
import 'package:reservation_workshop/modules/customer/presentation/cubits/customer_info_cubit/customer_info_state.dart';
import 'package:reservation_workshop/modules/spare_parts/domain/entities/taxonomy_category.dart';
import 'package:reservation_workshop/modules/spare_parts/presentation/cubits/products_cubit/products_cubit.dart';
import 'package:reservation_workshop/modules/spare_parts/presentation/cubits/taxonomy_cubit/taxonomy_cubit.dart';
import 'package:reservation_workshop/modules/spare_parts/presentation/cubits/taxonomy_cubit/taxonomy_state.dart';
import 'package:reservation_workshop/modules/spare_parts/presentation/cubits/cart_cubit/cart_cubit.dart';
import 'package:reservation_workshop/modules/spare_parts/presentation/screens/spare_parts_products_screen.dart';

class SparePartsScreen extends StatefulWidget {
  const SparePartsScreen({super.key});

  @override
  State<SparePartsScreen> createState() => _SparePartsScreenState();
}

class _SparePartsScreenState extends State<SparePartsScreen> {
  int? _selectedCarId;
  String? _selectedCarLabel;

  @override
  void initState() {
    super.initState();
    _loadSelectedCar();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<TaxonomyCubit>().loadProductCategories(page: 1);
      try {
        context.read<CustomerInfoCubit>().load();
      } catch (_) {}
    });
  }

  Future<void> _loadSelectedCar() async {
    final carId = await CacheHelper.getDataAsync<int>(
      key: PrefKeys.kSelectedCarId,
    );
    final carLabel = await CacheHelper.getDataAsync<String>(
      key: PrefKeys.kSelectedCarLabel,
    );
    if (!mounted) return;
    setState(() {
      _selectedCarId = carId;
      _selectedCarLabel = carLabel;
    });
  }

  String _carLabel(CustomerCar car) {
    final plate = (car.plateNumber ?? '').trim();
    return '${car.device} ${car.model} ${plate.isEmpty ? '' : plate}'.trim();
  }

  Future<void> _persistSelectedCar(CustomerCar car) async {
    await CacheHelper.saveData(key: PrefKeys.kSelectedCarId, value: car.id);
    await CacheHelper.saveData(
      key: PrefKeys.kSelectedCarLabel,
      value: _carLabel(car),
    );
    await CacheHelper.saveData(
      key: PrefKeys.kSelectedCarLogo,
      value: (car.carLogo ?? '').trim(),
    );
  }

  Future<void> _openCarPicker({required List<CustomerCar> cars}) async {
    if (cars.isEmpty) return;

    final picked = await showModalBottomSheet<CustomerCar>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF050505),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'cars.title'.tr(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
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
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: cars.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final car = cars[index];
                      final isSelected = _selectedCarId != null
                          ? car.id == _selectedCarId
                          : false;
                      return InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => Navigator.pop(ctx, car),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.brandPrimarySoft2
                                : const Color(0xFF050505),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFF0A0A0A)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: AppColors.brandPrimarySoft,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(
                                  Icons.directions_car_filled_outlined,
                                  color: AppColors.brandPrimary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${car.device} ${car.model}'.trim(),
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      (car.plateNumber ?? '').trim().isEmpty
                                          ? car.carType
                                          : (car.plateNumber ?? '').trim(),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.grey7,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                const Icon(
                                  Icons.check_circle,
                                  color: AppColors.brandPrimary,
                                )
                              else
                                const Icon(
                                  Icons.chevron_left,
                                  color: AppColors.grey7,
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );

    if (picked == null) return;
    await _persistSelectedCar(picked);
    if (!mounted) return;
    setState(() {
      _selectedCarId = picked.id;
      _selectedCarLabel = _carLabel(picked);
    });
  }

  Widget _buildCarHeader() {
    return BlocBuilder<CustomerInfoCubit, CustomerInfoState>(
      builder: (context, state) {
        final cars = state is CustomerInfoSuccess
            ? state.info.cars
            : const <CustomerCar>[];
        CustomerCar? selectedCar;
        if (_selectedCarId != null) {
          for (final c in cars) {
            if (c.id == _selectedCarId) {
              selectedCar = c;
              break;
            }
          }
        }
        selectedCar ??= (cars.isEmpty ? null : cars.first);

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              const SizedBox(width: 10),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: cars.isEmpty
                            ? null
                            : () => _openCarPicker(cars: cars),
                        child: Ink(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFF0A0A0A)),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x0A000000),
                                blurRadius: 12,
                                offset: Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Text(
                            (selectedCar?.device ?? '').trim().isNotEmpty
                                ? (selectedCar?.device ?? '').trim()
                                : 'spare_parts.brand'.tr(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              color: AppColors.brandDark,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: cars.isEmpty
                            ? null
                            : () => _openCarPicker(cars: cars),
                        child: Ink(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.brandOutline),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x0A000000),
                                blurRadius: 12,
                                offset: Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  (selectedCar?.model ?? '').trim().isNotEmpty
                                      ? (selectedCar?.model ?? '').trim()
                                      : 'spare_parts.model'.tr(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.brandDark,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: AppColors.grey7,
                              ),
                            ],
                          ),
                        ),
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        title: Text(
          'home.spare_parts'.tr(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
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
          child: Column(
            children: [
              _buildCarHeader(),
              Expanded(
                child: BlocBuilder<TaxonomyCubit, TaxonomyState>(
                  builder: (context, state) {
                    if (state is TaxonomyLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (state is TaxonomyError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Something went wrong',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
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
                                onPressed: () => context
                                    .read<TaxonomyCubit>()
                                    .loadProductCategories(page: 1),
                                child: Text('common.retry'.tr()),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    final categories = state is TaxonomySuccess
                        ? state.categories
                        : const <TaxonomyCategory>[];
                    if (categories.isEmpty) {
                      return const Center(
                        child: Text(
                          'No categories found',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      );
                    }

                    return GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 0.82,
                          ),
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final category = categories[index];
                        return Material(
                          color: Colors.white,
                          elevation: 0,
                          borderRadius: BorderRadius.circular(20),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => MultiBlocProvider(
                                    providers: [
                                      BlocProvider<CartCubit>.value(
                                        value: context.read<CartCubit>(),
                                      ),
                                      BlocProvider<CustomerInfoCubit>.value(
                                        value: context
                                            .read<CustomerInfoCubit>(),
                                      ),
                                      BlocProvider<ProductsCubit>(
                                        create: (_) => ProductsCubit(),
                                      ),
                                    ],
                                    child: SparePartsProductsScreen(
                                      category: category,
                                    ),
                                  ),
                                ),
                              );
                            },
                            child: Ink(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(0xFF0A0A0A),
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x12000000),
                                    blurRadius: 18,
                                    offset: Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    category.logo != null &&
                                            category.logo!.isNotEmpty
                                        ? Image.network(
                                            category.logo!,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) {
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
                                      left: 10,
                                      right: 10,
                                      bottom: 10,
                                      child: Text(
                                        category.name,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style:
                                            Theme.of(
                                              context,
                                            ).textTheme.titleSmall?.copyWith(
                                              fontSize: 14,
                                              height: 1.1,
                                              fontWeight: FontWeight.w900,
                                              color: Colors.white,
                                            ) ??
                                            const TextStyle(
                                              fontSize: 14,
                                              height: 1.1,
                                              fontWeight: FontWeight.w900,
                                              color: Colors.white,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
