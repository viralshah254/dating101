import 'dart:math';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../core/ads/ad_loading_dialog.dart';
import '../widgets/voice_intro_player.dart';
import '../../../core/ads/ad_service.dart';
import '../../../core/entitlements/entitlements.dart';
import '../../../core/feature_flags/feature_flags.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/widgets/premium_badge.dart';
import '../../../core/widgets/translatable_text.dart';
import '../../../core/mode/app_mode.dart';
import '../../../core/mode/mode_provider.dart';
import '../../../core/safety/safety_reason_picker.dart';

import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/api/api_client.dart';
import '../../../domain/models/contact_request_status.dart';
import '../../../domain/models/matrimony_extensions.dart';
import '../../../domain/models/photo_view_request.dart';
import '../../../domain/models/user_profile.dart';
import '../../../domain/repositories/discovery_repository.dart';
import '../../../l10n/app_localizations.dart';
import '../../ai/widgets/match_reason_chip.dart';
import '../../chat/providers/chat_providers.dart';
import '../../discovery/providers/discovery_providers.dart';
import '../../matches/providers/matches_providers.dart';
import '../../requests/providers/requests_providers.dart';
import '../../shortlist/providers/shortlist_providers.dart';

class FullProfileScreen extends ConsumerWidget {
  const FullProfileScreen({super.key, required this.profileId});

  final String profileId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.read(recordProfileVisitProvider(profileId));
    final mode = ref.watch(appModeProvider) ?? AppMode.dating;
    final l = AppLocalizations.of(context)!;

    if (mode == AppMode.matrimony) {
      final asyncFull = ref.watch(matrimonyProfileViewProvider(profileId));
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
          onRetry: () => ref.invalidate(matrimonyProfileViewProvider(profileId)),
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

class _MatrimonyProfileContent extends ConsumerStatefulWidget {
  const _MatrimonyProfileContent({required this.profile});
  final UserProfile profile;

  @override
  ConsumerState<_MatrimonyProfileContent> createState() =>
      _MatrimonyProfileContentState();
}

class _MatrimonyProfileContentState
    extends ConsumerState<_MatrimonyProfileContent> {
  final _aboutKey = GlobalKey();
  final _photosKey = GlobalKey();
  final _basicsKey = GlobalKey();
  final _eduCareerKey = GlobalKey();
  final _familyKey = GlobalKey();
  final _lifestyleKey = GlobalKey();
  final _horoscopeKey = GlobalKey();
  final _lookingForKey = GlobalKey();

  void _scrollTo(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      alignment: 0.05,
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    final l = AppLocalizations.of(context)!;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final accent = Theme.of(context).colorScheme.secondary;
    final mat = profile.matrimonyExtensions;
    final prefs = profile.partnerPreferences;
    final ent = ref.watch(entitlementsProvider);
    final flags = ref.watch(featureFlagsProvider);

    return Scaffold(
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          _HeroAppBar(
            profile: profile,
            accent: accent,
            onBlock: () =>
                _showBlockConfirm(context, ref, profile.id, profile.name),
            onReport: () =>
                _showReportConfirm(context, ref, profile.id, profile.name),
          ),
          // Section chips live in the scroll body (not a pinned sliver) to avoid
          // SliverGeometry errors from nested horizontal scroll under a pinned header.
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SectionNavBar(
                  accent: accent,
                  onTap: _scrollTo,
                  items: [
                    if (profile.aboutMe.isNotEmpty ||
                        (mat?.aboutEducation?.isNotEmpty == true))
                      (label: 'About', key: _aboutKey),
                    if (profile.photosHidden || profile.photoUrls.isNotEmpty)
                      (label: 'Photos', key: _photosKey),
                    (label: 'Basics', key: _basicsKey),
                    if (mat != null)
                      (label: 'Edu & Career', key: _eduCareerKey),
                    if (mat?.familyDetails != null)
                      (label: 'Family', key: _familyKey),
                    if (mat != null)
                      (label: 'Lifestyle', key: _lifestyleKey),
                    if (flags.horoscope && mat?.horoscope != null)
                      (label: 'Horoscope', key: _horoscopeKey),
                    if (prefs != null)
                      (label: 'Looking For', key: _lookingForKey),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  const SizedBox(height: 20),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _NameRow(
                              profile: profile,
                              accent: accent,
                              isPremium: ref.read(authRepositoryProvider).currentUserId == profile.id
                                  ? ent.isPremium
                                  : profile.isPremium,
                            ),
                            const SizedBox(height: 4),
                            _LocationRow(
                              profile: profile,
                              onSurface: onSurface,
                            ),
                          ],
                        ),
                      ),
                      if (mat != null &&
                          mat.roleManagingProfile != ProfileRole.self) ...[
                        const SizedBox(width: 12),
                        _ManagedByBanner(
                          role: mat.roleManagingProfile,
                          onSurface: onSurface,
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 16),

                  _CompatibilityCard(
                    profile: profile,
                    accent: accent,
                    profileId: profile.id,
                  ),

                  const SizedBox(height: 20),

                  if (profile.aboutMe.isNotEmpty ||
                      (mat?.aboutEducation != null &&
                          mat!.aboutEducation!.isNotEmpty)) ...[
                    SizedBox(key: _aboutKey, height: 0),
                    _SectionTitle(l.about, onSurface),
                    const SizedBox(height: 6),
                    if (profile.aboutMe.isNotEmpty)
                      TranslatableText(
                        content: profile.aboutMe,
                        textStyle: AppTypography.bodyLarge.copyWith(
                          color: onSurface.withValues(alpha: 0.85),
                          height: 1.5,
                        ),
                        showTranslateButton: true,
                      ),
                    if (mat?.aboutEducation != null &&
                        mat!.aboutEducation!.isNotEmpty) ...[
                      if (profile.aboutMe.isNotEmpty)
                        const SizedBox(height: 12),
                      Text(
                        mat.aboutEducation!,
                        style: AppTypography.bodyLarge.copyWith(
                          color: onSurface.withValues(alpha: 0.85),
                          height: 1.5,
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                  ],

                  if (profile.interests.isNotEmpty) ...[
                    _SectionTitle(l.interests, onSurface),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: profile.interests
                          .map<Widget>(
                            (i) => _InterestChip(label: i, accent: accent),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 20),
                  ],

                  SizedBox(key: _photosKey, height: 0),
                  if (profile.photosHidden &&
                      profile.canViewPhotos != true) ...[
                    _PhotosLockedSection(profileId: profile.id, accent: accent),
                    const SizedBox(height: 20),
                  ] else if ((!profile.photosHidden ||
                          profile.canViewPhotos == true) &&
                      profile.photoUrls.isNotEmpty) ...[
                    _PhotosSection(
                      photos: profile.photoUrls,
                      accent: accent,
                      name: profile.name,
                    ),
                    const SizedBox(height: 20),
                  ],

                  SizedBox(key: _basicsKey, height: 0),
                  _BasicDetailsCard(
                    profile: profile,
                    mat: mat,
                    onSurface: onSurface,
                    accent: accent,
                  ).animate(delay: AppMotion.stagger(0, stepMs: 80)).fadeIn(duration: AppMotion.medium).slideY(begin: 0.06, curve: AppMotion.spring),
                  const SizedBox(height: 14),

                  if (mat != null) ...[
                    SizedBox(key: _eduCareerKey, height: 0),
                    _EducationCareerCard(
                      mat: mat,
                      onSurface: onSurface,
                      accent: accent,
                    ).animate(delay: AppMotion.stagger(1, stepMs: 80)).fadeIn(duration: AppMotion.medium).slideY(begin: 0.06, curve: AppMotion.spring),
                    const SizedBox(height: 14),
                  ],

                  if (mat?.familyDetails != null) ...[
                    SizedBox(key: _familyKey, height: 0),
                    _FamilyCard(
                      mat: mat!,
                      onSurface: onSurface,
                      accent: accent,
                    ).animate(delay: AppMotion.stagger(2, stepMs: 80)).fadeIn(duration: AppMotion.medium).slideY(begin: 0.06, curve: AppMotion.spring),
                    const SizedBox(height: 14),
                  ],

                  if (mat != null) ...[
                    SizedBox(key: _lifestyleKey, height: 0),
                    _LifestyleCard(
                      mat: mat,
                      onSurface: onSurface,
                      accent: accent,
                    ).animate(delay: AppMotion.stagger(3, stepMs: 80)).fadeIn(duration: AppMotion.medium).slideY(begin: 0.06, curve: AppMotion.spring),
                    const SizedBox(height: 14),
                  ],

                  if (flags.horoscope && mat?.horoscope != null) ...[
                    SizedBox(key: _horoscopeKey, height: 0),
                    _HoroscopeCard(
                      mat: mat!,
                      onSurface: onSurface,
                      accent: accent,
                    ).animate(delay: AppMotion.stagger(4, stepMs: 80)).fadeIn(duration: AppMotion.medium).slideY(begin: 0.06, curve: AppMotion.spring),
                    const SizedBox(height: 14),
                  ],

                  if (prefs != null) ...[
                    SizedBox(key: _lookingForKey, height: 0),
                    _PartnerPrefsCard(
                      prefs: prefs,
                      onSurface: onSurface,
                      accent: accent,
                    ).animate(delay: AppMotion.stagger(5, stepMs: 80)).fadeIn(duration: AppMotion.medium).slideY(begin: 0.06, curve: AppMotion.spring),
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

                  // Space for floating bottom bar
                  const SizedBox(height: 100),
                    ],
                  ),
                ),
              ],
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
        profile: profile,
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
    required this.profile,
  });
  final Entitlements ent;
  final Color accent;
  final AppLocalizations l;
  final String profileName;
  final String profileId;
  final UserProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flags = ref.watch(featureFlagsProvider);
    final matchedIds =
        ref.watch(matchedUserIdsProvider).valueOrNull ?? <String>{};
    final shortlistedIds =
        ref.watch(shortlistedIdsProvider).valueOrNull ?? <String>{};
    final mode = ref.watch(appModeProvider) ?? AppMode.dating;
    final sentInterestIds =
        ref.watch(sentInterestProfileIdsProvider(mode)).valueOrNull ?? <String>{};
    final sentPriorityIds =
        ref.watch(sentPriorityInterestProfileIdsProvider(mode)).valueOrNull ??
        <String>{};
    final isMatched = matchedIds.contains(profileId);
    final isShortlisted = shortlistedIds.contains(profileId);
    final isSentInterest = sentInterestIds.contains(profileId);
    final isPrioritySent = sentPriorityIds.contains(profileId);
    final contactGatingOn = flags.contactRequestGating;
    final canRequestContactNow =
        !contactGatingOn || isMatched || ent.canRequestContact;
    // Once matched, messaging is unlocked for this profile (no premium required).
    final canMessageThisProfile = ent.canSendMessage || isMatched;

    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
      decoration: BoxDecoration(
        color: cs.surface.withValues(alpha: isDark ? 0.82 : 0.90),
        border: Border(
          top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.4)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildPrimaryActionButton(
                      context,
                      ref,
                      l: l,
                      accent: accent,
                      isMatched: isMatched,
                      isSentInterest: isSentInterest,
                      isPrioritySent: isPrioritySent,
                    ).animate().slideY(begin: 0.4, end: 0, duration: AppMotion.slow, curve: AppMotion.reveal).fadeIn(duration: AppMotion.medium),
                  ),
                  const SizedBox(width: 10),
                  _FloatingIconBtn(
                    icon: isShortlisted
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    accent: accent,
                    onTap: () => _onShortlist(context, ref, isShortlisted),
                  ),
                  const SizedBox(width: 8),
                  _FloatingIconBtn(
                    icon: canMessageThisProfile
                        ? Icons.chat_bubble_outline
                        : Icons.lock_outline,
                    accent: canMessageThisProfile ? accent : Theme.of(context).colorScheme.onSurfaceVariant,
                    showPremiumDot: !canMessageThisProfile,
                    onTap: () {
                      if (canMessageThisProfile) {
                        _onMessage(context, ref);
                      } else {
                        _showPremiumPrompt(context, ent);
                      }
                    },
                  ),
                ],
              ),
              if (contactGatingOn) ...[
                const SizedBox(height: 8),
                _RequestContactRow(
                  profileId: profileId,
                  canRequest: canRequestContactNow,
                  isMatched: isMatched,
                  ent: ent,
                  accent: accent,
                ),
              ],
            ],
          ),
        ),
      ),
        ),
      ),
    );
  }

  Widget _buildPrimaryActionButton(
    BuildContext context,
    WidgetRef ref, {
    required AppLocalizations l,
    required Color accent,
    required bool isMatched,
    required bool isSentInterest,
    required bool isPrioritySent,
  }) {
    final style = FilledButton.styleFrom(
      backgroundColor: accent,
      padding: const EdgeInsets.symmetric(vertical: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
    );
    if (isMatched) {
      return FilledButton.icon(
        onPressed: () => _onMessage(context, ref),
        icon: const Icon(Icons.chat_bubble_outline, size: 20),
        label: Text(l.ctaSendMessage),
        style: style,
      );
    }
    if (isPrioritySent) {
      return FilledButton.icon(
        onPressed: null,
        icon: const Icon(Icons.check_circle_outline, size: 20),
        label: Text(l.toastInterestSent),
        style: style.copyWith(
          backgroundColor: WidgetStatePropertyAll(accent.withValues(alpha: 0.7)),
        ),
      );
    }
    if (isSentInterest) {
      return FilledButton.icon(
        onPressed: () => _onExpressPriorityInterest(context, ref),
        icon: const Icon(Icons.auto_awesome, size: 20),
        label: Text(l.priorityInterest),
        style: style,
      );
    }
    return FilledButton.icon(
      onPressed: () => _onExpressInterest(context, ref),
      icon: const Icon(Icons.favorite_border, size: 20),
      label: Text(l.ctaSendInterest),
      style: style,
    );
  }

  Future<void> _onExpressInterest(BuildContext context, WidgetRef ref) async {
    final mode = ref.read(appModeProvider) ?? AppMode.dating;
    try {
      final result = await ref
          .read(interactionsRepositoryProvider)
          .expressInterest(profileId, source: 'profile', mode: mode);
      if (!context.mounted) return;
      ref.read(optimisticSentInterestProfileIdsProvider.notifier).update(
            (m) => {...m, mode: {...(m[mode] ?? {}), profileId}},
          );
      ref.invalidate(sentInteractionsProvider(mode));
      ref.invalidate(recommendedPaginatedProvider);
      if (result.mutualMatch) {
        ref.invalidate(mutualMatchesProvider);
        ref.invalidate(matchedUserIdsProvider);
        ref.read(shortlistUnlockedEntriesProvider.notifier).update(
              (list) => list.where((e) => e.profileId != profileId).toList(),
            );
        _showMutualMatchCelebration(context, result.chatThreadId);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.toastInterestSentTo(profileName),
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } on ApiException catch (e) {
      if (!context.mounted) return;
      if (e.code == 'ALREADY_SENT') {
        ref.invalidate(sentInteractionsProvider(mode));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l.toastInterestSent),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), behavior: SnackBarBehavior.floating),
      );
    }
  }

  Future<void> _onExpressPriorityInterest(
      BuildContext context, WidgetRef ref) async {
    final message = await _showPriorityMessageDialog(context);
    if (!context.mounted) return;
    final ent = ref.read(entitlementsProvider);
    String? adToken;
    if (ent.dailyPriorityInterestLimit == 0) {
      final watchAd = await _showWatchAdOrPremiumChoice(context);
      if (!context.mounted) return;
      if (watchAd == null) return;
      if (watchAd == false) {
        context.push('/paywall');
        return;
      }
      final shown = await loadAndShowInterstitialWithLoading(
        context,
        ref,
        AdRewardReason.priorityInterest,
      );
      if (!context.mounted) return;
      if (!shown) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Ad couldn\'t be loaded. Try again or upgrade to Premium.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      adToken = const Uuid().v4();
    }
    final mode = ref.read(appModeProvider) ?? AppMode.dating;
    try {
      final result = await ref
          .read(interactionsRepositoryProvider)
          .expressPriorityInterest(
            profileId,
            message: message,
            source: 'profile',
            adCompletionToken: adToken,
            mode: mode,
          );
      if (!context.mounted) return;
      ref.read(optimisticSentInterestProfileIdsProvider.notifier).update(
            (m) => {...m, mode: {...(m[mode] ?? {}), profileId}},
          );
      ref.invalidate(sentInteractionsProvider(mode));
      ref.invalidate(recommendedPaginatedProvider);
      if (result.mutualMatch) {
        ref.invalidate(mutualMatchesProvider);
        ref.invalidate(matchedUserIdsProvider);
        ref.read(shortlistUnlockedEntriesProvider.notifier).update(
              (list) => list.where((e) => e.profileId != profileId).toList(),
            );
        _showMutualMatchCelebration(context, result.chatThreadId);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.toastInterestSentTo(profileName),
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } on ApiException catch (e) {
      if (!context.mounted) return;
      if (e.code == 'ALREADY_SENT') {
        ref.invalidate(sentInteractionsProvider(mode));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l.toastInterestSent),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), behavior: SnackBarBehavior.floating),
      );
    }
  }

  Future<String?> _showPriorityMessageDialog(BuildContext context) async {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final surface = theme.colorScheme.surface;
    final accent = theme.colorScheme.primary;
    final width = MediaQuery.sizeOf(context).width;
    final dialogWidth = (width * 0.9).clamp(320.0, 420.0);
    final warmBg = Color.lerp(surface, accent, 0.03) ?? surface;
    final warmFill = Color.lerp(surface, accent, 0.06) ?? surface;
    final name = profileName.split(' ').first;
    final greeting =
        name.isNotEmpty ? loc.sayHiToName(name) : loc.sendPersonalNote;

    final controller = TextEditingController();
    return showDialog<String?>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding:
            EdgeInsets.symmetric(horizontal: (width - dialogWidth) / 2),
        child: Material(
          borderRadius: BorderRadius.circular(28),
          color: warmBg,
          elevation: 12,
          shadowColor: accent.withValues(alpha: 0.15),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: dialogWidth),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(26, 30, 26, 26),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
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
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Icon(
                          Icons.auto_awesome,
                          color: accent,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Text(
                          loc.priorityInterest,
                          style: AppTypography.titleLarge.copyWith(
                            color: onSurface,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    greeting,
                    style: AppTypography.bodyLarge.copyWith(
                      color: onSurface.withValues(alpha: 0.85),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'A short note goes a long way — optional, but they\'ll love it.',
                    style: AppTypography.bodyMedium.copyWith(
                      color: onSurface.withValues(alpha: 0.6),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 22),
                  TextField(
                    controller: controller,
                    maxLines: 4,
                    minLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText:
                          'e.g. Hi! Something in your profile caught my eye...',
                      hintStyle: TextStyle(
                        color: onSurface.withValues(alpha: 0.4),
                        fontWeight: FontWeight.w400,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide(
                          color: onSurface.withValues(alpha: 0.12),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide(color: accent, width: 2),
                      ),
                      filled: true,
                      fillColor: warmFill,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 26),
                  FilledButton(
                    onPressed: () {
                      final text = controller.text.trim();
                      Navigator.of(ctx).pop(text.isEmpty ? null : text);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Text(loc.sendYourNote),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(null),
                    style: TextButton.styleFrom(
                      foregroundColor: onSurface.withValues(alpha: 0.55),
                    ),
                    child: Text(loc.skipForNow),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<bool?> _showWatchAdOrPremiumChoice(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        title: Text(l.priorityInterest),
        content: const Text(
          'Watch an ad to send your priority interest, or upgrade to Premium to send without ads.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l.ctaUpgradeToPremium),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Watch ad'),
          ),
        ],
      ),
    );
  }

  void _showMutualMatchCelebration(BuildContext context, String? chatThreadId) {
    final l = AppLocalizations.of(context)!;
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        title: Text(l.toastMatchWith(profileName)),
        content: const Text(
          'You\'re both interested in each other! Send a message or view their profile.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.push('/profile/$profileId');
            },
            child: Text(l.viewProfile),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              if (chatThreadId != null) {
                context.push(
                  '/chat/$chatThreadId?otherUserId=${Uri.encodeComponent(profileId)}',
                );
              } else {
                context.push('/profile/$profileId');
              }
            },
            child: Text(l.ctaSendMessage),
          ),
        ],
      ),
    );
  }

  Future<void> _onShortlist(
    BuildContext context,
    WidgetRef ref,
    bool currentlyShortlisted,
  ) async {
    try {
      if (currentlyShortlisted) {
        await ref
            .read(shortlistRepositoryProvider)
            .removeFromShortlist(profileId);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.toastRemovedFromShortlist,
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        await ref.read(shortlistRepositoryProvider).addToShortlist(profileId);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.toastAddedToShortlist),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      ref.invalidate(shortlistProvider);
      ref.invalidate(shortlistedIdsProvider);
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
      final threadId = await ref
          .read(chatRepositoryProvider)
          .createThread(profileId, mode: modeStr);
      if (!context.mounted) return;
      context.push(
        '/chat/$threadId?otherUserId=${Uri.encodeComponent(profileId)}',
      );
    } on ApiException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.code == 'CONNECTION_REQUIRED'
                ? 'Send or accept an interest first'
                : e.message,
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.push('/chats');
    } catch (_) {
      if (!context.mounted) return;
      context.push('/chats');
    }
  }
}

/// When contactRequestGating is on: Request contact / Pending / View contacts (Call, WhatsApp) / disabled.
class _RequestContactRow extends ConsumerWidget {
  const _RequestContactRow({
    required this.profileId,
    required this.canRequest,
    required this.isMatched,
    required this.ent,
    required this.accent,
  });
  final String profileId;
  final bool canRequest;
  final bool isMatched;
  final Entitlements ent;
  final Color accent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final statusAsync = ref.watch(contactRequestStatusProvider(profileId));

    if (!canRequest) {
      return Tooltip(
        message: isMatched
            ? 'Request contact is available for matched profiles.'
            : ent.canRequestContact
            ? 'Request contact is available after you both express interest.'
            : 'Request contact is available after mutual interest or with premium.',
        child: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: onSurface.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Request contact is available after you both express interest or with premium.',
                  style: AppTypography.caption.copyWith(
                    color: onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return statusAsync.when(
      data: (status) {
        final s = status;
        if (s.state == ContactRequestState.accepted && s.canViewContacts) {
          return _ViewContactsRow(phone: s.sharedPhone!, accent: accent);
        }
        if (s.state == ContactRequestState.pending) {
          return SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: null,
              icon: Icon(
                Icons.schedule,
                size: 18,
                color: onSurface.withValues(alpha: 0.6),
              ),
              label: Text(
                'Request pending',
                style: TextStyle(color: onSurface.withValues(alpha: 0.6)),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: onSurface.withValues(alpha: 0.2)),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          );
        }
        if (s.state == ContactRequestState.declined) {
          return SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _sendContactRequest(context, ref, profileId),
              icon: const Icon(Icons.phone_outlined, size: 18),
              label: Text(AppLocalizations.of(context)!.requestAgain),
              style: OutlinedButton.styleFrom(
                foregroundColor: accent,
                side: BorderSide(color: accent.withValues(alpha: 0.6)),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          );
        }
        return SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _sendContactRequest(context, ref, profileId),
            icon: const Icon(Icons.phone_outlined, size: 18),
            label: Text(AppLocalizations.of(context)!.requestContact),
            style: OutlinedButton.styleFrom(
              foregroundColor: accent,
              side: BorderSide(color: accent.withValues(alpha: 0.6)),
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        );
      },
      loading: () => SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: null,
          icon: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: accent),
          ),
          label: Text(AppLocalizations.of(context)!.requestContact),
          style: OutlinedButton.styleFrom(
            foregroundColor: accent,
            side: BorderSide(color: accent.withValues(alpha: 0.6)),
            padding: const EdgeInsets.symmetric(vertical: 10),
          ),
        ),
      ),
      error: (_, __) => SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () => _sendContactRequest(context, ref, profileId),
          icon: const Icon(Icons.phone_outlined, size: 18),
          label: Text(AppLocalizations.of(context)!.requestContact),
          style: OutlinedButton.styleFrom(
            foregroundColor: accent,
            side: BorderSide(color: accent.withValues(alpha: 0.6)),
            padding: const EdgeInsets.symmetric(vertical: 10),
          ),
        ),
      ),
    );
  }

  Future<void> _sendContactRequest(
    BuildContext context,
    WidgetRef ref,
    String profileId,
  ) async {
    try {
      await ref
          .read(contactRequestRepositoryProvider)
          .sendContactRequest(profileId);
      if (!context.mounted) return;
      ref.invalidate(contactRequestStatusProvider(profileId));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.contactRequestSent),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.couldNotSendRequest('$e'),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

class _ViewContactsRow extends StatelessWidget {
  const _ViewContactsRow({required this.phone, required this.accent});
  final String phone;
  final Color accent;

  Future<void> _launchCall() async {
    final uri = Uri.parse('tel:${phone.replaceAll(RegExp(r'[^\d+]'), '')}');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _launchWhatsApp() async {
    final digits = phone.replaceAll(RegExp(r'[^\d]'), '');
    final uri = Uri.parse('https://wa.me/$digits');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'View contacts',
          style: AppTypography.labelMedium.copyWith(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.7),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _launchCall,
                icon: const Icon(Icons.call_outlined, size: 20),
                label: Text(AppLocalizations.of(context)!.call),
                style: OutlinedButton.styleFrom(
                  foregroundColor: accent,
                  side: BorderSide(color: accent.withValues(alpha: 0.6)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _launchWhatsApp,
                icon: const Icon(Icons.chat_outlined, size: 20),
                label: Text(AppLocalizations.of(context)!.whatsApp),
                style: OutlinedButton.styleFrom(
                  foregroundColor: accent,
                  side: BorderSide(color: accent.withValues(alpha: 0.6)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ],
        ),
      ],
    );
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
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.workspace_premium,
                size: 40,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l.premiumRequired,
              style: AppTypography.headlineSmall.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              ent.upgradeReason,
              style: AppTypography.bodyMedium.copyWith(
                color: Theme.of(
                  ctx,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
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
                  backgroundColor: Theme.of(context).colorScheme.primary,
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
                      color: Theme.of(context).colorScheme.primary,
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
    final surfaceVariant = Theme.of(context).colorScheme.surfaceContainerHighest;
    final imageUrls = _imageUrlsFromProfile(profile);
    final asyncCompat = ref.watch(compatibilityProvider(profile.id as String));

    final quickFacts = <_QuickFact>[
      if (profile.occupation != null)
        _QuickFact(Icons.work_outline_rounded, profile.occupation!),
      if (profile.educationDegree != null)
        _QuickFact(Icons.school_outlined, profile.educationDegree!),
      if (profile.heightCm != null)
        _QuickFact(Icons.straighten_rounded, _formatHeight(profile.heightCm!)),
      if (profile.motherTongue != null)
        _QuickFact(Icons.translate_rounded, profile.motherTongue!),
      if (profile.religion != null)
        _QuickFact(Icons.auto_awesome_outlined, profile.religion!),
      if (profile.diet != null)
        _QuickFact(Icons.restaurant_outlined, profile.diet!),
    ];

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          _DatingProfileHero(
            profile: profile,
            imageUrls: imageUrls,
            onBlock: () =>
                _showBlockConfirm(context, ref, profile.id, profile.name),
            onReport: () =>
                _showReportConfirm(context, ref, profile.id, profile.name),
            onImageTap: imageUrls.isNotEmpty
                ? () => _openPhotoGallery(context, imageUrls, 0)
                : null,
          ),

          SliverToBoxAdapter(
            child: Transform.translate(
              offset: const Offset(0, -28),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name + age + verified
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              '${profile.name}, ${profile.age ?? ''}',
                              style: AppTypography.headlineSmall.copyWith(
                                color: onSurface,
                                fontWeight: FontWeight.w800,
                                fontSize: 26,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ),
                          if (profile.verified) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: primary.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.verified_rounded, size: 22, color: primary),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Location + distance
                      if (profile.city != null && profile.city!.isNotEmpty)
                        Row(
                          children: [
                            Icon(Icons.location_on_rounded, size: 16, color: onSurface.withValues(alpha: 0.5)),
                            const SizedBox(width: 4),
                            Text(
                              '${profile.city ?? ''}${profile.distanceKm != null ? ' · ${l.kmAway(profile.distanceKm!.toStringAsFixed(1))}' : ''}',
                              style: AppTypography.bodyMedium.copyWith(
                                color: onSurface.withValues(alpha: 0.6),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),

                      // Voice Intro player
                      if ((profile.voiceIntroUrl as String?) != null &&
                          (profile.voiceIntroUrl as String).isNotEmpty) ...[
                        const SizedBox(height: 16),
                        VoiceIntroPlayerCard(
                          url: profile.voiceIntroUrl as String,
                          name: profile.name as String,
                        ),
                      ],

                      // Compatibility Story card
                      if (profile.compatibilityScore != null ||
                          profile.compatibilityLabel != null ||
                          asyncCompat.valueOrNull != null) ...[
                        const SizedBox(height: 16),
                        _CompatibilityStoryCard(
                          profile: profile,
                          compat: asyncCompat.valueOrNull,
                        ),
                      ],

                      // Quick facts row
                      if (quickFacts.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: quickFacts
                              .map((f) => _QuickFactChip(
                                    icon: f.icon,
                                    label: f.label,
                                    onSurface: onSurface,
                                    surfaceVariant: surfaceVariant,
                                  ))
                              .toList(),
                        ),
                      ],

                      // Bio / About
                      if ((profile.bio as String).isNotEmpty) ...[
                        const SizedBox(height: 24),
                        Text(
                          l.about,
                          style: AppTypography.titleSmall.copyWith(
                            color: onSurface.withValues(alpha: 0.5),
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TranslatableText(
                          content: profile.bio,
                          textStyle: AppTypography.bodyLarge.copyWith(
                            color: onSurface.withValues(alpha: 0.88),
                            height: 1.5,
                            fontSize: 16,
                          ),
                        ),
                      ],

                      // Prompt card
                      if ((profile.promptAnswer ?? '').isNotEmpty) ...[
                        const SizedBox(height: 24),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                primary.withValues(alpha: 0.07),
                                primary.withValues(alpha: 0.03),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: primary.withValues(alpha: 0.15),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.format_quote_rounded, size: 20, color: primary.withValues(alpha: 0.6)),
                                  const SizedBox(width: 8),
                                  Text(
                                    l.prompt,
                                    style: AppTypography.labelMedium.copyWith(
                                      color: primary.withValues(alpha: 0.7),
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                profile.promptAnswer!,
                                style: AppTypography.bodyLarge.copyWith(
                                  color: onSurface.withValues(alpha: 0.88),
                                  height: 1.5,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Photo gallery (inline, staggered)
                      if (imageUrls.length > 1) ...[
                        const SizedBox(height: 24),
                        _DatingPhotoGrid(
                          imageUrls: imageUrls,
                          onTap: (i) => _openPhotoGallery(context, imageUrls, i),
                        ),
                      ],

                      // Interests
                      if (profile.interests.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        Text(
                          l.interests,
                          style: AppTypography.titleSmall.copyWith(
                            color: onSurface.withValues(alpha: 0.5),
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: (profile.interests as List<String>)
                              .map<Widget>(
                                (i) => _DatingInterestChip(
                                  label: i,
                                  isShared: (profile.sharedInterests as List<String>?)
                                          ?.contains(i) ??
                                      false,
                                  primary: primary,
                                  onSurface: onSurface,
                                ),
                              )
                              .toList(),
                        ),
                      ],

                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _DatingProfileBottomBar(
        profileId: profile.id as String,
        profileName: profile.name as String,
      ),
    );
  }

  static String _formatHeight(int cm) {
    final feet = cm ~/ 30.48;
    final inches = ((cm % 30.48) / 2.54).round();
    return '$feet\'$inches" ($cm cm)';
  }

  static List<String> _imageUrlsFromProfile(dynamic profile) {
    if (profile.imageUrls != null && (profile.imageUrls as List<String>).isNotEmpty) {
      return profile.imageUrls as List<String>;
    }
    if (profile.imageUrl != null && (profile.imageUrl as String).isNotEmpty) {
      return [profile.imageUrl as String];
    }
    return [];
  }
}

class _QuickFact {
  const _QuickFact(this.icon, this.label);
  final IconData icon;
  final String label;
}

class _QuickFactChip extends StatelessWidget {
  const _QuickFactChip({
    required this.icon,
    required this.label,
    required this.onSurface,
    required this.surfaceVariant,
  });
  final IconData icon;
  final String label;
  final Color onSurface;
  final Color surfaceVariant;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: surfaceVariant.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: onSurface.withValues(alpha: 0.55)),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: onSurface.withValues(alpha: 0.8),
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

/// Staggered photo grid for dating profile: first photo large, remaining smaller.
class _DatingPhotoGrid extends StatelessWidget {
  const _DatingPhotoGrid({required this.imageUrls, required this.onTap});
  final List<String> imageUrls;
  final void Function(int index) onTap;

  @override
  Widget build(BuildContext context) {
    final urls = imageUrls.skip(1).take(4).toList();
    if (urls.isEmpty) return const SizedBox.shrink();

    if (urls.length <= 2) {
      return Row(
        children: [
          for (int i = 0; i < urls.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(child: _gridTile(context, urls[i], i + 1, 180)),
          ],
        ],
      );
    }
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _gridTile(context, urls[0], 1, 180)),
            const SizedBox(width: 8),
            Expanded(child: _gridTile(context, urls[1], 2, 180)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (int i = 2; i < urls.length; i++) ...[
              if (i > 2) const SizedBox(width: 8),
              Expanded(child: _gridTile(context, urls[i], i + 1, 140)),
            ],
            if (urls.length == 3) ...[
              const SizedBox(width: 8),
              const Expanded(child: SizedBox()),
            ],
          ],
        ),
      ],
    );
  }

  Widget _gridTile(BuildContext context, String url, int index, double height) {
    return GestureDetector(
      onTap: () => onTap(index),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: CachedNetworkImage(
          imageUrl: url,
          height: height,
          fit: BoxFit.cover,
          placeholder: (_, __) => Container(
            height: height,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
            child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          errorWidget: (_, __, ___) => Container(
            height: height,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Icon(
              Icons.image_not_supported_outlined,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
            ),
          ),
        ),
      ),
    );
  }
}

/// Hero for dating profile: tall photo with bottom sheet overlap.
class _DatingProfileHero extends StatelessWidget {
  const _DatingProfileHero({
    required this.profile,
    required this.imageUrls,
    required this.onBlock,
    required this.onReport,
    this.onImageTap,
  });
  final dynamic profile;
  final List<String> imageUrls;
  final VoidCallback onBlock;
  final VoidCallback onReport;
  final VoidCallback? onImageTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final l = AppLocalizations.of(context)!;
    final hasImages = imageUrls.isNotEmpty;
    final screenHeight = MediaQuery.of(context).size.height;

    return SliverAppBar(
      expandedHeight: screenHeight * 0.52,
      pinned: true,
      stretch: true,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.35),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
        ),
        onPressed: () => context.pop(),
      ),
      actions: [
        PopupMenuButton<String>(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.35),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.more_vert, color: Colors.white.withValues(alpha: 0.95), size: 22),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          onSelected: (v) {
            if (v == 'block') onBlock();
            if (v == 'report') onReport();
          },
          itemBuilder: (_) => [
            PopupMenuItem(
              value: 'block',
              child: Row(
                children: [
                  Icon(Icons.block, size: 20, color: Theme.of(context).colorScheme.error),
                  const SizedBox(width: 12),
                  Text(l.block),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'report',
              child: Row(
                children: [
                  Icon(Icons.flag_outlined, size: 20, color: Theme.of(context).colorScheme.error),
                  const SizedBox(width: 12),
                  Text(l.report),
                ],
              ),
            ),
          ],
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (hasImages)
              GestureDetector(
                onTap: onImageTap,
                child: Hero(
                  tag: 'profile_photo_${profile.id}',
                  child: CachedNetworkImage(
                    imageUrl: imageUrls.first,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => ColoredBox(
                      color: primary.withValues(alpha: 0.15),
                      child: Center(
                        child: CircleAvatar(
                          radius: 48,
                          backgroundColor: primary.withValues(alpha: 0.3),
                          child: Text(
                            profile.name.isNotEmpty ? profile.name[0].toUpperCase() : '?',
                            style: AppTypography.displayMedium.copyWith(color: primary),
                          ),
                        ),
                      ),
                    ),
                    errorWidget: (_, __, ___) => _DatingHeroFallback(profile: profile, primary: primary),
                  ),
                ),
              )
            else
              _DatingHeroFallback(profile: profile, primary: primary),

            // Photo count badge
            if (hasImages && imageUrls.length > 1)
              Positioned(
                right: 16,
                bottom: 44,
                child: GestureDetector(
                  onTap: onImageTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.photo_library_rounded, color: Colors.white, size: 15),
                        const SizedBox(width: 5),
                        Text(
                          '1/${imageUrls.length}',
                          style: AppTypography.labelSmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Bottom gradient for smooth sheet overlap
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.25),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DatingHeroFallback extends StatelessWidget {
  const _DatingHeroFallback({required this.profile, required this.primary});
  final dynamic profile;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    return Container(
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
    );
  }
}

/// Opens full-screen photo gallery at the given index. Used by profile photo sections.
void _openPhotoGallery(BuildContext context, List<String> imageUrls, int initialIndex) {
  if (imageUrls.isEmpty) return;
  Navigator.of(context).push(
    PageRouteBuilder(
      opaque: true,
      barrierColor: Colors.black,
      pageBuilder: (_, __, ___) => _FullScreenPhotoGallery(
        imageUrls: imageUrls,
        initialIndex: initialIndex.clamp(0, imageUrls.length - 1),
      ),
    ),
  );
}

/// Full-screen scrollable photo gallery for dating profile. Swipe between images, tap X to close.
class _FullScreenPhotoGallery extends StatefulWidget {
  const _FullScreenPhotoGallery({
    required this.imageUrls,
    required this.initialIndex,
  });
  final List<String> imageUrls;
  final int initialIndex;

  @override
  State<_FullScreenPhotoGallery> createState() => _FullScreenPhotoGalleryState();
}

class _FullScreenPhotoGalleryState extends State<_FullScreenPhotoGallery> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialIndex);
    _currentIndex = widget.initialIndex;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.imageUrls.length,
            onPageChanged: (i) => setState(() => _currentIndex = i),
            itemBuilder: (_, i) => InteractiveViewer(
              minScale: 0.8,
              maxScale: 4,
              child: SizedBox.expand(
                child: CachedNetworkImage(
                  imageUrl: widget.imageUrls[i],
                  fit: BoxFit.cover,
                  placeholder: (_, __) => const Center(
                    child: CircularProgressIndicator(color: Colors.white70),
                  ),
                  errorWidget: (_, __, ___) => const Center(
                    child: Icon(Icons.image_not_supported, color: Colors.white54, size: 48),
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, color: Colors.white, size: 24),
                    ),
                  ),
                  if (widget.imageUrls.length > 1)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_currentIndex + 1} / ${widget.imageUrls.length}',
                        style: AppTypography.labelLarge.copyWith(color: Colors.white),
                      ),
                    )
                  else
                    const SizedBox.shrink(),
                  const SizedBox(width: 48),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Posh compatibility pill for dating profile: refined typography and premium look.
/// Expandable compatibility story card for the full profile screen.
class _CompatibilityStoryCard extends StatefulWidget {
  const _CompatibilityStoryCard({required this.profile, this.compat});
  final dynamic profile;
  final dynamic compat;

  @override
  State<_CompatibilityStoryCard> createState() => _CompatibilityStoryCardState();
}

class _CompatibilityStoryCardState extends State<_CompatibilityStoryCard>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late AnimationController _ctrl;
  late Animation<double> _expandAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _expandAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    if (_expanded) { _ctrl.forward(); } else { _ctrl.reverse(); }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final onSurface = cs.onSurface;
    final p = widget.profile;
    final c = widget.compat;

    int score;
    String label;
    if (c != null) {
      score = (c.compatibilityScore * 100).round();
      label = c.compatibilityLabel ?? 'Match';
    } else if (p.compatibilityScore != null) {
      score = (p.compatibilityScore * 100).round();
      label = p.compatibilityLabel ?? 'Good match';
    } else {
      return const SizedBox.shrink();
    }

    final isHigh = score >= 70;
    final isMedium = score >= 50 && score < 70;
    final accentColor = isHigh
        ? const Color(0xFF2E7D32)
        : isMedium
            ? const Color(0xFFF9A825)
            : const Color(0xFFE65100);

    // Build narrative + dimensions
    final matchReasons = <String>[];
    if (c != null && c.matchReasons != null) {
      for (final r in (c.matchReasons as List)) {
        if (r.toString().trim().isNotEmpty) matchReasons.add(r.toString().trim());
        if (matchReasons.length >= 4) break;
      }
    } else if (p.matchReasons != null) {
      for (final r in (p.matchReasons as List)) {
        if (r.toString().trim().isNotEmpty) matchReasons.add(r.toString().trim());
        if (matchReasons.length >= 4) break;
      }
    }

    final sharedInterests = <String>[];
    if (p.sharedInterests != null) {
      for (final i in (p.sharedInterests as List)) {
        sharedInterests.add(i.toString());
        if (sharedInterests.length >= 3) break;
      }
    }

    String? narrative;
    if (sharedInterests.isNotEmpty) {
      narrative = 'You both love ${sharedInterests.take(2).join(' and ')}';
    } else if (matchReasons.isNotEmpty) {
      narrative = matchReasons.first;
    }

    return GestureDetector(
      onTap: matchReasons.isNotEmpty || narrative != null ? _toggle : null,
      child: AnimatedBuilder(
        animation: _expandAnim,
        builder: (ctx, _) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: accentColor.withValues(alpha: 0.18)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.auto_awesome_rounded, size: 20, color: accentColor),
                    const SizedBox(width: 10),
                    Text(
                      '$score%',
                      style: AppTypography.titleMedium.copyWith(
                        color: onSurface,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        label,
                        style: AppTypography.bodySmall.copyWith(
                          color: onSurface.withValues(alpha: 0.6),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (matchReasons.isNotEmpty || narrative != null)
                      Icon(
                        _expanded
                            ? Icons.expand_less_rounded
                            : Icons.expand_more_rounded,
                        size: 20,
                        color: onSurface.withValues(alpha: 0.4),
                      ),
                  ],
                ),
                SizeTransition(
                  sizeFactor: _expandAnim,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (narrative != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          '"$narrative"',
                          style: AppTypography.bodySmall.copyWith(
                            color: onSurface.withValues(alpha: 0.7),
                            fontStyle: FontStyle.italic,
                            fontSize: 13,
                          ),
                        ),
                      ],
                      if (matchReasons.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        ...matchReasons.map(
                          (r) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Icon(Icons.check_circle_rounded,
                                    size: 14, color: accentColor),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    r,
                                    style: AppTypography.bodySmall.copyWith(
                                      color: onSurface.withValues(alpha: 0.8),
                                      fontWeight: FontWeight.w500,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DatingInterestChip extends StatelessWidget {
  const _DatingInterestChip({
    required this.label,
    required this.isShared,
    required this.primary,
    required this.onSurface,
  });
  final String label;
  final bool isShared;
  final Color primary;
  final Color onSurface;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isShared ? primary.withValues(alpha: 0.14) : onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isShared ? primary.withValues(alpha: 0.4) : onSurface.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isShared) ...[
            Icon(Icons.favorite_rounded, size: 13, color: primary),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              fontWeight: isShared ? FontWeight.w700 : FontWeight.w500,
              color: isShared ? primary : onSurface.withValues(alpha: 0.8),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

/// Dating bottom bar: Pass / Super like / Like / Message before any action; after like or super like, Message-only bar.
class _DatingProfileBottomBar extends ConsumerWidget {
  const _DatingProfileBottomBar({
    required this.profileId,
    required this.profileName,
  });
  final String profileId;
  final String profileName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(appModeProvider) ?? AppMode.dating;
    final passedIds = ref.watch(passedProfileIdsProvider);
    final sentInterestIds =
        ref.watch(sentInterestProfileIdsProvider(mode)).valueOrNull ?? <String>{};
    final sentPriorityIds =
        ref.watch(sentPriorityInterestProfileIdsProvider(mode)).valueOrNull ??
            <String>{};
    final optimisticSent =
        ref.watch(optimisticSentInterestProfileIdsProvider)[mode];
    final isPassed = passedIds.contains(profileId);
    final isLiked = sentInterestIds.contains(profileId) ||
        (optimisticSent?.contains(profileId) ?? false);
    final isSuperLiked = sentPriorityIds.contains(profileId);

    if (isPassed && !isLiked && !isSuperLiked) {
      return const SizedBox.shrink();
    }
    if (isLiked || isSuperLiked) {
      return _DatingPostInterestBar(
        profileId: profileId,
        profileName: profileName,
      );
    }
    return _DatingFloatingBar(
      profileId: profileId,
      profileName: profileName,
    );
  }
}

/// After like / super like: keep a clear [Message] CTA (full bar was hidden before).
class _DatingPostInterestBar extends ConsumerWidget {
  const _DatingPostInterestBar({
    required this.profileId,
    required this.profileName,
  });

  final String profileId;
  final String profileName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final matched =
        ref.watch(matchedUserIdsProvider).valueOrNull?.contains(profileId) ??
            false;
    final hint = matched
        ? l.toastMatchWith(profileName)
        : l.toastInterestSent;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.grey.shade900.withValues(alpha: 0.92)
                : Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 24,
                spreadRadius: 0,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                hint,
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall.copyWith(
                  color: onSurface.withValues(alpha: 0.72),
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () =>
                    _datingFullProfileOnMessage(context, ref, profileId),
                icon: const Icon(Icons.chat_bubble_rounded, size: 22),
                label: Text(l.ctaSendMessage),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _datingFullProfileOpenChat(
  BuildContext context,
  WidgetRef ref,
  String profileId,
  String? initialAdToken,
) async {
  final l = AppLocalizations.of(context)!;
  final navigator = Navigator.of(context);
  try {
    final threadId = await ref.read(chatRepositoryProvider).createThread(
          profileId,
          mode: 'dating',
        );
    if (!context.mounted) return;
    ref.invalidate(messageRequestsProvider);
    ref.invalidate(messageRequestsCountProvider);
    ref.invalidate(receivedRequestsCountProvider);
    ref.invalidate(chatThreadsProvider);
    ref.invalidate(discoveryFeedProvider);
    ref.read(discoveryAdvancePastProfileIdProvider.notifier).state = profileId;
    navigator.pop();
    if (!context.mounted) return;
    final query = 'otherUserId=${Uri.encodeComponent(profileId)}';
    final tokenParam = initialAdToken != null
        ? '&initialAdToken=${Uri.encodeComponent(initialAdToken)}'
        : '';
    context.push('/chat/$threadId?$query$tokenParam');
  } on ApiException catch (e) {
    if (!context.mounted) return;
    ref.invalidate(discoveryFeedProvider);
    ref.read(discoveryAdvancePastProfileIdProvider.notifier).state = profileId;
    navigator.pop();
    if (!context.mounted) return;
    context.push('/chats');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          e.code == 'CONNECTION_REQUIRED'
              ? l.likedOpenChatFromChats
              : e.code == 'DAILY_MESSAGE_AD_LIMIT_REACHED'
                  ? l.datingMessageAdLimitReached
                  : e.message,
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  } catch (_) {
    if (!context.mounted) return;
    ref.read(discoveryAdvancePastProfileIdProvider.notifier).state = profileId;
    navigator.pop();
    if (!context.mounted) return;
    context.push('/chats');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l.errorGeneric),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

Future<void> _datingFullProfileOnMessage(
  BuildContext context,
  WidgetRef ref,
  String profileId,
) async {
  final ent = ref.read(entitlementsProvider);
  final l = AppLocalizations.of(context)!;
  if (ent.canSendMessage) {
    await _datingFullProfileOpenChat(context, ref, profileId, null);
    return;
  }
  final choice = await showModalBottomSheet<String?>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l.datingMessageGateTitle,
              style: AppTypography.titleMedium.copyWith(
                color: Theme.of(ctx).colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l.datingMessageGateBody,
              style: AppTypography.bodyMedium.copyWith(
                color:
                    Theme.of(ctx).colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => Navigator.of(ctx).pop('watch_ad'),
              icon: const Icon(Icons.play_circle_outline, size: 22),
              label: Text(l.watchAdToSendMessage),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () => Navigator.of(ctx).pop('upgrade'),
              icon: const Icon(Icons.workspace_premium_outlined, size: 22),
              label: Text(l.ctaUpgradeToPremium),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(null),
              child: Text(l.cancel),
            ),
          ],
        ),
      ),
    ),
  );
  if (!context.mounted || choice == null) return;
  if (choice == 'upgrade') {
    context.push('/paywall');
    return;
  }
  if (choice == 'watch_ad') {
    final shown = await loadAndShowInterstitialWithLoading(
      context,
      ref,
      AdRewardReason.sendMessage,
    );
    if (!context.mounted) return;
    if (!shown) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.failedToSendTryAgain),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final adToken = const Uuid().v4();
    final mode = ref.read(appModeProvider) ?? AppMode.dating;
    final sentIds =
        ref.read(sentInterestProfileIdsProvider(mode)).valueOrNull ??
            <String>{};
    final optimisticSent =
        ref.read(optimisticSentInterestProfileIdsProvider)[mode];
    final alreadySent = sentIds.contains(profileId) ||
        (optimisticSent?.contains(profileId) ?? false);
    if (!alreadySent) {
      try {
        await ref.read(interactionsRepositoryProvider).expressInterest(
              profileId,
              source: 'profile',
              mode: mode,
            );
        if (!context.mounted) return;
        ref.read(optimisticSentInterestProfileIdsProvider.notifier).update(
              (m) => {...m, mode: {...(m[mode] ?? {}), profileId}},
            );
        ref.invalidate(sentInteractionsProvider(mode));
      } on ApiException catch (e) {
        if (!context.mounted) return;
        if (e.code != 'ALREADY_SENT') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.message),
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }
        ref.invalidate(sentInteractionsProvider(mode));
      }
    }
    await _datingFullProfileOpenChat(context, ref, profileId, adToken);
  }
}

/// Dating-only action bar: Pass | Super like | Like | Message. No shortlist on dating.
class _DatingFloatingBar extends ConsumerWidget {
  const _DatingFloatingBar({
    required this.profileId,
    required this.profileName,
  });
  final String profileId;
  final String profileName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(appModeProvider) ?? AppMode.dating;
    final ent = ref.watch(entitlementsProvider);
    final sentInterestIds =
        ref.watch(sentInterestProfileIdsProvider(mode)).valueOrNull ?? <String>{};
    final sentPriorityIds =
        ref.watch(sentPriorityInterestProfileIdsProvider(mode)).valueOrNull ??
            <String>{};
    final optimisticSent =
        ref.watch(optimisticSentInterestProfileIdsProvider)[mode];
    final isLiked = sentInterestIds.contains(profileId) ||
        (optimisticSent?.contains(profileId) ?? false);
    final isSuperLiked = sentPriorityIds.contains(profileId);
    final canMessageDirect = ent.canSendMessage;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.grey.shade900.withValues(alpha: 0.92)
                : Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 24,
                spreadRadius: 0,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ActionCircle(
                icon: Icons.close_rounded,
                size: 46,
                iconSize: 22,
                gradient: const [Color(0xFFFF6B6B), Color(0xFFEE5A24)],
                enabled: true,
                onTap: () => _onPass(context, ref),
              ),
              _ActionCircle(
                icon: Icons.auto_awesome_rounded,
                size: 46,
                iconSize: 20,
                gradient: const [Color(0xFFD4A5FF), Color(0xFF9B59B6)],
                enabled: !isSuperLiked,
                onTap: isSuperLiked
                    ? null
                    : () => _onSuperLike(context, ref),
              ),
              _ActionCircle(
                icon: Icons.favorite_rounded,
                size: 60,
                iconSize: 28,
                gradient: const [Color(0xFF6DD5A0), Color(0xFF2ECC71)],
                enabled: !(isLiked || isSuperLiked),
                isHero: true,
                onTap: isLiked || isSuperLiked
                    ? null
                    : () => _onLike(context, ref),
              ),
              _ActionCircle(
                icon: Icons.chat_bubble_rounded,
                size: 46,
                iconSize: 20,
                gradient: const [Color(0xFF74B9FF), Color(0xFF0984E3)],
                enabled: true,
                showBadge: !canMessageDirect,
                onTap: () =>
                    _datingFullProfileOnMessage(context, ref, profileId),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onPass(BuildContext context, WidgetRef ref) async {
    final mode = ref.read(appModeProvider) ?? AppMode.dating;
    try {
      await ref.read(discoveryRepositoryProvider).sendFeedback(
            candidateId: profileId,
            action: 'pass',
            source: 'profile_view',
            mode: mode,
          );
    } catch (_) {}
    if (!context.mounted) return;
    ref.read(passedProfileIdsProvider.notifier).update((s) => {...s, profileId});
    context.pop();
  }

  Future<void> _onLike(BuildContext context, WidgetRef ref) async {
    final mode = ref.read(appModeProvider) ?? AppMode.dating;
    try {
      final result = await ref.read(interactionsRepositoryProvider).expressInterest(
            profileId,
            source: 'profile',
            mode: mode,
          );
      if (!context.mounted) return;
      ref.read(optimisticSentInterestProfileIdsProvider.notifier).update(
            (m) => {...m, mode: {...(m[mode] ?? {}), profileId}},
          );
      ref.invalidate(sentInteractionsProvider(mode));
      ref.invalidate(recommendedPaginatedProvider);
      if (result.mutualMatch && result.chatThreadId != null) {
        ref.invalidate(mutualMatchesProvider);
        ref.invalidate(matchedUserIdsProvider);
        ref.read(shortlistUnlockedEntriesProvider.notifier).update(
              (list) => list.where((e) => e.profileId != profileId).toList(),
            );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.toastMatchWith(profileName)),
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.push(
          '/chat/${result.chatThreadId}?otherUserId=${Uri.encodeComponent(profileId)}',
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.toastInterestSentTo(profileName)),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } on ApiException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), behavior: SnackBarBehavior.floating),
      );
    }
  }

  Future<void> _onSuperLike(BuildContext context, WidgetRef ref) async {
    final mode = ref.read(appModeProvider) ?? AppMode.dating;
    try {
      final result = await ref.read(interactionsRepositoryProvider).expressPriorityInterest(
            profileId,
            message: null,
            source: 'profile',
            adCompletionToken: null,
            mode: mode,
          );
      if (!context.mounted) return;
      ref.read(optimisticSentInterestProfileIdsProvider.notifier).update(
            (m) => {...m, mode: {...(m[mode] ?? {}), profileId}},
          );
      ref.invalidate(sentInteractionsProvider(mode));
      ref.invalidate(recommendedPaginatedProvider);
      if (result.mutualMatch && result.chatThreadId != null) {
        ref.invalidate(mutualMatchesProvider);
        ref.invalidate(matchedUserIdsProvider);
        ref.read(shortlistUnlockedEntriesProvider.notifier).update(
              (list) => list.where((e) => e.profileId != profileId).toList(),
            );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.toastMatchWith(profileName)),
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.push(
          '/chat/${result.chatThreadId}?otherUserId=${Uri.encodeComponent(profileId)}',
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.toastInterestSentTo(profileName)),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } on ApiException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), behavior: SnackBarBehavior.floating),
      );
    }
  }
}

/// Message button for dating profile: prominent CTA with icon + label; shows premium dot when gated.
/// Gradient-filled circular action button with optional hero scaling and badge.
class _ActionCircle extends StatefulWidget {
  const _ActionCircle({
    required this.icon,
    required this.size,
    required this.iconSize,
    required this.gradient,
    required this.enabled,
    this.isHero = false,
    this.showBadge = false,
    this.onTap,
  });
  final IconData icon;
  final double size;
  final double iconSize;
  final List<Color> gradient;
  final bool enabled;
  final bool isHero;
  final bool showBadge;
  final VoidCallback? onTap;

  @override
  State<_ActionCircle> createState() => _ActionCircleState();
}

class _ActionCircleState extends State<_ActionCircle>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      reverseDuration: const Duration(milliseconds: 200),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.88).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _handleTapDown(_) {
    if (widget.enabled) _ctrl.forward();
  }

  void _handleTapUp(_) {
    if (widget.enabled) _ctrl.reverse();
  }

  void _handleTapCancel() {
    if (widget.enabled) _ctrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final disabledGrey = Colors.grey.shade400;

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.enabled ? widget.onTap : null,
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) => Transform.scale(
          scale: _scale.value,
          child: child,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: widget.enabled
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: widget.gradient,
                      )
                    : null,
                color: widget.enabled ? null : disabledGrey.withValues(alpha: 0.25),
                boxShadow: widget.enabled
                    ? [
                        BoxShadow(
                          color: widget.gradient.first.withValues(alpha: widget.isHero ? 0.4 : 0.3),
                          blurRadius: widget.isHero ? 16 : 10,
                          spreadRadius: widget.isHero ? 2 : 0,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                widget.icon,
                size: widget.iconSize,
                color: widget.enabled ? Colors.white : disabledGrey,
              ),
            ),
            if (widget.showBadge)
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFB347), Color(0xFFFF6B6B)],
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════
//  SAFETY (BLOCK / REPORT)
// ═════════════════════════════════════════════════════════════════════════

Future<void> _showBlockConfirm(
  BuildContext context,
  WidgetRef ref,
  String profileId,
  String profileName,
) async {
  final l = AppLocalizations.of(context)!;
  final reason = await showBlockReasonPicker(context);
  if (reason == null || !context.mounted) return;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l.block),
      content: Text(
        '$profileName won\'t be able to see your profile or contact you.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(l.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
          child: Text(l.block),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;
  try {
    await ref
        .read(safetyRepositoryProvider)
        .block(profileId, reason, source: 'profile');
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.toastBlocked(profileName)),
        behavior: SnackBarBehavior.floating,
      ),
    );
    if (context.mounted) context.pop();
  } catch (_) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.toastErrorGeneric),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }
}

Future<void> _showReportConfirm(
  BuildContext context,
  WidgetRef ref,
  String profileId,
  String profileName,
) async {
  final l = AppLocalizations.of(context)!;
  final result = await showReportReasonPicker(context);
  if (result == null || !context.mounted) return;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l.report),
      content: Text(
        'Report $profileName? We take safety seriously and will review this profile.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(l.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
          child: Text(l.report),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;
  try {
    await ref
        .read(safetyRepositoryProvider)
        .report(
          profileId,
          result.reason,
          details: result.details,
          source: 'profile',
        );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.toastReportSubmitted),
        behavior: SnackBarBehavior.floating,
      ),
    );
  } catch (_) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.toastErrorGeneric),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════
//  SHARED / WIDGET COMPONENTS
// ═════════════════════════════════════════════════════════════════════════

class _HeroAppBar extends StatelessWidget {
  const _HeroAppBar({
    required this.profile,
    required this.accent,
    required this.onBlock,
    required this.onReport,
  });
  final UserProfile profile;
  final Color accent;
  final VoidCallback onBlock;
  final VoidCallback onReport;

  @override
  Widget build(BuildContext context) {
    // Only show profile photo when viewer is allowed (not hidden, or access granted).
    final canShowPhotos =
        !profile.photosHidden || profile.canViewPhotos == true;
    final hasPhoto = canShowPhotos && profile.photoUrls.isNotEmpty;
    final l = AppLocalizations.of(context)!;
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
      actions: [
        PopupMenuButton<String>(
          icon: Icon(
            Icons.more_vert,
            color: Colors.white.withValues(alpha: 0.9),
          ),
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          onSelected: (v) {
            if (v == 'block') onBlock();
            if (v == 'report') onReport();
          },
          itemBuilder: (_) => [
            PopupMenuItem(
              value: 'block',
              child: Row(
                children: [
                  Icon(
                    Icons.block,
                    size: 20,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(width: 12),
                  Text(l.block),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'report',
              child: Row(
                children: [
                  Icon(
                    Icons.flag_outlined,
                    size: 20,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(width: 12),
                  Text(l.report),
                ],
              ),
            ),
          ],
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: hasPhoto
            ? Image.network(
                profile.photoUrls.first,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    _AvatarFallback(profile: profile, accent: accent),
              )
            : (profile.photosHidden && profile.canViewPhotos != true)
            ? _LockedPhotosHeroBackground(
                profileId: profile.id,
                name: profile.name,
                accent: accent,
              )
            : _AvatarFallback(profile: profile, accent: accent),
      ),
    );
  }
}

/// Blurred-style hero area with "Request to view photos" button when photos are hidden.
class _LockedPhotosHeroBackground extends ConsumerWidget {
  const _LockedPhotosHeroBackground({
    required this.profileId,
    required this.name,
    required this.accent,
  });
  final String profileId;
  final String name;
  final Color accent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final statusAsync = ref.watch(photoViewStatusProvider(profileId));
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.5),
            accent.withValues(alpha: 0.15),
            Colors.black.withValues(alpha: 0.4),
          ],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: Icon(
              Icons.lock_outline,
              size: 64,
              color: Colors.white.withValues(alpha: 0.4),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 32,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: statusAsync.when(
                data: (status) {
                  if (status == PhotoViewStatus.pending) {
                    return Text(
                      l.photoViewRequestPending,
                      textAlign: TextAlign.center,
                      style: AppTypography.titleMedium.copyWith(
                        color: Colors.white.withValues(alpha: 0.95),
                      ),
                    );
                  }
                  if (status == PhotoViewStatus.accepted ||
                      status == PhotoViewStatus.declined) {
                    return const SizedBox.shrink();
                  }
                  return FilledButton.icon(
                    onPressed: () => _requestToViewPhotos(context, ref),
                    icon: const Icon(Icons.visibility_outlined, size: 20),
                    label: Text(l.requestToViewPhotos),
                    style: FilledButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                    ),
                  );
                },
                loading: () => const SizedBox(
                  height: 48,
                  child: Center(
                    child: CircularProgressIndicator(color: Colors.white70),
                  ),
                ),
                error: (_, __) => FilledButton.icon(
                  onPressed: () => _requestToViewPhotos(context, ref),
                  icon: const Icon(Icons.visibility_outlined, size: 20),
                  label: Text(l.requestToViewPhotos),
                  style: FilledButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _requestToViewPhotos(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context)!;
    try {
      await ref.read(photoViewRequestRepositoryProvider).sendRequest(profileId);
      if (!context.mounted) return;
      ref.invalidate(photoViewStatusProvider(profileId));
      ref.invalidate(matrimonyProfileViewProvider(profileId));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.requestToViewPhotosSent),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.errorGeneric),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
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
            style: AppTypography.displayLarge.copyWith(
              color: accent,
              fontSize: 48,
            ),
          ),
        ),
      ),
    );
  }
}

class _NameRow extends StatelessWidget {
  const _NameRow({
    required this.profile,
    required this.accent,
    required this.isPremium,
  });
  final UserProfile profile;
  final Color accent;
  final bool isPremium;

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
        const SizedBox(width: 8),
        PremiumBadge(isPremium: isPremium, compact: true),
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.location_on_outlined,
          size: 16,
          color: onSurface.withValues(alpha: 0.5),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            parts.join(', '),
            style: AppTypography.bodyMedium.copyWith(
              color: onSurface.withValues(alpha: 0.65),
            ),
            softWrap: true,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
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
          .map(
            (e) =>
                _CompatDimension(_prettifyKey(e.key), (e.value * 100).round()),
          )
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accent.withValues(alpha: 0.12),
            accent.withValues(alpha: 0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: "Compatibility with you"
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.favorite_rounded, size: 22, color: accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Compatibility with you',
                      style: AppTypography.titleMedium.copyWith(
                        color: onSurface,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      loading
                          ? 'Calculating...'
                          : 'How close they are to what you\'re looking for',
                      style: AppTypography.bodySmall.copyWith(
                        color: onSurface.withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Hero: overall score
          Center(
            child: Column(
              children: [
                if (loading)
                  SizedBox(
                    width: 100,
                    height: 100,
                    child: CircularProgressIndicator(
                      strokeWidth: 6,
                      backgroundColor: accent.withValues(alpha: 0.12),
                      valueColor: AlwaysStoppedAnimation<Color>(accent),
                    ),
                  )
                else
                  _ScoreRing(score: score, accent: accent),
                const SizedBox(height: 10),
                if (!loading)
                  Text(
                    label,
                    style: AppTypography.titleSmall.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
          ),
          if (breakdown.isNotEmpty) ...[
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Icon(
                    Icons.bar_chart_rounded,
                    size: 18,
                    color: onSurface.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Closeness by dimension',
                    style: AppTypography.labelLarge.copyWith(
                      color: onSurface.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            ...breakdown.map(
              (b) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _BreakdownRow(
                  label: b.label,
                  score: b.score,
                  accent: accent,
                  onSurface: onSurface,
                ),
              ),
            ),
          ],
          if (matchReasons.isNotEmpty) ...[
            const SizedBox(height: 14),
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
    );
  }

  static String _prettifyKey(String key) {
    if (key.isEmpty) return key;
    return key.replaceAll('_', ' ').replaceAllMapped(
          RegExp(r'(^|\s)\w'),
          (m) => (m.group(0) ?? '').toUpperCase(),
        );
  }
}

class _ScoreRing extends StatelessWidget {
  const _ScoreRing({required this.score, required this.accent});
  final int score;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final progress = (score / 100).clamp(0.0, 1.0);
    return SizedBox(
      width: 100,
      height: 100,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 100,
            height: 100,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 8,
              backgroundColor: accent.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation<Color>(accent),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$score',
                style: AppTypography.headlineMedium.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w800,
                  height: 1.0,
                ),
              ),
              Text(
                '%',
                style: AppTypography.titleSmall.copyWith(
                  color: accent.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
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
    final progress = (score / 100).clamp(0.0, 1.0);
    final barColor = score >= 75
        ? accent
        : (score >= 50 ? Theme.of(context).colorScheme.primary : onSurface.withValues(alpha: 0.4));
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTypography.bodyMedium.copyWith(
              color: onSurface.withValues(alpha: 0.85),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: accent.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 40,
          child: Text(
            '$score%',
            style: AppTypography.titleSmall.copyWith(
              color: barColor,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

// ── Photos section ───────────────────────────────────────────────────────

/// Shown when profile owner has hidden photos and viewer doesn't have access.
class _PhotosLockedSection extends ConsumerWidget {
  const _PhotosLockedSection({required this.profileId, required this.accent});
  final String profileId;
  final Color accent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final statusAsync = ref.watch(photoViewStatusProvider(profileId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionTitle('Photos', onSurface),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          decoration: BoxDecoration(
            color: onSurface.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: onSurface.withValues(alpha: 0.12)),
          ),
          child: Column(
            children: [
              Icon(
                Icons.lock_outline,
                size: 40,
                color: onSurface.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 12),
              Text(
                l.photosLocked,
                style: AppTypography.titleMedium.copyWith(color: onSurface),
              ),
              const SizedBox(height: 4),
              Text(
                l.photosLockedHint,
                style: AppTypography.bodySmall.copyWith(
                  color: onSurface.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              statusAsync.when(
                data: (status) {
                  if (status == PhotoViewStatus.pending) {
                    return Text(
                      l.photoViewRequestPending,
                      style: AppTypography.bodyMedium.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w500,
                      ),
                    );
                  }
                  if (status == PhotoViewStatus.accepted ||
                      status == PhotoViewStatus.declined) {
                    return const SizedBox.shrink();
                  }
                  return FilledButton.icon(
                    onPressed: () => _requestToViewPhotos(context, ref),
                    icon: const Icon(Icons.visibility_outlined, size: 20),
                    label: Text(l.requestToViewPhotos),
                    style: FilledButton.styleFrom(backgroundColor: accent),
                  );
                },
                loading: () => const SizedBox(
                  height: 40,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, __) => FilledButton.icon(
                  onPressed: () => _requestToViewPhotos(context, ref),
                  icon: const Icon(Icons.visibility_outlined, size: 20),
                  label: Text(l.requestToViewPhotos),
                  style: FilledButton.styleFrom(backgroundColor: accent),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _requestToViewPhotos(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context)!;
    try {
      await ref.read(photoViewRequestRepositoryProvider).sendRequest(profileId);
      if (!context.mounted) return;
      ref.invalidate(photoViewStatusProvider(profileId));
      ref.invalidate(matrimonyProfileViewProvider(profileId));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.requestToViewPhotosSent),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.errorGeneric),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }
}

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
                onTap: () => _openPhotoGallery(context, photos, i),
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
                itemBuilder: (_, i) => GestureDetector(
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _openPhotoGallery(ctx, photos, i);
                  },
                  child: ClipRRect(
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
              color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.08),
              child: Center(
                child: Text(
                  name.isNotEmpty ? name[0] : '?',
                  style: AppTypography.headlineMedium.copyWith(
                    color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.4),
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
    final l = AppLocalizations.of(context)!;
    final rows = <_DetailRow>[];

    if (profile.gender != null) {
      rows.add(_DetailRow(l.genderQuestion, profile.gender!));
    }
    if (profile.age != null) {
      rows.add(_DetailRow(l.ageRange, '${profile.age} years'));
    }
    if (profile.dateOfBirth != null) {
      rows.add(_DetailRow(l.dateOfBirth, profile.dateOfBirth!));
    }
    if (mat?.heightCm != null) {
      rows.add(_DetailRow(l.height, _formatHeight(mat.heightCm as int)));
    }
    if (mat?.maritalStatus != null) {
      rows.add(
        _DetailRow(l.maritalStatus, _titleCase(mat.maritalStatus as String)),
      );
    }
    if (mat?.religion != null) {
      rows.add(_DetailRow(l.religion, mat.religion as String));
    }
    if (mat?.casteOrCommunity != null) {
      rows.add(_DetailRow(l.communityLabel, mat.casteOrCommunity as String));
    }
    if (profile.motherTongue != null) {
      rows.add(_DetailRow(l.motherTongue, profile.motherTongue!));
    }
    if (profile.languagesSpoken.isNotEmpty) {
      rows.add(
        _DetailRow(l.languagesLabel, profile.languagesSpoken.join(', ')),
      );
    }
    if (profile.currentCity != null || profile.currentCountry != null) {
      rows.add(_DetailRow(l.locationLabel, profile.displayLocation));
    }
    if (profile.originCity != null || profile.originCountry != null) {
      final parts = [
        profile.originCity,
        profile.originCountry,
      ].whereType<String>().where((s) => s.isNotEmpty);
      if (parts.isNotEmpty) {
        rows.add(_DetailRow(l.originLabel, parts.join(', ')));
      }
    }

    if (rows.isEmpty) return const SizedBox.shrink();
    return _InfoCard(
      title: l.basicDetails,
      icon: Icons.person_outline,
      rows: rows,
      accent: accent,
      onSurface: onSurface,
    );
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
  const _EducationCareerCard({
    required this.mat,
    required this.onSurface,
    required this.accent,
  });
  final dynamic mat;
  final Color onSurface;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final rows = <_DetailRow>[];
    // Prefer educationEntries (degree, institution, year, grading), then fallback to legacy degree/institution
    final entries = mat.educationEntries;
    if (entries != null && entries.isNotEmpty) {
      for (final e in entries) {
        if (e.degree != null) {
          rows.add(_DetailRow(l.degreeLabel, e.degree!));
        }
        if (e.institution != null) {
          rows.add(_DetailRow(l.institutionLabel, e.institution!));
        }
        if (e.graduationYear != null) {
          rows.add(_DetailRow(l.yearOfGraduation, '${e.graduationYear}'));
        }
        if (e.scoreCountry != null || e.scoreType != null) {
          final grade = [
            e.scoreCountry,
            e.scoreType,
          ].whereType<String>().join(' – ');
          if (grade.isNotEmpty) {
            rows.add(_DetailRow(l.gradeClassification, grade));
          }
        }
      }
    } else {
      if (mat.educationDegree != null) {
        rows.add(_DetailRow(l.educationLevel, mat.educationDegree));
      }
      if (mat.educationInstitution != null) {
        rows.add(_DetailRow(l.institutionLabel, mat.educationInstitution));
      }
    }
    if (mat.occupation != null) {
      rows.add(_DetailRow(l.occupation, mat.occupation));
    }
    if (mat.employer != null) {
      rows.add(_DetailRow(l.employer, mat.employer));
    }
    if (mat.industry != null) {
      rows.add(_DetailRow(l.industry, mat.industry));
    }
    if (mat.incomeRange != null) {
      final inc = mat.incomeRange;
      final label = [
        inc.minLabel,
        inc.maxLabel,
      ].whereType<String>().join(' – ');
      if (label.isNotEmpty) {
        rows.add(_DetailRow(l.income, '${inc.currency ?? ''} $label'.trim()));
      }
    }
    if (mat.workLocation != null) {
      rows.add(_DetailRow(l.workLocationQuestion, mat.workLocation));
    }
    if (mat.settledAbroad != null) {
      rows.add(_DetailRow(l.settledAbroadQuestion, mat.settledAbroad));
    }
    if (mat.willingToRelocate != null) {
      rows.add(_DetailRow(l.willingToRelocate, mat.willingToRelocate));
    }
    if (mat.aboutCareer != null) {
      rows.add(_DetailRow(l.aboutCareer, mat.aboutCareer));
    }
    if (rows.isEmpty) return const SizedBox.shrink();
    return _InfoCard(
      title: l.educationAndCareerTitle,
      icon: Icons.school_outlined,
      rows: rows,
      accent: accent,
      onSurface: onSurface,
    );
  }
}

/// When parentGuardianRole flag is on: show that profile is managed by parent/guardian/etc.
class _ManagedByBanner extends StatelessWidget {
  const _ManagedByBanner({required this.role, required this.onSurface});
  final ProfileRole role;
  final Color onSurface;

  static String _label(BuildContext context, ProfileRole r) {
    final l = AppLocalizations.of(context)!;
    switch (r) {
      case ProfileRole.parent:
        return l.profileManagedByParent;
      case ProfileRole.guardian:
        return l.profileManagedByGuardian;
      case ProfileRole.sibling:
        return l.profileManagedBySibling;
      case ProfileRole.friend:
        return l.profileManagedByFriend;
      case ProfileRole.self:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = _label(context, role);
    if (label.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: onSurface.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: onSurface.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.family_restroom,
            size: 18,
            color: onSurface.withValues(alpha: 0.6),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: onSurface.withValues(alpha: 0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _FamilyCard extends StatelessWidget {
  const _FamilyCard({
    required this.mat,
    required this.onSurface,
    required this.accent,
  });
  final dynamic mat;
  final Color onSurface;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final fam = mat.familyDetails;
    if (fam == null) return const SizedBox.shrink();
    final rows = <_DetailRow>[];
    if (fam.householdIncome != null) {
      rows.add(_DetailRow('Household income', fam.householdIncome));
    }
    if (fam.familyType != null) {
      rows.add(_DetailRow('Family type', fam.familyType));
    }
    if (fam.familyValues != null) {
      rows.add(_DetailRow('Family values', fam.familyValues));
    }
    if (fam.familyLocation != null) {
      rows.add(_DetailRow('Family location', fam.familyLocation));
    }
    if (fam.fatherOccupation != null) {
      rows.add(_DetailRow('Father\'s occupation', fam.fatherOccupation));
    }
    if (fam.motherOccupation != null) {
      rows.add(_DetailRow('Mother\'s occupation', fam.motherOccupation));
    }
    if (fam.fatherAge != null) {
      rows.add(_DetailRow('Father\'s age', fam.fatherAge));
    }
    if (fam.motherAge != null) {
      rows.add(_DetailRow('Mother\'s age', fam.motherAge));
    }
    if (fam.brothers != null || fam.sisters != null) {
      final parts = <String>[];
      if (fam.brothers != null) {
        parts.add('${fam.brothers} brother(s)');
      }
      if (fam.sisters != null) {
        parts.add('${fam.sisters} sister(s)');
      }
      if (parts.isNotEmpty) {
        rows.add(_DetailRow('Siblings', parts.join(', ')));
      }
    } else if (fam.siblingsCount != null) {
      final married = fam.siblingsMarried;
      final siblingsText = married != null
          ? '${fam.siblingsCount} ($married married)'
          : '${fam.siblingsCount}';
      rows.add(_DetailRow('Siblings', siblingsText));
    }
    if (fam.familyExpectations != null && fam.familyExpectations!.isNotEmpty) {
      rows.add(_DetailRow('Family expectations', fam.familyExpectations!));
    }
    if (rows.isEmpty) return const SizedBox.shrink();
    return _InfoCard(
      title: AppLocalizations.of(context)!.familyTitle,
      icon: Icons.family_restroom,
      rows: rows,
      accent: accent,
      onSurface: onSurface,
    );
  }
}

class _LifestyleCard extends StatelessWidget {
  const _LifestyleCard({
    required this.mat,
    required this.onSurface,
    required this.accent,
  });
  final dynamic mat;
  final Color onSurface;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final rows = <_DetailRow>[];
    if (mat.diet != null) {
      rows.add(_DetailRow(l.diet, mat.diet));
    }
    if (mat.drinking != null) {
      rows.add(_DetailRow(l.drinkQuestion, mat.drinking));
    }
    if (mat.smoking != null) {
      rows.add(_DetailRow(l.smokeQuestion, mat.smoking));
    }
    if (mat.exercise != null) {
      rows.add(_DetailRow(l.exerciseQuestion, mat.exercise));
    }
    if (mat.pets != null) {
      rows.add(_DetailRow(l.petsQuestion, mat.pets));
    }
    if (mat.disability != null) {
      rows.add(_DetailRow(l.disabilityQuestion, mat.disability));
    }
    if (rows.isEmpty) return const SizedBox.shrink();
    return _InfoCard(
      title: l.lifestyleTitleSection,
      icon: Icons.spa_outlined,
      rows: rows,
      accent: accent,
      onSurface: onSurface,
    );
  }
}

class _HoroscopeCard extends StatelessWidget {
  const _HoroscopeCard({
    required this.mat,
    required this.onSurface,
    required this.accent,
  });
  final dynamic mat;
  final Color onSurface;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final hor = mat.horoscope;
    if (hor == null) return const SizedBox.shrink();
    final rows = <_DetailRow>[];
    if (hor.dateOfBirth != null) {
      rows.add(_DetailRow(l.dateOfBirth, hor.dateOfBirth));
    }
    if (hor.timeOfBirth != null) {
      rows.add(_DetailRow(l.birthTimeQuestion, hor.timeOfBirth));
    }
    if (hor.birthPlace != null) {
      rows.add(_DetailRow(l.birthPlaceQuestion, hor.birthPlace));
    }
    if (hor.manglik != null) {
      rows.add(_DetailRow(l.manglikQuestion, hor.manglik));
    }
    if (hor.rashi != null) {
      rows.add(_DetailRow(l.rashiQuestion, hor.rashi));
    }
    if (hor.nakshatra != null) {
      rows.add(_DetailRow(l.nakshatraQuestion, hor.nakshatra));
    }
    if (hor.gotra != null) {
      rows.add(_DetailRow(l.gotraQuestion, hor.gotra));
    }
    if (hor.horoscopeDocUrl != null) {
      rows.add(_DetailRow(l.horoscopeQuestion, '✓'));
    }
    if (rows.isEmpty) return const SizedBox.shrink();
    return _InfoCard(
      title: AppLocalizations.of(context)!.horoscopeTitle,
      icon: Icons.auto_awesome,
      rows: rows,
      accent: accent,
      onSurface: onSurface,
    );
  }
}

class _PartnerPrefsCard extends StatelessWidget {
  const _PartnerPrefsCard({
    required this.prefs,
    required this.onSurface,
    required this.accent,
  });
  final dynamic prefs;
  final Color onSurface;
  final Color accent;

  static bool _strict(dynamic prefs, String key) {
    final map = prefs.strictFilters as Map<String, dynamic>?;
    return map != null && map[key] == true;
  }

  String _val(String value, String strictKey, String strictSuffix) {
    return _strict(prefs, strictKey) ? '$value$strictSuffix' : value;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final rows = <_DetailRow>[];
    rows.add(_DetailRow(l.ageRange, '${prefs.ageMin} – ${prefs.ageMax}'));
    if (prefs.heightMinCm != null || prefs.heightMaxCm != null) {
      final hMin = prefs.heightMinCm != null
          ? '${prefs.heightMinCm} cm'
          : l.anyOption;
      final hMax = prefs.heightMaxCm != null
          ? '${prefs.heightMaxCm} cm'
          : l.anyOption;
      rows.add(_DetailRow(l.height, '$hMin – $hMax'));
    }
    final bodyVal = (prefs.preferredBodyTypes as List?)?.isNotEmpty == true
        ? (prefs.preferredBodyTypes as List).join(', ')
        : l.anyOption;
    rows.add(_DetailRow(
      l.bodyTypeQuestion,
      _val(bodyVal, 'bodyType', l.partnerPrefStrictSuffix),
    ));
    if (prefs.preferredReligions != null &&
        (prefs.preferredReligions as List).isNotEmpty) {
      rows.add(
        _DetailRow(
          l.religion,
          _val(
            (prefs.preferredReligions as List).join(', '),
            'religion',
            l.partnerPrefStrictSuffix,
          ),
        ),
      );
    }
    if (prefs.preferredCommunities != null &&
        (prefs.preferredCommunities as List).isNotEmpty) {
      rows.add(
        _DetailRow(
          l.communityLabel,
          (prefs.preferredCommunities as List).join(', '),
        ),
      );
    }
    if (prefs.preferredMotherTongues != null &&
        (prefs.preferredMotherTongues as List).isNotEmpty) {
      rows.add(
        _DetailRow(
          l.motherTongue,
          _val(
            (prefs.preferredMotherTongues as List).join(', '),
            'motherTongue',
            l.partnerPrefStrictSuffix,
          ),
        ),
      );
    }
    if (prefs.educationPreference != null) {
      rows.add(
        _DetailRow(
          l.educationLevel,
          _val(
            prefs.educationPreference!,
            'education',
            l.partnerPrefStrictSuffix,
          ),
        ),
      );
    }
    if (prefs.occupationPreference != null) {
      rows.add(_DetailRow(l.occupation, prefs.occupationPreference!));
    }
    if (prefs.incomePreference != null) {
      rows.add(_DetailRow(
        l.income,
        _val(prefs.incomePreference!, 'income', l.partnerPrefStrictSuffix),
      ));
    }
    if (prefs.maritalStatusPreference != null &&
        (prefs.maritalStatusPreference as List).isNotEmpty) {
      rows.add(
        _DetailRow(
          l.maritalStatus,
          _val(
            (prefs.maritalStatusPreference as List).join(', '),
            'maritalStatus',
            l.partnerPrefStrictSuffix,
          ),
        ),
      );
    }
    if (prefs.preferredLocations != null &&
        (prefs.preferredLocations as List).isNotEmpty) {
      rows.add(
        _DetailRow(
          l.partnerPrefLocations,
          (prefs.preferredLocations as List).join(', '),
        ),
      );
    }
    if (prefs.preferredCountries != null &&
        (prefs.preferredCountries as List).isNotEmpty) {
      rows.add(
        _DetailRow(
          l.partnerPrefCountries,
          (prefs.preferredCountries as List).join(', '),
        ),
      );
    }
    if (prefs.settledAbroadPreference != null) {
      rows.add(
        _DetailRow(
          l.partnerPrefSettledAbroad,
          _val(
            prefs.settledAbroadPreference!,
            'settledAbroad',
            l.partnerPrefStrictSuffix,
          ),
        ),
      );
    }
    if (prefs.dietPreference != null) {
      rows.add(_DetailRow(
        l.diet,
        _val(prefs.dietPreference!, 'diet', l.partnerPrefStrictSuffix),
      ));
    }
    if (prefs.drinkingPreference != null) {
      rows.add(
        _DetailRow(
          l.drinkQuestion,
          _val(
            prefs.drinkingPreference!,
            'drinking',
            l.partnerPrefStrictSuffix,
          ),
        ),
      );
    }
    if (prefs.smokingPreference != null) {
      rows.add(
        _DetailRow(
          l.smokeQuestion,
          _val(
            prefs.smokingPreference!,
            'smoking',
            l.partnerPrefStrictSuffix,
          ),
        ),
      );
    }
    if (prefs.horoscopeMatchPreferred == true) {
      rows.add(_DetailRow(l.partnerPrefHoroscopeMatch, l.partnerPrefPreferred));
    }
    if (rows.isEmpty) return const SizedBox.shrink();
    return _InfoCard(
      title: AppLocalizations.of(context)!.lookingForTitle,
      icon: Icons.search,
      rows: rows,
      accent: accent,
      onSurface: onSurface,
    );
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
          ...rows.map(
            (r) => Padding(
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
            ),
          ),
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

// ─────────────────────────────────────────────────────────────────────────────
//  SECTION NAV BAR
// ─────────────────────────────────────────────────────────────────────────────

class _SectionNavBar extends StatelessWidget {
  const _SectionNavBar({
    required this.items,
    required this.onTap,
    required this.accent,
  });

  final List<({String label, GlobalKey key})> items;
  final void Function(GlobalKey) onTap;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.4),
            width: 0.5,
          ),
        ),
      ),
      child: SingleChildScrollView(
        primary: false,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
        child: Row(
          children: items
              .map(
                (item) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _NavChip(
                    label: item.label,
                    accent: accent,
                    onTap: () => onTap(item.key),
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _NavChip extends StatelessWidget {
  const _NavChip({
    required this.label,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 5),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: accent.withValues(alpha: 0.22),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: accent,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
      ),
    );
  }
}

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
  dims.add(
    _CompatDimension('Profile completeness', profileScore.clamp(0, 100)),
  );

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
