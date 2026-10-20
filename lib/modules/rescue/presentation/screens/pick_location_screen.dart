import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:reservation_workshop/config/style/app_colors.dart';
import 'package:reservation_workshop/config/style/app_spacing.dart';
import 'package:reservation_workshop/core/components/toasters.dart';

class PickedLocation {
  final double latitude;
  final double longitude;

  const PickedLocation({required this.latitude, required this.longitude});
}

class PickLocationScreen extends StatefulWidget {
  const PickLocationScreen({
    super.key,
    required this.initialLatitude,
    required this.initialLongitude,
  });

  final double? initialLatitude;
  final double? initialLongitude;

  @override
  State<PickLocationScreen> createState() => _PickLocationScreenState();
}

class _PickLocationScreenState extends State<PickLocationScreen> {
  final MapController _mapController = MapController();
  LatLng _selected = const LatLng(30.0444, 31.2357);
  bool _loadingLocation = false;
  bool _loadingAddress = false;
  String? _address;
  int _addressRequestId = 0;

  @override
  void initState() {
    super.initState();
    final lat = widget.initialLatitude;
    final lng = widget.initialLongitude;
    if (lat != null && lng != null) {
      _selected = LatLng(lat, lng);
    }
    _resolveAddress(_selected);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _goToMyLocation();
    });
  }

  Future<void> _resolveAddress(LatLng point) async {
    final requestId = ++_addressRequestId;
    setState(() => _loadingAddress = true);
    try {
      final placemarks = await geo.Geocoding().placemarkFromCoordinates(
        point.latitude,
        point.longitude,
      );
      if (!mounted || requestId != _addressRequestId) return;
      final p = placemarks.isEmpty ? null : placemarks.first;
      final parts = <String>[
        p?.street ?? '',
        p?.subLocality ?? '',
        p?.locality ?? '',
        p?.administrativeArea ?? '',
        p?.country ?? '',
      ]
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toSet()
          .toList();
      setState(() {
        _address = parts.isEmpty ? null : parts.join('، ');
        _loadingAddress = false;
      });
    } catch (_) {
      if (!mounted || requestId != _addressRequestId) return;
      setState(() {
        _address = null;
        _loadingAddress = false;
      });
    }
  }

  Future<void> _goToMyLocation() async {
    setState(() => _loadingLocation = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showError('locations.enable_services'.tr());
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _showError('locations.permission_denied'.tr());
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (!mounted) return;
      final latLng = LatLng(pos.latitude, pos.longitude);

      setState(() => _selected = latLng);
      _mapController.move(latLng, 16);
      _resolveAddress(latLng);
    } catch (_) {
      _showError('locations.detect_failed'.tr());
    } finally {
      if (mounted) setState(() => _loadingLocation = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    Toasters.error(message);
  }

  void _confirm() {
    Navigator.pop(
      context,
      PickedLocation(
        latitude: _selected.latitude,
        longitude: _selected.longitude,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('locations.pick_title'.tr()),
        actions: [
          TextButton(onPressed: _confirm, child: Text('common.confirm'.tr())),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _selected,
              initialZoom: 13,
              onTap: (tapPosition, point) {
                setState(() => _selected = point);
                _resolveAddress(point);
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'reservation_workshop',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _selected,
                    width: 46,
                    height: 46,
                    child: const Icon(
                      Icons.location_on,
                      color: const Color(0xFFD4AF37),
                      size: 40,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE6E8EC)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 22,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _loadingAddress
                            ? Row(
                                children: [
                                  const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'locations.loading_address'.tr(),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Text(
                                _address ??
                                    'Lat: ${_selected.latitude.toStringAsFixed(6)}\nLng: ${_selected.longitude.toStringAsFixed(6)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87,
                                  height: 1.2,
                                ),
                              ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      SizedBox(
                        height: 42,
                        child: OutlinedButton.icon(
                          onPressed: _loadingLocation ? null : _goToMyLocation,
                          icon: _loadingLocation
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.my_location, size: 18),
                          label: Text('locations.my_location'.tr()),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ElevatedButton.icon(
                    onPressed: _confirm,
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: Text('locations.confirm_location'.tr()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brandPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            right: 16,
            top: 16,
            child: FloatingActionButton(
              mini: true,
              heroTag: 'location_pin',
              onPressed: _loadingLocation ? null : _goToMyLocation,
              backgroundColor: Colors.white,
              child: _loadingLocation
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(
                      Icons.location_on,
                      color: const Color(0xFFD4AF37),
                      size: 24,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
