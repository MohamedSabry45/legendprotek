import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'dart:ui' as ui;
import 'package:reservation_workshop/config/style/app_colors.dart';
import 'package:reservation_workshop/config/routes/routes_name.dart';
import 'package:reservation_workshop/core/network/local/cache_helper.dart';
import 'package:reservation_workshop/core/utils/strings/prefkeys.dart';
import 'package:reservation_workshop/modules/customer/domain/entities/customer_car.dart';
import 'package:reservation_workshop/modules/home/presentation/widgets/home_bottom_navigation_bar.dart';
import 'package:reservation_workshop/modules/main/presentation/tabs/booking_tab_view.dart';
import 'package:reservation_workshop/modules/main/presentation/tabs/estimators_tab_view.dart';
import 'package:reservation_workshop/modules/main/presentation/tabs/invoices_tab_view.dart';
import 'package:reservation_workshop/modules/main/presentation/tabs/maintenance_tab_view.dart';
import 'package:reservation_workshop/modules/menu/presentation/cubits/business_location_cubit/business_location_cubit.dart' show BusinessLocationCubit;
import 'package:reservation_workshop/modules/menu/presentation/widgets/menu_drawer.dart';
import 'package:reservation_workshop/modules/notifications/presentation/widgets/notification_unread_badge.dart';
import 'package:reservation_workshop/modules/branch/presentation/cubits/branch_cubit/branch_cubit.dart';
import 'package:reservation_workshop/modules/customer/presentation/cubits/customer_info_cubit/customer_info_cubit.dart';
import 'package:reservation_workshop/modules/customer/presentation/cubits/customer_info_cubit/customer_info_state.dart';
import 'package:reservation_workshop/modules/job_estimators/presentation/cubits/create_job_estimator_cubit/create_job_estimator_cubit.dart';
import 'package:reservation_workshop/modules/job_estimators/presentation/cubits/job_estimators_cubit.dart';
import 'package:reservation_workshop/modules/job_estimators/presentation/widgets/create_job_estimator_dialog.dart';
import 'package:reservation_workshop/modules/service/presentation/cubits/service_cubit/service_cubit.dart';

class RequestsTabsScreen extends StatefulWidget {
  const RequestsTabsScreen({super.key});

  @override
  State<RequestsTabsScreen> createState() => _RequestsTabsScreenState();
}

class _RequestsTabsScreenState extends State<RequestsTabsScreen> with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  late TabController _tabController;
  bool _controllerInitialized = false;
  bool _customerLoaded = false;

  int? _selectedCarId;

  int _selectedBottomIndex = 2;

  String _carLabel(CustomerCar car) {
    final plate = (car.plateNumber ?? '').trim();
    return '${car.device} ${car.model} ${plate.isEmpty ? '' : plate}'.trim();
  }

  Future<void> _persistSelectedCar(CustomerCar car) async {
    await CacheHelper.saveData(key: PrefKeys.kSelectedCarId, value: car.id);
    await CacheHelper.saveData(key: PrefKeys.kSelectedCarLabel, value: _carLabel(car));
    await CacheHelper.saveData(key: PrefKeys.kSelectedCarLogo, value: (car.carLogo ?? '').trim());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    const int tabCount = 4;

    if (_controllerInitialized && _tabController.length != tabCount) {
      _tabController.dispose();
      _controllerInitialized = false;
    }

    if (!_controllerInitialized) {
      final int initialIndex = (ModalRoute.of(context)?.settings.arguments as int?) ?? 2;
      _tabController = TabController(
        length: tabCount,
        vsync: this,
        initialIndex: initialIndex.clamp(0, tabCount - 1),
      );
      _tabController.addListener(() {
        if (!mounted) return;
        setState(() {});
      });
      _controllerInitialized = true;
    }

    if (!_customerLoaded) {
      _customerLoaded = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<CustomerInfoCubit>().load();
      });
    }

    CacheHelper.getDataAsync<int>(key: PrefKeys.kSelectedCarId).then((carId) {
      if (!mounted) return;
      if (carId != _selectedCarId) {
        setState(() => _selectedCarId = carId);
      }
    });

  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _openCreateEstimatorDialog() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final existingBranchCubit = context.read<BranchCubit>();
        final existingCustomerCubit = context.read<CustomerInfoCubit>();
        final existingServiceCubit = context.read<ServiceCubit>();
        return MultiBlocProvider(
          providers: [
            BlocProvider.value(value: existingBranchCubit),
            BlocProvider.value(value: existingCustomerCubit),
            BlocProvider.value(value: existingServiceCubit),
            BlocProvider<CreateJobEstimatorCubit>(create: (_) => CreateJobEstimatorCubit()),
          ],
          child: CreateJobEstimatorDialog(
            onCreated: () {
              final s = existingCustomerCubit.state;
              if (s is CustomerInfoSuccess) {
                context.read<JobEstimatorsCubit>().load(customerId: s.info.id);
              }
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final isEstimatorsTab = _controllerInitialized && _tabController.index == 0;
    return Directionality(
      textDirection: context.locale.languageCode == 'ar' ? ui.TextDirection.rtl : ui.TextDirection.ltr,
      child: BlocListener<CustomerInfoCubit, CustomerInfoState>(
        listener: (context, state) async {
          if (state is CustomerInfoSuccess) {
            final cars = state.info.cars;
            if (cars.isEmpty) return;

            final cachedId = _selectedCarId;
            final exists = cachedId != null && cars.any((c) => c.id == cachedId);
            if (!exists) {
              final first = cars.first;
              setState(() => _selectedCarId = first.id);
              await _persistSelectedCar(first);
            }
          }
        },
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
            decoration: const BoxDecoration(
              color: Colors.black,
            ),
            child: SafeArea(
              top: true,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () => _scaffoldKey.currentState?.openDrawer(),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFFD4AF37).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xFFD4AF37).withOpacity(0.4),
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
                          onTap: () => Navigator.pushNamed(context, RoutesName.notificationsScreen),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFFD4AF37).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xFFD4AF37).withOpacity(0.4),
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
                  Padding(
                    padding: const EdgeInsets.only(top: 12, left: 16, right: 16),
                    child: Container(
                      height: 44,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A0A0A),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.3)),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        indicator: BoxDecoration(
                          color: const Color(0xFFD4AF37),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFD4AF37).withOpacity(0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        labelColor: Colors.white,
                        unselectedLabelColor: Colors.white.withOpacity(0.6),
                        dividerColor: Colors.transparent,
                        indicatorSize: TabBarIndicatorSize.tab,
                        labelStyle: textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                        ),
                        unselectedLabelStyle: textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                          color: Colors.white.withOpacity(0.6),
                        ),
                        tabs: [
                          Tab(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text('tabs.estimator_request'.tr(), maxLines: 1),
                            ),
                          ),
                          Tab(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text('tabs.maintenance'.tr(), maxLines: 1),
                            ),
                          ),
                          Tab(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text('tabs.booking'.tr(), maxLines: 1),
                            ),
                          ),
                          Tab(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text('tabs.invoice'.tr(), maxLines: 1),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: const [
                        EstimatorsTabView(),
                        MaintenanceTabView(),
                        BookingTabView(),
                        InvoicesTabView(),
                      ],
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
