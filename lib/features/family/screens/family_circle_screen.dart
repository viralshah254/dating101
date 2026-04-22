import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_typography.dart';
import '../providers/family_providers.dart';
import 'family_chat_access_screen.dart';

// ── Screen ─────────────────────────────────────────────────────────────────

class FamilyCircleScreen extends ConsumerStatefulWidget {
  const FamilyCircleScreen({super.key});

  @override
  ConsumerState<FamilyCircleScreen> createState() => _FamilyCircleScreenState();
}

class _FamilyCircleScreenState extends ConsumerState<FamilyCircleScreen>
    with TickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Family Circle'),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Members'),
            Tab(text: 'Mode'),
            Tab(text: 'Preview'),
          ],
          indicatorColor: cs.primary,
          labelColor: cs.primary,
          unselectedLabelColor: cs.onSurface.withValues(alpha: 0.5),
          labelStyle: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w700),
          unselectedLabelStyle: AppTypography.titleSmall,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _MembersTab(),
          _ModeTab(),
          _PreviewTab(),
        ],
      ),
    );
  }
}

// ── Tab 1: Members ─────────────────────────────────────────────────────────

class _MembersTab extends ConsumerStatefulWidget {
  const _MembersTab();

  @override
  ConsumerState<_MembersTab> createState() => _MembersTabState();
}

class _MembersTabState extends ConsumerState<_MembersTab> {
  bool _isGenerating = false;
  String? _inviteUrl;
  String? _selectedRelationship;

  static const _relationships = <(String, IconData, String)>[
    ('parent', Icons.person_outline_rounded, 'Parent'),
    ('sibling', Icons.people_outline_rounded, 'Sibling'),
    ('guardian', Icons.shield_outlined, 'Guardian'),
    ('friend', Icons.groups_rounded, 'Close Friend'),
  ];

  Future<void> _generateInvite() async {
    if (_selectedRelationship == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select the relationship first'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() => _isGenerating = true);
    try {
      final repo = ref.read(familyRepositoryProvider);
      final resp = await repo.inviteMember(relationship: _selectedRelationship!);
      setState(() {
        _inviteUrl = resp['inviteLink'] as String? ?? '';
        _isGenerating = false;
      });
      ref.invalidate(familyMembersProvider);
    } catch (e) {
      if (mounted) {
        setState(() => _isGenerating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not generate link: $e'), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  void _copyLink() {
    if (_inviteUrl == null) return;
    Clipboard.setData(ClipboardData(text: _inviteUrl!));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Invite link copied!'), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final onSurface = cs.onSurface;
    final membersAsync = ref.watch(familyMembersProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Hero section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  cs.primary.withValues(alpha: 0.08),
                  cs.secondary.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: cs.primary.withValues(alpha: 0.12)),
            ),
            child: Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.brandGradient,
                  ),
                  child: const Icon(Icons.family_restroom_rounded, color: Colors.white, size: 28),
                ),
                const SizedBox(height: 12),
                Text(
                  'Involve Your Family',
                  style: AppTypography.headlineSmall.copyWith(fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  'Invite a parent or sibling to view your shortlisted profiles and leave private notes.',
                  style: AppTypography.bodySmall.copyWith(
                    color: onSurface.withValues(alpha: 0.6),
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
              .animate()
              .fadeIn(duration: AppMotion.medium)
              .slideY(begin: 0.2, end: 0),

          const SizedBox(height: 20),

          // Existing members
          membersAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (members) {
              if (members.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Your family members', style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  ...members.map((m) => _MemberTile(member: m, cs: cs, onRevoke: () async {
                    final repo = ref.read(familyRepositoryProvider);
                    await repo.revokeMember(m['id'] as String);
                    ref.invalidate(familyMembersProvider);
                  })),
                  const SizedBox(height: 24),
                ],
              );
            },
          ),

          if (_inviteUrl == null) ...[
            Text('Who are you inviting?', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            ..._relationships.map(((String, IconData, String) r) {
              final (key, icon, label) = r;
              final selected = _selectedRelationship == key;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GestureDetector(
                  onTap: () => setState(() => _selectedRelationship = key),
                  child: AnimatedContainer(
                    duration: 180.ms,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: selected ? cs.primary.withValues(alpha: 0.08) : cs.surfaceContainerHighest.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: selected ? cs.primary.withValues(alpha: 0.4) : cs.outline.withValues(alpha: 0.15),
                        width: selected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(icon, color: selected ? cs.primary : onSurface.withValues(alpha: 0.5)),
                        const SizedBox(width: 14),
                        Text(label, style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w600)),
                        const Spacer(),
                        if (selected) Icon(Icons.check_circle_rounded, color: cs.primary, size: 20),
                      ],
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _isGenerating ? null : _generateInvite,
              icon: _isGenerating
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.link_rounded),
              label: Text(_isGenerating ? 'Generating…' : 'Generate Invite Link'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.indiaGreen.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.indiaGreen.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.check_circle_rounded, color: AppColors.indiaGreen, size: 20),
                      const SizedBox(width: 8),
                      Text('Invite link ready!', style: AppTypography.titleSmall.copyWith(color: AppColors.indiaGreen, fontWeight: FontWeight.w700)),
                      const Spacer(),
                      TextButton(onPressed: () => setState(() => _inviteUrl = null), child: const Text('New invite')),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _inviteUrl!,
                            style: AppTypography.bodySmall.copyWith(color: onSurface.withValues(alpha: 0.7)),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(onTap: _copyLink, child: Icon(Icons.copy_rounded, size: 18, color: cs.primary)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _copyLink,
                    icon: const Icon(Icons.share_rounded, size: 18),
                    label: const Text('Copy & Share Link'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms).scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1)),
          ],
        ],
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  const _MemberTile({required this.member, required this.cs, required this.onRevoke});
  final Map<String, dynamic> member;
  final ColorScheme cs;
  final VoidCallback onRevoke;

  @override
  Widget build(BuildContext context) {
    final relationship = member['relationship'] as String? ?? 'member';
    final accepted = member['accepted'] as bool? ?? false;
    final expired = member['expired'] as bool? ?? false;
    final statusColor = accepted ? AppColors.indiaGreen : (expired ? cs.error : const Color(0xFFF57C00));

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outline.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Icon(Icons.person_rounded, size: 20, color: cs.primary.withValues(alpha: 0.7)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  relationship[0].toUpperCase() + relationship.substring(1),
                  style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  accepted ? 'Active member' : (expired ? 'Invite expired' : 'Pending acceptance'),
                  style: AppTypography.bodySmall.copyWith(color: statusColor, fontSize: 11),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              accepted ? 'Active' : (expired ? 'Expired' : 'Pending'),
              style: AppTypography.labelSmall.copyWith(color: statusColor, fontWeight: FontWeight.w600, fontSize: 10),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(Icons.delete_outline_rounded, size: 18, color: cs.error.withValues(alpha: 0.7)),
            tooltip: 'Revoke',
            onPressed: onRevoke,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }
}

// ── Tab 2: Mode (delegates to FamilyModesScreen inline) ──────────────────

class _ModeTab extends StatelessWidget {
  const _ModeTab();

  @override
  Widget build(BuildContext context) {
    // Embed FamilyModesScreen body inline (without the Scaffold/AppBar)
    return const _EmbeddedModeContent();
  }
}

class _EmbeddedModeContent extends ConsumerStatefulWidget {
  const _EmbeddedModeContent();

  @override
  ConsumerState<_EmbeddedModeContent> createState() => _EmbeddedModeContentState();
}

class _EmbeddedModeContentState extends ConsumerState<_EmbeddedModeContent> {
  String? _selectedMode;

  static const _modes = [
    _ModeInfo(value: 'self', icon: Icons.person_outline_rounded, name: 'Self mode', body: 'You manage everything yourself. Family sees nothing. Full independence.', gradient: LinearGradient(colors: [Color(0xFF1E3A8A), Color(0xFF3B5CC6)])),
    _ModeInfo(value: 'assisted', icon: Icons.family_restroom_rounded, name: 'Family-assisted mode', body: 'Your family can browse, shortlist, and add notes. You control what they see.', gradient: AppColors.premiumGradient, recommended: true),
    _ModeInfo(value: 'hidden', icon: Icons.visibility_off_outlined, name: 'Hidden-from-family mode', body: 'Your profile is completely hidden from people you flag as family members.', gradient: LinearGradient(colors: [Color(0xFF2D6A4F), Color(0xFF40916C)])),
    _ModeInfo(value: 'joint', icon: Icons.shield_outlined, name: 'Joint decision mode', body: 'Both you and a parent must approve before an interest is sent. True consensus.', gradient: AppColors.goldGradient),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final onSurface = cs.onSurface;
    final modeAsync = ref.watch(familyModeNotifierProvider);
    modeAsync.whenData((data) => _selectedMode ??= data['familyMode'] as String? ?? 'self');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('How involved should your family be?', style: AppTypography.headlineSmall.copyWith(fontWeight: FontWeight.w700, height: 1.2)),
          const SizedBox(height: 8),
          Text('Switch anytime. Your private chats always stay private.', style: AppTypography.bodyMedium.copyWith(color: onSurface.withValues(alpha: 0.55))),
          const SizedBox(height: 24),
          ...(_modes.asMap().entries.map((e) {
            final mode = e.value;
            final selected = _selectedMode == mode.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () async {
                  setState(() => _selectedMode = mode.value);
                  await ref.read(familyModeNotifierProvider.notifier).patch(familyMode: mode.value);
                },
                child: AnimatedContainer(
                  duration: 200.ms,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: selected ? cs.primary.withValues(alpha: 0.06) : cs.surfaceContainerHighest.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected ? cs.primary.withValues(alpha: 0.4) : cs.outline.withValues(alpha: 0.15),
                      width: selected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(shape: BoxShape.circle, gradient: mode.gradient),
                        child: Icon(mode.icon, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(mode.name, style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w700)),
                                if (mode.recommended) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(gradient: AppColors.brandGradient, borderRadius: BorderRadius.circular(6)),
                                    child: const Text('Most used', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w700)),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(mode.body, style: AppTypography.bodySmall.copyWith(color: onSurface.withValues(alpha: 0.6), height: 1.4)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        selected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                        color: selected ? cs.primary : onSurface.withValues(alpha: 0.2),
                        size: 22,
                      ),
                    ],
                  ),
                ),
              ).animate(delay: Duration(milliseconds: e.key * 70)).fadeIn(duration: 280.ms),
            );
          })),
          const SizedBox(height: 16),
          // Chat access shortcut
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FamilyChatAccessScreen())),
            icon: const Icon(Icons.lock_outline_rounded, size: 18),
            label: const Text('Manage chat privacy →'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeInfo {
  const _ModeInfo({required this.value, required this.icon, required this.name, required this.body, required this.gradient, this.recommended = false});
  final String value;
  final IconData icon;
  final String name;
  final String body;
  final LinearGradient gradient;
  final bool recommended;
}

// ── Tab 3: Preview (parent's view / your view) ────────────────────────────

class _PreviewTab extends ConsumerStatefulWidget {
  const _PreviewTab();

  @override
  ConsumerState<_PreviewTab> createState() => _PreviewTabState();
}

class _PreviewTabState extends ConsumerState<_PreviewTab> {
  bool _showParentView = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final onSurface = cs.onSurface;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'What your family sees',
            style: AppTypography.headlineSmall.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Toggle between what you see and what your family members see.',
            style: AppTypography.bodyMedium.copyWith(color: onSurface.withValues(alpha: 0.55)),
          ),
          const SizedBox(height: 20),

          // Toggle
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _showParentView = true),
                    child: AnimatedContainer(
                      duration: 200.ms,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _showParentView ? cs.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Text(
                        'Parent\'s view',
                        textAlign: TextAlign.center,
                        style: AppTypography.titleSmall.copyWith(
                          color: _showParentView ? Colors.white : onSurface.withValues(alpha: 0.55),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _showParentView = false),
                    child: AnimatedContainer(
                      duration: 200.ms,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: !_showParentView ? cs.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Text(
                        'Your view',
                        textAlign: TextAlign.center,
                        style: AppTypography.titleSmall.copyWith(
                          color: !_showParentView ? Colors.white : onSurface.withValues(alpha: 0.55),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          AnimatedSwitcher(
            duration: 300.ms,
            child: _showParentView
                ? _ParentView(key: const ValueKey('parent'))
                : _UserView(key: const ValueKey('user')),
          ),
        ],
      ),
    );
  }
}

class _ParentView extends StatelessWidget {
  const _ParentView({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final onSurface = cs.onSurface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Shortlist section
        Text(
          'Family shortlist',
          style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          'Your family can view, comment, and shortlist — without seeing your private chats.',
          style: AppTypography.bodySmall.copyWith(color: onSurface.withValues(alpha: 0.55)),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cs.outline.withValues(alpha: 0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('FAMILY SHORTLIST', style: AppTypography.labelSmall.copyWith(letterSpacing: 1, color: onSurface.withValues(alpha: 0.45))),
              const SizedBox(height: 12),
              ...[
                ('A', 'Arjun S., 28', 'Mumbai', 'Good family background ✓', true),
                ('K', 'Karan M., 30', 'Delhi', 'MBA from IIM', false),
                ('D', 'Dev P., 27', 'Pune', 'Engineer — looks promising', false),
              ].map((item) {
                final (initial, name, city, note, shortlisted) = item;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: cs.primary.withValues(alpha: 0.12),
                        child: Text(initial, style: TextStyle(color: cs.primary, fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(name, style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w600)),
                          Text(city, style: AppTypography.bodySmall.copyWith(color: onSurface.withValues(alpha: 0.5))),
                        ]),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(note, style: TextStyle(fontSize: 10, color: onSurface.withValues(alpha: 0.45)), textAlign: TextAlign.right),
                          if (shortlisted)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: AppColors.rosePrimary, borderRadius: BorderRadius.circular(6)),
                              child: const Text('Shortlisted', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
              const Divider(height: 20),
              Center(
                child: OutlinedButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('+ Add note to shortlist'),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Family access expires after 30 days unless renewed.', style: AppTypography.bodySmall.copyWith(color: onSurface.withValues(alpha: 0.45), fontSize: 11)),
              TextButton(onPressed: null, child: const Text('Share profile with family →', style: TextStyle(fontSize: 11))),
            ],
          ),
        ),
      ],
    );
  }
}

class _UserView extends StatelessWidget {
  const _UserView({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final onSurface = cs.onSurface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Private messages', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text('Your conversations are always yours. Family never sees your direct messages.', style: AppTypography.bodySmall.copyWith(color: onSurface.withValues(alpha: 0.55))),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: AppColors.indiaGreen.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const SizedBox(width: 8),
              Icon(Icons.check_circle_outline_rounded, size: 14, color: AppColors.indiaGreen),
              const SizedBox(width: 6),
              Text('Your family cannot see these messages', style: AppTypography.bodySmall.copyWith(color: AppColors.indiaGreen, fontSize: 11)),
              const SizedBox(width: 8),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cs.outline.withValues(alpha: 0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(color: cs.surfaceContainerHighest, borderRadius: BorderRadius.circular(14)),
                  child: Text('Hi! I really liked your profile. What do you enjoy outside of work?', style: AppTypography.bodySmall.copyWith(color: onSurface)),
                ),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(color: AppColors.rosePrimary, borderRadius: BorderRadius.circular(14)),
                  child: Text('Thanks! I love hiking and cooking. You?', style: AppTypography.bodySmall.copyWith(color: Colors.white)),
                ),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(color: cs.surfaceContainerHighest, borderRadius: BorderRadius.circular(14)),
                  child: Text('Same! I hike every weekend around Coorg. Maybe we could plan a call this week?', style: AppTypography.bodySmall.copyWith(color: onSurface)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
