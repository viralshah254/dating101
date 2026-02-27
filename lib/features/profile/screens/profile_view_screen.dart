import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/mode/app_mode.dart';
import '../../../core/mode/mode_provider.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../domain/models/user_profile.dart';
import '../../../l10n/app_localizations.dart';

final _profileProvider = FutureProvider<UserProfile?>((ref) async {
  final repo = ref.watch(profileRepositoryProvider);
  return repo.getMyProfile();
});

class ProfileViewScreen extends ConsumerWidget {
  const ProfileViewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(_profileProvider);
    final mode = ref.watch(appModeProvider) ?? AppMode.matrimony;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: profileAsync.when(
        loading: () => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: cs.primary),
              const SizedBox(height: 20),
              Text(
                'Loading profile…',
                style: AppTypography.bodyMedium.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
        error: (e, _) {
          final l = AppLocalizations.of(context)!;
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: 48,
                    color: cs.error.withValues(alpha: 0.8),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l.errorLoadingProfile('$e'),
                    style: AppTypography.bodyLarge.copyWith(
                      color: cs.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => ref.invalidate(_profileProvider),
                    icon: const Icon(Icons.refresh, size: 20),
                    label: Text(l.retry),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        data: (profile) {
          if (profile == null) {
            final l = AppLocalizations.of(context)!;
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.person_add_rounded,
                      size: 64,
                      color: cs.primary.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      l.noProfileYet,
                      style: AppTypography.headlineSmall.copyWith(
                        color: cs.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Create your profile to get started.',
                      style: AppTypography.bodyMedium.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.65),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),
                    FilledButton(
                      onPressed: () => context.push('/profile-setup'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(l.createProfile),
                    ),
                  ],
                ),
              ),
            );
          }
          return _ProfileBody(
            profile: profile,
            mode: mode,
            onRefresh: () => ref.invalidate(_profileProvider),
          );
        },
      ),
    );
  }
}

class _ProfileBody extends StatelessWidget {
  const _ProfileBody({
    required this.profile,
    required this.mode,
    required this.onRefresh,
  });

  final UserProfile profile;
  final AppMode mode;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final completeness = profile.profileCompleteness;
    final pct = (completeness * 100).round();
    final missing = _computeMissing(profile, mode);

    return CustomScrollView(
      slivers: [
        // Header with photo + name
        SliverToBoxAdapter(child: _buildHeader(context, cs, pct)),
        // Completeness card
        if (pct < 100)
          SliverToBoxAdapter(
            child: _CompletenessCard(
              pct: pct,
              missing: missing,
              onTap: () => _editSection(context, 'basic'),
            ),
          ),
        // Sections — generous spacing, same padding as completeness card
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              const SizedBox(height: 12),
              _buildBasicDetailsSection(context),
              if (mode.isMatrimony) _buildReligionSection(context),
              _buildPhysicalSection(context),
              if (mode.isMatrimony) _buildEducationCareerSection(context),
              _buildLifestyleSection(context),
              _buildInterestsSection(context),
              if (mode.isMatrimony) _buildFamilySection(context),
              if (mode.isMatrimony) _buildHoroscopeSection(context),
              _buildAboutMeSection(context),
              if (mode.isMatrimony) _buildPreferencesSection(context),
              _buildPhotosSection(context),
              const SizedBox(height: 48),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, ColorScheme cs, int pct) {
    final hasPhoto = profile.photoUrls.isNotEmpty;
    final progressColor = pct >= 80 ? AppColors.indiaGreen : AppColors.saffron;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.splashPeach.withValues(alpha: 0.5), cs.surface],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0.0, 0.6],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Nav bar — minimal, centered edit
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Spacer(),
                  Text(
                    'My profile',
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => _editSection(context, 'basic'),
                    icon: const Icon(Icons.edit_outlined, size: 22),
                  ),
                ],
              ),
            ),
            // Avatar with completion ring
            SizedBox(
              width: 112,
              height: 112,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 112,
                    height: 112,
                    child: CircularProgressIndicator(
                      value: pct / 100,
                      strokeWidth: 3,
                      backgroundColor: cs.outlineVariant.withValues(
                        alpha: 0.25,
                      ),
                      valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                    ),
                  ),
                  Container(
                    width: 98,
                    height: 98,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: progressColor.withValues(alpha: 0.4),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: progressColor.withValues(alpha: 0.15),
                          blurRadius: 16,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: hasPhoto
                          ? _buildImage(profile.photoUrls.first)
                          : Container(
                              color: AppColors.saffron.withValues(alpha: 0.12),
                              child: Icon(
                                Icons.person_rounded,
                                size: 48,
                                color: AppColors.saffron,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              profile.name,
              style: AppTypography.headlineMedium.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            if (profile.displayLocation.isNotEmpty)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: cs.onSurface.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    profile.displayLocation,
                    style: AppTypography.bodyMedium.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.65),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 12),
            // Completeness pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: progressColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: progressColor.withValues(alpha: 0.25),
                ),
              ),
              child: Text(
                '$pct% complete',
                style: AppTypography.labelLarge.copyWith(
                  color: progressColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ── Per-section completion (0–100) ─────────────────────────────────

  int _sectionPctBasic() {
    int filled = 0;
    if (profile.gender != null) filled++;
    if (profile.dateOfBirth != null) filled++;
    if (profile.displayLocation.isNotEmpty) filled++;
    if (profile.originCity != null) filled++;
    if (profile.motherTongue != null) filled++;
    if (profile.languagesSpoken.isNotEmpty) filled++;
    return (filled * 100 / 6).round().clamp(0, 100);
  }

  int _sectionPctReligion() {
    final mat = profile.matrimonyExtensions;
    if (mat == null) return 0;
    int filled = 0;
    if (mat.religion != null) filled++;
    if (mat.casteOrCommunity != null) filled++;
    if (mat.maritalStatus != null) filled++;
    return (filled * 100 / 3).round().clamp(0, 100);
  }

  int _sectionPctPhysical() {
    final mat = profile.matrimonyExtensions;
    return (mat?.heightCm != null) ? 100 : 0;
  }

  int _sectionPctEducationCareer() {
    final mat = profile.matrimonyExtensions;
    if (mat == null) return 0;
    int filled = 0;
    if (mat.educationDegree != null) filled++;
    if (mat.educationInstitution != null) filled++;
    if (mat.occupation != null) filled++;
    if (mat.employer != null) filled++;
    if (mat.industry != null) filled++;
    if (mat.incomeRange != null) filled++;
    return (filled * 100 / 6).round().clamp(0, 100);
  }

  int _sectionPctLifestyle() {
    final mat = profile.matrimonyExtensions;
    if (mat == null) return 0;
    int filled = 0;
    if (mat.diet != null) filled++;
    if (mat.drinking != null) filled++;
    if (mat.smoking != null) filled++;
    return (filled * 100 / 3).round().clamp(0, 100);
  }

  int _sectionPctInterests() => profile.interests.isNotEmpty ? 100 : 0;

  int _sectionPctFamily() {
    final fam = profile.matrimonyExtensions?.familyDetails;
    if (fam == null) return 0;
    int filled = 0;
    if (fam.familyType != null) filled++;
    if (fam.familyValues != null) filled++;
    if (fam.fatherOccupation != null) filled++;
    if (fam.motherOccupation != null) filled++;
    if (fam.siblingsCount != null) filled++;
    return (filled * 100 / 5).round().clamp(0, 100);
  }

  int _sectionPctHoroscope() {
    final hor = profile.matrimonyExtensions?.horoscope;
    if (hor == null) return 0;
    int filled = 0;
    if (hor.manglik != null) filled++;
    if (hor.nakshatra != null) filled++;
    if (hor.timeOfBirth != null) filled++;
    if (hor.birthPlace != null) filled++;
    return (filled * 100 / 4).round().clamp(0, 100);
  }

  int _sectionPctAboutMe() => profile.aboutMe.isNotEmpty ? 100 : 0;

  int _sectionPctPreferences() {
    final prefs = profile.partnerPreferences;
    if (prefs == null) return 0;
    int filled = 0;
    if (prefs.ageMin != 0 || prefs.ageMax != 0) filled++;
    if (prefs.preferredReligions?.isNotEmpty == true) filled++;
    if (prefs.educationPreference != null) filled++;
    if (prefs.maritalStatusPreference?.isNotEmpty == true) filled++;
    if (prefs.dietPreference != null) filled++;
    if (prefs.preferredLocations?.isNotEmpty == true) filled++;
    return (filled * 100 / 6).round().clamp(0, 100);
  }

  int _sectionPctPhotos() => profile.photoUrls.isNotEmpty ? 100 : 0;

  // ── Sections (compact: title + % complete + edit) ────────────────────

  Widget _buildBasicDetailsSection(BuildContext context) {
    return _SectionSummaryCard(
      title: AppLocalizations.of(context)!.basicDetails,
      icon: Icons.badge_outlined,
      pct: _sectionPctBasic(),
      onEdit: () => _editSection(context, 'basic'),
    );
  }

  Widget _buildReligionSection(BuildContext context) {
    return _SectionSummaryCard(
      title: AppLocalizations.of(context)!.religionAndCommunity,
      icon: Icons.temple_hindu_outlined,
      pct: _sectionPctReligion(),
      onEdit: () => _editSection(context, 'religion'),
    );
  }

  Widget _buildPhysicalSection(BuildContext context) {
    return _SectionSummaryCard(
      title: AppLocalizations.of(context)!.physicalAttributes,
      icon: Icons.accessibility_new_outlined,
      pct: _sectionPctPhysical(),
      onEdit: () => _editSection(context, 'physical'),
    );
  }

  Widget _buildEducationCareerSection(BuildContext context) {
    return _SectionSummaryCard(
      title: AppLocalizations.of(context)!.educationAndCareer,
      icon: Icons.school_outlined,
      pct: _sectionPctEducationCareer(),
      onEdit: () => _editSection(context, 'education-career'),
    );
  }

  Widget _buildLifestyleSection(BuildContext context) {
    return _SectionSummaryCard(
      title: AppLocalizations.of(context)!.lifestyleAndHabits,
      icon: Icons.self_improvement_outlined,
      pct: _sectionPctLifestyle(),
      onEdit: () => _editSection(context, 'lifestyle'),
    );
  }

  Widget _buildInterestsSection(BuildContext context) {
    return _SectionSummaryCard(
      title: AppLocalizations.of(context)!.interestsAndHobbiesSection,
      icon: Icons.interests_outlined,
      pct: _sectionPctInterests(),
      onEdit: () => _editSection(context, 'interests'),
    );
  }

  Widget _buildFamilySection(BuildContext context) {
    return _SectionSummaryCard(
      title: AppLocalizations.of(context)!.familySection,
      icon: Icons.family_restroom,
      pct: _sectionPctFamily(),
      onEdit: () => _editSection(context, 'family'),
    );
  }

  Widget _buildHoroscopeSection(BuildContext context) {
    return _SectionSummaryCard(
      title: AppLocalizations.of(context)!.horoscopeSection,
      icon: Icons.auto_awesome_outlined,
      pct: _sectionPctHoroscope(),
      onEdit: () => _editSection(context, 'horoscope'),
    );
  }

  Widget _buildAboutMeSection(BuildContext context) {
    return _SectionSummaryCard(
      title: AppLocalizations.of(context)!.aboutMeSection,
      icon: Icons.edit_note_outlined,
      pct: _sectionPctAboutMe(),
      onEdit: () => _editSection(context, 'about'),
      subtitle: profile.aboutMe.isNotEmpty
          ? (profile.aboutMe.length > 80
                ? '${profile.aboutMe.substring(0, 80).trim()}…'
                : profile.aboutMe)
          : null,
    );
  }

  Widget _buildPreferencesSection(BuildContext context) {
    return _SectionSummaryCard(
      title: AppLocalizations.of(context)!.partnerPreferencesSection,
      icon: Icons.tune,
      pct: _sectionPctPreferences(),
      onEdit: () => _editSection(context, 'preferences'),
    );
  }

  Widget _buildPhotosSection(BuildContext context) {
    return _SectionSummaryCard(
      title: AppLocalizations.of(context)!.profileBuilderPhotos,
      icon: Icons.photo_library_outlined,
      pct: _sectionPctPhotos(),
      onEdit: () => _editSection(context, 'photos'),
    );
  }

  // ── Navigation ────────────────────────────────────────────────────

  Future<void> _editSection(BuildContext context, String sectionId) async {
    await context.push(
      '/profile-edit?section=${Uri.encodeComponent(sectionId)}',
    );
    onRefresh();
  }

  // ── Helpers ───────────────────────────────────────────────────────

  Widget _buildImage(String url) {
    if (url.startsWith('http')) {
      return Image.network(url, fit: BoxFit.cover);
    }
    return Image.file(File(url), fit: BoxFit.cover);
  }

  static List<String> _computeMissing(UserProfile p, AppMode mode) {
    final missing = <String>[];
    if (p.photoUrls.isEmpty) missing.add('Photos');
    if (p.aboutMe.isEmpty) missing.add('About me');
    if (p.interests.isEmpty) missing.add('Interests');
    if (p.motherTongue == null) missing.add('Mother tongue');
    if (p.currentCity == null) missing.add('Location');
    if (mode.isMatrimony) {
      final mat = p.matrimonyExtensions;
      if (mat == null) {
        missing.addAll([
          'Religion',
          'Education',
          'Career',
          'Family',
          'Horoscope',
        ]);
      } else {
        if (mat.religion == null) missing.add('Religion');
        if (mat.educationDegree == null) missing.add('Education');
        if (mat.occupation == null) missing.add('Career');
        if (mat.heightCm == null) missing.add('Height');
        if (mat.diet == null) missing.add('Lifestyle');
        if (mat.familyDetails == null) missing.add('Family details');
        if (mat.horoscope == null) missing.add('Horoscope');
      }
      if (p.partnerPreferences == null) missing.add('Partner preferences');
    }
    return missing;
  }
}

// ── Section summary card (title + % complete + edit) ─────────────────

class _SectionSummaryCard extends StatelessWidget {
  const _SectionSummaryCard({
    required this.title,
    required this.icon,
    required this.pct,
    required this.onEdit,
    this.subtitle,
  });

  final String title;
  final IconData icon;
  final int pct;
  final VoidCallback onEdit;

  /// Optional preview text (e.g. About Me bio snippet).
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final accent = pct >= 100 ? AppColors.indiaGreen : AppColors.saffron;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
        elevation: 0,
        shadowColor: Colors.black.withValues(alpha: 0.06),
        child: InkWell(
          onTap: onEdit,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: cs.outlineVariant.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(icon, size: 24, color: accent),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        title,
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Text(
                        '$pct%',
                        style: AppTypography.labelMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          color: accent,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: cs.onSurface.withValues(alpha: 0.35),
                    ),
                  ],
                ),
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    subtitle!,
                    style: AppTypography.bodySmall.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.7),
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Completeness card ─────────────────────────────────────────────

class _CompletenessCard extends StatelessWidget {
  const _CompletenessCard({
    required this.pct,
    required this.missing,
    required this.onTap,
  });

  final int pct;
  final List<String> missing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final progressColor = pct >= 80 ? AppColors.indiaGreen : AppColors.saffron;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  progressColor.withValues(alpha: 0.08),
                  progressColor.withValues(alpha: 0.03),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: progressColor.withValues(alpha: 0.2)),
              boxShadow: [
                BoxShadow(
                  color: progressColor.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 52,
                  height: 52,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CircularProgressIndicator(
                        value: pct / 100,
                        strokeWidth: 4,
                        backgroundColor: cs.outlineVariant.withValues(
                          alpha: 0.25,
                        ),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          progressColor,
                        ),
                      ),
                      Center(
                        child: Icon(
                          pct >= 100
                              ? Icons.check_circle_rounded
                              : Icons.person_rounded,
                          size: 24,
                          color: progressColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pct >= 100
                            ? 'Profile complete'
                            : 'Complete your profile',
                        style: AppTypography.titleSmall.copyWith(
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        missing.isEmpty
                            ? (pct >= 100
                                  ? 'Looking good!'
                                  : 'Add a few more details for better matches.')
                            : 'Add: ${missing.take(3).join(', ')}${missing.length > 3 ? '…' : ''}',
                        style: AppTypography.bodySmall.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.65),
                          height: 1.35,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.arrow_forward_ios, size: 14, color: progressColor),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
