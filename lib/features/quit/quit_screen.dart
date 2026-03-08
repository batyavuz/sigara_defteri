import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sigara_defteri/features/settings/paywall_screen.dart';
import 'package:sigara_defteri/providers/smoke_providers.dart';
import 'package:sigara_defteri/services/premium_service.dart';
import 'package:sigara_defteri/services/storage_service.dart';
import 'package:sigara_defteri/shared/theme/app_theme.dart';

class _Milestone {
  final String label;
  final Duration duration;
  final String emoji;
  final String message;
  const _Milestone(this.label, this.duration, this.emoji, this.message);
}

const _milestones = [
  _Milestone('1 Gün', Duration(days: 1), '🌱', 'İlk adım atıldı. Bu kadar bile önemli.'),
  _Milestone('3 Gün', Duration(days: 3), '✨', 'Nikotin büyük ölçüde temizlendi.'),
  _Milestone('1 Hafta', Duration(days: 7), '💪', 'Bir hafta. Alışkanlık kırılmaya başlıyor.'),
  _Milestone('2 Hafta', Duration(days: 14), '🌬️', 'Nefes almak kolaylaşmış olmalı.'),
  _Milestone('1 Ay', Duration(days: 30), '🏆', 'Bir ay. Bu artık bir alışkanlık.'),
  _Milestone('3 Ay', Duration(days: 90), '🔥', 'Üç ay dayanmak ciddi bir iş.'),
  _Milestone('6 Ay', Duration(days: 180), '⭐', 'Altı ay! Bağımlılık tarihe karışıyor.'),
  _Milestone('1 Yıl', Duration(days: 365), '🎉', 'Bir yıl. Bir dönem kapandı.'),
];

class QuitScreen extends ConsumerWidget {
  const QuitScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPremium = ref.watch(premiumProvider).isPremium;
    if (!isPremium) {
      return const PaywallScreen();
    }
    final settings = ref.watch(settingsProvider);
    return settings.quitDate == null
        ? _SetupView(settings: settings, ref: ref)
        : _TrackerView(settings: settings, ref: ref);
  }
}

// ── Kurulum ekranı ────────────────────────────────────────────────────────────

class _SetupView extends StatefulWidget {
  final SettingsState settings;
  final WidgetRef ref;
  const _SetupView({required this.settings, required this.ref});

  @override
  State<_SetupView> createState() => _SetupViewState();
}

class _SetupViewState extends State<_SetupView> {
  DateTime _selected = DateTime.now();

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selected,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 2)),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.primary,
            surface: AppColors.surface,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selected = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bırakma Modu')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🚭', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 24),
            const Text(
              'Ne zaman bıraktın?',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Bırakma tarihini seç, gerisini biz takip edelim.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.primary),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        color: AppColors.primary, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      '${_selected.day}.${_selected.month}.${_selected.year}',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: () =>
                  widget.ref.read(settingsProvider.notifier).setQuitDate(_selected),
              child: const Text('Başla'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Takip ekranı ──────────────────────────────────────────────────────────────

class _TrackerView extends StatelessWidget {
  final SettingsState settings;
  final WidgetRef ref;
  const _TrackerView({required this.settings, required this.ref});

  @override
  Widget build(BuildContext context) {
    final quitDate = settings.quitDate!;
    final now = DateTime.now();
    final days = now.difference(quitDate).inDays;

    // Ortalama günlük tüketim (son 30 gün — bırakmadan önceki)
    final dailyTotals = StorageService.instance.getDailyTotals(30);
    final nonZero = dailyTotals.values.where((v) => v > 0).toList();
    final avgDaily = nonZero.isEmpty
        ? 0.0
        : nonZero.fold(0, (s, v) => s + v) / nonZero.length;
    final savings = days * avgDaily * settings.pricePerCig;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bırakma Modu'),
        actions: [
          TextButton(
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: AppColors.surface,
                  title: const Text('Sıfırla?',
                      style: TextStyle(color: AppColors.textPrimary)),
                  content: const Text('Bırakma tarihi silinecek.',
                      style: TextStyle(color: AppColors.textSecondary)),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('İptal')),
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: TextButton.styleFrom(foregroundColor: AppColors.error),
                        child: const Text('Sıfırla')),
                  ],
                ),
              );
              if (ok == true) {
                ref.read(settingsProvider.notifier).clearQuitDate();
              }
            },
            child: const Text('Sıfırla',
                style: TextStyle(color: AppColors.textDisabled, fontSize: 13)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          // Büyük sayaç
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 32),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primaryDim),
            ),
            child: Column(
              children: [
                const Text('🎉', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 8),
                Text(
                  '$days',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 72,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
                const Text(
                  'gündür sigarasız',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (savings > 0) ...[
                  const SizedBox(height: 12),
                  Text(
                    '₺${savings.toStringAsFixed(0)} biriktirdin',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'MİLESTONE\'LAR',
            style: TextStyle(
              color: AppColors.textDisabled,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          ..._milestones.map((m) {
            final achieved = days >= m.duration.inDays;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: achieved ? AppColors.primaryContainer : AppColors.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: achieved ? AppColors.primaryDim : AppColors.divider,
                ),
              ),
              child: Row(
                children: [
                  Text(m.emoji, style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          m.label,
                          style: TextStyle(
                            color: achieved
                                ? AppColors.primary
                                : AppColors.textDisabled,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          m.message,
                          style: TextStyle(
                            color: achieved
                                ? AppColors.textSecondary
                                : AppColors.textDisabled,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (achieved)
                    const Icon(Icons.check_circle_rounded,
                        color: AppColors.primary, size: 20),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
