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
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error loading profile: $e')),
        data: (profile) {
          if (profile == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('No profile yet', style: AppTypography.headlineMedium),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => context.push('/profile-setup'),
                    child: const Text('Create profile'),
                  ),
                ],
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
        SliverToBoxAdapter(
          child: _buildHeader(context, cs, pct),
        ),
        // Completeness card
        if (pct < 100)
          SliverToBoxAdapter(
            child: _CompletenessCard(
              pct: pct,
              missing: missing,
              onTap: () => _editSection(context, 0),
            ),
          ),
        // Sections — generous spacing so each section reads as its own block
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              const SizedBox(height: 8),
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
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.saffron.withValues(alpha: 0.15),
            cs.surface,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Nav bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => _editSection(context, 0),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Edit all'),
                  ),
                ],
              ),
            ),
            // Avatar
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.saffron, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.saffron.withValues(alpha: 0.2),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipOval(
                child: hasPhoto
                    ? _buildImage(profile.photoUrls.first)
                    : Container(
                        color: AppColors.saffron.withValues(alpha: 0.15),
                        child: Icon(Icons.person, size: 50, color: AppColors.saffron),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              profile.name,
              style: AppTypography.headlineMedium.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            if (profile.displayLocation.isNotEmpty)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.location_on_outlined, size: 14, color: cs.onSurface.withValues(alpha: 0.6)),
                  const SizedBox(width: 4),
                  Text(
                    profile.displayLocation,
                    style: AppTypography.bodySmall.copyWith(color: cs.onSurface.withValues(alpha: 0.6)),
                  ),
                ],
              ),
            const SizedBox(height: 8),
            // Completeness badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: pct >= 80
                    ? AppColors.indiaGreen.withValues(alpha: 0.1)
                    : AppColors.saffron.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$pct% complete',
                style: AppTypography.labelMedium.copyWith(
                  color: pct >= 80 ? AppColors.indiaGreen : AppColors.saffronDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 20),
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
      title: 'Basic Details',
      icon: Icons.badge_outlined,
      pct: _sectionPctBasic(),
      onEdit: () => _editSection(context, 0),
    );
  }

  Widget _buildReligionSection(BuildContext context) {
    return _SectionSummaryCard(
      title: 'Religion & Community',
      icon: Icons.temple_hindu_outlined,
      pct: _sectionPctReligion(),
      onEdit: () => _editSection(context, 5),
    );
  }

  Widget _buildPhysicalSection(BuildContext context) {
    return _SectionSummaryCard(
      title: 'Physical Attributes',
      icon: Icons.accessibility_new_outlined,
      pct: _sectionPctPhysical(),
      onEdit: () => _editSection(context, 5),
    );
  }

  Widget _buildEducationCareerSection(BuildContext context) {
    return _SectionSummaryCard(
      title: 'Education & Career',
      icon: Icons.school_outlined,
      pct: _sectionPctEducationCareer(),
      onEdit: () => _editSection(context, 3),
    );
  }

  Widget _buildLifestyleSection(BuildContext context) {
    return _SectionSummaryCard(
      title: 'Lifestyle & Habits',
      icon: Icons.self_improvement_outlined,
      pct: _sectionPctLifestyle(),
      onEdit: () => _editSection(context, 5),
    );
  }

  Widget _buildInterestsSection(BuildContext context) {
    return _SectionSummaryCard(
      title: 'Interests & Hobbies',
      icon: Icons.interests_outlined,
      pct: _sectionPctInterests(),
      onEdit: () => _editSection(context, 1),
    );
  }

  Widget _buildFamilySection(BuildContext context) {
    return _SectionSummaryCard(
      title: 'Family',
      icon: Icons.family_restroom,
      pct: _sectionPctFamily(),
      onEdit: () => _editSection(context, 5),
    );
  }

  Widget _buildHoroscopeSection(BuildContext context) {
    return _SectionSummaryCard(
      title: 'Horoscope',
      icon: Icons.auto_awesome_outlined,
      pct: _sectionPctHoroscope(),
      onEdit: () => _editSection(context, 5),
    );
  }

  Widget _buildAboutMeSection(BuildContext context) {
    return _SectionSummaryCard(
      title: 'About Me',
      icon: Icons.edit_note_outlined,
      pct: _sectionPctAboutMe(),
      onEdit: () => _editSection(context, 0),
    );
  }

  Widget _buildPreferencesSection(BuildContext context) {
    return _SectionSummaryCard(
      title: 'Partner Preferences',
      icon: Icons.tune,
      pct: _sectionPctPreferences(),
      onEdit: () => _editSection(context, 6),
    );
  }

  Widget _buildPhotosSection(BuildContext context) {
    return _SectionSummaryCard(
      title: 'Photos',
      icon: Icons.photo_library_outlined,
      pct: _sectionPctPhotos(),
      onEdit: () => _editSection(context, 2),
    );
  }

  // ── Navigation ────────────────────────────────────────────────────

  Future<void> _editSection(BuildContext context, int step) async {
    await context.push('/profile-setup?edit=true&step=$step');
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
        missing.addAll(['Religion', 'Education', 'Career', 'Family', 'Horoscope']);
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
  });

  final String title;
  final IconData icon;
  final int pct;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        elevation: 0,
        child: InkWell(
          onTap: onEdit,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.saffron.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 22, color: AppColors.saffron),
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
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: pct >= 100
                        ? AppColors.indiaGreen.withValues(alpha: 0.12)
                        : AppColors.saffron.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$pct%',
                    style: AppTypography.labelMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: pct >= 100 ? AppColors.indiaGreen : AppColors.saffronDark,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right, size: 22, color: cs.onSurface.withValues(alpha: 0.4)),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.saffron.withValues(alpha: 0.08),
                AppColors.indiaGreen.withValues(alpha: 0.04),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.saffron.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 56,
                height: 56,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: pct / 100,
                      strokeWidth: 5,
                      backgroundColor: cs.outlineVariant.withValues(alpha: 0.3),
                      color: pct >= 80 ? AppColors.indiaGreen : AppColors.saffron,
                    ),
                    Center(
                      child: Text(
                        '$pct%',
                        style: AppTypography.labelLarge.copyWith(
                          fontWeight: FontWeight.w700,
                          color: pct >= 80 ? AppColors.indiaGreen : AppColors.saffronDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Complete your profile',
                      style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      missing.isEmpty
                          ? 'Almost there!'
                          : 'Missing: ${missing.take(3).join(', ')}${missing.length > 3 ? ' +${missing.length - 3} more' : ''}',
                      style: AppTypography.bodySmall.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.6),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: cs.onSurface.withValues(alpha: 0.4)),
            ],
          ),
        ),
      ),
    );
  }
}
