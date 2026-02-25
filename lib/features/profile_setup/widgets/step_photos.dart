import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_typography.dart';
import '../../../l10n/app_localizations.dart';
import '../screens/profile_setup_screen.dart';

class StepPhotos extends StatefulWidget {
  const StepPhotos({
    super.key,
    required this.formData,
    required this.onChanged,
  });

  final ProfileFormData formData;
  final VoidCallback onChanged;

  @override
  State<StepPhotos> createState() => _StepPhotosState();
}

class _StepPhotosState extends State<StepPhotos> {
  static const _maxPhotos = 6;
  final _picker = ImagePicker();

  List<String> get _photos => widget.formData.photos;

  Future<void> _pickPhotos() async {
    final remaining = _maxPhotos - _photos.length;
    if (remaining <= 0) return;

    final picked = await _picker.pickMultiImage(
      imageQuality: 85,
      maxWidth: 1200,
      maxHeight: 1200,
    );

    if (picked.isEmpty) return;

    final paths = picked.take(remaining).map((x) => x.path).toList();
    setState(() {
      _photos.addAll(paths);
    });
    widget.onChanged();
  }

  void _removePhoto(int index) {
    HapticFeedback.lightImpact();
    setState(() {
      _photos.removeAt(index);
    });
    widget.onChanged();
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      final item = _photos.removeAt(oldIndex);
      _photos.insert(newIndex, item);
    });
    HapticFeedback.mediumImpact();
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final accent = Theme.of(context).colorScheme.primary;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    final forSelf = widget.formData.isForSelf;
    final subject = widget.formData.subjectName;

    final subtitle = forSelf
        ? 'Add at least 2 photos. Clear face photos get 3x more responses.'
        : l.dynPhotosSubtitle(subject);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.profileBuilderPhotos,
            style: AppTypography.displayLarge.copyWith(
              color: onSurface,
              fontSize: 32,
              height: 1.15,
            ),
          ).animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: AppTypography.bodyMedium.copyWith(
              color: onSurface.withValues(alpha: 0.6),
            ),
          ),
          if (_photos.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Hold & drag to reorder. First photo is your profile picture.',
              style: AppTypography.bodySmall.copyWith(
                color: accent.withValues(alpha: 0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const SizedBox(height: 28),

          _buildPhotoGrid(context, accent, onSurface),

          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: accent.withValues(alpha: 0.15)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.auto_awesome, size: 18, color: accent),
                    const SizedBox(width: 8),
                    Text(
                      'Photo tips',
                      style: AppTypography.labelLarge.copyWith(
                        color: onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _TipRow(icon: Icons.check_circle_outline, text: 'Clear, well-lit face photo as main'),
                const SizedBox(height: 6),
                _TipRow(icon: Icons.check_circle_outline, text: 'Full-length photo shows personality'),
                const SizedBox(height: 6),
                _TipRow(icon: Icons.check_circle_outline, text: 'Avoid heavy filters or group shots'),
                const SizedBox(height: 6),
                _TipRow(icon: Icons.check_circle_outline, text: 'Smile — it genuinely helps'),
              ],
            ),
          ).animate().fadeIn(delay: 300.ms),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildPhotoGrid(BuildContext context, Color accent, Color onSurface) {
    final slotWidth = (MediaQuery.of(context).size.width - 72) / 3;
    final slotHeight = slotWidth / 0.78;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: List.generate(_maxPhotos, (i) {
        final isFilled = i < _photos.length;

        return SizedBox(
          width: slotWidth,
          height: slotHeight,
          child: isFilled
              ? _buildFilledSlot(i, accent, slotWidth, slotHeight)
              : _buildEmptySlot(i, accent, onSurface),
        );
      }),
    ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.04, end: 0);
  }

  Widget _buildFilledSlot(int i, Color accent, double w, double h) {
    return LongPressDraggable<int>(
      data: i,
      delay: const Duration(milliseconds: 150),
      onDragStarted: () => HapticFeedback.mediumImpact(),
      feedback: Material(
        color: Colors.transparent,
        elevation: 8,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: w,
          height: h,
          child: Opacity(
            opacity: 0.85,
            child: _PhotoCard(path: _photos[i], isPrimary: i == 0, accent: accent),
          ),
        ),
      ),
      childWhenDragging: Container(
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accent.withValues(alpha: 0.3), width: 2),
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          _PhotoCard(path: _photos[i], isPrimary: i == 0, accent: accent),
          Positioned(
            top: -6,
            right: -6,
            child: GestureDetector(
              onTap: () => _removePhoto(i),
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySlot(int i, Color accent, Color onSurface) {
    final showPlus = i == _photos.length;
    final canAcceptDrop = _photos.isNotEmpty && i <= _photos.length;

    final content = GestureDetector(
      onTap: showPlus ? _pickPhotos : null,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: showPlus
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_photo_alternate_outlined, size: 28, color: onSurface.withValues(alpha: 0.3)),
                    const SizedBox(height: 4),
                    Text('Add', style: AppTypography.caption.copyWith(color: onSurface.withValues(alpha: 0.4))),
                  ],
                ),
              )
            : null,
      ),
    );

    if (!canAcceptDrop) return content;

    return DragTarget<int>(
      onWillAcceptWithDetails: (_) => true,
      onAcceptWithDetails: (details) => _onReorder(details.data, i.clamp(0, _photos.length - 1)),
      builder: (context, candidateData, _) {
        if (candidateData.isNotEmpty) {
          return Container(
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: accent.withValues(alpha: 0.4), width: 2),
            ),
          );
        }
        return content;
      },
    );
  }
}

class _PhotoCard extends StatelessWidget {
  const _PhotoCard({
    required this.path,
    required this.isPrimary,
    required this.accent,
  });
  final String path;
  final bool isPrimary;
  final Color accent;

  bool get _isNetwork => path.startsWith('http');

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPrimary ? accent : Theme.of(context).dividerColor,
          width: isPrimary ? 2 : 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_isNetwork)
              Image.network(path, fit: BoxFit.cover)
            else
              Image.file(File(path), fit: BoxFit.cover),
            if (isPrimary)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Main',
                    style: AppTypography.labelSmall.copyWith(
                      color: Colors.white,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TipRow extends StatelessWidget {
  const _TipRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Row(
      children: [
        Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: AppTypography.bodySmall.copyWith(
              color: onSurface.withValues(alpha: 0.7),
            ),
          ),
        ),
      ],
    );
  }
}
