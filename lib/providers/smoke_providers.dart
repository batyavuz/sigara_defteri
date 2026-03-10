import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sigara_defteri/models/smoke_entry.dart';
import 'package:sigara_defteri/services/storage_service.dart';
import 'package:sigara_defteri/services/widget_service.dart';
import 'package:sigara_defteri/services/notification_service.dart';

// ── Settings ─────────────────────────────────────────────────────────────────

class SettingsState {
  final double pricePerPack;
  final int cigsPerPack;
  final DateTime? quitDate;
  final bool reminderEnabled;
  final int reminderHour;
  final int reminderMinute;

  const SettingsState({
    this.pricePerPack = 0.0,
    this.cigsPerPack = 20,
    this.quitDate,
    this.reminderEnabled = false,
    this.reminderHour = 20,
    this.reminderMinute = 0,
  });

  double get pricePerCig => cigsPerPack > 0 ? pricePerPack / cigsPerPack : 0;

  SettingsState copyWith({
    double? pricePerPack,
    int? cigsPerPack,
    DateTime? quitDate,
    bool clearQuitDate = false,
    bool? reminderEnabled,
    int? reminderHour,
    int? reminderMinute,
  }) {
    return SettingsState(
      pricePerPack: pricePerPack ?? this.pricePerPack,
      cigsPerPack: cigsPerPack ?? this.cigsPerPack,
      quitDate: clearQuitDate ? null : (quitDate ?? this.quitDate),
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderHour: reminderHour ?? this.reminderHour,
      reminderMinute: reminderMinute ?? this.reminderMinute,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(const SettingsState()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final quitStr = prefs.getString('quit_date');
    state = SettingsState(
      pricePerPack: prefs.getDouble('price_per_pack') ?? 0.0,
      cigsPerPack: prefs.getInt('cigs_per_pack') ?? 20,
      quitDate: quitStr != null ? DateTime.tryParse(quitStr) : null,
      reminderEnabled: prefs.getBool('reminder_enabled') ?? false,
      reminderHour: prefs.getInt('reminder_hour') ?? 20,
      reminderMinute: prefs.getInt('reminder_minute') ?? 0,
    );
    if (state.reminderEnabled) {
      await NotificationService.scheduleDailyReminder(
        hour: state.reminderHour,
        minute: state.reminderMinute,
      );
    }
  }

  Future<void> setQuitDate(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('quit_date', date.toIso8601String());
    state = state.copyWith(quitDate: date);
  }

  Future<void> clearQuitDate() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('quit_date');
    state = state.copyWith(clearQuitDate: true);
  }

  Future<void> setPricePerPack(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('price_per_pack', value);
    state = state.copyWith(pricePerPack: value);
  }

  Future<void> setCigsPerPack(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('cigs_per_pack', value);
    state = state.copyWith(cigsPerPack: value);
  }

  Future<void> setReminderEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('reminder_enabled', enabled);
    state = state.copyWith(reminderEnabled: enabled);
    if (enabled) {
      await NotificationService.scheduleDailyReminder(
        hour: state.reminderHour,
        minute: state.reminderMinute,
      );
    } else {
      await NotificationService.cancelDailyReminder();
    }
  }

  Future<void> setReminderTime(int hour, int minute) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('reminder_hour', hour);
    await prefs.setInt('reminder_minute', minute);
    state = state.copyWith(reminderHour: hour, reminderMinute: minute);
    if (state.reminderEnabled) {
      await NotificationService.scheduleDailyReminder(hour: hour, minute: minute);
    }
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>(
  (ref) => SettingsNotifier(),
);

// ── Bugünkü Kayıtlar ─────────────────────────────────────────────────────────

class TodayEntriesNotifier extends StateNotifier<List<SmokeEntry>> {
  TodayEntriesNotifier() : super(StorageService.instance.getTodayEntries());

  void refresh() {
    state = StorageService.instance.getTodayEntries();
  }

  Future<void> add(SmokeEntry entry) async {
    await StorageService.instance.addEntry(entry);
    refresh();
    refreshHomeWidget();
  }

  Future<void> remove(String id) async {
    await StorageService.instance.deleteEntry(id);
    refresh();
    refreshHomeWidget();
  }
}

final todayEntriesProvider =
    StateNotifierProvider<TodayEntriesNotifier, List<SmokeEntry>>(
  (ref) => TodayEntriesNotifier(),
);

// ── Türetilmiş providerlar ───────────────────────────────────────────────────

/// Bugün toplam içilen adet
final todayCountProvider = Provider<int>((ref) {
  return ref.watch(todayEntriesProvider).fold(0, (s, e) => s + e.amount);
});

/// Azalma streak günü
final streakProvider = Provider<int>((ref) {
  ref.watch(todayEntriesProvider); // entries değişince yeniden hesapla
  return StorageService.instance.getStreakCount();
});

/// Bugünkü tahmini maliyet (TL)
final todayCostProvider = Provider<double>((ref) {
  final entries = ref.watch(todayEntriesProvider);
  final settings = ref.watch(settingsProvider);
  if (settings.cigsPerPack <= 0) return 0;

  return entries.fold(0.0, (sum, e) {
    final price = e.pricePerPack ?? settings.pricePerPack;
    if (price <= 0) return sum;
    return sum + (price / settings.cigsPerPack) * e.amount;
  });
});

/// Bugünkü tür dağılımı: {'sigara': 7, 'vape': 3}
final todayTypeBreakdownProvider = Provider<Map<String, int>>((ref) {
  final entries = ref.watch(todayEntriesProvider);
  final map = <String, int>{};
  for (final e in entries) {
    map[e.type] = (map[e.type] ?? 0) + e.amount;
  }
  return map;
});

/// Son 30 gün içinde ama 7 günden eski kayıtlar (dashboard blur + CTA için)
final entriesOlderThan7DaysProvider = Provider<List<SmokeEntry>>((ref) {
  ref.watch(todayEntriesProvider);
  final all = StorageService.instance.getEntriesForLastNDays(30);
  final cutoff = DateTime.now().subtract(const Duration(days: 7));
  final cutoffDate = DateTime(cutoff.year, cutoff.month, cutoff.day);
  return all.where((e) {
    final d = DateTime(e.createdAt.year, e.createdAt.month, e.createdAt.day);
    return d.isBefore(cutoffDate);
  }).toList();
});
