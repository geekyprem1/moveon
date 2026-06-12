import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/providers.dart';
import '../../../utils/haptic_service.dart';
import '../../analytics/data/achievement_service.dart';
import '../../analytics/presentation/profile_stats_screen.dart';
import '../../journal/presentation/journal_list_screen.dart';
import '../../letters/presentation/letters_list_screen.dart';
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
    final theme = Theme.of(context);

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
      LettersListScreen(),
      ProfileStatsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: activeIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          height: 80,
          elevation: 0,
          indicatorColor: theme.colorScheme.primaryContainer.withAlpha(102),
          labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>((states) {
            if (states.contains(WidgetState.selected)) {
              return TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.primary,
                letterSpacing: 0.2,
              );
            }
            return TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurfaceVariant.withAlpha(153),
              letterSpacing: 0.2,
            );
          }),
          iconTheme: WidgetStateProperty.resolveWith<IconThemeData>((states) {
            if (states.contains(WidgetState.selected)) {
              return IconThemeData(
                color: theme.colorScheme.primary,
                size: 24,
              );
            }
            return IconThemeData(
              color: theme.colorScheme.onSurfaceVariant.withAlpha(153),
              size: 24,
            );
          }),
        ),
        child: NavigationBar(
          selectedIndex: activeIndex,
          onDestinationSelected: (int index) {
            ref.read(hapticServiceProvider).selection();
            ref.read(activeTabProvider.notifier).state = index;
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard_rounded),
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: Icon(Icons.book_outlined),
              selectedIcon: Icon(Icons.book_rounded),
              label: 'Journals',
            ),
            NavigationDestination(
              icon: Icon(Icons.mail_outline_rounded),
              selectedIcon: Icon(Icons.mail_rounded),
              label: 'Letters',
            ),
            NavigationDestination(
              icon: Icon(Icons.analytics_outlined),
              selectedIcon: Icon(Icons.analytics_rounded),
              label: 'Insights',
            ),
          ],
        ),
      ),
    );
  }
}
