import 'package:hive_flutter/hive_flutter.dart';
import 'package:sigara_defteri/models/smoke_entry.dart';

class StorageService {
  static const _boxName = 'smoke_entries';

  static StorageService? _instance;
  static StorageService get instance {
    assert(_instance != null, 'StorageService.init() çağrılmadan önce kullanılamaz.');
    return _instance!;
  }

  StorageService._();

  static Future<void> init() async {
    await Hive.initFlutter();
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(SmokeEntryAdapter());
    }
    await Hive.openBox<SmokeEntry>(_boxName);
    _instance = StorageService._();
  }

  Box<SmokeEntry> get _box => Hive.box<SmokeEntry>(_boxName);

  // ── CRUD ────────────────────────────────────────────────────────────────────

  Future<void> addEntry(SmokeEntry entry) async {
    await _box.put(entry.id, entry);
  }

  Future<void> deleteEntry(String id) async {
    await _box.delete(id);
  }

  List<SmokeEntry> getAllEntries() {
    return _box.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  List<SmokeEntry> getEntriesByDate(DateTime date) {
    return _box.values.where((e) {
      return e.createdAt.year == date.year &&
          e.createdAt.month == date.month &&
          e.createdAt.day == date.day;
    }).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  // ── Bugün ────────────────────────────────────────────────────────────────────

  List<SmokeEntry> getTodayEntries() => getEntriesByDate(DateTime.now());

  int getTodayCount() =>
      getTodayEntries().fold(0, (sum, e) => sum + e.amount);

  // ── N-Gün aralıkları ─────────────────────────────────────────────────────────

  /// Son [n] günün kayıtları (bugün dahil), eskiden yeniye sıralı.
  List<SmokeEntry> getEntriesForLastNDays(int n) {
    final cutoff = _today().subtract(Duration(days: n - 1));
    return _box.values.where((e) {
      final d = DateTime(e.createdAt.year, e.createdAt.month, e.createdAt.day);
      return !d.isBefore(cutoff);
    }).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  /// Son [days] günün günlük toplam adetleri.
  /// Dönen map eskiden yeniye sıralı (en eski = [days-1] gün önce, en yeni = bugün).
  Map<DateTime, int> getDailyTotals(int days) {
    final now = _today();
    final map = <DateTime, int>{};
    for (int i = days - 1; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      map[day] = getEntriesByDate(day).fold(0, (s, e) => s + e.amount);
    }
    return map;
  }

  /// Tetikleyici bazında adet dağılımı (son [days] gün).
  Map<String, int> getTriggerDistribution({int days = 30}) {
    final entries = getEntriesForLastNDays(days);
    final map = <String, int>{};
    for (final e in entries) {
      if (e.trigger != null && e.trigger!.isNotEmpty) {
        map[e.trigger!] = (map[e.trigger!] ?? 0) + e.amount;
      }
    }
    return map;
  }

  // ── Maliyet hesaplamaları ─────────────────────────────────────────────────────

  double getTodayCost(double fallbackPrice, int perPack) =>
      _computeCost(getTodayEntries(), fallbackPrice, perPack);

  double getWeeklyCost(double fallbackPrice, int perPack) =>
      _computeCost(getEntriesForLastNDays(7), fallbackPrice, perPack);

  double getMonthlyCost(double fallbackPrice, int perPack) {
    final now = DateTime.now();
    final entries = _box.values.where(
      (e) => e.createdAt.year == now.year && e.createdAt.month == now.month,
    );
    return _computeCost(entries, fallbackPrice, perPack);
  }

  double getYearlyCost(double fallbackPrice, int perPack) {
    final now = DateTime.now();
    final entries = _box.values.where((e) => e.createdAt.year == now.year);
    return _computeCost(entries, fallbackPrice, perPack);
  }

  // ── Streak ───────────────────────────────────────────────────────────────────
  //
  // Dünden geriye giderek her günün önceki günden daha az kayıt içerdiği
  // ardışık gün sayısı.  Örnek: dün=8, 2gün=10, 3gün=12, 4gün=10 → streak=2
  //
  int getStreakCount() {
    final now = _today();
    final counts = List.generate(31, (i) {
      final day = now.subtract(Duration(days: i));
      return getEntriesByDate(day).fold(0, (s, e) => s + e.amount);
    });
    int streak = 0;
    for (int i = 1; i < counts.length - 1; i++) {
      if (counts[i] < counts[i + 1]) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  // ── Yardımcılar ──────────────────────────────────────────────────────────────

  DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  double _computeCost(
    Iterable<SmokeEntry> entries,
    double fallbackPrice,
    int perPack,
  ) {
    if (perPack <= 0) return 0;
    return entries.fold(0.0, (sum, e) {
      final price = e.pricePerPack ?? fallbackPrice;
      if (price <= 0) return sum;
      return sum + (price / perPack) * e.amount;
    });
  }
}
