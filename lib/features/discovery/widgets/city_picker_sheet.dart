import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/location/app_location_service.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/theme/app_typography.dart';
import '../../../domain/models/city_option.dart';
import '../../../domain/models/country_option.dart';
import '../../../domain/models/discovery_filter_params.dart';
import '../../../domain/repositories/location_repository.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/discovery_providers.dart';

/// Change city bottom sheet: Your area, Nearby cities (with user counts),
/// Browse by country → country → city (with user counts).
/// Only shows cities with active users.
void showCityPickerSheet(BuildContext context, WidgetRef ref) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => SafeArea(
      child: DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollController) => _CityPickerContent(
          scrollController: scrollController,
          onSelectCity: (cityName) {
            ref.read(discoveryTravelCityProvider.notifier).state = cityName;
            final fp = ref.read(discoveryFilterParamsProvider);
            ref.read(discoveryFilterParamsProvider.notifier).state =
                fp?.copyWith(city: cityName) ?? DiscoveryFilterParams(city: cityName);
            ref.invalidate(discoveryFeedProvider);
            if (context.mounted) Navigator.pop(ctx);
          },
          onSelectYourArea: () {
            ref.read(discoveryTravelCityProvider.notifier).state = null;
            final fp = ref.read(discoveryFilterParamsProvider);
            if (fp != null) {
              ref.read(discoveryFilterParamsProvider.notifier).state =
                  fp.copyWith(city: '');
            }
            ref.invalidate(discoveryFeedProvider);
            if (context.mounted) Navigator.pop(ctx);
          },
          onClose: () => Navigator.pop(ctx),
        ),
      ),
    ),
  );
}

class _CityPickerContent extends ConsumerStatefulWidget {
  const _CityPickerContent({
    required this.scrollController,
    required this.onSelectCity,
    required this.onSelectYourArea,
    required this.onClose,
  });

  final ScrollController scrollController;
  final void Function(String cityName) onSelectCity;
  final VoidCallback onSelectYourArea;
  final VoidCallback onClose;

  @override
  ConsumerState<_CityPickerContent> createState() => _CityPickerContentState();
}

class _CityPickerContentState extends ConsumerState<_CityPickerContent> {
  CountryOption? _selectedCountry;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final locRepo = ref.watch(locationRepositoryProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeader(context, l),
        Flexible(
          child: ListView(
            controller: widget.scrollController,
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            children: [
              _YourAreaTile(onTap: widget.onSelectYourArea),
              const Divider(height: 24),
              _NearbyCitiesSection(locRepo: locRepo, onSelectCity: widget.onSelectCity),
              const Divider(height: 24),
              _BrowseByCountrySection(
                locRepo: locRepo,
                selectedCountry: _selectedCountry,
                onSelectCountry: (c) => setState(() => _selectedCountry = c),
                onSelectCity: widget.onSelectCity,
                onBack: () => setState(() => _selectedCountry = null),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations l) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              l.changeCity,
              style: AppTypography.headlineSmall,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: widget.onClose,
          ),
        ],
      ),
    );
  }
}

class _YourAreaTile extends StatelessWidget {
  const _YourAreaTile({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.my_location),
      title: Text(l.yourArea),
      subtitle: Text(l.showProfilesNearYou),
      onTap: onTap,
    );
  }
}

class _NearbyCitiesSection extends StatelessWidget {
  const _NearbyCitiesSection({
    required this.locRepo,
    required this.onSelectCity,
  });

  final LocationRepository locRepo;
  final void Function(String) onSelectCity;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return FutureBuilder<ProfileCreationLocation?>(
      future: AppLocationService.instance.getCurrentCreationLocation(),
      builder: (context, locSnap) {
        if (locSnap.data == null) {
          return const SizedBox.shrink();
        }
        final lat = locSnap.data!.latitude;
        final lng = locSnap.data!.longitude;
        return FutureBuilder<List<CityOption>>(
          future: locRepo.getNearbyCities(lat: lat, lng: lng, limit: 10),
          builder: (context, snap) {
            if (!snap.hasData || snap.data!.isEmpty) return const SizedBox.shrink();
            final cities = snap.data!;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    l.nearbyCities,
                    style: AppTypography.titleSmall.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ),
                ...cities.map((c) => _CityTile(
                      city: c,
                      onTap: () => onSelectCity(c.name),
                    )),
              ],
            );
          },
        );
      },
    );
  }
}

class _BrowseByCountrySection extends StatelessWidget {
  const _BrowseByCountrySection({
    required this.locRepo,
    required this.selectedCountry,
    required this.onSelectCountry,
    required this.onSelectCity,
    required this.onBack,
  });

  final LocationRepository locRepo;
  final CountryOption? selectedCountry;
  final void Function(CountryOption) onSelectCountry;
  final void Function(String) onSelectCity;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    if (selectedCountry != null) {
      return FutureBuilder<List<CityOption>>(
        future: locRepo.getCitiesByCountry(selectedCountry!.code),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ));
          }
          final cities = snap.data ?? [];
          if (cities.isEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) => onBack());
            return const SizedBox.shrink();
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: onBack,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.arrow_back, size: 20),
                      const SizedBox(width: 8),
                      Text(l.back, style: AppTypography.labelLarge),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ...cities.map((c) => _CityTile(
                    city: c,
                    onTap: () => onSelectCity(c.name),
                  )),
            ],
          );
        },
      );
    }

    return FutureBuilder<List<CountryOption>>(
      future: locRepo.getCountries(),
      builder: (context, snap) {
        if (!snap.hasData || snap.data!.isEmpty) return const SizedBox.shrink();
        final countries = snap.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                l.browseByCountry,
                style: AppTypography.titleSmall.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ),
            ...countries.map((c) => _CountryTile(
                  country: c,
                  onTap: () => onSelectCountry(c),
                )),
          ],
        );
      },
    );
  }
}

class _CityTile extends StatelessWidget {
  const _CityTile({required this.city, required this.onTap});
  final CityOption city;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.location_city_outlined),
      title: Text(city.name),
      subtitle: Text(l.activeUsersCount(city.userCount)),
      onTap: onTap,
    );
  }
}

class _CountryTile extends StatelessWidget {
  const _CountryTile({required this.country, required this.onTap});
  final CountryOption country;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.public_outlined),
      title: Text(country.name),
      subtitle: Text(l.activeUsersCount(country.userCount)),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
