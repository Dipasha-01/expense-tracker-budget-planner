import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';

class ChartService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;

  // Get expense breakdown by category for pie chart
  Future<Map<String, double>> getCategoryBreakdown() async {
    if (_userId == null) return {};

    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 1);

    final snapshot = await _firestore
        .collection('users')
        .doc(_userId)
        .collection('transactions')
        .where('type', isEqualTo: TransactionType.expense.name)
        .where('date', isGreaterThanOrEqualTo: start)
        .where('date', isLessThan: end)
        .get();

    Map<String, double> breakdown = {};
    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final category = data['category'] ?? 'Other';
      final amount = (data['amount'] ?? 0.0).toDouble();
      breakdown[category] = (breakdown[category] ?? 0) + amount;
    }
    return breakdown;
  }

  // Get monthly income vs expense for bar chart (last 6 months)
  Future<Map<String, Map<String, double>>> getMonthlyIncomeExpense() async {
    if (_userId == null) return {};

    final now = DateTime.now();
    Map<String, Map<String, double>> result = {};

    for (int i = 5; i >= 0; i--) {
      final month = now.month - i;
      final year = now.year;
      final adjustedMonth = month <= 0 ? month + 12 : month;
      final adjustedYear = month <= 0 ? year - 1 : year;

      final monthName = _getMonthName(adjustedMonth);
      final key = '$monthName $adjustedYear';

      final start = DateTime(adjustedYear, adjustedMonth, 1);
      final end = DateTime(adjustedYear, adjustedMonth + 1, 1);

      final snapshot = await _firestore
          .collection('users')
          .doc(_userId)
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

      result[key] = {'income': income, 'expense': expense};
    }

    return result;
  }

  // Get daily spending for line chart (last 7 days)
  Future<Map<String, double>> getDailySpending() async {
    if (_userId == null) return {};

    final now = DateTime.now();
    Map<String, double> dailySpending = {};

    for (int i = 6; i >= 0; i--) {
      final date = DateTime(now.year, now.month, now.day - i);
      final start = DateTime(date.year, date.month, date.day);
      final end = start.add(const Duration(days: 1));

      final key = DateFormat('E').format(date); // Mon, Tue, Wed, etc.

      final snapshot = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('transactions')
          .where('type', isEqualTo: TransactionType.expense.name)
          .where('date', isGreaterThanOrEqualTo: start)
          .where('date', isLessThan: end)
          .get();

      double total = 0;
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        total += (data['amount'] ?? 0.0).toDouble();
      }
      dailySpending[key] = total;
    }

    return dailySpending;
  }

  // Get top spending categories (for quick insights)
  Future<List<MapEntry<String, double>>> getTopCategories() async {
    final breakdown = await getCategoryBreakdown();
    final sorted = breakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(5).toList();
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }
}
