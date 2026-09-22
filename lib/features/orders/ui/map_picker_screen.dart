import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/theme/tokens.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/feedback.dart';
import '../../../l10n/app_localizations.dart';
import '../../catalog/catalog_providers.dart';
import '../orders_providers.dart';

class PickedPlace {
  const PickedPlace(this.point, this.address);
  final LatLng point;
  final String? address;
}

/// Xaritadan manzil: markazdagi pin ostida xarita suriladi (Yandex Go kabi).
class MapPickerScreen extends ConsumerStatefulWidget {
  const MapPickerScreen({super.key, this.initial});
  final LatLng? initial;

  @override
  ConsumerState<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends ConsumerState<MapPickerScreen> {
  static const _tashkent = LatLng(41.311081, 69.240562);
  final _map = MapController();
  late LatLng _center = widget.initial ?? _tashkent;
  String? _address;
  bool _moving = false;
  bool _locating = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _lookup();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _lookup() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () async {
      final p = _center;
      final a = await ref.read(orderRepositoryProvider).reverseGeocode(p.latitude, p.longitude, ref.read(langProvider));
      if (mounted && p == _center) setState(() => _address = a);
    });
  }

  Future<void> _myLocation() async {
    final s = S.of(context);
    setState(() => _locating = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        if (mounted) showSnack(context, s.locationOff, icon: Icons.location_off_outlined);
        return;
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        if (mounted) showSnack(context, s.locationDenied, icon: Icons.location_off_outlined);
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 12)),
      );
      final p = LatLng(pos.latitude, pos.longitude);
      _map.move(p, 17);
      setState(() {
        _center = p;
        _address = null;
      });
      _lookup();
    } catch (_) {
      if (mounted) showSnack(context, s.locationFailed, icon: Icons.location_off_outlined);
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _map,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: widget.initial == null ? 12 : 17,
              interactionOptions: const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
              onPositionChanged: (cam, hasGesture) {
                if (!hasGesture) return;
                setState(() {
                  _center = cam.center;
                  _moving = true;
                  _address = null;
                });
              },
              onMapEvent: (e) {
                if (e is MapEventMoveEnd || e is MapEventFlingAnimationEnd || e is MapEventDoubleTapZoomEnd) {
                  if (_moving) {
                    HapticFeedback.selectionClick();
                    setState(() => _moving = false);
                    _lookup();
                  }
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'uz.climavent.app',
                maxZoom: 19,
              ),
              const RichAttributionWidget(
                alignment: AttributionAlignment.bottomLeft,
                attributions: [TextSourceAttribution('© OpenStreetMap')],
              ),
            ],
          ),
          // Markazdagi pin — ko'tarilib-tushadi.
          IgnorePointer(
            child: Center(
              child: AnimatedSlide(
                duration: const Duration(milliseconds: 160),
                offset: Offset(0, _moving ? -0.72 : -0.5),
                child: const Icon(Icons.location_on_rounded, size: 52, color: Brand.flame),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(Space.md),
              child: Row(
                children: [
                  const CircleBackButton(),
                  const Spacer(),
                  Material(
                    color: c.surface,
                    shape: CircleBorder(side: BorderSide(color: c.border)),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _locating ? null : _myLocation,
                      child: SizedBox(
                        width: 44,
                        height: 44,
                        child: _locating
                            ? const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2))
                            : Icon(Icons.my_location_rounded, color: c.textPrimary, size: 22),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(Space.gutter, Space.lg, Space.gutter, Space.md + MediaQuery.paddingOf(context).bottom),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(Radii.xl)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.deliveryAddress, style: context.text.bodySmall),
            const SizedBox(height: 4),
            SizedBox(
              height: 48,
              child: Align(
                alignment: Alignment.centerLeft,
                child: _moving || _address == null
                    ? Text(_moving ? s.mapMoving : s.mapLoadingAddress,
                        style: context.text.titleMedium?.copyWith(color: c.textTertiary))
                    : Text(_address!, maxLines: 2, overflow: TextOverflow.ellipsis, style: context.text.titleMedium),
              ),
            ),
            const SizedBox(height: Space.md),
            PrimaryButton(
              label: s.mapConfirm,
              onPressed: _moving ? null : () => Navigator.pop(context, PickedPlace(_center, _address)),
            ),
          ],
        ),
      ),
    );
  }
}
