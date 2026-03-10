import 'dart:io' show Platform;

import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sigara_defteri/services/storage_service.dart';

/// Ana ekran widget'ına gönderilecek veri anahtarları (native tarafta aynı key'ler kullanılmalı).
class WidgetKeys {
  static const todayCount = 'today_count';
  static const todayCost = 'today_cost';
  static const streak = 'streak';
  static const showCost = 'show_cost';
}

/// Android ve iOS widget provider / widget name (native tarafta kayıtlı isimle eşleşmeli).
const _androidName = 'SigaraDefteriWidgetProvider';
const _iosName = 'SigaraDefteriWidget';

/// Mevcut veriyi okuyup widget'ı günceller (kayıt ekleme/silme veya uygulama açılışında çağrılabilir).
Future<void> refreshHomeWidget() async {
  try {
    final storage = StorageService.instance;
    final todayCount = storage.getTodayCount();
    final streak = storage.getStreakCount();
    final prefs = await SharedPreferences.getInstance();
    final pricePerPack = prefs.getDouble('price_per_pack') ?? 0.0;
    final cigsPerPack = prefs.getInt('cigs_per_pack') ?? 20;
    final entries = storage.getTodayEntries();
    double todayCost = 0;
    if (cigsPerPack > 0 && pricePerPack > 0) {
      todayCost = entries.fold(0.0, (sum, e) {
        final p = e.pricePerPack ?? pricePerPack;
        return sum + (p / cigsPerPack) * e.amount;
      });
    }
    await updateHomeWidget(
      todayCount: todayCount,
      todayCost: todayCost,
      streak: streak,
      showCost: pricePerPack > 0,
    );
  } catch (_) {}
}

/// Widget verisini doğrudan parametrelerle günceller.
Future<void> updateHomeWidget({
  required int todayCount,
  required double todayCost,
  required int streak,
  required bool showCost,
}) async {
  try {
    await HomeWidget.saveWidgetData<int>(WidgetKeys.todayCount, todayCount);
    await HomeWidget.saveWidgetData<double>(WidgetKeys.todayCost, todayCost);
    await HomeWidget.saveWidgetData<int>(WidgetKeys.streak, streak);
    await HomeWidget.saveWidgetData<bool>(WidgetKeys.showCost, showCost);

    final name = Platform.isAndroid ? _androidName : _iosName;
    await HomeWidget.updateWidget(name: name);
  } catch (_) {
    // Widget yapılandırılmamışsa veya platform desteklemiyorsa sessizce geç
  }
}
