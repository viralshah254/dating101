import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../../../core/providers/repository_providers.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/app_localizations.dart';

enum _VerifStep {
  intro,
  selfiePreview,
  idPreview,
  uploading,
  pendingReview,
  failed,
}

class PhotoVerificationScreen extends ConsumerStatefulWidget {
  const PhotoVerificationScreen({super.key});

  @override
  ConsumerState<PhotoVerificationScreen> createState() =>
      _PhotoVerificationScreenState();
}

class _PhotoVerificationScreenState
    extends ConsumerState<PhotoVerificationScreen> {
  _VerifStep _step = _VerifStep.intro;
  XFile? _selfieFile;
  XFile? _idFile;
  String? _errorMessage;
  double _uploadProgress = 0;

  final _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _step == _VerifStep.uploading ? null : () => context.pop(),
        ),
        title: Text(_appBarTitle),
      ),
      body: SafeArea(child: _buildStep(context, accent)),
    );
  }

  String get _appBarTitle {
    switch (_step) {
      case _VerifStep.selfiePreview:
        return 'Step 1 of 2 — Selfie';
      case _VerifStep.idPreview:
        return 'Step 2 of 2 — ID Document';
      default:
        return AppLocalizations.of(context)?.photoVerification ?? 'Photo Verification';
    }
  }

  Widget _buildStep(BuildContext context, Color accent) {
    switch (_step) {
      case _VerifStep.intro:
        return _IntroStep(accent: accent, onStart: _pickSelfie);
      case _VerifStep.selfiePreview:
        return _PhotoPreviewStep(
          accent: accent,
          imageFile: _selfieFile!,
          title: 'Your selfie',
          hint: 'Make sure your face is clearly visible and well-lit.',
          retakeLabel: 'Retake selfie',
          continueLabel: 'Looks good — next',
          onRetake: _pickSelfie,
          onContinue: _pickIdDocument,
        );
      case _VerifStep.idPreview:
        return _PhotoPreviewStep(
          accent: accent,
          imageFile: _idFile!,
          title: 'Your ID document',
          hint: 'Ensure all text and your photo on the ID are clearly readable.',
          retakeLabel: 'Retake ID photo',
          continueLabel: 'Submit for review',
          onRetake: _pickIdDocument,
          onContinue: _submitVerification,
        );
      case _VerifStep.uploading:
        return _UploadingStep(accent: accent, progress: _uploadProgress);
      case _VerifStep.pendingReview:
        return _PendingStep(accent: accent, onClose: () => context.pop());
      case _VerifStep.failed:
        return _FailedStep(
          accent: accent,
          errorMessage: _errorMessage,
          onRetry: _pickSelfie,
          onCancel: () => context.pop(),
        );
    }
  }

  // ── Image picking ─────────────────────────────────────────────────────────

  Future<void> _pickSelfie() async {
    final file = await _picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front,
      imageQuality: 90,
    );
    if (file == null || !mounted) return;
    setState(() {
      _selfieFile = file;
      _step = _VerifStep.selfiePreview;
    });
  }

  Future<void> _pickIdDocument() async {
    final choice = await _showIdSourceSheet();
    if (choice == null || !mounted) return;

    final file = await _picker.pickImage(
      source: choice,
      preferredCameraDevice: CameraDevice.rear,
      imageQuality: 90,
    );
    if (file == null || !mounted) return;
    setState(() {
      _idFile = file;
      _step = _VerifStep.idPreview;
    });
  }

  Future<ImageSource?> _showIdSourceSheet() async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(ctx).colorScheme.onSurface.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text('Add ID document', style: AppTypography.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Aadhaar, PAN, Passport, Driving Licence or any govt. ID',
              style: AppTypography.bodySmall.copyWith(
                color: Theme.of(ctx).colorScheme.onSurface.withValues(alpha: 0.55),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded),
              title: const Text('Take a photo'),
              onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ── Upload + submit ───────────────────────────────────────────────────────

  Future<void> _submitVerification() async {
    if (_selfieFile == null || _idFile == null) return;

    setState(() {
      _step = _VerifStep.uploading;
      _uploadProgress = 0;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(verificationRepositoryProvider);

      // Step 1 — compress and upload selfie (progress: 0 → 0.45)
      final selfieBytes = await _compress(_selfieFile!.path);
      setState(() => _uploadProgress = 0.1);

      final selfieUrlResult = await repo.getIdUploadUrl(type: 'selfie');
      if (selfieUrlResult.uploadUrl.isEmpty || selfieUrlResult.key.isEmpty) {
        throw Exception('Could not start upload. Please try again.');
      }
      setState(() => _uploadProgress = 0.2);

      await _putToS3(selfieUrlResult.uploadUrl, selfieBytes);
      setState(() => _uploadProgress = 0.45);

      // Step 2 — compress and upload ID document (progress: 0.45 → 0.85)
      final idBytes = await _compress(_idFile!.path);
      setState(() => _uploadProgress = 0.55);

      final idUrlResult = await repo.getIdUploadUrl(type: 'id');
      if (idUrlResult.uploadUrl.isEmpty || idUrlResult.key.isEmpty) {
        throw Exception('Could not start upload. Please try again.');
      }
      setState(() => _uploadProgress = 0.65);

      await _putToS3(idUrlResult.uploadUrl, idBytes);
      setState(() => _uploadProgress = 0.85);

      // Step 3 — submit for review
      await repo.submitIdVerification(idUrlResult.key, selfieKey: selfieUrlResult.key);
      setState(() => _uploadProgress = 1.0);

      if (mounted) setState(() => _step = _VerifStep.pendingReview);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _step = _VerifStep.failed;
      });
    }
  }

  Future<List<int>> _compress(String path) async {
    final file = File(path);
    try {
      final compressed = await FlutterImageCompress.compressWithFile(
        file.absolute.path,
        minWidth: 1200,
        minHeight: 1200,
        quality: 85,
        format: CompressFormat.jpeg,
      );
      if (compressed != null && compressed.isNotEmpty) return compressed;
    } catch (_) {}
    return file.readAsBytesSync();
  }

  Future<void> _putToS3(String uploadUrl, List<int> bytes) async {
    final response = await http.put(
      Uri.parse(uploadUrl),
      headers: {'Content-Type': 'image/jpeg'},
      body: bytes,
    );
    if (response.statusCode != 200) {
      throw Exception('Upload failed (${response.statusCode}). Please try again.');
    }
  }
}

// ── Step widgets ──────────────────────────────────────────────────────────────

class _IntroStep extends StatelessWidget {
  const _IntroStep({required this.accent, required this.onStart});
  final Color accent;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),
          Icon(Icons.verified_user_rounded, size: 80, color: accent)
              .animate()
              .fadeIn()
              .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1)),
          const SizedBox(height: 24),
          Text(
            'Verify your identity',
            style: AppTypography.headlineMedium,
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 12),
          Text(
            'Our team will manually review your selfie and ID to confirm it\'s really you. '
            'Verified profiles get a trust badge and significantly more interest.',
            style: AppTypography.bodyMedium.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65),
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 28),
          _Bullet(
            icon: Icons.face_retouching_natural,
            label: 'Take a quick selfie facing the camera',
          ),
          _Bullet(
            icon: Icons.credit_card_rounded,
            label: 'Photograph your Aadhaar, PAN, Passport, Driving Licence or any government-issued ID',
          ),
          _Bullet(
            icon: Icons.schedule_rounded,
            label: 'Our team reviews within 24 hours and notifies you',
          ),
          _Bullet(
            icon: Icons.lock_outline_rounded,
            label: 'Your documents are encrypted and never shared with other users',
          ),
          const SizedBox(height: 36),
          FilledButton.icon(
            onPressed: onStart,
            icon: const Icon(Icons.camera_alt_rounded),
            label: const Text('Start — take selfie'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ).animate().fadeIn(delay: 300.ms),
        ],
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: accent),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: AppTypography.bodySmall)),
        ],
      ),
    );
  }
}

class _PhotoPreviewStep extends StatelessWidget {
  const _PhotoPreviewStep({
    required this.accent,
    required this.imageFile,
    required this.title,
    required this.hint,
    required this.retakeLabel,
    required this.continueLabel,
    required this.onRetake,
    required this.onContinue,
  });

  final Color accent;
  final XFile imageFile;
  final String title;
  final String hint;
  final String retakeLabel;
  final String continueLabel;
  final VoidCallback onRetake;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.file(
                File(imageFile.path),
                fit: BoxFit.cover,
              ),
              // Gradient overlay at bottom for readability
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 120,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withValues(alpha: 0.6)],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: Text(
                  hint,
                  style: AppTypography.bodySmall.copyWith(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FilledButton(
                onPressed: onContinue,
                style: FilledButton.styleFrom(
                  backgroundColor: accent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(continueLabel),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: onRetake,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(color: cs.outline),
                ),
                child: Text(retakeLabel),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _UploadingStep extends StatelessWidget {
  const _UploadingStep({required this.accent, required this.progress});
  final Color accent;
  final double progress;

  String get _label {
    if (progress < 0.45) return 'Uploading selfie…';
    if (progress < 0.85) return 'Uploading ID document…';
    if (progress < 1.0) return 'Submitting for review…';
    return 'Done!';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.cloud_upload_outlined, size: 64, color: accent)
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .fadeIn()
              .then()
              .shimmer(duration: 1200.ms, color: accent.withValues(alpha: 0.3)),
          const SizedBox(height: 28),
          Text(
            _label,
            style: AppTypography.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: accent.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(accent),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${(progress * 100).toInt()}%',
            style: AppTypography.bodySmall.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _PendingStep extends StatelessWidget {
  const _PendingStep({required this.accent, required this.onClose});
  final Color accent;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.hourglass_top_rounded, size: 40, color: accent),
          )
              .animate()
              .scale(begin: const Offset(0.6, 0.6), end: const Offset(1, 1))
              .fadeIn(),
          const SizedBox(height: 28),
          Text(
            'Documents submitted!',
            style: AppTypography.headlineMedium,
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 12),
          Text(
            'Our team will review your selfie and ID within 24 hours. '
            "You'll receive a notification once the review is complete.",
            style: AppTypography.bodyMedium.copyWith(
              color: cs.onSurface.withValues(alpha: 0.65),
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.info_outline_rounded, size: 16, color: accent),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'You can continue using the app while we review.',
                    style: AppTypography.bodySmall.copyWith(color: accent),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 300.ms),
          const SizedBox(height: 36),
          FilledButton(
            onPressed: onClose,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text(AppLocalizations.of(context)?.done ?? 'Done'),
          ).animate().fadeIn(delay: 350.ms),
        ],
      ),
    );
  }
}

class _FailedStep extends StatelessWidget {
  const _FailedStep({
    required this.accent,
    required this.errorMessage,
    required this.onRetry,
    required this.onCancel,
  });

  final Color accent;
  final String? errorMessage;
  final VoidCallback onRetry;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded, size: 64, color: cs.error),
          const SizedBox(height: 24),
          Text(
            'Submission failed',
            style: AppTypography.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Please check your connection and try again.',
            style: AppTypography.bodyMedium.copyWith(
              color: cs.onSurface.withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
          ),
          if (errorMessage != null && errorMessage!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              errorMessage!,
              style: AppTypography.bodySmall.copyWith(color: cs.error),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onRetry,
              child: Text(AppLocalizations.of(context)?.tryAgain ?? 'Try again'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: onCancel,
              child: Text(AppLocalizations.of(context)?.skipForNow ?? 'Skip for now'),
            ),
          ),
        ],
      ),
    );
  }
}
