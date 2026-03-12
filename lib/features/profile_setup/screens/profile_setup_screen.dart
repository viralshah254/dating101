import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/api/api_client.dart';
import '../../../core/location/app_location_service.dart';
import '../../../core/mode/app_mode.dart';
import '../../../core/mode/mode_provider.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/theme/app_typography.dart';
import '../../../domain/models/user_profile.dart';
import '../../../l10n/app_localizations.dart';
import '../widgets/step_identity.dart';
import '../widgets/step_interests.dart';
import '../widgets/step_photos.dart';
import '../widgets/step_details.dart';
import '../widgets/step_preferences.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({
    super.key,
    this.isEditing = false,
    this.initialStep,
  });

  /// When true, the user already has a profile — locked fields, different title.
  final bool isEditing;

  /// Jump directly to a specific step (0-based). Null starts at step 0.
  final int? initialStep;

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  late final ProfileFormData _formData = ProfileFormData(
    isEditing: widget.isEditing,
  );
  bool _isCompleting = false;
  bool _isLoading = true;
  int? _pendingInitialStep;

  late List<_StepInfo> _steps;
  static final _locationService = AppLocationService.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _ensureLocationAndProceed(),
    );
  }

  /// Redirect to location-required if permission not granted (app must not run without location).
  /// If user has an existing profile, prefills the form for seamless edit / mode switch.
  Future<void> _ensureLocationAndProceed() async {
    if (!mounted) return;
    final access = await _locationService.checkAccess();
    if (access != LocationAccess.granted) {
      if (!mounted) return;
      context.go(
        '/location-required?then=${Uri.encodeComponent('/profile-setup')}',
      );
      return;
    }
    final repo = ref.read(profileRepositoryProvider);
    final existing = await repo.getMyProfile();
    if (existing != null && mounted) {
      _formData.fillFrom(existing);
    }
    if (mounted) {
      setState(() {
        _isLoading = false;
        _pendingInitialStep = widget.initialStep;
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  bool get _canProceed {
    if (_isCompleting) return false;
    final step = _steps[_currentStep];
    if (!step.hasMandatory) return true;
    return step.isMandatorySatisfied(_formData);
  }

  Future<void> _next() async {
    FocusScope.of(context).unfocus();
    if (_currentStep < _steps.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep++);
    } else {
      setState(() => _isCompleting = true);

      if (widget.isEditing) {
        debugPrint('[ProfileSetup] Saving all edits (final)...');
        try {
          await _uploadPhotosIfNeeded();
          final repo = ref.read(profileRepositoryProvider);
          final json = _formData.toFullJson();
          debugPrint('[ProfileSetup] Final edit payload: $json');
          final existing = await repo.getMyProfile();
          await repo.saveProfileJson(json, create: existing == null);
          debugPrint('[ProfileSetup] Final edit saved ✓');
        } catch (e) {
          debugPrint('[ProfileSetup] Error saving edits: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(_profileSaveErrorMessage(e)),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        }
        if (!mounted) return;
        setState(() => _isCompleting = false);
        context.pop();
        return;
      }

      // First-time setup: capture exact creation location then complete
      debugPrint(
        '[ProfileSetup] First-time setup — getting creation location...',
      );
      final creation = await _locationService.getCurrentCreationLocation();
      if (!mounted) return;
      if (creation == null) {
        debugPrint('[ProfileSetup] Location unavailable');
        setState(() => _isCompleting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.profileCreationLocationError,
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        return;
      }
      _formData.creationLat = creation.latitude;
      _formData.creationLng = creation.longitude;
      _formData.creationAt = creation.capturedAt;
      _formData.creationAddress = creation.address;
      debugPrint(
        '[ProfileSetup] Creation location: ${creation.latitude}, ${creation.longitude} — ${creation.address}',
      );

      try {
        await _uploadPhotosIfNeeded();
        final repo = ref.read(profileRepositoryProvider);
        final json = _formData.toFullJson();
        debugPrint('[ProfileSetup] First-time setup payload: $json');
        final existing = await repo.getMyProfile();
        await repo.saveProfileJson(json, create: existing == null);
        debugPrint(
          '[ProfileSetup] Profile saved ✓ (${existing == null ? 'create' : 'update'})',
        );
      } catch (e) {
        debugPrint('[ProfileSetup] Error saving profile: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_profileSaveErrorMessage(e)),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }

      if (!mounted) return;
      context.go('/');
    }
  }

  void _skip() {
    FocusScope.of(context).unfocus();
    if (_currentStep < _steps.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep++);
    }
  }

  bool _isSaving = false;

  /// Save current changes, then advance to the next step (or close on last step).
  Future<void> _saveAndContinue() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      await _uploadPhotosIfNeeded();
      final repo = ref.read(profileRepositoryProvider);
      final json = _formData.toFullJson();
      debugPrint(
        '[ProfileSetup] Save & continue (step ${_currentStep + 1})...',
      );
      final existing = await repo.getMyProfile();
      await repo.saveProfileJson(json, create: existing == null);
      debugPrint('[ProfileSetup] Saved ✓');
    } catch (e) {
      debugPrint('[ProfileSetup] Save error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_profileSaveErrorMessage(e)),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        setState(() => _isSaving = false);
        return;
      }
    }

    if (!mounted) return;
    setState(() => _isSaving = false);

    // Section edit from profile view: save and close (do not advance to next step).
    if (widget.isEditing && widget.initialStep != null) {
      if (mounted) context.pop();
      return;
    }

    if (_currentStep < _steps.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep++);
    } else {
      context.pop();
    }
  }

  /// User-friendly message for save/upload errors (e.g. photo upload credentials).
  static String _profileSaveErrorMessage(Object e) {
    if (e is ApiException) {
      if (e.code == 'INTERNAL_ERROR' &&
          e.message.toLowerCase().contains('credentials')) {
        return 'Profile saved. Photo upload is temporarily unavailable—please try adding photos later from profile settings.';
      }
      return 'Failed to save: ${e.message}';
    }
    return 'Failed to save: $e';
  }

  /// Upload any local-file photos to S3, replacing paths with CDN URLs.
  Future<void> _uploadPhotosIfNeeded() async {
    final hasLocal = _formData.photos.any((p) => !p.startsWith('http'));
    if (!hasLocal) return;

    debugPrint(
      '[ProfileSetup] Uploading ${_formData.photos.where((p) => !p.startsWith("http")).length} photo(s) to S3...',
    );
    final uploadService = ref.read(photoUploadServiceProvider);
    final uploaded = await uploadService.uploadAll(_formData.photos);
    _formData.photos
      ..clear()
      ..addAll(uploaded);
    debugPrint('[ProfileSetup] Photos uploaded: ${_formData.photos}');
  }

  void _back() {
    FocusScope.of(context).unfocus();
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep--);
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveMode = ref.watch(appModeProvider) ?? AppMode.dating;
    final modePreference = ref.watch(modePreferenceProvider).valueOrNull;
    final signupPreference = modePreference ?? effectiveMode;
    final l = AppLocalizations.of(context)!;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final accent = Theme.of(context).colorScheme.primary;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
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

    _steps = _buildSteps(signupPreference, l);
    if (_steps.isNotEmpty && _currentStep >= _steps.length) {
      _currentStep = _steps.length - 1;
    }
    if (_pendingInitialStep != null && _steps.isNotEmpty) {
      final target = _pendingInitialStep!.clamp(0, _steps.length - 1);
      _pendingInitialStep = null;
      _currentStep = target;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_pageController.hasClients) {
          _pageController.jumpToPage(target);
        }
      });
    }
    if (_currentStep >= _steps.length) _currentStep = _steps.length - 1;
    final progress = (_currentStep + 1) / _steps.length;
    final currentStep = _steps[_currentStep];

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: AppBar(
          centerTitle: true,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            onPressed: _currentStep > 0 ? _back : () => context.pop(),
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          ),
          title: Text(
            currentStep.label,
            style: AppTypography.titleLarge.copyWith(
              color: onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              // Step progress — same concept as section edit: clear, minimal
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                child: Column(
                  children: [
                    if (signupPreference.isBoth && !widget.isEditing) ...[
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: accent.withValues(alpha: 0.22),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.merge_type_rounded,
                              color: accent,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                l.bothModeSetupHint,
                                style: AppTypography.bodySmall.copyWith(
                                  color: onSurface.withValues(alpha: 0.78),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l.stepOfTotal(_currentStep + 1, _steps.length),
                          style: AppTypography.labelMedium.copyWith(
                            color: onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                        Text(
                          '${(progress * 100).round()}%',
                          style: AppTypography.labelMedium.copyWith(
                            color: accent,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: onSurface.withValues(alpha: 0.1),
                        valueColor: AlwaysStoppedAnimation(accent),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: _steps.map((s) => s.widget).toList(),
                ),
              ),

              // Bottom — same style as ProfileSectionEditScreen (Save & close / Next)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: FilledButton(
                        onPressed: widget.isEditing
                            ? (_isSaving ? null : _saveAndContinue)
                            : (_canProceed ? _next : null),
                        child: widget.isEditing
                            ? (_isSaving
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          _currentStep >= _steps.length - 1
                                              ? l.saveAndClose
                                              : l.saveAndContinue,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        if (_currentStep <
                                            _steps.length - 1) ...[
                                          const SizedBox(width: 8),
                                          const Icon(
                                            Icons.arrow_forward,
                                            size: 20,
                                          ),
                                        ],
                                      ],
                                    ))
                            : Text(
                                _currentStep < _steps.length - 1
                                    ? l.next
                                    : l.getStarted,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                    if (!widget.isEditing &&
                        currentStep.skippable &&
                        _currentStep < _steps.length - 1) ...[
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: _skip,
                        child: Text(
                          l.skipForNow,
                          style: AppTypography.bodySmall.copyWith(
                            color: onSurface.withValues(alpha: 0.55),
                          ),
                        ),
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

  List<_StepInfo> _buildSteps(AppMode mode, AppLocalizations l) {
    void onChanged() => setState(() {});
    final editing = widget.isEditing;
    if (mode.isBoth) {
      // Shared-first flow for users who selected "both", then mode-specific sections.
      return [
        _StepInfo(
          label: editing ? l.editProfile : l.profileStepIdentity,
          widget: StepIdentity(
            mode: AppMode.matrimony,
            formData: _formData,
            onChanged: onChanged,
            isEditing: editing,
          ),
          hasMandatory: true,
          skippable: false,
          isMandatorySatisfied: (d) =>
              ProfileFormData.isNameValid(d.name) &&
              d.gender != null &&
              d.dateOfBirth != null &&
              ProfileFormData.isAtLeast18(d.dateOfBirth) &&
              (editing || d.confirmedAge18),
        ),
        _StepInfo(
          label: l.interestsAndHobbies,
          widget: StepInterests(formData: _formData, onChanged: onChanged),
          hasMandatory: false,
          skippable: true,
        ),
        _StepInfo(
          label: l.profileStepPhotos,
          widget: StepPhotos(formData: _formData, onChanged: onChanged),
          hasMandatory: false,
          skippable: true,
        ),
        _StepInfo(
          label: '${l.modeMatrimony} · ${l.profileStepEducation}',
          widget: StepEducation(formData: _formData, onChanged: onChanged),
          hasMandatory: false,
          skippable: true,
        ),
        _StepInfo(
          label: '${l.modeMatrimony} · ${l.profileStepCareer}',
          widget: StepCareer(formData: _formData, onChanged: onChanged),
          hasMandatory: false,
          skippable: true,
        ),
        _StepInfo(
          label: '${l.modeMatrimony} · ${l.profileStepDetails}',
          widget: StepDetails(
            mode: AppMode.matrimony,
            formData: _formData,
            onChanged: onChanged,
          ),
          hasMandatory: false,
          skippable: true,
        ),
        _StepInfo(
          label: '${l.modeMatrimony} · ${l.profileStepPreferences}',
          widget: StepPreferences(
            mode: AppMode.matrimony,
            formData: _formData,
            onChanged: onChanged,
          ),
          hasMandatory: false,
          skippable: true,
        ),
        _StepInfo(
          label: '${l.modeDating} · ${l.profileStepDetails}',
          widget: StepDetails(
            mode: AppMode.dating,
            formData: _formData,
            onChanged: onChanged,
          ),
          hasMandatory: false,
          skippable: true,
        ),
        _StepInfo(
          label: '${l.modeDating} · ${l.profileStepPreferences}',
          widget: StepPreferences(
            mode: AppMode.dating,
            formData: _formData,
            onChanged: onChanged,
          ),
          hasMandatory: false,
          skippable: true,
        ),
      ];
    }
    if (mode.isMatrimony) {
      return [
        _StepInfo(
          label: editing ? l.editProfile : l.profileStepIdentity,
          widget: StepIdentity(
            mode: mode,
            formData: _formData,
            onChanged: onChanged,
            isEditing: editing,
          ),
          hasMandatory: true,
          skippable: false,
          isMandatorySatisfied: (d) =>
              ProfileFormData.isNameValid(d.name) &&
              d.gender != null &&
              d.dateOfBirth != null &&
              ProfileFormData.isAtLeast18(d.dateOfBirth) &&
              (editing || d.confirmedAge18),
        ),
        _StepInfo(
          label: l.interestsAndHobbies,
          widget: StepInterests(formData: _formData, onChanged: onChanged),
          hasMandatory: false,
          skippable: true,
        ),
        _StepInfo(
          label: l.profileStepPhotos,
          widget: StepPhotos(formData: _formData, onChanged: onChanged),
          hasMandatory: false,
          skippable: true,
        ),
        _StepInfo(
          label: l.profileStepEducation,
          widget: StepEducation(formData: _formData, onChanged: onChanged),
          hasMandatory: false,
          skippable: true,
        ),
        _StepInfo(
          label: l.profileStepCareer,
          widget: StepCareer(formData: _formData, onChanged: onChanged),
          hasMandatory: false,
          skippable: true,
        ),
        _StepInfo(
          label: l.profileStepDetails,
          widget: StepDetails(
            mode: mode,
            formData: _formData,
            onChanged: onChanged,
          ),
          hasMandatory: false,
          skippable: true,
        ),
        _StepInfo(
          label: l.profileStepPreferences,
          widget: StepPreferences(
            mode: mode,
            formData: _formData,
            onChanged: onChanged,
          ),
          hasMandatory: false,
          skippable: true,
        ),
      ];
    }
    return [
      _StepInfo(
        label: editing ? l.editProfile : l.profileStepIdentity,
        widget: StepIdentity(
          mode: mode,
          formData: _formData,
          onChanged: onChanged,
          isEditing: editing,
        ),
        hasMandatory: true,
        skippable: false,
        isMandatorySatisfied: (d) =>
            ProfileFormData.isNameValid(d.name) &&
            d.gender != null &&
            d.dateOfBirth != null &&
            ProfileFormData.isAtLeast18(d.dateOfBirth) &&
            (editing || d.confirmedAge18),
      ),
      _StepInfo(
        label: l.interestsAndHobbies,
        widget: StepInterests(formData: _formData, onChanged: onChanged),
        hasMandatory: false,
        skippable: true,
      ),
      _StepInfo(
        label: l.profileStepPhotos,
        widget: StepPhotos(formData: _formData, onChanged: onChanged),
        hasMandatory: false,
        skippable: true,
      ),
      _StepInfo(
        label: l.profileStepDetails,
        widget: StepDetails(
          mode: mode,
          formData: _formData,
          onChanged: onChanged,
        ),
        hasMandatory: false,
        skippable: true,
      ),
      _StepInfo(
        label: l.profileStepPreferences,
        widget: StepPreferences(
          mode: mode,
          formData: _formData,
          onChanged: onChanged,
        ),
        hasMandatory: false,
        skippable: true,
      ),
    ];
  }
}

class _StepInfo {
  const _StepInfo({
    required this.label,
    required this.widget,
    this.hasMandatory = false,
    this.skippable = false,
    bool Function(ProfileFormData)? isMandatorySatisfied,
  }) : _isMandatorySatisfied = isMandatorySatisfied;

  final String label;
  final Widget widget;
  final bool hasMandatory;
  final bool skippable;
  final bool Function(ProfileFormData)? _isMandatorySatisfied;

  bool isMandatorySatisfied(ProfileFormData d) =>
      _isMandatorySatisfied?.call(d) ?? true;
}

/// One education entry (degree, institution, year, grade).
class EducationEntry {
  EducationEntry({
    this.degree,
    this.institution,
    this.country,
    this.graduationYear,
    this.scoreCountry,
    this.scoreType,
  });
  String? degree;
  String? institution;
  String? country;
  int? graduationYear;
  String? scoreCountry; // e.g. India, UK, US, Other
  String? scoreType; // e.g. First class, 2:1, GPA 3.5
}

/// Degrees that do not show university/college (e.g. High School, Diploma).
bool educationEntryShowsInstitution(String? degree) {
  if (degree == null) return true;
  return degree != 'High School' && degree != 'Diploma';
}

/// Shared mutable form data passed through all steps.
class ProfileFormData {
  ProfileFormData({this.isEditing = false});

  /// If true, user already has a profile and is editing.
  final bool isEditing;

  // Identity (mandatory: name, gender, dob, 18+ confirmed)
  String? creatingFor;
  String name = '';
  String? gender;
  DateTime? dateOfBirth;
  bool confirmedAge18 = false;
  String location = '';
  String hometown = '';

  /// Where the profile was created (for safety/support tracking). Set when user completes setup.
  double? creationLat;
  double? creationLng;
  DateTime? creationAt;
  String? creationAddress;

  // Physical
  String? heightCm;
  String? bodyType;
  String? complexion;
  String? disability;

  // Marital (single source — no duplicates)
  String? maritalStatus;

  // Religion / community
  String? religion;
  String? community;
  String? motherTongue;
  String? languagesSpoken;

  // Education (multiple entries; first or highest used for filters)
  List<EducationEntry> educationEntries = [];
  String? aboutEducation;

  // Career
  String? education;
  String? occupation;
  String? income;
  String? company;
  String? workLocation;
  String? sector;
  String? settledAbroad;
  String? willingToRelocate;
  String? aboutCareer;

  // Family
  String? familyType;
  String? familyValues;
  String? familyLocation;

  /// Country of family location (e.g. "India") for currency: India → INR, else USD.
  String? familyBasedOutOfCountry;
  String? householdIncome;
  String? motherOccupation;
  String? fatherOccupation;

  /// Mother's age or "Deceased".
  String? motherAge;

  /// Father's age or "Deceased".
  String? fatherAge;
  String? siblings;

  /// Number of brothers (dropdown: None, 1, 2, 3, 4+).
  String? siblingBrothers;

  /// Number of sisters (dropdown: None, 1, 2, 3, 4+).
  String? siblingSisters;

  // Horoscope (matrimony)
  String? manglik;
  String? rashi;
  String? nakshatra;
  String? gotra;
  String? birthTime;
  String? birthPlace;

  // Lifestyle
  String? diet;
  String? drinking;
  String? smoking;
  String? exercise;
  String? pets;

  // Dating extras
  String? datingIntent;
  String? interestedIn;

  // Bio / prompt
  String bio = '';
  String promptAnswer = '';

  // Photos (local file paths; first is profile pic)
  List<String> photos = [];

  // Interests
  List<String> selectedInterests = [];

  // Partner preferences (persisted)
  int? prefAgeMin;
  int? prefAgeMax;
  int? prefHeightMinCm;
  int? prefHeightMaxCm;
  List<String> preferredBodyTypes = [];
  bool prefBodyTypeStrict = false;
  String? prefReligion;
  bool prefReligionStrict = false;
  String? prefMotherTongue;
  bool prefMotherTongueStrict = false;
  String? prefEducation;
  bool prefEducationStrict = false;
  String? prefMaritalStatus;
  bool prefMaritalStatusStrict = false;
  String? prefIncome;
  bool prefIncomeStrict = false;
  String? prefDiet;
  bool prefDietStrict = false;
  String? prefDrink;
  bool prefDrinkStrict = false;
  String? prefSmoke;
  bool prefSmokeStrict = false;
  String? prefSettledAbroad;
  bool prefSettledAbroadStrict = false;

  /// City preference: 'any' | 'same_as_me' | 'preferred'
  String? prefCityMode;

  /// Preferred cities (multiple), used when prefCityMode == 'preferred'.
  List<String> preferredCities = [];

  /// Preferred countries (multiple).
  List<String> preferredCountries = [];

  /// Prefill from existing profile so edit / mode switch is seamless. Shared and mode-specific fields are mapped.
  void fillFrom(UserProfile? p) {
    if (p == null) return;
    name = p.name;
    gender = p.gender;
    if (p.dateOfBirth != null) {
      dateOfBirth = DateTime.tryParse(p.dateOfBirth!);
      confirmedAge18 = true;
    }
    if (p.currentCity != null || p.currentCountry != null) {
      location = [
        p.currentCity,
        p.currentCountry,
      ].whereType<String>().join(', ');
    }
    hometown = p.originCity ?? '';
    if (p.originCountry != null && p.originCountry!.isNotEmpty) {
      if (hometown.isNotEmpty) hometown += ', ';
      hometown += p.originCountry!;
    }
    motherTongue = p.motherTongue;
    languagesSpoken = p.languagesSpoken.isNotEmpty
        ? p.languagesSpoken.join(', ')
        : null;
    bio = p.aboutMe;
    selectedInterests = List<String>.from(p.interests);
    photos = List<String>.from(p.photoUrls);
    creationLat = p.creationLat;
    creationLng = p.creationLng;
    creationAt = p.creationAt;
    creationAddress = p.creationAddress;

    final mat = p.matrimonyExtensions;
    if (mat != null) {
      religion = mat.religion;
      community = mat.casteOrCommunity;
      if (mat.motherTongue != null) motherTongue = mat.motherTongue;
      maritalStatus = mat.maritalStatus;
      heightCm = mat.heightCm?.toString();
      bodyType = mat.bodyType;
      complexion = mat.complexion;
      education = mat.educationDegree;
      occupation = mat.occupation;
      company = mat.employer;
      sector = mat.industry;
      if (mat.incomeRange != null) {
        income = [
          mat.incomeRange!.minLabel,
          mat.incomeRange!.maxLabel,
          mat.incomeRange!.currency,
        ].whereType<String>().join(' ');
      }
      diet = mat.diet;
      drinking = mat.drinking;
      smoking = mat.smoking;
      exercise = mat.exercise;
      aboutEducation = mat.aboutEducation;
      final fam = mat.familyDetails;
      if (fam != null) {
        familyType = fam.familyType;
        familyValues = fam.familyValues;
        familyLocation = fam.familyLocation;
        familyBasedOutOfCountry = fam.familyBasedOutOfCountry;
        householdIncome = fam.householdIncome;
        fatherOccupation = fam.fatherOccupation;
        motherOccupation = fam.motherOccupation;
        fatherAge = fam.fatherAge;
        motherAge = fam.motherAge;
        if (fam.siblingsCount != null) siblings = fam.siblingsCount.toString();
        siblingBrothers = fam.brothers;
        siblingSisters = fam.sisters;
      }
      final hor = mat.horoscope;
      if (hor != null) {
        manglik = hor.manglik;
        rashi = hor.rashi;
        nakshatra = hor.nakshatra;
        gotra = hor.gotra;
        birthTime = hor.timeOfBirth;
        birthPlace = hor.birthPlace;
        if (hor.dateOfBirth != null) {
          final dob = DateTime.tryParse(hor.dateOfBirth!);
          if (dob != null) dateOfBirth ??= dob;
        }
      }
      if (mat.educationEntries != null && mat.educationEntries!.isNotEmpty) {
        educationEntries = mat.educationEntries!
            .map(
              (e) => EducationEntry(
                degree: e.degree,
                institution: e.institution,
                graduationYear: e.graduationYear,
                scoreCountry: e.scoreCountry,
                scoreType: e.scoreType,
              ),
            )
            .toList();
      } else if (mat.educationDegree != null ||
          mat.educationInstitution != null) {
        educationEntries = [
          EducationEntry(
            degree: mat.educationDegree,
            institution: mat.educationInstitution,
          ),
        ];
      }
    }

    final dat = p.datingExtensions;
    if (dat != null) {
      datingIntent = dat.datingIntent;
      if (dat.prompts != null && dat.prompts!.isNotEmpty) {
        promptAnswer = dat.prompts!.map((e) => e.answer).join('\n');
      }
    }

    final prefs = p.partnerPreferences;
    if (prefs != null) {
      interestedIn = prefs.genderPreference;
      prefAgeMin = prefs.ageMin;
      prefAgeMax = prefs.ageMax;
      prefHeightMinCm = prefs.heightMinCm;
      prefHeightMaxCm = prefs.heightMaxCm;
      if (prefs.preferredBodyTypes != null &&
          prefs.preferredBodyTypes!.isNotEmpty) {
        preferredBodyTypes = List<String>.from(prefs.preferredBodyTypes!);
      }
      prefReligion = prefs.preferredReligions?.isNotEmpty == true
          ? prefs.preferredReligions!.first
          : null;
      prefMotherTongue = prefs.preferredMotherTongues?.isNotEmpty == true
          ? prefs.preferredMotherTongues!.first
          : null;
      prefEducation = prefs.educationPreference;
      prefMaritalStatus = prefs.maritalStatusPreference?.isNotEmpty == true
          ? prefs.maritalStatusPreference!.first
          : null;
      prefDiet = prefs.dietPreference;
      prefIncome = prefs.incomePreference;
      prefDrink = prefs.drinkingPreference;
      prefSmoke = prefs.smokingPreference;
      prefSettledAbroad = prefs.settledAbroadPreference;
      prefCityMode = prefs.cityPreferenceMode;
      if (prefs.preferredLocations != null &&
          prefs.preferredLocations!.isNotEmpty) {
        preferredCities = List<String>.from(prefs.preferredLocations!);
      }
      if (prefs.preferredCountries != null &&
          prefs.preferredCountries!.isNotEmpty) {
        preferredCountries = List<String>.from(prefs.preferredCountries!);
      }
      final strict = prefs.strictFilters;
      if (strict != null) {
        prefReligionStrict = strict['religion'] ?? false;
        prefMotherTongueStrict = strict['motherTongue'] ?? false;
        prefEducationStrict = strict['education'] ?? false;
        prefMaritalStatusStrict = strict['maritalStatus'] ?? false;
        prefIncomeStrict = strict['income'] ?? false;
        prefDietStrict = strict['diet'] ?? false;
        prefDrinkStrict = strict['drinking'] ?? false;
        prefSmokeStrict = strict['smoking'] ?? false;
        prefSettledAbroadStrict = strict['settledAbroad'] ?? false;
        prefBodyTypeStrict = strict['bodyType'] ?? false;
      }
    }
  }

  String get subjectName {
    if (creatingFor == null) return '';
    switch (creatingFor) {
      case 'son':
        return 'your son';
      case 'daughter':
        return 'your daughter';
      case 'brother':
        return 'your brother';
      case 'sister':
        return 'your sister';
      case 'friend':
        return 'your friend';
      case 'relative':
        return 'your relative';
      default:
        return '';
    }
  }

  bool get isForSelf => creatingFor == null;

  /// Name must have at least 2 words, each word starting with an uppercase letter.
  static bool isNameValid(String name) {
    final words = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.length < 2) return false;
    for (final w in words) {
      if (w.isEmpty || w[0] != w[0].toUpperCase()) return false;
    }
    return true;
  }

  /// True if [dob] is non-null and the person is at least 18 today.
  static bool isAtLeast18(DateTime? dob) {
    if (dob == null) return false;
    final now = DateTime.now();
    final cutoff = DateTime(now.year - 18, now.month, now.day);
    return !dob.isAfter(cutoff);
  }

  /// Format name as title case (first letter of each word uppercase).
  static String toTitleCase(String name) {
    if (name.trim().isEmpty) return name;
    return name
        .trim()
        .split(RegExp(r'\s+'))
        .map((w) {
          if (w.isEmpty) return w;
          return w[0].toUpperCase() +
              (w.length > 1 ? w.substring(1).toLowerCase() : '');
        })
        .join(' ');
  }

  String get subjectPossessive {
    if (creatingFor == null) return 'Your';
    switch (creatingFor) {
      case 'son':
      case 'brother':
        return 'His';
      case 'daughter':
      case 'sister':
        return 'Her';
      default:
        return 'Their';
    }
  }

  List<String> get _parsedLocation {
    return location
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  List<String> get _parsedHometown {
    return hometown
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  List<String> get _parsedLanguages {
    return languagesSpoken
            ?.split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList() ??
        [];
  }

  /// Map UI role labels to backend enum values.
  /// UI: null (self), son, daughter, brother, sister, friend, relative
  /// Backend: self, parent, guardian, sibling, friend
  static String _mapRoleForBackend(String uiValue) {
    switch (uiValue) {
      case 'son':
      case 'daughter':
        return 'parent';
      case 'brother':
      case 'sister':
        return 'sibling';
      case 'relative':
        return 'guardian';
      case 'friend':
        return 'friend';
      default:
        return 'self';
    }
  }

  /// Build a complete JSON payload from ALL form fields.
  /// This bypasses the UserProfile model to ensure every field is sent.
  Map<String, dynamic> toFullJson() {
    final loc = _parsedLocation;
    final ht = _parsedHometown;

    final json = <String, dynamic>{
      'name': name,
      if (gender != null) 'gender': gender,
      if (dateOfBirth != null)
        'dateOfBirth': dateOfBirth!.toIso8601String().split('T').first,
      if (bio.isNotEmpty) 'aboutMe': bio,
      if (loc.isNotEmpty) 'currentCity': loc[0],
      if (loc.length > 1) 'currentCountry': loc[1],
      if (ht.isNotEmpty) 'originCity': ht[0],
      if (ht.length > 1) 'originCountry': ht[1],
      if (motherTongue != null) 'motherTongue': motherTongue,
      if (_parsedLanguages.isNotEmpty) 'languagesSpoken': _parsedLanguages,
      if (photos.isNotEmpty) 'photoUrls': photos,
      if (selectedInterests.isNotEmpty) 'interests': selectedInterests,
      if (creationLat != null) 'creationLat': creationLat,
      if (creationLng != null) 'creationLng': creationLng,
      if (creationAt != null) 'creationAt': creationAt!.toIso8601String(),
      if (creationAddress != null) 'creationAddress': creationAddress,
    };

    // ── Matrimony extensions ──
    final mat = <String, dynamic>{};
    if (creatingFor != null) {
      mat['roleManagingProfile'] = _mapRoleForBackend(creatingFor!);
    }
    if (religion != null) mat['religion'] = religion;
    if (community != null) mat['casteOrCommunity'] = community;
    if (motherTongue != null) mat['motherTongue'] = motherTongue;
    if (maritalStatus != null) mat['maritalStatus'] = maritalStatus;
    if (heightCm != null) mat['heightCm'] = int.tryParse(heightCm!) ?? heightCm;
    if (bodyType != null) mat['bodyType'] = bodyType;
    if (complexion != null) mat['complexion'] = complexion;
    if (disability != null) mat['disability'] = disability;
    final deg =
        education ??
        (educationEntries.isNotEmpty ? educationEntries.first.degree : null);
    if (deg != null) mat['educationDegree'] = deg;
    if (educationEntries.isNotEmpty &&
        educationEntries.first.institution != null) {
      mat['educationInstitution'] = educationEntries.first.institution;
    }
    if (occupation != null) mat['occupation'] = occupation;
    if (company != null) mat['employer'] = company;
    if (sector != null) mat['industry'] = sector;
    if (workLocation != null) mat['workLocation'] = workLocation;
    if (settledAbroad != null) mat['settledAbroad'] = settledAbroad;
    if (willingToRelocate != null) mat['willingToRelocate'] = willingToRelocate;
    if (income != null) mat['incomeRange'] = {'minLabel': income};
    if (diet != null) mat['diet'] = diet;
    if (drinking != null) mat['drinking'] = drinking;
    if (smoking != null) mat['smoking'] = smoking;
    if (exercise != null) mat['exercise'] = exercise;
    if (pets != null) mat['pets'] = pets;

    // Family
    final fam = <String, dynamic>{};
    if (familyType != null) fam['familyType'] = familyType;
    if (familyValues != null) fam['familyValues'] = familyValues;
    if (fatherOccupation != null) fam['fatherOccupation'] = fatherOccupation;
    if (motherOccupation != null) fam['motherOccupation'] = motherOccupation;
    if (fatherAge != null) fam['fatherAge'] = fatherAge;
    if (motherAge != null) fam['motherAge'] = motherAge;
    if (familyLocation != null) fam['familyLocation'] = familyLocation;
    if (familyBasedOutOfCountry != null) {
      fam['familyBasedOutOfCountry'] = familyBasedOutOfCountry;
    }
    if (householdIncome != null) fam['householdIncome'] = householdIncome;
    final sibCount = _computeSiblings();
    if (sibCount != null) fam['siblingsCount'] = sibCount;
    if (siblingBrothers != null) fam['brothers'] = siblingBrothers;
    if (siblingSisters != null) fam['sisters'] = siblingSisters;
    if (fam.isNotEmpty) mat['familyDetails'] = fam;

    // Horoscope — only include if user actually filled horoscope fields
    final hor = <String, dynamic>{};
    if (manglik != null) hor['manglik'] = manglik;
    if (rashi != null) hor['rashi'] = rashi;
    if (nakshatra != null) hor['nakshatra'] = nakshatra;
    if (gotra != null) hor['gotra'] = gotra;
    if (birthTime != null) hor['timeOfBirth'] = birthTime;
    if (birthPlace != null) hor['birthPlace'] = birthPlace;
    if (hor.isNotEmpty && dateOfBirth != null) {
      hor['dateOfBirth'] = dateOfBirth!.toIso8601String().split('T').first;
    }
    if (hor.isNotEmpty) mat['horoscope'] = hor;

    // About fields (education & career free-text)
    if (aboutEducation != null && aboutEducation!.isNotEmpty) {
      mat['aboutEducation'] = aboutEducation;
    }
    if (aboutCareer != null && aboutCareer!.isNotEmpty) {
      mat['aboutCareer'] = aboutCareer;
    }

    // Education entries — only include entries that have at least a degree
    final validEntries = educationEntries
        .map(
          (e) => <String, dynamic>{
            if (e.degree != null) 'degree': e.degree,
            if (e.institution != null) 'institution': e.institution,
            if (e.graduationYear != null) 'graduationYear': e.graduationYear,
            if (e.scoreCountry != null) 'scoreCountry': e.scoreCountry,
            if (e.scoreType != null) 'scoreType': e.scoreType,
          },
        )
        .where((m) => m.isNotEmpty)
        .toList();
    if (validEntries.isNotEmpty) {
      mat['educationEntries'] = validEntries;
    }

    if (mat.isNotEmpty) json['matrimonyExtensions'] = mat;

    // ── Dating extensions ──
    final dat = <String, dynamic>{};
    if (datingIntent != null) dat['datingIntent'] = datingIntent;
    if (promptAnswer.isNotEmpty) {
      dat['prompts'] = [
        {
          'questionId': 'default',
          'questionText': 'About me',
          'answer': promptAnswer,
        },
      ];
    }
    if (dat.isNotEmpty) json['datingExtensions'] = dat;

    // ── Partner preferences ──
    final pref = <String, dynamic>{};
    if (interestedIn != null) pref['genderPreference'] = interestedIn;
    if (prefAgeMin != null) pref['ageMin'] = prefAgeMin;
    if (prefAgeMax != null) pref['ageMax'] = prefAgeMax;
    if (prefHeightMinCm != null) pref['heightMinCm'] = prefHeightMinCm;
    if (prefHeightMaxCm != null) pref['heightMaxCm'] = prefHeightMaxCm;
    if (preferredBodyTypes.isNotEmpty) {
      pref['preferredBodyTypes'] = preferredBodyTypes;
    }
    if (prefReligion != null) pref['preferredReligions'] = [prefReligion];
    if (prefMotherTongue != null) {
      pref['preferredMotherTongues'] = [prefMotherTongue];
    }
    if (prefEducation != null) pref['educationPreference'] = prefEducation;
    if (prefMaritalStatus != null) {
      pref['maritalStatusPreference'] = [prefMaritalStatus];
    }
    if (prefDiet != null) pref['dietPreference'] = prefDiet;
    if (prefIncome != null) pref['incomePreference'] = prefIncome;
    if (prefDrink != null) pref['drinkingPreference'] = prefDrink;
    if (prefSmoke != null) pref['smokingPreference'] = prefSmoke;
    if (prefSettledAbroad != null) {
      pref['settledAbroadPreference'] = prefSettledAbroad;
    }
    if (prefCityMode != null) pref['cityPreferenceMode'] = prefCityMode;
    if (preferredCities.isNotEmpty) {
      pref['preferredLocations'] = preferredCities;
    }
    if (preferredCountries.isNotEmpty) {
      pref['preferredCountries'] = preferredCountries;
    }

    // Strict filters
    final strict = <String, dynamic>{};
    if (prefReligionStrict) strict['religion'] = true;
    if (prefMotherTongueStrict) strict['motherTongue'] = true;
    if (prefEducationStrict) strict['education'] = true;
    if (prefMaritalStatusStrict) strict['maritalStatus'] = true;
    if (prefIncomeStrict) strict['income'] = true;
    if (prefDietStrict) strict['diet'] = true;
    if (prefDrinkStrict) strict['drinking'] = true;
    if (prefSmokeStrict) strict['smoking'] = true;
    if (prefSettledAbroadStrict) strict['settledAbroad'] = true;
    if (prefBodyTypeStrict) strict['bodyType'] = true;
    if (strict.isNotEmpty) pref['strictFilters'] = strict;

    if (pref.isNotEmpty) json['partnerPreferences'] = pref;

    return json;
  }

  int? _computeSiblings() {
    final b = siblingBrothers != null ? int.tryParse(siblingBrothers!) : null;
    final s = siblingSisters != null ? int.tryParse(siblingSisters!) : null;
    if (b == null && s == null) {
      return siblings != null ? int.tryParse(siblings!) : null;
    }
    return (b ?? 0) + (s ?? 0);
  }
}
