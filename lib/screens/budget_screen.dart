import 'package:expense_tracker_fresh/models/budget_model.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/budget_service.dart';
import '../services/transaction_service.dart';
import '../utils/constants.dart';
import '../utils/categories.dart';
import '../models/transaction_model.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  final BudgetService _budgetService = BudgetService();
  final TransactionService _transactionService = TransactionService();
  final TextEditingController _budgetController = TextEditingController();
  String _selectedCategory = expenseCategories.first.name;
  bool _isSettingBudget = false;

  // Map to store expense totals per category
  Map<String, double> _categoryExpenses = {};

  @override
  void initState() {
    super.initState();
    _loadCategoryExpenses();
  }

  Future<void> _loadCategoryExpenses() async {
    // This will be refreshed in the builder
  }

  Future<void> _setBudget() async {
    final limit = double.tryParse(_budgetController.text);
    if (limit == null || limit <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    setState(() => _isSettingBudget = true);

    try {
      await _budgetService.setBudget(_selectedCategory, limit);
      _budgetController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Budget set successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }

    setState(() => _isSettingBudget = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Budget Planner'),
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: AppGradients.primary),
        ),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(
          left: AppSpacing.md,
          right: AppSpacing.md,
          top: AppSpacing.md,
          bottom: 80,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---------- Monthly Overview ----------
            _buildMonthlyOverview(),
            const SizedBox(height: AppSpacing.lg),

            // ---------- Set Budget Card ----------
            _buildSetBudgetCard(),
            const SizedBox(height: AppSpacing.lg),

            // ---------- Budget List ----------
            Text(
              'Your Budgets',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            StreamBuilder<List<BudgetModel>>(
              stream: _budgetService.getBudgets(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }

                final budgets = snapshot.data ?? [];
                if (budgets.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: AppDecorations.glassCard(),
                    child: const Center(
                      child: Text(
                        'No budgets set yet.\nSet your first budget above!',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  );
                }

                return FutureBuilder<Map<String, double>>(
                  future: _getCategoryExpenses(budgets),
                  builder: (context, expenseSnapshot) {
                    final expenseMap = expenseSnapshot.data ?? {};
                    return Column(
                      children: budgets.map((budget) {
                        final spent = expenseMap[budget.category] ?? 0;
                        final percentage = budget.monthlyLimit > 0
                            ? (spent / budget.monthlyLimit) * 100
                            : 0;
                        final isOverBudget = percentage >= 100;

                        // Get category icon and color
                        final category = expenseCategories.firstWhere(
                          (c) => c.name == budget.category,
                          orElse: () => const Category(
                            name: '',
                            icon: Icons.category,
                            color: Colors.grey,
                          ),
                        );

                        return Container(
                          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            gradient: AppGradients.card,
                            borderRadius: BorderRadius.circular(
                              AppRadius.medium,
                            ),
                            border: Border.all(
                              color: isOverBudget
                                  ? AppColors.expense.withOpacity(0.5)
                                  : AppColors.border,
                              width: 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              // Category row
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        category.icon,
                                        color: category.color,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        budget.category,
                                        style: AppTextStyles.bodyLarge,
                                      ),
                                    ],
                                  ),
                                  if (isOverBudget)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.expense.withOpacity(
                                          0.2,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Text(
                                        '⚠ Over Budget',
                                        style: TextStyle(
                                          color: AppColors.expense,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // Spent vs Limit
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '₹${spent.toStringAsFixed(2)} spent',
                                    style: TextStyle(
                                      color: isOverBudget
                                          ? AppColors.expense
                                          : AppColors.textSecondary,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    '₹${budget.monthlyLimit.toStringAsFixed(2)} limit',
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              // Progress bar
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: percentage > 100
                                      ? 1
                                      : percentage / 100,
                                  minHeight: 8,
                                  backgroundColor: AppColors.card,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    isOverBudget
                                        ? AppColors.expense
                                        : percentage > 80
                                        ? Colors.orange
                                        : AppColors.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${percentage.toStringAsFixed(1)}% used',
                                style: TextStyle(
                                  color: AppColors.textTertiary,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ---------- Monthly Overview Card ----------
  Widget _buildMonthlyOverview() {
    return FutureBuilder<double>(
      future: _budgetService.getTotalExpenseThisMonth(),
      builder: (context, snapshot) {
        final totalExpense = snapshot.data ?? 0.0;
        return Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            gradient: AppGradients.primary,
            borderRadius: BorderRadius.circular(AppRadius.large),
            boxShadow: AppShadows.soft,
          ),
          child: Column(
            children: [
              const Text(
                'Monthly Overview',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Text(
                '₹${totalExpense.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Total spent this month',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------- Set Budget Card ----------
  Widget _buildSetBudgetCard() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: AppDecorations.glassCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Set Monthly Budget',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Category Dropdown
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: 'Select Category',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.medium),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: AppColors.card,
            ),
            value: _selectedCategory,
            items: expenseCategories.map((cat) {
              return DropdownMenuItem(
                value: cat.name,
                child: Row(
                  children: [
                    Icon(cat.icon, color: cat.color),
                    const SizedBox(width: 8),
                    Text(cat.name),
                  ],
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() => _selectedCategory = value!);
            },
          ),
          const SizedBox(height: AppSpacing.md),

          // Amount Field
          TextField(
            controller: _budgetController,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.currency_rupee),
              hintText: 'Enter monthly limit',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.medium),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: AppColors.card,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Set Budget Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isSettingBudget ? null : _setBudget,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.medium),
                ),
                elevation: 0,
              ),
              child: _isSettingBudget
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Set Budget',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Helper ----------
  Future<Map<String, double>> _getCategoryExpenses(
    List<BudgetModel> budgets,
  ) async {
    Map<String, double> result = {};
    for (var budget in budgets) {
      final spent = await _budgetService.getCategoryExpenseThisMonth(
        budget.category,
      );
      result[budget.category] = spent;
    }
    return result;
  }
}
