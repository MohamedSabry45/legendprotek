import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:reservation_workshop/config/style/app_colors.dart';
import 'package:reservation_workshop/core/components/toasters.dart';

import '../cubit/vehicle_details_cubit.dart';
import '../cubit/vehicle_details_state.dart';
import '../widgets/vehicle_details/vehicle_badges.dart';
import '../widgets/vehicle_details/vehicle_description_section.dart';
import '../widgets/vehicle_details/vehicle_gallery.dart';
import '../widgets/vehicle_details/vehicle_seller_card.dart';
import '../widgets/vehicle_details/vehicle_specs_grid.dart';
import '../widgets/vehicle_details/vehicle_inquiry_dialog.dart';

class VehicleDetailsScreen extends StatelessWidget {
  final int vehicleId;

  const VehicleDetailsScreen({super.key, required this.vehicleId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<VehicleDetailsCubit>(
      create: (_) => VehicleDetailsCubit(id: vehicleId)..load(),
      child: const _VehicleDetailsView(),
    );
  }
}

class _VehicleDetailsView extends StatelessWidget {
  const _VehicleDetailsView();

  void _showInquiryDialog(BuildContext context, int vehicleId) {
    showDialog(
      context: context,
      builder: (context) => VehicleInquiryDialog(vehicleId: vehicleId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: BlocBuilder<VehicleDetailsCubit, VehicleDetailsState>(
          builder: (context, state) {
            if (state is VehicleDetailsLoading ||
                state is VehicleDetailsInitial) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.brandPrimary),
              );
            }

            if (state is VehicleDetailsError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.wifi_off,
                        color: Colors.white70,
                        size: 44,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'buy_car.loading_error'.tr(),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        Toasters.displayMessage(state.message),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 14),
                      FilledButton(
                        onPressed: () =>
                            context.read<VehicleDetailsCubit>().load(),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.brandPrimary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text('buy_car.retry'.tr()),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (state is VehicleDetailsSuccess) {
              final d = state.details;
              final media = d.media;

              return Column(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(24),
                    ),
                    child: AspectRatio(
                      aspectRatio: 16 / 10,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          VehicleGallery(media: media),
                          Positioned(
                            top: 12,
                            left: 12,
                            child: _TopNavButton(
                              icon: Icons.arrow_back,
                              onTap: () => Navigator.of(context).maybePop(),
                            ),
                          ),
                          Positioned(
                            top: 12,
                            right: 12,
                            child: Row(
                              children: [
                                _TopNavButton(
                                  icon: Icons.share_outlined,
                                  onTap: () {},
                                ),
                                const SizedBox(width: 10),
                                _TopNavButton(
                                  icon: d.isFavorited
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  onTap: () {},
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            left: 12,
                            right: 12,
                            bottom: 12,
                            child: VehicleBadges(
                              isPremium: d.isPremium,
                              isFeatured: d.isFeatured,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${d.make} ${d.modelName} ${d.year}',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 18,
                              color: Colors.white70,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                [
                                  d.locationCity,
                                  d.locationArea,
                                ].where((e) => e.trim().isNotEmpty).join(', '),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white70,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF050505),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: const Color(0xFF0A0A0A)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${d.listingPrice} ${d.currency}',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.brandPrimary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              if (d.minPrice.trim().isNotEmpty)
                                Text(
                                  'Min: ${d.minPrice} ${d.currency}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.grey7,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        VehicleSpecsGrid(
                          items: buildSpecs(
                            mileageKm: d.mileageKm,
                            transmission: d.transmission,
                            fuelType: d.fuelType,
                            engineCapacityCc: d.engineCapacityCc,
                            cylinderCount: d.cylinderCount,
                            condition: d.condition,
                            factoryPaint: d.factoryPaint,
                            importedSpecs: d.importedSpecs,
                          ),
                        ),
                        const SizedBox(height: 12),
                        VehicleDescriptionSection(
                          description: d.description,
                          conditionNotes: d.conditionNotes,
                        ),
                        const SizedBox(height: 12),
                        if (d.seller != null)
                          VehicleSellerCard(seller: d.seller!),
                        const SizedBox(height: 14),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(4),
                          child: _ActionButton(
                            icon: Icons.handshake,
                            label: 'buy_car.make_offer'.tr(),
                            onTap: () => _showInquiryDialog(context, d.id),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _ActionButton(
                                icon: Icons.chat,
                                label: 'buy_car.whatsapp'.tr(),
                                onTap: () async {
                                  final mobile = d.seller?.mobile;
                                  if (mobile != null &&
                                      mobile.trim().isNotEmpty) {
                                    final whatsappUrl = Uri.parse(
                                      'https://wa.me/$mobile',
                                    );
                                    final ok = await launchUrl(
                                      whatsappUrl,
                                      mode: LaunchMode.externalApplication,
                                    );
                                    if (!ok && context.mounted) {
                                      Toasters.errorKey(
                                        'buy_car.whatsapp_failed',
                                      );
                                    }
                                  } else if (context.mounted) {
                                    Toasters.errorKey('buy_car.no_phone');
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _ActionButton(
                                icon: Icons.call,
                                label: 'buy_car.call'.tr(),
                                onTap: () async {
                                  final mobile = d.seller?.mobile;
                                  if (mobile != null &&
                                      mobile.trim().isNotEmpty) {
                                    final phoneUrl = Uri.parse('tel:$mobile');
                                    final ok = await launchUrl(
                                      phoneUrl,
                                      mode: LaunchMode.externalApplication,
                                    );
                                    if (!ok && context.mounted) {
                                      Toasters.errorKey('buy_car.call_failed');
                                    }
                                  } else if (context.mounted) {
                                    Toasters.errorKey('buy_car.no_phone');
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

class _TopNavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _TopNavButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF050505).withOpacity(0.92),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, color: AppColors.brandDark),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF050505),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Ink(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF0A0A0A)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: AppColors.brandDark),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: AppColors.brandDark,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
