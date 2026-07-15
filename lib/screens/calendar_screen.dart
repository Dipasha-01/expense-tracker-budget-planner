import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/transaction_service.dart';
import '../models/transaction_model.dart';
import '../utils/constants.dart';
import '../utils/categories.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final TransactionService _transactionService = TransactionService();

  DateTime _selectedDate = DateTime.now();
  DateTime _focusedMonth = DateTime.now();
  Map<DateTime, List<TransactionModel>> _transactionsByDate = {};

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    final transactions = await _transactionService.getTransactions().first;
    setState(() {
      _transactionsByDate = {};
      for (var t in transactions) {
        final dateKey = DateTime(t.date.year, t.date.month, t.date.day);
        _transactionsByDate.putIfAbsent(dateKey, () => []).add(t);
      }
    });
  }

  List<TransactionModel> _getTransactionsForDate(DateTime date) {
    final key = DateTime(date.year, date.month, date.day);
    return _transactionsByDate[key] ?? [];
  }

  double _getDailyTotal(DateTime date) {
    final transactions = _getTransactionsForDate(date);
    double total = 0;
    for (var t in transactions) {
      if (t.type == TransactionType.expense) {
        total += t.amount;
      }
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Calendar'),
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: AppGradients.primary),
        ),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            onPressed: () {
              setState(() {
                _focusedMonth = DateTime.now();
              });
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            // ---------- Month Navigation ----------
            Container(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              decoration: AppDecorations.glassCard(),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.chevron_left,
                      color: AppColors.primary,
                    ),
                    onPressed: () {
                      setState(() {
                        _focusedMonth = DateTime(
                          _focusedMonth.year,
                          _focusedMonth.month - 1,
                          1,
                        );
                      });
                    },
                  ),
                  Text(
                    DateFormat('MMMM yyyy').format(_focusedMonth),
                    style: AppTextStyles.heading4,
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.chevron_right,
                      color: AppColors.primary,
                    ),
                    onPressed: () {
                      setState(() {
                        _focusedMonth = DateTime(
                          _focusedMonth.year,
                          _focusedMonth.month + 1,
                          1,
                        );
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // ---------- Calendar Grid ----------
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: AppDecorations.glassCard(),
              child: Column(
                children: [
                  // Weekday headers
                  Row(
                    children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
                        .map(
                          (day) => Expanded(
                            child: Center(
                              child: Text(
                                day,
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.textTertiary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 8),

                  // Calendar days
                  _buildCalendarGrid(),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // ---------- Selected Day Summary ----------
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: AppDecorations.glassCard(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat('dd MMMM yyyy').format(_selectedDate),
                        style: AppTextStyles.heading4,
                      ),
                      Text(
                        '₹${_getDailyTotal(_selectedDate).toStringAsFixed(2)}',
                        style: AppTextStyles.amountLarge.copyWith(
                          color: AppColors.expense,
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Divider(color: AppColors.border),
                  const SizedBox(height: AppSpacing.sm),

                  // Transactions for selected date
                  ..._buildTransactionsForDate(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final firstDay = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final daysInMonth = DateTime(
      _focusedMonth.year,
      _focusedMonth.month + 1,
      0,
    ).day;
    final startWeekday = firstDay.weekday % 7;

    List<Widget> dayWidgets = [];

    // Empty cells before first day
    for (int i = 0; i < startWeekday; i++) {
      dayWidgets.add(const Expanded(child: SizedBox.shrink()));
    }

    // Days of the month
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_focusedMonth.year, _focusedMonth.month, day);
      final hasTransaction = _getTransactionsForDate(date).isNotEmpty;
      final total = _getDailyTotal(date);
      final isToday =
          date.day == DateTime.now().day &&
          date.month == DateTime.now().month &&
          date.year == DateTime.now().year;
      final isSelected =
          date.day == _selectedDate.day &&
          date.month == _selectedDate.month &&
          date.year == _selectedDate.year;

      dayWidgets.add(
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedDate = date;
              });
            },
            child: Container(
              margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : isToday
                    ? AppColors.primary.withOpacity(0.2)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Text(
                      day.toString(),
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : isToday
                            ? AppColors.primary
                            : AppColors.textPrimary,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                  if (hasTransaction)
                    Positioned(
                      bottom: 4,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 3,
                        width: 10,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: total > 0
                              ? AppColors.expense
                              : AppColors.income,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Fill remaining cells
    final remaining = (7 - (startWeekday + daysInMonth) % 7) % 7;
    for (int i = 0; i < remaining; i++) {
      dayWidgets.add(const Expanded(child: SizedBox.shrink()));
    }

    return Column(
      children: [
        for (int i = 0; i < dayWidgets.length; i += 7)
          Row(
            children: dayWidgets.sublist(
              i,
              i + 7 > dayWidgets.length ? dayWidgets.length : i + 7,
            ),
          ),
      ],
    );
  }

  List<Widget> _buildTransactionsForDate() {
    final transactions = _getTransactionsForDate(_selectedDate);
    if (transactions.isEmpty) {
      return [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16.0),
          child: Center(
            child: Text(
              'No transactions on this day',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ),
      ];
    }

    return transactions.map((t) {
      final category = getCategoryByName(
        t.category,
        t.type == TransactionType.income,
      );
      return Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: (category?.color ?? Colors.grey).withOpacity(
                0.2,
              ),
              child: Icon(
                category?.icon ?? Icons.category,
                color: category?.color ?? Colors.grey,
                size: 14,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.category,
                    style: AppTextStyles.bodyLarge.copyWith(fontSize: 13),
                  ),
                  Text(
                    t.note.isNotEmpty
                        ? t.note
                        : DateFormat('HH:mm').format(t.date),
                    style: AppTextStyles.bodySmall.copyWith(fontSize: 10),
                  ),
                ],
              ),
            ),
            Text(
              '${t.type == TransactionType.income ? '+' : '-'}₹${t.amount.toStringAsFixed(2)}',
              style: AppTextStyles.amountSmall.copyWith(
                color: t.type == TransactionType.income
                    ? AppColors.income
                    : AppColors.expense,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}
