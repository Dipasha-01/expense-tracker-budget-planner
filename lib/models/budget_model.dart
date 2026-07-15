import 'package:cloud_firestore/cloud_firestore.dart';

class BudgetModel {
  final String id;
  final String category;
  final double monthlyLimit;
  final String userId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BudgetModel({
    required this.id,
    required this.category,
    required this.monthlyLimit,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category': category,
      'monthlyLimit': monthlyLimit,
      'userId': userId,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory BudgetModel.fromMap(String id, Map<String, dynamic> map) {
    return BudgetModel(
      id: id,
      category: map['category'] ?? '',
      monthlyLimit: (map['monthlyLimit'] ?? 0.0).toDouble(),
      userId: map['userId'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
