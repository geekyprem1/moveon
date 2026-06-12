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
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: activeIndex,
        onDestinationSelected: (int index) {
          ref.read(hapticServiceProvider).selection();
          ref.read(activeTabProvider.notifier).state = index;
        },
      ),
    );
  }
}

class CustomBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  const CustomBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final destinations = const [
      _NavBarDestination(
        icon: Icons.dashboard_outlined,
        selectedIcon: Icons.dashboard_rounded,
        label: 'Dashboard',
      ),
      _NavBarDestination(
        icon: Icons.book_outlined,
        selectedIcon: Icons.book_rounded,
        label: 'Journals',
      ),
      _NavBarDestination(
        icon: Icons.mail_outline_rounded,
        selectedIcon: Icons.mail_rounded,
        label: 'Letters',
      ),
      _NavBarDestination(
        icon: Icons.analytics_outlined,
        selectedIcon: Icons.analytics_rounded,
        label: 'Insights',
      ),
    ];

    return Container(
      height: 76,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withAlpha(isDark ? 10 : 15),
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(destinations.length, (index) {
            final isSelected = index == selectedIndex;
            final dest = destinations[index];

            return Expanded(
              flex: isSelected ? 32 : 20,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onDestinationSelected(index),
                child: Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: isSelected
                          ? LinearGradient(
                              colors: isDark
                                  ? const [
                                      Color(0xFF2C1E22), // Dark Sakura
                                      Color(0xFF211E26), // Dark Lavender
                                    ]
                                  : const [
                                      Color(0xFFFFF2F5), // Light Sakura
                                      Color(0xFFF3EFF5), // Light Lavender
                                    ],
                            )
                          : null,
                    ),
                    child: AnimatedScale(
                      scale: isSelected ? 1.05 : 1.0,
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutCubic,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isSelected ? dest.selectedIcon : dest.icon,
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurfaceVariant.withAlpha(153),
                            size: 22,
                          ),
                          AnimatedSize(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeOutCubic,
                            child: Row(
                              children: [
                                if (isSelected) ...[
                                  const SizedBox(width: 8),
                                  Text(
                                    dest.label,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: theme.colorScheme.primary,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _NavBarDestination {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const _NavBarDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}
