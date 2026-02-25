import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/dynamic_gradient_background.dart';

/// Week 14 — Signup 2.0: Indian identity layer (origin, language, community, family, veg).
class IdentityOnboardingScreen extends StatefulWidget {
  const IdentityOnboardingScreen({super.key});

  @override
  State<IdentityOnboardingScreen> createState() =>
      _IdentityOnboardingScreenState();
}

class _IdentityOnboardingScreenState extends State<IdentityOnboardingScreen> {
  final _pageController = PageController();
  int _step = 0;

  String? _selectedGender;
  String? _selectedInterest; // who are you interested in
  String? _selectedRelationship; // fun/casual, serious, etc.
  String? _selectedOrigin;
  String? _selectedLive; // where do you live
  bool _liveSameAsOrigin = false;
  String? _selectedLanguage;
  String? _selectedHeritage;
  final List<String> _communityTags = [];
  double _familyOrientation = 0.5;
  String? _diet;

  Future<String?> _fetchCurrentLocationLabel() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }
      if (permission == LocationPermission.deniedForever) return null;
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      );
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isEmpty) return null;
      final p = placemarks.first;
      final parts = [
        p.locality,
        p.administrativeArea,
        p.country,
      ].whereType<String>().where((e) => e.isNotEmpty).toList();
      return parts.isNotEmpty ? parts.join(', ') : (p.country ?? 'Unknown');
    } catch (_) {
      return null;
    }
  }

  static const _genders = [
    'Woman',
    'Man',
    'Non-binary',
    'Prefer to self-describe',
  ];
  static const _interests = ['Men', 'Women', 'Everyone', 'Non-binary'];
  static const _relationships = [
    'Fun / casual',
    'Serious relationship',
    'Marriage',
    'Friends first',
    'Open to see',
    'Still figuring it out',
  ];
  static const _origins = [
    'India',
    'UK',
    'USA',
    'UAE',
    'Canada',
    'Australia',
    'Other',
  ];
  static const _languages = [
    'English',
    'Hindi',
    'Tamil',
    'Telugu',
    'Bengali',
    'Gujarati',
    'Punjabi',
    'Other',
  ];
  static const _heritage = [
    'North Indian',
    'South Indian',
    'East Indian',
    'West Indian',
    'NRI / diaspora',
    'Mixed',
    'Other',
  ];
  static const _communityTagsList = [
    'Tech',
    'Healthcare',
    'Finance',
    'Creative',
    'Academia',
    'Entrepreneur',
    'Student',
  ];
  static const _diets = ['Vegetarian', 'Vegan', 'Non-vegetarian', 'Flexible'];

  static const _totalSteps = 8;

  void _goToNextStep() {
    if (_step < _totalSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
      setState(() => _step++);
    } else {
      context.go('/profile-wizard');
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;

    return Scaffold(
      body: DynamicGradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              Row(
                children: [
                  const Spacer(),
                  TextButton(
                    onPressed: () => context.go('/profile-wizard'),
                    child: Text(
                      'Skip',
                      style: TextStyle(
                        color: accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              LinearProgressIndicator(
                value: (_step + 1) / _totalSteps,
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(accent),
              ),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (i) => setState(() => _step = i),
                  children: [
                    _GenderAndInterestStep(
                      selectedGender: _selectedGender,
                      selectedInterest: _selectedInterest,
                      genderOptions: _genders,
                      interestOptions: _interests,
                      onGenderSelect: (v) =>
                          setState(() => _selectedGender = v),
                      onInterestSelect: (v) {
                        setState(() => _selectedInterest = v);
                        _goToNextStep();
                      },
                    ),
                    _RelationshipStep(
                      selected: _selectedRelationship,
                      options: _relationships,
                      onSelect: (v) {
                        setState(() => _selectedRelationship = v);
                        _goToNextStep();
                      },
                    ),
                    _LocationStep(
                      locationFuture: _fetchCurrentLocationLabel(),
                      selectedOrigin: _selectedOrigin,
                      selectedLive: _liveSameAsOrigin
                          ? _selectedOrigin
                          : _selectedLive,
                      liveSameAsOrigin: _liveSameAsOrigin,
                      options: _origins,
                      onOriginSelect: (v) =>
                          setState(() => _selectedOrigin = v),
                      onLiveSelect: (v) => setState(() => _selectedLive = v),
                      onLiveSameAsOriginChanged: (v) => setState(() {
                        _liveSameAsOrigin = v;
                        if (v && _selectedOrigin != null) {
                          _selectedLive = _selectedOrigin;
                        }
                      }),
                    ),
                    _LanguageStep(
                      selected: _selectedLanguage,
                      options: _languages,
                      onSelect: (v) => setState(() => _selectedLanguage = v),
                    ),
                    _HeritageStep(
                      selected: _selectedHeritage,
                      options: _heritage,
                      onSelect: (v) => setState(() => _selectedHeritage = v),
                    ),
                    _CommunityStep(
                      selected: _communityTags,
                      options: _communityTagsList,
                      onChanged: (v) => setState(() {
                        _communityTags.clear();
                        _communityTags.addAll(v);
                      }),
                    ),
                    _FamilyStep(
                      value: _familyOrientation,
                      onChanged: (v) => setState(() => _familyOrientation = v),
                    ),
                    _DietStep(
                      selected: _diet,
                      options: _diets,
                      onSelect: (v) => setState(() => _diet = v),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    if (_step > 0)
                      TextButton(
                        onPressed: () {
                          _pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                          setState(() => _step--);
                        },
                        child: const Text('Back'),
                      ),
                    const Spacer(),
                    if (_step > 1)
                      FilledButton(
                        onPressed: () {
                          if (_step < _totalSteps - 1) {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                            setState(() => _step++);
                          } else {
                            context.go('/onboarding');
                          }
                        },
                        child: Text(
                          _step < _totalSteps - 1 ? 'Next' : 'Continue',
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GenderAndInterestStep extends StatelessWidget {
  const _GenderAndInterestStep({
    required this.selectedGender,
    required this.selectedInterest,
    required this.genderOptions,
    required this.interestOptions,
    required this.onGenderSelect,
    required this.onInterestSelect,
  });
  final String? selectedGender;
  final String? selectedInterest;
  final List<String> genderOptions;
  final List<String> interestOptions;
  final ValueChanged<String> onGenderSelect;
  final ValueChanged<String> onInterestSelect;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final primary = Theme.of(context).colorScheme.primary;
    final showInterest = selectedGender != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),
          Text(
            'How do you identify?',
            style: AppTypography.headlineMedium.copyWith(
              color: onSurface,
              fontWeight: FontWeight.w600,
            ),
          ).animate().fadeIn().slideY(begin: -0.05, end: 0),
          const SizedBox(height: 8),
          Text(
            'We use this to personalise your experience and matches.',
            style: AppTypography.bodyMedium.copyWith(
              color: onSurface.withValues(alpha: 0.85),
            ),
          ).animate().fadeIn(delay: 80.ms),
          const SizedBox(height: 24),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: genderOptions
                .map(
                  (o) => ChoiceChip(
                    label: Text(o),
                    selected: selectedGender == o,
                    onSelected: (_) => onGenderSelect(o),
                  ),
                )
                .toList(),
          ).animate().fadeIn(delay: 120.ms).slideY(begin: 0.05, end: 0),
          if (showInterest) ...[
            const SizedBox(height: 40),
            Text(
                  'Who are you interested in?',
                  style: AppTypography.headlineSmall.copyWith(
                    color: onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                )
                .animate()
                .fadeIn(duration: 300.ms)
                .slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic),
            const SizedBox(height: 8),
            Text(
              'Tap one — we\'ll take you to the next step.',
              style: AppTypography.bodyMedium.copyWith(
                color: onSurface.withValues(alpha: 0.8),
              ),
            ).animate().fadeIn(delay: 100.ms),
            const SizedBox(height: 20),
            Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: interestOptions
                      .map(
                        (o) => ChoiceChip(
                          label: Text(o),
                          selected: selectedInterest == o,
                          selectedColor: primary.withValues(alpha: 0.25),
                          onSelected: (_) => onInterestSelect(o),
                        ),
                      )
                      .toList(),
                )
                .animate()
                .fadeIn(delay: 150.ms)
                .slideY(begin: 0.15, end: 0, curve: Curves.easeOutCubic),
          ],
        ],
      ),
    );
  }
}

class _RelationshipStep extends StatelessWidget {
  const _RelationshipStep({
    required this.selected,
    required this.options,
    required this.onSelect,
  });
  final String? selected;
  final List<String> options;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final primary = Theme.of(context).colorScheme.primary;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),
          Text(
            'What are you looking for?',
            style: AppTypography.headlineMedium.copyWith(
              color: onSurface,
              fontWeight: FontWeight.w600,
            ),
          ).animate().fadeIn().slideY(begin: -0.05, end: 0),
          const SizedBox(height: 8),
          Text(
            'Tap one — no pressure, you can change this anytime.',
            style: AppTypography.bodyMedium.copyWith(
              color: onSurface.withValues(alpha: 0.85),
            ),
          ).animate().fadeIn(delay: 80.ms),
          const SizedBox(height: 28),
          ...options.asMap().entries.map((entry) {
            final i = entry.key;
            final o = entry.value;
            final isSelected = selected == o;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child:
                  Material(
                        color: isSelected
                            ? primary.withValues(alpha: 0.15)
                            : Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(16),
                        child: InkWell(
                          onTap: () => onSelect(o),
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 18,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isSelected
                                      ? Icons.check_circle
                                      : Icons.circle_outlined,
                                  color: isSelected
                                      ? primary
                                      : onSurface.withValues(alpha: 0.5),
                                  size: 28,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    o,
                                    style: AppTypography.titleMedium.copyWith(
                                      color: onSurface,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                      .animate()
                      .fadeIn(delay: (100 + i * 50).ms)
                      .slideX(begin: 0.05, end: 0, curve: Curves.easeOutCubic),
            );
          }),
        ],
      ),
    );
  }
}

class _LocationStep extends StatefulWidget {
  const _LocationStep({
    required this.locationFuture,
    required this.selectedOrigin,
    required this.selectedLive,
    required this.liveSameAsOrigin,
    required this.options,
    required this.onOriginSelect,
    required this.onLiveSelect,
    required this.onLiveSameAsOriginChanged,
  });
  final Future<String?> locationFuture;
  final String? selectedOrigin;
  final String? selectedLive;
  final bool liveSameAsOrigin;
  final List<String> options;
  final ValueChanged<String> onOriginSelect;
  final ValueChanged<String> onLiveSelect;
  final ValueChanged<bool> onLiveSameAsOriginChanged;

  @override
  State<_LocationStep> createState() => _LocationStepState();
}

class _LocationStepState extends State<_LocationStep> {
  String? _currentLocation;
  bool _locationLoading = true;
  String? _locationError;

  @override
  void initState() {
    super.initState();
    widget.locationFuture
        .then((value) {
          if (mounted) {
            setState(() {
              _currentLocation = value;
              _locationLoading = false;
            });
          }
        })
        .catchError((_) {
          if (mounted) {
            setState(() {
              _locationLoading = false;
              _locationError = 'Unable to get location';
            });
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final primary = Theme.of(context).colorScheme.primary;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),
          // Current location
          if (_locationLoading)
            Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: primary,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Getting your location…',
                  style: AppTypography.bodyMedium.copyWith(
                    color: onSurface.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ).animate().fadeIn(),
          if (!_locationLoading && _currentLocation != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.location_on, color: primary, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'You are in $_currentLocation',
                      style: AppTypography.titleSmall.copyWith(
                        color: onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn().slideY(begin: -0.05, end: 0),
            const SizedBox(height: 24),
          ],
          if (!_locationLoading &&
              _currentLocation == null &&
              _locationError != null)
            Text(
              _locationError!,
              style: AppTypography.bodySmall.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          if (!_locationLoading &&
              _currentLocation == null &&
              _locationError == null)
            Text(
              'Location not available. You can still set where you\'re from and where you live.',
              style: AppTypography.bodySmall.copyWith(
                color: onSurface.withValues(alpha: 0.7),
              ),
            ),
          if (!_locationLoading) const SizedBox(height: 24),
          // Where are you from?
          Text(
            'Where are you from?',
            style: AppTypography.headlineSmall.copyWith(
              color: onSurface,
              fontWeight: FontWeight.w600,
            ),
          ).animate().fadeIn(delay: 80.ms),
          const SizedBox(height: 6),
          Text(
            'Origin helps us show you relevant communities.',
            style: AppTypography.bodyMedium.copyWith(
              color: onSurface.withValues(alpha: 0.85),
            ),
          ).animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.options
                .map(
                  (o) => FilterChip(
                    label: Text(o),
                    selected: widget.selectedOrigin == o,
                    onSelected: (_) => widget.onOriginSelect(o),
                  ),
                )
                .toList(),
          ).animate().fadeIn(delay: 120.ms).slideY(begin: 0.03, end: 0),
          const SizedBox(height: 28),
          // Same as where I'm from
          CheckboxListTile(
            value: widget.liveSameAsOrigin,
            onChanged: (v) => widget.onLiveSameAsOriginChanged(v ?? false),
            title: Text(
              'Same as where I\'m from',
              style: AppTypography.bodyLarge.copyWith(color: onSurface),
            ),
            subtitle: widget.liveSameAsOrigin
                ? Text(
                    'We\'ll use ${widget.selectedOrigin ?? 'your origin'} as where you live.',
                    style: AppTypography.bodySmall.copyWith(
                      color: onSurface.withValues(alpha: 0.7),
                    ),
                  )
                : null,
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          ).animate().fadeIn(delay: 140.ms),
          const SizedBox(height: 16),
          // Where do you live?
          Text(
            'Where do you live?',
            style: AppTypography.headlineSmall.copyWith(
              color: onSurface,
              fontWeight: FontWeight.w600,
            ),
          ).animate().fadeIn(delay: 160.ms),
          const SizedBox(height: 6),
          Text(
            'Your current city or country. Used for local matches and events.',
            style: AppTypography.bodyMedium.copyWith(
              color: onSurface.withValues(alpha: 0.85),
            ),
          ).animate().fadeIn(delay: 180.ms),
          const SizedBox(height: 12),
          Opacity(
            opacity: widget.liveSameAsOrigin ? 0.6 : 1,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.options
                  .map(
                    (o) => FilterChip(
                      label: Text(o),
                      selected:
                          (widget.liveSameAsOrigin
                              ? widget.selectedOrigin
                              : widget.selectedLive) ==
                          o,
                      onSelected: widget.liveSameAsOrigin
                          ? null
                          : (_) => widget.onLiveSelect(o),
                    ),
                  )
                  .toList(),
            ),
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.03, end: 0),
        ],
      ),
    );
  }
}

class _LanguageStep extends StatelessWidget {
  const _LanguageStep({
    required this.selected,
    required this.options,
    required this.onSelect,
  });
  final String? selected;
  final List<String> options;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return _StepFrame(
      title: 'Preferred language',
      subtitle: 'Optional — we’ll use this for content and matches.',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: options
            .map(
              (o) => ChoiceChip(
                label: Text(o),
                selected: selected == o,
                onSelected: (_) => onSelect(o),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _HeritageStep extends StatelessWidget {
  const _HeritageStep({
    required this.selected,
    required this.options,
    required this.onSelect,
  });
  final String? selected;
  final List<String> options;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return _StepFrame(
      title: 'Heritage / type of Indian',
      subtitle:
          'Optional — helps us connect you with relevant communities and events.',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: options
            .map(
              (o) => ChoiceChip(
                label: Text(o),
                selected: selected == o,
                onSelected: (_) => onSelect(o),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _CommunityStep extends StatelessWidget {
  const _CommunityStep({
    required this.selected,
    required this.options,
    required this.onChanged,
  });
  final List<String> selected;
  final List<String> options;
  final ValueChanged<List<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    return _StepFrame(
      title: 'Community tags (optional)',
      subtitle: 'Select any that apply — helps with circles and events.',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: options
            .map(
              (o) => FilterChip(
                label: Text(o),
                selected: selected.contains(o),
                onSelected: (_) {
                  final next = List<String>.from(selected);
                  if (next.contains(o)) {
                    next.remove(o);
                  } else {
                    next.add(o);
                  }
                  onChanged(next);
                },
              ),
            )
            .toList(),
      ),
    );
  }
}

class _FamilyStep extends StatelessWidget {
  const _FamilyStep({required this.value, required this.onChanged});
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return _StepFrame(
      title: 'Family orientation',
      subtitle: 'Slide to reflect your preference — no wrong answer.',
      child: Column(
        children: [
          Slider(value: value, onChanged: onChanged, divisions: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Traditional', style: AppTypography.bodySmall),
              Text('Progressive', style: AppTypography.bodySmall),
            ],
          ),
        ],
      ),
    );
  }
}

class _DietStep extends StatelessWidget {
  const _DietStep({
    required this.selected,
    required this.options,
    required this.onSelect,
  });
  final String? selected;
  final List<String> options;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return _StepFrame(
      title: 'Diet / lifestyle',
      subtitle: 'Helps with date ideas and filters.',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: options
            .map(
              (o) => ChoiceChip(
                label: Text(o),
                selected: selected == o,
                onSelected: (_) => onSelect(o),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _StepFrame extends StatelessWidget {
  const _StepFrame({
    required this.title,
    required this.subtitle,
    required this.child,
  });
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),
          Text(
            title,
            style: AppTypography.headlineMedium.copyWith(
              color: onSurface,
              fontWeight: FontWeight.w600,
            ),
          ).animate().fadeIn().slideY(begin: -0.05, end: 0),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: AppTypography.bodyMedium.copyWith(
              color: onSurface.withValues(alpha: 0.85),
            ),
          ).animate().fadeIn(delay: 80.ms),
          const SizedBox(height: 32),
          child.animate().fadeIn(delay: 150.ms).slideY(begin: 0.03, end: 0),
        ],
      ),
    );
  }
}
