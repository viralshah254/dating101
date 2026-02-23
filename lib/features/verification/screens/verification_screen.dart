import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/constants/app_ctas.dart';

class VerificationScreen extends StatelessWidget {
  const VerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Verification'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AppCTAs.verifyPriority,
              style: AppTypography.headlineMedium,
            ).animate().fadeIn().slideY(begin: -0.05, end: 0),
            const SizedBox(height: 8),
            Text(
              'Verified profiles get more matches. Add one or more verifications below.',
              style: AppTypography.bodyMedium,
            ).animate().fadeIn(delay: 80.ms),
            const SizedBox(height: 32),
            _VerificationTile(
              icon: Icons.badge_outlined,
              title: 'ID verification',
              subtitle: 'Upload a government ID. We match it to your photo.',
              status: VerificationStatus.pending,
              onTap: () => _showIdUpload(context),
              accent: accent,
            ).animate().fadeIn(delay: 120.ms),
            const SizedBox(height: 12),
            _VerificationTile(
              icon: Icons.face_retouching_natural,
              title: 'Face match',
              subtitle: 'Selfie matched to your ID photo.',
              status: VerificationStatus.pending,
              onTap: () {},
              accent: accent,
            ).animate().fadeIn(delay: 160.ms),
            const SizedBox(height: 12),
            _VerificationTile(
              icon: Icons.work_outline,
              title: 'LinkedIn',
              subtitle: 'Connect your LinkedIn to verify work.',
              status: VerificationStatus.pending,
              onTap: () {},
              accent: accent,
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 12),
            _VerificationTile(
              icon: Icons.school_outlined,
              title: 'Education',
              subtitle: 'Verify your university or college.',
              status: VerificationStatus.pending,
              onTap: () {},
              accent: accent,
            ).animate().fadeIn(delay: 240.ms),
            const SizedBox(height: 32),
            Text(
              'Safety score',
              style: AppTypography.labelLarge,
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: 0.2,
              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(accent),
            ),
            const SizedBox(height: 8),
            Text(
              'Complete verifications to increase your safety score and visibility.',
              style: AppTypography.caption,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showIdUpload(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('ID verification', style: AppTypography.headlineSmall),
              const SizedBox(height: 16),
              const Text(
                'Upload a clear photo of your passport or driving licence. We\'ll compare it to your profile photo.',
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () => Navigator.pop(ctx),
                icon: const Icon(Icons.upload_file),
                label: const Text('Choose file'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum VerificationStatus { pending, inReview, verified, failed }

class _VerificationTile extends StatelessWidget {
  const _VerificationTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.onTap,
    required this.accent,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VerificationStatus status;
  final VoidCallback onTap;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: accent),
        ),
        title: Text(title, style: AppTypography.titleMedium),
        subtitle: Text(subtitle, style: AppTypography.bodySmall),
        trailing: status == VerificationStatus.verified
            ? Icon(Icons.check_circle, color: accent)
            : const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
