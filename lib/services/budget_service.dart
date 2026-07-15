import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/budget_model.dart';
import '../models/transaction_model.dart';

class BudgetService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;

  CollectionReference get _budgetsCollection =>
      _firestore.collection('users').doc(_userId).collection('budgets');

  // Set or update a budget for a category
  Future<void> setBudget(String category, double monthlyLimit) async {
    if (_userId == null) throw Exception('User not logged in');

    final id = '$category-${DateTime.now().month}-${DateTime.now().year}';
    final budget = BudgetModel(
      id: id,
      category: category,
      monthlyLimit: monthlyLimit,
      userId: _userId!,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _budgetsCollection.doc(id).set(budget.toMap());
  }

  // Get all budgets for the current month
  Stream<List<BudgetModel>> getBudgets() {
    if (_userId == null) return Stream.value([]);
    return _budgetsCollection.snapshots().map((snapshot) {
      return snapshot.docs
          .map(
            (doc) =>
                BudgetModel.fromMap(doc.id, doc.data() as Map<String, dynamic>),
          )
          .toList();
    });
  }

  // Get a specific budget by category
  Future<BudgetModel?> getBudgetByCategory(String category) async {
    if (_userId == null) return null;
    final id = '$category-${DateTime.now().month}-${DateTime.now().year}';
    final doc = await _budgetsCollection.doc(id).get();
    if (doc.exists) {
      return BudgetModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
    }
    return null;
  }

  // Delete a budget
  Future<void> deleteBudget(String id) async {
    if (_userId == null) throw Exception('User not logged in');
    await _budgetsCollection.doc(id).delete();
  }

  // Get total expense for a specific category this month
  Future<double> getCategoryExpenseThisMonth(String category) async {
    if (_userId == null) return 0.0;
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 1);

    final snapshot = await _firestore
        .collection('users')
        .doc(_userId)
        .collection('transactions')
        .where('category', isEqualTo: category)
        .where('type', isEqualTo: TransactionType.expense.name)
        .where('date', isGreaterThanOrEqualTo: start)
        .where('date', isLessThan: end)
        .get();

    double total = 0;
    for (var doc in snapshot.docs) {
      total += (doc.data() as Map<String, dynamic>)['amount'] ?? 0;
    }
    return total;
  }

  // Get total expense for all categories this month
  Future<double> getTotalExpenseThisMonth() async {
    if (_userId == null) return 0.0;
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

    double total = 0;
    for (var doc in snapshot.docs) {
      total += (doc.data() as Map<String, dynamic>)['amount'] ?? 0;
    }
    return total;
  }
}
