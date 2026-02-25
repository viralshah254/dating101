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
        // Sections
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
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
              const SizedBox(height: 40),
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

  // ── Sections ──────────────────────────────────────────────────────

  Widget _buildBasicDetailsSection(BuildContext context) {
    final age = _computeAge(profile.dateOfBirth);
    final items = <_DetailItem>[
      if (profile.gender != null) _DetailItem(Icons.person_outline, 'Gender', profile.gender!),
      if (age != null) _DetailItem(Icons.cake_outlined, 'Age', '$age years'),
      if (profile.dateOfBirth != null) _DetailItem(Icons.calendar_today_outlined, 'Date of birth', _formatDate(profile.dateOfBirth!)),
      if (profile.displayLocation.isNotEmpty) _DetailItem(Icons.location_on_outlined, 'Living in', profile.displayLocation),
      if (profile.originCity != null) _DetailItem(Icons.home_outlined, 'From', [profile.originCity, profile.originCountry].whereType<String>().join(', ')),
      if (profile.motherTongue != null) _DetailItem(Icons.translate, 'Mother tongue', profile.motherTongue!),
      if (profile.languagesSpoken.isNotEmpty) _DetailItem(Icons.language, 'Languages', profile.languagesSpoken.join(', ')),
    ];
    return _SectionCard(
      title: 'Basic Details',
      icon: Icons.badge_outlined,
      editStep: 0,
      items: items,
      onEdit: () => _editSection(context, 0),
    );
  }

  Widget _buildReligionSection(BuildContext context) {
    final mat = profile.matrimonyExtensions;
    final items = <_DetailItem>[
      if (mat?.religion != null) _DetailItem(Icons.temple_hindu_outlined, 'Religion', mat!.religion!),
      if (mat?.casteOrCommunity != null) _DetailItem(Icons.groups_outlined, 'Community', mat!.casteOrCommunity!),
      if (mat?.maritalStatus != null) _DetailItem(Icons.favorite_border, 'Marital status', mat!.maritalStatus!),
    ];
    return _SectionCard(
      title: 'Religion & Community',
      icon: Icons.temple_hindu_outlined,
      items: items,
      onEdit: () => _editSection(context, 0),
    );
  }

  Widget _buildPhysicalSection(BuildContext context) {
    final mat = profile.matrimonyExtensions;
    final items = <_DetailItem>[
      if (mat?.heightCm != null) _DetailItem(Icons.height, 'Height', '${mat!.heightCm} cm'),
    ];
    return _SectionCard(
      title: 'Physical Attributes',
      icon: Icons.accessibility_new_outlined,
      items: items,
      onEdit: () => _editSection(context, 0),
    );
  }

  Widget _buildEducationCareerSection(BuildContext context) {
    final mat = profile.matrimonyExtensions;
    final items = <_DetailItem>[
      if (mat?.educationDegree != null) _DetailItem(Icons.school_outlined, 'Education', mat!.educationDegree!),
      if (mat?.educationInstitution != null) _DetailItem(Icons.account_balance_outlined, 'Institution', mat!.educationInstitution!),
      if (mat?.occupation != null) _DetailItem(Icons.work_outline, 'Occupation', mat!.occupation!),
      if (mat?.employer != null) _DetailItem(Icons.business_outlined, 'Company', mat!.employer!),
      if (mat?.industry != null) _DetailItem(Icons.category_outlined, 'Sector', mat!.industry!),
      if (mat?.incomeRange != null) _DetailItem(Icons.currency_rupee, 'Income', mat!.incomeRange!.minLabel ?? ''),
    ];
    return _SectionCard(
      title: 'Education & Career',
      icon: Icons.school_outlined,
      items: items,
      onEdit: () => _editSection(context, 3),
    );
  }

  Widget _buildLifestyleSection(BuildContext context) {
    final mat = profile.matrimonyExtensions;
    final chips = <_ChipData>[];
    if (mat?.diet != null) chips.add(_ChipData(Icons.restaurant_outlined, mat!.diet!));
    if (mat?.drinking != null) chips.add(_ChipData(Icons.local_bar_outlined, mat!.drinking!));
    if (mat?.smoking != null) chips.add(_ChipData(Icons.smoke_free, mat!.smoking!));
    return _SectionCard(
      title: 'Lifestyle & Habits',
      icon: Icons.self_improvement_outlined,
      chips: chips,
      items: const [],
      onEdit: () => _editSection(context, 5),
    );
  }

  Widget _buildInterestsSection(BuildContext context) {
    return _SectionCard(
      title: 'Interests & Hobbies',
      icon: Icons.interests_outlined,
      tags: profile.interests,
      items: const [],
      onEdit: () => _editSection(context, 1),
    );
  }

  Widget _buildFamilySection(BuildContext context) {
    final fam = profile.matrimonyExtensions?.familyDetails;
    final items = <_DetailItem>[
      if (fam?.familyType != null) _DetailItem(Icons.family_restroom, 'Family type', fam!.familyType!),
      if (fam?.familyValues != null) _DetailItem(Icons.diversity_1_outlined, 'Family values', fam!.familyValues!),
      if (fam?.fatherOccupation != null) _DetailItem(Icons.person_outline, "Father's occupation", fam!.fatherOccupation!),
      if (fam?.motherOccupation != null) _DetailItem(Icons.person_outline, "Mother's occupation", fam!.motherOccupation!),
      if (fam?.siblingsCount != null) _DetailItem(Icons.people_outline, 'Siblings', '${fam!.siblingsCount}'),
    ];
    return _SectionCard(
      title: 'Family',
      icon: Icons.family_restroom,
      items: items,
      onEdit: () => _editSection(context, 5),
    );
  }

  Widget _buildHoroscopeSection(BuildContext context) {
    final hor = profile.matrimonyExtensions?.horoscope;
    final items = <_DetailItem>[
      if (hor?.manglik != null) _DetailItem(Icons.auto_awesome_outlined, 'Manglik', hor!.manglik!),
      if (hor?.nakshatra != null) _DetailItem(Icons.star_outline, 'Nakshatra', hor!.nakshatra!),
      if (hor?.timeOfBirth != null) _DetailItem(Icons.access_time, 'Birth time', hor!.timeOfBirth!),
      if (hor?.birthPlace != null) _DetailItem(Icons.place_outlined, 'Birth place', hor!.birthPlace!),
    ];
    return _SectionCard(
      title: 'Horoscope',
      icon: Icons.auto_awesome_outlined,
      items: items,
      onEdit: () => _editSection(context, 5),
    );
  }

  Widget _buildAboutMeSection(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasAbout = profile.aboutMe.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeader(
              title: 'About Me',
              icon: Icons.edit_note_outlined,
              onEdit: () => _editSection(context, 0),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                hasAbout ? profile.aboutMe : 'Tell others about yourself...',
                style: AppTypography.bodyMedium.copyWith(
                  color: hasAbout ? cs.onSurface : cs.onSurface.withValues(alpha: 0.4),
                  fontStyle: hasAbout ? FontStyle.normal : FontStyle.italic,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreferencesSection(BuildContext context) {
    final prefs = profile.partnerPreferences;
    final items = <_DetailItem>[
      if (prefs != null) _DetailItem(Icons.calendar_today_outlined, 'Age range', '${prefs.ageMin} – ${prefs.ageMax} years'),
      if (prefs?.preferredReligions?.isNotEmpty == true)
        _DetailItem(Icons.temple_hindu_outlined, 'Religion', prefs!.preferredReligions!.join(', ')),
      if (prefs?.educationPreference != null)
        _DetailItem(Icons.school_outlined, 'Education', prefs!.educationPreference!),
      if (prefs?.maritalStatusPreference?.isNotEmpty == true)
        _DetailItem(Icons.favorite_border, 'Marital status', prefs!.maritalStatusPreference!.join(', ')),
      if (prefs?.dietPreference != null)
        _DetailItem(Icons.restaurant_outlined, 'Diet', prefs!.dietPreference!),
      if (prefs?.preferredLocations?.isNotEmpty == true)
        _DetailItem(Icons.location_on_outlined, 'Preferred locations', prefs!.preferredLocations!.join(', ')),
    ];
    return _SectionCard(
      title: 'Partner Preferences',
      icon: Icons.tune,
      items: items,
      onEdit: () => _editSection(context, 6),
    );
  }

  Widget _buildPhotosSection(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeader(
              title: 'Photos',
              icon: Icons.photo_library_outlined,
              onEdit: () => _editSection(context, 2),
              trailing: '${profile.photoUrls.length} photos',
            ),
            if (profile.photoUrls.isNotEmpty)
              SizedBox(
                height: 120,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: profile.photoUrls.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) => ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 90,
                      height: 120,
                      child: _buildImage(profile.photoUrls[i]),
                    ),
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Text(
                  'Add photos to get more matches',
                  style: AppTypography.bodySmall.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.4),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
      ),
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

  int? _computeAge(String? dateOfBirth) {
    if (dateOfBirth == null) return null;
    final dob = DateTime.tryParse(dateOfBirth);
    if (dob == null) return null;
    final now = DateTime.now();
    int age = now.year - dob.year;
    if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) age--;
    return age;
  }

  String _formatDate(String isoDate) {
    final dt = DateTime.tryParse(isoDate);
    if (dt == null) return isoDate;
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
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

// ── Reusable section card ─────────────────────────────────────────

class _DetailItem {
  const _DetailItem(this.icon, this.label, this.value);
  final IconData icon;
  final String label;
  final String value;
}

class _ChipData {
  const _ChipData(this.icon, this.label);
  final IconData icon;
  final String label;
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.items,
    required this.onEdit,
    this.editStep,
    this.chips,
    this.tags,
  });

  final String title;
  final IconData icon;
  final List<_DetailItem> items;
  final VoidCallback onEdit;
  final int? editStep;
  final List<_ChipData>? chips;
  final List<String>? tags;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isEmpty = items.isEmpty && (chips == null || chips!.isEmpty) && (tags == null || tags!.isEmpty);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeader(title: title, icon: icon, onEdit: onEdit),
            if (isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: GestureDetector(
                  onTap: onEdit,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: AppColors.saffron.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.saffron.withValues(alpha: 0.2),
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_circle_outline, size: 18, color: AppColors.saffron),
                        const SizedBox(width: 8),
                        Text(
                          'Add $title',
                          style: AppTypography.labelLarge.copyWith(color: AppColors.saffron),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            if (items.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  children: items.map((item) => _buildDetailRow(context, item)).toList(),
                ),
              ),
            if (chips != null && chips!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: chips!.map((c) => _buildChip(context, c)).toList(),
                ),
              ),
            if (tags != null && tags!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: tags!.map((t) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.saffron.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      t,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.saffronDark,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, _DetailItem item) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.saffron.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(item.icon, size: 18, color: AppColors.saffron),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: AppTypography.caption.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.5),
                  ),
                ),
                Text(
                  item.value,
                  style: AppTypography.bodyMedium.copyWith(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(BuildContext context, _ChipData chip) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(chip.icon, size: 18, color: cs.onSurface.withValues(alpha: 0.7)),
          const SizedBox(width: 8),
          Text(
            chip.label,
            style: AppTypography.bodySmall.copyWith(
              color: cs.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.icon,
    required this.onEdit,
    this.trailing,
  });

  final String title;
  final IconData icon;
  final VoidCallback onEdit;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.saffron),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          if (trailing != null) ...[
            Text(
              trailing!,
              style: AppTypography.caption.copyWith(color: cs.onSurface.withValues(alpha: 0.5)),
            ),
            const SizedBox(width: 4),
          ],
          IconButton(
            icon: Icon(Icons.edit_outlined, size: 18, color: AppColors.saffron),
            onPressed: onEdit,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
        ],
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
