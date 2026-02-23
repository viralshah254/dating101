import 'package:flutter/material.dart';

import '../../../core/theme/app_typography.dart';
import '../../../l10n/app_localizations.dart';

/// Matrimony: Recommended + Search + Nearby (feature-flagged).
/// Dating users never see this; they see DiscoveryScreen.
class MatchesScreen extends StatelessWidget {
  const MatchesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            l.navMatches,
            style: AppTypography.headlineSmall.copyWith(
              color: onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          bottom: TabBar(
            tabs: [
              Tab(text: l.matchesRecommended),
              Tab(text: l.matchesSearch),
              Tab(text: l.matchesNearby),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _RecommendedTab(),
            _SearchTab(),
            _NearbyTab(),
          ],
        ),
      ),
    );
  }
}

class _RecommendedTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              l.recommendedCopy,
              style: AppTypography.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Text(
              l.emptyStateGeneric,
              style: AppTypography.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Center(
      child: Text(
        l.matchesSearch,
        style: AppTypography.bodyLarge,
      ),
    );
  }
}

class _NearbyTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Center(
      child: Text(
        l.matchesNearby,
        style: AppTypography.bodyLarge,
      ),
    );
  }
}
