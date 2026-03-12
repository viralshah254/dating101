import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../mode/app_mode.dart';
import '../mode/mode_provider.dart';
import '../providers/repository_providers.dart';
import '../theme/app_typography.dart';
import '../../features/chat/providers/chat_providers.dart';
import '../../features/requests/providers/requests_providers.dart';
import '../../features/shortlist/providers/shortlist_providers.dart';
import '../../l10n/app_localizations.dart';

/// Mode-aware root shell: 5 tabs with labels/icons for Dating or Matrimony.
/// Dating: Discover, Map, Chats, Likes, Profile.
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
    final theme = Theme.of(context);
    final items = _navItems(mode, l);
    final requestsCount = ref.watch(receivedRequestsCountProvider).valueOrNull ?? 0;
    final shortlistCount = ref.watch(whoShortlistedMeCountProvider).valueOrNull ?? 0;
    final chatUnread = ref.watch(chatUnreadTotalProvider).valueOrNull ?? 0;
    final notificationsUnread =
        ref.watch(navNotificationsUnreadCountProvider).valueOrNull ?? 0;
    final badges = _badgesForMode(
      mode,
      requestsCount,
      shortlistCount,
      chatUnread,
      notificationsUnread,
    );

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(
            top: BorderSide(
              color: theme.colorScheme.outline.withValues(alpha: 0.35),
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

  /// Badge counts per tab index. [Requests, Shortlist, Chats, Notifications] map to mode indices.
  List<int> _badgesForMode(
    AppMode mode,
    int requestsCount,
    int shortlistCount,
    int chatUnread,
    int notificationsUnread,
  ) {
    if (mode == AppMode.dating) {
      return [0, 0, chatUnread, 0, notificationsUnread]; // Profile tab shows notification badge
    }
    return [
      0,
      requestsCount,
      shortlistCount,
      chatUnread,
      notificationsUnread,
    ]; // Requests=1, Shortlist=2, Chats=3, Profile=notifications
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
        _NavItemData(Icons.favorite_border, Icons.favorite, l.navLikes),
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
    final accent = Theme.of(context).colorScheme.primary;
    final color = isSelected
        ? accent
        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55);
    final showBadge = badgeCount > 0;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? accent.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(isSelected ? activeIcon : icon, size: 26, color: color),
                if (showBadge)
                  Positioned(
                    top: -5,
                    right: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.error,
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(color: Theme.of(context).colorScheme.surface, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).colorScheme.error.withValues(alpha: 0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 1),
                          ),
                        ],
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
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
