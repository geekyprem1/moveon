class AppTaskItem {
  final String id;
  final String title;
  final String icon;

  const AppTaskItem({
    required this.id,
    required this.title,
    required this.icon,
  });
}

class AppTasks {
  AppTasks._();

  static const List<AppTaskItem> defaultTasks = [
    AppTaskItem(
      id: 'walk',
      title: 'Walk 15 minutes',
      icon: '🚶‍♂️',
    ),
    AppTaskItem(
      id: 'water',
      title: 'Drink Water',
      icon: '💧',
    ),
    AppTaskItem(
      id: 'exercise',
      title: 'Exercise',
      icon: '💪',
    ),
    AppTaskItem(
      id: 'read',
      title: 'Read 10 Pages',
      icon: '📚',
    ),
  ];
}
