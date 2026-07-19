import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/transaction_service.dart';
import '../models/transaction_model.dart';
import '../utils/constants.dart';
import '../providers/theme_provider.dart';
import 'login_screen.dart';
import 'goals_screen.dart';
import 'pin_screen.dart';
import '../services/pin_service.dart';
import '../services/backup_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _auth = AuthService();
  final TransactionService _transactionService = TransactionService();
  final PinService _pinService = PinService();
  final BackupService _backupService = BackupService();

  late Future<Map<String, dynamic>> _userDataFuture;
  Future<bool> _pinEnabledFuture = Future.value(false);

  @override
  void initState() {
    super.initState();
    _userDataFuture = _getUserData();
    _pinEnabledFuture = _pinService.isPinEnabled();
  }

  Future<Map<String, dynamic>> _getUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    final prefs = await SharedPreferences.getInstance();
    final name = user?.displayName ?? prefs.getString('name') ?? 'User';
    final email = user?.email ?? prefs.getString('email') ?? 'No email';

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
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.themeMode == ThemeMode.dark;

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

          return FutureBuilder<bool>(
            future: _pinEnabledFuture,
            builder: (context, pinSnapshot) {
              final pinEnabled = pinSnapshot.data ?? false;
              return SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  children: [
                    // Profile Header
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: AppDecorations.glassCard(),
                      child: Column(
                        children: [
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

                    // Stats Cards
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
                    // 1. Theme Toggle
                    _buildMenuItem(
                      icon: isDark ? Icons.dark_mode : Icons.light_mode,
                      label: isDark ? 'Dark Mode' : 'Light Mode',
                      trailing: Switch(
                        value: isDark,
                        onChanged: (_) => themeProvider.toggleTheme(),
                        activeColor: AppColors.primary,
                      ),
                      onTap: () => themeProvider.toggleTheme(),
                    ),
                    // 2. PIN Lock
                    _buildMenuItem(
                      icon: Icons.lock_outline,
                      label: pinEnabled ? 'Disable PIN' : 'Enable PIN',
                      trailing: const Icon(
                        Icons.chevron_right,
                        color: AppColors.textTertiary,
                      ),
                      onTap: () async {
                        if (pinEnabled) {
                          // Disable PIN
                          await _pinService.disablePin();
                          setState(() {
                            _pinEnabledFuture = Future.value(false);
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('PIN disabled')),
                          );
                        } else {
                          // Navigate to PIN setup
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const PinScreen(mode: PinMode.setup),
                            ),
                          );
                          if (result == true) {
                            setState(() {
                              _pinEnabledFuture = Future.value(true);
                            });
                          }
                        }
                      },
                    ),
                    // 3. Backup & Sync
                    _buildMenuItem(
                      icon: Icons.backup,
                      label: 'Backup & Sync',
                      trailing: const Icon(
                        Icons.chevron_right,
                        color: AppColors.textTertiary,
                      ),
                      onTap: () => _showBackupDialog(context),
                    ),
                    // 4. Savings Goals (already in menu, but keep it)
                    _buildMenuItem(
                      icon: Icons.emoji_events,
                      label: 'Savings Goals',
                      trailing: const Icon(
                        Icons.chevron_right,
                        color: AppColors.textTertiary,
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const GoalsScreen(),
                          ),
                        );
                      },
                    ),
                    const Divider(
                      color: AppColors.border,
                      height: AppSpacing.lg,
                    ),

                    // Logout
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

  void _showBackupDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? AppColors.card
            : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.large),
        ),
        title: const Text('Backup & Sync'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.download, color: AppColors.primary),
              title: const Text('Export Data'),
              subtitle: const Text('Save all your data as JSON'),
              onTap: () async {
                Navigator.pop(context);
                await _backupService.exportData(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.upload, color: AppColors.primary),
              title: const Text('Import Data'),
              subtitle: const Text('Restore from a JSON file'),
              onTap: () async {
                Navigator.pop(context);
                await _backupService.importData(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.sync, color: AppColors.primary),
              title: const Text('Force Sync'),
              subtitle: const Text('Sync with cloud (manual)'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Sync triggered (data is already real-time)'),
                  ),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
