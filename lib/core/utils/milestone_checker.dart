class Milestone {
  final String id; // unique key for storage
  final String emoji;
  final String message;

  const Milestone({
    required this.id,
    required this.emoji,
    required this.message,
  });
}

List<Milestone> getAvailableMilestones({
  required int totalIncome,
  required int totalExpenses,
  required int daysTracking,
  required bool hasJournalEntry,
  required bool hasSavingsJar,
  required Set<String> alreadyShownIds,
}) {
  final milestones = <Milestone>[];

  if (!alreadyShownIds.contains('first_income') && totalIncome > 0) {
    milestones.add(const Milestone(
      id: 'first_income',
      emoji: '🎉',
      message: "You logged your first income! That's the foundation.",
    ));
  }

  if (!alreadyShownIds.contains('first_expense') && totalExpenses >= 1) {
    milestones.add(const Milestone(
      id: 'first_expense',
      emoji: '📝',
      message: "First expense logged. Awareness starts here.",
    ));
  }

  if (!alreadyShownIds.contains('seven_days') && daysTracking >= 7) {
    milestones.add(const Milestone(
      id: 'seven_days',
      emoji: '🔥',
      message: "7 days of tracking! You're building a real habit.",
    ));
  }

  if (!alreadyShownIds.contains('thirty_days') && daysTracking >= 30) {
    milestones.add(const Milestone(
      id: 'thirty_days',
      emoji: '🌟',
      message: "30 days! A whole month of awareness. That's strength.",
    ));
  }

  if (!alreadyShownIds.contains('ten_expenses') && totalExpenses >= 10) {
    milestones.add(const Milestone(
      id: 'ten_expenses',
      emoji: '📊',
      message: "10 expenses logged. You're really doing this.",
    ));
  }

  if (!alreadyShownIds.contains('first_journal') && hasJournalEntry) {
    milestones.add(const Milestone(
      id: 'first_journal',
      emoji: '📖',
      message: "You wrote your first reflection. That's courage.",
    ));
  }

  if (!alreadyShownIds.contains('savings_jar') && hasSavingsJar) {
    milestones.add(const Milestone(
      id: 'savings_jar',
      emoji: '🐷',
      message: "You added a savings jar. Your future self is smiling.",
    ));
  }

  return milestones;
}
