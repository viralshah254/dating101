import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../mode/app_mode.dart';
import '../mode/mode_provider.dart';
import '../feature_flags/feature_flags.dart';
import '../providers/repository_providers.dart';
import '../theme/app_tokens.dart';
import '../theme/brand_theme.dart';
import '../../features/chat/providers/chat_providers.dart';
import '../../features/requests/providers/requests_providers.dart';
import '../../features/shortlist/providers/shortlist_providers.dart';
import '../../l10n/app_localizations.dart';

/// Mode-aware root shell with premium frosted-glass bottom navigation.
class RootShell extends ConsumerWidget {
  const RootShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Future.microtask(() {
      ref.read(recordSecurityLocationProvider)();
      ref.read(registerFcmTokenProvider);
    });
    final mode = ref.watch(appModeProvider) ?? AppMode.dating;
    final flags = ref.watch(featureFlagsProvider);
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final brand = theme.extension<BrandTheme>();
    final items = _navItems(mode, flags, l);
    ref.watch(chatRealtimeHubProvider);
    final requestsCount = ref.watch(receivedRequestsCountProvider).valueOrNull ?? 0;
    final shortlistCount = ref.watch(whoShortlistedMeCountProvider).valueOrNull ?? 0;
    final chatUnread = ref.watch(chatNavUnreadCountProvider);
    final messageReqCount = ref.watch(messageRequestsCountProvider).valueOrNull ?? 0;
    final badges = _badgesForMode(
      mode,
      flags,
      requestsCount,
      shortlistCount,
      chatUnread,
      messageReqCount,
    );

    return Scaffold(
      body: navigationShell,
      extendBody: true,
      bottomNavigationBar: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            decoration: BoxDecoration(
              color: brand?.navBarSurface ?? theme.colorScheme.surface.withValues(alpha: 0.92),
              border: Border(
                top: BorderSide(
                  color: brand?.navBarBorder ?? theme.colorScheme.outline.withValues(alpha: 0.2),
                  width: 0.5,
                ),
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
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
        ),
      ),
    );
  }

  List<int> _badgesForMode(
    AppMode mode,
    FeatureFlags flags,
    int requestsCount,
    int shortlistCount,
    int chatUnread,
    int messageReqCount,
  ) {
    // Unread in-app notifications are surfaced on Profile → Notifications, not on the tab icon.
    if (mode == AppMode.dating) {
      return [0, 0, chatUnread + messageReqCount, 0, 0];
    }
    if (flags.mapInMatrimony) {
      return [0, 0, shortlistCount, chatUnread + messageReqCount, 0];
    }
    return [0, requestsCount, shortlistCount, chatUnread + messageReqCount, 0];
  }

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  List<_NavItemData> _navItems(
    AppMode mode,
    FeatureFlags flags,
    AppLocalizations l,
  ) {
    if (mode == AppMode.dating) {
      return [
        _NavItemData(Icons.explore_outlined, Icons.explore, l.navDiscover),
        _NavItemData(Icons.map_outlined, Icons.map, l.navMap),
        _NavItemData(Icons.chat_bubble_outline, Icons.chat_bubble, l.navChats),
        _NavItemData(Icons.favorite_border, Icons.favorite, l.navLikes),
        _NavItemData(Icons.person_outline, Icons.person, l.navProfile),
      ];
    }
    if (flags.mapInMatrimony) {
      return [
        _NavItemData(Icons.explore_outlined, Icons.explore, l.navDiscover),
        _NavItemData(Icons.map_outlined, Icons.map, l.navMap),
        _NavItemData(Icons.star_border_rounded, Icons.star_rounded, l.navShortlist),
        _NavItemData(Icons.chat_bubble_outline, Icons.chat_bubble, l.navChats),
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
    final theme = Theme.of(context);
    final brand = theme.extension<BrandTheme>();
    final accent = theme.colorScheme.primary;
    final muted = brand?.textMuted ?? theme.colorScheme.onSurface.withValues(alpha: 0.45);
    final color = isSelected ? accent : muted;
    final showBadge = badgeCount > 0;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: AppTokens.durationFast,
        curve: AppTokens.curveDecelerate,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? accent.withValues(alpha: 0.10) : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTokens.radius14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedSwitcher(
                  duration: AppTokens.durationFast,
                  child: Icon(
                    isSelected ? activeIcon : icon,
                    key: ValueKey(isSelected),
                    size: 24,
                    color: color,
                  ),
                ),
                if (showBadge)
                  Positioned(
                    top: -5,
                    right: -8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                      constraints: const BoxConstraints(minWidth: 17, minHeight: 17),
                      decoration: BoxDecoration(
                        color: brand?.rose ?? theme.colorScheme.error,
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(
                          color: brand?.navBarSurface ?? theme.colorScheme.surface,
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        badgeCount > 99 ? '99+' : '$badgeCount',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          height: 1.15,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 10.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
