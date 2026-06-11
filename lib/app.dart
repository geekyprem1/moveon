import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'routing/app_router.dart';
import 'theme/app_theme.dart';
import 'providers/providers.dart';

class MoveOnApp extends ConsumerWidget {
  const MoveOnApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);
    final userAsync = ref.watch(appUserProvider);
    final selectedTheme = userAsync.value?.selectedTheme ?? 'classic';
    final themeModeStr = userAsync.value?.themeMode ?? 'system';

    ThemeMode themeMode;
    if (themeModeStr == 'light') {
      themeMode = ThemeMode.light;
    } else if (themeModeStr == 'dark') {
      themeMode = ThemeMode.dark;
    } else {
      themeMode = ThemeMode.system;
    }

    return MaterialApp.router(
      title: 'Move On',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.getTheme(false, selectedTheme),
      darkTheme: AppTheme.getTheme(true, selectedTheme),
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
