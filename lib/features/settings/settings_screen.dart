import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sigara_defteri/app/router.dart';
import 'package:sigara_defteri/providers/smoke_providers.dart';
import 'package:sigara_defteri/services/premium_service.dart';
import 'package:sigara_defteri/services/export_service.dart';
import 'package:sigara_defteri/services/notification_service.dart';
import 'package:sigara_defteri/shared/theme/app_theme.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late TextEditingController _priceCtrl;
  late TextEditingController _cigsCtrl;
  bool _initialized = false;
  bool _saved = false;

  @override
  void dispose() {
    _priceCtrl.dispose();
    _cigsCtrl.dispose();
    super.dispose();
  }

  void _initControllers(SettingsState settings) {
    if (_initialized) return;
    _priceCtrl = TextEditingController(
      text: settings.pricePerPack > 0 ? settings.pricePerPack.toStringAsFixed(2) : '',
    );
    _cigsCtrl = TextEditingController(
      text: settings.cigsPerPack.toString(),
    );
    _initialized = true;
  }

  Future<void> _save() async {
    final notifier = ref.read(settingsProvider.notifier);
    final price = double.tryParse(_priceCtrl.text.replaceAll(',', '.')) ?? 0;
    final cigs = int.tryParse(_cigsCtrl.text) ?? 20;

    await notifier.setPricePerPack(price);
    await notifier.setCigsPerPack(cigs.clamp(1, 100));

    if (mounted) {
      setState(() => _saved = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Ayarlar kaydedildi'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 80),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) setState(() => _saved = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    _initControllers(settings);

    final estimatedCostPerCig = settings.pricePerCig;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayarlar'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _SectionHeader('PAKET BİLGİLERİ'),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Paket Fiyatı (₺)',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _priceCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[\d,\.]')),
                    ],
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: const InputDecoration(
                      hintText: '0.00',
                      prefixText: '₺ ',
                      prefixStyle: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Pakette Kaç Adet?',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _PackSizeSelector(
                    controller: _cigsCtrl,
                    onPreset: (v) => setState(() {
                      _cigsCtrl.text = v.toString();
                    }),
                  ),
                  if (estimatedCostPerCig > 0) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Adet başına: ₺${estimatedCostPerCig.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _save,
            child: Text(_saved ? '✓ Kaydedildi' : 'Kaydet'),
          ),
          const SizedBox(height: 32),
          const _SectionHeader('PREMIUM'),
          const SizedBox(height: 10),
          _PremiumSection(),
          const SizedBox(height: 32),
          const _SectionHeader('BİLDİRİMLER'),
          const SizedBox(height: 10),
          _ReminderSection(),
          const SizedBox(height: 32),
          const _SectionHeader('HAKKINDA'),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InfoRow(label: 'Uygulama', value: 'Sigara Defteri'),
                  const SizedBox(height: 12),
                  _InfoRow(label: 'Versiyon', value: '1.0.0'),
                  const SizedBox(height: 12),
                  const Text(
                    'Yargılamadan takip et.',
                    style: TextStyle(
                      color: AppColors.textDisabled,
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Paket boyutu seçici ───────────────────────────────────────────────────────

class _PackSizeSelector extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<int> onPreset;

  const _PackSizeSelector({required this.controller, required this.onPreset});

  static const _presets = [10, 14, 20, 25, 40];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
          decoration: const InputDecoration(
            hintText: '20',
            suffixText: 'adet',
            suffixStyle: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 6,
          children: _presets.map((n) {
            return GestureDetector(
              onTap: () => onPreset(n),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Text(
                  '$n',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ── Yardımcı widgetlar ────────────────────────────────────────────────────────

class _ReminderSection extends ConsumerWidget {
  const _ReminderSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    Future<void> toggleReminder(bool value) async {
      if (value) {
        await NotificationService.requestPermissions();
        await notifier.setReminderEnabled(true);
      } else {
        await notifier.setReminderEnabled(false);
      }
    }

    Future<void> pickTime() async {
      final picked = await showTimePicker(
        context: context,
        initialTime: TimeOfDay(
          hour: settings.reminderHour,
          minute: settings.reminderMinute,
        ),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.dark(
                primary: AppColors.primary,
                onPrimary: Color(0xFF1A1200),
                surface: AppColors.surface,
                onSurface: AppColors.textPrimary,
              ),
            ),
            child: child!,
          );
        },
      );
      if (picked != null) {
        await notifier.setReminderTime(picked.hour, picked.minute);
      }
    }

    final timeStr =
        '${settings.reminderHour.toString().padLeft(2, '0')}:${settings.reminderMinute.toString().padLeft(2, '0')}';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.notifications_outlined, color: AppColors.primary, size: 22),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Günlük hatırlatma',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Switch(
                  value: settings.reminderEnabled,
                  onChanged: toggleReminder,
                  activeTrackColor: AppColors.primary.withValues(alpha: 0.5),
                  activeThumbColor: AppColors.primary,
                ),
              ],
            ),
            if (settings.reminderEnabled) ...[
              const SizedBox(height: 4),
              const Text(
                'Her gün aynı saatte kayıt eklemen için bildirim gelir.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.schedule, color: AppColors.textSecondary, size: 22),
                title: const Text('Saat', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      timeStr,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right, color: AppColors.textDisabled, size: 20),
                  ],
                ),
                onTap: pickTime,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Premium bölümü ───────────────────────────────────────────────────────────

class _PremiumSection extends ConsumerStatefulWidget {
  const _PremiumSection();

  @override
  ConsumerState<_PremiumSection> createState() => _PremiumSectionState();
}

class _PremiumSectionState extends ConsumerState<_PremiumSection> {
  bool _restoreLoading = false;

  Future<void> _openPaywall(BuildContext context) async {
    await Navigator.pushNamed<bool>(context, AppRouter.paywall);
  }

  Future<void> _restore(BuildContext context) async {
    setState(() => _restoreLoading = true);
    final err = await ref.read(premiumProvider.notifier).restorePurchases();
    if (!mounted) return;
    setState(() => _restoreLoading = false);
    if (!context.mounted) return;
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Premium geri yüklendi ✓'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final premium = ref.watch(premiumProvider);
    final isPremium = premium.isPremium;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isPremium) ...[
              Row(
                children: [
                  const Icon(Icons.workspace_premium_rounded, color: AppColors.primary, size: 24),
                  const SizedBox(width: 10),
                  const Text(
                    'Premium aktif',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.flag_rounded, color: AppColors.primary, size: 22),
                title: const Text('Bırakma Modu', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
                trailing: const Icon(Icons.chevron_right, color: AppColors.textDisabled),
                onTap: () => Navigator.pushNamed(context, AppRouter.quit),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.file_download_outlined, color: AppColors.primary, size: 22),
                title: const Text('Veriyi dışa aktar (CSV)', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
                trailing: const Icon(Icons.chevron_right, color: AppColors.textDisabled),
                onTap: () async {
                  final err = await exportEntriesToCsvAndShare();
                  if (!context.mounted) return;
                  if (err != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Dışa aktarma hatası: $err'),
                        backgroundColor: AppColors.error,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
              ),
              if (_restoreLoading)
                const Center(child: Padding(padding: EdgeInsets.only(top: 8), child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))))
              else
                TextButton(
                  onPressed: () => _restore(context),
                  child: const Text('Satın almaları geri yükle', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                ),
            ] else ...[
              Row(
                children: [
                  const Icon(Icons.workspace_premium_outlined, color: AppColors.primary, size: 24),
                  const SizedBox(width: 10),
                  const Text(
                    'Premium',
                    style: TextStyle(color: AppColors.primary, fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Sınırsız geçmiş, detaylı istatistikler, bırakma modu ve daha fazlası için Premium\'a geç.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: premium.isLoading ? null : () => _openPaywall(context),
                child: premium.isLoading
                    ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF1A1200)))
                    : const Text('Premium\'a Geç'),
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.flag_outlined, color: AppColors.textSecondary, size: 22),
                title: const Text('Bırakma Modu', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                trailing: const Icon(Icons.chevron_right, color: AppColors.textDisabled),
                onTap: () => Navigator.pushNamed(context, AppRouter.quit),
              ),
              if (_restoreLoading)
                const Center(child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)))
              else
                TextButton(
                  onPressed: () => _restore(context),
                  child: const Text('Satın almaları geri yükle', style: TextStyle(color: AppColors.textDisabled, fontSize: 13)),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Yardımcı widgetlar ────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.textDisabled,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
        Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
