import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import 'package:pikacircle/core/appwrite/appwrite_providers.dart';
import 'package:pikacircle/features/discovery/presentation/screens/discovery_screen.dart';
import 'package:pikacircle/features/home/presentation/screens/home_screen.dart';
import 'package:pikacircle/features/profile/domain/entities/app_workflow.dart';
import 'package:pikacircle/features/profile/presentation/controllers/profile_controller.dart';
import 'package:pikacircle/features/profile/presentation/screens/profile_screen.dart';
import 'package:pikacircle/features/sessions/presentation/screens/sessions_screen.dart';
import 'package:pikacircle/features/shell/presentation/controllers/shell_controller.dart';
import 'package:pikacircle/features/shell/presentation/widgets/tab_config.dart';
import 'package:pikacircle/features/wallet/presentation/screens/wallet_screen.dart';
import 'package:pikacircle/shared/widgets/placeholder_page.dart';
import 'package:pikacircle/shared/widgets/pika_app_bar.dart';

/// The authenticated app shell: glass app bar, searchable bottom navigation,
/// and an [IndexedStack] of primary feature tabs.
///
/// Refactored from the former monolithic `MainShell`/`_MainShellState` in
/// `main.dart`. Navigation/search state now lives in [ShellController]; the
/// signed-in user's display name comes from [profileControllerProvider] and the
/// host-only "My Sessions" tab is gated on [currentWorkflowProvider].
class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  static const int _findPageIndex = 4;

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_handleSearchQueryChanged);
  }

  static const List<TabConfig> _tabs = [
    TabConfig(
      title: 'Home',
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      message: 'Your activity will appear here.',
      glowColor: Color(0xFF2F6BFF),
    ),
    TabConfig(
      title: 'Play',
      icon: Icons.local_play_outlined,
      activeIcon: Icons.local_play_rounded,
      message: 'Upcoming sessions will appear here.',
      glowColor: Color(0xFF8B5CF6),
    ),
    TabConfig(
      title: 'Sessions',
      icon: Icons.calendar_month_outlined,
      activeIcon: Icons.calendar_month_rounded,
      message: 'Upcoming sessions will appear here.',
      glowColor: Color(0xFF8B5CF6),
    ),
    TabConfig(
      title: 'Wallet',
      icon: Icons.account_balance_wallet_outlined,
      activeIcon: Icons.account_balance_wallet_rounded,
      message: 'Payments and passes will appear here.',
      glowColor: Color(0xFF0EA5E9),
    ),
    TabConfig(
      title: 'Find',
      icon: Icons.search_rounded,
      activeIcon: Icons.search_rounded,
      message: 'Search and discovery will appear here.',
      glowColor: Color(0xFF10B981),
    ),
  ];

  @override
  void dispose() {
    _searchController.removeListener(_handleSearchQueryChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _handleSearchQueryChanged() {
    ref
        .read(shellControllerProvider.notifier)
        .setSearchQuery(_searchController.text);
  }

  void _openProfile() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const ProfileScreen()));
  }

  void _openNotifications() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const PlaceholderPage(
          title: 'Notifications',
          message: 'Your notifications will appear here.',
          icon: Icons.notifications_rounded,
        ),
      ),
    );
  }

  void _setSearchActive(bool active) {
    ref
        .read(shellControllerProvider.notifier)
        .setSearchActive(active, findPageIndex: _findPageIndex);
    if (active) {
      _searchFocusNode.requestFocus();
    } else {
      _searchController.clear();
      ref.read(shellControllerProvider.notifier).setSearchQuery('');
      _searchFocusNode.unfocus();
    }
  }

  void _selectPrimaryTab(int index) {
    ref.read(shellControllerProvider.notifier).selectPrimaryTab(index);
    _searchFocusNode.unfocus();
  }

  Widget _tabBody(TabConfig tab, int index) {
    return switch (index) {
      0 => const HomeScreen(),
      1 => const SessionsScreen(),
      2 => const SessionsScreen(),
      3 => const WalletScreen(),
      _ => const DiscoveryScreen(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final shell = ref.watch(shellControllerProvider);
    final workflow = ref.watch(currentWorkflowProvider);
    final profileAsync = ref.watch(profileControllerProvider);
    final appwriteConfig = ref.watch(appwriteConfigProvider);
    final appwriteStorage = ref.watch(appwriteStorageProvider);
    final initials =
        profileAsync.asData?.value?.user.name
            .trim()
            .split(RegExp(r'\s+'))
            .where((p) => p.isNotEmpty)
            .take(2)
            .map((p) => p[0].toUpperCase())
            .join() ??
        'P';
    final avatarUrl = profileAsync.asData?.value?.user.profilePictureUrl;
    final avatarFileId = profileAsync.asData?.value?.user.profilePictureFileId;

    // The third tab ("Sessions" / "My Sessions") is host-only per the
    // registration workflow doc; relabel it for hosts.
    final isHost = workflow == AppWorkflow.host;

    return GlassScaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      statusBarStyle: GlassStatusBarStyle.auto,
      contentAwareBrightness: true,
      appBar: GlassAppBar(
        centerTitle: false,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        leading: PikaLeadingButton(
          leading: PikaAppBarLeading.profile,
          initials: initials,
          avatarUrl: avatarUrl,
          avatarFileId: avatarFileId,
          avatarBucketId: appwriteConfig.avatarBucketId,
          storage: appwriteStorage,
          onTap: _openProfile,
        ),
        actions: [
          PikaNavButton(icon: CupertinoIcons.bell, onTap: _openNotifications),
        ],
      ),
      bottomBar: GlassSearchableBottomBar(
        selectedIndex: shell.selectedIndex.clamp(0, 3),
        isSearchActive: shell.isSearchActive,
        onTabSelected: _selectPrimaryTab,
        tabs: _tabs.take(4).toList().asMap().entries.map((entry) {
          final tab = entry.value;
          final label = (isHost && entry.key == 2) ? 'My Sessions' : tab.title;
          return GlassBottomBarTab(
            label: label,
            icon: Icon(tab.icon),
            activeIcon: Icon(tab.activeIcon),
            glowColor: tab.glowColor,
          );
        }).toList(),
        tabPillAnchor: GlassTabPillAnchor.start,
        barHeight: 64,
        searchBarHeight: 54,
        tabWidth: 72,
        spacing: 6,
        horizontalPadding: 12,
        verticalPadding: 18,
        selectedIconColor: Theme.of(context).colorScheme.primary,
        searchConfig: GlassSearchBarConfig(
          hintText: 'Find sessions, venues, players',
          controller: _searchController,
          focusNode: _searchFocusNode,
          autoFocusOnExpand: true,
          collapsedTabWidth: 54,
          collapsedLogoBuilder: (_) => const Icon(Icons.layers_rounded),
          searchIcon: const Icon(Icons.search_rounded),
          textInputAction: TextInputAction.search,
          onSearchToggle: _setSearchActive,
          onCancelTap: () => _setSearchActive(false),
        ),
      ),
      body: IndexedStack(
        index: shell.selectedIndex,
        children: _tabs
            .asMap()
            .entries
            .map((entry) => _tabBody(entry.value, entry.key))
            .toList(),
      ),
    );
  }
}
