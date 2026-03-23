import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/feature_flags/feature_flags.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../circles/screens/circles_screen.dart';
import '../../events/screens/events_screen.dart';

/// Dating: Circles + Events combined in one tab (Communities).
class CommunityScreen extends ConsumerWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final flags = ref.watch(featureFlagsProvider);
    final showCircles = flags.circles;
    final showEvents = flags.events;

    final tabs = <Tab>[
      if (showCircles) Tab(text: l.circlesTab),
      if (showEvents) Tab(text: l.eventsTab),
    ];
    final screens = <Widget>[
      if (showCircles) const CirclesScreen(),
      if (showEvents) const EventsScreen(),
    ];
    if (tabs.isEmpty) {
      return const SizedBox.shrink();
    }

    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            l.navCommunities,
            style: AppTypography.headlineSmall.copyWith(
              color: onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          bottom: TabBar(tabs: tabs),
        ),
        body: TabBarView(children: screens),
      ),
    );
  }
}
