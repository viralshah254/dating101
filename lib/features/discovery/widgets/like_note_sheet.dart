import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_typography.dart';
import '../../../domain/models/profile_summary.dart';

/// Bottom sheet shown when user commits a like swipe.
/// Gives them the option to send silently or attach a note / prompt reply.
/// Returns [LikeNoteResult] with optional [message].
Future<LikeNoteResult?> showLikeNoteSheet(
  BuildContext context,
  ProfileSummary profile,
) {
  return showModalBottomSheet<LikeNoteResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => LikeNoteSheet(profile: profile),
  );
}

class LikeNoteResult {
  const LikeNoteResult({this.message});
  final String? message;
}

class LikeNoteSheet extends StatefulWidget {
  const LikeNoteSheet({super.key, required this.profile});
  final ProfileSummary profile;

  @override
  State<LikeNoteSheet> createState() => _LikeNoteSheetState();
}

class _LikeNoteSheetState extends State<LikeNoteSheet> {
  final _noteController = TextEditingController();
  bool _showNoteField = false;
  String? _selectedPrompt;

  static const int _maxNoteChars = 140;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  String? get _firstPrompt {
    final prompts = widget.profile.promptAnswer;
    if (prompts != null && prompts.trim().isNotEmpty) return prompts;
    return null;
  }

  void _send({String? message}) {
    HapticFeedback.mediumImpact();
    Navigator.of(context).pop(LikeNoteResult(message: message));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final prompt = _firstPrompt;
    final remaining = _maxNoteChars - _noteController.text.length;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          decoration: BoxDecoration(
            color: cs.surface.withValues(alpha: 0.95),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(
                color: cs.outline.withValues(alpha: 0.12),
              ),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                24,
                16,
                24,
                MediaQuery.viewInsetsOf(context).bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: cs.outline.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Header
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              cs.primary,
                              cs.secondary,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: const Icon(
                          Icons.favorite_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'You liked ${widget.profile.name}',
                              style: AppTypography.titleMedium.copyWith(
                                color: cs.onSurface,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'Make it memorable — add a note',
                              style: AppTypography.bodySmall.copyWith(
                                color: cs.onSurface.withValues(alpha: 0.55),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                      .animate()
                      .fadeIn(duration: AppMotion.medium, curve: AppMotion.spring)
                      .slideY(begin: 0.2, end: 0),
                  const SizedBox(height: 24),

                  // Option 1: Send silently
                  _OptionTile(
                    icon: Icons.send_rounded,
                    iconColor: cs.onSurface.withValues(alpha: 0.6),
                    title: 'Send silently',
                    subtitle: 'Let the like speak for itself',
                    delay: const Duration(milliseconds: 60),
                    onTap: () => _send(),
                  ),

                  // Option 2: Add a note
                  _OptionTile(
                    icon: Icons.edit_note_rounded,
                    iconColor: cs.primary,
                    title: 'Add a note',
                    subtitle: 'Stand out with a personal message',
                    delay: const Duration(milliseconds: 120),
                    onTap: () {
                      setState(() {
                        _showNoteField = !_showNoteField;
                        _selectedPrompt = null;
                      });
                    },
                    selected: _showNoteField,
                  ),

                  // Note field
                  if (_showNoteField) ...[
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: cs.primary.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                        color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          TextField(
                            controller: _noteController,
                            maxLength: _maxNoteChars,
                            maxLines: 3,
                            minLines: 2,
                            decoration: InputDecoration(
                              hintText: 'What caught your eye about ${widget.profile.name}?',
                              border: InputBorder.none,
                              counterText: '',
                              hintStyle: AppTypography.bodyMedium.copyWith(
                                color: cs.onSurface.withValues(alpha: 0.35),
                              ),
                            ),
                            style: AppTypography.bodyMedium.copyWith(color: cs.onSurface),
                            onChanged: (_) => setState(() {}),
                            autofocus: true,
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              '$remaining chars left',
                              style: AppTypography.labelSmall.copyWith(
                                color: remaining < 20
                                    ? cs.error
                                    : cs.onSurface.withValues(alpha: 0.4),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                        .animate()
                        .fadeIn(duration: 200.ms)
                        .slideY(begin: -0.1, end: 0),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _noteController.text.trim().isEmpty
                          ? null
                          : () => _send(message: _noteController.text.trim()),
                      style: FilledButton.styleFrom(
                        backgroundColor: cs.primary,
                        foregroundColor: cs.onPrimary,
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text('Send with Note'),
                    ),
                  ],

                  // Option 3: Answer a prompt (only if profile has a prompt)
                  if (prompt != null) ...[
                    _OptionTile(
                      icon: Icons.question_answer_rounded,
                      iconColor: cs.secondary,
                      title: 'Answer their prompt',
                      subtitle: '"${prompt.length > 60 ? '${prompt.substring(0, 60)}…' : prompt}"',
                      delay: const Duration(milliseconds: 180),
                      onTap: () {
                        setState(() {
                          _selectedPrompt = prompt;
                          _showNoteField = false;
                        });
                      },
                      selected: _selectedPrompt != null,
                    ),
                    if (_selectedPrompt != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: cs.secondary.withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                          color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            TextField(
                              controller: _noteController,
                              maxLength: _maxNoteChars,
                              maxLines: 3,
                              minLines: 2,
                              decoration: InputDecoration(
                                hintText: 'Your answer to their prompt…',
                                border: InputBorder.none,
                                counterText: '',
                                hintStyle: AppTypography.bodyMedium.copyWith(
                                  color: cs.onSurface.withValues(alpha: 0.35),
                                ),
                              ),
                              style: AppTypography.bodyMedium.copyWith(color: cs.onSurface),
                              onChanged: (_) => setState(() {}),
                              autofocus: true,
                            ),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                '${_maxNoteChars - _noteController.text.length} chars left',
                                style: AppTypography.labelSmall.copyWith(
                                  color: remaining < 20
                                      ? cs.error
                                      : cs.onSurface.withValues(alpha: 0.4),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                          .animate()
                          .fadeIn(duration: 200.ms)
                          .slideY(begin: -0.1, end: 0),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: _noteController.text.trim().isEmpty
                            ? null
                            : () => _send(
                                  message:
                                      '↩ "${_selectedPrompt!.length > 40 ? '${_selectedPrompt!.substring(0, 40)}…' : _selectedPrompt!}" — ${_noteController.text.trim()}',
                                ),
                        style: FilledButton.styleFrom(
                          backgroundColor: cs.secondary,
                          foregroundColor: cs.onSecondary,
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text('Send Prompt Reply'),
                      ),
                    ],
                  ],
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.selected = false,
    this.delay = Duration.zero,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool selected;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected
            ? iconColor.withValues(alpha: 0.08)
            : cs.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected
                    ? iconColor.withValues(alpha: 0.3)
                    : cs.outline.withValues(alpha: 0.12),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: iconColor.withValues(alpha: 0.12),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTypography.titleSmall.copyWith(
                          color: cs.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: AppTypography.bodySmall.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.55),
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (selected)
                  Icon(Icons.check_circle_rounded, color: iconColor, size: 20),
              ],
            ),
          ),
        ),
      ),
    )
        .animate(delay: delay)
        .fadeIn(duration: AppMotion.medium, curve: AppMotion.spring)
        .slideY(begin: 0.15, end: 0);
  }
}
