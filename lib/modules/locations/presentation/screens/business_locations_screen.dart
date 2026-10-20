import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:easy_localization/easy_localization.dart';
import 'dart:ui' as ui;

import 'package:reservation_workshop/config/style/app_colors.dart';
import 'package:reservation_workshop/config/style/app_spacing.dart';
import 'package:reservation_workshop/core/components/toasters.dart';
import 'package:reservation_workshop/core/widgets/app_header.dart';

import '../../domain/entities/business_location.dart';
import '../cubit/business_locations_cubit.dart';
import '../cubit/business_locations_state.dart';

class BusinessLocationsScreen extends StatefulWidget {
  const BusinessLocationsScreen({super.key});

  @override
  State<BusinessLocationsScreen> createState() =>
      _BusinessLocationsScreenState();
}

class _BusinessLocationsScreenState extends State<BusinessLocationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<BusinessLocationsCubit>().load();
    });
  }

  Future<void> _openMap(BusinessLocation location) async {
    final lat = location.latitude;
    final lng = location.longitude;

    if (lat == null || lng == null) {
      Toasters.errorKey('locations.no_map_for_branch');
      return;
    }

    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );

    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) {
      Toasters.errorKey('locations.open_map_failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isAr = context.locale.languageCode == 'ar';

    return Directionality(
      textDirection: isAr ? ui.TextDirection.rtl : ui.TextDirection.ltr,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.black, Color(0xFF050505), Color(0xFF0A0A0A)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                AppHeader(
                  title: 'locations.select_branch'.tr(),
                  onBack: () => Navigator.pop(context),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, AppSpacing.lg),
                  child: Row(
                    children: [
                      Expanded(
                        child:
                            BlocBuilder<
                              BusinessLocationsCubit,
                              BusinessLocationsState
                            >(
                              builder: (context, state) {
                                final count = state is BusinessLocationsSuccess
                                    ? state.locations.length
                                    : 0;
                                return Text(
                                  'locations.nearest_branch'.tr(
                                    args: [count.toString()],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style:
                                      (textTheme.bodySmall ?? const TextStyle())
                                          .copyWith(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white70,
                                          ),
                                );
                              },
                            ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      _MapButton(
                        onTap: () {
                          final state = context
                              .read<BusinessLocationsCubit>()
                              .state;
                          if (state is BusinessLocationsSuccess &&
                              state.locations.isNotEmpty) {
                            _openMap(state.locations.first);
                          }
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child:
                      BlocConsumer<
                        BusinessLocationsCubit,
                        BusinessLocationsState
                      >(
                        listener: (context, state) {
                          if (state is BusinessLocationsError) {
                            Toasters.errorFrom(state.message);
                          }
                        },
                        builder: (context, state) {
                          if (state is BusinessLocationsLoading) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          if (state is BusinessLocationsError) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(AppSpacing.xxl),
                                child: Text(
                                  'locations.load_failed'.tr(),
                                  textAlign: TextAlign.center,
                                  style:
                                      (textTheme.bodyMedium ??
                                              const TextStyle())
                                          .copyWith(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.grey7,
                                          ),
                                ),
                              ),
                            );
                          }

                          final items = state is BusinessLocationsSuccess
                              ? state.locations
                              : const <BusinessLocation>[];

                          if (items.isEmpty) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(AppSpacing.xxl),
                                child: Text(
                                  'locations.empty'.tr(),
                                  textAlign: TextAlign.center,
                                  style:
                                      (textTheme.bodyMedium ??
                                              const TextStyle())
                                          .copyWith(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.grey7,
                                          ),
                                ),
                              ),
                            );
                          }

                          return ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                            itemCount: items.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: AppSpacing.md),
                            itemBuilder: (context, index) {
                              final item = items[index];
                              return _LocationCard(
                                item: item,
                                onTap: () => _openMap(item),
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
      ),
    );
  }
}

class _MapButton extends StatelessWidget {
  const _MapButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.location_on_outlined, size: 18),
        label: Text(
          'locations.view_map'.tr(),
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
        ),
      ),
    );
  }
}

class _LocationCard extends StatelessWidget {
  const _LocationCard({required this.item, required this.onTap});

  final BusinessLocation item;
  final VoidCallback onTap;

  String _subtitle() {
    final parts = <String>[];
    final city = item.city.trim();
    final state = item.state.trim();
    final country = item.country.trim();
    final landmark = (item.landmark ?? '').trim();

    if (city.isNotEmpty) parts.add(city);
    if (state.isNotEmpty) parts.add(state);
    if (country.isNotEmpty) parts.add(country);
    if (landmark.isNotEmpty) parts.add(landmark);

    return parts.isEmpty ? '-' : parts.join(' - ');
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final hasMap = item.latitude != null && item.longitude != null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: const Color(0xFF050505),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFF0A0A0A)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0F000000),
                blurRadius: 18,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: AppColors.brandPrimarySoft,
                  borderRadius: BorderRadius.all(Radius.circular(14)),
                ),
                child: const Icon(
                  Icons.store_mall_directory_outlined,
                  color: AppColors.brandPrimary,
                  size: 28,
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: (textTheme.titleMedium ?? const TextStyle())
                                .copyWith(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  height: 1.1,
                                ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: hasMap
                                ? const Color(0xFF050505)
                                : const Color(0xFF0A0A0A),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            hasMap
                                ? 'locations.map_available'.tr()
                                : 'locations.no_location'.tr(),
                            style: (textTheme.bodySmall ?? const TextStyle())
                                .copyWith(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: hasMap
                                      ? const Color(0xFF0A0A0A)
                                      : Colors.white70,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 16,
                          color: Colors.black54,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            _subtitle(),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: (textTheme.bodyMedium ?? const TextStyle())
                                .copyWith(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.grey7,
                                  height: 1.2,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        const Icon(Icons.call, size: 16, color: Colors.black54),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          item.mobile.trim().isEmpty ? '-' : item.mobile.trim(),
                          style: (textTheme.bodyMedium ?? const TextStyle())
                              .copyWith(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: Colors.white70,
                                height: 1.1,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              const Icon(
                Icons.arrow_back_ios_new,
                size: 16,
                color: Colors.white70,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
