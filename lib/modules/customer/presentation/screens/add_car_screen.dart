import 'package:flutter/material.dart';
import 'dart:ui' as ui;

import 'package:reservation_workshop/core/components/dialogs/prograss_delay_dialog.dart';
import 'package:reservation_workshop/core/components/toasters.dart';
import 'package:reservation_workshop/core/functions/localization_helper.dart';
import 'package:reservation_workshop/modules/customer/data/datasources/car_remote_datasource.dart';
import 'package:reservation_workshop/modules/customer/data/models/brand_model.dart';
import 'package:reservation_workshop/modules/customer/data/models/car_model_model.dart';

class AddCarScreen extends StatefulWidget {
  const AddCarScreen({super.key});

  @override
  State<AddCarScreen> createState() => _AddCarScreenState();
}

class _AddCarScreenState extends State<AddCarScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final CarRemoteDataSource _ds = CarRemoteDataSource();

  final TextEditingController _colorController = TextEditingController();
  final TextEditingController _chassisController = TextEditingController();
  final TextEditingController _plateController = TextEditingController();

  List<BrandModel> _brands = const <BrandModel>[];
  List<CarModelModel> _models = const <CarModelModel>[];

  BrandModel? _selectedBrand;
  CarModelModel? _selectedModel;

  final List<String> _years = List.generate(30, (index) => (2026 - index).toString());
  String? _selectedYear;

  bool _loadingBrands = false;
  bool _loadingModels = false;

  @override
  void initState() {
    super.initState();
    _loadBrands();
  }

  @override
  void dispose() {
    _colorController.dispose();
    _chassisController.dispose();
    _plateController.dispose();
    super.dispose();
  }

  Future<void> _loadBrands() async {
    setState(() => _loadingBrands = true);
    try {
      final list = await _ds.getBrands();
      if (!mounted) return;
      setState(() {
        _brands = list;
      });
    } catch (e) {
      Toasters.show(e.toString());
    } finally {
      if (mounted) {
        setState(() => _loadingBrands = false);
      }
    }
  }

  Future<void> _loadModels(int brandId) async {
    setState(() {
      _loadingModels = true;
      _models = const <CarModelModel>[];
      _selectedModel = null;
    });

    try {
      final list = await _ds.getModels(brandId: brandId);
      if (!mounted) return;
      setState(() {
        _models = list;
      });
    } catch (e) {
      Toasters.show(e.toString());
    } finally {
      if (mounted) {
        setState(() => _loadingModels = false);
      }
    }
  }

  String? _requiredValidator(String? v) {
    if (v == null) return t(context, 'validation.required', ar: 'مطلوب', en: 'Required');
    if (v.trim().isEmpty) return t(context, 'validation.required', ar: 'مطلوب', en: 'Required');
    return null;
  }

  Future<void> _submit() async {
    final brand = _selectedBrand;
    final model = _selectedModel;
    final year = _selectedYear;

    if (brand == null) {
      Toasters.show(t(context, 'cars.select_brand', ar: 'اختر الماركة', en: 'Select brand'));
      return;
    }
    if (model == null) {
      Toasters.show(t(context, 'cars.select_model', ar: 'اختر الموديل', en: 'Select model'));
      return;
    }
    if (year == null || year.trim().isEmpty) {
      Toasters.show(t(context, 'cars.select_year', ar: 'اختر سنة الصنع', en: 'Select manufacturing year'));
      return;
    }

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    showPrograssDelayDialog(context);
    try {
      final msg = await _ds.addCar(
        brandId: brand.id,
        modelId: model.id,
        color: _colorController.text.trim(),
        chassisNumber: _chassisController.text.trim(),
        plateNumber: _plateController.text.trim(),
        manufacturingYear: year.trim(),
        carType: 'ملاكي',
      );

      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).maybePop();
      
      if (!mounted) return;
      Toasters.show(msg.isNotEmpty ? msg : t(context, 'cars.add_success', ar: 'تم إضافة السيارة بنجاح', en: 'Car added successfully'));
      
      await Future.delayed(const Duration(milliseconds: 300));
      
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).maybePop();
      Toasters.show(e.toString());
    }
  }

  InputDecoration _dropdownDecoration({required String hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white54),
      filled: true,
      fillColor: const Color(0xFF1A1A1A),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD4AF37)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF050505),
        elevation: 0,
        title: Text(
          t(context, 'cars.add_car_title', ar: 'إضافة سيارة', en: 'Add Car'),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
        ),
        iconTheme: const IconThemeData(color: Colors.white70),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Directionality(
            textDirection: isLtr(context) ? ui.TextDirection.ltr : ui.TextDirection.rtl,
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    t(context, 'cars.car_info', ar: 'معلومات السيارة', en: 'Car Information'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Chassis Input
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      border: Border.all(color: const Color(0xFF2A2A2A), width: 1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextFormField(
                      controller: _chassisController,
                      validator: _requiredValidator,
                      textDirection: ui.TextDirection.ltr,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                      decoration: InputDecoration(
                        hintText: t(context, 'cars.chassis_number', ar: 'رقم الشاسيه', en: 'Chassis Number'),
                        hintStyle: const TextStyle(color: Colors.white54),
                        filled: true,
                        fillColor: Colors.transparent,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Plate Input
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      border: Border.all(color: const Color(0xFF2A2A2A), width: 1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextFormField(
                      controller: _plateController,
                      validator: _requiredValidator,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                      decoration: InputDecoration(
                        hintText: t(context, 'cars.plate_number', ar: 'رقم اللوحة', en: 'Plate Number'),
                        hintStyle: const TextStyle(color: Colors.white54),
                        filled: true,
                        fillColor: Colors.transparent,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Brand Dropdown
                  DropdownButtonFormField<BrandModel>(
                    decoration: _dropdownDecoration(hint: t(context, 'cars.brand', ar: 'الماركة', en: 'Brand')),
                    value: _selectedBrand,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                    dropdownColor: const Color(0xFF1A1A1A),
                    items: _brands
                        .map(
                          (b) => DropdownMenuItem<BrandModel>(
                            value: b,
                            child: Text(b.name, style: const TextStyle(color: Colors.white)),
                          ),
                        )
                        .toList(),
                    onChanged: _loadingBrands
                        ? null
                        : (v) {
                            setState(() {
                              _selectedBrand = v;
                            });
                            if (v != null) {
                              _loadModels(v.id);
                            }
                          },
                  ),
                  if (_loadingBrands)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: LinearProgressIndicator(minHeight: 2),
                    ),
                  const SizedBox(height: 12),
                  // Model Dropdown
                  DropdownButtonFormField<CarModelModel>(
                    decoration: _dropdownDecoration(hint: t(context, 'cars.model', ar: 'الموديل', en: 'Model')),
                    value: _selectedModel,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                    dropdownColor: const Color(0xFF1A1A1A),
                    items: _models
                        .map(
                          (m) => DropdownMenuItem<CarModelModel>(
                            value: m,
                            child: Text(m.name, style: const TextStyle(color: Colors.white)),
                          ),
                        )
                        .toList(),
                    onChanged: (_loadingModels || _selectedBrand == null) ? null : (v) => setState(() => _selectedModel = v),
                  ),
                  if (_loadingModels)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: LinearProgressIndicator(minHeight: 2),
                    ),
                  const SizedBox(height: 12),
                  // Color Input
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      border: Border.all(color: const Color(0xFF2A2A2A), width: 1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextFormField(
                      controller: _colorController,
                      validator: _requiredValidator,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                      decoration: InputDecoration(
                        hintText: t(context, 'cars.color', ar: 'اللون', en: 'Color'),
                        hintStyle: const TextStyle(color: Colors.white54),
                        filled: true,
                        fillColor: Colors.transparent,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Year Dropdown
                  DropdownButtonFormField<String>(
                    decoration: _dropdownDecoration(hint: t(context, 'cars.manufacturing_year', ar: 'سنة الصنع', en: 'Manufacturing Year')),
                    value: _selectedYear,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                    dropdownColor: const Color(0xFF1A1A1A),
                    items: _years
                        .map(
                          (y) => DropdownMenuItem<String>(
                            value: y,
                            child: Text(y, style: const TextStyle(color: Colors.white)),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _selectedYear = v),
                  ),
                  const SizedBox(height: 24),
                  // Submit Button
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD4AF37),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _submit,
                      child: Text(
                        t(context, 'cars.add_car', ar: 'إضافة سيارة', en: 'Add Car'),
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
