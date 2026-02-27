import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/app_localizations.dart';

class EventsScreen extends StatelessWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final accent = Theme.of(context).colorScheme.primary;
    final events = _mockEvents;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l.navEvents,
          style: AppTypography.headlineSmall.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.calendar_month), onPressed: () {}),
        ],
      ),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            TabBar(
              labelColor: accent,
              unselectedLabelColor: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.6),
              tabs: const [
                Tab(text: 'Upcoming'),
                Tab(text: 'My RSVPs'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: events.length,
                    itemBuilder: (context, i) {
                      final e = events[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child:
                            Card(
                                  child: InkWell(
                                    onTap: () => _showEventDetail(context, e),
                                    borderRadius: BorderRadius.circular(16),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            width: 56,
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 8,
                                            ),
                                            decoration: BoxDecoration(
                                              color: accent.withValues(
                                                alpha: 0.15,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Column(
                                              children: [
                                                Text(
                                                  DateFormat(
                                                    'MMM',
                                                  ).format(e.date),
                                                  style: AppTypography
                                                      .labelSmall
                                                      .copyWith(
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .onSurface
                                                            .withValues(
                                                              alpha: 0.9,
                                                            ),
                                                      ),
                                                ),
                                                Text(
                                                  DateFormat(
                                                    'd',
                                                  ).format(e.date),
                                                  style: AppTypography
                                                      .titleMedium
                                                      .copyWith(
                                                        color: Theme.of(
                                                          context,
                                                        ).colorScheme.onSurface,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  e.title,
                                                  style: AppTypography
                                                      .titleMedium
                                                      .copyWith(
                                                        color: Theme.of(
                                                          context,
                                                        ).colorScheme.onSurface,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  e.venue,
                                                  style: AppTypography.bodySmall
                                                      .copyWith(
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .onSurface
                                                            .withValues(
                                                              alpha: 0.85,
                                                            ),
                                                      ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  '${e.attendeeCount} going',
                                                  style: AppTypography.caption
                                                      .copyWith(
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .onSurface
                                                            .withValues(
                                                              alpha: 0.75,
                                                            ),
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          FilledButton(
                                            onPressed: () => _rsvp(context, e),
                                            child: Text(l.rsvp),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                )
                                .animate()
                                .fadeIn(delay: (50 * i).ms)
                                .slideY(begin: 0.02, end: 0),
                      );
                    },
                  ),
                  Center(
                    child: Text(
                      'Events you\'ve RSVP\'d to will appear here.',
                      style: AppTypography.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEventDetail(BuildContext context, _Event e) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        expand: false,
        builder: (_, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(e.title, style: AppTypography.headlineSmall),
              const SizedBox(height: 8),
              Text(
                DateFormat.yMMMd().format(e.date),
                style: AppTypography.bodyMedium,
              ),
              Text(e.venue, style: AppTypography.bodySmall),
              const SizedBox(height: 16),
              Text(e.description, style: AppTypography.bodyMedium),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () {
                  _rsvp(context, e);
                  Navigator.pop(ctx);
                },
                child: Text(AppLocalizations.of(context)!.rsvp),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _rsvp(BuildContext context, _Event e) {
    final l = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l.rsvpdTo(e.title))));
  }
}

class _Event {
  _Event({
    required this.id,
    required this.title,
    required this.venue,
    required this.date,
    required this.attendeeCount,
    required this.description,
  });
  final String id;
  final String title;
  final String venue;
  final DateTime date;
  final int attendeeCount;
  final String description;
}

final List<_Event> _mockEvents = [
  _Event(
    id: '1',
    title: 'City meetup: Shoreditch',
    venue: 'The Breakfast Club, London',
    date: DateTime.now().add(const Duration(days: 5)),
    attendeeCount: 12,
    description: 'Casual brunch and chat. No agenda—just good company.',
  ),
  _Event(
    id: '2',
    title: 'Desi Professionals Networking',
    venue: 'WeWork Moorgate',
    date: DateTime.now().add(const Duration(days: 12)),
    attendeeCount: 28,
    description: 'Monthly networking for South Asian professionals in London.',
  ),
];
