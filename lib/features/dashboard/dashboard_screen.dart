import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sigara_defteri/app/router.dart';
import 'package:sigara_defteri/models/smoke_entry.dart';
import 'package:sigara_defteri/models/trigger.dart';
import 'package:sigara_defteri/providers/smoke_providers.dart';
import 'package:sigara_defteri/providers/stats_providers.dart';
import 'package:sigara_defteri/shared/theme/app_theme.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(todayEntriesProvider);
    final totalCount = ref.watch(todayCountProvider);
    final streak = ref.watch(streakProvider);
    final cost = ref.watch(todayCostProvider);
    final breakdown = ref.watch(todayTypeBreakdownProvider);
    final settings = ref.watch(settingsProvider);
    final weeklyMini = ref.watch(weeklyMiniProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sigara Defteri'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Ayarlar',
            onPressed: () => Navigator.pushNamed(context, AppRouter.settings),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          _TodaySummaryCard(
            totalCount: totalCount,
            breakdown: breakdown,
            hasEntries: entries.isNotEmpty,
          ),
          const SizedBox(height: 10),
          _StreakCard(streak: streak, hasEntriesToday: entries.isNotEmpty),
          if (settings.pricePerPack > 0) ...[
            const SizedBox(height: 10),
            _CostCard(cost: cost),
          ],
          const SizedBox(height: 10),
          _WeeklyMiniCard(mini: weeklyMini, showCost: settings.pricePerPack > 0),
          const SizedBox(height: 8),
          _StatsLink(onTap: () => Navigator.pushNamed(context, AppRouter.stats)),
          if (entries.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Padding(
              padding: EdgeInsets.only(left: 2, bottom: 10),
              child: Text(
                'BUGÜNKÜ KAYITLAR',
                style: TextStyle(
                  color: AppColors.textDisabled,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            ...entries.map((e) => _EntryTile(entry: e, ref: ref)),
          ],
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        foregroundColor: const Color(0xFF1A1200),
        onPressed: () async {
          final result = await Navigator.pushNamed(context, AppRouter.log);
          if (result == true) {
            ref.read(todayEntriesProvider.notifier).refresh();
          }
        },
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }
}

// ── Bugün özet kartı ─────────────────────────────────────────────────────────

class _TodaySummaryCard extends StatelessWidget {
  final int totalCount;
  final Map<String, int> breakdown;
  final bool hasEntries;

  const _TodaySummaryCard({
    required this.totalCount,
    required this.breakdown,
    required this.hasEntries,
  });

  static const _typeLabels = {
    'sigara': 'sigara',
    'vape': 'vape',
    'puro': 'puro',
    'nargile': 'nargile',
  };

  String get _breakdownText {
    if (!hasEntries) return 'Henüz kayıt yok';
    return breakdown.entries
        .map((e) => '${e.value} ${_typeLabels[e.key] ?? e.key}')
        .join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const Text('🚬', style: TextStyle(fontSize: 36)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'BUGÜN',
                    style: TextStyle(
                      color: AppColors.textDisabled,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hasEntries ? '$totalCount adet' : '—',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _breakdownText,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Streak kartı ─────────────────────────────────────────────────────────────

class _StreakCard extends StatelessWidget {
  final int streak;
  final bool hasEntriesToday;

  const _StreakCard({required this.streak, required this.hasEntriesToday});

  @override
  Widget build(BuildContext context) {
    final String emoji;
    final String title;
    final String subtitle;

    if (!hasEntriesToday) {
      emoji = '✨';
      title = 'Bugün henüz kayıt yok';
      subtitle = 'Kayıt eklemek için + butonuna bas';
    } else if (streak >= 3) {
      emoji = '🔥';
      title = '$streak gündür azalma trendi';
      subtitle = 'Harika gidiyorsun, böyle devam!';
    } else if (streak > 0) {
      emoji = '📉';
      title = '$streak gündür azalma trendi';
      subtitle = 'Azalmaya devam ediyorsun';
    } else {
      emoji = '📊';
      title = 'Azalma trendi yok';
      subtitle = 'Dünden az içersen trend başlar';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Maliyet kartı ────────────────────────────────────────────────────────────

class _CostCard extends StatelessWidget {
  final double cost;
  const _CostCard({required this.cost});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const Text('💰', style: TextStyle(fontSize: 28)),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'BUGÜNKÜ MALİYET',
                  style: TextStyle(
                    color: AppColors.textDisabled,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  cost > 0 ? '₺${cost.toStringAsFixed(2)}' : '—',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Haftalık mini kart ───────────────────────────────────────────────────────

class _WeeklyMiniCard extends StatelessWidget {
  final WeeklyMini mini;
  final bool showCost;

  const _WeeklyMiniCard({required this.mini, required this.showCost});

  @override
  Widget build(BuildContext context) {
    final isDown = mini.percentChange < -0.5;
    final isUp = mini.percentChange > 0.5;
    final trendColor = isDown
        ? AppColors.success
        : isUp
            ? AppColors.error
            : AppColors.textSecondary;
    final trendIcon = isDown ? '↓' : isUp ? '↑' : '→';
    final trendText = isDown
        ? '${mini.percentChange.abs().toStringAsFixed(0)}% azaldı'
        : isUp
            ? '${mini.percentChange.toStringAsFixed(0)}% arttı'
            : 'Değişmedi';

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'BU HAFTA',
                    style: TextStyle(
                      color: AppColors.textDisabled,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    mini.total > 0 ? '${mini.total} adet' : '—',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (showCost && mini.cost > 0)
                    Text(
                      '₺${mini.cost.toStringAsFixed(2)} harcandı',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                ],
              ),
            ),
            if (mini.total > 0) ...[
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    trendIcon,
                    style: TextStyle(
                      color: trendColor,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    trendText,
                    style: TextStyle(
                      color: trendColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── İstatistik linki ─────────────────────────────────────────────────────────

class _StatsLink extends StatelessWidget {
  final VoidCallback onTap;
  const _StatsLink({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: const Row(
          children: [
            Icon(Icons.bar_chart_rounded, color: AppColors.primary, size: 20),
            SizedBox(width: 10),
            Text(
              'Detaylı istatistikler',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            Spacer(),
            Icon(Icons.chevron_right, color: AppColors.textDisabled, size: 20),
          ],
        ),
      ),
    );
  }
}

// ── Kayıt satırı ─────────────────────────────────────────────────────────────

class _EntryTile extends StatelessWidget {
  final SmokeEntry entry;
  final WidgetRef ref;

  const _EntryTile({required this.entry, required this.ref});

  static const _typeEmojis = {
    'sigara': '🚬',
    'vape': '💨',
    'puro': '🍃',
    'nargile': '🫧',
  };

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final trigger = AppTrigger.findById(entry.trigger);

    return Dismissible(
      key: ValueKey(entry.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
        ),
        child: const Icon(Icons.delete_outline, color: AppColors.error, size: 22),
      ),
      confirmDismiss: (_) async => _confirmDelete(context),
      onDismissed: (_) {
        ref.read(todayEntriesProvider.notifier).remove(entry.id);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 44,
                child: Text(
                  _formatTime(entry.createdAt),
                  style: const TextStyle(
                    color: AppColors.textDisabled,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                _typeEmojis[entry.type] ?? '🚬',
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          _capitalize(entry.type),
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${entry.amount} adet',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (trigger != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${trigger.emoji} ${trigger.label}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                    if (entry.note != null && entry.note!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        entry.note!,
                        style: const TextStyle(
                          color: AppColors.textDisabled,
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  Future<bool> _confirmDelete(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Kaydı sil?',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: const Text(
          'Bu işlem geri alınamaz.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
