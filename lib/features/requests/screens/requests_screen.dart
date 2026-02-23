import 'package:flutter/material.dart';

import '../../../core/theme/app_typography.dart';
import '../../../l10n/app_localizations.dart';

/// Matrimony: Interest requests Received / Sent.
class RequestsScreen extends StatelessWidget {
  const RequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            l.navRequests,
            style: AppTypography.headlineSmall.copyWith(
              color: onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          bottom: TabBar(
            tabs: [
              Tab(text: l.requestsReceived),
              Tab(text: l.requestsSent),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      l.requestsEmpty,
                      style: AppTypography.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l.requestsEmptyHint,
                      style: AppTypography.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            Center(
              child: Text(
                l.requestsEmpty,
                style: AppTypography.bodyLarge,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
