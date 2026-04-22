import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../core/providers/repository_providers.dart';
import '../../../data/api/api_client.dart';
import '../../../domain/repositories/verification_repository.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/app_localizations.dart';

/// Custom URL scheme Persona redirects to when the user finishes (or exits).
const _personaRedirectScheme = 'shubhmilan';
const _personaRedirectHost = 'persona';

enum _VerifState {
  intro,
  creatingSession,
  webview,   // Persona hosted flow
  confirming,
  success,
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
  _VerifState _state = _VerifState.intro;
  LivenessSession? _session;
  LivenessResult? _result;
  String? _errorMessage;
  WebViewController? _webViewController;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        title: Text(
          _state == _VerifState.webview
              ? 'Identity Verification'
              : AppLocalizations.of(context)!.photoVerification,
        ),
      ),
      body: SafeArea(child: _buildStep(context, accent)),
    );
  }

  Widget _buildStep(BuildContext context, Color accent) {
    switch (_state) {
      case _VerifState.intro:
        return _IntroStep(
          accent: accent,
          onStart: _startVerification,
        );
      case _VerifState.creatingSession:
        return _LoadingStep(accent: accent, message: 'Preparing your verification…');
      case _VerifState.webview:
        return _buildWebView();
      case _VerifState.confirming:
        return _LoadingStep(accent: accent, message: 'Confirming your verification…');
      case _VerifState.success:
        return _SuccessStep(
          accent: accent,
          idVerified: _result?.idVerified ?? false,
          onClose: () => context.pop(),
        );
      case _VerifState.failed:
        return _FailedStep(
          accent: accent,
          errorMessage: _errorMessage,
          onRetry: _startVerification,
          onCancel: () => context.pop(),
        );
    }
  }

  // ── Session creation ──────────────────────────────────────────────────────

  Future<void> _startVerification() async {
    setState(() {
      _state = _VerifState.creatingSession;
      _errorMessage = null;
    });

    try {
      final session =
          await ref.read(verificationRepositoryProvider).createLivenessSession();
      if (!mounted) return;

      _session = session;

      if (session.isPersona && session.hostedUrl != null) {
        _setupWebView(session.hostedUrl!);
        setState(() => _state = _VerifState.webview);
      } else if (session.isRekognition) {
        // Rekognition: the session was created server-side; confirm it directly.
        // The FaceLivenessDetector native widget requires Amplify/Cognito, which
        // is handled via the backend confidence gate. Confirm triggers the result.
        _confirmSession(session.sessionId);
      } else {
        setState(() {
          _errorMessage = 'Provider "${session.provider}" is not yet supported in this app version.';
          _state = _VerifState.failed;
        });
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _state = _VerifState.failed;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Could not start verification. Please check your connection and try again.';
        _state = _VerifState.failed;
      });
    }
  }

  // ── WebView setup (Persona) ───────────────────────────────────────────────

  void _setupWebView(String url) {
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            final uri = Uri.tryParse(request.url);
            if (uri != null &&
                uri.scheme == _personaRedirectScheme &&
                uri.host == _personaRedirectHost) {
              // Persona completed/cancelled — extract inquiry-id
              final inquiryId = uri.queryParameters['inquiry-id'] ??
                  uri.queryParameters['inquiry_id'];
              _onPersonaRedirect(inquiryId);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onWebResourceError: (error) {
            if (!mounted) return;
            setState(() {
              _errorMessage = 'Verification page failed to load. Please try again.';
              _state = _VerifState.failed;
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(url));

    _webViewController = controller;
  }

  Widget _buildWebView() {
    if (_webViewController == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return WebViewWidget(controller: _webViewController!);
  }

  // ── Confirm session with backend ──────────────────────────────────────────

  void _onPersonaRedirect(String? inquiryId) {
    final id = inquiryId ?? _session?.sessionId;
    if (id == null || id.isEmpty) {
      setState(() {
        _errorMessage = 'Verification did not return an inquiry ID. Please try again.';
        _state = _VerifState.failed;
      });
      return;
    }
    _confirmSession(id);
  }

  Future<void> _confirmSession(String sessionId) async {
    setState(() {
      _state = _VerifState.confirming;
      _errorMessage = null;
    });

    try {
      final result = await ref
          .read(verificationRepositoryProvider)
          .confirmLivenessSession(sessionId, provider: _session?.provider);
      if (!mounted) return;
      _result = result;
      setState(() => _state = _VerifState.success);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _state = _VerifState.failed;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Verification confirmation failed. Please try again.';
        _state = _VerifState.failed;
      });
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
    return Padding(
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
            "We use a secure, guided flow to verify your government ID and confirm it's really you with a selfie. "
            'This keeps Shubhmilan safe and trustworthy.',
            style: AppTypography.bodyMedium,
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 20),
          _BulletPoint(icon: Icons.credit_card_rounded, label: 'Photograph your Aadhaar, PAN, Passport or Driving Licence'),
          _BulletPoint(icon: Icons.face_retouching_natural, label: 'Take a quick selfie — no blink challenge needed'),
          _BulletPoint(icon: Icons.lock_outline_rounded, label: 'Your data is encrypted and never shared with other users'),
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

class _BulletPoint extends StatelessWidget {
  const _BulletPoint({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: accent),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: AppTypography.bodySmall),
          ),
        ],
      ),
    );
  }
}

class _LoadingStep extends StatelessWidget {
  const _LoadingStep({required this.accent, required this.message});
  final Color accent;
  final String message;

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
          Text(message, style: AppTypography.titleMedium),
        ],
      ),
    );
  }
}

class _SuccessStep extends StatelessWidget {
  const _SuccessStep({
    required this.accent,
    required this.idVerified,
    required this.onClose,
  });
  final Color accent;
  final bool idVerified;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.verified_rounded, size: 80, color: accent)
              .animate()
              .scale(begin: const Offset(0.5, 0.5), end: const Offset(1, 1))
              .fadeIn(),
          const SizedBox(height: 24),
          Text(
            idVerified ? 'Identity verified' : 'Selfie verified',
            style: AppTypography.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            idVerified
                ? 'Your ID and selfie have been verified. Your profile will show a verified badge.'
                : 'Your selfie has been verified. Your profile will show a verified badge.',
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
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded, size: 64, color: accent),
          const SizedBox(height: 24),
          Text(
            "Verification didn't complete",
            style: AppTypography.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Make sure you have a stable internet connection and try again.',
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
