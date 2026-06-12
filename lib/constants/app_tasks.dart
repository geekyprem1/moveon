class AppTaskItem {
  final String id;
  final String title;
  final String icon;
  final String category; // 'Heart' | 'Mind' | 'Body'
  final String healingInsight;
  final String completedVerb;

  const AppTaskItem({
    required this.id,
    required this.title,
    required this.icon,
    required this.category,
    required this.healingInsight,
    required this.completedVerb,
  });
}

class AppTasks {
  AppTasks._();

  static const List<AppTaskItem> defaultTasks = [
    // Heart
    AppTaskItem(
      id: 'write_release',
      title: 'Write to Release',
      icon: '💖',
      category: 'Heart',
      healingInsight: 'Pouring heavy feelings onto paper takes them out of your body.',
      completedVerb: 'Released',
    ),
    AppTaskItem(
      id: 'self_compassion',
      title: 'Gentle Self-Grace',
      icon: '🌸',
      category: 'Heart',
      healingInsight: 'Self-compassion de-escalates the threat response of rejection.',
      completedVerb: 'Graced',
    ),
    // Mind
    AppTaskItem(
      id: 'no_stalking',
      title: 'Protect My Peace',
      icon: '🧘‍♂️',
      category: 'Mind',
      healingInsight: 'Consciously choose to not check their social media today.',
      completedVerb: 'Protected',
    ),
    AppTaskItem(
      id: 'read_comfort',
      title: 'Nourish Your Focus',
      icon: '📚',
      category: 'Mind',
      healingInsight: 'Reading wisdom feeds your brain positive new perspectives.',
      completedVerb: 'Focused',
    ),
    // Body
    AppTaskItem(
      id: 'gentle_walk',
      title: 'Grounding Movement',
      icon: '🚶‍♂️',
      category: 'Body',
      healingInsight: 'Physical movement discharges adrenaline and lowers cortisol.',
      completedVerb: 'Grounded',
    ),
    AppTaskItem(
      id: 'hydrate',
      title: 'Nourish the Vessel',
      icon: '💧',
      category: 'Body',
      healingInsight: 'Emotional distress is dehydrating. Water is physical self-love.',
      completedVerb: 'Nourished',
    ),
  ];
}
