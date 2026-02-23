import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/constants/app_ctas.dart';

class ProfileWizardScreen extends StatefulWidget {
  const ProfileWizardScreen({super.key});

  @override
  State<ProfileWizardScreen> createState() => _ProfileWizardScreenState();
}

class _ProfileWizardScreenState extends State<ProfileWizardScreen> {
  final _pageController = PageController();
  int _currentStep = 0;
  int _profileCompletion = 0;
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _promptController = TextEditingController();
  final List<String> _selectedLifestyleTags = [];

  static const _stepTitles = ['Basic info', 'Photos', 'Interests & prompts', 'Voice intro'];
  static const _lifestyleTags = [
    'Coffee lover', 'Fitness', 'Travel', 'Foodie', 'Arts', 'Music',
    'Reading', 'Yoga', 'Tech', 'Volunteering', 'Dining out', 'Outdoors',
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _bioController.dispose();
    _promptController.dispose();
    super.dispose();
  }

  void _recalcProgress() {
    int done = 0;
    if (_nameController.text.trim().isNotEmpty) done += 20;
    if (_bioController.text.trim().isNotEmpty) done += 15;
    if (_selectedLifestyleTags.isNotEmpty) done += 15;
    if (_promptController.text.trim().isNotEmpty) done += 20;
    setState(() => _profileCompletion = done.clamp(0, 100));
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Your profile'),
            Text(
              _stepTitles[_currentStep],
              style: AppTypography.bodySmall.copyWith(
                color: onSurface.withValues(alpha: 0.7),
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          if (_profileCompletion > 0)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  '$_profileCompletion%',
                  style: AppTypography.labelLarge.copyWith(color: accent),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: _profileCompletion / 100,
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(accent),
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _QuickProfileStep(
                  nameController: _nameController,
                  bioController: _bioController,
                  onChanged: _recalcProgress,
                ),
                _PhotosStep(onChanged: _recalcProgress),
                _PromptsAndTagsStep(
                  promptController: _promptController,
                  selectedTags: _selectedLifestyleTags,
                  lifestyleTags: _lifestyleTags,
                  onTagsChanged: (tags) {
                    setState(() {
                      _selectedLifestyleTags
                        ..clear()
                        ..addAll(tags);
                      _recalcProgress();
                    });
                  },
                  onPromptChanged: _recalcProgress,
                ),
                _VoiceIntroStep(),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                if (_profileCompletion < 70)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      AppCTAs.completeProfile.replaceFirst('%s%', _profileCompletion.toString()),
                      style: AppTypography.labelMedium.copyWith(
                        color: onSurface.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      if (_currentStep < 3) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                        setState(() => _currentStep++);
                      } else {
                        context.go('/');
                      }
                    },
                    child: Text(_currentStep < 3 ? 'Next' : 'Finish'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickProfileStep extends StatelessWidget {
  const _QuickProfileStep({
    required this.nameController,
    required this.bioController,
    required this.onChanged,
  });
  final TextEditingController nameController;
  final TextEditingController bioController;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Basic info',
            style: AppTypography.headlineMedium.copyWith(
              color: onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tell others who you are. You can edit this anytime.',
            style: AppTypography.bodyMedium.copyWith(
              color: onSurface.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Your name', style: AppTypography.labelLarge.copyWith(color: onSurface)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      hintText: 'e.g. Priya, Arjun',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => onChanged(),
                  ),
                  const SizedBox(height: 20),
                  Text('A few lines about you', style: AppTypography.labelLarge.copyWith(color: onSurface)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: bioController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Share what matters to you — work, interests, what you\'re looking for.',
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => onChanged(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotosStep extends StatelessWidget {
  const _PhotosStep({required this.onChanged});
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final primary = Theme.of(context).colorScheme.primary;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Add your photos',
            style: AppTypography.headlineMedium.copyWith(
              color: onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Add at least 2 photos. Profiles with clear face photos get more matches.',
            style: AppTypography.bodyLarge.copyWith(
              color: onSurface.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: primary.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.lightbulb_outline, size: 20, color: primary),
                    const SizedBox(width: 8),
                    Text(
                      'Tips for great photos',
                      style: AppTypography.labelLarge.copyWith(color: onSurface),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '• Use clear, well-lit photos\n• Include at least one clear face photo\n• Avoid group photos for your main picture\n• Smile — it helps others connect',
                  style: AppTypography.bodySmall.copyWith(
                    color: onSurface.withValues(alpha: 0.85),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.85,
            children: [
              _PhotoSlot(isPrimary: true, onTap: () => onChanged()),
              _PhotoSlot(isPrimary: false, onTap: () => onChanged()),
              _PhotoSlot(isPrimary: false, onTap: () => onChanged()),
              _PhotoSlot(isPrimary: false, onTap: () => onChanged()),
              _PhotoSlot(isPrimary: false, onTap: () => onChanged()),
              _PhotoSlot(isPrimary: false, onTap: () => onChanged()),
            ],
          ),
        ],
      ),
    );
  }
}

class _PhotoSlot extends StatelessWidget {
  const _PhotoSlot({required this.onTap, this.isPrimary = false});
  final VoidCallback onTap;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isPrimary ? primary : Theme.of(context).dividerColor,
            width: isPrimary ? 2 : 1,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              Icons.add_a_photo,
              size: 32,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            if (isPrimary)
              Positioned(
                bottom: 6,
                left: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Main',
                    style: AppTypography.labelSmall.copyWith(color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PromptsAndTagsStep extends StatelessWidget {
  const _PromptsAndTagsStep({
    required this.promptController,
    required this.selectedTags,
    required this.lifestyleTags,
    required this.onTagsChanged,
    required this.onPromptChanged,
  });
  final TextEditingController promptController;
  final List<String> selectedTags;
  final List<String> lifestyleTags;
  final ValueChanged<List<String>> onTagsChanged;
  final VoidCallback onPromptChanged;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Conversation starter',
            style: AppTypography.titleMedium.copyWith(
              color: onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Answer a prompt so matches have something to talk about.',
            style: AppTypography.bodySmall.copyWith(color: onSurface.withValues(alpha: 0.8)),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: promptController,
            maxLines: 2,
            decoration: const InputDecoration(
              hintText: 'e.g. Best way to spend a Sunday? Chai and a book. Or: My ideal weekend is…',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => onPromptChanged(),
          ),
          const SizedBox(height: 28),
          Text(
            'Interests',
            style: AppTypography.titleMedium.copyWith(
              color: onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Select any that describe you. Helps with better matches.',
            style: AppTypography.bodySmall.copyWith(color: onSurface.withValues(alpha: 0.8)),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: lifestyleTags.map((tag) {
              final selected = selectedTags.contains(tag);
              return FilterChip(
                label: Text(tag),
                selected: selected,
                onSelected: (_) {
                  final next = List<String>.from(selectedTags);
                  if (selected) {
                    next.remove(tag);
                  } else {
                    next.add(tag);
                  }
                  onTagsChanged(next);
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _VoiceIntroStep extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final primary = Theme.of(context).colorScheme.primary;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),
          Text(
            'Voice intro',
            style: AppTypography.headlineMedium.copyWith(
              color: onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Record a short voice note (up to 30 seconds) so matches can hear your personality. It makes your profile stand out.',
            style: AppTypography.bodyLarge.copyWith(
              color: onSurface.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 32),
          Center(
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.mic_none, size: 64, color: primary),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.mic, size: 20),
              label: const Text('Record your intro'),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: () {},
              child: const Text('Skip for now'),
            ),
          ),
        ],
      ),
    );
  }
}
