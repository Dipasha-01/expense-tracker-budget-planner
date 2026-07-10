import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/transaction_model.dart';

class TransactionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get _userId => _auth.currentUser?.uid;

  // Collection reference for transactions
  CollectionReference get _transactionsCollection =>
      _firestore.collection('users').doc(_userId).collection('transactions');

  // Add a new transaction
  Future<void> addTransaction(TransactionModel transaction) async {
    if (_userId == null) {
      throw Exception('User not logged in');
    }
    await _transactionsCollection.doc(transaction.id).set(transaction.toMap());
  }

  // Get all transactions for the current user (ordered by date descending)
  Stream<List<TransactionModel>> getTransactions() {
    if (_userId == null) {
      return Stream.value([]);
    }
    return _transactionsCollection
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => TransactionModel.fromMap(
                  doc.id,
                  doc.data() as Map<String, dynamic>,
                ),
              )
              .toList(),
        );
  }

  // Get transactions by type (income or expense)
  Stream<List<TransactionModel>> getTransactionsByType(TransactionType type) {
    if (_userId == null) {
      return Stream.value([]);
    }
    return _transactionsCollection
        .where('type', isEqualTo: type.name)
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => TransactionModel.fromMap(
                  doc.id,
                  doc.data() as Map<String, dynamic>,
                ),
              )
              .toList(),
        );
  }

  // Get transactions for a specific month
  Stream<List<TransactionModel>> getTransactionsForMonth(int year, int month) {
    if (_userId == null) {
      return Stream.value([]);
    }
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 1);
    return _transactionsCollection
        .where('date', isGreaterThanOrEqualTo: start)
        .where('date', isLessThan: end)
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => TransactionModel.fromMap(
                  doc.id,
                  doc.data() as Map<String, dynamic>,
                ),
              )
              .toList(),
        );
  }

  // Get transactions by category
  Stream<List<TransactionModel>> getTransactionsByCategory(String category) {
    if (_userId == null) {
      return Stream.value([]);
    }
    return _transactionsCollection
        .where('category', isEqualTo: category)
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => TransactionModel.fromMap(
                  doc.id,
                  doc.data() as Map<String, dynamic>,
                ),
              )
              .toList(),
        );
  }

  // Update a transaction
  Future<void> updateTransaction(TransactionModel transaction) async {
    if (_userId == null) {
      throw Exception('User not logged in');
    }
    await _transactionsCollection
        .doc(transaction.id)
        .update(transaction.toMap());
  }

  // Delete a transaction
  Future<void> deleteTransaction(String id) async {
    if (_userId == null) {
      throw Exception('User not logged in');
    }
    await _transactionsCollection.doc(id).delete();
  }

  // Get total income for a month
  Future<double> getTotalIncomeForMonth(int year, int month) async {
    if (_userId == null) return 0.0;
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 1);
    final snapshot = await _transactionsCollection
        .where('type', isEqualTo: TransactionType.income.name)
        .where('date', isGreaterThanOrEqualTo: start)
        .where('date', isLessThan: end)
        .get();
    double total = 0.0;
    for (var doc in snapshot.docs) {
      total += (doc.data() as Map<String, dynamic>)['amount'] ?? 0.0;
    }
    return total;
  }

  // Get total expense for a month
  Future<double> getTotalExpenseForMonth(int year, int month) async {
    if (_userId == null) return 0.0;
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 1);
    final snapshot = await _transactionsCollection
        .where('type', isEqualTo: TransactionType.expense.name)
        .where('date', isGreaterThanOrEqualTo: start)
        .where('date', isLessThan: end)
        .get();
    double total = 0.0;
    for (var doc in snapshot.docs) {
      total += (doc.data() as Map<String, dynamic>)['amount'] ?? 0.0;
    }
    return total;
  }

  // Get all category names with total spent for a month
  Future<Map<String, double>> getCategoryTotalsForMonth(
    int year,
    int month,
  ) async {
    if (_userId == null) return {};
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 1);
    final snapshot = await _transactionsCollection
        .where('type', isEqualTo: TransactionType.expense.name)
        .where('date', isGreaterThanOrEqualTo: start)
        .where('date', isLessThan: end)
        .get();
    Map<String, double> totals = {};
    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final category = data['category'] ?? 'Other';
      final amount = (data['amount'] ?? 0.0).toDouble();
      totals[category] = (totals[category] ?? 0.0) + amount;
    }
    return totals;
  }
}
