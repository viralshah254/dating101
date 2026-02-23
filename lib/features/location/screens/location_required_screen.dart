import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/location/app_location_service.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/app_localizations.dart';

/// Shown when the app requires location permission. User must allow to continue.
/// [then] query param = path to go to after permission is granted (e.g. /profile-setup, /).
class LocationRequiredScreen extends StatefulWidget {
  const LocationRequiredScreen({
    super.key,
    this.thenPath = '/',
  });

  final String thenPath;

  @override
  State<LocationRequiredScreen> createState() => _LocationRequiredScreenState();
}

class _LocationRequiredScreenState extends State<LocationRequiredScreen> {
  final _locationService = AppLocationService.instance;
  bool _isRequesting = false;
  String? _error;

  Future<void> _checkAndRedirect() async {
    final access = await _locationService.checkAccess();
    if (access == LocationAccess.granted && mounted) {
      context.go(widget.thenPath);
    }
  }

  /// When screen appears, if permission isn't granted yet, automatically
  /// trigger the system "Allow location?" dialog so the user doesn't have to tap.
  Future<void> _autoRequestLocation() async {
    final access = await _locationService.checkAccess();
    if (!mounted) return;
    if (access == LocationAccess.granted) {
      context.go(widget.thenPath);
      return;
    }
    // Automatically show the system permission prompt
    await _onAllow();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoRequestLocation();
    });
  }

  Future<void> _onAllow() async {
    setState(() {
      _isRequesting = true;
      _error = null;
    });

    final access = await _locationService.requestPermission();

    if (!mounted) return;
    setState(() => _isRequesting = false);

    switch (access) {
      case LocationAccess.granted:
        context.go(widget.thenPath);
        break;
      case LocationAccess.serviceDisabled:
        setState(() => _error = AppLocalizations.of(context)!.locationServiceDisabled);
        break;
      case LocationAccess.deniedForever:
        setState(() => _error = AppLocalizations.of(context)!.locationPermissionDenied);
        break;
      case LocationAccess.denied:
        // Don't show red error — keep screen as "asking" to allow; user can tap Allow again
        setState(() => _error = null);
        break;
    }
  }

  Future<void> _onOpenSettings() async {
    await _locationService.openAppSettings();
    // After returning from settings, re-check
    await _checkAndRedirect();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final accent = theme.colorScheme.primary;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 48),
              Icon(
                Icons.location_on_rounded,
                size: 64,
                color: accent,
              ),
              const SizedBox(height: 24),
              Text(
                l.locationRequiredTitle,
                style: AppTypography.displaySmall.copyWith(
                  color: onSurface,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                l.locationRequiredMessage,
                style: AppTypography.bodyLarge.copyWith(
                  color: onSurface.withValues(alpha: 0.7),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              if (_error != null) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: theme.colorScheme.onErrorContainer, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _error!,
                          style: AppTypography.bodySmall.copyWith(
                            color: theme.colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  onPressed: _isRequesting ? null : _onAllow,
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isRequesting
                      ? SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.onPrimary),
                          ),
                        )
                      : Text(
                          l.locationAllow,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _isRequesting ? null : _onOpenSettings,
                child: Text(
                  l.locationOpenSettings,
                  style: AppTypography.bodyMedium.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
