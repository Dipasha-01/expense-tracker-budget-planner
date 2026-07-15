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
  bool _isLoading = false;
  bool _isSettingBudget = false;

  // Map to store expense totals per category
  Map<String, double> _categoryExpenses = {};

  @override
  void initState() {
    super.initState();
    _loadCategoryExpenses();
  }

  Future<void> _loadCategoryExpenses() async {
    final expenses = await _budgetService.getTotalExpenseThisMonth();
    // We'll load per-category expenses in the builder
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
          decoration: BoxDecoration(gradient: AppColors.primaryGradient),
        ),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Monthly Budget Overview
            _buildMonthlyOverview(),
            const SizedBox(height: 24),

            // Set Budget Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppColors.cardShadow,
              ),
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
                  const SizedBox(height: 12),

                  // Category Dropdown
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Select Category',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
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
                      setState(() {
                        _selectedCategory = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 12),

                  // Amount Field
                  TextField(
                    controller: _budgetController,
                    keyboardType: TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.currency_rupee),
                      hintText: 'Enter monthly limit',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Set Budget Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isSettingBudget ? null : _setBudget,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
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
            ),
            const SizedBox(height: 24),

            // Budget List
            Text(
              'Your Budgets',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 12),

            StreamBuilder<List<BudgetModel>>(
              stream: _budgetService.getBudgets(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final budgets = snapshot.data ?? [];
                if (budgets.isEmpty) {
                  return Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Center(
                        child: Text(
                          'No budgets set yet.\nSet your first budget above!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textLight),
                        ),
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

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: AppColors.cardShadow,
                            border: isOverBudget
                                ? Border.all(color: AppColors.expense, width: 2)
                                : null,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Category Header
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        _getCategoryIcon(budget.category),
                                        color: _getCategoryColor(
                                          budget.category,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        budget.category,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (isOverBudget)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.expense,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Text(
                                        '⚠ Over Budget',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // Amounts
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '₹${spent.toStringAsFixed(2)} spent',
                                    style: TextStyle(
                                      color: isOverBudget
                                          ? AppColors.expense
                                          : AppColors.textLight,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    '₹${budget.monthlyLimit.toStringAsFixed(2)} limit',
                                    style: TextStyle(
                                      color: AppColors.textLight,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // Progress Bar
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: percentage > 100
                                      ? 1
                                      : percentage / 100,
                                  minHeight: 8,
                                  backgroundColor: Colors.grey.shade200,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    isOverBudget
                                        ? AppColors.expense
                                        : percentage > 80
                                        ? Colors.orange
                                        : AppColors.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${percentage.toStringAsFixed(1)}% used',
                                style: TextStyle(
                                  color: AppColors.textLight,
                                  fontSize: 12,
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

  Widget _buildMonthlyOverview() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0x336C63FF),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Monthly Overview',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          FutureBuilder<double>(
            future: _budgetService.getTotalExpenseThisMonth(),
            builder: (context, snapshot) {
              final totalExpense = snapshot.data ?? 0.0;
              return Text(
                '₹${totalExpense.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              );
            },
          ),
          const SizedBox(height: 4),
          const Text(
            'Total spent this month',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

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

  IconData _getCategoryIcon(String name) {
    final category = expenseCategories.firstWhere(
      (cat) => cat.name == name,
      orElse: () => expenseCategories.last,
    );
    return category.icon;
  }

  Color _getCategoryColor(String name) {
    final category = expenseCategories.firstWhere(
      (cat) => cat.name == name,
      orElse: () => expenseCategories.last,
    );
    return category.color;
  }
}
