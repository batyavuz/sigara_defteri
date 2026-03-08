import 'dart:math' show max;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sigara_defteri/models/trigger.dart';
import 'package:sigara_defteri/providers/smoke_providers.dart';
import 'package:sigara_defteri/providers/stats_providers.dart';
import 'package:sigara_defteri/shared/theme/app_theme.dart';

// ── Tetikleyici renk paleti ───────────────────────────────────────────────────

const _triggerColors = {
  'stres': Color(0xFFE05C5C),
  'kahve': Color(0xFFD4A843),
  'sikilma': Color(0xFF7E8EAF),
  'sosyal': Color(0xFF4CAF82),
  'yemek': Color(0xFFE8A838),
  'alkol': Color(0xFF9C7ABE),
  'otomatik': Color(0xFF5BA5C8),
  'diger': Color(0xFF6E6E6E),
};

const _weekDayLabels = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];

// ── Ana ekran ─────────────────────────────────────────────────────────────────

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('İstatistikler'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textDisabled,
          indicatorColor: AppColors.primary,
          indicatorSize: TabBarIndicatorSize.label,
          tabs: const [
            Tab(text: 'Haftalık'),
            Tab(text: 'Aylık'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _WeeklyTab(),
          _MonthlyTab(),
        ],
      ),
    );
  }
}

// ── Haftalık Tab ──────────────────────────────────────────────────────────────

class _WeeklyTab extends ConsumerWidget {
  const _WeeklyTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totals = ref.watch(weeklyTotalsProvider);
    final comparison = ref.watch(weeklyComparisonProvider);
    final triggerDist = ref.watch(weeklyTriggerDistProvider);
    final costReport = ref.watch(costReportProvider);
    final settings = ref.watch(settingsProvider);

    final values = totals.values.toList();
    final dates = totals.keys.toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      children: [
        _SectionLabel('SON 7 GÜN'),
        const SizedBox(height: 10),
        _WeeklyBarChart(values: values, dates: dates),
        const SizedBox(height: 12),
        _WeeklyStatsRow(comparison: comparison, weeklyCost: costReport.week, showCost: settings.pricePerPack > 0),
        const SizedBox(height: 24),
        _SectionLabel('MALİYET RAPORU'),
        const SizedBox(height: 10),
        _CostReportGrid(report: costReport, showCost: settings.pricePerPack > 0),
        if (settings.pricePerPack > 0 && costReport.year > 0) ...[
          const SizedBox(height: 12),
          _YearlyCostBanner(amount: costReport.year),
        ],
        const SizedBox(height: 24),
        _SectionLabel('TETİKLEYİCİ DAĞILIMI (Son 7 Gün)'),
        const SizedBox(height: 10),
        _TriggerPieSection(distribution: triggerDist),
      ],
    );
  }
}

// ── Aylık Tab ─────────────────────────────────────────────────────────────────

class _MonthlyTab extends ConsumerWidget {
  const _MonthlyTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totals = ref.watch(monthlyTotalsProvider);
    final triggerDist = ref.watch(monthlyTriggerDistProvider);
    final costReport = ref.watch(costReportProvider);
    final settings = ref.watch(settingsProvider);

    final values = totals.values.toList();
    final totalCount = values.fold(0, (s, v) => s + v);
    final avgPerDay = values.isEmpty ? 0.0 : totalCount / values.length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      children: [
        _SectionLabel('SON 30 GÜN'),
        const SizedBox(height: 10),
        _MonthlyLineChart(values: values),
        const SizedBox(height: 12),
        _MonthlyStatsRow(
          total: totalCount,
          avgPerDay: avgPerDay,
          monthlyCost: costReport.month,
          showCost: settings.pricePerPack > 0,
        ),
        const SizedBox(height: 24),
        _SectionLabel('MALİYET RAPORU'),
        const SizedBox(height: 10),
        _CostReportGrid(report: costReport, showCost: settings.pricePerPack > 0),
        if (settings.pricePerPack > 0 && costReport.year > 0) ...[
          const SizedBox(height: 12),
          _YearlyCostBanner(amount: costReport.year),
        ],
        const SizedBox(height: 24),
        _SectionLabel('TETİKLEYİCİ DAĞILIMI (Son 30 Gün)'),
        const SizedBox(height: 10),
        _TriggerPieSection(distribution: triggerDist),
      ],
    );
  }
}

// ── Haftalık Bar Chart ────────────────────────────────────────────────────────

class _WeeklyBarChart extends StatelessWidget {
  final List<int> values;
  final List<DateTime> dates;

  const _WeeklyBarChart({required this.values, required this.dates});

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) return const _EmptyChart();

    final maxVal = values.fold(0, max).toDouble();
    final maxY = maxVal < 5 ? 6.0 : (maxVal * 1.25).ceilToDouble();

    return Container(
      height: 200,
      padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
      child: BarChart(
        BarChartData(
          maxY: maxY,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => AppColors.surface,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '${rod.toY.toInt()} adet',
                  const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: maxY > 10 ? (maxY / 4).roundToDouble() : 2,
                getTitlesWidget: (value, meta) => Text(
                  value.toInt().toString(),
                  style: const TextStyle(
                    color: AppColors.textDisabled,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= dates.length) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      _weekDayLabels[dates[i].weekday - 1],
                      style: TextStyle(
                        color: i == dates.length - 1
                            ? AppColors.primary
                            : AppColors.textDisabled,
                        fontSize: 11,
                        fontWeight: i == dates.length - 1
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => const FlLine(
              color: AppColors.divider,
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(values.length, (i) {
            final isToday = i == values.length - 1;
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: values[i].toDouble(),
                  color: isToday
                      ? AppColors.primary
                      : AppColors.primary.withValues(alpha: 0.45),
                  width: 18,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(6),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

// ── Aylık Line Chart ─────────────────────────────────────────────────────────

class _MonthlyLineChart extends StatelessWidget {
  final List<int> values;
  const _MonthlyLineChart({required this.values});

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) return const _EmptyChart();

    final maxVal = values.fold(0, max).toDouble();
    final maxY = maxVal < 5 ? 6.0 : (maxVal * 1.25).ceilToDouble();
    final spots = List.generate(
      values.length,
      (i) => FlSpot(i.toDouble(), values[i].toDouble()),
    );

    return Container(
      height: 200,
      padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: (values.length - 1).toDouble(),
          minY: 0,
          maxY: maxY,
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => AppColors.surface,
              getTooltipItems: (touchedSpots) => touchedSpots.map((s) {
                return LineTooltipItem(
                  '${s.y.toInt()} adet',
                  const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                );
              }).toList(),
            ),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: maxY > 10 ? (maxY / 4).roundToDouble() : 2,
                getTitlesWidget: (value, meta) => Text(
                  value.toInt().toString(),
                  style: const TextStyle(
                    color: AppColors.textDisabled,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: 7,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i == 0) return _axisLabel('30g');
                  if (i == 7) return _axisLabel('21g');
                  if (i == 14) return _axisLabel('14g');
                  if (i == 21) return _axisLabel('7g');
                  if (i == 29) return _axisLabel('Bugün');
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => const FlLine(
              color: AppColors.divider,
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.25,
              color: AppColors.primary,
              barWidth: 2.5,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.28),
                    AppColors.primary.withValues(alpha: 0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _axisLabel(String text) => Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text(
          text,
          style: const TextStyle(color: AppColors.textDisabled, fontSize: 10),
        ),
      );
}

// ── Haftalık istatistik satırı ────────────────────────────────────────────────

class _WeeklyStatsRow extends StatelessWidget {
  final WeeklyComparison comparison;
  final double weeklyCost;
  final bool showCost;

  const _WeeklyStatsRow({
    required this.comparison,
    required this.weeklyCost,
    required this.showCost,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Bu Hafta',
            value: '${comparison.thisWeek}',
            unit: 'adet',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            label: 'Geçen Hafta',
            value: '${comparison.lastWeek}',
            unit: 'adet',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _TrendCard(percentChange: comparison.percentChange),
        ),
      ],
    );
  }
}

// ── Aylık istatistik satırı ───────────────────────────────────────────────────

class _MonthlyStatsRow extends StatelessWidget {
  final int total;
  final double avgPerDay;
  final double monthlyCost;
  final bool showCost;

  const _MonthlyStatsRow({
    required this.total,
    required this.avgPerDay,
    required this.monthlyCost,
    required this.showCost,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(label: 'Bu Ay', value: '$total', unit: 'adet'),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            label: 'Günlük Ortalama',
            value: avgPerDay.toStringAsFixed(1),
            unit: 'adet/gün',
          ),
        ),
        if (showCost) ...[
          const SizedBox(width: 8),
          Expanded(
            child: _StatCard(
              label: 'Aylık Maliyet',
              value: '₺${monthlyCost.toStringAsFixed(0)}',
              unit: '',
              valueColor: AppColors.primary,
            ),
          ),
        ],
      ],
    );
  }
}

// ── Maliyet raporu grid ───────────────────────────────────────────────────────

class _CostReportGrid extends StatelessWidget {
  final CostReport report;
  final bool showCost;

  const _CostReportGrid({required this.report, required this.showCost});

  @override
  Widget build(BuildContext context) {
    if (!showCost) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.divider),
        ),
        child: const Text(
          'Maliyet hesabı için Ayarlar\'dan paket fiyatı gir.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          textAlign: TextAlign.center,
        ),
      );
    }

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 1.6,
      children: [
        _CostCell(label: 'Bugün', amount: report.today),
        _CostCell(label: 'Bu Hafta', amount: report.week),
        _CostCell(label: 'Bu Ay', amount: report.month),
        _CostCell(label: 'Bu Yıl', amount: report.year, highlight: true),
      ],
    );
  }
}

class _CostCell extends StatelessWidget {
  final String label;
  final double amount;
  final bool highlight;

  const _CostCell({required this.label, required this.amount, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: highlight ? AppColors.primaryContainer : AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: highlight ? AppColors.primaryDim : AppColors.divider,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                color: highlight ? AppColors.primary : AppColors.textDisabled,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₺',
                  style: TextStyle(
                    color: highlight ? AppColors.primary : AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 2),
                Text(
                  amount.toStringAsFixed(2),
                  style: TextStyle(
                    color: highlight ? AppColors.primary : AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    height: 1,
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

// ── Yıllık maliyet banner ─────────────────────────────────────────────────────

class _YearlyCostBanner extends StatelessWidget {
  final double amount;
  const _YearlyCostBanner({required this.amount});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryDim),
      ),
      child: Text(
        'Bu yıl sigara için ₺${amount.toStringAsFixed(0)} harcadın.',
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

// ── Tetikleyici Pie Chart ─────────────────────────────────────────────────────

class _TriggerPieSection extends StatelessWidget {
  final Map<String, int> distribution;
  const _TriggerPieSection({required this.distribution});

  @override
  Widget build(BuildContext context) {
    if (distribution.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.divider),
        ),
        child: const Center(
          child: Text(
            'Bu dönem için tetikleyici verisi yok.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final total = distribution.values.fold(0, (s, v) => s + v);
    final entries = distribution.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final sections = entries.map((e) {
      final color = _triggerColors[e.key] ?? AppColors.textDisabled;
      return PieChartSectionData(
        value: e.value.toDouble(),
        color: color,
        radius: 52,
        title: '',
        showTitle: false,
      );
    }).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 180,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sections: sections,
                    centerSpaceRadius: 52,
                    sectionsSpace: 3,
                    startDegreeOffset: -90,
                    pieTouchData: PieTouchData(enabled: false),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$total',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Text(
                      'adet',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),
          ...entries.map((e) {
            final trigger = AppTrigger.findById(e.key);
            final color = _triggerColors[e.key] ?? AppColors.textDisabled;
            final pct = total > 0 ? (e.value / total * 100).round() : 0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    trigger != null
                        ? '${trigger.emoji} ${trigger.label}'
                        : e.key,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${e.value} adet',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 36,
                    child: Text(
                      '%$pct',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: color,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ── Yardımcı küçük widgetlar ──────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color? valueColor;

  const _StatCard({
    required this.label,
    required this.value,
    required this.unit,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textDisabled,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (unit.isNotEmpty)
            Text(
              unit,
              style: const TextStyle(
                color: AppColors.textDisabled,
                fontSize: 11,
              ),
            ),
        ],
      ),
    );
  }
}

class _TrendCard extends StatelessWidget {
  final double percentChange;
  const _TrendCard({required this.percentChange});

  @override
  Widget build(BuildContext context) {
    final isDown = percentChange < -0.5;
    final isUp = percentChange > 0.5;
    final color = isDown
        ? AppColors.success
        : isUp
            ? AppColors.error
            : AppColors.textSecondary;
    final icon = isDown ? '↓' : isUp ? '↑' : '→';
    final label = isDown
        ? '${percentChange.abs().toStringAsFixed(0)}% azaldı'
        : isUp
            ? '${percentChange.toStringAsFixed(0)}% arttı'
            : 'Değişmedi';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Trend',
            style: TextStyle(
              color: AppColors.textDisabled,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            icon,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

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

class _EmptyChart extends StatelessWidget {
  const _EmptyChart();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
      child: const Center(
        child: Text(
          'Henüz yeterli veri yok',
          style: TextStyle(color: AppColors.textDisabled, fontSize: 14),
        ),
      ),
    );
  }
}
