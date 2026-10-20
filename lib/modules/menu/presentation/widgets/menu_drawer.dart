import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:reservation_workshop/core/components/toasters.dart';
import 'dart:ui' as ui;
import 'package:url_launcher/url_launcher.dart';

import 'package:reservation_workshop/modules/menu/data/datasources/social_media_remote_datasource.dart';
import 'package:reservation_workshop/modules/menu/data/models/social_media_model.dart';

import 'package:reservation_workshop/constants/app_constants.dart';
import 'package:reservation_workshop/config/routes/routes_name.dart';
import 'package:reservation_workshop/core/network/local/cache_helper.dart';
import 'package:reservation_workshop/core/utils/strings/prefkeys.dart';
import 'package:reservation_workshop/modules/customer/domain/entities/customer_car.dart';
import 'package:reservation_workshop/modules/customer/presentation/cubits/customer_info_cubit/customer_info_cubit.dart';
import 'package:reservation_workshop/modules/customer/presentation/cubits/customer_info_cubit/customer_info_state.dart';

class MenuDrawer extends StatefulWidget {
  const MenuDrawer({super.key});

  @override
  State<MenuDrawer> createState() => _MenuDrawerState();
}

class _MenuDrawerState extends State<MenuDrawer> {
  int? _selectedCarId;
  String? _selectedCarLabel;
  bool _isGuest = false;
  List<SocialMediaItemModel> _socialItems = const [];
  bool _socialLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGuestMode();
    _loadSelectedCar();
    _loadSocialMedia();
  }

  Future<void> _loadSocialMedia() async {
    try {
      final items = await SocialMediaRemoteDataSource().getSocialMedia();
      if (!mounted) return;
      setState(() {
        _socialItems = items;
        _socialLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _socialItems = const [];
        _socialLoading = false;
      });
    }
  }

  Future<void> _loadGuestMode() async {
    final isGuest =
        await CacheHelper.getDataAsync<bool>(key: PrefKeys.kIsGuestMode) ??
        false;
    if (!mounted) return;
    setState(() {
      _isGuest = isGuest;
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

  void _goToLogin() {
    Navigator.of(context).maybePop();
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(RoutesName.enterMobileScreen, (route) => false);
  }

  Future<void> _guardGuest(VoidCallback action) async {
    if (_isGuest) {
      if (!mounted) return;
      _goToLogin();
      return;
    }
    action();
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
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return SafeArea(
          top: false,
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFF050505),
              borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
            ),
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
                            color: Colors.white,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close, color: Colors.white),
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
                                  ? const Color(0xFFD4AF37).withOpacity(0.15)
                                  : const Color(0xFF050505),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFFD4AF37)
                                    : Colors.white.withOpacity(0.08),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFFD4AF37,
                                    ).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(
                                    Icons.directions_car_filled_outlined,
                                    color: Color(0xFFD4AF37),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${car.device} ${car.model}'.trim(),
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        (car.plateNumber ?? '').trim().isEmpty
                                            ? car.carType
                                            : (car.plateNumber ?? '').trim(),
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white.withOpacity(0.6),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(
                                    Icons.check_circle,
                                    color: Color(0xFFD4AF37),
                                  )
                                else
                                  Icon(
                                    Icons.chevron_left,
                                    color: Colors.white.withOpacity(0.4),
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

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isRtl = context.locale.languageCode == 'ar';
    return SizedBox(
      width: width * 0.92,
      child: Drawer(
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        child: SafeArea(
          child: Directionality(
            textDirection: isRtl ? ui.TextDirection.rtl : ui.TextDirection.ltr,
            child: Container(
              color: Colors.black,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 62,
                          height: 62,
                          decoration: BoxDecoration(
                            color: const Color(0xFF21262D),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.08),
                            ),
                          ),
                          child: Icon(
                            Icons.person_outline,
                            size: 34,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child:
                                        BlocBuilder<
                                          CustomerInfoCubit,
                                          CustomerInfoState
                                        >(
                                          builder: (context, state) {
                                            String name;
                                            if (_isGuest) {
                                              name = 'common.guest'.tr();
                                            } else if (state
                                                is CustomerInfoSuccess) {
                                              name = state.info.name.trim();
                                              if (name.isEmpty)
                                                name = 'menu.user'.tr();
                                            } else {
                                              name = 'menu.user'.tr();
                                            }
                                            return Text(
                                              name,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w800,
                                                    fontSize: 18,
                                                    color: Colors.white,
                                                  ),
                                            );
                                          },
                                        ),
                                  ),
                                  const SizedBox(width: 10),
                                  InkWell(
                                    onTap: () async {
                                      final current =
                                          context.locale.languageCode;
                                      final next = current == 'ar'
                                          ? 'en'
                                          : 'ar';
                                      await CacheHelper.saveData(
                                        key: PrefKeys.kLocaleCode,
                                        value: next,
                                      );
                                      if (!context.mounted) return;
                                      context.setLocale(Locale(next));
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 4,
                                      ),
                                      child: Text(
                                        isRtl ? 'En' : 'العربية',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color: Colors.white.withOpacity(
                                                0.8,
                                              ),
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              BlocBuilder<CustomerInfoCubit, CustomerInfoState>(
                                builder: (context, state) {
                                  final cars = state is CustomerInfoSuccess
                                      ? state.info.cars
                                      : const <CustomerCar>[];
                                  final selectedFromList =
                                      _selectedCarId != null
                                      ? cars
                                            .where(
                                              (c) => c.id == _selectedCarId,
                                            )
                                            .toList()
                                      : const <CustomerCar>[];
                                  final cachedLabel = (_selectedCarLabel ?? '')
                                      .trim();
                                  final selectedCarLabel =
                                      selectedFromList.isNotEmpty
                                      ? _carLabel(selectedFromList.first)
                                      : cachedLabel;

                                  return InkWell(
                                    onTap: _isGuest
                                        ? _goToLogin
                                        : () => _openCarPicker(cars: cars),
                                    borderRadius: BorderRadius.circular(12),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 2,
                                        vertical: 2,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            _isGuest
                                                ? Icons.login
                                                : Icons
                                                      .directions_car_filled_outlined,
                                            size: 16,
                                            color: Colors.white.withOpacity(
                                              0.5,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Flexible(
                                            child: Text(
                                              _isGuest
                                                  ? 'menu.please_login'.tr()
                                                  : selectedCarLabel.isEmpty
                                                  ? 'home.select_car'.tr()
                                                  : selectedCarLabel,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.copyWith(
                                                    color: Colors.white
                                                        .withOpacity(0.6),
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Icon(
                                            _isGuest
                                                ? Icons.chevron_right
                                                : Icons.keyboard_arrow_down,
                                            size: 18,
                                            color: Colors.white.withOpacity(
                                              0.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: Colors.white.withOpacity(0.1)),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
                      children: [
                        _MenuItem(
                          title: 'menu.about_vag'.tr(),
                          icon: Icons.location_on_outlined,
                          onTap: () =>
                              _go(context, RoutesName.menuAboutSkodaScreen),
                        ),

                        _MenuItem(
                          title: 'menu.add_booking'.tr(),
                          icon: Icons.add_circle_outline,
                          onTap: () {
                            Navigator.of(context).maybePop();
                            Navigator.of(
                              context,
                            ).pushNamed(RoutesName.mainScreen, arguments: 2);
                          },
                        ),
                        _MenuItem(
                          title: 'menu.maintenance'.tr(),
                          icon: Icons.build_outlined,
                          onTap: () {
                            Navigator.of(context).maybePop();
                            Navigator.of(
                              context,
                            ).pushNamed(RoutesName.mainScreen, arguments: 1);
                          },
                        ),
                        _MenuItem(
                          title: 'menu.estimator_request'.tr(),
                          icon: Icons.receipt_long_outlined,
                          onTap: () {
                            Navigator.of(context).maybePop();
                            Navigator.of(
                              context,
                            ).pushNamed(RoutesName.mainScreen, arguments: 0);
                          },
                        ),
                        _MenuItem(
                          title: 'menu.invoices'.tr(),
                          icon: Icons.receipt_outlined,
                          onTap: () {
                            Navigator.of(context).maybePop();
                            Navigator.of(
                              context,
                            ).pushNamed(RoutesName.mainScreen, arguments: 3);
                          },
                        ),
                        const SizedBox(height: 8),

                        _MenuItem(
                          title: 'menu.rescue'.tr(),
                          icon: Icons.support_agent,
                          onTap: () =>
                              _go(context, RoutesName.menuRescueScreen),
                        ),
                        _MenuItem(
                          title: 'menu.contact'.tr(),
                          icon: Icons.headphones,
                          onTap: () =>
                              _go(context, RoutesName.menuContactScreen),
                        ),

                        _MenuItem(
                          title: 'menu.points'.tr(),
                          icon: Icons.workspace_premium_outlined,
                          onTap: () => _guardGuest(
                            () => _go(
                              context,
                              RoutesName.menuLoyaltyPointsScreen,
                            ),
                          ),
                        ),
                        if (_isGuest)
                          _MenuItem(
                            title: 'auth.login_button'.tr(),
                            icon: Icons.login,
                            onTap: _goToLogin,
                          )
                        else
                          _MenuItem(
                            title: 'menu.logout'.tr(),
                            icon: Icons.logout,
                            onTap: () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (ctx) {
                                  return AlertDialog(
                                    title: Text('menu.logout_title'.tr()),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(ctx).pop(false),
                                        child: Text('menu.no'.tr()),
                                      ),
                                      ElevatedButton(
                                        onPressed: () =>
                                            Navigator.of(ctx).pop(true),
                                        child: Text('menu.yes'.tr()),
                                      ),
                                    ],
                                  );
                                },
                              );
                              if (confirmed == true) {
                                AppConstants.token = null;
                                await CacheHelper.clearSession();
                                Navigator.of(context).pushNamedAndRemoveUntil(
                                  RoutesName.loginScreen,
                                  (route) => false,
                                );
                              }
                            },
                          ),
                        const SizedBox(height: 12),
                        if (_socialLoading || _socialItems.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: Wrap(
                              spacing: 4,
                              runSpacing: 4,
                              alignment: WrapAlignment.center,
                              children: _socialLoading
                                  ? List.generate(
                                      4,
                                      (_) => const _SocialCircle(
                                        icon: Icons.public,
                                        isLoading: true,
                                      ),
                                    )
                                  : _socialItems
                                        .map(
                                          (item) => _SocialIconCircle(
                                            item: item,
                                            onTap: () => _launchUrl(item.link),
                                          ),
                                        )
                                        .toList(),
                            ),
                          ),
                        const SizedBox(height: 18),
                        Center(
                          child: Text(
                            'menu.app_version'.tr(args: const ['1.0.0']),
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.4),
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
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

  static void _go(BuildContext context, String route) {
    Navigator.of(context).maybePop();
    Navigator.of(context).pushNamed(route);
  }

  Future<void> _launchUrl(String url) async {
    final raw = url.trim();
    debugPrint('🚀 _launchUrl called with: "$raw"');
    if (raw.isEmpty) {
      debugPrint('❌ URL is empty');
      return;
    }

    Uri uri;
    try {
      uri = Uri.parse(raw);
    } catch (e) {
      debugPrint('❌ Failed to parse URL: $e');
      if (mounted) Toasters.errorKey('common.cannot_open');
      return;
    }

    // Normalize URLs - add https if no scheme
    if (uri.scheme.isEmpty && !raw.startsWith('tel:')) {
      uri = Uri.parse('https://$raw');
      debugPrint('🌐 Converted to HTTPS URI: $uri');
    }

    // Launch URLs (not phone numbers)
    bool launched = false;
    try {
      debugPrint('🚀 Launching URL: $uri');
      launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        // Fallback to platformDefault
        debugPrint('🔄 Trying fallback with platformDefault');
        launched = await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      debugPrint('❌ Exception during launch: $e');
      launched = false;
    }

    debugPrint('✅ Launch result: $launched');
    if (!launched && mounted) {
      Toasters.errorKey('common.cannot_open');
    }
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF21262D),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                  ),
                  child: Icon(icon, size: 22, color: const Color(0xFFD4AF37)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
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
  }
}

class _SocialIconCircle extends StatelessWidget {
  const _SocialIconCircle({required this.item, this.onTap});

  final SocialMediaItemModel item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: item.name,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(19),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFF050505),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: item.iconUrl.trim().isEmpty
                ? Icon(
                    Icons.public,
                    size: 18,
                    color: Colors.white.withOpacity(0.7),
                  )
                : Image.network(
                    item.iconUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return Center(
                        child: SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white.withOpacity(0.5),
                          ),
                        ),
                      );
                    },
                    errorBuilder: (_, _, _) => Icon(
                      Icons.public,
                      size: 18,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _SocialCircle extends StatelessWidget {
  const _SocialCircle({required this.icon, this.isLoading = false});

  final IconData icon;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: const Color(0xFF050505),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: isLoading
          ? Center(
              child: SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white.withOpacity(0.5),
                ),
              ),
            )
          : Icon(icon, size: 18, color: Colors.white.withOpacity(0.3)),
    );
  }
}
