import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/repository_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../providers/family_providers.dart';

/// Deep-link landing screen for `app.shubhmilan.app/family/handover?token=XYZ`.
/// The user must be signed in; if not, they are sent to login first.
/// On success: the profile transfers to their account and they go to the discovery feed.
class HandoverAcceptScreen extends ConsumerStatefulWidget {
  const HandoverAcceptScreen({super.key, required this.token});

  final String token;

  @override
  ConsumerState<HandoverAcceptScreen> createState() => _HandoverAcceptScreenState();
}

class _HandoverAcceptScreenState extends ConsumerState<HandoverAcceptScreen> {
  _State _state = _State.idle;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _acceptHandover());
  }

  Future<void> _acceptHandover() async {
    setState(() {
      _state = _State.loading;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(familyRepositoryProvider);
      final result = await repo.acceptHandover(widget.token);
      // Save new credentials issued by the handover endpoint so the app
      // immediately authenticates as the profile subject (not the managing parent).
      final accessToken = result['accessToken'] as String?;
      final refreshToken = result['refreshToken'] as String?;
      final userId = result['userId'] as String?;
      if (accessToken != null && refreshToken != null && userId != null) {
        await ref.read(tokenStorageProvider).save(
          accessToken: accessToken,
          refreshToken: refreshToken,
          userId: userId,
        );
      }
      if (mounted) setState(() => _state = _State.success);
      // Give user a moment to see the success state before navigating
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) context.go('/');
    } catch (e) {
      if (mounted) {
        setState(() {
          _state = _State.error;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AnimatedSwitcher(
                duration: 400.ms,
                child: switch (_state) {
                  _State.idle || _State.loading => _LoadingView(key: const ValueKey('loading')),
                  _State.success => _SuccessView(key: const ValueKey('success')),
                  _State.error => _ErrorView(
                      key: const ValueKey('error'),
                      message: _errorMessage ?? 'Something went wrong. Please try again.',
                      onRetry: _acceptHandover,
                    ),
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _State { idle, loading, success, error }

class _LoadingView extends StatelessWidget {
  const _LoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AppColors.brandGradient),
          child: const Padding(
            padding: EdgeInsets.all(20),
            child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white),
          ),
        ).animate().scale(begin: const Offset(0.7, 0.7), end: const Offset(1, 1), duration: 400.ms, curve: Curves.elasticOut),
        const SizedBox(height: 24),
        Text(
          'Transferring your profile…',
          style: AppTypography.headlineSmall.copyWith(fontWeight: FontWeight.w700),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'This takes just a moment. Your parent will automatically become a family member.',
          style: AppTypography.bodyMedium.copyWith(color: Colors.grey.shade600),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _SuccessView extends StatelessWidget {
  const _SuccessView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.indiaGreen.withValues(alpha: 0.1),
          ),
          child: const Icon(Icons.check_rounded, color: AppColors.indiaGreen, size: 40),
        )
            .animate()
            .scale(begin: const Offset(0.5, 0.5), end: const Offset(1.15, 1.15), duration: 300.ms, curve: Curves.easeOut)
            .then()
            .scale(begin: const Offset(1.15, 1.15), end: const Offset(1, 1), duration: 150.ms),
        const SizedBox(height: 24),
        Text(
          'Profile transferred!',
          style: AppTypography.headlineSmall.copyWith(fontWeight: FontWeight.w700, color: AppColors.indiaGreen),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'This profile is now yours. Your family stays connected as a family circle member — and your chats are private by default.',
          style: AppTypography.bodyMedium.copyWith(color: Colors.grey.shade600),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Text(
          'Taking you to your profile…',
          style: AppTypography.bodySmall.copyWith(color: Colors.grey.shade400),
          textAlign: TextAlign.center,
        ),
      ],
    ).animate().fadeIn(duration: 400.ms);
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({super.key, required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.red.shade50,
          ),
          child: Icon(Icons.error_outline_rounded, color: Colors.red.shade400, size: 40),
        ),
        const SizedBox(height: 24),
        Text(
          'Could not transfer profile',
          style: AppTypography.headlineSmall.copyWith(fontWeight: FontWeight.w700),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          message,
          style: AppTypography.bodyMedium.copyWith(color: Colors.grey.shade600),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Try again'),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms);
  }
}
