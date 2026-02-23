import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/mode/app_mode.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/app_localizations.dart';
import '../screens/profile_setup_screen.dart';

class StepIdentity extends StatelessWidget {
  const StepIdentity({
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
    final l = AppLocalizations.of(context)!;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final accent = Theme.of(context).colorScheme.primary;

    final forSelf = formData.isForSelf;
    final subject = formData.subjectName;

    final title = forSelf ? l.profileSetupTitle : l.dynSetupTitle(subject);
    final subtitle = forSelf ? l.profileSetupSubtitle : l.dynSetupSubtitle(subject);
    final nameLabel = forSelf ? l.yourName : l.dynName(subject);
    final genderLabel = forSelf ? l.genderQuestion : l.dynGender(subject);
    final dobLabel = forSelf ? l.dateOfBirth : l.dynDob(subject);
    final locationLabel = forSelf ? l.currentLocation : l.dynLocation(subject);
    final hometownLabel = forSelf ? l.hometown : l.dynHometown(subject);

    String nameHint;
    if (forSelf) {
      nameHint = l.nameHint;
    } else if (formData.creatingFor == 'son' || formData.creatingFor == 'brother') {
      nameHint = l.dynNameHintSon;
    } else if (formData.creatingFor == 'daughter' || formData.creatingFor == 'sister') {
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
              fontSize: 32,
              height: 1.15,
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.08, end: 0),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: AppTypography.bodyMedium.copyWith(
              color: onSurface.withValues(alpha: 0.6),
            ),
          ).animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 32),

          // ── Creating for (matrimony only) ───────────────────────
          if (mode.isMatrimony) ...[
            _SectionLabel(label: l.profileCreatingFor),
            const SizedBox(height: 12),
            _CreatingForSelector(formData: formData, onChanged: onChanged),
            const SizedBox(height: 28),
          ],

          // ── Name (mandatory) ────────────────────────────────────
          _SectionLabel(label: nameLabel, mandatory: true),
          const SizedBox(height: 8),
          _StyledTextField(
            value: formData.name,
            hint: nameHint,
            textInputAction: TextInputAction.next,
            onChanged: (v) {
              formData.name = v;
              onChanged();
            },
          ),
          const SizedBox(height: 24),

          // ── Gender (mandatory) ──────────────────────────────────
          _SectionLabel(label: genderLabel, mandatory: true),
          const SizedBox(height: 12),
          _ChipSelector(
            options: [l.genderWoman, l.genderMan, l.genderNonBinary],
            selected: formData.gender,
            onSelected: (v) {
              formData.gender = v;
              // Smart default: auto-set "Interested in" based on gender
              if (v == l.genderMan && formData.interestedIn == null) {
                formData.interestedIn = mode.isDating ? l.interestedInWomen : l.lookingForBride;
              } else if (v == l.genderWoman && formData.interestedIn == null) {
                formData.interestedIn = mode.isDating ? l.interestedInMen : l.lookingForGroom;
              }
              onChanged();
            },
          ),
          const SizedBox(height: 24),

          // ── Interested in (smart default) ───────────────────────
          _SectionLabel(label: mode.isDating ? l.interestedIn : l.lookingForPartner),
          const SizedBox(height: 12),
          _ChipSelector(
            options: mode.isDating
                ? [l.interestedInWomen, l.interestedInMen, l.interestedInEveryone]
                : [l.lookingForBride, l.lookingForGroom],
            selected: formData.interestedIn,
            onSelected: (v) {
              formData.interestedIn = v;
              onChanged();
            },
          ),
          const SizedBox(height: 24),

          // ── Date of birth (mandatory) ───────────────────────────
          _SectionLabel(label: dobLabel, mandatory: true),
          const SizedBox(height: 8),
          _DateOfBirthPicker(
            value: formData.dateOfBirth,
            onChanged: (d) {
              formData.dateOfBirth = d;
              onChanged();
            },
          ),
          const SizedBox(height: 24),

          // ── Location ────────────────────────────────────────────
          _SectionLabel(label: locationLabel),
          const SizedBox(height: 8),
          _StyledTextField(
            value: formData.location,
            hint: 'e.g. Mumbai, New York',
            icon: Icons.location_on_outlined,
            textInputAction: TextInputAction.next,
            onChanged: (v) {
              formData.location = v;
              onChanged();
            },
          ),

          if (mode.isMatrimony) ...[
            const SizedBox(height: 24),
            _SectionLabel(label: hometownLabel),
            const SizedBox(height: 8),
            _StyledTextField(
              value: formData.hometown,
              hint: 'e.g. Jaipur, Hyderabad',
              icon: Icons.home_outlined,
              textInputAction: TextInputAction.done,
              onChanged: (v) {
                formData.hometown = v;
                onChanged();
              },
            ),
          ],

          const SizedBox(height: 28),

          // ── Physical & Personal section ─────────────────────────
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
}

// ── Physical / Personal card (height, body type, marital status, complexion) ──

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
              Icon(Icons.accessibility_new_outlined, size: 20, color: accent),
              const SizedBox(width: 8),
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
          const SizedBox(height: 8),
          _HeightPicker(
            value: formData.heightCm,
            onChanged: (v) {
              formData.heightCm = v;
              onChanged();
            },
          ),
          const SizedBox(height: 20),

          // Body type
          _SectionLabel(label: l.bodyTypeQuestion),
          const SizedBox(height: 10),
          _ChipSelector(
            options: [l.bodyTypeSlim, l.bodyTypeAthletic, l.bodyTypeAverage, l.bodyTypeHeavy, l.bodyTypeCurvy],
            selected: formData.bodyType,
            onSelected: (v) {
              formData.bodyType = v;
              onChanged();
            },
          ),

          if (mode.isMatrimony) ...[
            const SizedBox(height: 20),

            // Complexion
            _SectionLabel(label: l.complexionQuestion),
            const SizedBox(height: 10),
            _ChipSelector(
              options: [l.complexionFair, l.complexionWheatish, l.complexionDark, l.complexionPreferNot],
              selected: formData.complexion,
              onSelected: (v) {
                formData.complexion = v;
                onChanged();
              },
            ),
          ],

          const SizedBox(height: 20),

          // Marital status
          _SectionLabel(label: l.maritalStatus),
          const SizedBox(height: 10),
          _ChipSelector(
            options: [l.neverMarried, l.divorced, l.widowed, l.awaitingDivorce],
            selected: formData.maritalStatus,
            onSelected: (v) {
              formData.maritalStatus = v;
              onChanged();
            },
          ),

          if (mode.isMatrimony) ...[
            const SizedBox(height: 20),

            // Disability
            _SectionLabel(label: l.disabilityQuestion),
            const SizedBox(height: 10),
            _ChipSelector(
              options: [l.disabilityNone, l.disabilityPhysical, l.disabilityPreferNot],
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
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(ctx).dividerColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '$tmpFeet\' $tmpInches" — $cm cm',
                    style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _WheelColumn(
                        label: 'ft',
                        min: 4, max: 7, value: tmpFeet,
                        onChanged: (v) => setBS(() => tmpFeet = v),
                      ),
                      const SizedBox(width: 32),
                      _WheelColumn(
                        label: 'in',
                        min: 0, max: 11, value: tmpInches,
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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Confirm', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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
            Icon(Icons.straighten, size: 20, color: onSurface.withValues(alpha: 0.5)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                hasValue ? '$_feet\' $_inches" — $_totalCm cm' : 'Tap to select height',
                style: AppTypography.bodyLarge.copyWith(
                  color: hasValue ? onSurface : onSurface.withValues(alpha: 0.4),
                ),
              ),
            ),
            Icon(Icons.unfold_more, size: 20, color: accent.withValues(alpha: 0.6)),
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
        Text(label, style: AppTypography.labelSmall.copyWith(color: onSurface.withValues(alpha: 0.5))),
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
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                      color: isSelected ? accent : onSurface.withValues(alpha: 0.35),
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
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45),
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
          style: AppTypography.labelLarge.copyWith(
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
    required this.onChanged,
    this.icon,
    this.textInputAction = TextInputAction.done,
  });

  final String value;
  final String hint;
  final ValueChanged<String> onChanged;
  final IconData? icon;
  final TextInputAction textInputAction;

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
    return TextField(
      controller: _ctrl,
      textInputAction: widget.textInputAction,
      decoration: InputDecoration(
        hintText: widget.hint,
        prefixIcon: widget.icon != null ? Icon(widget.icon) : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
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
        return GestureDetector(
          onTap: () => onSelected(opt),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? accent.withValues(alpha: 0.12) : Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? accent : Theme.of(context).dividerColor,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Text(
              opt,
              style: AppTypography.bodyMedium.copyWith(
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

class _DateOfBirthPicker extends StatelessWidget {
  const _DateOfBirthPicker({required this.value, required this.onChanged});

  final DateTime? value;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final displayText = value != null
        ? '${value!.day.toString().padLeft(2, '0')} / ${value!.month.toString().padLeft(2, '0')} / ${value!.year}'
        : 'DD / MM / YYYY';

    return GestureDetector(
      onTap: () async {
        final now = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime(now.year - 25, 1, 1),
          firstDate: DateTime(1950),
          lastDate: DateTime(now.year - 18, now.month, now.day),
        );
        if (picked != null) onChanged(picked);
      },
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
            Icon(Icons.calendar_today_outlined, size: 20, color: onSurface.withValues(alpha: 0.5)),
            const SizedBox(width: 12),
            Text(
              displayText,
              style: AppTypography.bodyLarge.copyWith(
                color: value != null ? onSurface : onSurface.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      ),
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
      _RoleOption(l.profileCreatingForRelative, Icons.family_restroom, 'relative'),
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
                formData.interestedIn = l.lookingForBride;
              case 'daughter':
              case 'sister':
                formData.gender = l.genderWoman;
                formData.interestedIn = l.lookingForGroom;
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
                Icon(opt.icon, size: 18, color: isSelected ? accent : onSurface.withValues(alpha: 0.5)),
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

class _RoleOption {
  const _RoleOption(this.label, this.icon, this.value);
  final String label;
  final IconData icon;
  final String? value;
}
