import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../services/transaction_service.dart';
import '../models/transaction_model.dart';
import '../utils/constants.dart';
import '../utils/categories.dart';
import 'login_screen.dart';
import 'add_transaction_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _auth = AuthService();
  final TransactionService _transactionService = TransactionService();
  late Future<String?> _userNameFuture;

  @override
  void initState() {
    super.initState();
    _userNameFuture = _getUserName();
  }

  // ✅ Fetch user name from Firestore using the uid
  Future<String?> _getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('name');
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

  // Returns a positional record: (income, expense, balance)
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
        title: const Text('Expense Tracker'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
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
                return const Center(child: CircularProgressIndicator());
              }

              final transactions = snapshot.data ?? [];
              final (income, expense, balance) = _calculateTotals(transactions);
              final recentTransactions = transactions.take(5).toList();

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Greeting with user name
                    Text(
                      '${_greeting()}, $userName!',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Balance Card
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          children: [
                            const Text(
                              'Total Balance',
                              style: TextStyle(
                                color: AppColors.textLight,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '₹$balance',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    children: [
                                      const Text(
                                        'Income',
                                        style: TextStyle(
                                          color: AppColors.textLight,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '₹$income',
                                        style: const TextStyle(
                                          color: AppColors.income,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  height: 30,
                                  width: 1,
                                  color: Colors.grey[300],
                                ),
                                Expanded(
                                  child: Column(
                                    children: [
                                      const Text(
                                        'Expense',
                                        style: TextStyle(
                                          color: AppColors.textLight,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '₹$expense',
                                        style: const TextStyle(
                                          color: AppColors.expense,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Recent Transactions
                    const Text(
                      'Recent Transactions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (recentTransactions.isEmpty)
                      const Card(
                        child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: Center(
                            child: Text(
                              'No transactions yet.\nTap + to add one.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.textLight),
                            ),
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
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: category?.color ?? Colors.grey,
                                child: Icon(
                                  category?.icon ?? Icons.category,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              title: Text(t.category),
                              subtitle: Text(
                                DateFormat('dd MMM yyyy').format(t.date),
                              ),
                              trailing: Text(
                                '${t.type == TransactionType.income ? '+' : '-'}₹${t.amount.toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: t.type == TransactionType.income
                                      ? AppColors.income
                                      : AppColors.expense,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              onTap: () {
                                // TODO: show transaction details / edit
                              },
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
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddTransactionScreen(),
            ),
          );
          if (result == true) {
            // Transaction saved – refresh will happen automatically via stream
          }
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
