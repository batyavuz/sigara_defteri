import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

// TODO: release öncesi false yap!
const kDebugPremium = true;

const _entitlementId = 'premium';
const _productLifetime = 'sigara_defteri_lifetime';
const _productYearly = 'sigara_defteri_yearly';

// ── State ────────────────────────────────────────────────────────────────────

class PremiumState {
  final bool isPremium;
  final bool isLoading;
  final String? error;

  const PremiumState({
    this.isPremium = false,
    this.isLoading = false,
    this.error,
  });

  PremiumState copyWith({bool? isPremium, bool? isLoading, String? error}) {
    return PremiumState(
      isPremium: isPremium ?? this.isPremium,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// ── Notifier ─────────────────────────────────────────────────────────────────

class PremiumNotifier extends StateNotifier<PremiumState> {
  PremiumNotifier() : super(const PremiumState()) {
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    if (kDebugPremium) {
      state = const PremiumState(isPremium: true);
      return;
    }
    try {
      state = state.copyWith(isLoading: true);
      final info = await Purchases.getCustomerInfo();
      state = PremiumState(
        isPremium: info.entitlements.active.containsKey(_entitlementId),
      );
    } catch (_) {
      state = const PremiumState(isPremium: false);
    }
  }

  /// Ömürlük satın alma. Hata varsa Türkçe mesaj döner, null = başarılı.
  Future<String?> purchaseLifetime() async {
    if (kDebugPremium) {
      state = state.copyWith(isPremium: true);
      return null;
    }
    return _purchase(_productLifetime);
  }

  /// Yıllık abonelik satın alma.
  Future<String?> purchaseYearly() async {
    if (kDebugPremium) {
      state = state.copyWith(isPremium: true);
      return null;
    }
    return _purchase(_productYearly);
  }

  Future<String?> _purchase(String productId) async {
    state = state.copyWith(isLoading: true);
    try {
      final offerings = await Purchases.getOfferings();
      Package? pkg;
      for (final offering in offerings.all.values) {
        try {
          pkg = offering.getPackage(productId);
          break;
        } catch (_) {}
      }
      if (pkg == null) {
        state = state.copyWith(isLoading: false);
        return 'Ürün bulunamadı. Lütfen tekrar dene.';
      }
      final info = await Purchases.purchasePackage(pkg);
      state = PremiumState(
        isPremium: info.entitlements.active.containsKey(_entitlementId),
      );
      return null;
    } on PlatformException catch (e) {
      state = state.copyWith(isLoading: false);
      return _turkishError(e);
    }
  }

  /// Satın almaları geri yükle.
  Future<String?> restorePurchases() async {
    if (kDebugPremium) {
      state = state.copyWith(isPremium: true);
      return null;
    }
    state = state.copyWith(isLoading: true);
    try {
      final info = await Purchases.restorePurchases();
      final isPremium = info.entitlements.active.containsKey(_entitlementId);
      state = PremiumState(isPremium: isPremium);
      return isPremium ? null : 'Geri yüklenecek satın alma bulunamadı.';
    } on PlatformException catch (e) {
      state = state.copyWith(isLoading: false);
      return _turkishError(e);
    }
  }

  String _turkishError(PlatformException e) {
    final code = PurchasesErrorHelper.getErrorCode(e);
    switch (code) {
      case PurchasesErrorCode.purchaseCancelledError:
        return 'Satın alma iptal edildi.';
      case PurchasesErrorCode.networkError:
        return 'İnternet bağlantısı yok. Tekrar dene.';
      case PurchasesErrorCode.paymentPendingError:
        return 'Ödeme beklemede, biraz bekle.';
      case PurchasesErrorCode.productAlreadyPurchasedError:
        return 'Bu ürün zaten satın alınmış. Geri yükle.';
      case PurchasesErrorCode.receiptAlreadyInUseError:
        return 'Bu hesap başka bir cihazda kullanılıyor.';
      default:
        return 'Bir hata oluştu. Lütfen tekrar dene.';
    }
  }
}

// ── Provider ─────────────────────────────────────────────────────────────────

final premiumProvider =
    StateNotifierProvider<PremiumNotifier, PremiumState>(
  (ref) => PremiumNotifier(),
);
