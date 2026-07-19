import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/goal_model.dart';

class GoalService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;

  // Collection reference for goals
  CollectionReference get _goalsCollection =>
      _firestore.collection('users').doc(_userId).collection('goals');

  // Add a new goal
  Future<void> addGoal(GoalModel goal) async {
    if (_userId == null) {
      throw Exception('User not logged in');
    }
    await _goalsCollection.doc(goal.id).set(goal.toMap());
  }

  // Get all goals (real-time stream)
  Stream<List<GoalModel>> getGoals() {
    if (_userId == null) {
      return Stream.value([]);
    }
    return _goalsCollection
        .orderBy('deadline', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(
                (doc) => GoalModel.fromMap(
                  doc.id,
                  doc.data() as Map<String, dynamic>,
                ),
              )
              .toList();
        });
  }

  // Get active goals (not completed)
  Stream<List<GoalModel>> getActiveGoals() {
    if (_userId == null) {
      return Stream.value([]);
    }
    // We filter client-side because Firestore doesn't support computed fields
    // Alternatively, we could store an 'isCompleted' field, but we calculate it dynamically
    return _goalsCollection
        .orderBy('deadline', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(
                (doc) => GoalModel.fromMap(
                  doc.id,
                  doc.data() as Map<String, dynamic>,
                ),
              )
              .where((goal) => !goal.isCompleted)
              .toList();
        });
  }

  // Get completed goals
  Stream<List<GoalModel>> getCompletedGoals() {
    if (_userId == null) {
      return Stream.value([]);
    }
    return _goalsCollection
        .orderBy('deadline', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(
                (doc) => GoalModel.fromMap(
                  doc.id,
                  doc.data() as Map<String, dynamic>,
                ),
              )
              .where((goal) => goal.isCompleted)
              .toList();
        });
  }

  // Get a single goal by ID
  Future<GoalModel?> getGoalById(String id) async {
    if (_userId == null) return null;
    final doc = await _goalsCollection.doc(id).get();
    if (doc.exists) {
      return GoalModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
    }
    return null;
  }

  // Update a goal
  Future<void> updateGoal(GoalModel goal) async {
    if (_userId == null) {
      throw Exception('User not logged in');
    }
    await _goalsCollection.doc(goal.id).update(goal.toMap());
  }

  // Add amount to a goal (e.g., when saving money)
  Future<void> addToGoal(String id, double amount) async {
    if (_userId == null) {
      throw Exception('User not logged in');
    }
    final doc = await _goalsCollection.doc(id).get();
    if (!doc.exists) {
      throw Exception('Goal not found');
    }
    final data = doc.data() as Map<String, dynamic>;
    final currentAmount = (data['currentAmount'] ?? 0.0).toDouble();
    final newAmount = currentAmount + amount;
    await _goalsCollection.doc(id).update({
      'currentAmount': newAmount,
      'updatedAt': DateTime.now(),
    });
  }

  // Withdraw from a goal (reduce current amount)
  Future<void> withdrawFromGoal(String id, double amount) async {
    if (_userId == null) {
      throw Exception('User not logged in');
    }
    final doc = await _goalsCollection.doc(id).get();
    if (!doc.exists) {
      throw Exception('Goal not found');
    }
    final data = doc.data() as Map<String, dynamic>;
    final currentAmount = (data['currentAmount'] ?? 0.0).toDouble();
    final newAmount = currentAmount - amount;
    if (newAmount < 0) {
      throw Exception('Cannot withdraw more than current amount');
    }
    await _goalsCollection.doc(id).update({
      'currentAmount': newAmount,
      'updatedAt': DateTime.now(),
    });
  }

  // Delete a goal
  Future<void> deleteGoal(String id) async {
    if (_userId == null) {
      throw Exception('User not logged in');
    }
    await _goalsCollection.doc(id).delete();
  }
}
