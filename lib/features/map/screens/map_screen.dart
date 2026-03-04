import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/app_localizations.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _mapController = MapController();
  double _radiusKm = 10;
  double _currentZoom =
      11; // synced from map so clustering works on first frame
  bool _locationBlur = true;
  bool _activeNowOnly = false;
  bool _locationPermissionGranted = false;
  bool _hasSeenPermissionEducation = false;
  static final _center = LatLng(51.5074, -0.1278); // London

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
  }

  Future<void> _checkLocationPermission() async {
    // Placeholder: in production use permission_handler
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() {
        _locationPermissionGranted = false; // show education for demo
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final accent = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l.navMap,
          style: AppTypography.headlineSmall.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(_locationBlur ? Icons.blur_on : Icons.blur_off),
            onPressed: () => setState(() => _locationBlur = !_locationBlur),
            tooltip: l.locationBlur,
          ),
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: () => _showMapFilters(context),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: 11,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
              onPositionChanged: (position, hasGesture) {
                if (position.zoom != _currentZoom && mounted) {
                  setState(() => _currentZoom = position.zoom);
                }
              },
              onTap: (_, __) {
                // Tap on map (not pin) — close any open preview
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.dvtechventures.saathi',
              ),
              CircleLayer(
                circles: [
                  CircleMarker(
                    point: _center,
                    radius: _radiusKm * 120,
                    color: accent.withValues(alpha: 0.15),
                    borderColor: accent.withValues(alpha: 0.5),
                    borderStrokeWidth: 2,
                  ),
                ],
              ),
              // Week 16 — Clustered pins (simplified: show cluster when zoom < 12)
              MarkerLayer(markers: _buildMarkers(accent)),
            ],
          ),
          // Week 16 — Location permission education
          if (!_locationPermissionGranted && !_hasSeenPermissionEducation)
            _LocationPermissionBanner(
              accent: accent,
              onDismiss: () =>
                  setState(() => _hasSeenPermissionEducation = true),
              onEnable: () async {
                setState(() {
                  _hasSeenPermissionEducation = true;
                  _locationPermissionGranted = true;
                });
              },
            ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 24,
            child: Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Radius: ${_radiusKm.toStringAsFixed(0)} km',
                      style: AppTypography.labelLarge.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Slider(
                      value: _radiusKm,
                      min: 2,
                      max: 50,
                      divisions: 24,
                      activeColor: accent,
                      onChanged: (v) => setState(() => _radiusKm = v),
                    ),
                    Row(
                      children: [
                        FilterChip(
                          label: Text(l.activeNow),
                          selected: _activeNowOnly,
                          onSelected: (v) => setState(() => _activeNowOnly = v),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Privacy: ${_locationBlur ? "Blurred" : "Precise"}',
                          style: AppTypography.caption.copyWith(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Marker> _buildMarkers(Color accent) {
    final zoom = _currentZoom;
    final showClusters = zoom < 12 && _mockPins.length > 2;
    if (showClusters) {
      // Week 16 — Simple cluster: one marker with count
      return [
        Marker(
          point: _center,
          width: 56,
          height: 56,
          child: _ClusterPin(accent: accent, count: _mockPins.length),
        ),
      ];
    }
    return _mockPins.map((p) {
      return Marker(
        point: p.position,
        width: 42,
        height: 42,
        child: GestureDetector(
          onTap: () => _showProfilePreview(context, p),
          child: _locationBlur
              ? _BlurredPin(accent: accent)
              : _ProfilePin(accent: accent, label: p.name, age: p.age),
        ),
      );
    }).toList();
  }

  void _showProfilePreview(BuildContext context, _MapPin pin) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _MapProfilePreviewSheet(
        pin: pin,
        onViewFullProfile: () {
          Navigator.pop(ctx);
          context.push('/profile/${pin.profileId}');
        },
        onSendIntro: () {
          Navigator.pop(ctx);
          context.push('/paywall');
        },
        onClose: () => Navigator.pop(ctx),
      ),
    );
  }

  void _showMapFilters(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l.mapFilters, style: AppTypography.headlineSmall),
              const SizedBox(height: 16),
              ListTile(
                title: Text(l.activeNowOnly),
                subtitle: Text(l.activeNowOnlySubtitle),
              ),
              ListTile(
                title: Text(l.locationBlur),
                subtitle: Text(l.locationBlurSubtitle),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(l.done),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Week 16 — Tap pin → profile preview bottom sheet.
class _MapProfilePreviewSheet extends StatelessWidget {
  const _MapProfilePreviewSheet({
    required this.pin,
    required this.onViewFullProfile,
    required this.onSendIntro,
    required this.onClose,
  });
  final _MapPin pin;
  final VoidCallback onViewFullProfile;
  final VoidCallback onSendIntro;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: accent.withValues(alpha: 0.2),
                    child: Text(
                      pin.name.isNotEmpty ? pin.name[0].toUpperCase() : '?',
                      style: AppTypography.headlineMedium.copyWith(
                        color: accent,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${pin.name}, ${pin.age}',
                          style: AppTypography.titleLarge,
                        ),
                        if (pin.distanceKm != null)
                          Text(
                            '${pin.distanceKm!.toStringAsFixed(1)} km away',
                            style: AppTypography.bodySmall,
                          ),
                      ],
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.close), onPressed: onClose),
                ],
              ),
              if (pin.bio.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  pin.bio,
                  style: AppTypography.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: onViewFullProfile,
                icon: const Icon(Icons.person_outline, size: 18),
                label: Text(AppLocalizations.of(context)!.viewFullProfile),
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: onSendIntro,
                icon: const Icon(Icons.send, size: 18),
                label: Text(AppLocalizations.of(context)!.ctaSendIntro),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Week 16 — Location permission education banner.
class _LocationPermissionBanner extends StatelessWidget {
  const _LocationPermissionBanner({
    required this.accent,
    required this.onDismiss,
    required this.onEnable,
  });
  final Color accent;
  final VoidCallback onDismiss;
  final VoidCallback onEnable;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 16,
      right: 16,
      top: 16,
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: accent.withValues(alpha: 0.5)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.location_on, color: accent, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Enable location to see people near you',
                      style: AppTypography.labelLarge,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: onDismiss,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'We only use your location to show relevant matches. You can blur your exact position.',
                style: AppTypography.bodySmall,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  TextButton(
                    onPressed: onDismiss,
                    child: Text(AppLocalizations.of(context)!.notNow),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: onEnable,
                    child: Text(AppLocalizations.of(context)!.enable),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BlurredPin extends StatelessWidget {
  const _BlurredPin({required this.accent});
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.6),
        shape: BoxShape.circle,
        border: Border.all(color: accent, width: 2),
      ),
      child: const Icon(Icons.person, color: Colors.white, size: 24),
    );
  }
}

class _ProfilePin extends StatelessWidget {
  const _ProfilePin({required this.accent, required this.label, this.age});
  final Color accent;
  final String label;
  final int? age;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 20,
      backgroundColor: accent,
      child: Text(
        label.isNotEmpty ? label[0].toUpperCase() : '?',
        style: AppTypography.labelMedium.copyWith(color: Colors.white),
      ),
    );
  }
}

/// Week 16 — Cluster pin (zoom out: show count).
class _ClusterPin extends StatelessWidget {
  const _ClusterPin({required this.accent, required this.count});
  final Color accent;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.9),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          count > 99 ? '99+' : '$count',
          style: AppTypography.labelLarge.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _MapPin {
  _MapPin({
    required this.profileId,
    required this.position,
    required this.name,
    this.age,
    this.distanceKm,
    this.bio = '',
  });
  final String profileId;
  final LatLng position;
  final String name;
  final int? age;
  final double? distanceKm;
  final String bio;
}

final List<_MapPin> _mockPins = [
  _MapPin(
    profileId: '1',
    position: LatLng(51.5074, -0.1278),
    name: 'Priya',
    age: 28,
    distanceKm: 2.1,
    bio: 'Product designer. Chai over chaos.',
  ),
  _MapPin(
    profileId: '2',
    position: LatLng(51.52, -0.14),
    name: 'Ananya',
    age: 26,
    distanceKm: 4.2,
    bio: 'Software engineer. Bharatanatyam dancer. Chai and deep talks.',
  ),
  _MapPin(
    profileId: '3',
    position: LatLng(51.50, -0.11),
    name: 'Meera',
    age: 30,
    distanceKm: 5.0,
    bio: 'Finance. Yoga, hiking, new cuisines.',
  ),
  _MapPin(
    profileId: '4',
    position: LatLng(51.51, -0.13),
    name: 'Riya',
    age: 25,
    distanceKm: 3.2,
    bio: 'Content creator. Brunch, long walks, sunsets.',
  ),
  _MapPin(
    profileId: '5',
    position: LatLng(51.49, -0.12),
    name: 'Kavya',
    age: 27,
    distanceKm: 6.1,
    bio: 'Doctor. Family, friends, good food.',
  ),
];
