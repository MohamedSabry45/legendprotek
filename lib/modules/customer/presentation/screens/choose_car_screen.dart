import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:ui' as ui;

import 'package:reservation_workshop/config/routes/routes_name.dart';
import 'package:reservation_workshop/core/components/toasters.dart';
import 'package:reservation_workshop/core/network/local/cache_helper.dart';
import 'package:reservation_workshop/core/functions/localization_helper.dart';
import 'package:reservation_workshop/core/utils/strings/prefkeys.dart';

import '../../domain/entities/customer_car.dart';
import '../cubits/customer_info_cubit/customer_info_cubit.dart';
import '../cubits/customer_info_cubit/customer_info_state.dart';

class ChooseCarScreen extends StatefulWidget {
  const ChooseCarScreen({super.key});

  @override
  State<ChooseCarScreen> createState() => _ChooseCarScreenState();
}

class _ChooseCarScreenState extends State<ChooseCarScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CustomerInfoCubit>().load();
    });
  }

  Future<void> _openAddCar() async {
    final res = await Navigator.pushNamed(context, RoutesName.addCarScreen);
    if (!mounted) return;
    if (res == true) {
      context.read<CustomerInfoCubit>().load();
    }
  }

  void _selectCar(CustomerCar car) {
    CacheHelper.saveData(key: PrefKeys.kSelectedCarId, value: car.id);
    CacheHelper.saveData(
      key: PrefKeys.kSelectedCarLabel,
      value: '${car.device} ${car.model} ${car.plateNumber ?? ''}'.trim(),
    );
    CacheHelper.saveData(
      key: PrefKeys.kSelectedCarLogo,
      value: (car.carLogo ?? '').trim(),
    );

    Navigator.pushNamedAndRemoveUntil(
      context,
      RoutesName.homeScreen,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CustomerInfoCubit, CustomerInfoState>(
      listener: (context, state) {
        if (state is CustomerInfoError) {
          Toasters.show(state.message);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          elevation: 0,
          title: Text(
            t(context, 'cars.choose_title', ar: 'اختر المركبه', en: 'Choose your car'),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Color(0xFFD4AF37),
            ),
          ),
          foregroundColor: const Color(0xFFD4AF37),
          iconTheme: const IconThemeData(color: Color(0xFFD4AF37)),
             actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => context.read<CustomerInfoCubit>().load(),
            ),
          ],
        ),
        body: SafeArea(
          child: BlocBuilder<CustomerInfoCubit, CustomerInfoState>(
            builder: (context, state) {
              if (state is! CustomerInfoSuccess) {
                return const SizedBox.shrink();
              }

              final cars = state.info.cars;

              return Directionality(
                textDirection: isLtr(context) ? ui.TextDirection.ltr : ui.TextDirection.rtl,
                 child: RefreshIndicator(
                  color: const Color(0xFFD4AF37),
                  backgroundColor: Colors.black,
                  onRefresh: () async {
                    await context.read<CustomerInfoCubit>().load();
                  },
                
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    ...cars.map(
                      (car) => _CarCard(
                        car: car,
                        onTap: () => _selectCar(car),
                      ),
                    ),
                    if (cars.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: Text(
                            t(context, 'cars.empty', ar: 'لا توجد سيارات مرتبطة بالحساب', en: 'No cars linked to this account'),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withOpacity(0.6),
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 52,
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD4AF37),
                          foregroundColor: Colors.black,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          shadowColor: const Color(0xFFD4AF37).withOpacity(0.4),
                        ),
                        onPressed: _openAddCar,
                        child: Text(
                          t(context, 'cars.add_car', ar: 'إضافة سيارة', en: 'Add car'),
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ));
            },
          ),
        ),
      ),
    );
  }
}

/* ======================= CAR CARD ======================= */

class _CarCard extends StatelessWidget {
  const _CarCard({
    required this.car,
    required this.onTap,
  });

  final CustomerCar car;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF050505),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.3), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFD4AF37).withOpacity(0.15),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            _infoRow(t(context, 'cars.brand', ar: 'الماركة:', en: 'Brand:'), car.device),
            const SizedBox(height: 8),
            _infoRow(t(context, 'cars.model', ar: 'الموديل:', en: 'Model:'), car.model),
            const SizedBox(height: 8),
            _infoRow(t(context, 'cars.color', ar: 'اللون:', en: 'Color:'), car.color),
            const SizedBox(height: 16),
            Center(
              child: _EgyptPlateWidget(
                plateNumber: car.plateNumber,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.white.withOpacity(0.6),
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

/* ======================= PLATE ======================= */

class _EgyptPlateWidget extends StatelessWidget {
  const _EgyptPlateWidget({required this.plateNumber});

  final String? plateNumber;

  @override
  Widget build(BuildContext context) {
    final plate = plateNumber?.trim() ?? '';
    final parts = plate.isEmpty ? const _PlateParts(letters: '', numbers: '') : _parsePlate(plate);

    return Container(
      width: 140,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.3)),
        color: const Color(0xFF0A0A0A),
      ),
      child: Column(
        children: [
          Container(
            height: 22,
            decoration: const BoxDecoration(
              color: Color(0xFFD4AF37),
              borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Center(
                    child: Text(
                      t(context, 'cars.plate_country_ar', ar: 'مصر', en: 'Egypt'),
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const VerticalDivider(color: Colors.white54, width: 1),
                Expanded(
                  child: Center(
                    child: Text(
                      t(context, 'cars.plate_country_en', ar: 'Egypt', en: 'Egypt'),
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(child: _cell(parts.letters)),
                const SizedBox(width: 8),
                Expanded(child: _cell(parts.numbers)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _cell(String text) {
    return Container(
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
        color: const Color(0xFF21262D),
      ),
      child: Text(
        text.isEmpty ? '-' : text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }

  _PlateParts _parsePlate(String plate) {
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

    return _PlateParts(
      letters: letters.toString(),
      numbers: numbers.toString(),
    );
  }
}

class _PlateParts {
  final String letters;
  final String numbers;

  const _PlateParts({
    required this.letters,
    required this.numbers,
  });
}
