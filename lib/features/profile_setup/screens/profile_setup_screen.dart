import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/location/app_location_service.dart';
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

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final _formData = ProfileFormData();
  bool _isCompleting = false;

  late List<_StepInfo> _steps;
  static final _locationService = AppLocationService.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureLocationAndProceed());
  }

  /// Redirect to location-required if permission not granted (app must not run without location).
  Future<void> _ensureLocationAndProceed() async {
    if (!mounted) return;
    final access = await _locationService.checkAccess();
    if (access == LocationAccess.granted) return;
    if (!mounted) return;
    context.go('/location-required?then=${Uri.encodeComponent('/profile-setup')}');
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
      // Last step: capture exact creation location then complete
      setState(() => _isCompleting = true);
      final creation = await _locationService.getCurrentCreationLocation();
      if (!mounted) return;
      if (creation == null) {
        setState(() => _isCompleting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.profileCreationLocationError),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        return;
      }
      _formData.creationLat = creation.latitude;
      _formData.creationLng = creation.longitude;
      _formData.creationAt = creation.capturedAt;
      _formData.creationAddress = creation.address;

      // Persist creation location to profile for safety/support tracking
      try {
        final repo = ref.read(profileRepositoryProvider);
        final existing = await repo.getMyProfile();
        if (existing != null) {
          await repo.updateMyProfile(existing.copyWith(
            creationLat: creation.latitude,
            creationLng: creation.longitude,
            creationAt: creation.capturedAt,
            creationAddress: creation.address,
          ));
        }
      } catch (_) {
        // Non-fatal: creation location is in formData; backend may persist later
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
    final mode = ref.watch(appModeProvider) ?? AppMode.dating;
    final l = AppLocalizations.of(context)!;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final accent = Theme.of(context).colorScheme.primary;

    _steps = _buildSteps(mode, l);
    final progress = (_currentStep + 1) / _steps.length;
    final currentStep = _steps[_currentStep];

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
                child: Row(
                  children: [
                    if (_currentStep > 0)
                      IconButton(
                        onPressed: _back,
                        icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                      )
                    else
                      const SizedBox(width: 48),
                    const Spacer(),
                    ...List.generate(_steps.length, (i) {
                      return Container(
                        width: i == _currentStep ? 24 : 8,
                        height: 4,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: i <= _currentStep
                              ? accent
                              : onSurface.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      );
                    }),
                    const Spacer(),
                    Text(
                      '${_currentStep + 1}/${_steps.length}',
                      style: AppTypography.labelMedium.copyWith(
                        color: onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: onSurface.withValues(alpha: 0.08),
                    valueColor: AlwaysStoppedAnimation(accent),
                    minHeight: 3,
                  ),
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: _steps.map((s) => s.widget).toList(),
                ),
              ),

              // Bottom buttons
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: FilledButton(
                        onPressed: _canProceed ? _next : null,
                        style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text(
                          _currentStep < _steps.length - 1 ? l.next : l.getStarted,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    if (currentStep.skippable && _currentStep < _steps.length - 1) ...[
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _skip,
                        child: Text(
                          l.skipForNow,
                          style: AppTypography.bodySmall.copyWith(
                            color: onSurface.withValues(alpha: 0.5),
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
    final void Function() onChanged = () => setState(() {});
    if (mode.isMatrimony) {
      return [
        _StepInfo(
          label: l.profileStepIdentity,
          widget: StepIdentity(mode: mode, formData: _formData, onChanged: onChanged),
          hasMandatory: true,
          skippable: false,
          isMandatorySatisfied: (d) =>
            ProfileFormData.isNameValid(d.name) &&
            d.gender != null &&
            d.dateOfBirth != null &&
            ProfileFormData.isAtLeast18(d.dateOfBirth) &&
            d.confirmedAge18,
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
          widget: StepDetails(mode: mode, formData: _formData, onChanged: onChanged),
          hasMandatory: false,
          skippable: true,
        ),
        _StepInfo(
          label: l.profileStepPreferences,
          widget: StepPreferences(mode: mode, formData: _formData, onChanged: onChanged),
          hasMandatory: false,
          skippable: true,
        ),
      ];
    }
    return [
      _StepInfo(
        label: l.profileStepIdentity,
        widget: StepIdentity(mode: mode, formData: _formData, onChanged: onChanged),
        hasMandatory: true,
        skippable: false,
        isMandatorySatisfied: (d) =>
          ProfileFormData.isNameValid(d.name) &&
          d.gender != null &&
          d.dateOfBirth != null &&
          ProfileFormData.isAtLeast18(d.dateOfBirth) &&
          d.confirmedAge18,
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
        widget: StepDetails(mode: mode, formData: _formData, onChanged: onChanged),
        hasMandatory: false,
        skippable: true,
      ),
      _StepInfo(
        label: l.profileStepPreferences,
        widget: StepPreferences(mode: mode, formData: _formData, onChanged: onChanged),
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
  String? scoreType;     // e.g. First class, 2:1, GPA 3.5
}

/// Degrees that do not show university/college (e.g. High School, Diploma).
bool educationEntryShowsInstitution(String? degree) {
  if (degree == null) return true;
  return degree != 'High School' && degree != 'Diploma';
}

/// Shared mutable form data passed through all steps.
class ProfileFormData {
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

  // Interests
  List<String> selectedInterests = [];

  // Partner preferences (persisted)
  int? prefAgeMin;
  int? prefAgeMax;
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

  String get subjectName {
    if (creatingFor == null) return '';
    switch (creatingFor) {
      case 'son': return 'your son';
      case 'daughter': return 'your daughter';
      case 'brother': return 'your brother';
      case 'sister': return 'your sister';
      case 'friend': return 'your friend';
      case 'relative': return 'your relative';
      default: return '';
    }
  }

  bool get isForSelf => creatingFor == null;

  /// Name must have at least 2 words, each word starting with an uppercase letter.
  static bool isNameValid(String name) {
    final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
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
    return name.trim().split(RegExp(r'\s+')).map((w) {
      if (w.isEmpty) return w;
      return w[0].toUpperCase() + (w.length > 1 ? w.substring(1).toLowerCase() : '');
    }).join(' ');
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
}
