import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sigara_defteri/services/premium_service.dart';
import 'package:sigara_defteri/shared/theme/app_theme.dart';

class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  bool _lifetimeLoading = false;
  bool _yearlyLoading = false;
  bool _restoreLoading = false;

  static const _features = [
    'Sınırsız kayıt geçmişi',
    'Detaylı aylık & yıllık istatistikler',
    'Bırakma Modu — gün sayacı & milestone\'lar',
    'Yıllık maliyet raporu',
    'Ana ekran widget\'ı',
    'Reklamsız deneyim',
    'Veri dışa aktarma (CSV)',
  ];

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _buyLifetime() async {
    setState(() => _lifetimeLoading = true);
    final err = await ref.read(premiumProvider.notifier).purchaseLifetime();
    if (!mounted) return;
    setState(() => _lifetimeLoading = false);
    if (err != null) {
      _showError(err);
    } else {
      Navigator.pop(context, true);
    }
  }

  Future<void> _buyYearly() async {
    setState(() => _yearlyLoading = true);
    final err = await ref.read(premiumProvider.notifier).purchaseYearly();
    if (!mounted) return;
    setState(() => _yearlyLoading = false);
    if (err != null) {
      _showError(err);
    } else {
      Navigator.pop(context, true);
    }
  }

  Future<void> _restore() async {
    setState(() => _restoreLoading = true);
    final err = await ref.read(premiumProvider.notifier).restorePurchases();
    if (!mounted) return;
    setState(() => _restoreLoading = false);
    if (err != null) {
      _showError(err);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Premium geri yüklendi ✓'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Üst: kapat butonu
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textDisabled),
                  onPressed: () => Navigator.pop(context, false),
                ),
              ),
            ),
            // İçerik
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Column(
                  children: [
                    const Text(
                      '🚬',
                      style: TextStyle(fontSize: 56),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Sigara Defteri Premium',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Tüm özellikler, sınırsız geçmiş',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 15,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    // Özellik listesi
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Column(
                        children: _features.map((f) => _FeatureRow(f)).toList(),
                      ),
                    ),
                    const SizedBox(height: 28),
                    // Ömürlük — ana buton
                    _PurchaseButton(
                      label: 'Ömürlük',
                      price: '₺99',
                      subtitle: 'Bir kez öde, sonsuza kadar kullan',
                      isPrimary: true,
                      isLoading: _lifetimeLoading,
                      onTap: _buyLifetime,
                    ),
                    const SizedBox(height: 10),
                    // Yıllık — ikinci seçenek
                    _PurchaseButton(
                      label: 'Yıllık',
                      price: '₺199',
                      subtitle: 'yıl — yeni özelliklere öncelikli erişim',
                      isPrimary: false,
                      isLoading: _yearlyLoading,
                      onTap: _buyYearly,
                    ),
                    const SizedBox(height: 20),
                    // Geri yükle
                    _restoreLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary,
                            ),
                          )
                        : TextButton(
                            onPressed: _restore,
                            child: const Text(
                              'Satın almaları geri yükle',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ),
                    // Devam et (ücretsiz)
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text(
                        'Şimdilik ücretsiz devam et',
                        style: TextStyle(
                          color: AppColors.textDisabled,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Gizlilik / Kullanım
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _LegalLink('Gizlilik Politikası'),
                        const Text(
                          '  ·  ',
                          style: TextStyle(color: AppColors.textDisabled, fontSize: 12),
                        ),
                        _LegalLink('Kullanım Şartları'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Özellik satırı ────────────────────────────────────────────────────────────

class _FeatureRow extends StatelessWidget {
  final String text;
  const _FeatureRow(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Satın alma butonu ─────────────────────────────────────────────────────────

class _PurchaseButton extends StatelessWidget {
  final String label;
  final String price;
  final String subtitle;
  final bool isPrimary;
  final bool isLoading;
  final VoidCallback onTap;

  const _PurchaseButton({
    required this.label,
    required this.price,
    required this.subtitle,
    required this.isPrimary,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isPrimary ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isPrimary ? AppColors.primary : AppColors.divider,
            width: isPrimary ? 0 : 1,
          ),
        ),
        child: isLoading
            ? Center(
                child: SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: isPrimary ? const Color(0xFF1A1200) : AppColors.primary,
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          color: isPrimary ? const Color(0xFF1A1200) : AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: isPrimary
                              ? const Color(0xFF1A1200).withValues(alpha: 0.7)
                              : AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    price,
                    style: TextStyle(
                      color: isPrimary ? const Color(0xFF1A1200) : AppColors.primary,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ── Hukuki link ───────────────────────────────────────────────────────────────

class _LegalLink extends StatelessWidget {
  final String text;
  const _LegalLink(this.text);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // TODO: url_launcher ile gerçek URL aç
      },
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.textDisabled,
          fontSize: 11,
          decoration: TextDecoration.underline,
          decorationColor: AppColors.textDisabled,
        ),
      ),
    );
  }
}
