import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../mode/app_mode.dart';
import '../mode/mode_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../../l10n/app_localizations.dart';

/// Mode-aware root shell: 5 tabs with labels/icons for Dating or Matrimony.
/// Dating: Discover, Map, Chats, Communities, Profile.
/// Matrimony: Matches, Requests, Shortlist, Chats, Profile.
class RootShell extends ConsumerWidget {
  const RootShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(appModeProvider) ?? AppMode.dating;
    final l = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final items = _navItems(mode, l);

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
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
                for (int i = 0; i < items.length; i++)
                  _NavItem(
                    icon: items[i].icon,
                    activeIcon: items[i].activeIcon,
                    label: items[i].label,
                    index: i,
                    currentIndex: navigationShell.currentIndex,
                    onTap: () => _onTap(i),
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

  List<_NavItemData> _navItems(AppMode mode, AppLocalizations l) {
    if (mode == AppMode.dating) {
      return [
        _NavItemData(Icons.explore_outlined, Icons.explore, l.navDiscover),
        _NavItemData(Icons.map_outlined, Icons.map, l.navMap),
        _NavItemData(Icons.chat_bubble_outline, Icons.chat_bubble, l.navChats),
        _NavItemData(Icons.people_outline, Icons.people, l.navCommunities),
        _NavItemData(Icons.person_outline, Icons.person, l.navProfile),
      ];
    }
    return [
      _NavItemData(Icons.favorite_border, Icons.favorite, l.navMatches),
      _NavItemData(Icons.mail_outline, Icons.mail, l.navRequests),
      _NavItemData(Icons.bookmark_border, Icons.bookmark, l.navShortlist),
      _NavItemData(Icons.chat_bubble_outline, Icons.chat_bubble, l.navChats),
      _NavItemData(Icons.person_outline, Icons.person, l.navProfile),
    ];
  }
}

class _NavItemData {
  const _NavItemData(this.icon, this.activeIcon, this.label);
  final IconData icon;
  final IconData activeIcon;
  final String label;
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
    final color = isSelected
        ? (Theme.of(context).brightness == Brightness.dark
            ? AppColors.darkAccent
            : AppColors.lightAccent)
        : (Theme.of(context).brightness == Brightness.dark
            ? AppColors.darkTextTertiary
            : AppColors.lightTextTertiary);
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
              style: AppTypography.labelSmall.copyWith(
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
