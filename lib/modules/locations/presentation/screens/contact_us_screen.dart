import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:easy_localization/easy_localization.dart';
import 'dart:ui' as ui;

import 'package:reservation_workshop/config/style/app_spacing.dart';
import 'package:reservation_workshop/core/components/toasters.dart';

import '../../domain/entities/business_location.dart';
import '../cubit/business_locations_cubit.dart';
import '../cubit/business_locations_state.dart';

class ContactUsScreen extends StatefulWidget {
  const ContactUsScreen({super.key});

  @override
  State<ContactUsScreen> createState() => _ContactUsScreenState();
}

class _ContactUsScreenState extends State<ContactUsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<BusinessLocationsCubit>().load();
    });
  }

  Future<void> _callPhone(String phone) async {
    final p = phone.trim();
    if (p.isEmpty) {
      Toasters.errorKey('contact_us.phone_unavailable');
      return;
    }

    final uri = Uri.parse('tel:$p');
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) {
      Toasters.errorKey('contact_us.open_phone_failed');
    }
  }

  Future<void> _copyPhone(String phone) async {
    final p = phone.trim();
    if (p.isEmpty) {
      Toasters.errorKey('contact_us.phone_unavailable');
      return;
    }

    await Clipboard.setData(ClipboardData(text: p));
    Toasters.successKey('contact_us.phone_copied');
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
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            'contact_us.title'.tr(),
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          foregroundColor: Colors.white,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: SafeArea(
          child: BlocConsumer<BusinessLocationsCubit, BusinessLocationsState>(
            listener: (context, state) {
              if (state is BusinessLocationsError) {
                Toasters.errorFrom(state.message);
              }
            },
            builder: (context, state) {
              if (state is BusinessLocationsLoading) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFF050505),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFFD4AF37),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'contact_us.loading_branches'.tr(),
                        style: textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              }

              if (state is BusinessLocationsError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xxl),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: const Color(0xFF050505),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.error_outline,
                            size: 40,
                            color: const Color(0xFFD4AF37),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'contact_us.load_failed_title'.tr(),
                          textAlign: TextAlign.center,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'contact_us.load_failed_subtitle'.tr(),
                          textAlign: TextAlign.center,
                          style: textTheme.bodyMedium?.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final items = state is BusinessLocationsSuccess
                  ? state.locations
                  : const <BusinessLocation>[];

              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                children: [
                  // Hero Section with red theme
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          const Color(0xFFD4AF37),
                          const Color(0xFFB8942E),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFD4AF37).withOpacity(0.25),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Icon(
                            Icons.support_agent_rounded,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'contact_us.hero_title'.tr(),
                                style: textTheme.titleLarge?.copyWith(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'contact_us.hero_subtitle'.tr(),
                                style: textTheme.bodyMedium?.copyWith(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withOpacity(0.9),
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Section Header with count
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 24,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD4AF37),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'contact_us.section_branches'.tr(),
                        style: textTheme.titleLarge?.copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      if (items.isNotEmpty) ...[
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD4AF37).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFD4AF37).withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            '${items.length}',
                            style: textTheme.bodySmall?.copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFD4AF37),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Text(
                      'contact_us.section_branches_subtitle'.tr(),
                      style: textTheme.bodyMedium?.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  if (items.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 60),
                        child: Column(
                          children: [
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: const Color(0xFF050505),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.store_mall_directory_outlined,
                                size: 48,
                                color: Colors.grey.shade500,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'contact_us.empty_title'.tr(),
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'contact_us.empty_subtitle'.tr(),
                              style: textTheme.bodyMedium?.copyWith(
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ...items.asMap().entries.map(
                      (entry) => Padding(
                        padding: EdgeInsets.only(
                          bottom: entry.key < items.length - 1 ? 16 : 0,
                        ),
                        child: _ContactLocationCard(
                          item: entry.value,
                          onCall: () => _callPhone(entry.value.mobile),
                          onCopy: () => _copyPhone(entry.value.mobile),
                          onMap: () => _openMap(entry.value),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ContactLocationCard extends StatelessWidget {
  const _ContactLocationCard({
    required this.item,
    required this.onCall,
    required this.onCopy,
    required this.onMap,
  });

  final BusinessLocation item;
  final VoidCallback onCall;
  final VoidCallback onCopy;
  final VoidCallback onMap;

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

    return parts.isEmpty
        ? 'contact_us.address_unavailable'.tr()
        : parts.join(' • ');
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final phone = item.mobile.trim();
    final hasPhone = phone.isNotEmpty;
    final hasMap = item.latitude != null && item.longitude != null;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF050505),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF0A0A0A), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section with gradient
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF050505),
                gradient: LinearGradient(
                  colors: [const Color(0xFF050505), const Color(0xFF0A0A0A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          const Color(0xFFD4AF37),
                          const Color(0xFFB8942E),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFD4AF37).withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.store_mall_directory_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.titleLarge?.copyWith(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            gradient: hasMap
                                ? const LinearGradient(
                                    colors: [
                                      Color(0xFFDCFCE7),
                                      Color(0xFFD1FAE5),
                                    ],
                                  )
                                : null,
                            color: hasMap ? null : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: hasMap
                                  ? const Color(0xFF10B981).withOpacity(0.2)
                                  : const Color(0xFFCBD5E1),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                hasMap ? Icons.check_circle : Icons.cancel,
                                size: 14,
                                color: hasMap
                                    ? const Color(0xFF10B981)
                                    : Colors.grey.shade600,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                hasMap
                                    ? 'locations.map_available'.tr()
                                    : 'locations.no_location'.tr(),
                                style: textTheme.bodySmall?.copyWith(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: hasMap
                                      ? const Color(0xFF10B981)
                                      : Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Content Section
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Location Info
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF050505),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF0A0A0A)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF050505),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.location_on_rounded,
                            color: const Color(0xFFD4AF37),
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _subtitle(),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.bodyMedium?.copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Phone Info
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF050505),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF0A0A0A)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF050505),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.phone_rounded,
                            size: 18,
                            color: hasPhone
                                ? const Color(0xFFD4AF37)
                                : Colors.grey.shade500,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            hasPhone
                                ? phone
                                : 'contact_us.phone_unavailable_label'.tr(),
                            style: textTheme.bodyMedium?.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: hasPhone
                                  ? Colors.white
                                  : Colors.grey.shade500,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: _ActionButton(
                          onPressed: hasPhone ? onCall : null,
                          icon: Icons.phone_rounded,
                          label: 'contact_us.call'.tr(),
                          isPrimary: true,
                          isEnabled: hasPhone,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ActionButton(
                          onPressed: hasPhone ? onCopy : null,
                          icon: Icons.content_copy_rounded,
                          label: 'contact_us.copy'.tr(),
                          isPrimary: false,
                          isEnabled: hasPhone,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ActionButton(
                          onPressed: hasMap ? onMap : null,
                          icon: Icons.map_rounded,
                          label: 'contact_us.map'.tr(),
                          isPrimary: false,
                          isEnabled: hasMap,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.isPrimary,
    required this.isEnabled,
  });

  final VoidCallback? onPressed;
  final IconData icon;
  final String label;
  final bool isPrimary;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          decoration: BoxDecoration(
            gradient: isPrimary && isEnabled
                ? const LinearGradient(
                    colors: [const Color(0xFFD4AF37), Color(0xFFB91C1C)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isPrimary && isEnabled
                ? null
                : isEnabled
                ? const Color(0xFF050505)
                : const Color(0xFF0A0A0A),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isPrimary && isEnabled
                  ? Colors.transparent
                  : isEnabled
                  ? const Color(0xFFD4AF37).withOpacity(0.3)
                  : const Color(0xFF0A0A0A),
              width: 1.5,
            ),
            boxShadow: isPrimary && isEnabled
                ? [
                    BoxShadow(
                      color: const Color(0xFFD4AF37).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20,
                color: isPrimary && isEnabled
                    ? Colors.white
                    : isEnabled
                    ? const Color(0xFFD4AF37)
                    : Colors.grey.shade600,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: textTheme.bodySmall?.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isPrimary && isEnabled
                      ? Colors.white
                      : isEnabled
                      ? Colors.white
                      : Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
