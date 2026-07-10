import 'package:flutter/material.dart';

class Category {
  final String name;
  final IconData icon;
  final Color color;

  const Category({required this.name, required this.icon, required this.color});
}

// Income Categories
List<Category> incomeCategories = [
  const Category(name: 'Salary', icon: Icons.work, color: Colors.green),
  const Category(name: 'Scholarship', icon: Icons.school, color: Colors.blue),
  const Category(
    name: 'Freelancing',
    icon: Icons.computer,
    color: Colors.purple,
  ),
  const Category(name: 'Pocket Money', icon: Icons.money, color: Colors.orange),
  const Category(name: 'Business', icon: Icons.store, color: Colors.teal),
  const Category(name: 'Other', icon: Icons.more_horiz, color: Colors.grey),
];

// Expense Categories
List<Category> expenseCategories = [
  const Category(name: 'Food', icon: Icons.restaurant, color: Colors.red),
  const Category(
    name: 'Shopping',
    icon: Icons.shopping_bag,
    color: Colors.pink,
  ),
  const Category(
    name: 'Travel',
    icon: Icons.directions_bus,
    color: Colors.blue,
  ),
  const Category(
    name: 'Fuel',
    icon: Icons.local_gas_station,
    color: Colors.orange,
  ),
  const Category(
    name: 'Recharge',
    icon: Icons.phone_android,
    color: Colors.teal,
  ),
  const Category(name: 'Bills', icon: Icons.receipt, color: Colors.deepPurple),
  const Category(name: 'Education', icon: Icons.book, color: Colors.indigo),
  const Category(
    name: 'Entertainment',
    icon: Icons.movie,
    color: Colors.purple,
  ),
  const Category(
    name: 'Health',
    icon: Icons.health_and_safety,
    color: Colors.lightGreen,
  ),
  const Category(name: 'EMI', icon: Icons.home, color: Colors.amber),
  const Category(name: 'Others', icon: Icons.more_horiz, color: Colors.grey),
];

// Helper to get category by name
Category? getCategoryByName(String name, bool isIncome) {
  final list = isIncome ? incomeCategories : expenseCategories;
  try {
    return list.firstWhere((cat) => cat.name == name);
  } catch (e) {
    return null;
  }
}
