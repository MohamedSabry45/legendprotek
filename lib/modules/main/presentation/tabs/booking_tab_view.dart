import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:reservation_workshop/config/routes/routes_name.dart';
import 'package:reservation_workshop/config/style/app_colors.dart';
import 'package:reservation_workshop/config/style/app_spacing.dart';
import 'package:reservation_workshop/core/components/toasters.dart';
import 'package:reservation_workshop/core/network/local/cache_helper.dart';
import 'package:reservation_workshop/core/utils/strings/prefkeys.dart';
import 'package:reservation_workshop/core/widgets/app_card.dart';
import 'package:reservation_workshop/core/widgets/login_required_view.dart';
import 'package:reservation_workshop/modules/branch/domain/entities/branch.dart';
import 'package:reservation_workshop/modules/branch/presentation/cubits/branch_cubit/branch_cubit.dart';
import 'package:reservation_workshop/modules/branch/presentation/cubits/branch_cubit/branch_state.dart';
import 'package:reservation_workshop/modules/customer/domain/entities/customer_car.dart';
import 'package:reservation_workshop/modules/customer/presentation/cubits/customer_info_cubit/customer_info_cubit.dart';
import 'package:reservation_workshop/modules/customer/presentation/cubits/customer_info_cubit/customer_info_state.dart';
import 'package:reservation_workshop/modules/main/presentation/screens/booking_details_args.dart';
import 'package:reservation_workshop/modules/main/presentation/widgets/booking_dropdown_field.dart';
import 'package:reservation_workshop/modules/main/presentation/widgets/date_time_field.dart';
import 'package:reservation_workshop/modules/main/presentation/widgets/notes_field.dart';
import 'package:reservation_workshop/modules/main/presentation/widgets/notification_card.dart';
import 'package:reservation_workshop/modules/main/presentation/widgets/submit_booking_button.dart';
import 'package:reservation_workshop/modules/service/domain/entities/service.dart';
import 'package:reservation_workshop/modules/service/presentation/cubits/service_cubit/service_cubit.dart';
import 'package:reservation_workshop/modules/service/presentation/cubits/service_cubit/service_state.dart';

class BookingTabView extends StatefulWidget {
  const BookingTabView({super.key});

  @override
  State<BookingTabView> createState() => _BookingTabViewState();
}

class _BookingTabViewState extends State<BookingTabView> {
  int? _selectedBranchId;
  int? _selectedCarId;
  int? _selectedServiceId;
  DateTime _selectedDateTime = DateTime.now();
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSelectedCar();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final isGuest =
          CacheHelper.getData<bool>(key: PrefKeys.kIsGuestMode) ?? false;
      if (isGuest) return;
      context.read<CustomerInfoCubit>().load();
      context.read<BranchCubit>().load();
    });
  }

  Future<void> _loadSelectedCar() async {
    final carId = await CacheHelper.getDataAsync<int>(
      key: PrefKeys.kSelectedCarId,
    );
    if (!mounted) return;
    setState(() => _selectedCarId = carId);
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

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDate: _selectedDateTime,
    );
    if (date == null) return;

    if (!mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
    );
    if (time == null) return;

    setState(() {
      _selectedDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  String _formatDateTime(DateTime dt) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(dt.month)}/${two(dt.day)}/${dt.year} ${two(dt.hour)}:${two(dt.minute)}';
  }

  String _formatBookingStart(DateTime dt) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${dt.year}-${two(dt.month)}-${two(dt.day)}T${two(dt.hour)}:${two(dt.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isGuest =
        CacheHelper.getData<bool>(key: PrefKeys.kIsGuestMode) ?? false;
    if (isGuest) {
      return const LoginRequiredView();
    }
    return BlocBuilder<CustomerInfoCubit, CustomerInfoState>(
      builder: (context, state) {
        final customerName = state is CustomerInfoSuccess
            ? state.info.name
            : '';
        final cars = state is CustomerInfoSuccess
            ? state.info.cars
            : const <CustomerCar>[];

        final greeting = customerName.trim().isEmpty
            ? 'booking.greeting'.tr()
            : 'booking.greeting_named'.tr(args: [customerName]);

        return LayoutBuilder(
          builder: (context, constraints) {
            return CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  sliver: SliverToBoxAdapter(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: AppCard(
                          padding: const EdgeInsets.all(16),
                          borderRadius: 18,
                          backgroundColor: const Color(0xFF050505),
                          borderColor: const Color(
                            0xFFD4AF37,
                          ).withOpacity(0.25),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFD4AF37).withOpacity(0.15),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                greeting,
                                style: textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'booking.subtitle'.tr(),
                                style: textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withOpacity(0.7),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              BookingDropdownField<int>(
                                label: 'booking.car'.tr(),
                                labelColor: Colors.white,
                                value: _selectedCarId,
                                items: cars
                                    .map(
                                      (c) => DropdownMenuItem<int>(
                                        value: c.id,
                                        child: Text(_carLabel(c)),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (id) async {
                                  if (id == null) return;
                                  final car = cars
                                      .where((e) => e.id == id)
                                      .toList();
                                  if (car.isEmpty) return;

                                  setState(() => _selectedCarId = id);
                                  await _persistSelectedCar(car.first);
                                  if (!context.mounted) return;
                                  context.read<CustomerInfoCubit>().load();
                                },
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              BlocBuilder<BranchCubit, BranchState>(
                                builder: (context, branchState) {
                                  final branches = branchState is BranchSuccess
                                      ? branchState.branches
                                      : const <Branch>[];

                                  return BookingDropdownField<int>(
                                    label: 'booking.select_branch'.tr(),
                                    labelColor: Colors.white,
                                    isRequired: true,
                                    value: _selectedBranchId,
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
                                      context.read<ServiceCubit>().load(
                                        locationId: id,
                                      );
                                    },
                                  );
                                },
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              if (_selectedBranchId != null)
                                BlocBuilder<ServiceCubit, ServiceState>(
                                  builder: (context, serviceState) {
                                    final services =
                                        serviceState is ServiceSuccess
                                        ? serviceState.services
                                        : const <Service>[];

                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              'booking.select_service'.tr(),
                                              style: textTheme.bodySmall
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.white,
                                                  ),
                                            ),
                                            const SizedBox(width: 4),
                                            const Text(
                                              '*',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: const Color(0xFFD4AF37),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: AppSpacing.md),
                                        GridView.count(
                                          crossAxisCount: 2,
                                          mainAxisSpacing: 10,
                                          crossAxisSpacing: 10,
                                          childAspectRatio: 2.55,
                                          shrinkWrap: true,
                                          physics:
                                              const NeverScrollableScrollPhysics(),
                                          children: services
                                              .map(
                                                (s) => _ServiceCard(
                                                  title: s.name,
                                                  selected:
                                                      _selectedServiceId ==
                                                      s.id,
                                                  onTap: () => setState(
                                                    () => _selectedServiceId =
                                                        s.id,
                                                  ),
                                                ),
                                              )
                                              .toList(),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              const SizedBox(height: AppSpacing.lg),
                              DateTimeField(
                                label: 'booking.select_datetime'.tr(),
                                labelColor: Colors.white,
                                valueText: _formatDateTime(_selectedDateTime),
                                onPick: _pickDateTime,
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              NotesField(
                                hintText: 'booking.describe_problem'.tr(),
                                controller: _notesController,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            const SizedBox(height: AppSpacing.lg),
                            SubmitBookingButton(
                              onPressed: () async {
                                final isGuest =
                                    CacheHelper.getData<bool>(
                                      key: PrefKeys.kIsGuestMode,
                                    ) ??
                                    false;
                                if (isGuest) {
                                  Navigator.pushNamedAndRemoveUntil(
                                    context,
                                    RoutesName.enterMobileScreen,
                                    (route) => false,
                                  );
                                  return;
                                }

                                final carId = _selectedCarId;
                                final branchId = _selectedBranchId;
                                final serviceId = _selectedServiceId;

                                if (carId == null) {
                                  Toasters.errorKey('booking.toast_select_car');
                                  return;
                                }
                                if (branchId == null) {
                                  Toasters.errorKey(
                                    'booking.toast_select_branch',
                                  );
                                  return;
                                }
                                if (serviceId == null) {
                                  Toasters.errorKey(
                                    'booking.toast_select_service',
                                  );
                                  return;
                                }

                                final customerState = context
                                    .read<CustomerInfoCubit>()
                                    .state;
                                final name =
                                    customerState is CustomerInfoSuccess
                                    ? customerState.info.name
                                    : '';
                                final phone =
                                    customerState is CustomerInfoSuccess
                                    ? customerState.info.mobile
                                    : '';
                                final cars =
                                    customerState is CustomerInfoSuccess
                                    ? customerState.info.cars
                                    : const <CustomerCar>[];
                                final selectedCar = cars
                                    .where((c) => c.id == carId)
                                    .toList();

                                final branchState = context
                                    .read<BranchCubit>()
                                    .state;
                                final branches = branchState is BranchSuccess
                                    ? branchState.branches
                                    : const <Branch>[];
                                final selectedBranch = branches
                                    .where((b) => b.id == branchId)
                                    .toList();

                                final serviceState = context
                                    .read<ServiceCubit>()
                                    .state;
                                final services = serviceState is ServiceSuccess
                                    ? serviceState.services
                                    : const <Service>[];
                                final selectedService = services
                                    .where((s) => s.id == serviceId)
                                    .toList();

                                final note = _notesController.text.trim();
                                final bookingStart = _formatBookingStart(
                                  _selectedDateTime,
                                );

                                final model = NotificationCardModel(
                                  workOrderNo: '-',
                                  customer: '',
                                  car: selectedCar.isNotEmpty
                                      ? selectedCar.first.device
                                      : '-',
                                  carModel: selectedCar.isNotEmpty
                                      ? selectedCar.first.model
                                      : '-',
                                  plate: selectedCar.isNotEmpty
                                      ? ((selectedCar.first.plateNumber ?? '')
                                                .trim()
                                                .isEmpty
                                            ? '-'
                                            : selectedCar.first.plateNumber!
                                                  .trim())
                                      : '-',
                                  status: '-',
                                  dateTime: bookingStart,
                                  service: selectedService.isNotEmpty
                                      ? selectedService.first.name
                                      : '-',
                                  branch: selectedBranch.isNotEmpty
                                      ? selectedBranch.first.name
                                      : '-',
                                  area: note.isEmpty ? '-' : note,
                                  name: name,
                                  phone: phone,
                                );

                                final args = BookingDetailsArgs(
                                  model: model,
                                  bookingStart: bookingStart,
                                  locationId: branchId,
                                  serviceId: serviceId,
                                  deviceId: carId,
                                  bookingNote: note,
                                );

                                final created =
                                    await Navigator.pushNamed(
                                      context,
                                      RoutesName.bookingDetailsScreen,
                                      arguments: args,
                                    );

                                if (created == true && mounted) {
                                  setState(() {
                                    _selectedBranchId = null;
                                    _selectedServiceId = null;
                                    _selectedDateTime = DateTime.now();
                                    _notesController.clear();
                                  });
                                }
                              },
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'booking.can_edit_before_confirm'.tr(),
                              textAlign: TextAlign.center,
                              style: textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w500,
                                color: AppColors.grey7,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFD4AF37) : const Color(0xFF0A0A0A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? const Color(0xFFD4AF37)
                : const Color(0xFFD4AF37).withOpacity(0.3),
            width: 1.2,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: const Color(0xFFD4AF37).withOpacity(0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [],
        ),
        child: Center(
          child: Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: textTheme.bodySmall?.copyWith(
              height: 1.2,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
