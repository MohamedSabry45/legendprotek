import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'dart:ui' as ui;
import 'package:reservation_workshop/config/routes/routes_name.dart';
import 'package:reservation_workshop/core/network/local/cache_helper.dart';
import 'package:reservation_workshop/core/utils/strings/prefkeys.dart';
import 'package:reservation_workshop/modules/customer/domain/entities/customer_car.dart';
import 'package:reservation_workshop/modules/customer/presentation/cubits/customer_info_cubit/customer_info_cubit.dart';
import 'package:reservation_workshop/modules/customer/presentation/cubits/customer_info_cubit/customer_info_state.dart';
import 'package:reservation_workshop/modules/menu/presentation/widgets/menu_drawer.dart';
import 'package:reservation_workshop/modules/menu/presentation/cubits/business_location_cubit/business_location_cubit.dart';
import 'package:reservation_workshop/modules/notifications/presentation/widgets/notification_unread_badge.dart';
import 'package:reservation_workshop/modules/home/presentation/cubit/blog_cubit.dart';
import '../widgets/home_bottom_navigation_bar.dart';
import '../widgets/home_hero_section.dart';
import '../widgets/home_philosophy_section.dart';
import '../widgets/home_services_header_section.dart';
import '../widgets/home_service_cards_section.dart';
import '../widgets/home_fleet_section.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _scrollController = ScrollController();

  int _selectedBottomIndex = 0;
  int? _selectedCarId;
  String? _selectedCarLabel;
  bool _isGuest = false;
  bool _customerInfoRequested = false;
  Locale? _locale;

  @override
  void initState() {
    super.initState();
    _loadGuestMode();
    _loadSelectedCar();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = context.locale;
    final localeChanged = _locale != null && _locale != locale;
    _locale = locale;
    if (!_customerInfoRequested || localeChanged) {
      _customerInfoRequested = true;
      context.read<CustomerInfoCubit>().load();
    }
    if (localeChanged) {
      context.read<BlogCubit>().loadFirst(localeCode: locale.languageCode);
    }
  }

  Future<void> _loadGuestMode() async {
    final isGuest =
        await CacheHelper.getDataAsync<bool>(key: PrefKeys.kIsGuestMode) ??
        false;
    if (!mounted) return;
    setState(() => _isGuest = isGuest);
  }

  Future<void> _loadSelectedCar() async {
    final id = await CacheHelper.getDataAsync<int>(
      key: PrefKeys.kSelectedCarId,
    );
    final label = await CacheHelper.getDataAsync<String>(
      key: PrefKeys.kSelectedCarLabel,
    );
    if (!mounted) return;
    setState(() {
      _selectedCarId = id;
      _selectedCarLabel = label?.trim();
    });
  }

  String _carLabel(CustomerCar car) {
    final plate = (car.plateNumber ?? '').trim();
    return '${car.device} ${car.model} ${plate.isEmpty ? '' : plate}'.trim();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < 600;

    return Directionality(
      textDirection: context.locale.languageCode == 'ar'
          ? ui.TextDirection.rtl
          : ui.TextDirection.ltr,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: Colors.black,
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
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              // Hero Section
              SliverToBoxAdapter(
                child: Stack(
                  children: [
                    BlocBuilder<CustomerInfoCubit, CustomerInfoState>(
                      builder: (context, state) {
                        String name = '';
                        if (!_isGuest && state is CustomerInfoSuccess) {
                          name = state.info.name.trim();
                        }
                        final greeting = _isGuest
                            ? 'home.greeting_guest'.tr()
                            : (name.isNotEmpty
                                  ? 'home.greeting_named'.tr(args: [name])
                                  : 'home.greeting'.tr());

                        final List<CustomerCar> cars =
                            state is CustomerInfoSuccess
                            ? List<CustomerCar>.from(state.info.cars)
                            : <CustomerCar>[];
                        CustomerCar? selectedCar;
                        if (cars.isNotEmpty) {
                          if (_selectedCarId != null) {
                            for (final car in cars) {
                              if (car.id == _selectedCarId) {
                                selectedCar = car;
                                break;
                              }
                            }
                          }
                          selectedCar ??= cars.first;
                        }

                        String carLabel;
                        if (selectedCar != null) {
                          carLabel = _carLabel(selectedCar);
                        } else {
                          carLabel = (_selectedCarLabel ?? '').isNotEmpty
                              ? _selectedCarLabel!
                              : 'home.select_car'.tr();
                        }

                        return HomeHeroSection(
                          scrollController: _scrollController,
                          greeting: greeting,
                          carLabel: carLabel,
                          cars: cars,
                          selectedCarId: _selectedCarId,
                          onCarSelected: (carId) async {
                            setState(() => _selectedCarId = carId);
                            if (carId != null) {
                              final car = cars.firstWhere((c) => c.id == carId);
                              final label = _carLabel(car);
                              await CacheHelper.saveData(
                                key: PrefKeys.kSelectedCarId,
                                value: carId,
                              );
                              await CacheHelper.saveData(
                                key: PrefKeys.kSelectedCarLabel,
                                value: label,
                              );
                              setState(() => _selectedCarLabel = label);
                            }
                          },
                        );
                      },
                    ),
                    // App Bar with menu only
                    Positioned(
                      top: isMobile ? 48 : 56,
                      left: 12,
                      right: 12,
                      child: Container(
                        height: isMobile ? 85 : 90,
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 16 : 24,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF050505).withOpacity(0.92),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: const Color(0xFFD4AF37).withOpacity(0.35),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.35),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Image.asset(
                              'assets/images/logoappbar.png',
                              height: isMobile ? 75 : 85,
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: () => Navigator.pushNamed(
                                context,
                                RoutesName.notificationsScreen,
                              ),
                              child: Container(
                                width: isMobile ? 44 : 52,
                                height: isMobile ? 44 : 52,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: const Color(
                                    0xFFD4AF37,
                                  ).withOpacity(0.15),
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
                                      size: 24,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            GestureDetector(
                              onTap: () =>
                                  _scaffoldKey.currentState?.openDrawer(),
                              child: Container(
                                width: isMobile ? 44 : 52,
                                height: isMobile ? 44 : 52,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: const Color(
                                    0xFFD4AF37,
                                  ).withOpacity(0.15),
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
                                  size: 24,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Our Philosophy Section
              const SliverToBoxAdapter(child: HomePhilosophySection()),
              // Our Services Header Section
              const SliverToBoxAdapter(child: HomeServicesHeaderSection()),
              // Service Cards Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: const HomeServiceCardsSection(),
                ),
              ),
              // Fleet Section
              const SliverToBoxAdapter(child: HomeFleetSection()),
            ],
          ),
        ),
      ),
    );
  }
}
