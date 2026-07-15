import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../services/transaction_service.dart';
import '../models/transaction_model.dart';
import '../utils/constants.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _auth = AuthService();
  final TransactionService _transactionService = TransactionService();

  late Future<Map<String, dynamic>> _userDataFuture;

  @override
  void initState() {
    super.initState();
    _userDataFuture = _getUserData();
  }

  Future<Map<String, dynamic>> _getUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    final prefs = await SharedPreferences.getInstance();
    final name = user?.displayName ?? prefs.getString('name') ?? 'User';
    final email = user?.email ?? prefs.getString('email') ?? 'No email';

    // Get transaction stats
    final transactions = await _transactionService.getTransactions().first;
    double income = 0;
    double expense = 0;
    for (var t in transactions) {
      if (t.type == TransactionType.income) {
        income += t.amount;
      } else {
        expense += t.amount;
      }
    }

    return {
      'name': name,
      'email': email,
      'income': income,
      'expense': expense,
      'count': transactions.length,
    };
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profile'),
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: AppGradients.primary),
        ),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _userDataFuture,
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
                style: TextStyle(color: AppColors.expense),
              ),
            );
          }

          final data = snapshot.data ?? {};
          final name = data['name'] ?? 'User';
          final email = data['email'] ?? '';
          final income = data['income'] ?? 0.0;
          final expense = data['expense'] ?? 0.0;
          final count = data['count'] ?? 0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                // ---------- Profile Header ----------
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: AppDecorations.glassCard(),
                  child: Column(
                    children: [
                      // Avatar
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: AppGradients.primary,
                          shape: BoxShape.circle,
                          boxShadow: AppShadows.soft,
                        ),
                        child: Center(
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : 'U',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(name, style: AppTextStyles.heading3),
                      const SizedBox(height: 4),
                      Text(email, style: AppTextStyles.bodyMedium),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // ---------- Stats Cards ----------
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Total Income',
                        '₹${income.toStringAsFixed(2)}',
                        AppColors.income,
                        Icons.arrow_upward,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _buildStatCard(
                        'Total Expense',
                        '₹${expense.toStringAsFixed(2)}',
                        AppColors.expense,
                        Icons.arrow_downward,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Transactions',
                        count.toString(),
                        AppColors.primary,
                        Icons.receipt_long,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _buildStatCard(
                        'Savings',
                        '₹${(income - expense).toStringAsFixed(2)}',
                        (income - expense) >= 0
                            ? AppColors.accent
                            : AppColors.expense,
                        Icons.savings,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                // ---------- Settings Menu ----------
                _buildMenuItem(
                  icon: Icons.dark_mode,
                  label: 'Dark Mode',
                  trailing: const Icon(
                    Icons.toggle_on,
                    color: AppColors.primary,
                  ),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Theme settings coming soon!'),
                      ),
                    );
                  },
                ),
                _buildMenuItem(
                  icon: Icons.currency_rupee,
                  label: 'Currency',
                  trailing: const Text(
                    '₹ INR',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Currency settings coming soon!'),
                      ),
                    );
                  },
                ),
                _buildMenuItem(
                  icon: Icons.language,
                  label: 'Language',
                  trailing: const Text(
                    'English',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Language settings coming soon!'),
                      ),
                    );
                  },
                ),
                _buildMenuItem(
                  icon: Icons.security,
                  label: 'Security',
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: AppColors.textTertiary,
                  ),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Security settings coming soon!'),
                      ),
                    );
                  },
                ),
                _buildMenuItem(
                  icon: Icons.backup,
                  label: 'Backup & Sync',
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: AppColors.textTertiary,
                  ),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Backup settings coming soon!'),
                      ),
                    );
                  },
                ),
                const Divider(color: AppColors.border, height: AppSpacing.lg),

                // ---------- Logout ----------
                _buildMenuItem(
                  icon: Icons.logout,
                  label: 'Logout',
                  color: AppColors.expense,
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: AppColors.textTertiary,
                  ),
                  onTap: _logout,
                ),

                const SizedBox(height: AppSpacing.md),
                Text(
                  'ExpenseX v1.0.0',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: AppDecorations.glassCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 4),
              Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.amountSmall.copyWith(
              color: AppColors.textPrimary,
              fontSize: 14,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    Widget? trailing,
    Color color = AppColors.textPrimary,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.md,
          horizontal: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppColors.border, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.bodyLarge.copyWith(color: color),
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }
}
