import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/mode/app_mode.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/app_localizations.dart';
import '../screens/profile_setup_screen.dart';

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
  RangeValues _ageRange = const RangeValues(22, 35);
  String? _prefReligion;
  String? _prefEducation;
  String? _prefMaritalStatus;
  String? _prefIncome;
  String? _prefDiet;
  String? _prefDrink;
  String? _prefSmoke;
  String? _prefMotherTongue;
  String? _prefSettledAbroad;
  String _prefCity = '';

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
              onChanged: (v) => setState(() => _ageRange = v),
            ),
          ),
          const SizedBox(height: 16),

          // Religion
          _PrefCard(
            icon: Icons.temple_hindu_outlined,
            title: l.religion,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                _ChipRow(
                  options: [l.anyOption, 'Hindu', 'Muslim', 'Christian', 'Sikh', 'Jain', 'Buddhist'],
                  selected: _prefReligion,
                  onSelected: (v) => setState(() => _prefReligion = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Mother tongue
          _PrefCard(
            icon: Icons.translate,
            title: l.prefMotherTongueQuestion,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                _ChipRow(
                  options: [l.anyOption, 'Hindi', 'Bengali', 'Telugu', 'Marathi', 'Tamil', 'Gujarati', 'Kannada', 'Malayalam', 'Punjabi'],
                  selected: _prefMotherTongue,
                  onSelected: (v) => setState(() => _prefMotherTongue = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Education
          _PrefCard(
            icon: Icons.school_outlined,
            title: l.educationLevel,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                _ChipRow(
                  options: [l.anyOption, 'Bachelors+', 'Masters+', 'MBA', 'Medical', 'Engineering', 'PhD'],
                  selected: _prefEducation,
                  onSelected: (v) => setState(() => _prefEducation = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Marital status
          _PrefCard(
            icon: Icons.person_outline,
            title: l.maritalStatus,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                _ChipRow(
                  options: [l.anyOption, l.neverMarried, l.divorced, l.widowed],
                  selected: _prefMaritalStatus,
                  onSelected: (v) => setState(() => _prefMaritalStatus = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Income
          _PrefCard(
            icon: Icons.account_balance_wallet_outlined,
            title: l.income,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                _ChipRow(
                  options: [l.anyOption, '3-5 LPA', '5-10 LPA', '10-20 LPA', '20-50 LPA', '50 LPA+'],
                  selected: _prefIncome,
                  onSelected: (v) => setState(() => _prefIncome = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Diet preference
          _PrefCard(
            icon: Icons.restaurant_outlined,
            title: l.prefDietQuestion,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                _ChipRow(
                  options: [l.anyOption, l.dietVeg, l.dietNonVeg, l.dietVegan, l.dietJain],
                  selected: _prefDiet,
                  onSelected: (v) => setState(() => _prefDiet = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Drinking pref
          _PrefCard(
            icon: Icons.local_bar_outlined,
            title: l.prefDrinkQuestion,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                _ChipRow(
                  options: [l.anyOption, l.drinkNever, l.drinkSocially],
                  selected: _prefDrink,
                  onSelected: (v) => setState(() => _prefDrink = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Smoking pref
          _PrefCard(
            icon: Icons.smoke_free,
            title: l.prefSmokeQuestion,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                _ChipRow(
                  options: [l.anyOption, l.smokeNever, l.smokeOccasionally],
                  selected: _prefSmoke,
                  onSelected: (v) => setState(() => _prefSmoke = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Settled abroad pref
          _PrefCard(
            icon: Icons.flight_outlined,
            title: l.prefSettledAbroadQuestion,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                _ChipRow(
                  options: [l.anyOption, l.settledAbroadYes, l.settledAbroadNo],
                  selected: _prefSettledAbroad,
                  onSelected: (v) => setState(() => _prefSettledAbroad = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // City pref
          _PrefCard(
            icon: Icons.location_city_outlined,
            title: l.prefCityQuestion,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                _SmartSingleLine(
                  value: _prefCity,
                  hint: l.prefCityHint,
                  onChanged: (v) => setState(() => _prefCity = v),
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

// ── Shared widgets ──────────────────────────────────────────────────────

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
      spacing: 8,
      runSpacing: 8,
      children: options.map((opt) {
        final isSelected = opt == selected;
        return GestureDetector(
          onTap: () => onSelected(opt),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? accent.withValues(alpha: 0.12) : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? accent : Theme.of(context).dividerColor,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Text(
              opt,
              style: AppTypography.bodySmall.copyWith(
                color: isSelected ? accent : onSurface.withValues(alpha: 0.7),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        );
      }).toList(),
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
