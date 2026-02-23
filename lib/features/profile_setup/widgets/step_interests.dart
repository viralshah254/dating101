import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_typography.dart';
import '../../../l10n/app_localizations.dart';
import '../screens/profile_setup_screen.dart';

/// Dedicated step for Interests & Hobbies (between Identity and Photos).
class StepInterests extends StatelessWidget {
  const StepInterests({
    super.key,
    required this.formData,
    required this.onChanged,
  });

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
            l.interestsAndHobbies,
            style: AppTypography.displayLarge.copyWith(
              color: onSurface,
              fontSize: 32,
              height: 1.15,
            ),
          ).animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 4),
          Text(
            l.interestsAndHobbiesSubtitle,
            style: AppTypography.bodyMedium.copyWith(
              color: onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 28),
          _InterestPickerContent(formData: formData, onChanged: onChanged),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _InterestPickerContent extends StatefulWidget {
  const _InterestPickerContent({
    required this.formData,
    required this.onChanged,
  });

  final ProfileFormData formData;
  final VoidCallback onChanged;

  @override
  State<_InterestPickerContent> createState() => _InterestPickerContentState();
}

class _InterestPickerContentState extends State<_InterestPickerContent> {
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
                  l.interestsAndHobbies,
                  style: AppTypography.titleMedium.copyWith(
                    color: onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${selected.length}/6',
                  style: AppTypography.labelSmall.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _searchCtrl,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: l.interestsSearchHint,
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
          if (_query.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _filtered.map((tag) => _buildChip(context, tag, selected.contains(tag))).toList(),
            )
          else
            ..._categories.entries.map((entry) {
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
                      children: entry.value.map((tag) => _buildChip(context, tag, selected.contains(tag))).toList(),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  static const _maxInterests = 6;

  Widget _buildChip(BuildContext context, String tag, bool isSelected) {
    final accent = Theme.of(context).colorScheme.primary;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final selected = widget.formData.selectedInterests;
    final atMax = selected.length >= _maxInterests;

    return GestureDetector(
      onTap: () {
        final next = List<String>.from(widget.formData.selectedInterests);
        if (isSelected) {
          next.remove(tag);
        } else {
          if (atMax) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocalizations.of(context)!.interestsMaxReached),
                behavior: SnackBarBehavior.floating,
              ),
            );
            return;
          }
          next.add(tag);
        }
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
