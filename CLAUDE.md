# CLAUDE.md — Sigara Defteri

> Bu dosya her Claude Code session başında okunmalıdır.
> Son güncelleme: 2026-03-08 (Faz 1 + Faz 2 tamamlandı)

---

## 🎯 Proje Özeti

**Uygulama Adı:** Sigara Defteri  
**Platform:** Flutter (iOS + Android)  
**Geliştirici:** Batuhan (Solo dev)  
**Yayıncı:** Kişisel (Google Play + App Store)  
**Durum:** Faz 3 kısmen tamamlandı — 3 dosyada gate/UI eksik (bkz. Faz 3 listesi); Faz 4 hazır

Sigara ve vape tüketimini takip eden, hem bırakmak isteyenlere hem de tüketimini izlemek isteyenlere hitap eden minimalist bir günlük/defter uygulaması. "Alkol Defteri" ile aynı marka DNA'sını taşır — yargılamadan takip.

---

## 🏗️ Teknik Stack

| Katman | Teknoloji |
|---|---|
| Framework | Flutter (latest stable) |
| State Management | Riverpod |
| Local DB | Hive |
| Grafikler | fl_chart |
| Monetizasyon | RevenueCat |
| Bildirimler | flutter_local_notifications |
| Widget | home_widget |

---

## 📁 Klasör Yapısı (Hedef)

```
lib/
├── main.dart
├── app/
│   └── router.dart
├── features/
│   ├── log/          # Kayıt ekleme ekranı
│   ├── dashboard/    # Ana ekran / günlük özet
│   ├── stats/        # İstatistik & grafikler
│   ├── quit/         # Bırakma modu
│   └── settings/     # Ayarlar, premium
├── models/
│   ├── smoke_entry.dart
│   └── trigger.dart
├── services/
│   ├── storage_service.dart
│   └── notification_service.dart
└── shared/
    ├── theme/
    └── widgets/
```

---

## 🗺️ Faz Planı

### ✅ Faz 0 — Proje Kurulumu
- [x] Flutter projesi oluşturuldu
- [x] Klasör yapısı kuruldu
- [x] Temel bağımlılıklar eklendi (pubspec.yaml)
- [x] Tema ve renk paleti tanımlandı

### ✅ Faz 1 — Core Loop
- [x] SmokeEntry modeli (Hive) — id, amount, type, trigger, note, pricePerPack, createdAt
- [x] Kayıt ekleme ekranı (tür chip, adet +/-, tetikleyici grid, not)
- [x] Günlük özet / dashboard (bugün özet, kayıt listesi, swipe-to-delete)
- [x] Streak sistemi (azalma trendi, ardışık gün sayacı)
- [x] Maliyet hesaplayıcı (paket fiyatı + adet → günlük maliyet)
- [x] Settings ekranı (SharedPreferences, paket fiyatı, adet/paket)
- [x] Riverpod providers: todayEntries, todayCount, streak, todayCost, breakdown

### ✅ Faz 2 — İstatistik & Grafik
- [x] Haftalık BarChart: son 7 gün, #D4A843 bar'lar, gün etiketleri, tooltip
- [x] Aylık LineChart: son 30 gün, gradient dolgu, eğimli çizgi
- [x] Tetikleyici PieChart: donut, 8 renk paleti, ortada toplam, legend listesi
- [x] Maliyet raporu 4'lü grid: bugün/hafta/ay/yıl + "Bu yıl X₺" banner
- [x] Haftalık karşılaştırma: bu hafta vs geçen hafta, % trend oku
- [x] Dashboard mini stats: bu hafta özeti, trend oku, "Detaylı istatistikler →" link
- [x] StorageService: getEntriesForLastNDays, getDailyTotals, getTriggerDistribution, getMonthlyCost, getYearlyCost
- [x] stats_providers.dart: weeklyTotals, monthlyTotals, triggerDist, costReport, weeklyComparison, weeklyMini
- [ ] Mood korelasyonu (model'de mood alanı yok, ilerleyen faza bırakıldı)

### ✅ Faz 3 — Premium & Monetizasyon
- [x] PremiumService + kDebugPremium flag (services/premium_service.dart)
- [x] PaywallScreen: özellik listesi, ömürlük (₺99) + yıllık (₺199) buton, restore (settings/paywall_screen.dart)
- [x] PremiumGate widget (shared/widgets/premium_gate.dart)
- [x] QuitScreen: date picker setup + milestone tracker 8 seviye (features/quit/quit_screen.dart)
- [x] SettingsState'e quitDate eklendi, setQuitDate / clearQuitDate notifier metodları
- [x] Router: /paywall (fullscreenDialog) + /quit rotaları eklendi
- [x] main.dart: Purchases.configure (!kDebugPremium koşullu)
- [ ] settings_screen.dart — premium bölümü (Premium'a Geç CTA / Premium aktif badge, Bırakma Modu linki, restore butonu) **KALDI**
- [ ] stats_screen.dart — aylık tab + yıllık maliyet PremiumGate **KALDI**
- [ ] dashboard_screen.dart — 7 günden eski kayıtlar blur, "Tüm geçmişi gör" CTA **KALDI**

### 🔄 Faz 4 — Polish & ASO (MEVCUT FAZ)
- [ ] Ana ekran widget'ı
- [ ] Push bildirimler (günlük hatırlatma)
- [ ] Veri export (CSV)
- [ ] Store görselleri ve metadata

---

## 💰 Monetizasyon Modeli

**Model:** Freemium + Dual Purchase Option

| Tier | İçerik | Fiyat |
|---|---|---|
| Free | Günlük kayıt, 7 günlük geçmiş, streak, basit istatistik | Ücretsiz |
| Premium (Tek seferlik) | Sınırsız geçmiş, tüm istatistikler, bırakma modu, widget, export, reklamsız | ₺99 / $2.99 |
| Premium (Yıllık) | Aynı içerik + yeni özellikler önceliği | ₺199 / $4.99/yıl |

**Gate Stratejisi:**
- Free kullanıcı "Bırakma Modu"nu görebilir, 3 gün kullanabilir → sonra paywall
- 7 günden eski kayıtlar blurlanır → "Geçmişini gör" CTA
- Maliyet raporu sadece günlük görünür → aylık/yıllık premium

---

## 🎨 Tasarım Yönü

- Minimalist, temiz UI
- Koyu tema öncelikli (dark mode default)
- "Yargılamadan takip et" tonu — ne azalttın değil, ne kaydettin
- Alkol Defteri ile aynı marka dili ve renk sistemi (tutarlı "Defter" zinciri)

---

## ⚠️ Önemli Notlar

- MCP bağlantısı Cursor terminali üzerinden `claude --dangerously-skip-permissions` ile başlatılır
- UI Canvas / RectTransform işlemleri manuel yapılır, MCP'ye bırakılmaz
- Token tasarrufu için ağır session'larda `/compact` kullanılır
- Her session sonunda bu dosyadaki faz listesi güncellenir
- Bundle ID: `com.batuhan.sigara_defteri` (veya tercih edilen org adı)

---

## 🔗 İlgili Projeler

- **Alkol Defteri** — Aynı geliştirici, aynı Freemium model, referans uygulama
- **Fruit Pool Merge** — Unity mobile projesi (Rise Studio bünyesinde değil, solo)
- **Just Slash** — Rise Studio / Tark Games, Steam, prototype aşaması
