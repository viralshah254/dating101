import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/location/place_search_service.dart';
import '../../../core/mode/app_mode.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/app_localizations.dart';
import '../screens/profile_setup_screen.dart';

/// Option lists aligned with Background & details (dropdowns + currency).
const _religionPrefOptions = ['Any', 'Hindu', 'Muslim', 'Christian', 'Sikh', 'Jain', 'Buddhist', 'Parsi', 'Jewish', 'Other'];
const _motherTonguePrefOptions = [
  'Any', 'Hindi', 'Bengali', 'Telugu', 'Marathi', 'Tamil', 'Urdu', 'Gujarati', 'Kannada', 'Malayalam', 'Punjabi',
  'Odia', 'Assamese', 'Kashmiri', 'Sindhi', 'Konkani', 'Nepali', 'Sanskrit', 'English', 'Other',
];
const _educationPrefOptions = ['Any', 'Bachelors+', 'Masters+', 'MBA', 'Medical', 'Engineering', 'PhD', 'High School', 'Diploma'];
const _incomePrefOptionsLPA = ['Any', 'Below Rs 5 LPA', 'Rs 5-10 LPA', 'Rs 10-15 LPA', 'Rs 15-20 LPA', 'Rs 20-50 LPA', 'Rs 50 LPA+'];
const _incomePrefOptionsUSD = ['Any', 'Below \$50k', '\$50k–\$100k', '\$100k–\$150k', '\$150k–\$200k', '\$200k–\$500k', '\$500k+'];
const _cityModeOptions = ['Any', 'Same as me', 'Preferred'];

enum _PlaceMode { country, city }

class StepPreferences extends StatelessWidget {
  const StepPreferences({
    super.key,
    required this.mode,
    required this.formData,
    required this.onChanged,
  });

  final AppMode mode;
  final ProfileFormData formData;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    if (mode.isDating) return _DatingPreferences(formData: formData, onChanged: onChanged);
    return _MatrimonyPreferences(formData: formData, onChanged: onChanged);
  }
}

// ── Dating Preferences ──────────────────────────────────────────────────

class _DatingPreferences extends StatefulWidget {
  const _DatingPreferences({required this.formData, required this.onChanged});
  final ProfileFormData formData;
  final VoidCallback onChanged;

  @override
  State<_DatingPreferences> createState() => _DatingPreferencesState();
}

class _DatingPreferencesState extends State<_DatingPreferences> {
  RangeValues _ageRange = const RangeValues(22, 35);
  double _distance = 50;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final accent = Theme.of(context).colorScheme.primary;

    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your\npreferences',
            style: AppTypography.displayLarge.copyWith(
              color: onSurface,
              fontSize: 32,
              height: 1.15,
            ),
          ).animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 8),
          Text(
            'We\'ll use these to show you relevant people. You can always refine later.',
            style: AppTypography.bodyMedium.copyWith(
              color: onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 32),

          _PrefCard(
            icon: Icons.cake_outlined,
            title: l.ageRange,
            trailing: '${_ageRange.start.toInt()} — ${_ageRange.end.toInt()}',
            child: RangeSlider(
              values: _ageRange,
              min: 18,
              max: 60,
              divisions: 42,
              labels: RangeLabels('${_ageRange.start.toInt()}', '${_ageRange.end.toInt()}'),
              activeColor: accent,
              onChanged: (v) => setState(() => _ageRange = v),
            ),
          ),
          const SizedBox(height: 16),

          _PrefCard(
            icon: Icons.location_on_outlined,
            title: l.distance,
            trailing: '${_distance.toInt()} km',
            child: Slider(
              value: _distance,
              min: 5,
              max: 200,
              divisions: 39,
              label: '${_distance.toInt()} km',
              activeColor: accent,
              onChanged: (v) => setState(() => _distance = v),
            ),
          ),
          const SizedBox(height: 16),

          _PrefCard(
            icon: Icons.chat_bubble_outline,
            title: 'Conversation starter',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text(
                  'Answer a prompt so matches have something to talk about.',
                  style: AppTypography.bodySmall.copyWith(color: onSurface.withValues(alpha: 0.6)),
                ),
                const SizedBox(height: 12),
                _SmartMultiline(
                  value: widget.formData.promptAnswer,
                  hint: 'e.g. Best way to spend a Sunday? Chai and a book...',
                  onChanged: (v) {
                    widget.formData.promptAnswer = v;
                    widget.onChanged();
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ── Matrimony Preferences ───────────────────────────────────────────────

class _MatrimonyPreferences extends StatefulWidget {
  const _MatrimonyPreferences({required this.formData, required this.onChanged});
  final ProfileFormData formData;
  final VoidCallback onChanged;

  @override
  State<_MatrimonyPreferences> createState() => _MatrimonyPreferencesState();
}

class _MatrimonyPreferencesState extends State<_MatrimonyPreferences> {
  RangeValues get _ageRange {
    final min = widget.formData.prefAgeMin ?? 22;
    final max = widget.formData.prefAgeMax ?? 35;
    return RangeValues(min.toDouble(), max.toDouble());
  }

  set _ageRange(RangeValues v) {
    widget.formData.prefAgeMin = v.start.toInt();
    widget.formData.prefAgeMax = v.end.toInt();
    widget.onChanged();
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _autoSelectFromBackground());
  }

  void _autoSelectFromBackground() {
    if (!mounted) return;
    final d = widget.formData;
    var changed = false;
    if (d.prefReligion == null && d.religion != null && d.religion!.isNotEmpty) {
      d.prefReligion = d.religion;
      changed = true;
    }
    if (d.prefMotherTongue == null && d.motherTongue != null && d.motherTongue!.isNotEmpty) {
      d.prefMotherTongue = d.motherTongue;
      changed = true;
    }
    if (d.prefEducation == null) {
      final deg = d.educationEntries.isNotEmpty ? d.educationEntries.first.degree : null;
      if (deg != null && deg.isNotEmpty) {
        if (deg.contains('PhD')) {
          d.prefEducation = 'PhD';
        } else if (deg.contains('MBA')) {
          d.prefEducation = 'MBA';
        } else if (deg.contains('Medical') || deg.contains('MBBS')) {
          d.prefEducation = 'Medical';
        } else if (deg.contains('Engineering') || deg.contains('B.Tech')) {
          d.prefEducation = 'Engineering';
        } else if (deg.contains('Masters') || deg.contains('M.Tech')) {
          d.prefEducation = 'Masters+';
        } else if (deg.contains('Bachelors') || deg.contains('B.Tech')) {
          d.prefEducation = 'Bachelors+';
        }
        if (d.prefEducation != null) { changed = true; }
      }
    }
    if (d.prefDiet == null && d.diet != null && d.diet!.isNotEmpty) {
      d.prefDiet = d.diet;
      changed = true;
    }
    if (d.prefDrink == null && d.drinking != null && d.drinking!.isNotEmpty) {
      d.prefDrink = d.drinking;
      changed = true;
    }
    if (d.prefSmoke == null && d.smoking != null && d.smoking!.isNotEmpty) {
      d.prefSmoke = d.smoking;
      changed = true;
    }
    if (d.prefAgeMin == null && d.dateOfBirth != null) {
      final age = DateTime.now().year - d.dateOfBirth!.year;
      d.prefAgeMin = (age - 5).clamp(18, 60);
      d.prefAgeMax = (age + 5).clamp(18, 60);
      changed = true;
    }
    if (changed) {
      widget.onChanged();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final accent = Theme.of(context).colorScheme.primary;

    final forSelf = widget.formData.isForSelf;
    final subject = widget.formData.subjectName;

    final pageTitle = forSelf ? 'Partner\npreferences' : l.dynPrefsTitle(subject);
    final pageSubtitle = forSelf
        ? 'Help us find the right match. You can refine these anytime.'
        : l.dynPrefsSubtitle(subject);

    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            pageTitle,
            style: AppTypography.displayLarge.copyWith(
              color: onSurface,
              fontSize: 32,
              height: 1.15,
            ),
          ).animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 8),
          Text(
            pageSubtitle,
            style: AppTypography.bodyMedium.copyWith(color: onSurface.withValues(alpha: 0.6)),
          ),
          const SizedBox(height: 32),

          // Age range
          _PrefCard(
            icon: Icons.cake_outlined,
            title: l.ageRange,
            trailing: '${_ageRange.start.toInt()} — ${_ageRange.end.toInt()}',
            child: RangeSlider(
              values: _ageRange,
              min: 18, max: 60, divisions: 42,
              labels: RangeLabels('${_ageRange.start.toInt()}', '${_ageRange.end.toInt()}'),
              activeColor: accent,
              onChanged: (v) => _ageRange = v,
            ),
          ),
          const SizedBox(height: 16),

          _PrefDropdownCard(
            icon: Icons.temple_hindu_outlined,
            title: l.religion,
            value: widget.formData.prefReligion,
            items: _religionPrefOptions,
            strict: widget.formData.prefReligionStrict,
            onChanged: (v) {
              widget.formData.prefReligion = v;
              widget.onChanged();
              setState(() {});
            },
            onStrictChanged: (v) {
              widget.formData.prefReligionStrict = v;
              widget.onChanged();
              setState(() {});
            },
          ),
          const SizedBox(height: 16),

          _PrefDropdownCard(
            icon: Icons.translate,
            title: l.prefMotherTongueQuestion,
            value: widget.formData.prefMotherTongue,
            items: _motherTonguePrefOptions,
            strict: widget.formData.prefMotherTongueStrict,
            onChanged: (v) {
              widget.formData.prefMotherTongue = v;
              widget.onChanged();
              setState(() {});
            },
            onStrictChanged: (v) {
              widget.formData.prefMotherTongueStrict = v;
              widget.onChanged();
              setState(() {});
            },
          ),
          const SizedBox(height: 16),

          _PrefDropdownCard(
            icon: Icons.school_outlined,
            title: l.educationLevel,
            value: widget.formData.prefEducation,
            items: _educationPrefOptions,
            strict: widget.formData.prefEducationStrict,
            onChanged: (v) {
              widget.formData.prefEducation = v;
              widget.onChanged();
              setState(() {});
            },
            onStrictChanged: (v) {
              widget.formData.prefEducationStrict = v;
              widget.onChanged();
              setState(() {});
            },
          ),
          const SizedBox(height: 16),

          _PrefDropdownCard(
            icon: Icons.person_outline,
            title: l.maritalStatus,
            value: widget.formData.prefMaritalStatus,
            items: [l.anyOption, l.neverMarried, l.divorced, l.widowed],
            strict: widget.formData.prefMaritalStatusStrict,
            onChanged: (v) {
              widget.formData.prefMaritalStatus = v;
              widget.onChanged();
              setState(() {});
            },
            onStrictChanged: (v) {
              widget.formData.prefMaritalStatusStrict = v;
              widget.onChanged();
              setState(() {});
            },
          ),
          const SizedBox(height: 16),

          _PrefDropdownCard(
            icon: Icons.account_balance_wallet_outlined,
            title: l.income,
            value: widget.formData.prefIncome,
            items: widget.formData.familyBasedOutOfCountry != null && widget.formData.familyBasedOutOfCountry != 'India'
                ? _incomePrefOptionsUSD
                : _incomePrefOptionsLPA,
            strict: widget.formData.prefIncomeStrict,
            onChanged: (v) {
              widget.formData.prefIncome = v;
              widget.onChanged();
              setState(() {});
            },
            onStrictChanged: (v) {
              widget.formData.prefIncomeStrict = v;
              widget.onChanged();
              setState(() {});
            },
          ),
          const SizedBox(height: 16),

          _PrefDropdownCard(
            icon: Icons.restaurant_outlined,
            title: l.prefDietQuestion,
            value: widget.formData.prefDiet,
            items: [l.anyOption, l.dietVeg, l.dietNonVeg, l.dietVegan, l.dietJain],
            strict: widget.formData.prefDietStrict,
            onChanged: (v) {
              widget.formData.prefDiet = v;
              widget.onChanged();
              setState(() {});
            },
            onStrictChanged: (v) {
              widget.formData.prefDietStrict = v;
              widget.onChanged();
              setState(() {});
            },
          ),
          const SizedBox(height: 16),

          _PrefDropdownCard(
            icon: Icons.local_bar_outlined,
            title: l.prefDrinkQuestion,
            value: widget.formData.prefDrink,
            items: [l.anyOption, l.drinkNever, l.drinkSocially],
            strict: widget.formData.prefDrinkStrict,
            onChanged: (v) {
              widget.formData.prefDrink = v;
              widget.onChanged();
              setState(() {});
            },
            onStrictChanged: (v) {
              widget.formData.prefDrinkStrict = v;
              widget.onChanged();
              setState(() {});
            },
          ),
          const SizedBox(height: 16),

          _PrefDropdownCard(
            icon: Icons.smoke_free,
            title: l.prefSmokeQuestion,
            value: widget.formData.prefSmoke,
            items: [l.anyOption, l.smokeNever, l.smokeOccasionally],
            strict: widget.formData.prefSmokeStrict,
            onChanged: (v) {
              widget.formData.prefSmoke = v;
              widget.onChanged();
              setState(() {});
            },
            onStrictChanged: (v) {
              widget.formData.prefSmokeStrict = v;
              widget.onChanged();
              setState(() {});
            },
          ),
          const SizedBox(height: 16),

          _PrefDropdownCard(
            icon: Icons.flight_outlined,
            title: l.prefSettledAbroadQuestion,
            value: widget.formData.prefSettledAbroad,
            items: [l.anyOption, l.settledAbroadYes, l.settledAbroadNo],
            strict: widget.formData.prefSettledAbroadStrict,
            onChanged: (v) {
              widget.formData.prefSettledAbroad = v;
              widget.onChanged();
              setState(() {});
            },
            onStrictChanged: (v) {
              widget.formData.prefSettledAbroadStrict = v;
              widget.onChanged();
              setState(() {});
            },
          ),
          const SizedBox(height: 16),

          // Preferred countries (multi-select, API search)
          _PrefCard(
            icon: Icons.public_outlined,
            title: l.prefCountryQuestion,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                _MultiSelectPlaceField(
                  hint: l.prefCountryHint,
                  selected: widget.formData.preferredCountries,
                  mode: _PlaceMode.country,
                  onChanged: (list) {
                    widget.formData.preferredCountries = list;
                    widget.onChanged();
                    setState(() {});
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // City: Any / Same as me / Preferred (multi-select when Preferred)
          _PrefCard(
            icon: Icons.location_city_outlined,
            title: l.prefCityQuestion,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _cityModeValue(widget.formData.prefCityMode),
                  isExpanded: true,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  items: _cityModeOptions.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (v) {
                    widget.formData.prefCityMode = v?.toLowerCase().replaceAll(' ', '_');
                    if (widget.formData.prefCityMode != 'preferred') widget.formData.preferredCities = [];
                    widget.onChanged();
                    setState(() {});
                  },
                ),
                if (widget.formData.prefCityMode == 'preferred') ...[
                  const SizedBox(height: 12),
                  _MultiSelectPlaceField(
                    hint: l.prefCityHint,
                    selected: widget.formData.preferredCities,
                    mode: _PlaceMode.city,
                    onChanged: (list) {
                      widget.formData.preferredCities = list;
                      widget.onChanged();
                      setState(() {});
                    },
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ── Helpers ─────────────────────────────────────────────────────────────

String _cityModeValue(String? mode) {
  if (mode == null) return 'Any';
  switch (mode) {
    case 'same_as_me': return 'Same as me';
    case 'preferred': return 'Preferred';
    default: return 'Any';
  }
}

// ── Shared widgets ──────────────────────────────────────────────────────

class _PrefDropdownCard extends StatelessWidget {
  const _PrefDropdownCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.items,
    required this.strict,
    required this.onChanged,
    required this.onStrictChanged,
  });

  final IconData icon;
  final String title;
  final String? value;
  final List<String> items;
  final bool strict;
  final ValueChanged<String?> onChanged;
  final ValueChanged<bool> onStrictChanged;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final surface = Theme.of(context).colorScheme.surface;
    final l = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: onSurface.withValues(alpha: 0.5)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.titleSmall.copyWith(color: onSurface, fontWeight: FontWeight.w600),
                ),
              ),
              Semantics(
                label: l.strictMatchLabel,
                child: MergeSemantics(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Strict',
                        style: AppTypography.labelSmall.copyWith(
                          color: strict
                              ? Theme.of(context).colorScheme.primary
                              : onSurface.withValues(alpha: 0.5),
                          fontWeight: strict ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 6),
                      SizedBox(
                        height: 28,
                        child: Transform.scale(
                          scale: 0.82,
                          alignment: Alignment.centerRight,
                          child: Switch.adaptive(
                            value: strict,
                            onChanged: onStrictChanged,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: value != null && items.contains(value) ? value! : (items.isNotEmpty ? items.first : null),
            isExpanded: true,
            decoration: InputDecoration(
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _PrefCard extends StatelessWidget {
  const _PrefCard({
    required this.icon,
    required this.title,
    required this.child,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final Widget child;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final accent = Theme.of(context).colorScheme.primary;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: onSurface.withValues(alpha: 0.5)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.titleSmall.copyWith(color: onSurface, fontWeight: FontWeight.w600),
                ),
              ),
              if (trailing != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    trailing!,
                    style: AppTypography.labelMedium.copyWith(color: accent, fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
          child,
        ],
      ),
    );
  }
}

class _SmartMultiline extends StatefulWidget {
  const _SmartMultiline({required this.value, required this.hint, required this.onChanged});
  final String value;
  final String hint;
  final ValueChanged<String> onChanged;

  @override
  State<_SmartMultiline> createState() => _SmartMultilineState();
}

class _SmartMultilineState extends State<_SmartMultiline> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(_SmartMultiline old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value && widget.value != _ctrl.text) {
      _ctrl.text = widget.value;
    }
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _ctrl,
      maxLines: 3,
      textInputAction: TextInputAction.newline,
      keyboardType: TextInputType.multiline,
      decoration: InputDecoration(
        hintText: widget.hint,
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.all(14),
      ),
      onChanged: widget.onChanged,
    );
  }
}

/// Multi-select place search (API): add countries or cities, show as chips.
class _MultiSelectPlaceField extends StatefulWidget {
  const _MultiSelectPlaceField({
    required this.hint,
    required this.selected,
    required this.mode,
    required this.onChanged,
  });
  final String hint;
  final List<String> selected;
  final _PlaceMode mode;
  final ValueChanged<List<String>> onChanged;

  @override
  State<_MultiSelectPlaceField> createState() => _MultiSelectPlaceFieldState();
}

class _MultiSelectPlaceFieldState extends State<_MultiSelectPlaceField> {
  final TextEditingController _ctrl = TextEditingController();
  Timer? _debounce;
  List<PlaceSuggestion> _suggestions = [];
  bool _loading = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  void _onTextChanged(String q) {
    _debounce?.cancel();
    if (q.trim().length < 2) {
      setState(() { _suggestions = []; _loading = false; });
      return;
    }
    setState(() => _loading = true);
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      final list = await PlaceSearchService.searchWithIndiaBias(q);
      if (!mounted) return;
      setState(() { _suggestions = list; _loading = false; });
    });
  }

  void _add(PlaceSuggestion s) {
    final value = widget.mode == _PlaceMode.country ? s.country : s.displayName;
    if (value.isEmpty) return;
    if (widget.selected.contains(value)) return;
    widget.onChanged([...widget.selected, value]);
    _ctrl.clear();
    setState(() => _suggestions = []);
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final accent = Theme.of(context).colorScheme.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _ctrl,
          decoration: InputDecoration(
            hintText: widget.hint,
            prefixIcon: Icon(Icons.search, size: 20, color: onSurface.withValues(alpha: 0.4)),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            suffixIcon: _loading
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                : null,
          ),
          onChanged: _onTextChanged,
        ),
        if (widget.selected.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.selected.map((s) {
              return Chip(
                label: Text(s, style: AppTypography.bodySmall),
                deleteIcon: Icon(Icons.close, size: 16, color: onSurface.withValues(alpha: 0.6)),
                onDeleted: () {
                  widget.onChanged(widget.selected.where((e) => e != s).toList());
                },
                backgroundColor: accent.withValues(alpha: 0.12),
                side: BorderSide(color: accent.withValues(alpha: 0.3)),
              );
            }).toList(),
          ),
        ],
        if (_suggestions.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _suggestions.length,
              itemBuilder: (context, i) {
                final s = _suggestions[i];
                final value = widget.mode == _PlaceMode.country ? s.country : s.displayName;
                final alreadyAdded = value.isNotEmpty && widget.selected.contains(value);
                return ListTile(
                  title: Text(
                    widget.mode == _PlaceMode.country ? s.country : s.displayName,
                    style: AppTypography.bodyMedium.copyWith(
                      color: alreadyAdded ? onSurface.withValues(alpha: 0.5) : onSurface,
                    ),
                  ),
                  trailing: alreadyAdded ? Icon(Icons.check, size: 18, color: accent) : null,
                  onTap: () {
                    if (!alreadyAdded) _add(s);
                  },
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}

class _SmartSingleLine extends StatefulWidget {
  const _SmartSingleLine({required this.value, required this.hint, required this.onChanged});
  final String value;
  final String hint;
  final ValueChanged<String> onChanged;

  @override
  State<_SmartSingleLine> createState() => _SmartSingleLineState();
}

class _SmartSingleLineState extends State<_SmartSingleLine> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(_SmartSingleLine old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value && widget.value != _ctrl.text) {
      _ctrl.text = widget.value;
    }
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _ctrl,
      textInputAction: TextInputAction.done,
      decoration: InputDecoration(
        hintText: widget.hint,
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      onChanged: widget.onChanged,
    );
  }
}
