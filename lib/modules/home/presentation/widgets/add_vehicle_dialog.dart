import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:reservation_workshop/config/style/app_colors.dart';
import 'package:reservation_workshop/core/components/toasters.dart';

import '../../data/datasources/vehicle_filters_remote_datasource.dart';
import '../cubit/vehicles_cubit.dart';
import 'image_watermark_picker.dart';
import 'modern_dropdown.dart';
import 'modern_switch_tile.dart';
import 'section_card.dart';
import 'vehicle_form_constants.dart';

class AddVehicleDialog extends StatefulWidget {
  const AddVehicleDialog({super.key});

  @override
  State<AddVehicleDialog> createState() => _AddVehicleDialogState();
}

class _AddVehicleDialogState extends State<AddVehicleDialog> {
  final _formKey = GlobalKey<FormState>();
  final _filtersDataSource = VehicleFiltersRemoteDataSourceImpl();
  bool _isLoadingBrands = false;
  bool _isLoadingModels = false;
  bool _isSubmitting = false;

  List<FilterItem> _brands = <FilterItem>[];
  List<FilterItem> _models = <FilterItem>[];

  FilterItem? _selectedBrand;
  FilterItem? _selectedModel;

  List<String> _imagesDataUrls = <String>[];

  final _yearController = TextEditingController();
  final _listingPriceController = TextEditingController();
  final _minPriceController = TextEditingController();
  final _colorController = TextEditingController();
  final _trimLevelController = TextEditingController();
  final _vinController = TextEditingController();
  final _plateController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationCityController = TextEditingController();
  final _locationAreaController = TextEditingController();
  final _license3YearCostController = TextEditingController();
  final _insuranceAnnualCostController = TextEditingController();
  final _insuranceRatePctController = TextEditingController();
  final _conditionNotesController = TextEditingController();
  final _currencyController = TextEditingController();

  String? _selectedCondition;
  String? _selectedBodyType;
  String? _selectedFuelType;
  String? _selectedTransmission;
  String? _selectedLicenseType;

  bool _factoryPaint = false;
  bool _importedSpecs = false;

  @override
  void initState() {
    super.initState();
    _selectedCondition = 'used';
    _selectedBodyType = 'suv';
    _selectedFuelType = 'gas';
    _selectedTransmission = 'automatic';
    _selectedLicenseType = 'seller_owned';
    _currencyController.text = 'EGP';
    _loadBrands();
  }

  @override
  void dispose() {
    _yearController.dispose();
    _listingPriceController.dispose();
    _minPriceController.dispose();
    _colorController.dispose();
    _trimLevelController.dispose();
    _vinController.dispose();
    _plateController.dispose();
    _descriptionController.dispose();
    _locationCityController.dispose();
    _locationAreaController.dispose();
    _license3YearCostController.dispose();
    _insuranceAnnualCostController.dispose();
    _insuranceRatePctController.dispose();
    _conditionNotesController.dispose();
    _currencyController.dispose();
    super.dispose();
  }

  Future<void> _loadBrands() async {
    setState(() => _isLoadingBrands = true);
    try {
      final brands = await _filtersDataSource.getBrands(perPage: 50, page: 1);
      if (!mounted) return;
      setState(() {
        _brands = brands;
        _isLoadingBrands = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingBrands = false);
    }
  }

  Future<void> _loadModels(int brandId) async {
    setState(() {
      _isLoadingModels = true;
      _models = <FilterItem>[];
      _selectedModel = null;
    });

    try {
      final models = await _filtersDataSource.getModels(
        brandCategoryId: brandId,
        perPage: 50,
        page: 1,
      );
      if (!mounted) return;
      setState(() {
        _models = models;
        _isLoadingModels = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingModels = false);
    }
  }

  int _asInt(String value) => int.tryParse(value.trim()) ?? 0;

  double _asDouble(String value) => double.tryParse(value.trim()) ?? 0.0;

  Future<void> _submit() async {
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) return;
    if (_selectedBrand == null || _selectedModel == null) {
      Toasters.errorKey('add_vehicle.select_brand_model');
      return;
    }

    if (_selectedCondition == null ||
        _selectedBodyType == null ||
        _selectedFuelType == null ||
        _selectedTransmission == null ||
        _selectedLicenseType == null ||
        _currencyController.text.trim().isEmpty) {
      Toasters.errorKey('add_vehicle.fill_required');
      return;
    }

    if (_imagesDataUrls.isEmpty) {
      Toasters.errorKey('add_vehicle.please_add_images');
      return;
    }

    final year = _asInt(_yearController.text);
    final listingPrice = _asInt(_listingPriceController.text);
    final minPrice = _asInt(_minPriceController.text);

    final license3Years = _asInt(_license3YearCostController.text);
    final insuranceAnnual = _asInt(_insuranceAnnualCostController.text);
    final insuranceRate = _asDouble(_insuranceRatePctController.text);

    final body = <String, dynamic>{
      'brand_category_id': _selectedBrand!.id,
      'repair_device_model_id': _selectedModel!.id,
      'year': year,
      'listing_price': listingPrice,
      'condition': _selectedCondition!,
      'body_type': _selectedBodyType!,
      'fuel_type': _selectedFuelType!,
      'transmission': _selectedTransmission!,
      'color': _colorController.text.trim(),
      'trim_level': _trimLevelController.text.trim(),
      'vin_number': _vinController.text.trim(),
      'plate_number': _plateController.text.trim(),
      'description': _descriptionController.text.trim(),
      'location_city': _locationCityController.text.trim(),
      'location_area': _locationAreaController.text.trim(),
      'ownership_costs': {
        'license_3year_cost': license3Years,
        'insurance_annual_cost': insuranceAnnual,
        'insurance_rate_pct': insuranceRate,
      },
      'factory_paint': _factoryPaint,
      'imported_specs': _importedSpecs,
      'license_type': _selectedLicenseType ?? 'seller_owned',
      'condition_notes': _conditionNotesController.text.trim(),
      'min_price': minPrice,
      'currency': _currencyController.text.trim(),
      'license_3year_cost': license3Years,
      'insurance_annual_cost': insuranceAnnual,
      'insurance_rate_pct': insuranceRate,
      'images': List<String>.unmodifiable(_imagesDataUrls),
    };

    setState(() => _isSubmitting = true);

    try {
      await context.read<VehiclesCubit>().createSellerVehicle(
        body: body,
      );
      if (!mounted) return;
      Toasters.success('add_vehicle.success'.tr());
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      Toasters.errorFrom(e, fallbackKey: 'add_vehicle.error');
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.92,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.brandPrimary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.add,
                      color: AppColors.brandPrimary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    context.locale.languageCode == 'ar'
                        ? 'إضافة سيارة للبيع'
                        : 'Add vehicle for sale',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A1A1A),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFF0F0F0)),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: FilterDropdown(
                              label: context.locale.languageCode == 'ar'
                                  ? 'الماركة'
                                  : 'Brand',
                              value: _selectedBrand,
                              items: _brands,
                              isLoading: _isLoadingBrands,
                              onChanged: (v) {
                                setState(() => _selectedBrand = v);
                                if (v != null) {
                                  _loadModels(v.id);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilterDropdown(
                              label: context.locale.languageCode == 'ar'
                                  ? 'الموديل'
                                  : 'Model',
                              value: _selectedModel,
                              items: _models,
                              isLoading: _isLoadingModels,
                              enabled:
                                  _selectedBrand != null && !_isLoadingModels,
                              onChanged: (v) =>
                                  setState(() => _selectedModel = v),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              label: context.locale.languageCode == 'ar'
                                  ? 'سنة الصنع'
                                  : 'Year',
                              controller: _yearController,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextField(
                              label: context.locale.languageCode == 'ar'
                                  ? 'السعر'
                                  : 'Price',
                              controller: _listingPriceController,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Vehicle Details Section
                      SectionCard(
                        title: context.locale.languageCode == 'ar'
                            ? 'مواصفات السيارة'
                            : 'Vehicle Details',
                        icon: Icons.settings_rounded,
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: ModernDropdown(
                                    label: context.locale.languageCode == 'ar'
                                        ? 'الحالة'
                                        : 'Condition',
                                    value: _selectedCondition,
                                    items: VehicleFormConstants.conditions,
                                    onChanged: (val) => setState(
                                      () => _selectedCondition = val,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: ModernDropdown(
                                    label: context.locale.languageCode == 'ar'
                                        ? 'نوع الهيكل'
                                        : 'Body type',
                                    value: _selectedBodyType,
                                    items: VehicleFormConstants.bodyTypes,
                                    onChanged: (val) =>
                                        setState(() => _selectedBodyType = val),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: ModernDropdown(
                                    label: context.locale.languageCode == 'ar'
                                        ? 'نوع الوقود'
                                        : 'Fuel type',
                                    value: _selectedFuelType,
                                    items: VehicleFormConstants.fuelTypes,
                                    onChanged: (val) =>
                                        setState(() => _selectedFuelType = val),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: ModernDropdown(
                                    label: context.locale.languageCode == 'ar'
                                        ? 'ناقل الحركة'
                                        : 'Transmission',
                                    value: _selectedTransmission,
                                    items: VehicleFormConstants.transmissions,
                                    onChanged: (val) => setState(
                                      () => _selectedTransmission = val,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Appearance Section
                      SectionCard(
                        title: context.locale.languageCode == 'ar'
                            ? 'المظهر والتعريف'
                            : 'Appearance & ID',
                        icon: Icons.palette_rounded,
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _buildTextField(
                                    label: context.locale.languageCode == 'ar'
                                        ? 'اللون'
                                        : 'Color',
                                    controller: _colorController,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildTextField(
                                    label: context.locale.languageCode == 'ar'
                                        ? 'الموديل'
                                        : 'Trim level',
                                    controller: _trimLevelController,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildTextField(
                                    label: context.locale.languageCode == 'ar'
                                        ? 'رقم الهيكل'
                                        : 'VIN number',
                                    controller: _vinController,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildTextField(
                                    label: context.locale.languageCode == 'ar'
                                        ? 'رقم اللوحة'
                                        : 'Plate number',
                                    controller: _plateController,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Location Section
                      SectionCard(
                        title: context.locale.languageCode == 'ar'
                            ? 'الموقع'
                            : 'Location',
                        icon: Icons.location_on_rounded,
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                label: context.locale.languageCode == 'ar'
                                    ? 'المدينة'
                                    : 'City',
                                controller: _locationCityController,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildTextField(
                                label: context.locale.languageCode == 'ar'
                                    ? 'المنطقة'
                                    : 'Area',
                                controller: _locationAreaController,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Description Section
                      SectionCard(
                        title: context.locale.languageCode == 'ar'
                            ? 'الوصف'
                            : 'Description',
                        icon: Icons.description_rounded,
                        child: _buildTextField(
                          label: context.locale.languageCode == 'ar'
                              ? 'اكتب وصفاً مفصلاً للسيارة'
                              : 'Write a detailed description',
                          controller: _descriptionController,
                          maxLines: 4,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Pricing Details Section
                      SectionCard(
                        title: context.locale.languageCode == 'ar'
                            ? 'تفاصيل التسعير'
                            : 'Pricing Details',
                        icon: Icons.attach_money_rounded,
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                label: context.locale.languageCode == 'ar'
                                    ? 'أقل سعر'
                                    : 'Min price',
                                controller: _minPriceController,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildTextField(
                                label: context.locale.languageCode == 'ar'
                                    ? 'العملة'
                                    : 'Currency',
                                controller: _currencyController,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Features Section
                      SectionCard(
                        title: context.locale.languageCode == 'ar'
                            ? 'المميزات'
                            : 'Features',
                        icon: Icons.star_rounded,
                        child: Column(
                          children: [
                            ModernSwitchTile(
                              title: context.locale.languageCode == 'ar'
                                  ? 'دهان مصنع أصلي'
                                  : 'Original Factory Paint',
                              subtitle: context.locale.languageCode == 'ar'
                                  ? 'السيارة ذات الدهان الأصلي من المصنع'
                                  : 'Vehicle with original factory paint',
                              value: _factoryPaint,
                              onChanged: (v) =>
                                  setState(() => _factoryPaint = v),
                              icon: Icons.format_paint_rounded,
                            ),
                            const SizedBox(height: 12),
                            ModernSwitchTile(
                              title: context.locale.languageCode == 'ar'
                                  ? 'مواصفات مستوردة'
                                  : 'Imported Specifications',
                              subtitle: context.locale.languageCode == 'ar'
                                  ? 'سيارة بمواصفات عالمية مستوردة'
                                  : 'Vehicle with imported international specs',
                              value: _importedSpecs,
                              onChanged: (v) =>
                                  setState(() => _importedSpecs = v),
                              icon: Icons.flight_land_rounded,
                            ),
                            const SizedBox(height: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.badge_rounded,
                                      color: AppColors.brandPrimary,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      context.locale.languageCode == 'ar'
                                          ? 'نوع الرخصة'
                                          : 'License Type',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                DropdownButtonFormField<String>(
                                  value: _selectedLicenseType,
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  dropdownColor: Colors.white,
                                  isExpanded: true,
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: Colors.white,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: AppColors.brandPrimary,
                                        width: 2,
                                      ),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 14,
                                    ),
                                    hintStyle: TextStyle(
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                  items: VehicleFormConstants.licenseTypes.map((
                                    type,
                                  ) {
                                    final label =
                                        VehicleFormConstants.getLicenseTypeLabel(
                                          type,
                                          context.locale.languageCode,
                                        );
                                    return DropdownMenuItem(
                                      value: type,
                                      child: Text(
                                        label,
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (val) => setState(
                                    () => _selectedLicenseType = val,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Image Upload Section
                      SectionCard(
                        title: context.locale.languageCode == 'ar'
                            ? 'صور السيارة'
                            : 'Vehicle Images',
                        icon: Icons.photo_library_rounded,
                        child: ImageWatermarkPicker(
                          initialImages: _imagesDataUrls,
                          onImagesChanged: (val) =>
                              setState(() => _imagesDataUrls = val),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Footer buttons
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 16,
                    offset: const Offset(0, -8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 1.5,
                        ),
                        color: Colors.white,
                      ),
                      child: TextButton(
                        onPressed: _isSubmitting
                            ? null
                            : () => Navigator.of(context).pop(false),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.close_rounded,
                              color: Colors.grey.shade600,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'buy_car.cancel'.tr(),
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: const LinearGradient(
                          colors: [AppColors.brandPrimary, Color(0xFF1976D2)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.brandPrimary.withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _isSubmitting
                            ? SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.add_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    context.locale.languageCode == 'ar'
                                        ? 'إضافة سيارة'
                                        : 'Add Vehicle',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      letterSpacing: 0.5,
                                    ),
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
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool enabled = true,
    String? Function(String?)? validator,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          enabled: enabled,
          validator: validator,
          style: const TextStyle(color: Colors.black),
          decoration: InputDecoration(
            hintText: context.locale.languageCode == 'ar'
                ? 'اكتب $label'
                : 'Enter $label',
            filled: true,
            fillColor: const Color(0xFFF8F9FA),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.brandPrimary,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: const Color(0xFFD4AF37),
                width: 1,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: const Color(0xFFD4AF37),
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            hintStyle: TextStyle(color: Colors.grey.shade500),
          ),
        ),
      ],
    );
  }
}
