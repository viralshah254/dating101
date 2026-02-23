import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/mode/app_mode.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/app_localizations.dart';
import '../screens/profile_setup_screen.dart';

class StepDetails extends StatelessWidget {
  const StepDetails({
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
    if (mode.isDating) return _DatingDetails(formData: formData, onChanged: onChanged);
    return _MatrimonyDetails(formData: formData, onChanged: onChanged);
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
          const SizedBox(height: 28),

          _InterestSection(formData: formData, onChanged: onChanged),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ── Matrimony Details ───────────────────────────────────────────────────

class _MatrimonyDetails extends StatelessWidget {
  const _MatrimonyDetails({required this.formData, required this.onChanged});
  final ProfileFormData formData;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    final forSelf = formData.isForSelf;
    final subject = formData.subjectName;

    final pageTitle = forSelf ? 'Background\n& details' : l.dynDetailsTitle(subject);
    final pageSubtitle = forSelf
        ? 'These help us find compatible matches. Fill what you can — skip the rest.'
        : l.dynDetailsSubtitle(subject);
    final aboutTitle = forSelf ? l.profileBuilderAbout : l.dynAboutTitle(subject);
    final aboutHint = forSelf
        ? 'Write a few lines about yourself...'
        : l.dynAboutHint(subject);

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
          const SizedBox(height: 4),
          Text(
            pageSubtitle,
            style: AppTypography.bodyMedium.copyWith(
              color: onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 28),

          // Religion & Community
          _DetailCard(
            icon: Icons.temple_hindu_outlined,
            title: l.backgroundTitle,
            children: [
              _DropdownField(
                label: l.matrimonyReligionQuestion,
                value: formData.religion,
                items: const ['Hindu', 'Muslim', 'Christian', 'Sikh', 'Jain', 'Buddhist', 'Parsi', 'Jewish', 'Other'],
                onChanged: (v) { formData.religion = v; onChanged(); },
              ),
              const SizedBox(height: 16),
              _SmartTextField(
                label: l.matrimonyCommunityQuestion,
                value: formData.community ?? '',
                hint: 'e.g. Brahmin, Maratha, Reddy',
                onChanged: (v) { formData.community = v; onChanged(); },
              ),
              const SizedBox(height: 16),
              _DropdownField(
                label: l.matrimonyMotherTongueQuestion,
                value: formData.motherTongue,
                items: const ['Hindi', 'Bengali', 'Telugu', 'Marathi', 'Tamil', 'Urdu', 'Gujarati', 'Kannada', 'Malayalam', 'Punjabi', 'English', 'Other'],
                onChanged: (v) { formData.motherTongue = v; onChanged(); },
              ),
              const SizedBox(height: 16),
              _SmartTextField(
                label: l.languagesSpoken,
                value: formData.languagesSpoken ?? '',
                hint: l.languagesHint,
                onChanged: (v) { formData.languagesSpoken = v; onChanged(); },
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Education & Career
          _DetailCard(
            icon: Icons.school_outlined,
            title: l.careerTitle,
            children: [
              _DropdownField(
                label: l.matrimonyEducationQuestion,
                value: formData.education,
                items: const ['High School', 'Diploma', 'Bachelors', 'Masters', 'MBA', 'PhD', 'Medical (MBBS/MD)', 'Engineering (B.Tech/M.Tech)', 'CA/CFA', 'Law (LLB/LLM)', 'Other'],
                onChanged: (v) { formData.education = v; onChanged(); },
              ),
              const SizedBox(height: 16),
              _SmartTextField(
                label: l.matrimonyOccupationQuestion,
                value: formData.occupation ?? '',
                hint: 'e.g. Software Engineer, Doctor',
                onChanged: (v) { formData.occupation = v; onChanged(); },
              ),
              const SizedBox(height: 16),
              _SmartTextField(
                label: l.companyQuestion,
                value: formData.company ?? '',
                hint: l.companyHint,
                onChanged: (v) { formData.company = v; onChanged(); },
              ),
              const SizedBox(height: 16),
              _DropdownField(
                label: l.matrimonyIncomeQuestion,
                value: formData.income,
                items: const ['Not specified', 'Below 3 LPA', '3-5 LPA', '5-10 LPA', '10-20 LPA', '20-50 LPA', '50 LPA+', 'Abroad salary'],
                onChanged: (v) { formData.income = v; onChanged(); },
              ),
              const SizedBox(height: 16),
              _SmartTextField(
                label: l.workLocationQuestion,
                value: formData.workLocation ?? '',
                hint: l.workLocationHint,
                onChanged: (v) { formData.workLocation = v; onChanged(); },
              ),
              const SizedBox(height: 16),
              _SectionLabel(label: l.settledAbroadQuestion),
              const SizedBox(height: 8),
              _ChipRow(
                options: [l.settledAbroadYes, l.settledAbroadNo, l.settledAbroadPlanning],
                selected: formData.settledAbroad,
                onSelected: (v) { formData.settledAbroad = v; onChanged(); },
              ),
              const SizedBox(height: 16),
              _SectionLabel(label: l.willingToRelocate),
              const SizedBox(height: 8),
              _ChipRow(
                options: [l.relocateYes, l.relocateNo, l.relocateMaybe],
                selected: formData.willingToRelocate,
                onSelected: (v) { formData.willingToRelocate = v; onChanged(); },
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Lifestyle
          _LifestyleSection(formData: formData, onChanged: onChanged),

          const SizedBox(height: 16),

          // Family
          _DetailCard(
            icon: Icons.family_restroom_outlined,
            title: l.profileBuilderFamily,
            children: [
              _SectionLabel(label: l.matrimonyFamilyTypeQuestion),
              const SizedBox(height: 8),
              _ChipRow(
                options: [l.nuclear, l.joint],
                selected: formData.familyType,
                onSelected: (v) { formData.familyType = v; onChanged(); },
              ),
              const SizedBox(height: 16),
              _SectionLabel(label: l.matrimonyFamilyValuesQuestion),
              const SizedBox(height: 8),
              _ChipRow(
                options: [l.traditional, l.moderate, l.liberal],
                selected: formData.familyValues,
                onSelected: (v) { formData.familyValues = v; onChanged(); },
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Horoscope
          _DetailCard(
            icon: Icons.auto_awesome_outlined,
            title: l.horoscopeQuestion,
            children: [
              _SectionLabel(label: l.manglikQuestion),
              const SizedBox(height: 8),
              _ChipRow(
                options: [l.manglikYes, l.manglikNo, l.manglikPartial, l.manglikDontKnow],
                selected: formData.manglik,
                onSelected: (v) { formData.manglik = v; onChanged(); },
              ),
              const SizedBox(height: 16),
              _DropdownField(
                label: l.rashiQuestion,
                value: formData.rashi,
                items: const ['Mesh (Aries)', 'Vrishabh (Taurus)', 'Mithun (Gemini)', 'Kark (Cancer)', 'Simha (Leo)', 'Kanya (Virgo)', 'Tula (Libra)', 'Vrishchik (Scorpio)', 'Dhanu (Sagittarius)', 'Makar (Capricorn)', 'Kumbh (Aquarius)', 'Meen (Pisces)', 'Don\'t know'],
                onChanged: (v) { formData.rashi = v; onChanged(); },
              ),
              const SizedBox(height: 16),
              _DropdownField(
                label: l.nakshatraQuestion,
                value: formData.nakshatra,
                items: const ['Ashwini', 'Bharani', 'Krittika', 'Rohini', 'Mrigashira', 'Ardra', 'Punarvasu', 'Pushya', 'Ashlesha', 'Magha', 'Purva Phalguni', 'Uttara Phalguni', 'Hasta', 'Chitra', 'Swati', 'Vishakha', 'Anuradha', 'Jyeshtha', 'Moola', 'Purva Ashadha', 'Uttara Ashadha', 'Shravana', 'Dhanishta', 'Shatabhisha', 'Purva Bhadrapada', 'Uttara Bhadrapada', 'Revati', 'Don\'t know'],
                onChanged: (v) { formData.nakshatra = v; onChanged(); },
              ),
              const SizedBox(height: 16),
              _SmartTextField(
                label: l.gotraQuestion,
                value: formData.gotra ?? '',
                hint: l.gotraHint,
                onChanged: (v) { formData.gotra = v; onChanged(); },
              ),
            ],
          ),

          const SizedBox(height: 16),

          // About / Bio
          _DetailCard(
            icon: Icons.edit_note,
            title: aboutTitle,
            children: [
              _MultilineField(
                value: formData.bio,
                hint: aboutHint,
                onChanged: (v) { formData.bio = v; onChanged(); },
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Interests
          _InterestSection(formData: formData, onChanged: onChanged),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ── Shared building blocks ──────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTypography.labelLarge.copyWith(
        color: Theme.of(context).colorScheme.onSurface,
        fontWeight: FontWeight.w600,
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
              Icon(icon, size: 20, color: onSurface.withValues(alpha: 0.5)),
              const SizedBox(width: 8),
              Text(
                title,
                style: AppTypography.titleMedium.copyWith(
                  color: onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
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
        Text(label, style: AppTypography.labelMedium.copyWith(color: onSurface.withValues(alpha: 0.7))),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: value,
          isExpanded: true,
          dropdownColor: surface,
          style: TextStyle(color: onSurface, fontSize: 14, fontWeight: FontWeight.w400),
          decoration: InputDecoration(
            filled: true,
            fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Theme.of(context).dividerColor)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          items: items.map((e) => DropdownMenuItem(
            value: e,
            child: Text(e, style: TextStyle(color: onSurface, fontSize: 14)),
          )).toList(),
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
        Text(widget.label, style: AppTypography.labelMedium.copyWith(color: onSurface.withValues(alpha: 0.7))),
        const SizedBox(height: 6),
        TextField(
          controller: _ctrl,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            hintText: widget.hint,
            filled: true,
            fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
      spacing: 8,
      runSpacing: 8,
      children: options.map((opt) {
        final isSelected = opt == selected;
        return GestureDetector(
          onTap: () => onSelected(opt),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? accent.withValues(alpha: 0.12) : Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? accent : Theme.of(context).dividerColor,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Text(
              opt,
              style: AppTypography.bodySmall.copyWith(
                color: isSelected ? accent : onSurface,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
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
              color: isSelected ? accent.withValues(alpha: 0.12) : Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? accent : Theme.of(context).dividerColor,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(opt.icon, size: 20, color: isSelected ? accent : onSurface.withValues(alpha: 0.4)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    opt.label,
                    style: AppTypography.bodySmall.copyWith(
                      color: isSelected ? accent : onSurface,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
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
            options: [l.dietVeg, l.dietNonVeg, l.dietEggetarian, l.dietVegan, l.dietJain, l.dietFlexible],
            selected: formData.diet,
            onSelected: (v) { formData.diet = v; onChanged(); },
          ),
          _divider(context),

          _LifestyleRow(
            icon: Icons.local_bar_outlined,
            label: l.drinkQuestion,
            options: [l.drinkNever, l.drinkSocially, l.drinkRegularly],
            selected: formData.drinking,
            onSelected: (v) { formData.drinking = v; onChanged(); },
          ),
          _divider(context),

          _LifestyleRow(
            icon: Icons.smoke_free,
            label: l.smokeQuestion,
            options: [l.smokeNever, l.smokeOccasionally, l.smokeRegularly],
            selected: formData.smoking,
            onSelected: (v) { formData.smoking = v; onChanged(); },
          ),
          _divider(context),

          _LifestyleRow(
            icon: Icons.fitness_center_outlined,
            label: l.exerciseQuestion,
            options: [l.exerciseDaily, l.exerciseRegularly, l.exerciseSometimes, l.exerciseRarely],
            selected: formData.exercise,
            onSelected: (v) { formData.exercise = v; onChanged(); },
          ),
        ],
      ),
    );
  }

  Widget _divider(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Divider(height: 1, color: Theme.of(context).dividerColor.withValues(alpha: 0.5)),
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
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: isSelected ? accent.withValues(alpha: 0.12) : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? accent : onSurface.withValues(alpha: 0.15),
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
        ),
      ],
    );
  }
}

// ── Interest Section with Search ────────────────────────────────────────

class _InterestSection extends StatefulWidget {
  const _InterestSection({required this.formData, required this.onChanged});
  final ProfileFormData formData;
  final VoidCallback onChanged;

  @override
  State<_InterestSection> createState() => _InterestSectionState();
}

class _InterestSectionState extends State<_InterestSection> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  static const _categories = <String, List<String>>{
    'Active': ['Fitness', 'Yoga', 'Cricket', 'Dancing', 'Swimming', 'Running', 'Gym', 'Hiking', 'Badminton', 'Football', 'Tennis'],
    'Creative': ['Arts', 'Music', 'Photography', 'Writing', 'Painting', 'Singing', 'Design', 'Crafting', 'Poetry'],
    'Social': ['Dining out', 'Volunteering', 'Networking', 'Parties', 'Clubbing', 'Theatre', 'Stand-up comedy'],
    'Chill': ['Coffee', 'Reading', 'Movies', 'Gaming', 'Meditation', 'Netflix', 'Podcasts', 'Board games'],
    'Food & Drink': ['Foodie', 'Cooking', 'Baking', 'Wine', 'Street food', 'Chai', 'Biryani', 'Vegan cooking'],
    'Outdoors': ['Travel', 'Outdoors', 'Camping', 'Trekking', 'Road trips', 'Beaches', 'Mountains', 'Cycling'],
    'Lifestyle': ['Pets', 'Gardening', 'Tech', 'Fashion', 'Astrology', 'Spirituality', 'Investing', 'Cars'],
  };

  List<String> get _allInterests => _categories.values.expand((v) => v).toList();

  List<String> get _filtered {
    if (_query.isEmpty) return _allInterests;
    final q = _query.toLowerCase();
    return _allInterests.where((t) => t.toLowerCase().contains(q)).toList();
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
    final selected = widget.formData.selectedInterests;
    final l = AppLocalizations.of(context)!;

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
              Icon(Icons.interests_outlined, size: 20, color: accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l.interests,
                  style: AppTypography.titleMedium.copyWith(
                    color: onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (selected.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${selected.length} selected',
                    style: AppTypography.labelSmall.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Pick what you enjoy. Helps with better matches.',
            style: AppTypography.bodySmall.copyWith(
              color: onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 14),

          TextField(
            controller: _searchCtrl,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search interests...',
              prefixIcon: Icon(Icons.search, size: 20, color: onSurface.withValues(alpha: 0.4)),
              suffixIcon: _query.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.close, size: 18, color: onSurface.withValues(alpha: 0.4)),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _query = '');
                      },
                    )
                  : null,
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              isDense: true,
            ),
            onChanged: (v) => setState(() => _query = v),
          ),
          const SizedBox(height: 16),

          if (selected.isNotEmpty && _query.isEmpty) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: selected.map((tag) => _buildChip(context, tag, true)).toList(),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1, color: Theme.of(context).dividerColor.withValues(alpha: 0.5)),
            ),
          ],

          if (_query.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _filtered.map((tag) => _buildChip(context, tag, selected.contains(tag))).toList(),
            )
          else
            ..._categories.entries.map((entry) {
              final unselected = entry.value.where((t) => !selected.contains(t)).toList();
              if (unselected.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.key,
                      style: AppTypography.labelSmall.copyWith(
                        color: onSurface.withValues(alpha: 0.4),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: unselected.map((tag) => _buildChip(context, tag, false)).toList(),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildChip(BuildContext context, String tag, bool isSelected) {
    final accent = Theme.of(context).colorScheme.primary;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return GestureDetector(
      onTap: () {
        final next = List<String>.from(widget.formData.selectedInterests);
        if (isSelected) { next.remove(tag); } else { next.add(tag); }
        widget.formData.selectedInterests = next;
        widget.onChanged();
        setState(() {});
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? accent.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? accent : onSurface.withValues(alpha: 0.15),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              Icon(Icons.check, size: 14, color: accent),
              const SizedBox(width: 4),
            ],
            Text(
              tag,
              style: AppTypography.bodySmall.copyWith(
                color: isSelected ? accent : onSurface.withValues(alpha: 0.7),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
