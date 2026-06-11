import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/providers.dart';
import '../../analytics/data/achievement_service.dart';
import '../../analytics/presentation/profile_stats_screen.dart';
import '../../journal/presentation/journal_list_screen.dart';
import 'dashboard_screen.dart';

class MainLayout extends ConsumerStatefulWidget {
  const MainLayout({super.key});

  @override
  ConsumerState<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends ConsumerState<MainLayout> {
  @override
  void initState() {
    super.initState();
    // Log App Open event in Firebase Analytics on startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(analyticsServiceProvider).logAppOpen();
    });
  }

  @override
  Widget build(BuildContext context) {
    // 1. Listen to user profile to check and unlock achievements in background
    ref.listen(appUserProvider, (previous, next) {
      final user = next.value;
      if (user != null) {
        AchievementService.checkAndUnlock(ref, user);
      }
    });

    final int activeIndex = ref.watch(activeTabProvider);

    final List<Widget> screens = const [
      DashboardScreen(),
      JournalListScreen(),
      ProfileStatsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: activeIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: activeIndex,
        onDestinationSelected: (int index) {
          ref.read(activeTabProvider.notifier).state = index;
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.book_outlined),
            selectedIcon: Icon(Icons.book),
            label: 'Journals',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics),
            label: 'Insights',
          ),
        ],
      ),
    );
  }
}
