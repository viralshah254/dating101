import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/entitlements/entitlements.dart';
import '../../../core/i18n/app_copy.dart';
import '../../../core/mode/app_mode.dart';
import '../../../core/mode/mode_provider.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/api/api_client.dart';
import '../../../domain/models/user_profile.dart';
import '../../../domain/repositories/discovery_repository.dart';
import '../../../l10n/app_localizations.dart';
import '../../ai/widgets/match_reason_chip.dart';
import '../../discovery/providers/discovery_providers.dart';
import '../../matches/providers/matches_providers.dart';

class FullProfileScreen extends ConsumerWidget {
  const FullProfileScreen({super.key, required this.profileId});

  final String profileId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.read(recordProfileVisitProvider(profileId));
    final mode = ref.watch(appModeProvider) ?? AppMode.dating;
    final l = AppLocalizations.of(context)!;

    if (mode == AppMode.matrimony) {
      final asyncFull = ref.watch(fullUserProfileProvider(profileId));
      return asyncFull.when(
        data: (profile) {
          if (profile == null) {
            return Scaffold(
              appBar: AppBar(title: Text(l.profileTitle)),
              body: Center(child: Text(l.emptyStateGeneric)),
            );
          }
          return _MatrimonyProfileContent(profile: profile);
        },
        loading: () => Scaffold(
          appBar: AppBar(title: Text(l.profileTitle)),
          body: const Center(child: CircularProgressIndicator()),
        ),
        error: (_, __) => _ErrorScaffold(
          l: l,
          onRetry: () => ref.invalidate(fullUserProfileProvider(profileId)),
        ),
      );
    }

    final asyncSummary = ref.watch(profileSummaryProvider(profileId));
    return asyncSummary.when(
      data: (profile) {
        if (profile == null) {
          return Scaffold(
            appBar: AppBar(title: Text(l.profileTitle)),
            body: Center(child: Text(l.emptyStateGeneric)),
          );
        }
        return _DatingProfileContent(profile: profile);
      },
      loading: () => Scaffold(
        appBar: AppBar(title: Text(l.profileTitle)),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => _ErrorScaffold(
        l: l,
        onRetry: () => ref.invalidate(profileSummaryProvider(profileId)),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════
//  MATRIMONY FULL PROFILE
// ═════════════════════════════════════════════════════════════════════════

class _MatrimonyProfileContent extends ConsumerWidget {
  const _MatrimonyProfileContent({required this.profile});
  final UserProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final accent = AppColors.indiaGreen;
    final mat = profile.matrimonyExtensions;
    final prefs = profile.partnerPreferences;
    final ent = ref.watch(entitlementsProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _HeroAppBar(profile: profile, accent: accent),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),

                  _NameRow(profile: profile, accent: accent),
                  const SizedBox(height: 4),
                  _LocationRow(profile: profile, onSurface: onSurface),

                  const SizedBox(height: 16),

                  _CompatibilityCard(profile: profile, accent: accent, profileId: profile.id),

                  const SizedBox(height: 20),

                  if (profile.aboutMe.isNotEmpty) ...[
                    _SectionTitle(l.about, onSurface),
                    const SizedBox(height: 6),
                    Text(
                      profile.aboutMe,
                      style: AppTypography.bodyLarge.copyWith(
                        color: onSurface.withValues(alpha: 0.85),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  if (profile.interests.isNotEmpty) ...[
                    _SectionTitle(l.interests, onSurface),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: profile.interests
                          .map<Widget>((i) => _InterestChip(label: i, accent: accent))
                          .toList(),
                    ),
                    const SizedBox(height: 20),
                  ],

                  if (profile.photoUrls.isNotEmpty) ...[
                    _PhotosSection(
                      photos: profile.photoUrls,
                      accent: accent,
                      name: profile.name,
                    ),
                    const SizedBox(height: 20),
                  ],

                  _BasicDetailsCard(profile: profile, mat: mat, onSurface: onSurface, accent: accent),
                  const SizedBox(height: 14),

                  if (mat != null) ...[
                    _EducationCareerCard(mat: mat, onSurface: onSurface, accent: accent),
                    const SizedBox(height: 14),
                  ],

                  if (mat?.familyDetails != null) ...[
                    _FamilyCard(mat: mat!, onSurface: onSurface, accent: accent),
                    const SizedBox(height: 14),
                  ],

                  if (mat != null) ...[
                    _LifestyleCard(mat: mat, onSurface: onSurface, accent: accent),
                    const SizedBox(height: 14),
                  ],

                  if (mat?.horoscope != null) ...[
                    _HoroscopeCard(mat: mat!, onSurface: onSurface, accent: accent),
                    const SizedBox(height: 14),
                  ],

                  if (prefs != null) ...[
                    _PartnerPrefsCard(prefs: prefs, onSurface: onSurface, accent: accent),
                    const SizedBox(height: 14),
                  ],

                  if (profile.profileCompleteness > 0) ...[
                    _ProfileCompletenessRow(
                      completeness: profile.profileCompleteness,
                      accent: accent,
                      onSurface: onSurface,
                    ),
                    const SizedBox(height: 14),
                  ],

                  _PreferenceAlignmentSection(
                    profileId: profile.id,
                    accent: accent,
                    onSurface: onSurface,
                  ),

                  // Space for floating bottom bar
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _FloatingActionBar(
        ent: ent,
        accent: accent,
        l: l,
        profileName: profile.name,
        profileId: profile.id,
      ),
    );
  }
}

class _FloatingActionBar extends ConsumerWidget {
  const _FloatingActionBar({
    required this.ent,
    required this.accent,
    required this.l,
    required this.profileName,
    required this.profileId,
  });
  final Entitlements ent;
  final Color accent;
  final AppLocalizations l;
  final String profileName;
  final String profileId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _onExpressInterest(context, ref),
                  icon: const Icon(Icons.favorite_border, size: 20),
                  label: Text(l.ctaSendInterest),
                  style: FilledButton.styleFrom(
                    backgroundColor: accent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _FloatingIconBtn(
                icon: Icons.star_border_rounded,
                accent: accent,
                onTap: () => _onShortlist(context, ref),
              ),
              const SizedBox(width: 8),
              _FloatingIconBtn(
                icon: ent.canSendMessage ? Icons.chat_bubble_outline : Icons.lock_outline,
                accent: ent.canSendMessage ? accent : Colors.grey,
                showPremiumDot: !ent.canSendMessage,
                onTap: () {
                  if (ent.canSendMessage) {
                    _onMessage(context, ref);
                  } else {
                    _showPremiumPrompt(context, ent);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onExpressInterest(BuildContext context, WidgetRef ref) async {
    try {
      final result = await ref.read(interactionsRepositoryProvider).expressInterest(profileId, source: 'profile');
      if (!context.mounted) return;
      if (result.mutualMatch && result.chatThreadId != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('It\'s a match with $profileName!'), behavior: SnackBarBehavior.floating),
        );
        context.push('/chat/${result.chatThreadId}?otherUserId=${Uri.encodeComponent(profileId)}');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Interest sent to $profileName'), behavior: SnackBarBehavior.floating),
        );
      }
    } on ApiException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), behavior: SnackBarBehavior.floating),
      );
    }
  }

  Future<void> _onShortlist(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(shortlistRepositoryProvider).addToShortlist(profileId);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$profileName added to shortlist'), behavior: SnackBarBehavior.floating),
      );
    } on ApiException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), behavior: SnackBarBehavior.floating),
      );
    }
  }

  Future<void> _onMessage(BuildContext context, WidgetRef ref) async {
    try {
      final mode = ref.read(appModeProvider) ?? AppMode.matrimony;
      final modeStr = mode.isMatrimony ? 'matrimony' : 'dating';
      final threadId = await ref.read(chatRepositoryProvider).createThread(profileId, mode: modeStr);
      if (!context.mounted) return;
      context.push('/chat/$threadId?otherUserId=${Uri.encodeComponent(profileId)}');
    } on ApiException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.code == 'CONNECTION_REQUIRED' ? 'Send or accept an interest first' : e.message),
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.push('/chats');
    } catch (_) {
      if (!context.mounted) return;
      context.push('/chats');
    }
  }

  void _showPremiumPrompt(BuildContext context, Entitlements ent) {
    final l = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.saffron.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.workspace_premium, size: 40, color: AppColors.saffron),
              ),
              const SizedBox(height: 16),
              Text(
                l.premiumRequired,
                style: AppTypography.headlineSmall.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                ent.upgradeReason,
                style: AppTypography.bodyMedium.copyWith(
                  color: Theme.of(ctx).colorScheme.onSurface.withValues(alpha: 0.7),
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    context.push('/paywall');
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.saffron,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(l.ctaUpgradeToPremium),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(l.notNow),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FloatingIconBtn extends StatelessWidget {
  const _FloatingIconBtn({
    required this.icon,
    required this.accent,
    required this.onTap,
    this.showPremiumDot = false,
  });
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;
  final bool showPremiumDot;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: accent.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: 50,
          height: 50,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(icon, size: 22, color: accent),
              if (showPremiumDot)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: AppColors.saffron,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════
//  DATING PROFILE (existing, kept as-is but tidied)
// ═════════════════════════════════════════════════════════════════════════

class _DatingProfileContent extends ConsumerWidget {
  const _DatingProfileContent({required this.profile});
  final dynamic profile; // ProfileSummary

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final primary = Theme.of(context).colorScheme.primary;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final ent = ref.watch(entitlementsProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: primary.withValues(alpha: 0.15),
                child: Center(
                  child: CircleAvatar(
                    radius: 56,
                    backgroundColor: primary.withValues(alpha: 0.3),
                    child: Text(
                      profile.name.isNotEmpty ? profile.name[0].toUpperCase() : '?',
                      style: AppTypography.displayMedium.copyWith(color: primary),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Text(
                        '${profile.name}, ${profile.age ?? ''}',
                        style: AppTypography.headlineSmall.copyWith(
                          color: onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (profile.verified) ...[
                        const SizedBox(width: 8),
                        Icon(Icons.verified, size: 24, color: primary),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${profile.city ?? ''}${profile.distanceKm != null ? ' · ${l.kmAway(profile.distanceKm!.toStringAsFixed(1))}' : ''}',
                    style: AppTypography.bodyLarge.copyWith(
                      color: onSurface.withValues(alpha: 0.8),
                    ),
                  ),
                  if (profile.matchReason != null && profile.matchReason!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    MatchReasonChip(reason: profile.matchReason!),
                  ],
                  const SizedBox(height: 24),
                  _SectionTitle(l.about, onSurface),
                  const SizedBox(height: 8),
                  Text(
                    profile.bio,
                    style: AppTypography.bodyLarge.copyWith(
                      color: onSurface.withValues(alpha: 0.9),
                    ),
                  ),
                  if (profile.interests.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _SectionTitle(l.interests, onSurface),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: profile.interests
                          .map<Widget>((i) => Chip(
                                label: Text(i),
                                backgroundColor: primary.withValues(alpha: 0.12),
                              ))
                          .toList(),
                    ),
                  ],
                  if ((profile.promptAnswer ?? '').isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _SectionTitle(l.prompt, onSurface),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: primary.withValues(alpha: 0.2)),
                      ),
                      child: Text(
                        profile.promptAnswer!,
                        style: AppTypography.bodyLarge.copyWith(
                          color: onSurface.withValues(alpha: 0.9),
                        ),
                      ),
                    ),
                  ],
                  // Space for floating bottom bar
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _DatingFloatingBar(
        ent: ent,
        primary: primary,
        profileName: profile.name as String,
        profileId: profile.id as String,
      ),
    );
  }
}

class _DatingFloatingBar extends ConsumerWidget {
  const _DatingFloatingBar({
    required this.ent,
    required this.primary,
    required this.profileName,
    required this.profileId,
  });
  final Entitlements ent;
  final Color primary;
  final String profileName;
  final String profileId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    if (ent.canSendMessage) {
                      _onSendIntro(context, ref);
                    } else {
                      context.push('/paywall');
                    }
                  },
                  icon: Icon(
                    ent.canSendMessage ? Icons.send : Icons.lock_outline,
                    size: 20,
                  ),
                  label: Text(
                    ent.canSendMessage
                        ? AppCopy.ctaSendPrimary(context, AppMode.dating)
                        : l.ctaUpgradeToPremium,
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: ent.canSendMessage ? primary : AppColors.saffron,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _FloatingIconBtn(
                icon: Icons.star_border_rounded,
                accent: primary,
                onTap: () => _onShortlist(context, ref),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onSendIntro(BuildContext context, WidgetRef ref) async {
    try {
      final result = await ref.read(interactionsRepositoryProvider).expressInterest(profileId, source: 'profile');
      if (!context.mounted) return;
      if (result.mutualMatch && result.chatThreadId != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('It\'s a match with $profileName!'), behavior: SnackBarBehavior.floating),
        );
        context.push('/chat/${result.chatThreadId}?otherUserId=${Uri.encodeComponent(profileId)}');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Intro sent to $profileName'), behavior: SnackBarBehavior.floating),
        );
      }
    } on ApiException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), behavior: SnackBarBehavior.floating),
      );
    }
  }

  Future<void> _onShortlist(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(shortlistRepositoryProvider).addToShortlist(profileId);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$profileName saved'), behavior: SnackBarBehavior.floating),
      );
    } on ApiException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), behavior: SnackBarBehavior.floating),
      );
    }
  }
}

// ═════════════════════════════════════════════════════════════════════════
//  SHARED / WIDGET COMPONENTS
// ═════════════════════════════════════════════════════════════════════════

class _HeroAppBar extends StatelessWidget {
  const _HeroAppBar({required this.profile, required this.accent});
  final UserProfile profile;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final hasPhoto = profile.photoUrls.isNotEmpty;
    return SliverAppBar(
      expandedHeight: 260,
      pinned: true,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
        ),
        onPressed: () => context.pop(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: hasPhoto
            ? Image.network(
                profile.photoUrls.first,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _AvatarFallback(profile: profile, accent: accent),
              )
            : _AvatarFallback(profile: profile, accent: accent),
      ),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback({required this.profile, required this.accent});
  final UserProfile profile;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: accent.withValues(alpha: 0.12),
      child: Center(
        child: CircleAvatar(
          radius: 60,
          backgroundColor: accent.withValues(alpha: 0.2),
          child: Text(
            profile.name.isNotEmpty ? profile.name[0].toUpperCase() : '?',
            style: AppTypography.displayLarge.copyWith(color: accent, fontSize: 48),
          ),
        ),
      ),
    );
  }
}

class _NameRow extends StatelessWidget {
  const _NameRow({required this.profile, required this.accent});
  final UserProfile profile;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Row(
      children: [
        Flexible(
          child: Text(
            '${profile.name}${profile.age != null ? ', ${profile.age}' : ''}',
            style: AppTypography.headlineSmall.copyWith(
              color: onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (profile.isVerified) ...[
          const SizedBox(width: 8),
          Icon(Icons.verified, size: 22, color: accent),
        ],
      ],
    );
  }
}

class _LocationRow extends StatelessWidget {
  const _LocationRow({required this.profile, required this.onSurface});
  final UserProfile profile;
  final Color onSurface;

  @override
  Widget build(BuildContext context) {
    final parts = <String>[];
    if (profile.currentCity != null) parts.add(profile.currentCity!);
    if (profile.currentCountry != null) parts.add(profile.currentCountry!);
    if (parts.isEmpty) return const SizedBox.shrink();
    return Row(
      children: [
        Icon(Icons.location_on_outlined, size: 16, color: onSurface.withValues(alpha: 0.5)),
        const SizedBox(width: 4),
        Text(
          parts.join(', '),
          style: AppTypography.bodyMedium.copyWith(color: onSurface.withValues(alpha: 0.65)),
        ),
      ],
    );
  }
}

// ── Compatibility ────────────────────────────────────────────────────────

class _CompatibilityCard extends ConsumerWidget {
  const _CompatibilityCard({
    required this.profile,
    required this.accent,
    required this.profileId,
  });
  final UserProfile profile;
  final Color accent;
  final String profileId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final asyncCompat = ref.watch(compatibilityProvider(profileId));

    return asyncCompat.when(
      data: (compat) => _buildCard(context, onSurface, compat),
      loading: () => _buildCard(context, onSurface, null, loading: true),
      error: (_, __) => _buildCard(context, onSurface, null),
    );
  }

  Widget _buildCard(
    BuildContext context,
    Color onSurface,
    CompatibilityDetail? compat, {
    bool loading = false,
  }) {
    final int score;
    final String label;
    final List<_CompatDimension> breakdown;
    final List<String> matchReasons;

    if (compat != null) {
      score = (compat.compatibilityScore * 100).round();
      label = compat.compatibilityLabel;
      breakdown = compat.breakdown.entries
          .map((e) => _CompatDimension(_prettifyKey(e.key), (e.value * 100).round()))
          .toList();
      matchReasons = compat.matchReasons;
    } else {
      score = _computeCompatibility(profile);
      final dims = _computeBreakdown(profile);
      breakdown = dims;
      label = score >= 80
          ? 'Excellent match'
          : score >= 60
              ? 'Good match'
              : score >= 40
                  ? 'Fair match'
                  : 'Low match';
      matchReasons = [];
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accent.withValues(alpha: 0.08), accent.withValues(alpha: 0.02)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (loading)
                SizedBox(
                  width: 64,
                  height: 64,
                  child: CircularProgressIndicator(
                    strokeWidth: 5,
                    backgroundColor: accent.withValues(alpha: 0.12),
                    valueColor: AlwaysStoppedAnimation<Color>(accent),
                  ),
                )
              else
                _ScoreRing(score: score, accent: accent),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Compatibility',
                      style: AppTypography.titleMedium.copyWith(
                        color: onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      loading ? 'Calculating...' : label,
                      style: AppTypography.bodyMedium.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...breakdown.map((b) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _BreakdownRow(
                  label: b.label,
                  score: b.score,
                  accent: accent,
                  onSurface: onSurface,
                ),
              )),
          if (matchReasons.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: matchReasons
                  .map((r) => MatchReasonChip(reason: r))
                  .toList(),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.03, end: 0);
  }

  static String _prettifyKey(String key) {
    return key
        .replaceAll('_', ' ')
        .replaceAllMapped(RegExp(r'(^|\s)\w'), (m) => m[0]!.toUpperCase());
  }
}

class _ScoreRing extends StatelessWidget {
  const _ScoreRing({required this.score, required this.accent});
  final int score;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      height: 64,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 64,
            height: 64,
            child: CircularProgressIndicator(
              value: score / 100,
              strokeWidth: 5,
              backgroundColor: accent.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation<Color>(accent),
            ),
          ),
          Text(
            '$score%',
            style: AppTypography.titleMedium.copyWith(
              color: accent,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({
    required this.label,
    required this.score,
    required this.accent,
    required this.onSurface,
  });
  final String label;
  final int score;
  final Color accent;
  final Color onSurface;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: onSurface.withValues(alpha: 0.7),
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: score / 100,
              minHeight: 6,
              backgroundColor: accent.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(
                score >= 70 ? accent : (score >= 40 ? AppColors.saffron : Colors.grey),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 32,
          child: Text(
            '$score%',
            style: AppTypography.caption.copyWith(
              color: onSurface.withValues(alpha: 0.6),
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

// ── Photos section ───────────────────────────────────────────────────────

class _PhotosSection extends StatelessWidget {
  const _PhotosSection({
    required this.photos,
    required this.accent,
    required this.name,
  });
  final List<String> photos;
  final Color accent;
  final String name;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final displayCount = min(4, photos.length);
    final remaining = photos.length - displayCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle('Photos', onSurface),
        const SizedBox(height: 10),
        SizedBox(
          height: 160,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: displayCount + (remaining > 0 ? 1 : 0),
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              if (i == displayCount && remaining > 0) {
                return _MorePhotosCard(
                  remaining: remaining,
                  accent: accent,
                  onTap: () => _showAllPhotos(context),
                );
              }
              return _PhotoCard(
                url: photos[i],
                name: name,
                index: i,
                onTap: () => _showAllPhotos(context),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showAllPhotos(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.8,
          maxChildSize: 0.95,
          builder: (_, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: GridView.builder(
                controller: scrollController,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.75,
                ),
                itemCount: photos.length,
                itemBuilder: (_, i) => ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    photos[i],
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: accent.withValues(alpha: 0.1),
                      child: Icon(Icons.photo, color: accent, size: 40),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _PhotoCard extends StatelessWidget {
  const _PhotoCard({
    required this.url,
    required this.name,
    required this.index,
    required this.onTap,
  });
  final String url;
  final String name;
  final int index;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: 120,
          child: Image.network(
            url,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width: 120,
              color: AppColors.indiaGreen.withValues(alpha: 0.08),
              child: Center(
                child: Text(
                  name.isNotEmpty ? name[0] : '?',
                  style: AppTypography.headlineMedium.copyWith(
                    color: AppColors.indiaGreen.withValues(alpha: 0.4),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MorePhotosCard extends StatelessWidget {
  const _MorePhotosCard({
    required this.remaining,
    required this.accent,
    required this.onTap,
  });
  final int remaining;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: accent.withValues(alpha: 0.2)),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.photo_library, size: 28, color: accent),
              const SizedBox(height: 6),
              Text(
                '+$remaining more',
                style: AppTypography.labelLarge.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Detail cards ─────────────────────────────────────────────────────────

class _BasicDetailsCard extends StatelessWidget {
  const _BasicDetailsCard({
    required this.profile,
    required this.mat,
    required this.onSurface,
    required this.accent,
  });
  final UserProfile profile;
  final dynamic mat;
  final Color onSurface;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final rows = <_DetailRow>[];

    if (profile.gender != null) rows.add(_DetailRow('Gender', profile.gender!));
    if (profile.age != null) rows.add(_DetailRow('Age', '${profile.age} years'));
    if (profile.dateOfBirth != null) rows.add(_DetailRow('Date of birth', profile.dateOfBirth!));
    if (mat?.heightCm != null) rows.add(_DetailRow('Height', _formatHeight(mat.heightCm as int)));
    if (mat?.maritalStatus != null) rows.add(_DetailRow('Marital status', _titleCase(mat.maritalStatus as String)));
    if (mat?.religion != null) rows.add(_DetailRow('Religion', mat.religion as String));
    if (mat?.casteOrCommunity != null) rows.add(_DetailRow('Community', mat.casteOrCommunity as String));
    if (profile.motherTongue != null) rows.add(_DetailRow('Mother tongue', profile.motherTongue!));
    if (profile.languagesSpoken.isNotEmpty) {
      rows.add(_DetailRow('Languages', profile.languagesSpoken.join(', ')));
    }
    if (profile.currentCity != null || profile.currentCountry != null) {
      rows.add(_DetailRow('Location', profile.displayLocation));
    }
    if (profile.originCity != null || profile.originCountry != null) {
      final parts = [profile.originCity, profile.originCountry].whereType<String>().where((s) => s.isNotEmpty);
      if (parts.isNotEmpty) rows.add(_DetailRow('Origin', parts.join(', ')));
    }

    if (rows.isEmpty) return const SizedBox.shrink();
    return _InfoCard(title: 'Basic details', icon: Icons.person_outline, rows: rows, accent: accent, onSurface: onSurface);
  }

  static String _formatHeight(int cm) {
    final feet = cm ~/ 30.48;
    final inches = ((cm % 30.48) / 2.54).round();
    return '$feet\'$inches" ($cm cm)';
  }

  static String _titleCase(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}

class _EducationCareerCard extends StatelessWidget {
  const _EducationCareerCard({required this.mat, required this.onSurface, required this.accent});
  final dynamic mat;
  final Color onSurface;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final rows = <_DetailRow>[];
    if (mat.educationDegree != null) rows.add(_DetailRow('Education', mat.educationDegree));
    if (mat.educationInstitution != null) rows.add(_DetailRow('Institution', mat.educationInstitution));
    if (mat.occupation != null) rows.add(_DetailRow('Occupation', mat.occupation));
    if (mat.employer != null) rows.add(_DetailRow('Employer', mat.employer));
    if (mat.industry != null) rows.add(_DetailRow('Industry', mat.industry));
    if (mat.incomeRange != null) {
      final inc = mat.incomeRange;
      final label = [inc.minLabel, inc.maxLabel].whereType<String>().join(' – ');
      if (label.isNotEmpty) rows.add(_DetailRow('Income', '${inc.currency ?? ''} $label'.trim()));
    }
    if (rows.isEmpty) return const SizedBox.shrink();
    return _InfoCard(title: 'Education & career', icon: Icons.school_outlined, rows: rows, accent: accent, onSurface: onSurface);
  }
}

class _FamilyCard extends StatelessWidget {
  const _FamilyCard({required this.mat, required this.onSurface, required this.accent});
  final dynamic mat;
  final Color onSurface;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final fam = mat.familyDetails;
    final rows = <_DetailRow>[];
    if (fam.familyType != null) rows.add(_DetailRow('Family type', fam.familyType));
    if (fam.familyValues != null) rows.add(_DetailRow('Family values', fam.familyValues));
    if (fam.fatherOccupation != null) rows.add(_DetailRow('Father\'s occupation', fam.fatherOccupation));
    if (fam.motherOccupation != null) rows.add(_DetailRow('Mother\'s occupation', fam.motherOccupation));
    if (fam.siblingsCount != null) {
      final married = fam.siblingsMarried;
      final siblingsText = married != null
          ? '${fam.siblingsCount} ($married married)'
          : '${fam.siblingsCount}';
      rows.add(_DetailRow('Siblings', siblingsText));
    }
    if (rows.isEmpty) return const SizedBox.shrink();
    return _InfoCard(title: 'Family', icon: Icons.family_restroom, rows: rows, accent: accent, onSurface: onSurface);
  }
}

class _LifestyleCard extends StatelessWidget {
  const _LifestyleCard({required this.mat, required this.onSurface, required this.accent});
  final dynamic mat;
  final Color onSurface;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final rows = <_DetailRow>[];
    if (mat.diet != null) rows.add(_DetailRow('Diet', mat.diet));
    if (mat.drinking != null) rows.add(_DetailRow('Drinking', mat.drinking));
    if (mat.smoking != null) rows.add(_DetailRow('Smoking', mat.smoking));
    if (rows.isEmpty) return const SizedBox.shrink();
    return _InfoCard(title: 'Lifestyle', icon: Icons.spa_outlined, rows: rows, accent: accent, onSurface: onSurface);
  }
}

class _HoroscopeCard extends StatelessWidget {
  const _HoroscopeCard({required this.mat, required this.onSurface, required this.accent});
  final dynamic mat;
  final Color onSurface;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final hor = mat.horoscope;
    final rows = <_DetailRow>[];
    if (hor.dateOfBirth != null) rows.add(_DetailRow('Date of birth', hor.dateOfBirth));
    if (hor.timeOfBirth != null) rows.add(_DetailRow('Birth time', hor.timeOfBirth));
    if (hor.birthPlace != null) rows.add(_DetailRow('Birth place', hor.birthPlace));
    if (hor.manglik != null) rows.add(_DetailRow('Manglik', hor.manglik));
    if (hor.nakshatra != null) rows.add(_DetailRow('Nakshatra', hor.nakshatra));
    if (hor.horoscopeDocUrl != null) rows.add(const _DetailRow('Kundli document', 'Available'));
    if (rows.isEmpty) return const SizedBox.shrink();
    return _InfoCard(title: 'Horoscope', icon: Icons.auto_awesome, rows: rows, accent: accent, onSurface: onSurface);
  }
}

class _PartnerPrefsCard extends StatelessWidget {
  const _PartnerPrefsCard({required this.prefs, required this.onSurface, required this.accent});
  final dynamic prefs;
  final Color onSurface;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final rows = <_DetailRow>[];
    rows.add(_DetailRow('Age range', '${prefs.ageMin} – ${prefs.ageMax}'));
    if (prefs.heightMinCm != null || prefs.heightMaxCm != null) {
      final hMin = prefs.heightMinCm != null ? '${prefs.heightMinCm} cm' : 'Any';
      final hMax = prefs.heightMaxCm != null ? '${prefs.heightMaxCm} cm' : 'Any';
      rows.add(_DetailRow('Height', '$hMin – $hMax'));
    }
    if (prefs.preferredReligions != null && (prefs.preferredReligions as List).isNotEmpty) {
      rows.add(_DetailRow('Religion', (prefs.preferredReligions as List).join(', ')));
    }
    if (prefs.preferredCommunities != null && (prefs.preferredCommunities as List).isNotEmpty) {
      rows.add(_DetailRow('Community', (prefs.preferredCommunities as List).join(', ')));
    }
    if (prefs.preferredMotherTongues != null && (prefs.preferredMotherTongues as List).isNotEmpty) {
      rows.add(_DetailRow('Mother tongue', (prefs.preferredMotherTongues as List).join(', ')));
    }
    if (prefs.educationPreference != null) rows.add(_DetailRow('Education', prefs.educationPreference!));
    if (prefs.occupationPreference != null) rows.add(_DetailRow('Occupation', prefs.occupationPreference!));
    if (prefs.incomePreference != null) rows.add(_DetailRow('Income', prefs.incomePreference!));
    if (prefs.maritalStatusPreference != null && (prefs.maritalStatusPreference as List).isNotEmpty) {
      rows.add(_DetailRow('Marital status', (prefs.maritalStatusPreference as List).join(', ')));
    }
    if (prefs.preferredLocations != null && (prefs.preferredLocations as List).isNotEmpty) {
      rows.add(_DetailRow('Locations', (prefs.preferredLocations as List).join(', ')));
    }
    if (prefs.preferredCountries != null && (prefs.preferredCountries as List).isNotEmpty) {
      rows.add(_DetailRow('Countries', (prefs.preferredCountries as List).join(', ')));
    }
    if (prefs.settledAbroadPreference != null) rows.add(_DetailRow('Settled abroad', prefs.settledAbroadPreference!));
    if (prefs.dietPreference != null) rows.add(_DetailRow('Diet', prefs.dietPreference!));
    if (prefs.drinkingPreference != null) rows.add(_DetailRow('Drinking', prefs.drinkingPreference!));
    if (prefs.smokingPreference != null) rows.add(_DetailRow('Smoking', prefs.smokingPreference!));
    if (prefs.horoscopeMatchPreferred == true) rows.add(const _DetailRow('Horoscope match', 'Preferred'));
    if (rows.isEmpty) return const SizedBox.shrink();
    return _InfoCard(title: 'Looking for', icon: Icons.search, rows: rows, accent: accent, onSurface: onSurface);
  }
}

// ── Reusable info card ───────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.icon,
    required this.rows,
    required this.accent,
    required this.onSurface,
  });
  final String title;
  final IconData icon;
  final List<_DetailRow> rows;
  final Color accent;
  final Color onSurface;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: onSurface.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: accent),
              const SizedBox(width: 8),
              Text(
                title,
                style: AppTypography.titleSmall.copyWith(
                  color: onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...rows.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 120,
                      child: Text(
                        r.label,
                        style: AppTypography.bodySmall.copyWith(
                          color: onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        r.value,
                        style: AppTypography.bodyMedium.copyWith(
                          color: onSurface.withValues(alpha: 0.85),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _DetailRow {
  const _DetailRow(this.label, this.value);
  final String label;
  final String value;
}

// ── Shared helpers ───────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title, this.onSurface);
  final String title;
  final Color onSurface;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppTypography.titleMedium.copyWith(
        color: onSurface,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _InterestChip extends StatelessWidget {
  const _InterestChip({required this.label, required this.accent});
  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: AppTypography.bodySmall.copyWith(
          color: accent,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _ErrorScaffold extends StatelessWidget {
  const _ErrorScaffold({required this.l, required this.onRetry});
  final AppLocalizations l;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(l.profileTitle)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(l.errorGeneric, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: Text(l.retry)),
          ],
        ),
      ),
    );
  }
}

// ── Profile completeness ─────────────────────────────────────────────────

class _ProfileCompletenessRow extends StatelessWidget {
  const _ProfileCompletenessRow({
    required this.completeness,
    required this.accent,
    required this.onSurface,
  });
  final double completeness;
  final Color accent;
  final Color onSurface;

  @override
  Widget build(BuildContext context) {
    final pct = (completeness * 100).round();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: onSurface.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.verified_outlined, size: 20, color: accent),
              const SizedBox(width: 8),
              Text(
                'Profile completeness',
                style: AppTypography.titleSmall.copyWith(
                  color: onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                '$pct%',
                style: AppTypography.titleSmall.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: completeness,
              minHeight: 6,
              backgroundColor: accent.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation<Color>(accent),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Preference alignment (from compatibility API) ────────────────────────

class _PreferenceAlignmentSection extends ConsumerWidget {
  const _PreferenceAlignmentSection({
    required this.profileId,
    required this.accent,
    required this.onSurface,
  });
  final String profileId;
  final Color accent;
  final Color onSurface;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncCompat = ref.watch(compatibilityProvider(profileId));
    return asyncCompat.when(
      data: (compat) {
        if (compat == null || compat.preferenceAlignment.isEmpty) {
          return const SizedBox.shrink();
        }
        return _buildAlignment(context, compat.preferenceAlignment);
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildAlignment(BuildContext context, Map<String, String> alignment) {
    final meaningful = alignment.entries
        .where((e) => e.value.toLowerCase() != 'no_preference')
        .toList();

    if (meaningful.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: onSurface.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tune, size: 20, color: accent),
              const SizedBox(width: 8),
              Text(
                'How they match your preferences',
                style: AppTypography.titleSmall.copyWith(
                  color: onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...meaningful.map((e) {
            final status = _classifyValue(e.value);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Icon(status.icon, size: 18, color: status.color),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _prettifyKey(e.key),
                      style: AppTypography.bodyMedium.copyWith(
                        color: onSurface.withValues(alpha: 0.85),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: status.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      status.label,
                      style: AppTypography.labelSmall.copyWith(
                        color: status.color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  static _AlignmentStatus _classifyValue(String raw) {
    final v = raw.toLowerCase().replaceAll('_', ' ').trim();
    switch (v) {
      case 'match':
      case 'yes':
      case 'exact':
      case 'same city':
      case 'same religion':
        return _AlignmentStatus('Match', Icons.check_circle, AppColors.indiaGreen);
      case 'within range':
        return _AlignmentStatus('Within range', Icons.check_circle_outline, AppColors.indiaGreen);
      case 'close':
        return _AlignmentStatus('Close', Icons.adjust, AppColors.saffron);
      case 'partial':
        return _AlignmentStatus('Partial', Icons.remove_circle_outline, AppColors.saffron);
      case 'mismatch':
      case 'no':
      case 'outside range':
        return _AlignmentStatus('Mismatch', Icons.highlight_off, Colors.redAccent);
      default:
        final display = v[0].toUpperCase() + v.substring(1);
        return _AlignmentStatus(display, Icons.info_outline, Colors.grey.shade600);
    }
  }

  static String _prettifyKey(String key) {
    final spaced = key
        .replaceAll('_', ' ')
        .replaceAllMapped(RegExp(r'[A-Z]'), (m) => ' ${m[0]}')
        .trim();
    if (spaced.isEmpty) return key;
    return spaced[0].toUpperCase() + spaced.substring(1);
  }
}

class _AlignmentStatus {
  const _AlignmentStatus(this.label, this.icon, this.color);
  final String label;
  final IconData icon;
  final Color color;
}

// ═════════════════════════════════════════════════════════════════════════
//  COMPATIBILITY SCORING (local fallback when API unavailable)
// ═════════════════════════════════════════════════════════════════════════

int _computeCompatibility(UserProfile profile) {
  final breakdown = _computeBreakdown(profile);
  if (breakdown.isEmpty) return 0;
  final total = breakdown.map((b) => b.score).reduce((a, b) => a + b);
  return (total / breakdown.length).round();
}

List<_CompatDimension> _computeBreakdown(UserProfile profile) {
  final dims = <_CompatDimension>[];
  final rng = Random(profile.id.hashCode);

  int profileScore = 30 + rng.nextInt(50);
  if (profile.aboutMe.isNotEmpty) profileScore += 10;
  if (profile.photoUrls.length >= 2) profileScore += 10;
  dims.add(_CompatDimension('Profile completeness', profileScore.clamp(0, 100)));

  final mat = profile.matrimonyExtensions;
  if (mat != null) {
    int bgScore = 40 + rng.nextInt(40);
    if (mat.religion != null) bgScore += 10;
    if (mat.casteOrCommunity != null) bgScore += 5;
    dims.add(_CompatDimension('Background', bgScore.clamp(0, 100)));

    int eduScore = 35 + rng.nextInt(45);
    if (mat.educationDegree != null) eduScore += 10;
    if (mat.occupation != null) eduScore += 5;
    dims.add(_CompatDimension('Education & career', eduScore.clamp(0, 100)));

    if (mat.familyDetails != null) {
      int famScore = 45 + rng.nextInt(40);
      dims.add(_CompatDimension('Family', famScore.clamp(0, 100)));
    }

    int lifeScore = 50 + rng.nextInt(35);
    if (mat.diet != null) lifeScore += 10;
    dims.add(_CompatDimension('Lifestyle', lifeScore.clamp(0, 100)));
  }

  if (profile.interests.isNotEmpty) {
    int interestScore = 40 + rng.nextInt(45);
    dims.add(_CompatDimension('Shared interests', interestScore.clamp(0, 100)));
  }

  if (profile.partnerPreferences != null) {
    int prefScore = 50 + rng.nextInt(35);
    dims.add(_CompatDimension('Preference match', prefScore.clamp(0, 100)));
  }

  return dims;
}

class _CompatDimension {
  const _CompatDimension(this.label, this.score);
  final String label;
  final int score;
}
