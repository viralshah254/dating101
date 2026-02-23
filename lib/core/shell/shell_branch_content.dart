import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../mode/app_mode.dart';
import '../mode/mode_provider.dart';
import '../../features/chat/screens/chat_list_screen.dart';
import '../../features/discovery/screens/discovery_screen.dart';
import '../../features/map/screens/map_screen.dart';
import '../../features/matches/screens/matches_screen.dart';
import '../../features/mode_select/screens/mode_select_screen.dart';
import '../../features/profile/screens/profile_settings_screen.dart';
import '../../features/requests/screens/requests_screen.dart';
import '../../features/shortlist/screens/shortlist_screen.dart';
import '../../features/community/screens/community_screen.dart';

/// Renders the correct screen for a shell branch index and current app mode.
/// If mode is null (first run), branch 0 shows ModeSelectScreen.
/// Branch indices: 0=Discover/Matches, 1=Map/Requests, 2=Chats, 3=Communities/Shortlist, 4=Profile.
class ShellBranchContent extends ConsumerWidget {
  const ShellBranchContent({super.key, required this.branchIndex});

  final int branchIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(appModeProvider);

    if (mode == null && branchIndex == 0) {
      return const ModeSelectScreen();
    }
    final effectiveMode = mode ?? AppMode.dating;

    if (effectiveMode == AppMode.dating) {
      switch (branchIndex) {
        case 0:
          return const DiscoveryScreen();
        case 1:
          return const MapScreen();
        case 2:
          return const ChatListScreen();
        case 3:
          return const CommunityScreen();
        case 4:
          return const ProfileSettingsScreen();
        default:
          return const DiscoveryScreen();
      }
    } else {
      // matrimony
      switch (branchIndex) {
        case 0:
          return const MatchesScreen();
        case 1:
          return const RequestsScreen();
        case 2:
          return const ChatListScreen();
        case 3:
          return const ShortlistScreen();
        case 4:
          return const ProfileSettingsScreen();
        default:
          return const MatchesScreen();
      }
    }
  }
}
