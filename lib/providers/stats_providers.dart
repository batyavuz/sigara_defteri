import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sigara_defteri/providers/smoke_providers.dart';
import 'package:sigara_defteri/services/storage_service.dart';

// ── Günlük toplamlar ─────────────────────────────────────────────────────────

/// Son 7 günün günlük toplamları (eskiden yeniye sıralı).
final weeklyTotalsProvider = Provider<Map<DateTime, int>>((ref) {
  ref.watch(todayEntriesProvider);
  return StorageService.instance.getDailyTotals(7);
});

/// Son 30 günün günlük toplamları.
final monthlyTotalsProvider = Provider<Map<DateTime, int>>((ref) {
  ref.watch(todayEntriesProvider);
  return StorageService.instance.getDailyTotals(30);
});

// ── Tetikleyici dağılımı ──────────────────────────────────────────────────────

/// Son 7 günün tetikleyici dağılımı.
final weeklyTriggerDistProvider = Provider<Map<String, int>>((ref) {
  ref.watch(todayEntriesProvider);
  return StorageService.instance.getTriggerDistribution(days: 7);
});

/// Son 30 günün tetikleyici dağılımı.
final monthlyTriggerDistProvider = Provider<Map<String, int>>((ref) {
  ref.watch(todayEntriesProvider);
  return StorageService.instance.getTriggerDistribution(days: 30);
});

// ── Maliyet raporu ───────────────────────────────────────────────────────────

class CostReport {
  final double today;
  final double week;
  final double month;
  final double year;

  const CostReport({
    required this.today,
    required this.week,
    required this.month,
    required this.year,
  });
}

final costReportProvider = Provider<CostReport>((ref) {
  ref.watch(todayEntriesProvider);
  final settings = ref.watch(settingsProvider);
  final s = StorageService.instance;
  final p = settings.pricePerPack;
  final n = settings.cigsPerPack;
  return CostReport(
    today: s.getTodayCost(p, n),
    week: s.getWeeklyCost(p, n),
    month: s.getMonthlyCost(p, n),
    year: s.getYearlyCost(p, n),
  );
});

// ── Haftalık karşılaştırma ───────────────────────────────────────────────────

class WeeklyComparison {
  final int thisWeek;
  final int lastWeek;
  final double percentChange; // negatif = azalma, pozitif = artış

  const WeeklyComparison({
    required this.thisWeek,
    required this.lastWeek,
    required this.percentChange,
  });

  bool get isDecreasing => percentChange < -0.5;
  bool get isIncreasing => percentChange > 0.5;
}

final weeklyComparisonProvider = Provider<WeeklyComparison>((ref) {
  ref.watch(todayEntriesProvider);
  final totals = StorageService.instance.getDailyTotals(14);
  final vals = totals.values.toList();
  // vals[0..6] = geçen hafta, vals[7..13] = bu hafta
  final lastWeek = vals.take(7).fold(0, (s, v) => s + v);
  final thisWeek = vals.skip(7).fold(0, (s, v) => s + v);
  final pct = lastWeek > 0
      ? (thisWeek - lastWeek) / lastWeek * 100.0
      : 0.0;
  return WeeklyComparison(
    thisWeek: thisWeek,
    lastWeek: lastWeek,
    percentChange: pct,
  );
});

// ── Dashboard mini stats ─────────────────────────────────────────────────────

class WeeklyMini {
  final int total;
  final double cost;
  final double percentChange;

  const WeeklyMini({
    required this.total,
    required this.cost,
    required this.percentChange,
  });
}

final weeklyMiniProvider = Provider<WeeklyMini>((ref) {
  final comparison = ref.watch(weeklyComparisonProvider);
  final cost = ref.watch(costReportProvider);
  return WeeklyMini(
    total: comparison.thisWeek,
    cost: cost.week,
    percentChange: comparison.percentChange,
  );
});
