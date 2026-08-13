import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

/// Finance module — revenue, expenses, net, and monthly expense chart.
class FinanceScreen extends StatelessWidget {
  const FinanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final s = app.stats;
    final currency = app.settings.currency;
    final net = s.profitLoss;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E252E) : AppColors.surface;
    final monthly = app.monthlyExpenses;
    final totalMonthly =
        monthly.values.fold<double>(0, (a, b) => a + b);
    final avg = monthly.isEmpty ? 0.0 : totalMonthly / monthly.length;

    return Scaffold(
      appBar: AppBar(title: const Text('Finance')),
      body: RefreshIndicator(
        color: AppColors.primaryBlue,
        onRefresh: app.refreshDashboard,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 36),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 22),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                border: isDark ? null : Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Financial Summary',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _FinanceColumn(
                          icon: Icons.arrow_upward_rounded,
                          value: Formatters.money(
                            s.totalReceived,
                            currency: currency,
                          ),
                          label: 'Revenue',
                        ),
                      ),
                      Expanded(
                        child: _FinanceColumn(
                          icon: Icons.arrow_downward_rounded,
                          value: Formatters.money(
                            s.totalExpenses,
                            currency: currency,
                          ),
                          label: 'Expenses',
                        ),
                      ),
                      Expanded(
                        child: _FinanceColumn(
                          icon: Icons.savings_outlined,
                          value: net >= 0
                              ? Formatters.money(net, currency: currency)
                              : '-${Formatters.money(net.abs(), currency: currency)}',
                          label: net >= 0 ? 'Net Profit' : 'Net Loss',
                          valueColor: net >= 0
                              ? AppColors.success
                              : const Color(0xFFFF8A80),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                border: isDark ? null : Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Monthly Expenses',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 180,
                    child: _MonthlyChart(monthly: monthly, isDark: isDark),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        'Total: ${Formatters.money(totalMonthly, currency: currency)}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const Spacer(),
                      Text(
                        'Avg: ${Formatters.money(avg, currency: currency)}/mo',
                        style: TextStyle(
                          color: AppColors.textMuted(context),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                border: isDark ? null : Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pending payments',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMuted(context),
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    Formatters.money(s.pendingPayments, currency: currency),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFFE53935),
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

class _FinanceColumn extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color? valueColor;

  const _FinanceColumn({
    required this.icon,
    required this.value,
    required this.label,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).brightness == Brightness.dark
        ? Colors.white70
        : AppColors.slate;
    return Column(
      children: [
        Icon(icon, size: 18, color: muted),
        const SizedBox(height: 8),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: valueColor,
              ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: muted),
        ),
      ],
    );
  }
}

class _MonthlyChart extends StatelessWidget {
  final Map<String, double> monthly;
  final bool isDark;

  const _MonthlyChart({required this.monthly, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final entries = monthly.entries.toList();
    if (entries.isEmpty) {
      return Center(
        child: Text(
          'No expense data yet',
          style: TextStyle(color: AppColors.textMuted(context)),
        ),
      );
    }

    final maxY = entries.map((e) => e.value).fold<double>(0, (a, b) => a > b ? a : b);
    final spots = <FlSpot>[
      for (var i = 0; i < entries.length; i++)
        FlSpot(i.toDouble(), entries[i].value),
    ];

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxY <= 0 ? 1 : maxY * 1.2,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (v) => FlLine(
            color: isDark ? Colors.white12 : AppColors.border,
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              getTitlesWidget: (v, _) => Text(
                v == 0 ? '0' : NumberFormat.compact().format(v),
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.textMuted(context),
                ),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (v, _) {
                final i = v.round();
                if (i < 0 || i >= entries.length) return const SizedBox.shrink();
                final label = entries[i].key;
                final month = DateTime.tryParse('$label-01');
                final text = month == null
                    ? label
                    : DateFormat('MMM').format(month);
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    text,
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.textMuted(context),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppColors.primaryBlue,
            barWidth: 3,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.primaryBlue.withValues(alpha: 0.15),
            ),
          ),
        ],
      ),
    );
  }
}
