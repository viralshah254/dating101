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
  ConsumerState<DiscoveryFiltersSheet> createState() => _DiscoveryFiltersSheetState();
}

class _DiscoveryFiltersSheetState extends ConsumerState<DiscoveryFiltersSheet> {
  int? _ageMin;
  int? _ageMax;
  String? _city;
  String? _religion;
  String? _education;
  String? _diet;

  @override
  void initState() {
    super.initState();
    _ageMin = widget.initialParams?.ageMin;
    _ageMax = widget.initialParams?.ageMax;
    _city = widget.initialParams?.city;
    _religion = widget.initialParams?.religion;
    _education = widget.initialParams?.education;
    _diet = widget.initialParams?.diet;
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
            final effectiveReligion = _religion ?? opts.religions.defaultSelected;
            final effectiveEducation = _education ?? opts.education.defaultSelected;
            final effectiveDiet = _diet ?? opts.diet?.defaultSelected;
            return _FiltersContent(
              scrollController: scrollController,
              opts: opts,
              ageMin: effectiveAgeMin,
              ageMax: effectiveAgeMax,
              city: effectiveCity,
              religion: effectiveReligion,
              education: effectiveEducation,
              diet: effectiveDiet,
              onAgeMinChanged: (v) => setState(() => _ageMin = v),
              onAgeMaxChanged: (v) => setState(() => _ageMax = v),
              onCityChanged: (v) => setState(() => _city = v),
              onReligionChanged: (v) => setState(() => _religion = v),
              onEducationChanged: (v) => setState(() => _education = v),
              onDietChanged: (v) => setState(() => _diet = v),
              onApply: () {
                widget.onApply(DiscoveryFilterParams(
                  ageMin: effectiveAgeMin,
                  ageMax: effectiveAgeMax,
                  city: effectiveCity?.isNotEmpty == true ? effectiveCity : null,
                  religion: effectiveReligion?.isNotEmpty == true ? effectiveReligion : null,
                  education: effectiveEducation?.isNotEmpty == true ? effectiveEducation : null,
                  diet: effectiveDiet?.isNotEmpty == true ? effectiveDiet : null,
                ));
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
                  TextButton(onPressed: () => Navigator.pop(context), child: Text(l.close)),
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
    required this.onAgeMinChanged,
    required this.onAgeMaxChanged,
    required this.onCityChanged,
    required this.onReligionChanged,
    required this.onEducationChanged,
    required this.onDietChanged,
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
  final void Function(int?) onAgeMinChanged;
  final void Function(int?) onAgeMaxChanged;
  final void Function(String?) onCityChanged;
  final void Function(String?) onReligionChanged;
  final void Function(String?) onEducationChanged;
  final void Function(String?) onDietChanged;
  final VoidCallback onApply;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l.filters, style: AppTypography.headlineSmall),
                TextButton(onPressed: onClear, child: const Text('Reset')),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              children: [
                _AgeSection(opts: opts, ageMin: ageMin, ageMax: ageMax, onAgeMinChanged: onAgeMinChanged, onAgeMaxChanged: onAgeMaxChanged),
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
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onApply,
                child: Text(l.apply),
              ),
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
            Text(l.ageRange, style: AppTypography.titleSmall.copyWith(color: onSurface, fontWeight: FontWeight.w600)),
            if (age.strict) ...[
              const SizedBox(width: 8),
              _StrictBadge(),
            ],
          ],
        ),
        const SizedBox(height: 8),
        if (age.strict)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '${age.defaultMin} – ${age.defaultMax} years',
              style: AppTypography.bodyMedium.copyWith(color: onSurface.withValues(alpha: 0.85)),
            ),
          )
        else
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: minVal.clamp(age.min, age.max),
                  decoration: const InputDecoration(labelText: 'Min'),
                  items: List.generate(age.max - age.min + 1, (i) => age.min + i)
                      .map((v) => DropdownMenuItem(value: v, child: Text('$v')))
                      .toList(),
                  onChanged: onAgeMinChanged,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: maxVal.clamp(age.min, age.max),
                  decoration: const InputDecoration(labelText: 'Max'),
                  items: List.generate(age.max - age.min + 1, (i) => age.min + i)
                      .map((v) => DropdownMenuItem(value: v, child: Text('$v')))
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
            Text(title, style: AppTypography.titleSmall.copyWith(color: onSurface, fontWeight: FontWeight.w600)),
            if (dimension.strict) ...[
              const SizedBox(width: 8),
              _StrictBadge(),
            ],
          ],
        ),
        const SizedBox(height: 8),
        if (dimension.strict && singleOption && dimension.options.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              dimension.options.first,
              style: AppTypography.bodyMedium.copyWith(color: onSurface.withValues(alpha: 0.85)),
            ),
          )
        else if (dimension.options.isEmpty)
          const SizedBox.shrink()
        else
          DropdownButtonFormField<String>(
            value: displayValue != null && dimension.options.contains(displayValue) ? displayValue : dimension.options.first,
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
