import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:sigara_defteri/app/router.dart';
import 'package:sigara_defteri/services/notification_service.dart';
import 'package:sigara_defteri/services/premium_service.dart';
import 'package:sigara_defteri/services/storage_service.dart';
import 'package:sigara_defteri/services/widget_service.dart';
import 'package:sigara_defteri/shared/theme/app_theme.dart';

// TODO: Gerçek API key'leri buraya gir.
const _rcAndroidKey = 'REVENUECAT_ANDROID_KEY_BURAYA';
const _rcIosKey = 'REVENUECAT_IOS_KEY_BURAYA';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  await StorageService.init();
  await NotificationService.init();

  // AdMob: Sadece Android'de başlat. iOS'ta initialize() TestFlight/release'da
  // GADApplicationVerifyPublisherInitializedCorrectly ile çökme yapıyor (init başarısız olunca
  // SDK abort ediyor). Gerçek iOS App ID Info.plist'e girilip reklamlar açılacaksa
  // aşağıdaki Platform.isAndroid koşulunu kaldırıp iOS'ta da init edebilirsin.
  if (Platform.isAndroid) {
    try {
      await MobileAds.instance.initialize();
    } catch (e, st) {
      debugPrint('AdMob init hatası: $e');
      debugPrint(st.toString());
    }
  }

  // Ana ekran widget'ını ilk veriyle güncelle
  refreshHomeWidget();

  if (!kDebugPremium) {
    // RevenueCat sadece gerçek API key varken yapılandırılır.
    final apiKey = Platform.isIOS ? _rcIosKey : _rcAndroidKey;
    await Purchases.configure(PurchasesConfiguration(apiKey));
  }

  runApp(
    const ProviderScope(
      child: SigaraDefteriApp(),
    ),
  );
}

class SigaraDefteriApp extends StatelessWidget {
  const SigaraDefteriApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sigara Defteri',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      onGenerateRoute: AppRouter.onGenerateRoute,
      initialRoute: AppRouter.splash,
    );
  }
}
