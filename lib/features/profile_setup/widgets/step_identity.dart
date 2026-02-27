import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/location/place_search_service.dart';
import '../../../core/mode/app_mode.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/app_localizations.dart';
import '../screens/profile_setup_screen.dart';

/// Convert normalized stored value ("Woman", "Man", "Any") to display label.
String? _genderPrefToDisplay(String? stored, AppMode mode, AppLocalizations l) {
  if (stored == null) return null;
  if (mode.isDating) {
    switch (stored) {
      case 'Woman':
        return l.interestedInWomen;
      case 'Man':
        return l.interestedInMen;
      case 'Any':
        return l.interestedInEveryone;
    }
  } else {
    switch (stored) {
      case 'Woman':
        return l.lookingForBride;
      case 'Man':
        return l.lookingForGroom;
    }
  }
  return stored;
}

/// Convert display label back to normalized stored value.
String _displayToGenderPref(String display, AppLocalizations l) {
  if (display == l.lookingForBride || display == l.interestedInWomen) {
    return 'Woman';
  }
  if (display == l.lookingForGroom || display == l.interestedInMen) {
    return 'Man';
  }
  if (display == l.interestedInEveryone) {
    return 'Any';
  }
  return display;
}

/// When non-null, only that part of the identity step is shown (for section-only edit screens).
enum StepIdentityOnlySection { basic, physical }

class StepIdentity extends StatelessWidget {
  const StepIdentity({
    super.key,
    required this.mode,
    required this.formData,
    required this.onChanged,
    this.isEditing = false,
    this.onlySection,
  });

  final AppMode mode;
  final ProfileFormData formData;
  final VoidCallback onChanged;
  final bool isEditing;

  /// When set, only that section is shown (for dedicated section edit screen).
  final StepIdentityOnlySection? onlySection;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final accent = Theme.of(context).colorScheme.primary;

    final forSelf = formData.isForSelf;
    final subject = formData.subjectName;

    if (onlySection == StepIdentityOnlySection.physical) {
      return SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.physicalTitle,
              style: AppTypography.displayLarge.copyWith(
                color: onSurface,
                fontSize: 28,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Update your physical attributes.',
              style: AppTypography.bodyMedium.copyWith(
                color: onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            _PhysicalSection(
              mode: mode,
              formData: formData,
              onChanged: onChanged,
              accent: accent,
            ),
            const SizedBox(height: 40),
          ],
        ),
      );
    }

    final isBasicOnly = onlySection == StepIdentityOnlySection.basic;
    final title = isBasicOnly && isEditing
        ? 'Your details'
        : (isEditing
              ? 'Edit your profile'
              : (forSelf ? l.profileSetupTitle : l.dynSetupTitle(subject)));
    final subtitle = isBasicOnly && isEditing
        ? 'Name and date of birth cannot be changed after setup.'
        : (isEditing
              ? 'Update your details. Some fields cannot be changed.'
              : (forSelf
                    ? l.profileSetupSubtitle
                    : l.dynSetupSubtitle(subject)));
    final nameLabel = forSelf ? l.yourName : l.dynName(subject);
    final genderLabel = forSelf ? l.genderQuestion : l.dynGender(subject);
    final dobLabel = forSelf ? l.dateOfBirth : l.dynDob(subject);
    final locationLabel = forSelf ? l.currentLocation : l.dynLocation(subject);
    final hometownLabel = forSelf ? l.hometown : l.dynHometown(subject);

    String nameHint;
    if (forSelf) {
      nameHint = l.nameHint;
    } else if (formData.creatingFor == 'son' ||
        formData.creatingFor == 'brother') {
      nameHint = l.dynNameHintSon;
    } else if (formData.creatingFor == 'daughter' ||
        formData.creatingFor == 'sister') {
      nameHint = l.dynNameHintDaughter;
    } else {
      nameHint = l.dynNameHintGeneric;
    }

    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.displayLarge.copyWith(
              color: onSurface,
              fontSize: isBasicOnly && isEditing ? 26 : 32,
              height: 1.2,
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.08, end: 0),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: AppTypography.bodyMedium.copyWith(
              color: onSurface.withValues(alpha: 0.65),
              height: 1.4,
            ),
          ).animate().fadeIn(delay: 100.ms),
          SizedBox(height: isBasicOnly && isEditing ? 28 : 32),

          // ── Creating for (matrimony only, first-time setup only) ──
          if (mode.isMatrimony && !isEditing) ...[
            _SectionLabel(label: l.profileCreatingFor),
            const SizedBox(height: 12),
            _CreatingForSelector(formData: formData, onChanged: onChanged),
            const SizedBox(height: 28),
          ],

          // ── Name (locked in edit mode) ────────────────────────
          _SectionLabel(label: nameLabel, mandatory: !isEditing),
          const SizedBox(height: 8),
          _StyledTextField(
            value: formData.name,
            hint: nameHint,
            textInputAction: TextInputAction.next,
            readOnly: isEditing,
            onChanged: isEditing
                ? null
                : (v) {
                    formData.name = ProfileFormData.toTitleCase(v);
                    onChanged();
                  },
          ),
          if (isEditing) ...[
            const SizedBox(height: 4),
            Text(
              'Name cannot be changed after setup',
              style: AppTypography.bodySmall.copyWith(
                color: onSurface.withValues(alpha: 0.4),
                fontSize: 11,
              ),
            ),
          ],
          if (!isEditing &&
              formData.name.trim().isNotEmpty &&
              !ProfileFormData.isNameValid(formData.name)) ...[
            const SizedBox(height: 6),
            Text(
              l.nameValidationHint,
              style: AppTypography.bodySmall.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
          const SizedBox(height: 24),

          // ── About me (first page, after name) ────────────────────
          _SectionLabel(
            label: forSelf ? l.profileBuilderAbout : l.dynAboutTitle(subject),
          ),
          const SizedBox(height: 8),
          _StyledMultilineField(
            value: formData.bio,
            hint: forSelf
                ? 'Write a few lines about yourself...'
                : l.dynAboutHint(subject),
            onChanged: (v) {
              formData.bio = v;
              onChanged();
            },
          ),
          const SizedBox(height: 24),

          // ── Gender (locked in edit mode) ────────────────────────
          _SectionLabel(label: genderLabel, mandatory: !isEditing),
          const SizedBox(height: 10),
          IgnorePointer(
            ignoring: isEditing,
            child: Opacity(
              opacity: isEditing ? 0.6 : 1.0,
              child: _ChipSelector(
                options: [l.genderWoman, l.genderMan, l.genderNonBinary],
                selected: formData.gender,
                onSelected: (v) {
                  formData.gender = v;
                  if (v == l.genderMan && formData.interestedIn == null) {
                    formData.interestedIn = 'Woman';
                  } else if (v == l.genderWoman &&
                      formData.interestedIn == null) {
                    formData.interestedIn = 'Man';
                  }
                  onChanged();
                },
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ── Partner gender preference ───────────────────────────
          _SectionLabel(
            label: mode.isDating ? l.interestedIn : l.lookingForPartner,
          ),
          const SizedBox(height: 10),
          _ChipSelector(
            options: mode.isDating
                ? [
                    l.interestedInWomen,
                    l.interestedInMen,
                    l.interestedInEveryone,
                  ]
                : [l.lookingForBride, l.lookingForGroom],
            selected: _genderPrefToDisplay(formData.interestedIn, mode, l),
            onSelected: (v) {
              formData.interestedIn = _displayToGenderPref(v, l);
              onChanged();
            },
          ),
          const SizedBox(height: 24),

          // ── Date of birth (locked in edit mode) ──────────────────
          _SectionLabel(label: dobLabel, mandatory: !isEditing),
          const SizedBox(height: 10),
          IgnorePointer(
            ignoring: isEditing,
            child: Opacity(
              opacity: isEditing ? 0.6 : 1.0,
              child: _DateOfBirthPicker(
                value: formData.dateOfBirth,
                onChanged: (d) {
                  formData.dateOfBirth = d;
                  // Picker only allows dates 18+ years ago; auto-check confirmation.
                  if (ProfileFormData.isAtLeast18(d)) {
                    formData.confirmedAge18 = true;
                  }
                  onChanged();
                },
              ),
            ),
          ),
          if (isEditing && formData.dateOfBirth != null) ...[
            const SizedBox(height: 4),
            Text(
              'Date of birth cannot be changed',
              style: AppTypography.bodySmall.copyWith(
                color: onSurface.withValues(alpha: 0.4),
                fontSize: 11,
              ),
            ),
          ],
          if (!isEditing &&
              formData.dateOfBirth != null &&
              !ProfileFormData.isAtLeast18(formData.dateOfBirth)) ...[
            const SizedBox(height: 6),
            Text(
              l.dobMustBe18,
              style: AppTypography.bodySmall.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
          if (!isEditing) ...[
            const SizedBox(height: 16),
            _ConfirmAge18Checkbox(formData: formData, onChanged: onChanged),
          ],
          const SizedBox(height: 24),

          // ── Location (searchable from place API) ─────────────────────
          _SectionLabel(label: locationLabel),
          const SizedBox(height: 10),
          _IdentityPlaceSearchField(
            label: locationLabel,
            value: formData.location,
            hint: l.currentLocationHint,
            icon: Icons.location_on_outlined,
            onSelected: (s) {
              final city = s.city ?? s.displayName.split(',').first.trim();
              formData.location = s.country.isNotEmpty
                  ? '$city, ${s.country}'
                  : city;
              onChanged();
            },
          ),

          if (mode.isMatrimony) ...[
            const SizedBox(height: 28),
            _SectionLabel(label: hometownLabel),
            const SizedBox(height: 10),
            _IdentityPlaceSearchField(
              label: hometownLabel,
              value: formData.hometown,
              hint: l.placeOfBirthHint,
              icon: Icons.home_outlined,
              onSelected: (s) {
                final city = s.city ?? s.displayName.split(',').first.trim();
                formData.hometown = s.country.isNotEmpty
                    ? '$city, ${s.country}'
                    : city;
                onChanged();
              },
            ),
          ],

          const SizedBox(height: 28),

          // ── Physical & Personal section (omit when only basic) ─────
          if (onlySection != StepIdentityOnlySection.basic)
            _PhysicalSection(
              mode: mode,
              formData: formData,
              onChanged: onChanged,
              accent: accent,
            ),
          if (onlySection != StepIdentityOnlySection.basic)
            const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ── Physical only (height, body type, complexion, disability; marital is in Religion & Community) ──

class _PhysicalSection extends StatelessWidget {
  const _PhysicalSection({
    required this.mode,
    required this.formData,
    required this.onChanged,
    required this.accent,
  });

  final AppMode mode;
  final ProfileFormData formData;
  final VoidCallback onChanged;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
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
              Icon(Icons.accessibility_new_outlined, size: 22, color: accent),
              const SizedBox(width: 10),
              Text(
                l.physicalTitle,
                style: AppTypography.titleMedium.copyWith(
                  color: onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              _OptionalBadge(),
            ],
          ),
          const SizedBox(height: 20),

          // Height picker
          _SectionLabel(label: l.heightQuestion),
          const SizedBox(height: 10),
          _HeightPicker(
            value: formData.heightCm,
            onChanged: (v) {
              formData.heightCm = v;
              onChanged();
            },
          ),
          const SizedBox(height: 24),

          // Body type
          _SectionLabel(label: l.bodyTypeQuestion),
          const SizedBox(height: 10),
          _ChipSelector(
            options: [
              l.bodyTypeSlim,
              l.bodyTypeAthletic,
              l.bodyTypeAverage,
              l.bodyTypeHeavy,
              l.bodyTypeCurvy,
            ],
            selected: formData.bodyType,
            onSelected: (v) {
              formData.bodyType = v;
              onChanged();
            },
          ),

          if (mode.isMatrimony) ...[
            const SizedBox(height: 24),

            // Complexion
            _SectionLabel(label: l.complexionQuestion),
            const SizedBox(height: 10),
            _ChipSelector(
              options: [
                l.complexionFair,
                l.complexionWheatish,
                l.complexionDark,
                l.complexionPreferNot,
              ],
              selected: formData.complexion,
              onSelected: (v) {
                formData.complexion = v;
                onChanged();
              },
            ),
          ],

          if (mode.isMatrimony) ...[
            const SizedBox(height: 20),

            // Disability
            _SectionLabel(label: l.disabilityQuestion),
            const SizedBox(height: 10),
            _ChipSelector(
              options: [
                l.disabilityNone,
                l.disabilityPhysical,
                l.disabilityPreferNot,
              ],
              selected: formData.disability,
              onSelected: (v) {
                formData.disability = v;
                onChanged();
              },
            ),
          ],
        ],
      ),
    );
  }
}

// ── Height Picker (ft/in + cm display) ──────────────────────────────────

class _HeightPicker extends StatefulWidget {
  const _HeightPicker({required this.value, required this.onChanged});
  final String? value;
  final ValueChanged<String> onChanged;

  @override
  State<_HeightPicker> createState() => _HeightPickerState();
}

class _HeightPickerState extends State<_HeightPicker> {
  int _feet = 5;
  int _inches = 6;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized && widget.value != null && widget.value!.isNotEmpty) {
      final cm = int.tryParse(widget.value!);
      if (cm != null) {
        final totalInches = (cm / 2.54).round();
        _feet = totalInches ~/ 12;
        _inches = totalInches % 12;
      }
      _initialized = true;
    }
  }

  int get _totalCm => ((_feet * 12 + _inches) * 2.54).round();

  void _showPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final l = AppLocalizations.of(ctx)!;
        int tmpFeet = _feet;
        int tmpInches = _inches;
        return StatefulBuilder(
          builder: (ctx, setBS) {
            final cm = ((tmpFeet * 12 + tmpInches) * 2.54).round();
            return Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(ctx).dividerColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '$tmpFeet\' $tmpInches" — $cm cm',
                    style: AppTypography.titleLarge.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _WheelColumn(
                        label: l.feetUnit,
                        min: 4,
                        max: 7,
                        value: tmpFeet,
                        onChanged: (v) => setBS(() => tmpFeet = v),
                      ),
                      const SizedBox(width: 32),
                      _WheelColumn(
                        label: l.inchesUnit,
                        min: 0,
                        max: 11,
                        value: tmpInches,
                        onChanged: (v) => setBS(() => tmpInches = v),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton(
                      onPressed: () {
                        setState(() {
                          _feet = tmpFeet;
                          _inches = tmpInches;
                        });
                        widget.onChanged('$_totalCm');
                        Navigator.pop(ctx);
                      },
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        l.confirm,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final accent = Theme.of(context).colorScheme.primary;
    final hasValue = widget.value != null && widget.value!.isNotEmpty;

    return GestureDetector(
      onTap: _showPicker,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Row(
          children: [
            Icon(
              Icons.straighten,
              size: 20,
              color: onSurface.withValues(alpha: 0.5),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                hasValue
                    ? '$_feet\' $_inches" — $_totalCm cm'
                    : 'Tap to select height',
                style: AppTypography.bodyLarge.copyWith(
                  color: hasValue
                      ? onSurface
                      : onSurface.withValues(alpha: 0.4),
                ),
              ),
            ),
            Icon(
              Icons.unfold_more,
              size: 20,
              color: accent.withValues(alpha: 0.6),
            ),
          ],
        ),
      ),
    );
  }
}

class _WheelColumn extends StatelessWidget {
  const _WheelColumn({
    required this.label,
    required this.min,
    required this.max,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final int min;
  final int max;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final items = List.generate(max - min + 1, (i) => min + i);

    return Column(
      children: [
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: onSurface.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 160,
          width: 64,
          child: ListWheelScrollView.useDelegate(
            itemExtent: 40,
            diameterRatio: 1.5,
            physics: const FixedExtentScrollPhysics(),
            controller: FixedExtentScrollController(initialItem: value - min),
            onSelectedItemChanged: (i) => onChanged(min + i),
            childDelegate: ListWheelChildBuilderDelegate(
              childCount: items.length,
              builder: (ctx, i) {
                final isSelected = items[i] == value;
                return Center(
                  child: Text(
                    '${items[i]}',
                    style: TextStyle(
                      fontSize: isSelected ? 24 : 18,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w400,
                      color: isSelected
                          ? accent
                          : onSurface.withValues(alpha: 0.35),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

// ── Shared widgets ──────────────────────────────────────────────────────

class _OptionalBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        l.optional,
        style: AppTypography.labelSmall.copyWith(
          color: Theme.of(
            context,
          ).colorScheme.onSurface.withValues(alpha: 0.45),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, this.mandatory = false});
  final String label;
  final bool mandatory;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Row(
      children: [
        Text(
          label,
          style: AppTypography.titleSmall.copyWith(
            color: onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (mandatory) ...[
          const SizedBox(width: 4),
          Text(
            '*',
            style: TextStyle(
              color: Colors.red.shade400,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );
  }
}

class _StyledTextField extends StatefulWidget {
  const _StyledTextField({
    required this.value,
    required this.hint,
    this.onChanged,
    this.textInputAction = TextInputAction.done,
    this.readOnly = false,
  });

  final String value;
  final String hint;
  final ValueChanged<String>? onChanged;
  final TextInputAction textInputAction;
  final bool readOnly;

  @override
  State<_StyledTextField> createState() => _StyledTextFieldState();
}

class _StyledTextFieldState extends State<_StyledTextField> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(_StyledTextField old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value && widget.value != _ctrl.text) {
      _ctrl.text = widget.value;
      _ctrl.selection = TextSelection.collapsed(offset: widget.value.length);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final onSurface = cs.onSurface;
    return TextField(
      controller: _ctrl,
      textInputAction: widget.textInputAction,
      readOnly: widget.readOnly,
      enabled: !widget.readOnly,
      style: AppTypography.bodyLarge.copyWith(color: onSurface),
      decoration: InputDecoration(
        hintText: widget.hint,
        hintStyle: AppTypography.bodyLarge.copyWith(
          color: onSurface.withValues(alpha: 0.4),
        ),
        prefixIcon: null,
        prefixIconConstraints: const BoxConstraints(
          minWidth: 52,
          minHeight: 24,
        ),
        filled: true,
        fillColor: widget.readOnly
            ? cs.surfaceContainerHighest.withValues(alpha: 0.6)
            : cs.surfaceContainerHighest,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: cs.outlineVariant.withValues(alpha: 0.6),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: cs.primary, width: 1.5),
        ),
      ),
      onChanged: widget.onChanged,
    );
  }
}

class _StyledMultilineField extends StatefulWidget {
  const _StyledMultilineField({
    required this.value,
    required this.hint,
    required this.onChanged,
  });

  final String value;
  final String hint;
  final ValueChanged<String> onChanged;

  @override
  State<_StyledMultilineField> createState() => _StyledMultilineFieldState();
}

class _StyledMultilineFieldState extends State<_StyledMultilineField> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(_StyledMultilineField old) {
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
    final cs = Theme.of(context).colorScheme;
    final onSurface = cs.onSurface;
    return TextField(
      controller: _ctrl,
      maxLines: 4,
      textInputAction: TextInputAction.newline,
      style: AppTypography.bodyLarge.copyWith(color: onSurface),
      decoration: InputDecoration(
        hintText: widget.hint,
        hintStyle: AppTypography.bodyLarge.copyWith(
          color: onSurface.withValues(alpha: 0.4),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: cs.outlineVariant.withValues(alpha: 0.6),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: cs.primary, width: 1.5),
        ),
        filled: true,
        fillColor: cs.surfaceContainerHighest,
        contentPadding: const EdgeInsets.all(18),
      ),
      onChanged: widget.onChanged,
    );
  }
}

class _ChipSelector extends StatelessWidget {
  const _ChipSelector({
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

class _ConfirmAge18Checkbox extends StatelessWidget {
  const _ConfirmAge18Checkbox({
    required this.formData,
    required this.onChanged,
  });

  final ProfileFormData formData;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final forSelf = formData.isForSelf;
    final label = forSelf ? l.confirmAge18Self : l.confirmAge18Other;
    final accent = Theme.of(context).colorScheme.primary;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return InkWell(
      onTap: () {
        formData.confirmedAge18 = !formData.confirmedAge18;
        onChanged();
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: formData.confirmedAge18,
                onChanged: (v) {
                  formData.confirmedAge18 = v ?? false;
                  onChanged();
                },
                activeColor: accent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: AppTypography.bodyMedium.copyWith(color: onSurface),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateOfBirthPicker extends StatelessWidget {
  const _DateOfBirthPicker({required this.value, required this.onChanged});

  final DateTime? value;
  final ValueChanged<DateTime> onChanged;

  static DateTime get _today => DateTime.now();
  static DateTime get _maxDate =>
      DateTime(_today.year - 18, _today.month, _today.day);

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final displayText = value != null
        ? '${value!.day.toString().padLeft(2, '0')} / ${value!.month.toString().padLeft(2, '0')} / ${value!.year}'
        : 'DD / MM / YYYY';

    final cs = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          final picked = await _showEfficientDatePicker(
            context: context,
            initial: value ?? DateTime(_today.year - 25, 1, 1),
            lastDate: _maxDate,
          );
          if (picked != null) onChanged(picked);
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.6)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 22,
                color: onSurface.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  displayText,
                  style: AppTypography.bodyLarge.copyWith(
                    color: value != null
                        ? onSurface
                        : onSurface.withValues(alpha: 0.45),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Uses the platform calendar date picker for a clearer, more intuitive experience.
  static Future<DateTime?> _showEfficientDatePicker({
    required BuildContext context,
    required DateTime initial,
    required DateTime lastDate,
  }) {
    final firstDate = DateTime(1950, 1, 1);
    final initialDate = DateTime(
      initial.year.clamp(firstDate.year, lastDate.year),
      initial.month.clamp(1, 12),
      initial.day.clamp(1, DateTime(initial.year, initial.month + 1, 0).day),
    );
    return showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: AppLocalizations.of(context)!.selectDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Theme.of(context).colorScheme.primary,
              surface: Theme.of(context).colorScheme.surface,
            ),
          ),
          child: child!,
        );
      },
    );
  }
}

class _CreatingForSelector extends StatelessWidget {
  const _CreatingForSelector({required this.formData, required this.onChanged});

  final ProfileFormData formData;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final accent = Theme.of(context).colorScheme.primary;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    final options = [
      _RoleOption(l.profileCreatingForSelf, Icons.person, null),
      _RoleOption(l.profileCreatingForSon, Icons.boy, 'son'),
      _RoleOption(l.profileCreatingForDaughter, Icons.girl, 'daughter'),
      _RoleOption(l.profileCreatingForBrother, Icons.person_outline, 'brother'),
      _RoleOption(l.profileCreatingForSister, Icons.person_outline, 'sister'),
      _RoleOption(l.profileCreatingForFriend, Icons.people_outline, 'friend'),
      _RoleOption(
        l.profileCreatingForRelative,
        Icons.family_restroom,
        'relative',
      ),
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: options.map((opt) {
        final isSelected = formData.creatingFor == opt.value;
        return GestureDetector(
          onTap: () {
            formData.creatingFor = opt.value;
            // Auto-set gender + interested-in based on relationship
            switch (opt.value) {
              case 'son':
              case 'brother':
                formData.gender = l.genderMan;
                formData.interestedIn = 'Woman';
              case 'daughter':
              case 'sister':
                formData.gender = l.genderWoman;
                formData.interestedIn = 'Man';
              default:
                break;
            }
            onChanged();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? accent.withValues(alpha: 0.12)
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? accent : Theme.of(context).dividerColor,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  opt.icon,
                  size: 18,
                  color: isSelected ? accent : onSurface.withValues(alpha: 0.5),
                ),
                const SizedBox(width: 6),
                Text(
                  opt.label,
                  style: AppTypography.bodySmall.copyWith(
                    color: isSelected ? accent : onSurface,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
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

/// Searchable place field for "Where do you live?" and "Where were you born?" (API-backed).
class _IdentityPlaceSearchField extends StatefulWidget {
  const _IdentityPlaceSearchField({
    required this.label,
    required this.value,
    required this.hint,
    required this.icon,
    required this.onSelected,
  });

  final String label;
  final String value;
  final String hint;
  final IconData icon;
  final void Function(PlaceSuggestion s) onSelected;

  @override
  State<_IdentityPlaceSearchField> createState() =>
      _IdentityPlaceSearchFieldState();
}

class _IdentityPlaceSearchFieldState extends State<_IdentityPlaceSearchField> {
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
  void didUpdateWidget(_IdentityPlaceSearchField old) {
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
        TextField(
          controller: _ctrl,
          decoration: InputDecoration(
            hintText: widget.hint,
            prefixIcon: Icon(
              widget.icon,
              size: 22,
              color: onSurface.withValues(alpha: 0.5),
            ),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
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
            if (v.trim().isNotEmpty) {
              widget.onSelected(
                PlaceSuggestion(displayName: v.trim(), country: ''),
              );
            }
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
                    widget.onSelected(s);
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

class _RoleOption {
  const _RoleOption(this.label, this.icon, this.value);
  final String label;
  final IconData icon;
  final String? value;
}
