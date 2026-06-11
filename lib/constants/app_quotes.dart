class AppQuotes {
  AppQuotes._();

  static const List<String> emergencyQuotes = [
    "No contact is not about making them miss you. It is about letting go of someone who was comfortable letting you go.",
    "If you text them, you are restarting the clock. Protect the progress you have made so far.",
    "Your future self is begging you to hold on today.",
    "The urge to contact them will pass, whether you message them or not. Let it pass without resetting your progress.",
    "Do not go back to what broke you, expecting it to heal you.",
    "Contacting them will only give you temporary relief followed by a wave of regret. Stay strong.",
    "You cannot heal in the same environment that made you sick. Keep the distance.",
    "Every day of No Contact is a vote of self-respect. Keep voting for yourself.",
    "You survived the breakup; you can survive this urge.",
    "Healing isn't linear. Feeling the urge to reach out doesn't mean you're failing; it just means you are human. Choose yourself anyway.",
    "If you reach out, you are handing them the key to your emotional peace. Keep the key.",
    "Let the silence do the talking.",
    "Closure doesn't come from them. It comes from you accepting that it is over.",
    "If you are looking for a sign to NOT text them, this is it.",
    "Your value does not decrease based on someone's inability to see your worth."
  ];

  static String getRandomQuote() {
    final DateTime now = DateTime.now();
    return emergencyQuotes[now.millisecondsSinceEpoch % emergencyQuotes.length];
  }
}
