import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sigara_defteri/providers/smoke_providers.dart';
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
