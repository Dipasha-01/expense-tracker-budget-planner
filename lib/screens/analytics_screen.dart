import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/chart_service.dart';
import '../services/transaction_service.dart';
import '../services/pdf_service.dart'; // ✅ Added import
import '../models/transaction_model.dart';
import '../utils/constants.dart';
import '../utils/categories.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final ChartService _chartService = ChartService();
  final TransactionService _transactionService = TransactionService();

  String _selectedPeriod = 'This Month';
  final List<String> _periods = [
    'This Month',
    'Last Month',
    'Last 3 Months',
    'Last 6 Months',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Analytics'),
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: AppGradients.primary),
        ),
        foregroundColor: Colors.white,
        elevation: 0,
        // ✅ Added actions with PDF export button
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () async {
              final now = DateTime.now();
              try {
                await PdfService().generateMonthlyReport(
                  context,
                  now.year,
                  now.month,
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: ${e.toString()}')),
                );
              }
            },
          ),
        ],
        // ✅ Reduced height from 50 to 40
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(40),
          child: _buildPeriodSelector(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            _buildSummaryCard(),
            const SizedBox(height: AppSpacing.lg),
            _buildPieChart(),
            const SizedBox(height: AppSpacing.lg),
            _buildBarChart(),
            const SizedBox(height: AppSpacing.lg),
            _buildLineChart(),
            const SizedBox(height: AppSpacing.lg),
            _buildTopCategories(),
          ],
        ),
      ),
    );
  }

  // ---------- Compact Period Selector ----------
  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 4,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: Colors.white70, size: 14),
            const SizedBox(width: 6),
            ..._periods.map((period) {
              final isSelected = _selectedPeriod == period;
              return Padding(
                padding: const EdgeInsets.only(right: 4.0),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedPeriod = period;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white.withOpacity(0.2)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? Colors.white
                            : Colors.white.withOpacity(0.3),
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      period,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white70,
                        fontSize: 10,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  // ---------- Summary Card (compact) ----------
  Widget _buildSummaryCard() {
    return FutureBuilder<Map<String, double>>(
      future: _getTotals(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: 70,
            decoration: AppDecorations.glassCard(),
            child: const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        final data = snapshot.data ?? {};
        final income = data['income'] ?? 0;
        final expense = data['expense'] ?? 0;
        final savings = income - expense;

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: AppDecorations.glassCard(),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'Income',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 9,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '₹${income.toStringAsFixed(0)}',
                      style: AppTextStyles.amountSmall.copyWith(
                        color: AppColors.income,
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(height: 25, width: 1, color: AppColors.border),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'Expense',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 9,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '₹${expense.toStringAsFixed(0)}',
                      style: AppTextStyles.amountSmall.copyWith(
                        color: AppColors.expense,
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(height: 25, width: 1, color: AppColors.border),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'Savings',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 9,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '₹${savings.toStringAsFixed(0)}',
                      style: AppTextStyles.amountSmall.copyWith(
                        color: savings >= 0
                            ? AppColors.accent
                            : AppColors.expense,
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------- Pie Chart ----------
  Widget _buildPieChart() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: AppDecorations.glassCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Expense Distribution',
                style: AppTextStyles.heading4.copyWith(fontSize: 16),
              ),
              Text(
                'Pie Chart',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textTertiary,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FutureBuilder<Map<String, double>>(
            future: _chartService.getCategoryBreakdown(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 180,
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                );
              }

              final data = snapshot.data ?? {};
              if (data.isEmpty) {
                return const SizedBox(
                  height: 180,
                  child: Center(
                    child: Text(
                      'No expense data available',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                );
              }

              final entries = data.entries.toList();
              final total = entries.fold(
                0.0,
                (sum, entry) => sum + entry.value,
              );
              final colors = [
                AppColors.primary,
                AppColors.secondary,
                AppColors.expense,
                AppColors.income,
                Colors.orange,
                Colors.cyan,
                Colors.pink,
                Colors.teal,
                Colors.purple,
                Colors.indigo,
              ];

              List<PieChartSectionData> sections = [];
              for (int i = 0; i < entries.length; i++) {
                final entry = entries[i];
                final percentage = total > 0 ? (entry.value / total) * 100 : 0;
                sections.add(
                  PieChartSectionData(
                    color: colors[i % colors.length],
                    value: entry.value,
                    title: '${percentage.toStringAsFixed(0)}%',
                    radius: 70,
                    titleStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }

              return SizedBox(
                height: 200,
                child: PieChart(
                  PieChartData(
                    sections: sections,
                    sectionsSpace: 2,
                    centerSpaceRadius: 35,
                    startDegreeOffset: -90,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          FutureBuilder<Map<String, double>>(
            future: _chartService.getCategoryBreakdown(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox.shrink();
              final data = snapshot.data ?? {};
              final entries = data.entries.toList();
              final colors = [
                AppColors.primary,
                AppColors.secondary,
                AppColors.expense,
                AppColors.income,
                Colors.orange,
                Colors.cyan,
                Colors.pink,
                Colors.teal,
                Colors.purple,
                Colors.indigo,
              ];

              List<Widget> legendItems = [];
              for (int i = 0; i < entries.length && i < 5; i++) {
                final entry = entries[i];
                legendItems.add(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        color: colors[i % colors.length],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${entry.key} (₹${entry.value.toStringAsFixed(0)})',
                        style: AppTextStyles.bodySmall.copyWith(fontSize: 9),
                      ),
                    ],
                  ),
                );
              }
              return Wrap(spacing: 6, children: legendItems);
            },
          ),
        ],
      ),
    );
  }

  // ---------- Bar Chart ----------
  Widget _buildBarChart() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: AppDecorations.glassCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Monthly Income vs Expense',
                style: AppTextStyles.heading4.copyWith(fontSize: 16),
              ),
              Text(
                'Bar Chart',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textTertiary,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FutureBuilder<Map<String, Map<String, double>>>(
            future: _chartService.getMonthlyIncomeExpense(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 180,
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                );
              }

              final data = snapshot.data ?? {};
              if (data.isEmpty) {
                return const SizedBox(
                  height: 180,
                  child: Center(
                    child: Text(
                      'No data available',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                );
              }

              final keys = data.keys.toList();
              final incomeValues = keys
                  .map((k) => data[k]!['income'] ?? 0)
                  .toList();
              final expenseValues = keys
                  .map((k) => data[k]!['expense'] ?? 0)
                  .toList();
              final maxValue = [
                ...incomeValues,
                ...expenseValues,
              ].reduce((a, b) => a > b ? a : b);

              List<BarChartGroupData> barGroups = [];
              for (int i = 0; i < keys.length; i++) {
                final key = keys[i];
                final income = data[key]!['income'] ?? 0;
                final expense = data[key]!['expense'] ?? 0;
                barGroups.add(
                  BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: income,
                        color: AppColors.income,
                        width: 10,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(3),
                        ),
                      ),
                      BarChartRodData(
                        toY: expense,
                        color: AppColors.expense,
                        width: 10,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(3),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return SizedBox(
                height: 180,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: maxValue + 150,
                    barGroups: barGroups,
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index >= 0 && index < keys.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  keys[index],
                                  style: AppTextStyles.bodySmall.copyWith(
                                    fontSize: 8,
                                  ),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    gridData: const FlGridData(show: false),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Container(width: 10, height: 10, color: AppColors.income),
                  const SizedBox(width: 3),
                  Text(
                    'Income',
                    style: AppTextStyles.bodySmall.copyWith(fontSize: 10),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Row(
                children: [
                  Container(width: 10, height: 10, color: AppColors.expense),
                  const SizedBox(width: 3),
                  Text(
                    'Expense',
                    style: AppTextStyles.bodySmall.copyWith(fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------- Line Chart ----------
  Widget _buildLineChart() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: AppDecorations.glassCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Daily Spending',
                style: AppTextStyles.heading4.copyWith(fontSize: 16),
              ),
              Text(
                'Line Chart',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textTertiary,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FutureBuilder<Map<String, double>>(
            future: _chartService.getDailySpending(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 160,
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                );
              }

              final data = snapshot.data ?? {};
              if (data.isEmpty) {
                return const SizedBox(
                  height: 160,
                  child: Center(
                    child: Text(
                      'No spending data available',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                );
              }

              final keys = data.keys.toList();
              final values = keys.map((k) => data[k] ?? 0).toList();
              final maxValue = values.reduce((a, b) => a > b ? a : b);

              List<FlSpot> spots = [];
              for (int i = 0; i < values.length; i++) {
                spots.add(FlSpot(i.toDouble(), values[i]));
              }

              return SizedBox(
                height: 160,
                child: LineChart(
                  LineChartData(
                    minX: 0,
                    maxX: 6,
                    minY: 0,
                    maxY: maxValue + 50,
                    gridData: const FlGridData(show: false),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index >= 0 && index < keys.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  keys[index],
                                  style: AppTextStyles.bodySmall.copyWith(
                                    fontSize: 8,
                                  ),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        color: AppColors.primary,
                        barWidth: 2,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, barData, index) {
                            return FlDotCirclePainter(
                              radius: 3,
                              color: AppColors.primary,
                              strokeWidth: 1.5,
                              strokeColor: Colors.white,
                            );
                          },
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          color: AppColors.primary.withOpacity(0.15),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ---------- Top Categories ----------
  Widget _buildTopCategories() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: AppDecorations.glassCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Top Spending Categories',
                style: AppTextStyles.heading4.copyWith(fontSize: 16),
              ),
              Text(
                'This Month',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textTertiary,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FutureBuilder<List<MapEntry<String, double>>>(
            future: _chartService.getTopCategories(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                );
              }

              final data = snapshot.data ?? [];
              if (data.isEmpty) {
                return const Center(
                  child: Text(
                    'No data available',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                );
              }

              List<Widget> categoryWidgets = [];
              for (var entry in data) {
                final category = entry.key;
                final amount = entry.value;
                final categoryObj = expenseCategories.firstWhere(
                  (c) => c.name == category,
                  orElse: () => const Category(
                    name: '',
                    icon: Icons.category,
                    color: Colors.grey,
                  ),
                );
                categoryWidgets.add(
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Icon(
                          categoryObj.icon,
                          color: categoryObj.color,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                category,
                                style: AppTextStyles.bodyLarge.copyWith(
                                  fontSize: 13,
                                ),
                              ),
                              Container(
                                width: double.infinity,
                                height: 3,
                                decoration: BoxDecoration(
                                  color: AppColors.card,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: FractionallySizedBox(
                                  widthFactor: data.isNotEmpty
                                      ? amount / data.first.value
                                      : 0,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: categoryObj.color,
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '₹${amount.toStringAsFixed(0)}',
                          style: AppTextStyles.amountSmall.copyWith(
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return Column(children: categoryWidgets);
            },
          ),
        ],
      ),
    );
  }

  // ---------- Helper ----------
  Future<Map<String, double>> _getTotals() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 1);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return {};

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('transactions')
        .where('date', isGreaterThanOrEqualTo: start)
        .where('date', isLessThan: end)
        .get();

    double income = 0;
    double expense = 0;

    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final type = data['type'];
      final amount = (data['amount'] ?? 0.0).toDouble();
      if (type == TransactionType.income.name) {
        income += amount;
      } else {
        expense += amount;
      }
    }

    return {'income': income, 'expense': expense};
  }
}
