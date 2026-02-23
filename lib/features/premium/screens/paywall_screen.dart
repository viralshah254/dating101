import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/constants/app_ctas.dart';

class PaywallScreen extends StatelessWidget {
  const PaywallScreen({super.key});

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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            Text(
              'Unlock more with DesiLink',
              style: AppTypography.displaySmall,
              textAlign: TextAlign.center,
            ).animate().fadeIn().slideY(begin: -0.05, end: 0),
            const SizedBox(height: 8),
            Text(
              AppCTAs.upgradeGlobal,
              style: AppTypography.bodyLarge,
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 80.ms),
            const SizedBox(height: 32),
            _PlanCard(
              title: 'Premium',
              price: '£9.99',
              period: '/month',
              features: const [
                'See who likes you',
                'Unlimited intros',
                'Travel mode: explore other cities',
                'Priority in discovery',
                'Read receipts',
              ],
              accent: accent,
              isPopular: true,
            ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.03, end: 0),
            const SizedBox(height: 12),
            _PlanCard(
              title: 'Boost pack',
              price: '£4.99',
              period: ' one-time',
              features: const [
                '1 profile boost (24h)',
                'Stand out in discovery',
              ],
              accent: accent,
              isPopular: false,
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.03, end: 0),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () {
                // Stripe / IAP
                context.pop();
              },
              child: const Text('Subscribe'),
            ).animate().fadeIn(delay: 250.ms),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {},
              child: const Text('Restore purchases'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.title,
    required this.price,
    required this.period,
    required this.features,
    required this.accent,
    required this.isPopular,
  });
  final String title;
  final String price;
  final String period;
  final List<String> features;
  final Color accent;
  final bool isPopular;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: isPopular ? 2 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isPopular ? BorderSide(color: accent, width: 2) : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isPopular)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Most popular',
                  style: AppTypography.labelSmall.copyWith(color: accent),
                ),
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(title, style: AppTypography.titleLarge),
                const SizedBox(width: 12),
                Text(price, style: AppTypography.headlineSmall.copyWith(color: accent)),
                Text(period, style: AppTypography.bodySmall),
              ],
            ),
            const SizedBox(height: 12),
            ...features.map(
              (f) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, size: 20, color: accent),
                    const SizedBox(width: 8),
                    Expanded(child: Text(f, style: AppTypography.bodySmall)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
