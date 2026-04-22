import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/mode/app_mode.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/brand_theme.dart';
import '../../../domain/models/discovery_filter_params.dart';
import '../../../domain/models/filter_options.dart';
import '../../../features/matches/providers/matches_providers.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/discovery_providers.dart';

/// Unified filter + sort bottom sheet used for both Discover (dating) and
/// Matches (matrimony) screens.
///
/// Pass [mode] to control which sections are shown (e.g. marital status and
/// diet are matrimony-only).  Pass [isMatrimony] = true to show extra sections.
class UnifiedFilterSheet extends ConsumerStatefulWidget {
  const UnifiedFilterSheet({
    super.key,
    required this.mode,
    required this.onApply,
    this.initialParams,
    this.initialSort,
  });

  final AppMode mode;
  final void Function(DiscoveryFilterParams params, SortOption sort) onApply;
  final DiscoveryFilterParams? initialParams;
  final SortOption? initialSort;

  @override
  ConsumerState<UnifiedFilterSheet> createState() => _UnifiedFilterSheetState();
}

class _UnifiedFilterSheetState extends ConsumerState<UnifiedFilterSheet> {
  late int _ageMin;
  late int _ageMax;
  String? _city;
  String? _religion;
  String? _education;
  String? _diet;
  String? _maritalStatus;
  String? _motherTongue;
  String? _intentFilter;
  late int _heightMin;
  late int _heightMax;
  late SortOption _sort;
  late bool _verifiedOnly;

  static const int _defaultAgeMin = 22;
  static const int _defaultAgeMax = 40;
  static const int _heightMinDefault = 145;
  static const int _heightMaxDefault = 195;

  @override
  void initState() {
    super.initState();
    final p = widget.initialParams;
    _ageMin = p?.ageMin ?? _defaultAgeMin;
    _ageMax = p?.ageMax ?? _defaultAgeMax;
    _city = p?.city;
    _religion = p?.religion;
    _education = p?.education;
    _diet = p?.diet;
    _maritalStatus = p?.maritalStatus;
    _motherTongue = p?.motherTongue;
    _intentFilter = p?.intentFilter;
    _heightMin = p?.heightMinCm ?? _heightMinDefault;
    _heightMax = p?.heightMaxCm ?? _heightMaxDefault;
    _sort = widget.initialSort ?? ref.read(sortByProvider);
    _verifiedOnly = p?.verifiedOnly ?? false;
  }

  bool get _isMatrimony => widget.mode.isMatrimony;

  void _applyAndClose() {
    widget.onApply(
      DiscoveryFilterParams(
        ageMin: _ageMin != _defaultAgeMin ? _ageMin : null,
        ageMax: _ageMax != _defaultAgeMax ? _ageMax : null,
        city: _city?.isNotEmpty == true ? _city : null,
        religion: _religion?.isNotEmpty == true ? _religion : null,
        education: _education?.isNotEmpty == true ? _education : null,
        diet: _diet?.isNotEmpty == true ? _diet : null,
        maritalStatus: _maritalStatus?.isNotEmpty == true ? _maritalStatus : null,
        motherTongue: _motherTongue?.isNotEmpty == true ? _motherTongue : null,
        heightMinCm: _heightMin != _heightMinDefault ? _heightMin : null,
        heightMaxCm: _heightMax != _heightMaxDefault ? _heightMax : null,
        intentFilter: _intentFilter?.isNotEmpty == true ? _intentFilter : null,
        verifiedOnly: _verifiedOnly,
      ),
      _sort,
    );
    if (mounted) Navigator.pop(context);
  }

  void _reset(FilterOptions opts) {
    setState(() {
      _ageMin = opts.age.defaultMin;
      _ageMax = opts.age.defaultMax;
      _city = null;
      _religion = null;
      _education = null;
      _diet = null;
      _maritalStatus = null;
      _motherTongue = null;
      _intentFilter = null;
      _heightMin = _heightMinDefault;
      _heightMax = _heightMaxDefault;
      _sort = SortOption.bestMatch;
      _verifiedOnly = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final optsAsync = ref.watch(filterOptionsProvider);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final brand = theme.extension<BrandTheme>()!;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.97,
      expand: false,
      builder: (ctx, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: optsAsync.when(
            data: (opts) => _SheetContent(
              scrollController: scrollController,
              opts: opts,
              isMatrimony: _isMatrimony,
              ageMin: _ageMin,
              ageMax: _ageMax,
              city: _city,
              religion: _religion,
              education: _education,
              diet: _diet,
              maritalStatus: _maritalStatus,
              motherTongue: _motherTongue,
              heightMin: _heightMin,
              heightMax: _heightMax,
              sort: _sort,
              verifiedOnly: _verifiedOnly,
              onAgeChanged: (min, max) => setState(() {
                _ageMin = min;
                _ageMax = max;
              }),
              onCityChanged: (v) => setState(() => _city = v),
              onReligionChanged: (v) => setState(() => _religion = v),
              onEducationChanged: (v) => setState(() => _education = v),
              onDietChanged: (v) => setState(() => _diet = v),
              onMaritalStatusChanged: (v) => setState(() => _maritalStatus = v),
              onMotherTongueChanged: (v) => setState(() => _motherTongue = v),
              intentFilter: _intentFilter,
              onIntentFilterChanged: (v) => setState(() => _intentFilter = v),
              onHeightChanged: (min, max) => setState(() {
                _heightMin = min;
                _heightMax = max;
              }),
              onSortChanged: (s) => setState(() => _sort = s),
              onVerifiedOnlyChanged: (v) => setState(() => _verifiedOnly = v),
              onReset: () => _reset(opts),
              onApply: _applyAndClose,
              brand: brand,
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  AppLocalizations.of(context)!.errorGeneric,
                  style: AppTypography.bodyMedium.copyWith(
                    color: cs.onSurface,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SheetContent extends StatelessWidget {
  const _SheetContent({
    required this.scrollController,
    required this.opts,
    required this.isMatrimony,
    required this.ageMin,
    required this.ageMax,
    required this.city,
    required this.religion,
    required this.education,
    required this.diet,
    required this.maritalStatus,
    required this.motherTongue,
    required this.heightMin,
    required this.heightMax,
    required this.sort,
    required this.verifiedOnly,
    required this.onAgeChanged,
    required this.onCityChanged,
    required this.onReligionChanged,
    required this.onEducationChanged,
    required this.onDietChanged,
    required this.onMaritalStatusChanged,
    required this.onMotherTongueChanged,
    required this.onHeightChanged,
    required this.onSortChanged,
    required this.onVerifiedOnlyChanged,
    required this.onReset,
    required this.onApply,
    required this.brand,
    this.intentFilter,
    this.onIntentFilterChanged,
  });

  final ScrollController scrollController;
  final FilterOptions opts;
  final bool isMatrimony;
  final int ageMin;
  final int ageMax;
  final String? city;
  final String? religion;
  final String? education;
  final String? diet;
  final String? maritalStatus;
  final String? motherTongue;
  final String? intentFilter;
  final int heightMin;
  final int heightMax;
  final SortOption sort;
  final bool verifiedOnly;
  final void Function(int min, int max) onAgeChanged;
  final void Function(String?) onCityChanged;
  final void Function(String?) onReligionChanged;
  final void Function(String?) onEducationChanged;
  final void Function(String?) onDietChanged;
  final void Function(String?) onMaritalStatusChanged;
  final void Function(String?) onMotherTongueChanged;
  final void Function(String?)? onIntentFilterChanged;
  final void Function(int min, int max) onHeightChanged;
  final void Function(SortOption) onSortChanged;
  final void Function(bool) onVerifiedOnlyChanged;
  final VoidCallback onReset;
  final VoidCallback onApply;
  final BrandTheme brand;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final onSurface = cs.onSurface;

    return SafeArea(
      child: Column(
        children: [
          // Handle bar
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: onSurface.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 12, 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l.filters,
                    style: AppTypography.headlineSmall.copyWith(
                      color: onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: onReset,
                  child: Text(
                    l.reset,
                    style: TextStyle(
                      color: cs.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Scrollable content
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
              children: [
                // ── Verified only toggle ──────────────────────────
                _VerifiedOnlyToggle(
                  value: verifiedOnly,
                  onChanged: onVerifiedOnlyChanged,
                  onSurface: onSurface,
                  cs: cs,
                ),
                const _Divider(),

                // ── Sort row ──────────────────────────────────────
                _SectionHeader(label: 'Sort by', onSurface: onSurface),
                const SizedBox(height: 8),
                _SortRow(current: sort, onChanged: onSortChanged, brand: brand),
                const _Divider(),

                // ── Age range ────────────────────────────────────
                _SectionHeader(label: l.ageRange, onSurface: onSurface, strict: opts.age.strict),
                const SizedBox(height: 4),
                _AgeSlider(
                  min: opts.age.min,
                  max: opts.age.max,
                  ageMin: ageMin,
                  ageMax: ageMax,
                  onChanged: onAgeChanged,
                  accent: cs.primary,
                  onSurface: onSurface,
                  strict: opts.age.strict,
                ),
                const _Divider(),

                // ── Height range ─────────────────────────────────
                _SectionHeader(label: l.height, onSurface: onSurface),
                const SizedBox(height: 4),
                _HeightSlider(
                  heightMin: heightMin,
                  heightMax: heightMax,
                  onChanged: onHeightChanged,
                  accent: cs.primary,
                  onSurface: onSurface,
                ),
                const _Divider(),

                // ── City ─────────────────────────────────────────
                _SectionHeader(label: l.city, onSurface: onSurface, strict: opts.cities.strict),
                const SizedBox(height: 8),
                _ChipGrid(
                  dimension: opts.cities,
                  selected: city,
                  onChanged: onCityChanged,
                  accent: cs.primary,
                ),
                const _Divider(),

                // ── Religion ─────────────────────────────────────
                _SectionHeader(label: l.religion, onSurface: onSurface, strict: opts.religions.strict),
                const SizedBox(height: 8),
                _ChipGrid(
                  dimension: opts.religions,
                  selected: religion,
                  onChanged: onReligionChanged,
                  accent: cs.primary,
                ),
                const _Divider(),

                // ── Mother tongue ─────────────────────────────────
                if (opts.motherTongue != null && (opts.motherTongue!.options.isNotEmpty)) ...[
                  _SectionHeader(label: l.motherTongue, onSurface: onSurface),
                  const SizedBox(height: 8),
                  _ChipGrid(
                    dimension: opts.motherTongue!,
                    selected: motherTongue,
                    onChanged: onMotherTongueChanged,
                    accent: cs.primary,
                  ),
                  const _Divider(),
                ],

                // ── Education ─────────────────────────────────────
                _SectionHeader(label: l.educationLevel, onSurface: onSurface, strict: opts.education.strict),
                const SizedBox(height: 8),
                _ChipGrid(
                  dimension: opts.education,
                  selected: education,
                  onChanged: onEducationChanged,
                  accent: cs.primary,
                ),

                // ── Intent Match filter (dating mode) ─────────────
                if (!isMatrimony) ...[
                  const _Divider(),
                  _SectionHeader(label: 'Looking For', onSurface: onSurface),
                  const SizedBox(height: 8),
                  _IntentFilterChips(
                    selected: intentFilter,
                    onChanged: onIntentFilterChanged,
                    accent: cs.primary,
                  ),
                ],

                // ── Matrimony-only sections ────────────────────────
                if (isMatrimony) ...[
                  if (opts.diet != null && opts.diet!.options.isNotEmpty) ...[
                    const _Divider(),
                    _SectionHeader(label: l.diet, onSurface: onSurface, strict: opts.diet!.strict),
                    const SizedBox(height: 8),
                    _ChipGrid(
                      dimension: opts.diet!,
                      selected: diet,
                      onChanged: onDietChanged,
                      accent: cs.primary,
                    ),
                  ],
                  if (opts.maritalStatus != null && opts.maritalStatus!.options.isNotEmpty) ...[
                    const _Divider(),
                    _SectionHeader(
                      label: l.maritalStatus,
                      onSurface: onSurface,
                      strict: opts.maritalStatus!.strict,
                    ),
                    const SizedBox(height: 8),
                    _ChipGrid(
                      dimension: opts.maritalStatus!,
                      selected: maritalStatus,
                      onChanged: onMaritalStatusChanged,
                      accent: cs.primary,
                    ),
                  ],
                ],
              ],
            ),
          ),
          // Footer
          _Footer(onApply: onApply, brand: brand),
        ],
      ),
    );
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.label,
    required this.onSurface,
    this.strict = false,
  });

  final String label;
  final Color onSurface;
  final bool strict;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: AppTypography.titleSmall.copyWith(
            color: onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (strict) ...[
          const SizedBox(width: 8),
          _StrictBadge(),
        ],
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
        'From preferences',
        style: AppTypography.labelSmall.copyWith(
          color: Theme.of(context).colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Divider(
        height: 1,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
      ),
    );
  }
}

/// Sort option pills row
class _SortRow extends StatelessWidget {
  const _SortRow({
    required this.current,
    required this.onChanged,
    required this.brand,
  });

  final SortOption current;
  final void Function(SortOption) onChanged;
  final BrandTheme brand;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: SortOption.values.map((s) {
        final selected = s == current;
        return GestureDetector(
          onTap: () => onChanged(s),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              gradient: selected ? brand.accentGradient : null,
              color: selected ? null : cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(20),
              border: selected
                  ? null
                  : Border.all(
                      color: cs.onSurface.withValues(alpha: 0.12),
                    ),
            ),
            child: Text(
              s.label,
              style: AppTypography.labelMedium.copyWith(
                color: selected ? Colors.white : cs.onSurface.withValues(alpha: 0.75),
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _AgeSlider extends StatelessWidget {
  const _AgeSlider({
    required this.min,
    required this.max,
    required this.ageMin,
    required this.ageMax,
    required this.onChanged,
    required this.accent,
    required this.onSurface,
    required this.strict,
  });

  final int min;
  final int max;
  final int ageMin;
  final int ageMax;
  final void Function(int, int) onChanged;
  final Color accent;
  final Color onSurface;
  final bool strict;

  @override
  Widget build(BuildContext context) {
    if (strict) {
      return Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          '$ageMin – $ageMax years',
          style: AppTypography.bodyMedium.copyWith(
            color: onSurface.withValues(alpha: 0.8),
          ),
        ),
      );
    }
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _AgeLabel(value: ageMin, accent: accent),
            _AgeLabel(value: ageMax, accent: accent),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: accent,
            inactiveTrackColor: accent.withValues(alpha: 0.18),
            thumbColor: accent,
            overlayColor: accent.withValues(alpha: 0.1),
          ),
          child: RangeSlider(
            values: RangeValues(
              ageMin.toDouble().clamp(min.toDouble(), max.toDouble()),
              ageMax.toDouble().clamp(min.toDouble(), max.toDouble()),
            ),
            min: min.toDouble(),
            max: max.toDouble(),
            divisions: max - min,
            onChanged: (v) => onChanged(v.start.round(), v.end.round()),
          ),
        ),
      ],
    );
  }
}

class _AgeLabel extends StatelessWidget {
  const _AgeLabel({required this.value, required this.accent});

  final int value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: '$value',
            style: AppTypography.titleMedium.copyWith(
              color: accent,
              fontWeight: FontWeight.w700,
            ),
          ),
          TextSpan(
            text: ' yrs',
            style: AppTypography.bodySmall.copyWith(
              color: accent.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeightSlider extends StatelessWidget {
  const _HeightSlider({
    required this.heightMin,
    required this.heightMax,
    required this.onChanged,
    required this.accent,
    required this.onSurface,
  });

  final int heightMin;
  final int heightMax;
  final void Function(int, int) onChanged;
  final Color accent;
  final Color onSurface;

  static const int _minCm = 140;
  static const int _maxCm = 210;

  String _label(int cm) {
    final feet = (cm / 30.48).floor();
    final inches = ((cm / 2.54) - feet * 12).round();
    return "$cm cm ($feet'$inches\")";
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _label(heightMin),
              style: AppTypography.labelMedium.copyWith(
                color: accent,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              _label(heightMax),
              style: AppTypography.labelMedium.copyWith(
                color: accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: accent,
            inactiveTrackColor: accent.withValues(alpha: 0.18),
            thumbColor: accent,
            overlayColor: accent.withValues(alpha: 0.1),
          ),
          child: RangeSlider(
            values: RangeValues(
              heightMin.toDouble().clamp(_minCm.toDouble(), _maxCm.toDouble()),
              heightMax.toDouble().clamp(_minCm.toDouble(), _maxCm.toDouble()),
            ),
            min: _minCm.toDouble(),
            max: _maxCm.toDouble(),
            divisions: _maxCm - _minCm,
            onChanged: (v) => onChanged(v.start.round(), v.end.round()),
          ),
        ),
      ],
    );
  }
}

/// Chip grid showing options with optional user counts.
class _ChipGrid extends StatelessWidget {
  const _ChipGrid({
    required this.dimension,
    required this.selected,
    required this.onChanged,
    required this.accent,
  });

  final FilterDimension dimension;
  final String? selected;
  final void Function(String?) onChanged;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final options = dimension.options.where((o) => o.count > 0 || dimension.options.length <= 5).toList();
    if (options.isEmpty) {
      return const SizedBox.shrink();
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((opt) {
        final isSelected = selected == opt.value;
        final label = opt.count > 0
            ? '${opt.value} (${_formatCount(opt.count)})'
            : opt.value;
        return GestureDetector(
          onTap: dimension.strict
              ? null
              : () => onChanged(isSelected ? null : opt.value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: isSelected
                  ? accent
                  : cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? accent
                    : cs.onSurface.withValues(alpha: 0.1),
              ),
            ),
            child: Text(
              label,
              style: AppTypography.labelMedium.copyWith(
                color: isSelected
                    ? Colors.white
                    : cs.onSurface.withValues(
                        alpha: dimension.strict ? 0.5 : 0.85,
                      ),
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  static String _formatCount(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return '$n';
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.onApply, required this.brand});

  final VoidCallback onApply;
  final BrandTheme brand;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
          ),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: brand.accentGradient,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: brand.saffron.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onApply,
              borderRadius: BorderRadius.circular(14),
              child: Center(
                child: Text(
                  l.apply,
                  style: AppTypography.titleSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _VerifiedOnlyToggle extends StatelessWidget {
  const _VerifiedOnlyToggle({
    required this.value,
    required this.onChanged,
    required this.onSurface,
    required this.cs,
  });

  final bool value;
  final void Function(bool) onChanged;
  final Color onSurface;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: value
              ? const Color(0xFF1565C0).withValues(alpha: 0.1)
              : cs.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: value
                ? const Color(0xFF1565C0).withValues(alpha: 0.5)
                : onSurface.withValues(alpha: 0.1),
            width: value ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: value
                    ? const Color(0xFF1565C0).withValues(alpha: 0.12)
                    : onSurface.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.verified_rounded,
                size: 18,
                color: value ? const Color(0xFF1565C0) : onSurface.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Verified profiles only',
                    style: AppTypography.titleSmall.copyWith(
                      color: onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Show only ID or photo verified profiles',
                    style: AppTypography.bodySmall.copyWith(
                      color: onSurface.withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: const Color(0xFF1565C0),
            ),
          ],
        ),
      ),
    );
  }
}

class _IntentFilterChips extends StatelessWidget {
  const _IntentFilterChips({
    required this.selected,
    required this.onChanged,
    required this.accent,
  });

  final String? selected;
  final void Function(String?)? onChanged;
  final Color accent;

  static const _intents = [
    ('marriage', Icons.diamond_rounded, 'Marriage'),
    ('serious', Icons.favorite_rounded, 'Serious'),
    ('casual', Icons.coffee_rounded, 'Casual'),
    ('friends_first', Icons.waving_hand_rounded, 'Friends First'),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _intents.map(((String, IconData, String) entry) {
        final (key, icon, label) = entry;
        final isSelected = selected == key;
        return GestureDetector(
          onTap: () => onChanged?.call(isSelected ? null : key),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: isSelected ? accent : cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? accent : cs.outline.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon,
                    size: 14,
                    color: isSelected
                        ? Colors.white
                        : cs.onSurface.withValues(alpha: 0.6)),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: AppTypography.labelMedium.copyWith(
                    color: isSelected
                        ? Colors.white
                        : cs.onSurface.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w600,
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
