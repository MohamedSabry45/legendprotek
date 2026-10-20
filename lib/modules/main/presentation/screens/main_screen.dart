import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:reservation_workshop/config/routes/routes_name.dart';
import 'package:reservation_workshop/core/components/toasters.dart';
import 'package:reservation_workshop/core/network/local/cache_helper.dart';
import 'package:reservation_workshop/core/utils/strings/prefkeys.dart';
import 'package:reservation_workshop/modules/branch/domain/entities/branch.dart';
import 'package:reservation_workshop/modules/branch/presentation/cubits/branch_cubit/branch_cubit.dart';
import 'package:reservation_workshop/modules/branch/presentation/cubits/branch_cubit/branch_state.dart';
import 'package:reservation_workshop/modules/customer/domain/entities/customer_car.dart';
import 'package:reservation_workshop/modules/customer/presentation/cubits/customer_info_cubit/customer_info_cubit.dart';
import 'package:reservation_workshop/modules/customer/presentation/cubits/customer_info_cubit/customer_info_state.dart';
import 'package:reservation_workshop/modules/home/presentation/widgets/home_bottom_navigation_bar.dart';
import 'package:reservation_workshop/modules/menu/presentation/cubits/business_location_cubit/business_location_cubit.dart'
    show BusinessLocationCubit;
import 'package:reservation_workshop/modules/service/domain/entities/service.dart';
import 'package:reservation_workshop/modules/service/presentation/cubits/service_cubit/service_cubit.dart';
import 'package:reservation_workshop/modules/service/presentation/cubits/service_cubit/service_state.dart';
import 'package:reservation_workshop/modules/main/presentation/widgets/booking_dropdown_field.dart';
import 'package:reservation_workshop/modules/main/presentation/widgets/date_time_field.dart';
import 'package:reservation_workshop/modules/main/presentation/widgets/notes_field.dart';
import 'package:reservation_workshop/modules/main/presentation/widgets/submit_booking_button.dart';
import 'package:reservation_workshop/modules/main/presentation/screens/booking_details_args.dart';
import 'package:reservation_workshop/modules/main/presentation/widgets/notification_card.dart';
import 'package:reservation_workshop/core/widgets/app_card.dart';
import 'package:reservation_workshop/config/style/app_spacing.dart';
import 'package:reservation_workshop/modules/menu/presentation/widgets/menu_drawer.dart';
import 'package:reservation_workshop/modules/notifications/presentation/cubit/maintenance_notifications_cubit.dart';
import 'package:reservation_workshop/modules/notifications/presentation/widgets/notification_unread_badge.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  int? _selectedBranchId;
  int? _selectedCarId;
  int? _selectedServiceId;
  DateTime _selectedDateTime = DateTime.now();
  final TextEditingController _notesController = TextEditingController();

  int _selectedBottomIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadSelectedCar();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<CustomerInfoCubit>().load();
      context.read<BranchCubit>().load();
      context.read<MaintenanceNotificationsCubit>().refresh();
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
    return MultiBlocListener(
      listeners: [
        BlocListener<CustomerInfoCubit, CustomerInfoState>(
          listener: (context, state) async {
            if (state is CustomerInfoSuccess) {
              final cars = state.info.cars;
              if (cars.isEmpty) return;

              final cachedId = _selectedCarId;
              final exists =
                  cachedId != null && cars.any((c) => c.id == cachedId);
              if (!exists) {
                final first = cars.first;
                setState(() => _selectedCarId = first.id);
                await _persistSelectedCar(first);
              }
            }
          },
        ),
        BlocListener<BranchCubit, BranchState>(
          listener: (context, state) {
            if (state is BranchError) {
              Toasters.errorFrom(state.message);
            }
          },
        ),
        BlocListener<ServiceCubit, ServiceState>(
          listener: (context, state) {
            if (state is ServiceError) {
              Toasters.errorFrom(state.message);
            }
          },
        ),
      ],
      child: Scaffold(
        key: _scaffoldKey,
        extendBody: false,
        drawer: BlocProvider<BusinessLocationCubit>(
          create: (_) => BusinessLocationCubit()..fetchBusinessLocation(),
          child: const MenuDrawer(),
        ),
        bottomNavigationBar: HomeBottomNavigationBar(
          selectedIndex: _selectedBottomIndex,
          onItemTapped: (index, route, arguments) {
            setState(() => _selectedBottomIndex = index);
            if (arguments != null) {
              Navigator.pushNamed(context, route, arguments: arguments);
            } else {
              Navigator.pushNamed(context, route);
            }
          },
        ),
        body: Container(
          decoration: const BoxDecoration(color: Colors.black),
          child: SafeArea(
            child: BlocBuilder<CustomerInfoCubit, CustomerInfoState>(
              builder: (context, state) {
                final customerName = state is CustomerInfoSuccess
                    ? state.info.name
                    : '';
                final cars = state is CustomerInfoSuccess
                    ? state.info.cars
                    : const <CustomerCar>[];

                return Column(
                  children: [
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return CustomScrollView(
                            slivers: [
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    12,
                                    16,
                                    0,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      GestureDetector(
                                        onTap: () => _scaffoldKey.currentState
                                            ?.openDrawer(),
                                        child: Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: const Color(
                                              0xFFD4AF37,
                                            ).withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            border: Border.all(
                                              color: const Color(
                                                0xFFD4AF37,
                                              ).withOpacity(0.4),
                                              width: 1.2,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.menu,
                                            color: Color(0xFFD4AF37),
                                            size: 20,
                                          ),
                                        ),
                                      ),
                                      Image.asset(
                                        'assets/images/logo.png',
                                        height: 100,
                                      ),
                                      GestureDetector(
                                        onTap: () => Navigator.pushNamed(
                                          context,
                                          RoutesName.notificationsScreen,
                                        ),
                                        child: Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: const Color(
                                              0xFFD4AF37,
                                            ).withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            border: Border.all(
                                              color: const Color(
                                                0xFFD4AF37,
                                              ).withOpacity(0.4),
                                              width: 1.2,
                                            ),
                                          ),
                                          child: const Center(
                                            child: NotificationUnreadBadge(
                                              child: Icon(
                                                Icons.notifications_outlined,
                                                color: Color(0xFFD4AF37),
                                                size: 20,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SliverPadding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  16,
                                  16,
                                  0,
                                ),
                                sliver: SliverToBoxAdapter(
                                  child: Center(
                                    child: ConstrainedBox(
                                      constraints: const BoxConstraints(
                                        maxWidth: 420,
                                      ),
                                      child: AppCard(
                                        padding: const EdgeInsets.all(16),
                                        borderRadius: 18,
                                        backgroundColor: const Color(
                                          0xFF050505,
                                        ),
                                        borderColor: const Color(
                                          0xFFD4AF37,
                                        ).withOpacity(0.25),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(
                                              0xFFD4AF37,
                                            ).withOpacity(0.15),
                                            blurRadius: 20,
                                            offset: const Offset(0, 8),
                                          ),
                                        ],
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            Text(
                                              customerName.trim().isEmpty
                                                  ? 'booking.greeting'.tr()
                                                  : 'booking.greeting_named'.tr(
                                                      args: [customerName],
                                                    ),
                                              style: textTheme.titleSmall
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w800,
                                                    color: Colors.white,
                                                  ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'booking.subtitle'.tr(),
                                              style: textTheme.bodySmall
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w500,
                                                    color: Colors.white
                                                        .withOpacity(0.6),
                                                  ),
                                            ),
                                            const SizedBox(
                                              height: AppSpacing.lg,
                                            ),
                                            BookingDropdownField<int>(
                                              label: 'booking.car'.tr(),
                                              value: _selectedCarId,
                                              items: cars
                                                  .map(
                                                    (c) =>
                                                        DropdownMenuItem<int>(
                                                          value: c.id,
                                                          child: Text(
                                                            _carLabel(c),
                                                          ),
                                                        ),
                                                  )
                                                  .toList(),
                                              onChanged: (id) async {
                                                if (id == null) return;
                                                final car = cars
                                                    .where((e) => e.id == id)
                                                    .toList();
                                                if (car.isEmpty) return;

                                                setState(
                                                  () => _selectedCarId = id,
                                                );
                                                await _persistSelectedCar(
                                                  car.first,
                                                );
                                              },
                                            ),
                                            const SizedBox(
                                              height: AppSpacing.lg,
                                            ),
                                            BlocBuilder<
                                              BranchCubit,
                                              BranchState
                                            >(
                                              builder: (context, branchState) {
                                                final branches =
                                                    branchState is BranchSuccess
                                                    ? branchState.branches
                                                    : const <Branch>[];

                                                return BookingDropdownField<
                                                  int
                                                >(
                                                  label: 'booking.select_branch'
                                                      .tr(),
                                                  isRequired: true,
                                                  value: _selectedBranchId,
                                                  items: branches
                                                      .map(
                                                        (b) =>
                                                            DropdownMenuItem<
                                                              int
                                                            >(
                                                              value: b.id,
                                                              child: Text(
                                                                b.name,
                                                              ),
                                                            ),
                                                      )
                                                      .toList(),
                                                  onChanged: (id) {
                                                    setState(() {
                                                      _selectedBranchId = id;
                                                      _selectedServiceId = null;
                                                    });

                                                    if (id == null) {
                                                      context
                                                          .read<ServiceCubit>()
                                                          .clear();
                                                      return;
                                                    }
                                                    context
                                                        .read<ServiceCubit>()
                                                        .load(locationId: id);
                                                  },
                                                );
                                              },
                                            ),
                                            const SizedBox(
                                              height: AppSpacing.lg,
                                            ),
                                            if (_selectedBranchId != null)
                                              BlocBuilder<
                                                ServiceCubit,
                                                ServiceState
                                              >(
                                                builder: (context, serviceState) {
                                                  final services =
                                                      serviceState
                                                          is ServiceSuccess
                                                      ? serviceState.services
                                                      : const <Service>[];

                                                  return Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          Text(
                                                            'booking.select_service'
                                                                .tr(),
                                                            style: textTheme
                                                                .bodySmall
                                                                ?.copyWith(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                  color: Colors
                                                                      .white,
                                                                ),
                                                          ),
                                                          const SizedBox(
                                                            width: 4,
                                                          ),
                                                          const Text(
                                                            '*',
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700,
                                                              color:
                                                                  const Color(
                                                                    0xFFD4AF37,
                                                                  ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(
                                                        height: AppSpacing.md,
                                                      ),
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
                                                              (
                                                                s,
                                                              ) => _ServiceCard(
                                                                title: s.name,
                                                                selected:
                                                                    _selectedServiceId ==
                                                                    s.id,
                                                                onTap: () => setState(
                                                                  () =>
                                                                      _selectedServiceId =
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
                                            const SizedBox(
                                              height: AppSpacing.lg,
                                            ),
                                            DateTimeField(
                                              label: 'booking.select_datetime'
                                                  .tr(),
                                              valueText: _formatDateTime(
                                                _selectedDateTime,
                                              ),
                                              onPick: _pickDateTime,
                                            ),
                                            const SizedBox(
                                              height: AppSpacing.lg,
                                            ),
                                            NotesField(
                                              hintText:
                                                  'booking.describe_problem'
                                                      .tr(),
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
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    0,
                                    16,
                                    16,
                                  ),
                                  child: Center(
                                    child: ConstrainedBox(
                                      constraints: const BoxConstraints(
                                        maxWidth: 420,
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          const SizedBox(height: AppSpacing.lg),
                                          SubmitBookingButton(
                                            onPressed: () {
                                              final carId = _selectedCarId;
                                              final branchId =
                                                  _selectedBranchId;
                                              final serviceId =
                                                  _selectedServiceId;

                                              if (carId == null) {
                                                Toasters.errorKey(
                                                  'booking.toast_select_car',
                                                );
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
                                              final customerName =
                                                  customerState
                                                      is CustomerInfoSuccess
                                                  ? customerState.info.name
                                                  : '';
                                              final customerPhone =
                                                  customerState
                                                      is CustomerInfoSuccess
                                                  ? customerState.info.mobile
                                                  : '';
                                              final cars =
                                                  customerState
                                                      is CustomerInfoSuccess
                                                  ? customerState.info.cars
                                                  : const <CustomerCar>[];
                                              final selectedCar = cars
                                                  .where((c) => c.id == carId)
                                                  .toList();

                                              final branchState = context
                                                  .read<BranchCubit>()
                                                  .state;
                                              final branches =
                                                  branchState is BranchSuccess
                                                  ? branchState.branches
                                                  : const <Branch>[];
                                              final selectedBranch = branches
                                                  .where(
                                                    (b) => b.id == branchId,
                                                  )
                                                  .toList();

                                              final serviceState = context
                                                  .read<ServiceCubit>()
                                                  .state;
                                              final services =
                                                  serviceState is ServiceSuccess
                                                  ? serviceState.services
                                                  : const <Service>[];
                                              final selectedService = services
                                                  .where(
                                                    (s) => s.id == serviceId,
                                                  )
                                                  .toList();

                                              final note = _notesController.text
                                                  .trim();
                                              final bookingStart =
                                                  _formatBookingStart(
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
                                                    ? ((selectedCar
                                                                      .first
                                                                      .plateNumber ??
                                                                  '')
                                                              .trim()
                                                              .isEmpty
                                                          ? '-'
                                                          : selectedCar
                                                                .first
                                                                .plateNumber!
                                                                .trim())
                                                    : '-',
                                                status: '-',
                                                dateTime: bookingStart,
                                                service:
                                                    selectedService.isNotEmpty
                                                    ? selectedService.first.name
                                                    : '-',
                                                branch:
                                                    selectedBranch.isNotEmpty
                                                    ? selectedBranch.first.name
                                                    : '-',
                                                area: note.isEmpty ? '-' : note,
                                                name: customerName,
                                                phone: customerPhone,
                                              );

                                              final args = BookingDetailsArgs(
                                                model: model,
                                                bookingStart: bookingStart,
                                                locationId: branchId,
                                                serviceId: serviceId,
                                                deviceId: carId,
                                                bookingNote: note,
                                              );

                                              Navigator.pushNamed(
                                                context,
                                                RoutesName.bookingDetailsScreen,
                                                arguments: args,
                                              );
                                            },
                                          ),
                                          const SizedBox(height: AppSpacing.sm),
                                          Text(
                                            'booking.can_edit_before_confirm'
                                                .tr(),
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.white.withOpacity(
                                                0.5,
                                              ),
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
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
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
              color: selected ? Colors.black : Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
