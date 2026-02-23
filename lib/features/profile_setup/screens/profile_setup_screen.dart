import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/mode/app_mode.dart';
import '../../../core/mode/mode_provider.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/app_localizations.dart';
import '../widgets/step_identity.dart';
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

  late List<_StepInfo> _steps;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  bool get _canProceed {
    final step = _steps[_currentStep];
    if (!step.hasMandatory) return true;
    return step.isMandatorySatisfied(_formData);
  }

  void _next() {
    FocusScope.of(context).unfocus();
    if (_currentStep < _steps.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep++);
    } else {
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
    return [
      _StepInfo(
        label: l.profileStepIdentity,
        widget: StepIdentity(mode: mode, formData: _formData, onChanged: () => setState(() {})),
        hasMandatory: true,
        skippable: false,
        isMandatorySatisfied: (d) => d.name.trim().isNotEmpty && d.gender != null && d.dateOfBirth != null,
      ),
      _StepInfo(
        label: l.profileStepPhotos,
        widget: StepPhotos(formData: _formData, onChanged: () => setState(() {})),
        hasMandatory: false,
        skippable: true,
      ),
      _StepInfo(
        label: l.profileStepDetails,
        widget: StepDetails(mode: mode, formData: _formData, onChanged: () => setState(() {})),
        hasMandatory: false,
        skippable: true,
      ),
      _StepInfo(
        label: l.profileStepPreferences,
        widget: StepPreferences(mode: mode, formData: _formData, onChanged: () => setState(() {})),
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

/// Shared mutable form data passed through all steps.
class ProfileFormData {
  // Identity (mandatory: name, gender, dob)
  String? creatingFor;
  String name = '';
  String? gender;
  DateTime? dateOfBirth;
  String location = '';
  String hometown = '';

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

  // Education & Career
  String? education;
  String? occupation;
  String? income;
  String? company;
  String? workLocation;
  String? settledAbroad;
  String? willingToRelocate;

  // Family
  String? familyType;
  String? familyValues;

  // Horoscope (matrimony)
  String? manglik;
  String? rashi;
  String? nakshatra;
  String? gotra;

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
