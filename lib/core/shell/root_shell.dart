import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../mode/app_mode.dart';
import '../mode/mode_provider.dart';
import '../providers/repository_providers.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../../features/chat/providers/chat_providers.dart';
import '../../features/requests/providers/requests_providers.dart';
import '../../features/shortlist/providers/shortlist_providers.dart';
import '../../l10n/app_localizations.dart';

/// Mode-aware root shell: 5 tabs with labels/icons for Dating or Matrimony.
/// Dating: Discover, Map, Chats, Communities, Profile.
/// Matrimony: Discover, Requests, Shortlist, Chats, Profile.
class RootShell extends ConsumerWidget {
  const RootShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Defer side effects so we don't modify provider state during build
    Future.microtask(() {
      ref.read(recordSecurityLocationProvider)();
      ref.read(registerFcmTokenProvider);
    });
    final mode = ref.watch(appModeProvider) ?? AppMode.dating;
    final l = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final items = _navItems(mode, l);
    final requestsCount = ref.watch(receivedRequestsCountProvider).valueOrNull ?? 0;
    final shortlistCount = ref.watch(whoShortlistedMeCountProvider).valueOrNull ?? 0;
    final chatUnread = ref.watch(chatUnreadTotalProvider).valueOrNull ?? 0;
    final badges = _badgesForMode(mode, requestsCount, shortlistCount, chatUnread);

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.darkDivider : AppColors.splashPeach.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 16,
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
                    badgeCount: badges[i],
                    onTap: () => _onTap(i),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Badge counts per tab index. [Requests, Shortlist, Chats] map to indices by mode.
  List<int> _badgesForMode(AppMode mode, int requestsCount, int shortlistCount, int chatUnread) {
    if (mode == AppMode.dating) {
      return [0, 0, chatUnread, 0, 0]; // Chats at index 2
    }
    return [0, requestsCount, shortlistCount, chatUnread, 0]; // Requests=1, Shortlist=2, Chats=3
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
      _NavItemData(Icons.explore_outlined, Icons.explore, l.navDiscover),
      _NavItemData(Icons.mail_outline, Icons.mail, l.navRequests),
      _NavItemData(Icons.star_border_rounded, Icons.star_rounded, l.navShortlist),
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
    this.badgeCount = 0,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;
  final int currentIndex;
  final int badgeCount;
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
    final showBadge = badgeCount > 0;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(isSelected ? activeIcon : icon, size: 24, color: color),
                if (showBadge)
                  Positioned(
                    top: -4,
                    right: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                      decoration: BoxDecoration(
                        color: AppColors.lightError,
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(color: Theme.of(context).colorScheme.surface, width: 1),
                      ),
                      child: Text(
                        badgeCount > 99 ? '99+' : '$badgeCount',
                        style: AppTypography.labelSmall.copyWith(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
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
