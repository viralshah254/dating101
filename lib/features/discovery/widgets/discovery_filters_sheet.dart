import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_typography.dart';
import '../../../domain/models/discovery_filter_params.dart';
import '../../../domain/models/filter_options.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/discovery_providers.dart';

/// Bottom sheet for discovery filters. Uses GET /discovery/filter-options;
/// strict dimensions are shown as read-only with "From your preferences" label.
class DiscoveryFiltersSheet extends ConsumerStatefulWidget {
  const DiscoveryFiltersSheet({
    super.key,
    this.initialParams,
    required this.onApply,
  });

  final DiscoveryFilterParams? initialParams;
  final void Function(DiscoveryFilterParams params) onApply;

  @override
  ConsumerState<DiscoveryFiltersSheet> createState() =>
      _DiscoveryFiltersSheetState();
}

/// Body type options for discovery filter (align with partner prefs).
const _bodyTypeOptions = [
  'Slim',
  'Average',
  'Athletic',
  'Heavyset',
  'Plus size',
];

class _DiscoveryFiltersSheetState extends ConsumerState<DiscoveryFiltersSheet> {
  int? _ageMin;
  int? _ageMax;
  String? _city;
  String? _religion;
  String? _education;
  String? _diet;
  int? _heightMinCm;
  int? _heightMaxCm;
  String? _bodyType;
  String? _maritalStatus;

  static const int _heightMinDefault = 140;
  static const int _heightMaxDefault = 200;

  @override
  void initState() {
    super.initState();
    _ageMin = widget.initialParams?.ageMin;
    _ageMax = widget.initialParams?.ageMax;
    _city = widget.initialParams?.city;
    _religion = widget.initialParams?.religion;
    _education = widget.initialParams?.education;
    _diet = widget.initialParams?.diet;
    _heightMinCm = widget.initialParams?.heightMinCm;
    _heightMaxCm = widget.initialParams?.heightMaxCm;
    _bodyType = widget.initialParams?.bodyType;
    _maritalStatus = widget.initialParams?.maritalStatus;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final optsAsync = ref.watch(filterOptionsProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return optsAsync.when(
          data: (opts) {
            final effectiveAgeMin = _ageMin ?? opts.age.defaultMin;
            final effectiveAgeMax = _ageMax ?? opts.age.defaultMax;
            final effectiveCity = _city ?? opts.cities.defaultSelected;
            final effectiveReligion =
                _religion ?? opts.religions.defaultSelected;
            final effectiveEducation =
                _education ?? opts.education.defaultSelected;
            final effectiveDiet = _diet ?? opts.diet?.defaultSelected;
            final heightOpts = opts.height;
            final effectiveHeightMin =
                _heightMinCm ?? heightOpts?.defaultMinCm ?? _heightMinDefault;
            final effectiveHeightMax =
                _heightMaxCm ?? heightOpts?.defaultMaxCm ?? _heightMaxDefault;
            final effectiveMaritalStatus =
                _maritalStatus ?? opts.maritalStatus?.defaultSelected;
            return _FiltersContent(
              scrollController: scrollController,
              opts: opts,
              ageMin: effectiveAgeMin,
              ageMax: effectiveAgeMax,
              city: effectiveCity,
              religion: effectiveReligion,
              education: effectiveEducation,
              diet: effectiveDiet,
              heightMinCm: effectiveHeightMin,
              heightMaxCm: effectiveHeightMax,
              bodyType: _bodyType,
              maritalStatus: effectiveMaritalStatus,
              onAgeMinChanged: (v) => setState(() => _ageMin = v),
              onAgeMaxChanged: (v) => setState(() => _ageMax = v),
              onCityChanged: (v) => setState(() => _city = v),
              onReligionChanged: (v) => setState(() => _religion = v),
              onEducationChanged: (v) => setState(() => _education = v),
              onDietChanged: (v) => setState(() => _diet = v),
              onHeightMinChanged: (v) => setState(() => _heightMinCm = v),
              onHeightMaxChanged: (v) => setState(() => _heightMaxCm = v),
              onBodyTypeChanged: (v) => setState(() => _bodyType = v),
              onMaritalStatusChanged: (v) => setState(() => _maritalStatus = v),
              onApply: () {
                widget.onApply(
                  DiscoveryFilterParams(
                    ageMin: _ageMin,
                    ageMax: _ageMax,
                    city: _city?.isNotEmpty == true ? _city : null,
                    religion: _religion?.isNotEmpty == true ? _religion : null,
                    education: _education?.isNotEmpty == true
                        ? _education
                        : null,
                    diet: _diet?.isNotEmpty == true ? _diet : null,
                    heightMinCm: _heightMinCm,
                    heightMaxCm: _heightMaxCm,
                    bodyType: _bodyType?.isNotEmpty == true ? _bodyType : null,
                    maritalStatus: _maritalStatus?.isNotEmpty == true
                        ? _maritalStatus
                        : null,
                  ),
                );
                if (context.mounted) Navigator.pop(context);
              },
              onClear: () {
                setState(() {
                  _ageMin = null;
                  _ageMax = null;
                  _city = null;
                  _religion = null;
                  _education = null;
                  _diet = null;
                  _heightMinCm = null;
                  _heightMaxCm = null;
                  _bodyType = null;
                  _maritalStatus = null;
                });
              },
            );
          },
          loading: () => SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l.filters, style: AppTypography.headlineSmall),
                  const SizedBox(height: 24),
                  const Center(child: CircularProgressIndicator()),
                ],
              ),
            ),
          ),
          error: (e, _) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(l.filters, style: AppTypography.headlineSmall),
                  const SizedBox(height: 16),
                  Text(l.errorGeneric, style: AppTypography.bodyMedium),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(l.close),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FiltersContent extends StatelessWidget {
  const _FiltersContent({
    required this.scrollController,
    required this.opts,
    required this.ageMin,
    required this.ageMax,
    required this.city,
    required this.religion,
    required this.education,
    required this.diet,
    required this.heightMinCm,
    required this.heightMaxCm,
    required this.bodyType,
    this.maritalStatus,
    required this.onAgeMinChanged,
    required this.onAgeMaxChanged,
    required this.onCityChanged,
    required this.onReligionChanged,
    required this.onEducationChanged,
    required this.onDietChanged,
    required this.onHeightMinChanged,
    required this.onHeightMaxChanged,
    required this.onBodyTypeChanged,
    required this.onMaritalStatusChanged,
    required this.onApply,
    required this.onClear,
  });

  final ScrollController scrollController;
  final FilterOptions opts;
  final int? ageMin;
  final int? ageMax;
  final String? city;
  final String? religion;
  final String? education;
  final String? diet;
  final int? heightMinCm;
  final int? heightMaxCm;
  final String? bodyType;
  final String? maritalStatus;
  final void Function(int?) onAgeMinChanged;
  final void Function(int?) onAgeMaxChanged;
  final void Function(String?) onCityChanged;
  final void Function(String?) onReligionChanged;
  final void Function(String?) onEducationChanged;
  final void Function(String?) onDietChanged;
  final void Function(int?) onHeightMinChanged;
  final void Function(int?) onHeightMaxChanged;
  final void Function(String?) onBodyTypeChanged;
  final void Function(String?) onMaritalStatusChanged;
  final VoidCallback onApply;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l.filters, style: AppTypography.headlineSmall),
                TextButton(onPressed: onClear, child: Text(l.reset)),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              children: [
                _AgeSection(
                  opts: opts,
                  ageMin: ageMin,
                  ageMax: ageMax,
                  onAgeMinChanged: onAgeMinChanged,
                  onAgeMaxChanged: onAgeMaxChanged,
                ),
                const SizedBox(height: 20),
                _DimensionSection(
                  title: l.city,
                  dimension: opts.cities,
                  value: city,
                  onChanged: onCityChanged,
                ),
                const SizedBox(height: 16),
                _DimensionSection(
                  title: l.religion,
                  dimension: opts.religions,
                  value: religion,
                  onChanged: onReligionChanged,
                ),
                const SizedBox(height: 16),
                _DimensionSection(
                  title: l.educationLevel,
                  dimension: opts.education,
                  value: education,
                  onChanged: onEducationChanged,
                ),
                if (opts.diet != null) ...[
                  const SizedBox(height: 16),
                  _DimensionSection(
                    title: l.diet,
                    dimension: opts.diet!,
                    value: diet,
                    onChanged: onDietChanged,
                  ),
                ],
                if (opts.height != null) ...[
                  const SizedBox(height: 16),
                  _HeightSection(
                    opts: opts.height!,
                    heightMinCm: heightMinCm,
                    heightMaxCm: heightMaxCm,
                    onHeightMinChanged: onHeightMinChanged,
                    onHeightMaxChanged: onHeightMaxChanged,
                  ),
                ],
                const SizedBox(height: 16),
                _BodyTypeSection(value: bodyType, onChanged: onBodyTypeChanged),
                if (opts.maritalStatus != null) ...[
                  const SizedBox(height: 16),
                  _DimensionSection(
                    title: l.maritalStatus,
                    dimension: opts.maritalStatus!,
                    value: maritalStatus,
                    onChanged: onMaritalStatusChanged,
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(onPressed: onApply, child: Text(l.apply)),
            ),
          ),
        ],
      ),
    );
  }
}

class _AgeSection extends StatelessWidget {
  const _AgeSection({
    required this.opts,
    required this.ageMin,
    required this.ageMax,
    required this.onAgeMinChanged,
    required this.onAgeMaxChanged,
  });

  final FilterOptions opts;
  final int? ageMin;
  final int? ageMax;
  final void Function(int?) onAgeMinChanged;
  final void Function(int?) onAgeMaxChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final age = opts.age;
    final minVal = ageMin ?? age.defaultMin;
    final maxVal = ageMax ?? age.defaultMax;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              l.ageRange,
              style: AppTypography.titleSmall.copyWith(
                color: onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (age.strict) ...[const SizedBox(width: 8), _StrictBadge()],
          ],
        ),
        const SizedBox(height: 8),
        if (age.strict)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '${age.defaultMin} – ${age.defaultMax} years',
              style: AppTypography.bodyMedium.copyWith(
                color: onSurface.withValues(alpha: 0.85),
              ),
            ),
          )
        else
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: minVal.clamp(age.min, age.max),
                  decoration: const InputDecoration(labelText: 'Min'),
                  items:
                      List.generate(age.max - age.min + 1, (i) => age.min + i)
                          .map(
                            (v) =>
                                DropdownMenuItem(value: v, child: Text('$v')),
                          )
                          .toList(),
                  onChanged: onAgeMinChanged,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: maxVal.clamp(age.min, age.max),
                  decoration: const InputDecoration(labelText: 'Max'),
                  items:
                      List.generate(age.max - age.min + 1, (i) => age.min + i)
                          .map(
                            (v) =>
                                DropdownMenuItem(value: v, child: Text('$v')),
                          )
                          .toList(),
                  onChanged: onAgeMaxChanged,
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _DimensionSection extends StatelessWidget {
  const _DimensionSection({
    required this.title,
    required this.dimension,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final FilterDimension dimension;
  final String? value;
  final void Function(String?) onChanged;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final displayValue = value ?? dimension.defaultSelected;
    final singleOption = dimension.strict && dimension.options.length <= 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: AppTypography.titleSmall.copyWith(
                color: onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (dimension.strict) ...[const SizedBox(width: 8), _StrictBadge()],
          ],
        ),
        const SizedBox(height: 8),
        if (dimension.strict && singleOption && dimension.options.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              dimension.options.first,
              style: AppTypography.bodyMedium.copyWith(
                color: onSurface.withValues(alpha: 0.85),
              ),
            ),
          )
        else if (dimension.options.isEmpty)
          const SizedBox.shrink()
        else
          DropdownButtonFormField<String>(
            initialValue:
                displayValue != null && dimension.options.contains(displayValue)
                ? displayValue
                : dimension.options.first,
            decoration: InputDecoration(hintText: title),
            items: dimension.options
                .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                .toList(),
            onChanged: dimension.strict ? null : onChanged,
          ),
      ],
    );
  }
}

class _StrictBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'From your preferences',
        style: AppTypography.labelSmall.copyWith(
          color: Theme.of(context).colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _HeightSection extends StatelessWidget {
  const _HeightSection({
    required this.opts,
    required this.heightMinCm,
    required this.heightMaxCm,
    required this.onHeightMinChanged,
    required this.onHeightMaxChanged,
  });

  final FilterHeightRange opts;
  final int? heightMinCm;
  final int? heightMaxCm;
  final void Function(int?) onHeightMinChanged;
  final void Function(int?) onHeightMaxChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final minVal = heightMinCm ?? opts.defaultMinCm ?? opts.minCm;
    final maxVal = heightMaxCm ?? opts.defaultMaxCm ?? opts.maxCm;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              l.height,
              style: AppTypography.titleSmall.copyWith(
                color: onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (opts.strict) ...[const SizedBox(width: 8), _StrictBadge()],
          ],
        ),
        const SizedBox(height: 8),
        if (opts.strict)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '${opts.defaultMinCm ?? opts.minCm} – ${opts.defaultMaxCm ?? opts.maxCm} cm',
              style: AppTypography.bodyMedium.copyWith(
                color: onSurface.withValues(alpha: 0.85),
              ),
            ),
          )
        else
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: minVal.clamp(opts.minCm, opts.maxCm),
                  decoration: const InputDecoration(labelText: 'Min (cm)'),
                  items:
                      List.generate(
                            opts.maxCm - opts.minCm + 1,
                            (i) => opts.minCm + i,
                          )
                          .map(
                            (v) =>
                                DropdownMenuItem(value: v, child: Text('$v')),
                          )
                          .toList(),
                  onChanged: onHeightMinChanged,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: maxVal.clamp(opts.minCm, opts.maxCm),
                  decoration: const InputDecoration(labelText: 'Max (cm)'),
                  items:
                      List.generate(
                            opts.maxCm - opts.minCm + 1,
                            (i) => opts.minCm + i,
                          )
                          .map(
                            (v) =>
                                DropdownMenuItem(value: v, child: Text('$v')),
                          )
                          .toList(),
                  onChanged: onHeightMaxChanged,
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _BodyTypeSection extends StatelessWidget {
  const _BodyTypeSection({required this.value, required this.onChanged});

  final String? value;
  final void Function(String?) onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.bodyTypeQuestion,
          style: AppTypography.titleSmall.copyWith(
            color: onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String?>(
          value: value != null && _bodyTypeOptions.contains(value)
              ? value
              : null,
          decoration: InputDecoration(hintText: l.anyOption),
          items: [
            DropdownMenuItem<String?>(value: null, child: Text(l.anyOption)),
            ..._bodyTypeOptions.map(
              (o) => DropdownMenuItem<String?>(value: o, child: Text(o)),
            ),
          ],
          onChanged: onChanged,
        ),
      ],
    );
  }
}
