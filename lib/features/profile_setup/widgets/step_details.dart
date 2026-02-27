import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/location/place_search_service.dart';
import '../../../core/mode/app_mode.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/university/university_search_service.dart';
import '../../../l10n/app_localizations.dart';
import '../screens/profile_setup_screen.dart';

const _degreeOptions = [
  'High School',
  'Diploma',
  'Bachelors',
  'Masters',
  'MBA',
  'PhD',
  'Medical (MBBS/MD)',
  'Engineering (B.Tech/M.Tech)',
  'CA/CFA',
  'Law (LLB/LLM)',
  'Other',
];

/// Degrees that do not show university/college field (e.g. High School, Diploma).
bool _showsInstitution(String? degree) =>
    educationEntryShowsInstitution(degree);

/// Country options for degree grading system.
const _scoreCountries = ['India', 'UK', 'US', 'Other'];

/// Score type options by country (degree grade / classification).
const _scoreTypesByCountry = <String, List<String>>{
  'India': ['First class', 'Second class', 'Distinction', 'Pass'],
  'UK': [
    'First-class honours',
    'Upper second (2:1)',
    'Lower second (2:2)',
    'Third class',
    'Pass',
  ],
  'US': [
    'GPA 3.5 – 4.0',
    'GPA 3.0 – 3.5',
    'GPA 2.5 – 3.0',
    'GPA 2.0 – 2.5',
    'Pass',
  ],
  'Other': ['Percentage', 'Grade', 'Pass', 'Not specified'],
};

/// Career step: searchable options.
const _occupationOptions = [
  'Software Engineer',
  'Doctor',
  'Teacher',
  'Engineer',
  'Accountant',
  'Lawyer',
  'Architect',
  'CA / Chartered Accountant',
  'Consultant',
  'Manager',
  'Business Owner',
  'Government Employee',
  'Banking / Finance',
  'Marketing',
  'HR',
  'Designer',
  'Data Scientist',
  'Professor',
  'Researcher',
  'Nurse',
  'Pharmacist',
  'Veterinarian',
  'Journalist',
  'Civil Servant',
  'Defence',
  'Other',
];
const _companyOptions = [
  'Self-employed',
  'Startup',
  'Google',
  'Microsoft',
  'Amazon',
  'TCS',
  'Infosys',
  'Wipro',
  'HCL',
  'Accenture',
  'Cognizant',
  'IBM',
  'Capgemini',
  'Deloitte',
  'EY',
  'KPMG',
  'PwC',
  'Government',
  'PSU',
  'Reliance',
  'Tata',
  'Mahindra',
  'ICICI',
  'HDFC',
  'State Bank',
  'Other',
];
const _workLocationOptions = [
  'Remote',
  'Abroad',
  'Mumbai',
  'Delhi',
  'Bangalore',
  'Hyderabad',
  'Chennai',
  'Kolkata',
  'Pune',
  'Ahmedabad',
  'Jaipur',
  'Chandigarh',
  'Kochi',
  'Indore',
  'Lucknow',
  'Nagpur',
  'Other',
];

/// Annual income options: India (LPA) vs rest of world (USD), based on locale.
const _incomeOptionsIndia = [
  'Not specified',
  'Below 3 LPA',
  '3-5 LPA',
  '5-10 LPA',
  '10-20 LPA',
  '20-50 LPA',
  '50 LPA+',
  'Abroad salary',
];
const _incomeOptionsUSD = [
  'Not specified',
  'Below \$30k',
  '\$30k–\$50k',
  '\$50k–\$75k',
  '\$75k–\$100k',
  '\$100k–\$150k',
  '\$150k+',
  'Abroad salary',
];

/// Background (Indians-only): religion dropdown options.
const _religionOptions = [
  'Hindu',
  'Muslim',
  'Christian',
  'Sikh',
  'Jain',
  'Buddhist',
  'Parsi',
  'Jewish',
  'Other',
];

/// Background: community/caste options keyed by religion.
const _communityByReligion = <String, List<String>>{
  'Hindu': [
    'Brahmin',
    'Kshatriya',
    'Vaishya',
    'Shudra',
    'Agarwal',
    'Arora',
    'Baniya',
    'Bania',
    'Gupta',
    'Jat',
    'Kayastha',
    'Khatri',
    'Kurmi',
    'Lingayat',
    'Maratha',
    'Meena',
    'Nair',
    'Naidu',
    'Patel',
    'Rajput',
    'Reddy',
    'Kapu',
    'Sharma',
    'Sindhi',
    'Verma',
    'Yadav',
    'SC',
    'ST',
    'OBC',
    'Other',
  ],
  'Muslim': [
    'Syed',
    'Sheikh',
    'Mughal',
    'Pathan',
    'Ansari',
    'Qureshi',
    'Bohra',
    'Khoja',
    'Memon',
    'Mappila',
    'Shia',
    'Sunni',
    'Hanafi',
    'Deobandi',
    'Barelvi',
    'Ahmadiyya',
    'Other',
  ],
  'Christian': [
    'Roman Catholic',
    'Protestant',
    'Syrian Catholic',
    'Syrian Orthodox',
    'Marthoma',
    'CSI',
    'CNI',
    'Pentecostal',
    'Evangelical',
    'Adventist',
    'Baptist',
    'Methodist',
    'Anglican',
    'Latin Catholic',
    'Jacobite',
    'Other',
  ],
  'Sikh': [
    'Jat Sikh',
    'Khatri Sikh',
    'Ramgarhia',
    'Arora Sikh',
    'Saini',
    'Labana',
    'Ramdasia',
    'Mazhabi',
    'Namdhari',
    'Nihang',
    'Other',
  ],
  'Jain': [
    'Digambar',
    'Shwetambar',
    'Agarwal',
    'Baniya',
    'Oswal',
    'Porwal',
    'Khandelwal',
    'Humad',
    'Sthanakvasi',
    'Terapanthi',
    'Other',
  ],
  'Buddhist': [
    'Theravada',
    'Mahayana',
    'Vajrayana',
    'Neo-Buddhist',
    'Ambedkarite',
    'Tibetan',
    'Other',
  ],
  'Parsi': ['Irani', 'Parsi', 'Other'],
  'Jewish': ['Bene Israel', 'Cochin Jews', 'Baghdadi Jews', 'Other'],
};

List<String> _communityOptionsForReligion(String? religion) {
  if (religion == null || religion.isEmpty) {
    return _communityByReligion.values.expand((l) => l).toSet().toList()
      ..sort();
  }
  return _communityByReligion[religion] ?? ['Other'];
}

/// Mother tongue & languages: Indian languages + English + Other.
const _motherTongueAndLanguageOptions = [
  'Hindi',
  'Bengali',
  'Telugu',
  'Marathi',
  'Tamil',
  'Urdu',
  'Gujarati',
  'Kannada',
  'Malayalam',
  'Punjabi',
  'Odia',
  'Assamese',
  'Kashmiri',
  'Sindhi',
  'Konkani',
  'Nepali',
  'Sanskrit',
  'English',
  'Other',
];

/// Parent age dropdown: Deceased + ages 35–95.
final _parentAgeOptions = [
  'Deceased',
  ...List.generate(61, (i) => '${35 + i}'),
];

/// Household income in India — Rs (LPA).
const _householdIncomeLPA = [
  'Not specified',
  'Below Rs 5 LPA',
  'Rs 5-10 LPA',
  'Rs 10-15 LPA',
  'Rs 15-20 LPA',
  'Rs 20-50 LPA',
  'Rs 50 LPA+',
];

/// Household income in USD (outside India).
const _householdIncomeUSD = [
  'Not specified',
  'Below \$50k',
  '\$50k–\$100k',
  '\$100k–\$150k',
  '\$150k–\$200k',
  '\$200k–\$500k',
  '\$500k+',
];

/// Gotra options (searchable dropdown) — major gotras and common variants.
const _gotraOptions = [
  'Agastya',
  'Angirasa',
  'Asita',
  'Atri',
  'Atreya',
  'Aurva',
  'Avatsara',
  'Barhaspatya',
  'Bharadwaj',
  'Bharadvaja',
  'Bhargava',
  'Bhrigu',
  'Cyavana',
  'Daivala',
  'Daivarata',
  'Daivodasa',
  'Dairghatamasa',
  'Gargya',
  'Gathina',
  'Gautam',
  'Gautama',
  'Gartsamada',
  'Jamadagni',
  'Jamadagnya',
  'Kashyap',
  'Kashyapa',
  'Kaushik',
  'Kaushika',
  'Kakshivata',
  'Kanva',
  'Kautsa',
  'Maitravaruna',
  'Mandhata',
  'Maudgalya',
  'Parasharya',
  'Partha',
  'Sankritya',
  'Sandilya',
  'Shandilya',
  'Shaunaka',
  'Shaktya',
  'Upamanyu',
  'Aupamanyava',
  'Vashistha',
  'Vasishtha',
  'Vatsa',
  'Vainya',
  'Vishwamitra',
  'Vaishvamitra',
  'Madhucchandasa',
  'Ambarisha',
  'Other',
  'Don\'t know',
];

/// Sibling count options for Brothers / Sisters dropdowns.
const _siblingCountOptions = ['None', '1', '2', '3', '4+'];

void _syncSiblingsText(ProfileFormData formData) {
  final b = formData.siblingBrothers;
  final s = formData.siblingSisters;
  if (b == null && s == null) {
    formData.siblings = null;
    return;
  }
  final parts = <String>[];
  if (b != null && b != 'None') parts.add('$b Brother${b == '1' ? '' : 's'}');
  if (s != null && s != 'None') parts.add('$s Sister${s == '1' ? '' : 's'}');
  formData.siblings = parts.isEmpty ? null : parts.join(', ');
}

/// Parent occupation options (searchable dropdown for mother/father).
const _parentOccupationOptions = [
  'Homemaker',
  'Teacher',
  'Professor',
  'Govt. employee',
  'Private sector',
  'Business',
  'Self-employed',
  'Doctor',
  'Engineer',
  'Lawyer',
  'CA / Accountant',
  'Banking / Finance',
  'IT / Software',
  'Nurse',
  'Retired',
  'Not working',
  'Agriculture',
  'Defence',
  'Other',
];

/// Map university country (from search API) to grading system key. Returns null if unknown.
String? _countryToGradingSystem(String? country) {
  if (country == null || country.isEmpty) return null;
  final c = country.trim().toLowerCase();
  if (c == 'united kingdom' ||
      c == 'uk' ||
      c == 'england' ||
      c == 'scotland' ||
      c == 'wales' ||
      c == 'northern ireland')
    return 'UK';
  if (c == 'united states' ||
      c == 'united states of america' ||
      c == 'usa' ||
      c == 'us')
    return 'US';
  if (c == 'india') return 'India';
  return 'Other';
}

/// When non-null, only that part of the details step is shown (for section-only edit screens). Matrimony only.
enum StepDetailsOnlySection { religion, lifestyle, family, horoscope }

class StepDetails extends StatelessWidget {
  const StepDetails({
    super.key,
    required this.mode,
    required this.formData,
    required this.onChanged,
    this.onlySection,
  });

  final AppMode mode;
  final ProfileFormData formData;
  final VoidCallback onChanged;

  /// When set (matrimony only), only that section is shown.
  final StepDetailsOnlySection? onlySection;

  @override
  Widget build(BuildContext context) {
    if (mode.isDating)
      return _DatingDetails(formData: formData, onChanged: onChanged);
    return _MatrimonyDetails(
      formData: formData,
      onChanged: onChanged,
      onlySection: onlySection,
    );
  }
}

// ── Step: Education (matrimony only) ─────────────────────────────────────

class StepEducation extends StatefulWidget {
  const StepEducation({
    super.key,
    required this.formData,
    required this.onChanged,
  });

  final ProfileFormData formData;
  final VoidCallback onChanged;

  @override
  State<StepEducation> createState() => _StepEducationState();
}

class _StepEducationState extends State<StepEducation> {
  @override
  void initState() {
    super.initState();
    if (widget.formData.educationEntries.isEmpty) {
      widget.formData.educationEntries.add(EducationEntry());
      WidgetsBinding.instance.addPostFrameCallback((_) => widget.onChanged());
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final formData = widget.formData;
    final onChanged = widget.onChanged;

    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.profileStepEducation,
            style: AppTypography.displayLarge.copyWith(
              color: onSurface,
              fontSize: 32,
              height: 1.15,
            ),
          ).animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 4),
          Text(
            l.educationStepSubtitle,
            style: AppTypography.bodyMedium.copyWith(
              color: onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 28),
          ...formData.educationEntries.asMap().entries.map((entry) {
            final i = entry.key;
            final e = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: _EducationEntryRow(
                entry: e,
                onDegreeChanged: (v) {
                  e.degree = v;
                  onChanged();
                },
                onInstitutionChanged: (name, country) {
                  e.institution = name;
                  e.country = country;
                  final grading = _countryToGradingSystem(country);
                  if (grading != null) {
                    e.scoreCountry = grading;
                    e.scoreType = null;
                  }
                  onChanged();
                },
                onGraduationYearChanged: (v) {
                  e.graduationYear = v;
                  onChanged();
                },
                onScoreCountryChanged: (v) {
                  e.scoreCountry = v;
                  e.scoreType = null;
                  onChanged();
                },
                onScoreTypeChanged: (v) {
                  e.scoreType = v;
                  onChanged();
                },
                onRemove: formData.educationEntries.length > 1
                    ? () {
                        formData.educationEntries.removeAt(i);
                        onChanged();
                      }
                    : null,
                hint: l.searchUniversityHint,
              ),
            );
          }),
          TextButton.icon(
            onPressed: () {
              formData.educationEntries.add(EducationEntry());
              onChanged();
            },
            icon: const Icon(Icons.add_circle_outline, size: 20),
            label: Text(l.addEducation),
          ),
          const SizedBox(height: 24),
          _SectionLabel(label: l.aboutEducation),
          const SizedBox(height: 8),
          _MultilineField(
            value: formData.aboutEducation ?? '',
            hint: l.aboutEducationHint,
            onChanged: (v) {
              formData.aboutEducation = v.isEmpty ? null : v;
              onChanged();
            },
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _EducationEntryRow extends StatelessWidget {
  const _EducationEntryRow({
    required this.entry,
    required this.onDegreeChanged,
    required this.onInstitutionChanged,
    required this.onGraduationYearChanged,
    required this.onScoreCountryChanged,
    required this.onScoreTypeChanged,
    required this.hint,
    this.onRemove,
  });

  final EducationEntry entry;
  final ValueChanged<String?> onDegreeChanged;
  final void Function(String name, String? country) onInstitutionChanged;
  final ValueChanged<int?> onGraduationYearChanged;
  final ValueChanged<String?> onScoreCountryChanged;
  final ValueChanged<String?> onScoreTypeChanged;
  final String hint;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final showUni = _showsInstitution(entry.degree);
    final scoreTypes =
        entry.scoreCountry != null &&
            _scoreTypesByCountry.containsKey(entry.scoreCountry)
        ? _scoreTypesByCountry[entry.scoreCountry]!
        : <String>[];

    return Container(
      padding: const EdgeInsets.all(16),
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
              Expanded(
                child: _SearchableDegreeField(
                  label: l.whatDidYouComplete,
                  value: entry.degree,
                  hint: l.whatDidYouCompleteHint,
                  onSelected: onDegreeChanged,
                ),
              ),
              if (onRemove != null)
                IconButton(
                  onPressed: onRemove,
                  icon: Icon(
                    Icons.remove_circle_outline,
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
            ],
          ),
          if (showUni) ...[
            const SizedBox(height: 16),
            _UniversitySearchField(
              label: l.searchUniversity,
              value: entry.institution ?? '',
              hint: hint,
              subtitle: l.universityImportantHint,
              onSelected: onInstitutionChanged,
            ),
          ],
          const SizedBox(height: 16),
          _YearOfGraduationPicker(
            label: l.graduationYear,
            value: entry.graduationYear,
            onChanged: onGraduationYearChanged,
          ),
          if (showUni) ...[
            const SizedBox(height: 16),
            _DropdownField(
              label: l.scoreCountry,
              value: entry.scoreCountry ?? '—',
              items: ['—', ..._scoreCountries],
              onChanged: (v) {
                onScoreCountryChanged(v == null || v == '—' ? null : v);
              },
            ),
            if (scoreTypes.isNotEmpty) ...[
              const SizedBox(height: 16),
              _DropdownField(
                label: l.degreeGrade,
                value: entry.scoreType,
                items: scoreTypes,
                onChanged: onScoreTypeChanged,
              ),
            ],
          ],
        ],
      ),
    );
  }
}

/// List of years for graduation (current year down to ~70 years ago).
List<int> get _graduationYears =>
    List.generate(70, (i) => DateTime.now().year - i);

/// Year-of-graduation picker: tap opens a modal list so the dropdown works reliably.
class _YearOfGraduationPicker extends StatelessWidget {
  const _YearOfGraduationPicker({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final int? value;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final display = value != null ? '$value' : '—';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.labelMedium.copyWith(
            color: onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: () async {
            const int clearYearSentinel = -1;
            final picked = await showModalBottomSheet<int?>(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (ctx) => _YearPickerSheet(
                current: value,
                years: _graduationYears,
                onSelected: (y) => Navigator.of(ctx).pop(y),
                onClear: () => Navigator.of(ctx).pop(clearYearSentinel),
              ),
            );
            if (picked == clearYearSentinel) {
              onChanged(null);
            } else if (picked != null) {
              onChanged(picked);
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Row(
              children: [
                Text(
                  display,
                  style: AppTypography.bodyLarge.copyWith(
                    color: value != null
                        ? onSurface
                        : onSurface.withValues(alpha: 0.5),
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.arrow_drop_down,
                  color: onSurface.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _YearPickerSheet extends StatelessWidget {
  const _YearPickerSheet({
    required this.current,
    required this.years,
    required this.onSelected,
    required this.onClear,
  });

  final int? current;
  final List<int> years;
  final ValueChanged<int?> onSelected;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final surface = Theme.of(context).colorScheme.surface;
    final screenHeight = MediaQuery.of(context).size.height;
    final sheetHeight = (screenHeight * 0.5).clamp(320.0, 400.0);

    return SafeArea(
      top: false,
      child: Container(
        height: sheetHeight,
        decoration: BoxDecoration(
          color: surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  TextButton(onPressed: onClear, child: Text(l.clearButton)),
                  const Spacer(),
                  Text(
                    AppLocalizations.of(context)!.graduationYear,
                    style: AppTypography.titleSmall.copyWith(color: onSurface),
                  ),
                  const Spacer(),
                  const SizedBox(width: 64),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: years.length,
                itemBuilder: (ctx, i) {
                  final y = years[i];
                  final selected = y == current;
                  return ListTile(
                    title: Text(
                      '$y',
                      style: AppTypography.bodyLarge.copyWith(color: onSurface),
                    ),
                    trailing: selected
                        ? Icon(
                            Icons.check,
                            color: Theme.of(context).colorScheme.primary,
                          )
                        : null,
                    onTap: () => onSelected(y),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchableDegreeField extends StatefulWidget {
  const _SearchableDegreeField({
    required this.label,
    required this.value,
    required this.hint,
    required this.onSelected,
  });

  final String label;
  final String? value;
  final String hint;
  final ValueChanged<String?> onSelected;

  @override
  State<_SearchableDegreeField> createState() => _SearchableDegreeFieldState();
}

class _SearchableDegreeFieldState extends State<_SearchableDegreeField> {
  late final TextEditingController _ctrl;
  final FocusNode _focusNode = FocusNode();
  bool _showList = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.value ?? '');
    _focusNode.addListener(
      () => setState(() => _showList = _focusNode.hasFocus),
    );
  }

  @override
  void didUpdateWidget(_SearchableDegreeField old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value && widget.value != _ctrl.text) {
      _ctrl.text = widget.value ?? '';
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  List<String> get _filtered {
    final q = _ctrl.text.trim().toLowerCase();
    if (q.isEmpty) return _degreeOptions;
    return _degreeOptions.where((d) => d.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: AppTypography.labelMedium.copyWith(
            color: onSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _ctrl,
          focusNode: _focusNode,
          decoration: InputDecoration(
            hintText: widget.hint,
            prefixIcon: Icon(
              Icons.search,
              size: 20,
              color: onSurface.withValues(alpha: 0.4),
            ),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          onChanged: (_) => setState(() {}),
          onTap: () => setState(() => _showList = true),
        ),
        if (_showList && _filtered.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(maxHeight: 220),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _filtered.length,
              itemBuilder: (context, i) {
                final d = _filtered[i];
                return ListTile(
                  title: Text(
                    d,
                    style: AppTypography.bodyMedium.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  onTap: () {
                    _ctrl.text = d;
                    _focusNode.unfocus();
                    setState(() => _showList = false);
                    widget.onSelected(d);
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

/// Searchable dropdown for career (occupation, company, work location). Allows custom value.
class _SearchableSelectField extends StatefulWidget {
  const _SearchableSelectField({
    required this.label,
    required this.value,
    required this.hint,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final String hint;
  final List<String> options;
  final ValueChanged<String?> onChanged;

  @override
  State<_SearchableSelectField> createState() => _SearchableSelectFieldState();
}

class _SearchableSelectFieldState extends State<_SearchableSelectField> {
  late final TextEditingController _ctrl;
  final FocusNode _focusNode = FocusNode();
  bool _showList = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.value ?? '');
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    setState(() => _showList = _focusNode.hasFocus);
    if (!_focusNode.hasFocus && _ctrl.text.trim().isNotEmpty) {
      widget.onChanged(_ctrl.text.trim());
    }
  }

  @override
  void didUpdateWidget(_SearchableSelectField old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value && widget.value != _ctrl.text) {
      _ctrl.text = widget.value ?? '';
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _ctrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  List<String> get _filtered {
    final q = _ctrl.text.trim().toLowerCase();
    if (q.isEmpty) return widget.options;
    return widget.options.where((s) => s.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: AppTypography.labelMedium.copyWith(
            color: onSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _ctrl,
          focusNode: _focusNode,
          decoration: InputDecoration(
            hintText: widget.hint,
            prefixIcon: Icon(
              Icons.search,
              size: 20,
              color: onSurface.withValues(alpha: 0.4),
            ),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          onChanged: (_) => setState(() {}),
          onTap: () => setState(() => _showList = true),
        ),
        if (_showList && _filtered.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(maxHeight: 220),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Theme.of(
                  context,
                ).colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _filtered.length,
              itemBuilder: (context, i) {
                final opt = _filtered[i];
                return ListTile(
                  title: Text(
                    opt,
                    style: AppTypography.bodyMedium.copyWith(
                      color: onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onTap: () {
                    _ctrl.text = opt;
                    _focusNode.unfocus();
                    setState(() => _showList = false);
                    widget.onChanged(opt);
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

/// Multi-select dropdown with search for languages spoken (comma-separated value).
class _MultiSelectSearchField extends StatefulWidget {
  const _MultiSelectSearchField({
    required this.label,
    required this.value,
    required this.options,
    required this.hint,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final List<String> options;
  final String hint;
  final ValueChanged<String?> onChanged;

  @override
  State<_MultiSelectSearchField> createState() =>
      _MultiSelectSearchFieldState();
}

class _MultiSelectSearchFieldState extends State<_MultiSelectSearchField> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  List<String> get _selected {
    final v = widget.value?.trim();
    if (v == null || v.isEmpty) return [];
    return v
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  List<String> get _filtered {
    if (_query.isEmpty) return widget.options;
    final q = _query.toLowerCase();
    return widget.options.where((s) => s.toLowerCase().contains(q)).toList();
  }

  void _toggle(String option) {
    final next = List<String>.from(_selected);
    if (next.contains(option)) {
      next.remove(option);
    } else {
      next.add(option);
    }
    widget.onChanged(next.isEmpty ? null : next.join(', '));
    setState(() {});
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final selected = _selected;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: AppTypography.labelMedium.copyWith(
            color: onSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _searchCtrl,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: widget.hint,
            prefixIcon: Icon(
              Icons.search,
              size: 20,
              color: onSurface.withValues(alpha: 0.4),
            ),
            suffixIcon: _query.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      Icons.close,
                      size: 18,
                      color: onSurface.withValues(alpha: 0.4),
                    ),
                    onPressed: () {
                      _searchCtrl.clear();
                      setState(() => _query = '');
                    },
                  )
                : null,
            filled: true,
            fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          onChanged: (v) => setState(() => _query = v),
        ),
        if (selected.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: selected.map((s) {
              return Chip(
                label: Text(s, style: AppTypography.bodySmall),
                deleteIcon: Icon(
                  Icons.close,
                  size: 16,
                  color: onSurface.withValues(alpha: 0.6),
                ),
                onDeleted: () => _toggle(s),
                backgroundColor: accent.withValues(alpha: 0.12),
                side: BorderSide(color: accent.withValues(alpha: 0.3)),
              );
            }).toList(),
          ),
        ],
        const SizedBox(height: 10),
        Container(
          constraints: const BoxConstraints(maxHeight: 220),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _filtered.length,
            itemBuilder: (context, i) {
              final opt = _filtered[i];
              final isSelected = selected.contains(opt);
              return ListTile(
                title: Text(
                  opt,
                  style: AppTypography.bodyMedium.copyWith(
                    color: onSurface,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
                trailing: isSelected
                    ? Icon(Icons.check_circle, size: 20, color: accent)
                    : null,
                onTap: () => _toggle(opt),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _UniversitySearchField extends StatefulWidget {
  const _UniversitySearchField({
    required this.label,
    required this.value,
    required this.hint,
    this.subtitle,
    required this.onSelected,
  });

  final String label;
  final String value;
  final String hint;
  final String? subtitle;
  final void Function(String name, String? country) onSelected;

  @override
  State<_UniversitySearchField> createState() => _UniversitySearchFieldState();
}

class _UniversitySearchFieldState extends State<_UniversitySearchField> {
  late final TextEditingController _ctrl;
  late final FocusNode _focusNode;
  Timer? _debounce;
  List<UniversitySuggestion> _suggestions = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.value);
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus && _ctrl.text.trim().isNotEmpty) {
      widget.onSelected(_ctrl.text.trim(), null);
    }
  }

  @override
  void didUpdateWidget(_UniversitySearchField old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value && widget.value != _ctrl.text) {
      _ctrl.text = widget.value;
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _debounce?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  void _onTextChanged(String q) {
    _debounce?.cancel();
    if (q.trim().length < 2) {
      setState(() {
        _suggestions = [];
        _loading = false;
      });
      return;
    }
    setState(() => _loading = true);
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      final list = await UniversitySearchService.instance.search(q);
      if (!mounted) return;
      setState(() {
        _suggestions = list;
        _loading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: AppTypography.labelMedium.copyWith(
            color: onSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (widget.subtitle != null && widget.subtitle!.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            widget.subtitle!,
            style: AppTypography.bodySmall.copyWith(
              color: onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
        const SizedBox(height: 6),
        TextField(
          controller: _ctrl,
          focusNode: _focusNode,
          decoration: InputDecoration(
            hintText: widget.hint,
            filled: true,
            fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            suffixIcon: _loading
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : null,
          ),
          onChanged: _onTextChanged,
          onSubmitted: (v) {
            if (v.trim().isNotEmpty) widget.onSelected(v.trim(), null);
          },
        ),
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
                final onSurface = Theme.of(context).colorScheme.onSurface;
                return ListTile(
                  title: Text(
                    s.name,
                    style: AppTypography.bodyMedium.copyWith(
                      color: onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onTap: () {
                    _ctrl.text = s.name;
                    setState(() => _suggestions = []);
                    widget.onSelected(s.name, s.country);
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

/// Family "based out of" searchable field using place API (cities/countries, India-focused).
class _FamilyLocationSearchField extends StatefulWidget {
  const _FamilyLocationSearchField({
    required this.label,
    required this.value,
    required this.hint,
    required this.onSelected,
  });

  final String label;
  final String value;
  final String hint;
  final void Function(String displayName, String? country) onSelected;

  @override
  State<_FamilyLocationSearchField> createState() =>
      _FamilyLocationSearchFieldState();
}

class _FamilyLocationSearchFieldState
    extends State<_FamilyLocationSearchField> {
  late final TextEditingController _ctrl;
  Timer? _debounce;
  List<PlaceSuggestion> _suggestions = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(_FamilyLocationSearchField old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value && widget.value != _ctrl.text) {
      _ctrl.text = widget.value;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  void _onTextChanged(String q) {
    _debounce?.cancel();
    if (q.trim().length < 2) {
      setState(() {
        _suggestions = [];
        _loading = false;
      });
      return;
    }
    setState(() => _loading = true);
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      final list = await PlaceSearchService.searchWithIndiaBias(q);
      if (!mounted) return;
      setState(() {
        _suggestions = list;
        _loading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: AppTypography.labelMedium.copyWith(
            color: onSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _ctrl,
          decoration: InputDecoration(
            hintText: widget.hint,
            prefixIcon: Icon(
              Icons.location_on_outlined,
              size: 20,
              color: onSurface.withValues(alpha: 0.4),
            ),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            suffixIcon: _loading
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : null,
          ),
          onChanged: _onTextChanged,
          onSubmitted: (v) {
            if (v.trim().isNotEmpty) widget.onSelected(v.trim(), null);
          },
        ),
        if (_suggestions.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(maxHeight: 220),
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
                return ListTile(
                  title: Text(
                    s.displayName,
                    style: AppTypography.bodyMedium.copyWith(
                      color: onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onTap: () {
                    _ctrl.text = s.displayName;
                    setState(() => _suggestions = []);
                    widget.onSelected(
                      s.displayName,
                      s.isIndia ? 'India' : s.country,
                    );
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

// ── Step: Career (matrimony only) ────────────────────────────────────────

class StepCareer extends StatelessWidget {
  const StepCareer({
    super.key,
    required this.formData,
    required this.onChanged,
  });

  final ProfileFormData formData;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.profileStepCareer,
            style: AppTypography.displayLarge.copyWith(
              color: onSurface,
              fontSize: 32,
              height: 1.15,
            ),
          ).animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 4),
          Text(
            'Your work and where you\'re based.',
            style: AppTypography.bodyMedium.copyWith(
              color: onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 28),
          _DetailCard(
            icon: Icons.work_outline,
            title: l.profileStepCareer,
            children: [
              _SearchableSelectField(
                label: l.matrimonyOccupationQuestion,
                value: formData.occupation,
                hint: 'Search or type occupation',
                options: _occupationOptions,
                onChanged: (v) {
                  formData.occupation = v;
                  onChanged();
                },
              ),
              const SizedBox(height: 16),
              _SearchableSelectField(
                label: l.companyQuestion,
                value: formData.company,
                hint: l.companyHint,
                options: _companyOptions,
                onChanged: (v) {
                  formData.company = v;
                  onChanged();
                },
              ),
              const SizedBox(height: 16),
              Builder(
                builder: (context) {
                  final locale = Localizations.localeOf(context).countryCode;
                  final isIndia = locale == 'IN';
                  final incomeOptions = isIndia
                      ? _incomeOptionsIndia
                      : _incomeOptionsUSD;
                  final String displayIncome;
                  final cur = formData.income;
                  if (cur != null && incomeOptions.contains(cur)) {
                    displayIncome = cur;
                  } else {
                    displayIncome = 'Not specified';
                  }
                  return _DropdownField(
                    label: l.matrimonyIncomeQuestion,
                    value: displayIncome,
                    items: incomeOptions,
                    onChanged: (v) {
                      formData.income = v;
                      onChanged();
                    },
                  );
                },
              ),
              const SizedBox(height: 16),
              _SectionLabel(label: l.sectorQuestion),
              const SizedBox(height: 8),
              _ChipRow(
                options: [
                  l.sectorPrivate,
                  l.sectorGovernment,
                  l.sectorPSU,
                  l.sectorBusiness,
                  l.sectorOther,
                ],
                selected: formData.sector,
                onSelected: (v) {
                  formData.sector = v;
                  onChanged();
                },
              ),
              const SizedBox(height: 16),
              _SearchableSelectField(
                label: l.workLocationQuestion,
                value: formData.workLocation,
                hint: l.workLocationHint,
                options: _workLocationOptions,
                onChanged: (v) {
                  formData.workLocation = v;
                  onChanged();
                },
              ),
              const SizedBox(height: 16),
              _SectionLabel(label: l.settledAbroadQuestion),
              const SizedBox(height: 8),
              _ChipRow(
                options: [
                  l.settledAbroadYes,
                  l.settledAbroadNo,
                  l.settledAbroadPlanning,
                ],
                selected: formData.settledAbroad,
                onSelected: (v) {
                  formData.settledAbroad = v;
                  onChanged();
                },
              ),
              const SizedBox(height: 16),
              _SectionLabel(label: l.willingToRelocate),
              const SizedBox(height: 8),
              _ChipRow(
                options: [l.relocateYes, l.relocateNo, l.relocateMaybe],
                selected: formData.willingToRelocate,
                onSelected: (v) {
                  formData.willingToRelocate = v;
                  onChanged();
                },
              ),
              const SizedBox(height: 20),
              _SectionLabel(label: l.aboutCareer),
              const SizedBox(height: 8),
              _MultilineField(
                value: formData.aboutCareer ?? '',
                hint: l.aboutCareerHint,
                onChanged: (v) {
                  formData.aboutCareer = v.isEmpty ? null : v;
                  onChanged();
                },
              ),
            ],
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ── Dating Details ──────────────────────────────────────────────────────

class _DatingDetails extends StatelessWidget {
  const _DatingDetails({required this.formData, required this.onChanged});
  final ProfileFormData formData;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'About you',
            style: AppTypography.displayLarge.copyWith(
              color: onSurface,
              fontSize: 32,
              height: 1.15,
            ),
          ).animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 4),
          Text(
            'Help others know what you\'re about. All fields are optional — fill what you like.',
            style: AppTypography.bodyMedium.copyWith(
              color: onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 28),

          _SectionLabel(label: l.datingIntentQuestion),
          const SizedBox(height: 12),
          _OptionGrid(
            options: [
              _Option(l.datingIntentSerious, Icons.favorite_outline),
              _Option(l.datingIntentCasual, Icons.celebration_outlined),
              _Option(l.datingIntentMarriage, Icons.diamond_outlined),
              _Option(l.datingIntentFriends, Icons.people_outline),
              _Option(l.datingIntentOpen, Icons.explore_outlined),
            ],
            selected: formData.datingIntent,
            onSelected: (v) {
              formData.datingIntent = v;
              onChanged();
            },
          ),
          const SizedBox(height: 28),

          _SectionLabel(label: l.aboutYou),
          const SizedBox(height: 8),
          _MultilineField(
            value: formData.bio,
            hint: l.aboutYouHint,
            onChanged: (v) {
              formData.bio = v;
              onChanged();
            },
          ),
          const SizedBox(height: 28),

          _LifestyleSection(formData: formData, onChanged: onChanged),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ── Matrimony Details ───────────────────────────────────────────────────

class _MatrimonyDetails extends StatelessWidget {
  const _MatrimonyDetails({
    required this.formData,
    required this.onChanged,
    this.onlySection,
  });
  final ProfileFormData formData;
  final VoidCallback onChanged;
  final StepDetailsOnlySection? onlySection;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    final forSelf = formData.isForSelf;
    final subject = formData.subjectName;

    final pageTitle = forSelf
        ? 'Background\n& details'
        : l.dynDetailsTitle(subject);
    final pageSubtitle = forSelf
        ? 'These help us find compatible matches. Fill what you can — skip the rest.'
        : l.dynDetailsSubtitle(subject);

    final showReligion =
        onlySection == null || onlySection == StepDetailsOnlySection.religion;
    final showLifestyle =
        onlySection == null || onlySection == StepDetailsOnlySection.lifestyle;
    final showFamily =
        onlySection == null || onlySection == StepDetailsOnlySection.family;
    final showHoroscope =
        onlySection == null || onlySection == StepDetailsOnlySection.horoscope;

    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            onlySection != null ? _sectionTitle(onlySection!, l) : pageTitle,
            style: AppTypography.displayLarge.copyWith(
              color: onSurface,
              fontSize: onlySection != null ? 28 : 32,
              height: 1.15,
            ),
          ).animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 4),
          Text(
            onlySection != null ? _sectionSubtitle(onlySection!) : pageSubtitle,
            style: AppTypography.bodyMedium.copyWith(
              color: onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 28),

          // Religion & Community (Indians-only: dropdowns + multi-select languages)
          if (showReligion)
            onlySection == StepDetailsOnlySection.religion
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    key: const ValueKey('religion-only'),
                    children: [
                      _DropdownField(
                        label: l.matrimonyReligionQuestion,
                        value: formData.religion,
                        items: _religionOptions,
                        onChanged: (v) {
                          formData.religion = v;
                          if (formData.community != null &&
                              !_communityOptionsForReligion(
                                v,
                              ).contains(formData.community)) {
                            formData.community = null;
                          }
                          onChanged();
                        },
                      ),
                      const SizedBox(height: 24),
                      _SearchableSelectField(
                        label: l.matrimonyCommunityQuestion,
                        value: formData.community,
                        hint:
                            'e.g. ${_communityOptionsForReligion(formData.religion).take(3).join(", ")}',
                        options: _communityOptionsForReligion(
                          formData.religion,
                        ),
                        onChanged: (v) {
                          formData.community = v;
                          onChanged();
                        },
                      ),
                      const SizedBox(height: 24),
                      _SearchableSelectField(
                        label: l.matrimonyMotherTongueQuestion,
                        value: formData.motherTongue,
                        hint: 'Select mother tongue',
                        options: _motherTongueAndLanguageOptions,
                        onChanged: (v) {
                          formData.motherTongue = v;
                          onChanged();
                        },
                      ),
                      const SizedBox(height: 24),
                      _MultiSelectSearchField(
                        label: l.languagesSpoken,
                        value: formData.languagesSpoken,
                        options: _motherTongueAndLanguageOptions,
                        hint: l.languagesHint,
                        onChanged: (v) {
                          formData.languagesSpoken = v;
                          onChanged();
                        },
                      ),
                      const SizedBox(height: 24),
                      _SectionLabel(label: l.maritalStatus),
                      const SizedBox(height: 10),
                      _ChipRow(
                        options: [
                          l.neverMarried,
                          l.divorced,
                          l.widowed,
                          l.awaitingDivorce,
                        ],
                        selected: formData.maritalStatus,
                        onSelected: (v) {
                          formData.maritalStatus = v;
                          onChanged();
                        },
                      ),
                    ],
                  )
                : _DetailCard(
                    icon: Icons.temple_hindu_outlined,
                    title: l.backgroundTitle,
                    children: [
                      _DropdownField(
                        label: l.matrimonyReligionQuestion,
                        value: formData.religion,
                        items: _religionOptions,
                        onChanged: (v) {
                          formData.religion = v;
                          if (formData.community != null &&
                              !_communityOptionsForReligion(
                                v,
                              ).contains(formData.community)) {
                            formData.community = null;
                          }
                          onChanged();
                        },
                      ),
                      const SizedBox(height: 20),
                      _SearchableSelectField(
                        label: l.matrimonyCommunityQuestion,
                        value: formData.community,
                        hint:
                            'e.g. ${_communityOptionsForReligion(formData.religion).take(3).join(", ")}',
                        options: _communityOptionsForReligion(
                          formData.religion,
                        ),
                        onChanged: (v) {
                          formData.community = v;
                          onChanged();
                        },
                      ),
                      const SizedBox(height: 20),
                      _SearchableSelectField(
                        label: l.matrimonyMotherTongueQuestion,
                        value: formData.motherTongue,
                        hint: 'Select mother tongue',
                        options: _motherTongueAndLanguageOptions,
                        onChanged: (v) {
                          formData.motherTongue = v;
                          onChanged();
                        },
                      ),
                      const SizedBox(height: 20),
                      _MultiSelectSearchField(
                        label: l.languagesSpoken,
                        value: formData.languagesSpoken,
                        options: _motherTongueAndLanguageOptions,
                        hint: l.languagesHint,
                        onChanged: (v) {
                          formData.languagesSpoken = v;
                          onChanged();
                        },
                      ),
                      const SizedBox(height: 20),
                      _SectionLabel(label: l.maritalStatus),
                      const SizedBox(height: 10),
                      _ChipRow(
                        options: [
                          l.neverMarried,
                          l.divorced,
                          l.widowed,
                          l.awaitingDivorce,
                        ],
                        selected: formData.maritalStatus,
                        onSelected: (v) {
                          formData.maritalStatus = v;
                          onChanged();
                        },
                      ),
                    ],
                  ),
          if (showReligion) const SizedBox(height: 24),

          // Lifestyle
          if (showLifestyle)
            _LifestyleSection(formData: formData, onChanged: onChanged),
          if (showLifestyle) const SizedBox(height: 24),

          // Family
          if (showFamily)
            _DetailCard(
              icon: Icons.family_restroom_outlined,
              title: l.profileBuilderFamily,
              children: [
                _FamilyLocationSearchField(
                  label: l.familyLocationQuestion,
                  value: formData.familyLocation ?? '',
                  hint: l.familyLocationHint,
                  onSelected: (displayName, country) {
                    final countryChanged =
                        formData.familyBasedOutOfCountry != country;
                    formData.familyLocation = displayName;
                    formData.familyBasedOutOfCountry = country;
                    if (countryChanged) formData.householdIncome = null;
                    onChanged();
                  },
                ),
                const SizedBox(height: 16),
                _DropdownField(
                  label: l.householdIncomeQuestion,
                  value: formData.householdIncome,
                  items:
                      formData.familyBasedOutOfCountry != null &&
                          formData.familyBasedOutOfCountry != 'India'
                      ? _householdIncomeUSD
                      : _householdIncomeLPA,
                  onChanged: (v) {
                    formData.householdIncome = v;
                    onChanged();
                  },
                ),
                const SizedBox(height: 16),
                _SectionLabel(label: l.matrimonyFamilyTypeQuestion),
                const SizedBox(height: 8),
                _ChipRow(
                  options: [l.nuclear, l.joint],
                  selected: formData.familyType,
                  onSelected: (v) {
                    formData.familyType = v;
                    onChanged();
                  },
                ),
                const SizedBox(height: 16),
                _SectionLabel(label: l.matrimonyFamilyValuesQuestion),
                const SizedBox(height: 8),
                _ChipRow(
                  options: [l.traditional, l.moderate, l.liberal],
                  selected: formData.familyValues,
                  onSelected: (v) {
                    formData.familyValues = v;
                    onChanged();
                  },
                ),
                const SizedBox(height: 16),
                _SearchableSelectField(
                  label: l.motherAgeQuestion,
                  value: formData.motherAge,
                  hint: 'e.g. 45 or select Deceased',
                  options: _parentAgeOptions,
                  onChanged: (v) {
                    formData.motherAge = v;
                    onChanged();
                  },
                ),
                const SizedBox(height: 16),
                _SearchableSelectField(
                  label: l.fatherAgeQuestion,
                  value: formData.fatherAge,
                  hint: 'e.g. 50 or select Deceased',
                  options: _parentAgeOptions,
                  onChanged: (v) {
                    formData.fatherAge = v;
                    onChanged();
                  },
                ),
                const SizedBox(height: 16),
                _SearchableSelectField(
                  label: l.motherOccupationQuestion,
                  value: formData.motherOccupation,
                  hint: l.motherOccupationHint,
                  options: _parentOccupationOptions,
                  onChanged: (v) {
                    formData.motherOccupation = v;
                    onChanged();
                  },
                ),
                const SizedBox(height: 16),
                _SearchableSelectField(
                  label: l.fatherOccupationQuestion,
                  value: formData.fatherOccupation,
                  hint: l.fatherOccupationHint,
                  options: _parentOccupationOptions,
                  onChanged: (v) {
                    formData.fatherOccupation = v;
                    onChanged();
                  },
                ),
                const SizedBox(height: 16),
                _SectionLabel(label: l.siblingsQuestion),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _DropdownField(
                        label: l.siblingsBrothers,
                        value: formData.siblingBrothers,
                        items: _siblingCountOptions,
                        onChanged: (v) {
                          formData.siblingBrothers = v;
                          _syncSiblingsText(formData);
                          onChanged();
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _DropdownField(
                        label: l.siblingsSisters,
                        value: formData.siblingSisters,
                        items: _siblingCountOptions,
                        onChanged: (v) {
                          formData.siblingSisters = v;
                          _syncSiblingsText(formData);
                          onChanged();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          if (showFamily) const SizedBox(height: 24),

          // Horoscope
          if (showHoroscope)
            _DetailCard(
              icon: Icons.auto_awesome_outlined,
              title: l.horoscopeQuestion,
              children: [
                _SectionLabel(label: l.manglikQuestion),
                const SizedBox(height: 8),
                _ChipRow(
                  options: [
                    l.manglikYes,
                    l.manglikNo,
                    l.manglikPartial,
                    l.manglikDontKnow,
                  ],
                  selected: formData.manglik,
                  onSelected: (v) {
                    formData.manglik = v;
                    onChanged();
                  },
                ),
                const SizedBox(height: 16),
                _DropdownField(
                  label: l.rashiQuestion,
                  value: formData.rashi,
                  items: const [
                    'Mesh (Aries)',
                    'Vrishabh (Taurus)',
                    'Mithun (Gemini)',
                    'Kark (Cancer)',
                    'Simha (Leo)',
                    'Kanya (Virgo)',
                    'Tula (Libra)',
                    'Vrishchik (Scorpio)',
                    'Dhanu (Sagittarius)',
                    'Makar (Capricorn)',
                    'Kumbh (Aquarius)',
                    'Meen (Pisces)',
                    'Don\'t know',
                  ],
                  onChanged: (v) {
                    formData.rashi = v;
                    onChanged();
                  },
                ),
                const SizedBox(height: 16),
                _DropdownField(
                  label: l.nakshatraQuestion,
                  value: formData.nakshatra,
                  items: const [
                    'Ashwini',
                    'Bharani',
                    'Krittika',
                    'Rohini',
                    'Mrigashira',
                    'Ardra',
                    'Punarvasu',
                    'Pushya',
                    'Ashlesha',
                    'Magha',
                    'Purva Phalguni',
                    'Uttara Phalguni',
                    'Hasta',
                    'Chitra',
                    'Swati',
                    'Vishakha',
                    'Anuradha',
                    'Jyeshtha',
                    'Moola',
                    'Purva Ashadha',
                    'Uttara Ashadha',
                    'Shravana',
                    'Dhanishta',
                    'Shatabhisha',
                    'Purva Bhadrapada',
                    'Uttara Bhadrapada',
                    'Revati',
                    'Don\'t know',
                  ],
                  onChanged: (v) {
                    formData.nakshatra = v;
                    onChanged();
                  },
                ),
                const SizedBox(height: 16),
                _SearchableSelectField(
                  label: l.gotraQuestion,
                  value: formData.gotra,
                  hint: l.gotraHint,
                  options: _gotraOptions,
                  onChanged: (v) {
                    formData.gotra = v;
                    onChanged();
                  },
                ),
                const SizedBox(height: 16),
                _TimeOfBirthField(
                  label: l.birthTimeQuestion,
                  value: formData.birthTime,
                  hint: l.birthTimeHint,
                  onChanged: (v) {
                    formData.birthTime = v;
                    onChanged();
                  },
                ),
                const SizedBox(height: 16),
                _FamilyLocationSearchField(
                  label: l.birthPlaceQuestion,
                  value: formData.birthPlace ?? '',
                  hint: l.birthPlaceHint,
                  onSelected: (displayName, _) {
                    formData.birthPlace = displayName;
                    onChanged();
                  },
                ),
              ],
            ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

String _sectionTitle(StepDetailsOnlySection section, AppLocalizations l) {
  switch (section) {
    case StepDetailsOnlySection.religion:
      return l.backgroundTitle;
    case StepDetailsOnlySection.lifestyle:
      return 'Lifestyle & habits';
    case StepDetailsOnlySection.family:
      return l.profileBuilderFamily;
    case StepDetailsOnlySection.horoscope:
      return l.horoscopeQuestion;
  }
}

String _sectionSubtitle(StepDetailsOnlySection section) {
  switch (section) {
    case StepDetailsOnlySection.religion:
      return 'Update your religion and community.';
    case StepDetailsOnlySection.lifestyle:
      return 'Diet, drinking, smoking and more.';
    case StepDetailsOnlySection.family:
      return 'Update your family details.';
    case StepDetailsOnlySection.horoscope:
      return 'Update your horoscope details.';
  }
}

// ── Shared building blocks ──────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Text(
        label,
        style: AppTypography.labelLarge.copyWith(
          color: Theme.of(context).colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({
    required this.icon,
    required this.title,
    required this.children,
  });

  final IconData icon;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
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
              Icon(icon, size: 22, color: onSurface.withValues(alpha: 0.6)),
              const SizedBox(width: 10),
              Text(
                title,
                style: AppTypography.titleMedium.copyWith(
                  color: onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }
}

/// Time of birth: tap to open time picker (clever selectable).
class _TimeOfBirthField extends StatelessWidget {
  const _TimeOfBirthField({
    required this.label,
    required this.value,
    required this.hint,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final String hint;
  final ValueChanged<String?> onChanged;

  static TimeOfDay? _parse(String? s) {
    if (s == null || s.trim().isEmpty) return null;
    final t = s.trim();
    // Try "11:30 AM" / "11:30 PM"
    final amPm = RegExp(r'^(\d{1,2}):(\d{2})\s*(AM|PM)$', caseSensitive: false);
    final m = amPm.firstMatch(t);
    if (m != null) {
      var h = int.tryParse(m.group(1) ?? '') ?? 0;
      final min = int.tryParse(m.group(2) ?? '') ?? 0;
      final pm = (m.group(3) ?? '').toUpperCase() == 'PM';
      if (pm && h < 12) h += 12;
      if (!pm && h == 12) h = 0;
      if (h >= 0 && h <= 23 && min >= 0 && min <= 59)
        return TimeOfDay(hour: h, minute: min);
    }
    // Try "11:30" (24h or 12h)
    final simple = RegExp(r'^(\d{1,2}):(\d{2})$');
    final m2 = simple.firstMatch(t);
    if (m2 != null) {
      var h = int.tryParse(m2.group(1) ?? '') ?? 0;
      final min = int.tryParse(m2.group(2) ?? '') ?? 0;
      if (h >= 0 && h <= 23 && min >= 0 && min <= 59)
        return TimeOfDay(hour: h, minute: min);
    }
    return null;
  }

  static String _format(TimeOfDay t) {
    final h = t.hour;
    final hour12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    final am = h < 12 ? 'AM' : 'PM';
    return '${hour12.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')} $am';
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final initial = _parse(value) ?? TimeOfDay.now();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.labelMedium.copyWith(
            color: onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: () async {
            final picked = await showTimePicker(
              context: context,
              initialTime: initial,
              builder: (context, child) =>
                  Theme(data: Theme.of(context), child: child!),
            );
            if (picked != null) onChanged(_format(picked));
          },
          borderRadius: BorderRadius.circular(12),
          child: InputDecorator(
            decoration: InputDecoration(
              hintText: hint,
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              suffixIcon: Icon(
                Icons.schedule,
                size: 20,
                color: onSurface.withValues(alpha: 0.4),
              ),
            ),
            child: Text(
              value?.isNotEmpty == true ? value! : '',
              style: AppTypography.bodyMedium.copyWith(
                color: value?.isNotEmpty == true
                    ? onSurface
                    : onSurface.withValues(alpha: 0.5),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DropdownField extends StatelessWidget {
  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final surface = Theme.of(context).colorScheme.surface;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.labelMedium.copyWith(
            color: onSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: value,
          isExpanded: true,
          dropdownColor: surface,
          style: TextStyle(
            color: onSurface,
            fontSize: 15,
            fontWeight: FontWeight.w400,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: Theme.of(
                  context,
                ).colorScheme.outlineVariant.withValues(alpha: 0.6),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 16,
            ),
          ),
          items: items
              .map(
                (e) => DropdownMenuItem(
                  value: e,
                  child: Text(
                    e,
                    style: TextStyle(color: onSurface, fontSize: 14),
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _SmartTextField extends StatefulWidget {
  const _SmartTextField({
    required this.label,
    required this.value,
    required this.hint,
    required this.onChanged,
  });

  final String label;
  final String value;
  final String hint;
  final ValueChanged<String> onChanged;

  @override
  State<_SmartTextField> createState() => _SmartTextFieldState();
}

class _SmartTextFieldState extends State<_SmartTextField> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(_SmartTextField old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value && widget.value != _ctrl.text) {
      _ctrl.text = widget.value;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: AppTypography.labelMedium.copyWith(
            color: onSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _ctrl,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            hintText: widget.hint,
            filled: true,
            fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          onChanged: widget.onChanged,
        ),
      ],
    );
  }
}

class _ChipRow extends StatelessWidget {
  const _ChipRow({
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final List<String> options;
  final String? selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: options.map((opt) {
        final isSelected = opt == selected;
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onSelected(opt),
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              constraints: const BoxConstraints(minHeight: 48),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? accent.withValues(alpha: 0.12)
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? accent : Theme.of(context).dividerColor,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  opt,
                  style: AppTypography.bodyMedium.copyWith(
                    color: isSelected ? accent : onSurface,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _MultilineField extends StatefulWidget {
  const _MultilineField({
    required this.value,
    required this.hint,
    required this.onChanged,
  });

  final String value;
  final String hint;
  final ValueChanged<String> onChanged;

  @override
  State<_MultilineField> createState() => _MultilineFieldState();
}

class _MultilineFieldState extends State<_MultilineField> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(_MultilineField old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value && widget.value != _ctrl.text) {
      _ctrl.text = widget.value;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _ctrl,
      maxLines: 4,
      textInputAction: TextInputAction.newline,
      keyboardType: TextInputType.multiline,
      decoration: InputDecoration(
        hintText: widget.hint,
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.all(16),
      ),
      onChanged: widget.onChanged,
    );
  }
}

class _OptionGrid extends StatelessWidget {
  const _OptionGrid({
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final List<_Option> options;
  final String? selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: options.map((opt) {
        final isSelected = opt.label == selected;
        return GestureDetector(
          onTap: () => onSelected(opt.label),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: (MediaQuery.of(context).size.width - 58) / 2,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: isSelected
                  ? accent.withValues(alpha: 0.12)
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? accent : Theme.of(context).dividerColor,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  opt.icon,
                  size: 20,
                  color: isSelected ? accent : onSurface.withValues(alpha: 0.4),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    opt.label,
                    style: AppTypography.bodySmall.copyWith(
                      color: isSelected ? accent : onSurface,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _Option {
  const _Option(this.label, this.icon);
  final String label;
  final IconData icon;
}

// ── Lifestyle Section (shared by dating + matrimony) ────────────────────

class _LifestyleSection extends StatelessWidget {
  const _LifestyleSection({required this.formData, required this.onChanged});
  final ProfileFormData formData;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final accent = Theme.of(context).colorScheme.primary;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
              Icon(Icons.self_improvement_outlined, size: 20, color: accent),
              const SizedBox(width: 8),
              Text(
                l.lifestyleTitle,
                style: AppTypography.titleMedium.copyWith(
                  color: onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          _LifestyleRow(
            icon: Icons.restaurant_outlined,
            label: l.dietQuestion,
            options: [
              l.dietVeg,
              l.dietNonVeg,
              l.dietEggetarian,
              l.dietVegan,
              l.dietJain,
              l.dietFlexible,
            ],
            selected: formData.diet,
            onSelected: (v) {
              formData.diet = v;
              onChanged();
            },
          ),
          _divider(context),

          _LifestyleRow(
            icon: Icons.local_bar_outlined,
            label: l.drinkQuestion,
            options: [l.drinkNever, l.drinkSocially, l.drinkRegularly],
            selected: formData.drinking,
            onSelected: (v) {
              formData.drinking = v;
              onChanged();
            },
          ),
          _divider(context),

          _LifestyleRow(
            icon: Icons.smoke_free,
            label: l.smokeQuestion,
            options: [l.smokeNever, l.smokeOccasionally, l.smokeRegularly],
            selected: formData.smoking,
            onSelected: (v) {
              formData.smoking = v;
              onChanged();
            },
          ),
          _divider(context),

          _LifestyleRow(
            icon: Icons.fitness_center_outlined,
            label: l.exerciseQuestion,
            options: [
              l.exerciseDaily,
              l.exerciseRegularly,
              l.exerciseSometimes,
              l.exerciseRarely,
            ],
            selected: formData.exercise,
            onSelected: (v) {
              formData.exercise = v;
              onChanged();
            },
          ),
        ],
      ),
    );
  }

  Widget _divider(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Divider(
        height: 1,
        color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
      ),
    );
  }
}

class _LifestyleRow extends StatelessWidget {
  const _LifestyleRow({
    required this.icon,
    required this.label,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final IconData icon;
  final String label;
  final List<String> options;
  final String? selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: onSurface.withValues(alpha: 0.45)),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTypography.labelLarge.copyWith(
                color: onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (selected != null) ...[
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  selected!,
                  style: AppTypography.labelSmall.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((opt) {
            final isSelected = opt == selected;
            return GestureDetector(
              onTap: () => onSelected(opt),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? accent.withValues(alpha: 0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? accent
                        : onSurface.withValues(alpha: 0.15),
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Text(
                  opt,
                  style: AppTypography.bodySmall.copyWith(
                    color: isSelected
                        ? accent
                        : onSurface.withValues(alpha: 0.7),
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
