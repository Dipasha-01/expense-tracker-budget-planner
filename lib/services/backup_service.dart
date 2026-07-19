import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../services/transaction_service.dart';
import '../services/budget_service.dart';
import '../services/goal_service.dart';

class BackupService {
  final TransactionService _transactionService = TransactionService();
  final BudgetService _budgetService = BudgetService();
  final GoalService _goalService = GoalService();

  Future<void> exportData(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please log in first')));
      return;
    }

    try {
      final transactions = await _transactionService.getTransactions().first;
      final budgets = await _budgetService.getBudgets().first;
      final goals = await _goalService.getGoals().first;

      final data = {
        'user': user.uid,
        'email': user.email,
        'exportDate': DateTime.now().toIso8601String(),
        'transactions': transactions.map((t) => t.toMap()).toList(),
        'budgets': budgets.map((b) => b.toMap()).toList(),
        'goals': goals.map((g) => g.toMap()).toList(),
      };

      final json = jsonEncode(data);
      final tempDir = await getTemporaryDirectory();
      final file = File(
        '${tempDir.path}/ExpenseX_Backup_${DateTime.now().millisecondsSinceEpoch}.json',
      );
      await file.writeAsString(json);

      await Share.shareXFiles([XFile(file.path)], text: 'ExpenseX Backup');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Backup exported successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Export failed: ${e.toString()}')));
    }
  }

  // ✅ Placeholder for import – we'll implement later without file_picker
  Future<void> importData(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Import feature coming soon!')),
    );
  }
}
