import 'package:flutter/material.dart';

import '../../../core/theme/app_typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../circles/screens/circles_screen.dart';
import '../../events/screens/events_screen.dart';

/// Dating: Circles + Events combined in one tab (Communities).
class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            l.navCommunities,
            style: AppTypography.headlineSmall.copyWith(
              color: onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Circles'),
              Tab(text: 'Events'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            CirclesScreen(),
            EventsScreen(),
          ],
        ),
      ),
    );
  }
}
