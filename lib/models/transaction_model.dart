import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionType { income, expense }

class TransactionModel {
  final String id;
  final TransactionType type;
  final double amount;
  final String category;
  final DateTime date;
  final String note;
  final String paymentMethod;
  final String? receiptUrl;
  final String? location;
  final String userId;
  final DateTime createdAt;

  const TransactionModel({
    required this.id,
    required this.type,
    required this.amount,
    required this.category,
    required this.date,
    required this.note,
    required this.paymentMethod,
    this.receiptUrl,
    this.location,
    required this.userId,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'amount': amount,
      'category': category,
      'date': date,
      'note': note,
      'paymentMethod': paymentMethod,
      'receiptUrl': receiptUrl,
      'location': location,
      'userId': userId,
      'createdAt': createdAt,
    };
  }

  factory TransactionModel.fromMap(String id, Map<String, dynamic> map) {
    return TransactionModel(
      id: id,
      type: TransactionType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => TransactionType.expense,
      ),
      amount: (map['amount'] ?? 0.0).toDouble(),
      category: map['category'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      note: map['note'] ?? '',
      paymentMethod: map['paymentMethod'] ?? '',
      receiptUrl: map['receiptUrl'],
      location: map['location'],
      userId: map['userId'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }
}
