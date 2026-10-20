import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:ui' as ui;
import 'package:easy_localization/easy_localization.dart';

import 'package:reservation_workshop/core/components/toasters.dart';
import 'package:reservation_workshop/core/widgets/app_header.dart';
import 'package:reservation_workshop/core/widgets/login_required_view.dart';
import 'package:reservation_workshop/config/routes/routes_name.dart';

import 'package:reservation_workshop/modules/customer/presentation/cubits/customer_info_cubit/customer_info_cubit.dart';

import '../../data/models/pickup_request_model.dart';
import '../cubit/rescue_cubit.dart';
import '../cubit/rescue_state.dart';
import 'pick_location_screen.dart';

class RescueScreen extends StatefulWidget {
  const RescueScreen({super.key});

  @override
  State<RescueScreen> createState() => _RescueScreenState();
}

class _RescueScreenState extends State<RescueScreen> {
  final _formKey = GlobalKey<FormState>();

  int? _deviceId;
  int? _locationId;
  int? _serviceId;
  DateTime? _bookingStart;

  double? _pickupLat;
  double? _pickupLng;

  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _locationController.text = '';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<RescueCubit>().load(
        customerInfoCubit: context.read<CustomerInfoCubit>(),
      );
    });
  }

  @override
  void dispose() {
    _locationController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  String _formatDateTime(DateTime? dt) {
    if (dt == null) return 'rescue.select_datetime'.tr();
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $hh:$mm:00';
  }

  Future<void> _pickBookingStart() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _bookingStart ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_bookingStart ?? now),
    );
    if (time == null) return;

    setState(() {
      _bookingStart = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _pickLocationFromMap() async {
    final initialLat = _pickupLat;
    final initialLng = _pickupLng;

    final picked = await Navigator.of(context).push<PickedLocation>(
      MaterialPageRoute(
        builder: (_) => PickLocationScreen(
          initialLatitude: initialLat,
          initialLongitude: initialLng,
        ),
      ),
    );

    if (picked == null) return;

    setState(() {
      _pickupLat = picked.latitude;
      _pickupLng = picked.longitude;
      _locationController.text = _locationLabel();
    });
  }

  String _locationLabel() {
    if (_pickupLat == null || _pickupLng == null)
      return 'rescue.location_pick_on_map'.tr();
    return 'rescue.location_picked_success'.tr();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    if (_deviceId == null ||
        _locationId == null ||
        _serviceId == null ||
        _bookingStart == null ||
        _pickupLat == null ||
        _pickupLng == null) {
      Toasters.errorKey('rescue.toast_fill_required');
      return;
    }

    final request = PickupRequestModel(
      deviceId: _deviceId!,
      locationId: _locationId!,
      serviceId: _serviceId!,
      bookingStart: _formatDateTime(_bookingStart),
      pickupLatitude: _pickupLat!,
      pickupLongitude: _pickupLng!,
      bookingNote: _noteController.text,
    );

    context.read<RescueCubit>().submit(request: request);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final size = MediaQuery.of(context).size;

    return Directionality(
      textDirection: context.locale.languageCode == 'ar'
          ? ui.TextDirection.rtl
          : ui.TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Column(
            children: [
              AppHeader(
                title: 'rescue.title'.tr(),
                onBack: () => Navigator.pop(context),
                titleColor: Colors.white,
              ),
              Expanded(
                child: BlocConsumer<RescueCubit, RescueState>(
                  listener: (context, state) {
                    if (state is RescueError) {
                      Toasters.errorFrom(
                        state.message,
                        fallbackKey: 'rescue.request_failed',
                      );
                    }
                    if (state is RescueSuccess) {
                      Toasters.success('rescue.request_sent'.tr());
                      Navigator.pop(context);
                    }
                  },
                  builder: (context, state) {
                    if (state is RescueLoading) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: const Color(0xFFD4AF37).withOpacity(0.3),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.20),
                                    blurRadius: 24,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: const CircularProgressIndicator(
                                strokeWidth: 3,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'rescue.loading'.tr(),
                              style: textTheme.bodyMedium?.copyWith(
                                color: const Color.fromARGB(153, 255, 255, 255),
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    if (state is RescueError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFFD4AF37,
                                  ).withOpacity(0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.error_outline_rounded,
                                  size: 48,
                                  color: Colors.white70,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                Toasters.displayMessage(state.message),
                                textAlign: TextAlign.center,
                                style: textTheme.bodyLarge?.copyWith(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  height: 1.6,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    if (state is RescueGuestNotAllowed) {
                      return const LoginRequiredView();
                    }

                    if (state is! RescueLoaded) {
                      return const SizedBox.shrink();
                    }

                    final isGuest = state.isGuest;

                    return SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(
                        20,
                        16,
                        20,
                        MediaQuery.of(context).viewInsets.bottom + 20,
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: const Color(0xFFD4AF37).withOpacity(0.3),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 16,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: const Color.fromARGB(
                                            179,
                                            100,
                                            116,
                                            139,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.directions_car_rounded,
                                          size: 22,
                                          color: Colors.white70,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'rescue.section_request_data'.tr(),
                                        style: textTheme.titleLarge?.copyWith(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),
                                  _buildModernDropdown(
                                    label: 'rescue.label_car'.tr(),
                                    icon: Icons.directions_car_filled_rounded,
                                    value: _deviceId,
                                    items: state.cars
                                        .map(
                                          (c) => DropdownMenuItem<int>(
                                            value: c.id,
                                            child: Text(
                                              '${c.device} ${c.model} ${(c.plateNumber ?? '').trim()}'
                                                  .trim(),
                                              style: const TextStyle(
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (v) =>
                                        setState(() => _deviceId = v),
                                  ),
                                  const SizedBox(height: 16),
                                  _buildModernDropdown(
                                    label: 'rescue.label_branch'.tr(),
                                    icon: Icons.location_city_rounded,
                                    value: _locationId,
                                    items: state.branches
                                        .map(
                                          (b) => DropdownMenuItem<int>(
                                            value: b.id,
                                            child: Text(
                                              b.name,
                                              style: const TextStyle(
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (v) {
                                      setState(() {
                                        _locationId = v;
                                        _serviceId = null;
                                      });
                                      if (v != null) {
                                        context
                                            .read<RescueCubit>()
                                            .loadServices(locationId: v);
                                      }
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  _buildModernDropdown(
                                    label: 'rescue.label_service'.tr(),
                                    icon: Icons.build_circle_rounded,
                                    value: _serviceId,
                                    items: state.services
                                        .map(
                                          (s) => DropdownMenuItem<int>(
                                            value: s.id,
                                            child: Text(
                                              s.name,
                                              style: const TextStyle(
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (v) =>
                                        setState(() => _serviceId = v),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: const Color(0xFFD4AF37).withOpacity(0.3),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color.fromARGB(
                                    20,
                                    255,
                                    255,
                                    255,
                                  ),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.20),
                                    blurRadius: 16,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: const Color.fromARGB(
                                            38,
                                            139,
                                            92,
                                            246,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.access_time_rounded,
                                          size: 22,
                                          color: Colors.white70,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'rescue.section_datetime_location'.tr(),
                                        style: textTheme.titleLarge?.copyWith(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),
                                  _buildDateTimeField(
                                    label: 'rescue.label_booking_start'.tr(),
                                    value: _formatDateTime(_bookingStart),
                                    onTap: _pickBookingStart,
                                    icon: Icons.calendar_today_rounded,
                                  ),
                                  const SizedBox(height: 16),
                                  _buildLocationField(
                                    label: 'rescue.label_location'.tr(),
                                    value: _locationLabel(),
                                    onTap: _pickLocationFromMap,
                                    hasLocation:
                                        _pickupLat != null &&
                                        _pickupLng != null,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: const Color(0xFFD4AF37).withOpacity(0.3),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color.fromARGB(
                                    20,
                                    255,
                                    255,
                                    255,
                                  ),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.20),
                                    blurRadius: 16,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: const Color(
                                            0xFFF59E0B,
                                          ).withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.note_alt_rounded,
                                          size: 22,
                                          color: Colors.white70,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'rescue.section_notes'.tr(),
                                        style: textTheme.titleLarge?.copyWith(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  TextFormField(
                                    controller: _noteController,
                                    maxLines: 4,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      height: 1.6,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: 'rescue.notes_hint'.tr(),
                                      hintStyle: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 13,
                                      ),
                                      filled: true,
                                      fillColor: const Color(0xFF050505),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: const Color(
                                            0xFFD4AF37,
                                          ).withOpacity(0.3),
                                          width: 1.5,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: const Color(
                                            0xFFD4AF37,
                                          ).withOpacity(0.3),
                                          width: 1.5,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                          color: Color(0xFF3B82F6),
                                          width: 2,
                                        ),
                                      ),
                                      contentPadding: const EdgeInsets.all(16),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 28),
                            if (isGuest)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF050505),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: Colors.white10),
                                    ),
                                    child: Text(
                                      'auth.login_required_message'.tr(),
                                      style: textTheme.bodyMedium?.copyWith(
                                        color: Colors.white70,
                                        fontSize: 14,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 52,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFFD4AF37,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                      ),
                                      onPressed: () {
                                        Navigator.pushNamedAndRemoveUntil(
                                          context,
                                          RoutesName.enterMobileScreen,
                                          (route) => false,
                                        );
                                      },
                                      child: Text(
                                        'auth.login_button'.tr(),
                                        style: textTheme.titleMedium?.copyWith(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                ],
                              )
                            else
                              Container(
                                height: 56,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  gradient: const LinearGradient(
                                    colors: [
                                      const Color(0xFFD4AF37),
                                      const Color(0xFFB8942E),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFFD4AF37,
                                      ).withOpacity(0.3).withOpacity(0.3),
                                      blurRadius: 16,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: state.isSubmitting
                                      ? null
                                      : _submit,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    padding: EdgeInsets.zero,
                                  ),
                                  child: state.isSubmitting
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const Icon(
                                              Icons.send_rounded,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 10),
                                            Text(
                                              'rescue.submit'.tr(),
                                              style: textTheme.titleMedium
                                                  ?.copyWith(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
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

  Widget _buildModernDropdown({
    required String label,
    required IconData icon,
    required int? value,
    required List<DropdownMenuItem<int>> items,
    required void Function(int?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 4, bottom: 8),
          child: Row(
            children: [
              Icon(icon, size: 16, color: const Color(0xFF64748B)),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const Text(
                ' *',
                style: TextStyle(
                  color: const Color(0xFFD4AF37),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        DropdownButtonFormField<int>(
          value: value,
          items: items,
          onChanged: onChanged,
          validator: (v) => (v == null) ? 'rescue.required_field'.tr() : null,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 24),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFF050505),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: const Color(0xFFD4AF37).withOpacity(0.3),
                width: 1.5,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: const Color(0xFFD4AF37).withOpacity(0.3),
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: const Color(0xFFD4AF37),
                width: 1.5,
              ),
            ),
          ),
          style: const TextStyle(
            fontSize: 14,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildDateTimeField({
    required String label,
    required String value,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    final hasValue = value != 'rescue.select_datetime'.tr();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 4, bottom: 8),
          child: Row(
            children: [
              Icon(icon, size: 16, color: const Color(0xFF64748B)),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const Text(
                ' *',
                style: TextStyle(
                  color: const Color(0xFFD4AF37),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF050505),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFD4AF37).withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: hasValue ? Colors.white : Colors.white70,
                    ),
                  ),
                ),
                Icon(
                  Icons.edit_calendar_rounded,
                  size: 20,
                  color: hasValue ? const Color(0xFF8B5CF6) : Colors.white70,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationField({
    required String label,
    required String value,
    required VoidCallback onTap,
    required bool hasLocation,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 4, bottom: 8),
          child: Row(
            children: [
              const Icon(
                Icons.location_on_rounded,
                size: 16,
                color: Color(0xFF64748B),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const Text(
                ' *',
                style: TextStyle(
                  color: const Color(0xFFD4AF37),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: hasLocation
                  ? const Color.fromARGB(13, 16, 185, 129)
                  : const Color(0xFF050505),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: hasLocation
                    ? const Color.fromARGB(77, 16, 185, 129)
                    : const Color(0xFFD4AF37).withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: hasLocation
                        ? const Color.fromARGB(26, 16, 185, 129)
                        : const Color(0xFF050505),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    hasLocation
                        ? Icons.check_circle_rounded
                        : Icons.map_rounded,
                    size: 20,
                    color: hasLocation
                        ? const Color(0xFF10B981)
                        : Colors.white70,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: hasLocation
                          ? const Color(0xFF059669)
                          : Colors.white70,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_back_ios_rounded,
                  size: 16,
                  color: hasLocation ? const Color(0xFF10B981) : Colors.white70,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
