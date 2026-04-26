import 'package:flutter/material.dart';

import '../../../core/mode/app_mode.dart';
import '../screens/profile_setup_screen.dart';
import 'step_details.dart';
import 'wizard_step_shell.dart';

/// Dating "Lifestyle" step — diet, drinking, smoking, exercise, pets,
/// height, body type.
/// Extracted from the old combined StepDetails so "About you" (bio + intent
/// + conversation starter) can sit immediately after Photos.
class StepLifestyle extends StatelessWidget {
  const StepLifestyle({
    super.key,
    required this.formData,
    required this.onChanged,
  });

  final ProfileFormData formData;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return WizardStepShell(
      icon: Icons.self_improvement_rounded,
      headline: 'How do you actually live?',
      subtitle: 'These details spark the best conversations.',
      child: StepDetails(
        mode: AppMode.dating,
        formData: formData,
        onChanged: onChanged,
        datingOnlySection: DatingDetailsOnlySection.lifestyle,
      ),
    );
  }
}
