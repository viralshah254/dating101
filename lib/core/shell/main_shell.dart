import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';
import '../feature_flags/feature_flags.dart';

class MainShell extends ConsumerWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final eventsEnabled = ref.watch(isEventsEnabledProvider);
    final items = _items(l, eventsEnabled);
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                for (var i = 0; i < items.length; i++)
                  _NavItem(
                    icon: items[i].icon,
                    activeIcon: items[i].activeIcon,
                    label: items[i].label,
                    index: i,
                    currentIndex: navigationShell.currentIndex,
                    onTap: () => _onTap(items[i].branchIndex),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  List<_MainShellItem> _items(AppLocalizations l, bool eventsEnabled) {
    final base = <_MainShellItem>[
      _MainShellItem(Icons.explore_outlined, Icons.explore, l.navDiscover, 0),
      _MainShellItem(Icons.map_outlined, Icons.map, l.navMap, 1),
      _MainShellItem(Icons.chat_bubble_outline, Icons.chat_bubble, l.navChats, 2),
      _MainShellItem(Icons.person_outline, Icons.person, l.navProfile, 5),
    ];
    if (!eventsEnabled) return base;
    return [
      _MainShellItem(Icons.explore_outlined, Icons.explore, l.navDiscover, 0),
      _MainShellItem(Icons.map_outlined, Icons.map, l.navMap, 1),
      _MainShellItem(Icons.chat_bubble_outline, Icons.chat_bubble, l.navChats, 2),
      _MainShellItem(Icons.people_outline, Icons.people, l.navCommunities, 3),
      _MainShellItem(Icons.event_outlined, Icons.event, l.navEvents, 4),
      _MainShellItem(Icons.person_outline, Icons.person, l.navProfile, 5),
    ];
  }
}

class _MainShellItem {
  const _MainShellItem(this.icon, this.activeIcon, this.label, this.branchIndex);
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int branchIndex;
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.index,
    required this.currentIndex,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;
  final int currentIndex;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isSelected = index == currentIndex;
    final theme = Theme.of(context);
    final color = isSelected
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurface.withValues(alpha: 0.45);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isSelected ? activeIcon : icon, size: 24, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
