import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/transaction_service.dart';
import '../models/transaction_model.dart';
import '../utils/constants.dart';
import '../utils/categories.dart';

class TransactionListScreen extends StatefulWidget {
  const TransactionListScreen({super.key});

  @override
  State<TransactionListScreen> createState() => _TransactionListScreenState();
}

class _TransactionListScreenState extends State<TransactionListScreen> {
  final TransactionService _transactionService = TransactionService();
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  String _selectedFilter = 'All';
  String _selectedSort = 'Newest';
  String _selectedCategoryFilter = 'All';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Transactions'),
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: AppGradients.primary),
        ),
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(120),
          child: _buildSearchAndFilter(),
        ),
      ),
      body: StreamBuilder<List<TransactionModel>>(
        stream: _transactionService.getTransactions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: AppColors.expense),
              ),
            );
          }

          List<TransactionModel> transactions = snapshot.data ?? [];

          // Apply filters
          if (_selectedFilter == 'Income') {
            transactions = transactions
                .where((t) => t.type == TransactionType.income)
                .toList();
          } else if (_selectedFilter == 'Expense') {
            transactions = transactions
                .where((t) => t.type == TransactionType.expense)
                .toList();
          }

          if (_selectedCategoryFilter != 'All') {
            transactions = transactions
                .where((t) => t.category == _selectedCategoryFilter)
                .toList();
          }

          if (_searchQuery.isNotEmpty) {
            transactions = transactions.where((t) {
              final query = _searchQuery.toLowerCase();
              return t.category.toLowerCase().contains(query) ||
                  t.note.toLowerCase().contains(query) ||
                  t.amount.toString().contains(query);
            }).toList();
          }

          switch (_selectedSort) {
            case 'Oldest':
              transactions.sort((a, b) => a.date.compareTo(b.date));
              break;
            case 'Highest':
              transactions.sort((a, b) => b.amount.compareTo(a.amount));
              break;
            case 'Lowest':
              transactions.sort((a, b) => a.amount.compareTo(b.amount));
              break;
            default:
              transactions.sort((a, b) => b.date.compareTo(a.date));
          }

          if (transactions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 80,
                    color: AppColors.textTertiary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No transactions found',
                    style: AppTextStyles.heading4.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add your first transaction!',
                    style: AppTextStyles.bodyMedium,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final t = transactions[index];
              final category = getCategoryByName(
                t.category,
                t.type == TransactionType.income,
              );

              return Dismissible(
                key: Key(t.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.expense,
                    borderRadius: BorderRadius.circular(AppRadius.medium),
                  ),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (direction) async {
                  await _transactionService.deleteTransaction(t.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Transaction deleted')),
                  );
                },
                child: GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Details for ${t.category}')),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: AppDecorations.glassCard(
                      borderRadius: AppRadius.medium,
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: (category?.color ?? Colors.grey)
                              .withOpacity(0.2),
                          child: Icon(
                            category?.icon ?? Icons.category,
                            color: category?.color ?? Colors.grey,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t.category,
                                style: AppTextStyles.bodyLarge,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                DateFormat('dd MMM yyyy, HH:mm').format(t.date),
                                style: AppTextStyles.bodySmall,
                              ),
                              if (t.note.isNotEmpty) ...[
                                Text(
                                  t.note,
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.textTertiary,
                                    fontStyle: FontStyle.italic,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${t.type == TransactionType.income ? '+' : '-'}₹${t.amount.toStringAsFixed(2)}',
                                style: AppTextStyles.amountSmall.copyWith(
                                  color: t.type == TransactionType.income
                                      ? AppColors.income
                                      : AppColors.expense,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: t.type == TransactionType.income
                                      ? AppColors.income.withOpacity(0.2)
                                      : AppColors.expense.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  t.type == TransactionType.income
                                      ? 'Income'
                                      : 'Expense',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: t.type == TransactionType.income
                                        ? AppColors.income
                                        : AppColors.expense,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // ---------- Search & Filter with Labels ----------
  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: Column(
        children: [
          // Search Bar
          Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(AppRadius.medium),
              border: Border.all(color: AppColors.border, width: 1),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              style: AppTextStyles.bodyMedium,
              decoration: InputDecoration(
                hintText: 'Search transactions...',
                hintStyle: AppTextStyles.bodySmall,
                prefixIcon: Icon(Icons.search, color: AppColors.textTertiary),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: AppColors.textTertiary),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // 🔹 3 Dropdowns with labels: Type, Sort, Category
          Row(
            children: [
              Expanded(flex: 2, child: _buildFilterDropdown()),
              const SizedBox(width: 4),
              Expanded(flex: 2, child: _buildSortDropdown()),
              const SizedBox(width: 4),
              Expanded(flex: 3, child: _buildCategoryFilterDropdown()),
            ],
          ),
        ],
      ),
    );
  }

  // ---------- Dropdown 1: Type ----------
  Widget _buildFilterDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedFilter,
      dropdownColor: AppColors.card,
      style: AppTextStyles.bodySmall,
      decoration: InputDecoration(
        labelText: 'Type',
        labelStyle: AppTextStyles.caption.copyWith(
          color: AppColors.textTertiary,
          fontSize: 10,
        ),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        filled: true,
        fillColor: AppColors.card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.small),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        isDense: true,
      ),
      items: const [
        DropdownMenuItem(value: 'All', child: Text('All')),
        DropdownMenuItem(value: 'Income', child: Text('Income')),
        DropdownMenuItem(value: 'Expense', child: Text('Expense')),
      ],
      onChanged: (value) {
        setState(() {
          _selectedFilter = value!;
        });
      },
    );
  }

  // ---------- Dropdown 2: Sort ----------
  Widget _buildSortDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedSort,
      dropdownColor: AppColors.card,
      style: AppTextStyles.bodySmall,
      decoration: InputDecoration(
        labelText: 'Sort',
        labelStyle: AppTextStyles.caption.copyWith(
          color: AppColors.textTertiary,
          fontSize: 10,
        ),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        filled: true,
        fillColor: AppColors.card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.small),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        isDense: true,
      ),
      items: const [
        DropdownMenuItem(value: 'Newest', child: Text('Newest')),
        DropdownMenuItem(value: 'Oldest', child: Text('Oldest')),
        DropdownMenuItem(value: 'Highest', child: Text('Highest')),
        DropdownMenuItem(value: 'Lowest', child: Text('Lowest')),
      ],
      onChanged: (value) {
        setState(() {
          _selectedSort = value!;
        });
      },
    );
  }

  // ---------- Dropdown 3: Category ----------
  Widget _buildCategoryFilterDropdown() {
    final allCategories = expenseCategories.map((c) => c.name).toList();
    final incomeCatNames = incomeCategories.map((c) => c.name).toList();
    final all = [...allCategories, ...incomeCatNames].toSet().toList();

    // Ensure default value is 'All'
    if (_selectedCategoryFilter.isEmpty) {
      _selectedCategoryFilter = 'All';
    }

    return DropdownButtonFormField<String>(
      value: _selectedCategoryFilter,
      dropdownColor: AppColors.card,
      style: AppTextStyles.bodySmall,
      decoration: InputDecoration(
        labelText: 'Category',
        labelStyle: AppTextStyles.caption.copyWith(
          color: AppColors.textTertiary,
          fontSize: 10,
        ),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        filled: true,
        fillColor: AppColors.card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.small),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        isDense: true,
      ),
      items: [
        const DropdownMenuItem(value: 'All', child: Text('All')),
        ...all.map((cat) {
          final expenseCat = expenseCategories.firstWhere(
            (c) => c.name == cat,
            orElse: () => incomeCategories.firstWhere(
              (c) => c.name == cat,
              orElse: () => const Category(
                name: '',
                icon: Icons.category,
                color: Colors.grey,
              ),
            ),
          );
          return DropdownMenuItem(
            value: cat,
            child: Row(
              children: [
                Icon(expenseCat.icon, color: expenseCat.color, size: 16),
                const SizedBox(width: 4),
                Text(cat),
              ],
            ),
          );
        }),
      ],
      onChanged: (value) {
        setState(() {
          _selectedCategoryFilter = value!;
        });
      },
    );
  }
}
