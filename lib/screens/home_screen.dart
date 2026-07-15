import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/auth_service.dart';
import '../services/transaction_service.dart';
import '../services/chart_service.dart';
import '../models/transaction_model.dart';
import '../utils/constants.dart';
import '../utils/categories.dart';
import 'login_screen.dart';
import 'add_transaction_screen.dart';
import 'budget_screen.dart';
import 'transaction_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _auth = AuthService();
  final TransactionService _transactionService = TransactionService();
  final ChartService _chartService = ChartService();
  late Future<String?> _userNameFuture;
  late Future<Map<String, double>> _weeklySpendingFuture;

  @override
  void initState() {
    super.initState();
    _userNameFuture = _getUserName();
    _weeklySpendingFuture = _chartService.getDailySpending();
  }

  Future<String?> _getUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      if (user.displayName != null && user.displayName!.isNotEmpty) {
        return user.displayName;
      }
      if (user.email != null && user.email!.isNotEmpty) {
        return user.email!.split('@').first;
      }
    }
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('name');
    if (name != null && name.isNotEmpty) return name;
    final uid = await _auth.getCurrentUserId();
    if (uid != null) {
      final userData = await _auth.getUserData(uid);
      if (userData != null && userData.name.isNotEmpty) return userData.name;
    }
    return 'User';
  }

  Future<void> _logout() async {
    await _auth.logout();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  (double, double, double) _calculateTotals(
    List<TransactionModel> transactions,
  ) {
    double income = 0;
    double expense = 0;
    for (var t in transactions) {
      if (t.type == TransactionType.income) {
        income += t.amount;
      } else {
        expense += t.amount;
      }
    }
    return (income, expense, income - expense);
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('ExpenseX'),
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: AppGradients.primary),
        ),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.pie_chart),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const BudgetScreen()),
              );
            },
          ),
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: FutureBuilder<String?>(
        future: _userNameFuture,
        builder: (context, snapshot) {
          final userName = snapshot.data ?? 'User';
          return StreamBuilder<List<TransactionModel>>(
            stream: _transactionService.getTransactions(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                );
              }

              final transactions = snapshot.data ?? [];
              final (income, expense, balance) = _calculateTotals(transactions);
              final recentTransactions = transactions.take(5).toList();

              // Category spending (UI only)
              Map<String, double> categorySpending = {};
              for (var t in transactions.where(
                (t) => t.type == TransactionType.expense,
              )) {
                categorySpending[t.category] =
                    (categorySpending[t.category] ?? 0) + t.amount;
              }
              final sortedCategories = categorySpending.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value));
              final topCategory = sortedCategories.isNotEmpty
                  ? sortedCategories.first.key
                  : 'None';

              return SingleChildScrollView(
                padding: const EdgeInsets.only(
                  left: AppSpacing.md,
                  right: AppSpacing.md,
                  top: AppSpacing.md,
                  bottom: 80,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ---------- HEADER ----------
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_greeting()}, $userName',
                              style: AppTextStyles.heading3,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Here\'s your financial overview',
                              style: AppTextStyles.bodyMedium,
                            ),
                          ],
                        ),
                        CircleAvatar(
                          backgroundColor: AppColors.primary.withOpacity(0.2),
                          child: const Icon(
                            Icons.notifications_outlined,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // ---------- BALANCE CARD ----------
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        gradient: AppGradients.primary,
                        borderRadius: BorderRadius.circular(AppRadius.large),
                        boxShadow: AppShadows.soft,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Total Balance',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 500),
                            style: AppTextStyles.amountLarge.copyWith(
                              color: Colors.white,
                              fontSize: 40,
                            ),
                            child: Text('₹${balance.toStringAsFixed(2)}'),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                    horizontal: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.small,
                                    ),
                                    border: Border.all(
                                      color: AppColors.border,
                                      width: 1,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Income',
                                        style: AppTextStyles.caption.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '₹${income.toStringAsFixed(2)}',
                                        style: AppTextStyles.amountSmall
                                            .copyWith(color: AppColors.income),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                    horizontal: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.small,
                                    ),
                                    border: Border.all(
                                      color: AppColors.border,
                                      width: 1,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Expense',
                                        style: AppTextStyles.caption.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '₹${expense.toStringAsFixed(2)}',
                                        style: AppTextStyles.amountSmall
                                            .copyWith(color: AppColors.expense),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                    horizontal: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.small,
                                    ),
                                    border: Border.all(
                                      color: AppColors.border,
                                      width: 1,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Savings',
                                        style: AppTextStyles.caption.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '₹${(income - expense).toStringAsFixed(2)}',
                                        style: AppTextStyles.amountSmall
                                            .copyWith(
                                              color: (income - expense) >= 0
                                                  ? AppColors.accent
                                                  : AppColors.expense,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // ---------- QUICK ACTIONS ----------
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildQuickAction(
                          icon: Icons.trending_up,
                          label: 'Income',
                          color: AppColors.income,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AddTransactionScreen(
                                  initialType: TransactionType
                                      .income, // ✅ Preselect Income
                                ),
                              ),
                            );
                          },
                        ),
                        _buildQuickAction(
                          icon: Icons.trending_down,
                          label: 'Expense',
                          color: AppColors.expense,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AddTransactionScreen(
                                  initialType: TransactionType
                                      .expense, // ✅ Preselect Expense
                                ),
                              ),
                            );
                          },
                        ),
                        _buildQuickAction(
                          icon: Icons.pie_chart,
                          label: 'Budget',
                          color: AppColors.secondary,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const BudgetScreen(),
                              ),
                            );
                          },
                        ),
                        _buildQuickAction(
                          icon: Icons.history,
                          label: 'History',
                          color: AppColors.primary,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const TransactionListScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // ---------- WEEKLY SPENDING CHART (Dynamic) ----------
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        gradient: AppGradients.card,
                        borderRadius: BorderRadius.circular(AppRadius.large),
                        border: Border.all(color: AppColors.border, width: 1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Weekly Spending',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                'Last 7 days',
                                style: TextStyle(
                                  color: AppColors.textTertiary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          FutureBuilder<Map<String, double>>(
                            future: _weeklySpendingFuture,
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const SizedBox(
                                  height: 80,
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      color: AppColors.primary,
                                    ),
                                  ),
                                );
                              }
                              final data = snapshot.data ?? {};
                              final keys = data.keys.toList();
                              final values = keys
                                  .map((k) => data[k] ?? 0)
                                  .toList();
                              if (values.isEmpty ||
                                  values.every((v) => v == 0)) {
                                return const SizedBox(
                                  height: 80,
                                  child: Center(
                                    child: Text(
                                      'No spending this week',
                                      style: TextStyle(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                );
                              }
                              final maxValue = values.reduce(
                                (a, b) => a > b ? a : b,
                              );
                              return SizedBox(
                                height: 80,
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
                                            if (index >= 0 &&
                                                index < keys.length) {
                                              return Padding(
                                                padding: const EdgeInsets.only(
                                                  top: 4,
                                                ),
                                                child: Text(
                                                  keys[index],
                                                  style: AppTextStyles.bodySmall
                                                      .copyWith(fontSize: 9),
                                                ),
                                              );
                                            }
                                            return const SizedBox.shrink();
                                          },
                                        ),
                                      ),
                                      leftTitles: const AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: false,
                                        ),
                                      ),
                                      topTitles: const AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: false,
                                        ),
                                      ),
                                      rightTitles: const AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: false,
                                        ),
                                      ),
                                    ),
                                    lineBarsData: [
                                      LineChartBarData(
                                        spots: values.asMap().entries.map((e) {
                                          return FlSpot(
                                            e.key.toDouble(),
                                            e.value,
                                          );
                                        }).toList(),
                                        isCurved: true,
                                        color: AppColors.primary,
                                        barWidth: 2,
                                        dotData: FlDotData(
                                          show: true,
                                          getDotPainter:
                                              (spot, percent, barData, index) {
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
                                          color: AppColors.primary.withOpacity(
                                            0.15,
                                          ),
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
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // ---------- RECENT TRANSACTIONS ----------
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Recent Transactions',
                          style: AppTextStyles.heading4,
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const TransactionListScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            'See All',
                            style: TextStyle(color: AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    if (recentTransactions.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          gradient: AppGradients.card,
                          borderRadius: BorderRadius.circular(AppRadius.large),
                          border: Border.all(color: AppColors.border, width: 1),
                        ),
                        child: const Center(
                          child: Text(
                            'No transactions yet.\nTap + to add one.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: recentTransactions.length,
                        itemBuilder: (context, index) {
                          final t = recentTransactions[index];
                          final category = getCategoryByName(
                            t.category,
                            t.type == TransactionType.income,
                          );
                          return Container(
                            margin: const EdgeInsets.only(
                              bottom: AppSpacing.sm,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.sm,
                            ),
                            decoration: BoxDecoration(
                              gradient: AppGradients.card,
                              borderRadius: BorderRadius.circular(
                                AppRadius.medium,
                              ),
                              border: Border.all(
                                color: AppColors.border,
                                width: 1,
                              ),
                            ),
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: CircleAvatar(
                                backgroundColor:
                                    (category?.color ?? Colors.grey)
                                        .withOpacity(0.2),
                                child: Icon(
                                  category?.icon ?? Icons.category,
                                  color: category?.color ?? Colors.grey,
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                t.category,
                                style: AppTextStyles.bodyLarge,
                              ),
                              subtitle: Text(
                                DateFormat('dd MMM yyyy').format(t.date),
                                style: AppTextStyles.bodySmall,
                              ),
                              trailing: Text(
                                '${t.type == TransactionType.income ? '+' : '-'}₹${t.amount.toStringAsFixed(2)}',
                                style: AppTextStyles.amountSmall.copyWith(
                                  color: t.type == TransactionType.income
                                      ? AppColors.income
                                      : AppColors.expense,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          gradient: AppGradients.card,
          borderRadius: BorderRadius.circular(AppRadius.medium),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
