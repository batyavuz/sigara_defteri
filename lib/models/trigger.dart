class AppTrigger {
  final String id;
  final String label;
  final String emoji;

  const AppTrigger({
    required this.id,
    required this.label,
    required this.emoji,
  });

  static const all = [
    AppTrigger(id: 'stres', label: 'Stres', emoji: '😤'),
    AppTrigger(id: 'kahve', label: 'Kahve/Çay', emoji: '☕'),
    AppTrigger(id: 'sikilma', label: 'Sıkılma', emoji: '😑'),
    AppTrigger(id: 'sosyal', label: 'Sosyal', emoji: '👥'),
    AppTrigger(id: 'yemek', label: 'Yemek Sonrası', emoji: '🍽️'),
    AppTrigger(id: 'alkol', label: 'Alkol', emoji: '🍺'),
    AppTrigger(id: 'otomatik', label: 'Otomatik', emoji: '🔁'),
    AppTrigger(id: 'diger', label: 'Diğer', emoji: '•••'),
  ];

  static AppTrigger? findById(String? id) {
    if (id == null) return null;
    try {
      return all.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }
}
