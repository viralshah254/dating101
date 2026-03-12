import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/mode/app_mode.dart';
import '../../../core/mode/mode_provider.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/api/api_client.dart';
import '../../../domain/models/matrimony_extensions.dart';
import '../../../domain/models/profile_summary.dart';
import '../../../l10n/app_localizations.dart';
import '../../requests/providers/requests_providers.dart';
import '../providers/matches_providers.dart';

/// Modal popup showing 9 daily matches. User can deselect and send free interest to selected.
class DailyMatchesPopup extends ConsumerStatefulWidget {
  const DailyMatchesPopup({
    super.key,
    required this.profiles,
    required this.onDismiss,
    required this.onSent,
  });

  final List<ProfileSummary> profiles;
  final VoidCallback onDismiss;
  final VoidCallback onSent;

  @override
  ConsumerState<DailyMatchesPopup> createState() => _DailyMatchesPopupState();
}

class _DailyMatchesPopupState extends ConsumerState<DailyMatchesPopup> {
  late Set<String> _selectedIds;

  @override
  void initState() {
    super.initState();
    _selectedIds = widget.profiles.map((p) => p.id).toSet();
  }

  String _location(ProfileSummary p) {
    final parts = <String>[];
    if (p.city != null && p.city!.isNotEmpty) parts.add(p.city!);
    if (p.occupation != null && p.occupation!.isNotEmpty) {
      parts.add(p.occupation!);
    }
    return parts.join(' • ');
  }

  Future<void> _sendInterests() async {
    if (_selectedIds.isEmpty) {
      Navigator.of(context).pop();
      widget.onDismiss();
      return;
    }
    final mode = ref.read(appModeProvider) ?? AppMode.matrimony;
    final repo = ref.read(interactionsRepositoryProvider);
    final ids = _selectedIds.toList();
    try {
      for (final id in ids) {
        await repo.expressInterest(id, source: 'daily_matches', mode: mode);
      }
      if (!mounted) return;
      ref.read(optimisticSentInterestProfileIdsProvider.notifier).update(
            (m) => {
              ...m,
              mode: {...(m[mode] ?? {}), ...ids},
            },
          );
      ref.invalidate(recommendedPaginatedProvider);
      ref.invalidate(matchesSearchProvider);
      ref.invalidate(matchesNearbyProvider);
      ref.invalidate(sentInteractionsProvider(mode));
      ref.invalidate(mutualMatchesProvider);
      ref.invalidate(matchedUserIdsProvider);
      Navigator.of(context).pop();
      widget.onSent();
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.code == 'ALREADY_SENT') {
        ref.invalidate(sentInteractionsProvider(mode));
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final accent = AppColors.indiaGreen;
    final surface = Theme.of(context).colorScheme.surface;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
            decoration: BoxDecoration(
              color: surface.withValues(alpha: isDark ? 0.92 : 0.98),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: onSurface.withValues(alpha: 0.06),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 40,
                  offset: const Offset(0, 20),
                ),
                BoxShadow(
                  color: accent.withValues(alpha: 0.08),
                  blurRadius: 60,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with gradient accent
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 24, 16, 20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        accent.withValues(alpha: 0.06),
                        accent.withValues(alpha: 0.02),
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              accent.withValues(alpha: 0.2),
                              accent.withValues(alpha: 0.08),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.auto_awesome_rounded,
                          color: accent,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l.dailyMatchesTitle,
                              style: AppTypography.headlineSmall.copyWith(
                                color: onSurface,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              l.dailyMatchesSubtitle,
                              style: AppTypography.bodySmall.copyWith(
                                color: onSurface.withValues(alpha: 0.6),
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            Navigator.of(context).pop();
                            widget.onDismiss();
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Icon(
                              Icons.close_rounded,
                              color: onSurface.withValues(alpha: 0.5),
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Profile grid with staggered animation
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        for (var i = 0; i < widget.profiles.length; i++)
                          _DailyMatchCard(
                            profile: widget.profiles[i],
                            location: _location(widget.profiles[i]),
                            selected: _selectedIds.contains(widget.profiles[i].id),
                            accent: accent,
                            onTap: () => setState(() {
                              final id = widget.profiles[i].id;
                              if (_selectedIds.contains(id)) {
                                _selectedIds.remove(id);
                              } else {
                                _selectedIds.add(id);
                              }
                            }),
                          )
                              .animate()
                              .fadeIn(delay: (50 * i).ms, duration: 350.ms)
                              .scale(
                                begin: const Offset(0.9, 0.9),
                                end: const Offset(1, 1),
                                delay: (50 * i).ms,
                                duration: 350.ms,
                                curve: Curves.easeOutCubic,
                              ),
                      ],
                    ),
                  ),
                ),
                // CTA section
                Container(
                  padding: EdgeInsets.fromLTRB(
                    24,
                    16,
                    24,
                    24 + MediaQuery.of(context).padding.bottom,
                  ),
                  decoration: BoxDecoration(
                    color: surface,
                    border: Border(
                      top: BorderSide(
                        color: onSurface.withValues(alpha: 0.06),
                      ),
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed:
                                _selectedIds.isEmpty ? null : _sendInterests,
                            style: FilledButton.styleFrom(
                              backgroundColor: accent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              elevation: 0,
                              shadowColor: accent.withValues(alpha: 0.4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.favorite_rounded,
                                  size: 20,
                                  color: _selectedIds.isEmpty
                                      ? Colors.white.withValues(alpha: 0.5)
                                      : Colors.white,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  _selectedIds.isEmpty
                                      ? l.dailyMatchesSendFreeInterest
                                      : _selectedIds.length ==
                                              widget.profiles.length
                                          ? l.dailyMatchesSendFreeInterest
                                          : l.dailyMatchesSendFreeInterestToCount(
                                              _selectedIds.length,
                                            ),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            widget.onDismiss();
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: onSurface.withValues(alpha: 0.5),
                          ),
                          child: Text(
                            l.dailyMatchesMaybeLater,
                            style: AppTypography.bodySmall.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DailyMatchCard extends StatelessWidget {
  const _DailyMatchCard({
    required this.profile,
    required this.location,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  final ProfileSummary profile;
  final String location;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final surface = Theme.of(context).colorScheme.surface;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        width: 108,
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? accent : onSurface.withValues(alpha: 0.1),
            width: selected ? 2.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: (selected ? accent : Colors.black).withValues(alpha: selected ? 0.12 : 0.05),
              blurRadius: selected ? 14 : 10,
              offset: Offset(0, selected ? 5 : 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Photo - portrait aspect for better visibility
              Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 3 / 4,
                    child: profile.imageUrl != null && profile.imageUrl!.isNotEmpty
                        ? Image.network(
                            profile.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _placeholder(onSurface),
                          )
                        : _placeholder(onSurface),
                  ),
                  // Checkmark badge
                  Positioned(
                    top: 6,
                    right: 6,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: selected ? accent : Colors.white.withValues(alpha: 0.95),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Icon(
                        selected ? Icons.check_rounded : Icons.add_rounded,
                        size: 16,
                        color: selected ? Colors.white : onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                  // Guardian badge
                  if (profile.roleManagingProfile != null &&
                      profile.roleManagingProfile != ProfileRole.self)
                    Positioned(
                      left: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.people_outline_rounded,
                              size: 11,
                              color: Colors.white.withValues(alpha: 0.95),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              'Guardian',
                              style: AppTypography.bodySmall.copyWith(
                                color: Colors.white.withValues(alpha: 0.95),
                                fontSize: 9,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              // Text below image
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      profile.name,
                      style: AppTypography.labelLarge.copyWith(
                        color: onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (profile.age != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        '${profile.age} yrs',
                        style: AppTypography.bodySmall.copyWith(
                          color: onSurface.withValues(alpha: 0.65),
                          fontSize: 12,
                        ),
                      ),
                    ],
                    if (location.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        location,
                        style: AppTypography.bodySmall.copyWith(
                          color: onSurface.withValues(alpha: 0.55),
                          fontSize: 11,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder(Color onSurface) {
    return Container(
      color: onSurface.withValues(alpha: 0.08),
      child: Center(
        child: Text(
          (profile.name.isNotEmpty ? profile.name[0] : '?').toUpperCase(),
          style: AppTypography.titleMedium.copyWith(
            color: onSurface.withValues(alpha: 0.35),
          ),
        ),
      ),
    );
  }
}
