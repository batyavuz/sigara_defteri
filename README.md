# Sigara Defteri

Sigara ve vape tüketimini takip eden, minimalist bir günlük uygulaması. Hem bırakmak isteyenlere hem de tüketimini sadece izlemek isteyenlere hitap eder — **yargılamadan takip** felsefesiyle.

---

## Ne İşe Yarar?

- **Günlük kayıt:** Her tüketimi tür (sigara / vape), adet, tetikleyici (kahve, stres, sosyal vb.) ve isteğe bağlı notla kaydedersin.
- **Özet ve trend:** Bugünkü toplam, streak (ardışık gün), haftalık/aylık grafikler ve tetikleyici dağılımı.
- **Maliyet:** Paket fiyatı ve adet bilgisiyle günlük/haftalık/aylık/yıllık harcama tahmini.
- **Bırakma modu:** Bırakma tarihi seçip milestone'larla ilerlemeyi takip edebilirsin (premium ile tam erişim).

Ücretsiz sürümde son 7 günlük geçmiş ve temel istatistikler; premium ile sınırsız geçmiş, tüm grafikler, bırakma modu, widget ve CSV export sunuluyor.

---

## Teknolojiler

| Alan            | Kullanılan |
|-----------------|------------|
| Framework       | Flutter    |
| State           | Riverpod   |
| Yerel veritabanı| Hive       |
| Grafikler       | fl_chart   |
| Abonelik / satın alma | RevenueCat |

---

## Gereksinimler

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (stable)
- Android Studio / Xcode (mobil build için)

---

## Kurulum ve Çalıştırma

```bash
git clone https://github.com/batyavuz/sigara_defteri.git
cd sigara_defteri
flutter pub get
flutter run
```

Release build (Android APK):

```bash
flutter build apk
```

---

## Proje Yapısı

- `lib/features/` — Ekranlar: log (kayıt), dashboard, stats, quit, settings
- `lib/models/` — SmokeEntry, Trigger (Hive modelleri)
- `lib/services/` — Storage, bildirim, premium (RevenueCat)
- `lib/shared/` — Tema ve ortak widget'lar (örn. PremiumGate)

---

## Lisans ve Yayın

Kişisel proje; Google Play ve App Store'da **Sigara Defteri** adıyla yayınlanması planlanıyor. "Alkol Defteri" ile aynı marka ailesindedir.
