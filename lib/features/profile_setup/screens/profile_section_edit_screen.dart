import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/api/api_client.dart';
import '../../../core/mode/app_mode.dart';
import '../../../core/mode/mode_provider.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/app_localizations.dart';
import '../widgets/step_identity.dart';
import '../widgets/step_interests.dart';
import '../widgets/step_photos.dart';
import '../widgets/step_details.dart';
import '../widgets/step_preferences.dart';
import '../widgets/step_about_you.dart';
import 'profile_setup_screen.dart';

/// Section IDs used in route /profile-edit/:section
const List<String> profileSectionIds = [
  'basic',
  'location-status',
  'religion',
  'physical',
  'education-career',
  'lifestyle',
  'interests',
  'family',
  'horoscope',
  'about',
  'preferences',
  'photos',
];

String _sectionTitle(String sectionId, BuildContext context) {
  final l = AppLocalizations.of(context)!;
  switch (sectionId) {
    case 'basic':
      return 'Basic Details';
    case 'location-status':
      return l.locationAndStatusSectionTitle;
    case 'religion':
      return l.backgroundTitle;
    case 'physical':
      return l.physicalTitle;
    case 'education-career':
      return 'Education & Career';
    case 'lifestyle':
      return 'Lifestyle & Habits';
    case 'interests':
      return l.interestsAndHobbies;
    case 'family':
      return l.profileBuilderFamily;
    case 'horoscope':
      return l.horoscopeQuestion;
    case 'about':
      return 'About Me';
    case 'preferences':
      return l.profileStepPreferences;
    case 'photos':
      return l.profileStepPhotos;
    default:
      return 'Edit';
  }
}

class ProfileSectionEditScreen extends ConsumerStatefulWidget {
  const ProfileSectionEditScreen({super.key, required this.sectionId});

  final String sectionId;

  @override
  ConsumerState<ProfileSectionEditScreen> createState() =>
      _ProfileSectionEditScreenState();
}

class _ProfileSectionEditScreenState
    extends ConsumerState<ProfileSectionEditScreen> {
  late final ProfileFormData _formData = ProfileFormData(isEditing: true);
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadProfile());
  }

  Future<void> _loadProfile() async {
    if (!mounted) return;
    final repo = ref.read(profileRepositoryProvider);
    final existing = await repo.getMyProfile();
    if (existing != null && mounted) {
      _formData.fillFrom(existing);
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _saveAndClose() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      final repo = ref.read(profileRepositoryProvider);
      final existing = await repo.getMyProfile();
      if (existing == null) {
        final json = _formData.toFullJson();
        final jsonForCreate = Map<String, dynamic>.from(json)
          ..['photoUrls'] = [];
        await repo.saveProfileJson(jsonForCreate, create: true);
      }
      await _uploadPhotosIfNeeded();
      final json = _formData.toFullJson();
      await repo.saveProfileJson(json, create: false);
      if (!mounted) return;
      context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_profileSaveErrorMessage(e)),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String _profileSaveErrorMessage(Object e) {
    final l = AppLocalizations.of(context);
    if (e is ApiException) {
      if (e.code == 'INTERNAL_ERROR' &&
          e.message.toLowerCase().contains('credentials')) {
        return l?.profileSavePhotoUnavailable ??
            'Profile saved. Photo upload is temporarily unavailable.';
      }
      return l?.profileSaveFailed(e.message) ?? 'Failed to save: ${e.message}';
    }
    return l?.profileSaveFailedGeneric ?? 'Failed to save. Please try again.';
  }

  Future<void> _uploadPhotosIfNeeded() async {
    final hasLocal = _formData.photos.any((p) => !p.startsWith('http'));
    if (!hasLocal) return;
    final uploadService = ref.read(photoUploadServiceProvider);
    final uploaded = await uploadService.uploadAll(_formData.photos);
    _formData.photos
      ..clear()
      ..addAll(uploaded);
  }

  void _onChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final mode = ref.watch(appModeProvider) ?? AppMode.matrimony;
    final accent = Theme.of(context).colorScheme.primary;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: AppBar(
          centerTitle: true,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            onPressed: () => context.pop(),
          ),
          title: Text(
            _sectionTitle(widget.sectionId, context),
            style: AppTypography.titleLarge.copyWith(
              color: onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: accent),
              const SizedBox(height: 20),
              Text(
                'Loading…',
                style: AppTypography.bodyMedium.copyWith(
                  color: onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: cs.surface,
        appBar: AppBar(
          centerTitle: true,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          backgroundColor: cs.surface,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            onPressed: () => context.pop(),
          ),
          title: Text(
            _sectionTitle(widget.sectionId, context),
            style: AppTypography.titleLarge.copyWith(
              color: onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        body: SafeArea(
          top: false,
          child: Container(
            width: double.infinity,
            color: cs.surface,
            child: _buildSectionContent(mode),
          ),
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: cs.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: _isSaving ? null : _saveAndClose,
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Save & close',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionContent(AppMode mode) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    switch (widget.sectionId) {
      case 'basic':
        return StepIdentity(
          mode: mode,
          formData: _formData,
          onChanged: _onChanged,
          isEditing: true,
          onlySection: StepIdentityOnlySection.basics,
        );
      case 'location-status':
        return StepIdentity(
          mode: mode,
          formData: _formData,
          onChanged: _onChanged,
          isEditing: true,
          onlySection: StepIdentityOnlySection.locationStatus,
        );
      case 'physical':
        return StepIdentity(
          mode: mode,
          formData: _formData,
          onChanged: _onChanged,
          isEditing: true,
          onlySection: StepIdentityOnlySection.physical,
        );
      case 'religion':
        return StepDetails(
          mode: mode,
          formData: _formData,
          onChanged: _onChanged,
          onlySection: StepDetailsOnlySection.religion,
        );
      case 'lifestyle':
        return StepDetails(
          mode: mode,
          formData: _formData,
          onChanged: _onChanged,
          onlySection: StepDetailsOnlySection.lifestyle,
        );
      case 'family':
        return StepDetails(
          mode: mode,
          formData: _formData,
          onChanged: _onChanged,
          onlySection: StepDetailsOnlySection.family,
        );
      case 'horoscope':
        return StepDetails(
          mode: mode,
          formData: _formData,
          onChanged: _onChanged,
          onlySection: StepDetailsOnlySection.horoscope,
        );
      case 'education-career':
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Education & Career',
                style: AppTypography.displayLarge.copyWith(
                  color: onSurface,
                  fontSize: 28,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Update your education and career details.',
                style: AppTypography.bodyMedium.copyWith(
                  color: onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 24),
              StepEducation(formData: _formData, onChanged: _onChanged),
              const SizedBox(height: 24),
              StepCareer(formData: _formData, onChanged: _onChanged),
              const SizedBox(height: 40),
            ],
          ),
        );
      case 'interests':
        return StepInterests(formData: _formData, onChanged: _onChanged);
      case 'about':
        return mode.isMatrimony
            ? StepAboutYouMatrimony(
                formData: _formData,
                onChanged: _onChanged,
              )
            : StepAboutYou(
                formData: _formData,
                onChanged: _onChanged,
              );
      case 'preferences':
        return StepPreferences(
          mode: mode,
          formData: _formData,
          onChanged: _onChanged,
        );
      case 'photos':
        return StepPhotos(formData: _formData, onChanged: _onChanged);
      default:
        return Center(
          child: Text(
            'Unknown section: ${widget.sectionId}',
            style: AppTypography.bodyMedium.copyWith(color: onSurface),
          ),
        );
    }
  }
}

/// About Me section: title, subtitle, and a world-class multi-line text field.
class _AboutSectionContent extends StatefulWidget {
  const _AboutSectionContent({
    required this.formData,
    required this.onChanged,
    required this.l,
    required this.onSurface,
  });

  final ProfileFormData formData;
  final VoidCallback onChanged;
  final AppLocalizations l;
  final Color onSurface;

  @override
  State<_AboutSectionContent> createState() => _AboutSectionContentState();
}

class _AboutSectionContentState extends State<_AboutSectionContent> {
  // Keep in sync with kAboutMeMaxChars in step_details.dart
  static const int _maxChars = 2000;
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.formData.bio);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'About Me',
            style: AppTypography.displayMedium.copyWith(
              color: widget.onSurface,
              fontSize: 26,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tell others about yourself. What makes you unique?',
            style: AppTypography.bodyMedium.copyWith(
              color: widget.onSurface.withValues(alpha: 0.65),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 28),
          Text(
            widget.l.profileBuilderAbout,
            style: AppTypography.labelMedium.copyWith(
              color: widget.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _controller,
            maxLines: 12,
            minLines: 5,
            maxLength: _maxChars,
            textInputAction: TextInputAction.newline,
            decoration: InputDecoration(
              hintText: widget.l.profileBuilderAbout,
              hintStyle: TextStyle(
                color: widget.onSurface.withValues(alpha: 0.4),
              ),
              filled: true,
              fillColor: cs.surfaceContainerHighest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: cs.outlineVariant),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: cs.outlineVariant.withValues(alpha: 0.6),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: cs.primary, width: 1.5),
              ),
              contentPadding: const EdgeInsets.all(20),
              counterStyle: TextStyle(
                fontSize: 12,
                color: widget.onSurface.withValues(alpha: 0.45),
              ),
            ),
            onChanged: (v) {
              widget.formData.bio = v;
              widget.onChanged();
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
