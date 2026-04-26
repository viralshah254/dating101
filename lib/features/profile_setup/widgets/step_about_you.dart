import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_typography.dart';
import '../../../l10n/app_localizations.dart';
import '../screens/profile_setup_screen.dart';
import 'step_details.dart' show kAboutMeMaxChars, kAboutMeMinRecommendedChars;
import 'wizard_step_shell.dart';

/// Dating "About You" step — bio + dating intent + conversation starter prompt.
/// This step replaces the old "StepDetails" for dating and absorbs the
/// "Conversation starter" from StepPreferences.
class StepAboutYou extends StatefulWidget {
  const StepAboutYou({
    super.key,
    required this.formData,
    required this.onChanged,
  });

  final ProfileFormData formData;
  final VoidCallback onChanged;

  @override
  State<StepAboutYou> createState() => _StepAboutYouState();
}

class _StepAboutYouState extends State<StepAboutYou> {
  late final TextEditingController _bioController;
  late final TextEditingController _promptController;
  String? _saveStatus;

  static const _datingIntents = [
    _Intent('Serious relationship', Icons.favorite_outline),
    _Intent('Casual / exploring', Icons.celebration_outlined),
    _Intent('Open to marriage', Icons.diamond_outlined),
    _Intent('Friendship first', Icons.people_outline),
    _Intent('Open to anything', Icons.explore_outlined),
  ];

  @override
  void initState() {
    super.initState();
    _bioController = TextEditingController(text: widget.formData.bio);
    _promptController = TextEditingController(text: widget.formData.promptAnswer);
  }

  @override
  void dispose() {
    _bioController.dispose();
    _promptController.dispose();
    super.dispose();
  }

  void _onBioChanged(String v) {
    widget.formData.bio = v;
    setState(() => _saveStatus = 'saving');
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) setState(() => _saveStatus = 'saved');
    });
    widget.onChanged();
  }

  void _onPromptChanged(String v) {
    widget.formData.promptAnswer = v;
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final onSurface = cs.onSurface;
    final bio = _bioController.text;
    final bioLen = bio.length;

    return WizardStepShell(
      icon: Icons.auto_stories_rounded,
      headline: 'Tell us what makes you tick',
      subtitle: 'Be honest — the right person will love it.',
      saveStatus: _saveStatus,
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Bio ──────────────────────────────────────────────────────
            _SectionHeader(
              icon: Icons.edit_note_rounded,
              label: l.aboutMeSection,
              color: cs.primary,
            ),
            const SizedBox(height: 10),
            _BioBubble(
              controller: _bioController,
              hint: l.aboutMeHint,
              onChanged: _onBioChanged,
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (bioLen > 0 && bioLen < kAboutMeMinRecommendedChars)
                  Text(
                    l.aboutMeMinRecommended(kAboutMeMinRecommendedChars),
                    style: TextStyle(
                      fontSize: 11,
                      color: cs.error.withValues(alpha: 0.8),
                    ),
                  )
                else if (bioLen >= kAboutMeMinRecommendedChars)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_outline_rounded, size: 12, color: Colors.green.shade600),
                      const SizedBox(width: 3),
                      Text(
                        'Bio looks strong!',
                        style: TextStyle(fontSize: 11, color: Colors.green.shade600, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                const Spacer(),
                Text(
                  '$bioLen / $kAboutMeMaxChars',
                  style: TextStyle(
                    fontSize: 11,
                    color: onSurface.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // ── Dating intent ──────────────────────────────────────────────
            _SectionHeader(
              icon: Icons.favorite_border_rounded,
              label: 'I\'m looking for',
              color: cs.primary,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _datingIntents.asMap().entries.map((e) {
                final intent = e.value;
                final selected = widget.formData.datingIntent == intent.label;
                return ChoiceChip(
                  avatar: selected ? null : Icon(intent.icon, size: 16, color: cs.primary),
                  label: Text(intent.label),
                  selected: selected,
                  onSelected: (_) {
                    widget.formData.datingIntent = intent.label;
                    widget.onChanged();
                    setState(() {});
                  },
                  selectedColor: cs.primary.withValues(alpha: 0.15),
                  side: BorderSide(
                    color: selected ? cs.primary : cs.outline.withValues(alpha: 0.3),
                    width: selected ? 1.5 : 1,
                  ),
                  labelStyle: AppTypography.bodySmall.copyWith(
                    color: selected ? cs.primary : onSurface.withValues(alpha: 0.75),
                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  ),
                  backgroundColor: cs.surface,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ).animate(delay: Duration(milliseconds: e.key * 50)).fadeIn().scale(
                      begin: const Offset(0.9, 0.9),
                      end: const Offset(1, 1),
                    );
              }).toList(),
            ),
            const SizedBox(height: 28),

            // ── Conversation starter ─────────────────────────────────────
            _SectionHeader(
              icon: Icons.chat_bubble_outline_rounded,
              label: 'Your conversation starter',
              color: cs.primary,
            ),
            const SizedBox(height: 6),
            Text(
              'Write a fun prompt that helps someone start a conversation with you.',
              style: AppTypography.bodySmall.copyWith(
                color: onSurface.withValues(alpha: 0.55),
              ),
            ),
            const SizedBox(height: 12),
            _BioBubble(
              controller: _promptController,
              hint: 'e.g. "Ask me about my last hiking trip…"',
              onChanged: _onPromptChanged,
              minLines: 2,
              maxLines: 5,
              maxLength: 300,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _Intent {
  const _Intent(this.label, this.icon);
  final String label;
  final IconData icon;
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.label,
    required this.color,
  });
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppTypography.labelLarge.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}

class _BioBubble extends StatelessWidget {
  const _BioBubble({
    required this.controller,
    required this.hint,
    required this.onChanged,
    this.minLines = 5,
    this.maxLines = 12,
    this.maxLength = kAboutMeMaxChars,
  });
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;
  final int minLines;
  final int maxLines;
  final int maxLength;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return TextField(
      controller: controller,
      minLines: minLines,
      maxLines: maxLines,
      maxLength: maxLength,
      keyboardType: TextInputType.multiline,
      textInputAction: TextInputAction.newline,
      decoration: InputDecoration(
        hintText: hint,
        counterText: '',
        hintStyle: AppTypography.bodyMedium.copyWith(
          color: cs.onSurface.withValues(alpha: 0.35),
        ),
        filled: true,
        fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: cs.primary.withValues(alpha: 0.5), width: 1.5),
        ),
        contentPadding: const EdgeInsets.all(16),
      ),
      style: AppTypography.bodyMedium.copyWith(
        color: cs.onSurface,
        height: 1.5,
      ),
      onChanged: onChanged,
    );
  }
}

// ── Matrimony "About You" step ─────────────────────────────────────────────

/// Matrimony version: bio + 3 short prompts that map into matrimonyExtensions.prompts
class StepAboutYouMatrimony extends StatefulWidget {
  const StepAboutYouMatrimony({
    super.key,
    required this.formData,
    required this.onChanged,
  });
  final ProfileFormData formData;
  final VoidCallback onChanged;

  @override
  State<StepAboutYouMatrimony> createState() => _StepAboutYouMatrimonyState();
}

class _StepAboutYouMatrimonyState extends State<StepAboutYouMatrimony> {
  late final TextEditingController _bioController;
  late final TextEditingController _familyPromptController;
  late final TextEditingController _valuePromptController;
  late final TextEditingController _funPromptController;
  String? _saveStatus;

  @override
  void initState() {
    super.initState();
    _bioController = TextEditingController(text: widget.formData.bio);

    // Load existing prompts from matrimonyExtensions map
    final prompts = (widget.formData.matrimonyPrompts) ?? {};
    _familyPromptController = TextEditingController(text: prompts['myFamily'] ?? '');
    _valuePromptController = TextEditingController(text: prompts['myValues'] ?? '');
    _funPromptController = TextEditingController(text: prompts['funFact'] ?? '');
  }

  @override
  void dispose() {
    _bioController.dispose();
    _familyPromptController.dispose();
    _valuePromptController.dispose();
    _funPromptController.dispose();
    super.dispose();
  }

  void _savePrompts() {
    widget.formData.matrimonyPrompts = {
      'myFamily': _familyPromptController.text,
      'myValues': _valuePromptController.text,
      'funFact': _funPromptController.text,
    };
    widget.onChanged();
  }

  void _onBioChanged(String v) {
    widget.formData.bio = v;
    setState(() => _saveStatus = 'saving');
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) setState(() => _saveStatus = 'saved');
    });
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final onSurface = cs.onSurface;
    final bio = _bioController.text;
    final bioLen = bio.length;

    return WizardStepShell(
      icon: Icons.auto_stories_rounded,
      headline: 'Write your story',
      subtitle: 'Families read this first. Be warm, be real.',
      saveStatus: _saveStatus,
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeader(icon: Icons.edit_note_rounded, label: 'About me', color: cs.primary),
            const SizedBox(height: 10),
            _BioBubble(
              controller: _bioController,
              hint: 'Write a few lines about yourself — personality, what you love, what matters to you…',
              onChanged: _onBioChanged,
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (bioLen >= kAboutMeMinRecommendedChars)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_outline_rounded, size: 12, color: Colors.green.shade600),
                      const SizedBox(width: 3),
                      Text(
                        'Bio looks strong!',
                        style: TextStyle(fontSize: 11, color: Colors.green.shade600, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                const Spacer(),
                Text(
                  '$bioLen / $kAboutMeMaxChars',
                  style: TextStyle(fontSize: 11, color: onSurface.withValues(alpha: 0.4)),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Short prompts
            _SectionHeader(icon: Icons.question_answer_outlined, label: 'A few quick prompts', color: cs.primary),
            const SizedBox(height: 8),
            Text(
              'Optional but loved — helps families and matches understand you better.',
              style: AppTypography.bodySmall.copyWith(color: onSurface.withValues(alpha: 0.55)),
            ),
            const SizedBox(height: 16),
            _PromptCard(
              emoji: '🏠',
              question: 'My family in one line',
              controller: _familyPromptController,
              hint: 'e.g. "Close-knit family, three siblings, love Sunday lunches together."',
              onChanged: (_) => _savePrompts(),
            ),
            const SizedBox(height: 12),
            _PromptCard(
              emoji: '💛',
              question: 'What I value in a partner',
              controller: _valuePromptController,
              hint: 'e.g. "Kindness, a good sense of humour, and intellectual curiosity."',
              onChanged: (_) => _savePrompts(),
            ),
            const SizedBox(height: 12),
            _PromptCard(
              emoji: '✨',
              question: 'A fun fact about me',
              controller: _funPromptController,
              hint: 'e.g. "I make my own chai blend. Seriously, ask me for the recipe."',
              onChanged: (_) => _savePrompts(),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _PromptCard extends StatelessWidget {
  const _PromptCard({
    required this.emoji,
    required this.question,
    required this.controller,
    required this.hint,
    required this.onChanged,
  });
  final String emoji;
  final String question;
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outline.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  question,
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: controller,
            maxLines: 3,
            minLines: 1,
            maxLength: 200,
            decoration: InputDecoration(
              hintText: hint,
              counterText: '',
              hintStyle: AppTypography.bodySmall.copyWith(
                color: cs.onSurface.withValues(alpha: 0.35),
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              isDense: true,
            ),
            style: AppTypography.bodyMedium.copyWith(
              color: cs.onSurface,
              height: 1.5,
            ),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
