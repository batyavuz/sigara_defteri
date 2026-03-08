import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sigara_defteri/models/smoke_entry.dart';
import 'package:sigara_defteri/models/trigger.dart';
import 'package:sigara_defteri/providers/smoke_providers.dart';
import 'package:sigara_defteri/shared/theme/app_theme.dart';

class LogScreen extends ConsumerStatefulWidget {
  const LogScreen({super.key});

  @override
  ConsumerState<LogScreen> createState() => _LogScreenState();
}

class _LogScreenState extends ConsumerState<LogScreen> {
  static const _types = [
    {'id': 'sigara', 'label': 'Sigara', 'emoji': '🚬'},
    {'id': 'vape', 'label': 'Vape', 'emoji': '💨'},
    {'id': 'puro', 'label': 'Puro', 'emoji': '🍃'},
    {'id': 'nargile', 'label': 'Nargile', 'emoji': '🫧'},
  ];

  /// Yaygın sigara markaları; "Özel" seçilirse metin kutusu açılır.
  static const _brands = [
    'Marlboro',
    'Camel',
    'Parliament',
    'Winston',
    'L&M',
    'Bond',
    'Pall Mall',
    'Kent',
    'Eclipse',
    'Samsun',
    'Tekel',
    'Özel',
  ];

  String _type = 'sigara';
  int _amount = 1;
  String? _trigger;
  String? _brand; // seçili marka; "Özel" ise _customBrand kullanılır
  final _customBrandCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _customBrandCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  String? get _effectiveBrand {
    if (_brand == null || _brand == 'Özel') {
      final t = _customBrandCtrl.text.trim();
      return t.isEmpty ? null : t;
    }
    return _brand;
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final settings = ref.read(settingsProvider);
    final entry = SmokeEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      createdAt: DateTime.now(),
      amount: _amount,
      type: _type,
      trigger: _trigger,
      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      pricePerPack: settings.pricePerPack > 0 ? settings.pricePerPack : null,
      brand: _effectiveBrand,
    );
    await ref.read(todayEntriesProvider.notifier).add(entry);
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kayıt Ekle'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionLabel('TÜR'),
            const SizedBox(height: 10),
            _TypeSelector(
              types: _types,
              selected: _type,
              onChanged: (v) => setState(() => _type = v),
            ),
            const SizedBox(height: 28),
            _SectionLabel('ADET'),
            const SizedBox(height: 10),
            _AmountSelector(
              value: _amount,
              onChanged: (v) => setState(() => _amount = v),
            ),
            const SizedBox(height: 28),
            _SectionLabel('MARKA (OPSİYONEL)'),
            const SizedBox(height: 10),
            _BrandSelector(
              brands: _brands,
              selected: _brand,
              customController: _customBrandCtrl,
              onChanged: (v) => setState(() => _brand = v),
            ),
            const SizedBox(height: 28),
            _SectionLabel('TETİKLEYİCİ'),
            const SizedBox(height: 10),
            _TriggerGrid(
              selected: _trigger,
              onChanged: (v) => setState(() => _trigger = v == _trigger ? null : v),
            ),
            const SizedBox(height: 28),
            _SectionLabel('NOT (OPSİYONEL)'),
            const SizedBox(height: 10),
            TextField(
              controller: _noteCtrl,
              maxLength: 200,
              maxLines: 3,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Ne hissediyorsun?',
                counterStyle: TextStyle(color: AppColors.textDisabled, fontSize: 12),
              ),
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.black),
                    )
                  : const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tür seçimi ────────────────────────────────────────────────────────────────

class _TypeSelector extends StatelessWidget {
  final List<Map<String, String>> types;
  final String selected;
  final ValueChanged<String> onChanged;

  const _TypeSelector({
    required this.types,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: types.map((t) {
        final isSelected = selected == t['id'];
        return GestureDetector(
          onTap: () => onChanged(t['id']!),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primaryContainer : AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.divider,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Text(
              '${t['emoji']} ${t['label']}',
              style: TextStyle(
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 15,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Adet seçici ──────────────────────────────────────────────────────────────

class _AmountSelector extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const _AmountSelector({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _CircleBtn(
          icon: Icons.remove,
          enabled: value > 1,
          onTap: () => onChanged(value - 1),
        ),
        const SizedBox(width: 20),
        SizedBox(
          width: 56,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(width: 20),
        _CircleBtn(
          icon: Icons.add,
          enabled: value < 99,
          onTap: () => onChanged(value + 1),
        ),
      ],
    );
  }
}

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _CircleBtn({required this.icon, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: enabled ? AppColors.primaryContainer : AppColors.surface,
          border: Border.all(
            color: enabled ? AppColors.primary : AppColors.divider,
          ),
        ),
        child: Icon(
          icon,
          color: enabled ? AppColors.primary : AppColors.textDisabled,
          size: 22,
        ),
      ),
    );
  }
}

// ── Tetikleyici grid ─────────────────────────────────────────────────────────

class _BrandSelector extends StatelessWidget {
  final List<String> brands;
  final String? selected;
  final TextEditingController customController;
  final ValueChanged<String?> onChanged;

  const _BrandSelector({
    required this.brands,
    required this.selected,
    required this.customController,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isCustom = selected == 'Özel';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: brands.map((b) {
            final isSelected = selected == b;
            return GestureDetector(
              onTap: () => onChanged(b),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primaryContainer : AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.divider,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Text(
                  b,
                  style: TextStyle(
                    color: isSelected ? AppColors.primary : AppColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        if (isCustom) ...[
          const SizedBox(height: 12),
          TextField(
            controller: customController,
            maxLength: 40,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: const InputDecoration(
              hintText: 'Marka adı yazın',
              counterStyle: TextStyle(color: AppColors.textDisabled, fontSize: 12),
            ),
            onChanged: (_) => onChanged('Özel'),
          ),
        ],
      ],
    );
  }
}

// ── Tetikleyici grid ─────────────────────────────────────────────────────────

class _TriggerGrid extends StatelessWidget {
  final String? selected;
  final ValueChanged<String> onChanged;

  const _TriggerGrid({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: AppTrigger.all.map((t) {
        final isSelected = selected == t.id;
        return GestureDetector(
          onTap: () => onChanged(t.id),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primaryContainer : AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.divider,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Text(
              '${t.emoji} ${t.label}',
              style: TextStyle(
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Yardımcı ─────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

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
