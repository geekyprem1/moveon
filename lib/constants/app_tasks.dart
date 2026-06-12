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
      id: 'practice_forgiveness',
      title: 'Practice Self-Forgiveness',
      icon: '🌸',
      category: 'Heart',
      healingInsight: 'Forgiveness is releasing the hope that the past could be different.',
      completedVerb: 'Forgiven',
    ),
    AppTaskItem(
      id: 'closure_reflection',
      title: 'Closure Reflection',
      icon: '🕊️',
      category: 'Heart',
      healingInsight: 'Closure is something you give yourself, not something you find in them.',
      completedVerb: 'Reflected',
    ),
    AppTaskItem(
      id: 'gratitude_moment',
      title: 'Gratitude Moment',
      icon: '✨',
      category: 'Heart',
      healingInsight: 'Gratitude shifts focus from what was lost to what is present.',
      completedVerb: 'Appreciated',
    ),
    AppTaskItem(
      id: 'self_grace',
      title: 'Gentle Self-Grace',
      icon: '🌟',
      category: 'Heart',
      healingInsight: 'Self-compassion de-escalates the threat response of rejection.',
      completedVerb: 'Graced',
    ),
    AppTaskItem(
      id: 'release_memory',
      title: 'Release One Memory',
      icon: '🍃',
      category: 'Heart',
      healingInsight: 'Acknowledge a memory, then gently choose to step back to the present.',
      completedVerb: 'Released',
    ),

    // Mind
    AppTaskItem(
      id: 'protect_peace',
      title: 'Protect My Peace',
      icon: '🧘‍♂️',
      category: 'Mind',
      healingInsight: 'Consciously choose to not check their social media today.',
      completedVerb: 'Protected',
    ),
    AppTaskItem(
      id: 'avoid_social',
      title: 'Avoid Their Social Media',
      icon: '🛡️',
      category: 'Mind',
      healingInsight: 'Breaking contact stops reinforcing old dopamine loops of attachment.',
      completedVerb: 'Protected',
    ),
    AppTaskItem(
      id: 'thought_reframing',
      title: 'Thought Reframing',
      icon: '🧠',
      category: 'Mind',
      healingInsight: 'Reframe a painful belief: "I am learning to walk alone again."',
      completedVerb: 'Reframed',
    ),
    AppTaskItem(
      id: 'read_wisdom',
      title: 'Read Something Wise',
      icon: '📚',
      category: 'Mind',
      healingInsight: 'Reading wisdom feeds your brain positive new perspectives.',
      completedVerb: 'Focused',
    ),
    AppTaskItem(
      id: 'focus_reset',
      title: 'Focus Reset',
      icon: '🎯',
      category: 'Mind',
      healingInsight: 'Direct your attention to a creative task or hobby for 15 minutes.',
      completedVerb: 'Reset',
    ),
    AppTaskItem(
      id: 'mindful_reflection',
      title: 'Mindful Reflection',
      icon: '☁️',
      category: 'Mind',
      healingInsight: 'Observe your thoughts like clouds passing in a silent sky.',
      completedVerb: 'Observed',
    ),

    // Body
    AppTaskItem(
      id: 'grounding_walk',
      title: 'Grounding Walk',
      icon: '🚶‍♂️',
      category: 'Body',
      healingInsight: 'Physical movement discharges adrenaline and lowers cortisol.',
      completedVerb: 'Grounded',
    ),
    AppTaskItem(
      id: 'stretch_session',
      title: 'Stretch Session',
      icon: '🧘‍♀️',
      category: 'Body',
      healingInsight: 'Emotional trauma is stored in tight muscles. Stretch to release it.',
      completedVerb: 'Released',
    ),
    AppTaskItem(
      id: 'deep_breathing',
      title: 'Deep Breathing',
      icon: '🌬️',
      category: 'Body',
      healingInsight: 'Slow, deep breathing activates the vagus nerve and calms panic.',
      completedVerb: 'Breathed',
    ),
    AppTaskItem(
      id: 'hydration_goal',
      title: 'Hydration Goal',
      icon: '💧',
      category: 'Body',
      healingInsight: 'Emotional distress is dehydrating. Water is physical self-love.',
      completedVerb: 'Nourished',
    ),
    AppTaskItem(
      id: 'morning_sunlight',
      title: 'Morning Sunlight',
      icon: '☀️',
      category: 'Body',
      healingInsight: 'Sunlight resets your circadian rhythm and boosts serotonin production.',
      completedVerb: 'Nourished',
    ),
    AppTaskItem(
      id: 'calm_movement',
      title: 'Calm Movement',
      icon: '💃',
      category: 'Body',
      healingInsight: 'Somatic shaking or gentle movement releases stored physical tension.',
      completedVerb: 'Moved',
    ),
  ];

  static List<AppTaskItem> getDailyRituals(DateTime date) {
    // Generate a daily seed based on the date
    final int seed = date.year * 10000 + date.month * 100 + date.day;

    final heartPool = defaultTasks.where((t) => t.category == 'Heart').toList();
    final mindPool = defaultTasks.where((t) => t.category == 'Mind').toList();
    final bodyPool = defaultTasks.where((t) => t.category == 'Body').toList();

    int nextSeed(int s) {
      return (s * 1103515245 + 12345) & 0x7fffffff;
    }

    int s1 = nextSeed(seed);
    int s2 = nextSeed(s1);
    int s3 = nextSeed(s2);

    final h = heartPool[s1 % heartPool.length];
    final m = mindPool[s2 % mindPool.length];
    final b = bodyPool[s3 % bodyPool.length];

    return [h, m, b];
  }
}
