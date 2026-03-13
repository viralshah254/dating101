import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/providers/repository_providers.dart';
import '../../../data/api/api_client.dart';

import '../../../core/theme/app_typography.dart';
import '../../../l10n/app_localizations.dart';

/// Week 15 — Live photo verification: capture, blink/smile challenge, badge states, retry.
enum PhotoVerificationState {
  intro,
  capture,
  challenge, // blink / smile
  processing,
  success,
  failed,
  retry,
}

class PhotoVerificationScreen extends ConsumerStatefulWidget {
  const PhotoVerificationScreen({super.key});

  @override
  ConsumerState<PhotoVerificationScreen> createState() =>
      _PhotoVerificationScreenState();
}

class _PhotoVerificationScreenState
    extends ConsumerState<PhotoVerificationScreen> {
  PhotoVerificationState _state = PhotoVerificationState.intro;
  final ImagePicker _picker = ImagePicker();
  XFile? _capturedImage;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        title: Text(AppLocalizations.of(context)!.photoVerification),
      ),
      body: SafeArea(child: _buildStep(context, accent, isDark)),
    );
  }

  Widget _buildStep(BuildContext context, Color accent, bool isDark) {
    switch (_state) {
      case PhotoVerificationState.intro:
        return _IntroStep(
          accent: accent,
          onStart: () =>
              setState(() => _state = PhotoVerificationState.capture),
        );
      case PhotoVerificationState.capture:
        return _CaptureStep(
          accent: accent,
          capturedImage: _capturedImage,
          errorMessage: _errorMessage,
          onCapture: _captureSelfie,
        );
      case PhotoVerificationState.challenge:
        return _ChallengeStep(
          accent: accent,
          onPass: _submitPhotoVerification,
          onFail: () => setState(() => _state = PhotoVerificationState.retry),
        );
      case PhotoVerificationState.processing:
        return _ProcessingStep(accent: accent);
      case PhotoVerificationState.success:
        return _SuccessStep(accent: accent, onClose: () => context.pop());
      case PhotoVerificationState.failed:
      case PhotoVerificationState.retry:
        return _RetryStep(
          accent: accent,
          errorMessage: _errorMessage,
          onRetry: () =>
              setState(() => _state = PhotoVerificationState.capture),
          onCancel: () => context.pop(),
        );
    }
  }

  Future<void> _captureSelfie() async {
    try {
      final file = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 85,
      );
      if (file == null || !mounted) return;
      setState(() {
        _capturedImage = file;
        _errorMessage = null;
        _state = PhotoVerificationState.challenge;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Could not open the camera. Please try again.');
    }
  }

  Future<void> _submitPhotoVerification() async {
    if (_capturedImage == null) {
      setState(() {
        _errorMessage = 'Take a selfie first to continue.';
        _state = PhotoVerificationState.capture;
      });
      return;
    }

    setState(() {
      _state = PhotoVerificationState.processing;
      _errorMessage = null;
    });

    try {
      await ref.read(verificationRepositoryProvider).submitPhotoVerification();
      if (!mounted) return;
      setState(() => _state = PhotoVerificationState.success);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _state = PhotoVerificationState.retry;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Photo verification failed. Please try again.';
        _state = PhotoVerificationState.retry;
      });
    }
  }
}

class _IntroStep extends StatelessWidget {
  const _IntroStep({required this.accent, required this.onStart});
  final Color accent;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),
          Icon(Icons.face_retouching_natural, size: 80, color: accent)
              .animate()
              .fadeIn()
              .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1)),
          const SizedBox(height: 24),
          Text(
            'Verify with a selfie',
            style: AppTypography.headlineMedium,
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 12),
          Text(
            'We’ll ask you to take a photo and complete a quick blink or smile. This helps keep Shubhmilan safe.',
            style: AppTypography.bodyMedium,
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 200.ms),
          const Spacer(),
          FilledButton(
            onPressed: onStart,
            child: Text(AppLocalizations.of(context)!.startVerification),
          ).animate().fadeIn(delay: 300.ms),
        ],
      ),
    );
  }
}

class _CaptureStep extends StatelessWidget {
  const _CaptureStep({
    required this.accent,
    required this.onCapture,
    required this.capturedImage,
    required this.errorMessage,
  });
  final Color accent;
  final Future<void> Function() onCapture;
  final XFile? capturedImage;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              clipBehavior: Clip.antiAlias,
              child: capturedImage == null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt, size: 64, color: accent),
                          const SizedBox(height: 16),
                          Text(
                            'Use your front camera to take a clear selfie.',
                            style: AppTypography.bodySmall,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : Image.file(
                      File(capturedImage!.path),
                      fit: BoxFit.cover,
                    ),
            ),
          ),
          if (errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              errorMessage!,
              style: AppTypography.bodySmall.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => onCapture(),
            icon: const Icon(Icons.camera),
            label: Text(AppLocalizations.of(context)!.takePhoto),
          ),
        ],
      ),
    );
  }
}

class _ChallengeStep extends StatelessWidget {
  const _ChallengeStep({
    required this.accent,
    required this.onPass,
    required this.onFail,
  });
  final Color accent;
  final VoidCallback onPass;
  final VoidCallback onFail;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),
          Text(
            'Blink or smile',
            style: AppTypography.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'We’ll detect the movement to confirm it’s you.',
            style: AppTypography.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.face, size: 120),
          ),
          const Spacer(),
          FilledButton(
            onPressed: onPass,
            child: Text(AppLocalizations.of(context)!.imReady),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: onFail,
            child: Text(AppLocalizations.of(context)!.somethingWentWrong),
          ),
        ],
      ),
    );
  }
}

class _ProcessingStep extends StatelessWidget {
  const _ProcessingStep({required this.accent});
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(accent),
                ),
              )
              .animate(onPlay: (c) => c.repeat())
              .shimmer(duration: 1500.ms, color: accent.withValues(alpha: 0.3)),
          const SizedBox(height: 24),
          Text('Verifying your photo…', style: AppTypography.titleMedium),
        ],
      ),
    );
  }
}

class _SuccessStep extends StatelessWidget {
  const _SuccessStep({required this.accent, required this.onClose});
  final Color accent;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.verified, size: 80, color: accent)
              .animate()
              .scale(begin: const Offset(0.5, 0.5), end: const Offset(1, 1))
              .fadeIn(),
          const SizedBox(height: 24),
          Text('You’re verified', style: AppTypography.headlineMedium),
          const SizedBox(height: 8),
          Text(
            'Your profile will show a verification badge.',
            style: AppTypography.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: onClose,
            child: Text(AppLocalizations.of(context)!.done),
          ),
        ],
      ),
    );
  }
}

class _RetryStep extends StatelessWidget {
  const _RetryStep({
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
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.refresh, size: 64, color: accent),
          const SizedBox(height: 24),
          Text(
            'Verification didn’t work',
            style: AppTypography.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Check lighting and try again. You can also skip and verify later.',
            style: AppTypography.bodyMedium,
            textAlign: TextAlign.center,
          ),
          if (errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              errorMessage!,
              style: AppTypography.bodySmall.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 32),
          FilledButton(
            onPressed: onRetry,
            child: Text(AppLocalizations.of(context)!.tryAgain),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: onCancel,
            child: Text(AppLocalizations.of(context)!.skipForNow),
          ),
        ],
      ),
    );
  }
}
