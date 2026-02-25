import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/app_typography.dart';

class ReferralScreen extends StatelessWidget {
  const ReferralScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    const inviteCode = 'DESI-XXXX';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Invite friends'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Give friends a better way to connect',
              style: AppTypography.headlineMedium,
            ).animate().fadeIn().slideY(begin: -0.05, end: 0),
            const SizedBox(height: 8),
            Text(
              'Share your invite code or link. When they join, you both get a reward.',
              style: AppTypography.bodyMedium,
            ).animate().fadeIn(delay: 80.ms),
            const SizedBox(height: 32),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(
                      'Your invite code',
                      style: AppTypography.labelMedium,
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      inviteCode,
                      style: AppTypography.headlineMedium.copyWith(
                        color: accent,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () {
                        Clipboard.setData(const ClipboardData(text: inviteCode));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Code copied')),
                        );
                      },
                      icon: const Icon(Icons.copy),
                      label: const Text('Copy code'),
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.03, end: 0),
            const SizedBox(height: 24),
            Text(
              'Share via',
              style: AppTypography.labelLarge,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await Share.share(
                        'Join me on saathi — sophisticated dating, globally. Use my code: $inviteCode',
                      );
                    },
                    icon: const Icon(Icons.share),
                    label: const Text('Share'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Clipboard.setData(
                      const ClipboardData(
                        text: 'https://saathi.app/i/$inviteCode',
                      ),
                    ),
                    icon: const Icon(Icons.link),
                    label: const Text('Copy link'),
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 32),
            Text(
              'Rewards',
              style: AppTypography.labelLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'You: 1 month Premium when they sign up. Them: 2 weeks free Premium.',
              style: AppTypography.bodySmall,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

