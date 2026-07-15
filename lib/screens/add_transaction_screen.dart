import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/transaction_model.dart';
import '../services/transaction_service.dart';
import '../utils/constants.dart';
import '../utils/categories.dart';

class AddTransactionScreen extends StatefulWidget {
  final TransactionType? initialType; // ✅ New parameter for pre-selecting type

  const AddTransactionScreen({super.key, this.initialType});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final TransactionService _transactionService = TransactionService();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  TransactionType _type = TransactionType.expense;
  Category? _selectedCategory;
  String? _selectedSubcategory;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  String _paymentMethod = 'Cash';
  bool _isLoading = false;
  bool _addReceipt = false;
  bool _useVoiceInput = false;

  final List<String> _paymentMethods = [
    'Cash',
    'Bank Transfer',
    'UPI',
    'Credit Card',
    'Debit Card',
    'Net Banking',
    'PayPal',
    'Other',
  ];

  final Map<String, List<String>> _subcategories = {
    'Food': ['Groceries', 'Restaurant', 'Cafe', 'Delivery', 'Snacks'],
    'Shopping': ['Clothes', 'Electronics', 'Home', 'Accessories', 'Gifts'],
    'Travel': ['Flight', 'Train', 'Bus', 'Taxi', 'Fuel', 'Hotel'],
    'Fuel': ['Petrol', 'Diesel', 'CNG', 'EV Charging'],
    'Recharge': ['Mobile', 'DTH', 'Internet', 'OTT'],
    'Bills': ['Electricity', 'Water', 'Gas', 'Internet', 'Rent', 'Insurance'],
    'Education': ['Tuition', 'Books', 'Courses', 'Stationery'],
    'Entertainment': ['Movies', 'Concerts', 'Games', 'OTT Subscription'],
    'Health': ['Doctor', 'Medicine', 'Gym', 'Insurance', 'Tests'],
    'EMI': ['Home Loan', 'Car Loan', 'Personal Loan', 'Education Loan'],
    'Others': ['Miscellaneous'],
    // Income subcategories
    'Salary': ['Monthly', 'Bonus', 'Overtime'],
    'Freelancing': ['Project', 'Consulting', 'Design'],
    'Scholarship': ['Merit', 'Need-based'],
    'Pocket Money': ['Weekly', 'Monthly'],
    'Business': ['Revenue', 'Refund'],
    'Other': ['Miscellaneous'],
  };

  List<String> get _availableSubcategories =>
      _subcategories[_selectedCategory?.name ?? ''] ?? [];

  @override
  void initState() {
    super.initState();
    // ✅ Set initial type if provided
    if (widget.initialType != null) {
      _type = widget.initialType!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Add Transaction'),
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: AppGradients.primary),
        ),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            // ---------- Toggle Income/Expense ----------
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(AppRadius.medium),
                border: Border.all(color: AppColors.border, width: 1),
              ),
              child: Row(
                children: [
                  _buildToggleButton('Expense', TransactionType.expense),
                  _buildToggleButton('Income', TransactionType.income),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // ---------- Main Form Card ----------
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: AppDecorations.glassCard(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Amount
                  _buildSectionLabel('Amount'),
                  TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.currency_rupee),
                      hintText: 'Enter amount',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Category
                  _buildSectionLabel('Category'),
                  DropdownButtonFormField<Category>(
                    value: _selectedCategory,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      hintText: 'Select category',
                    ),
                    items:
                        (_type == TransactionType.income
                                ? incomeCategories
                                : expenseCategories)
                            .map((cat) {
                              return DropdownMenuItem(
                                value: cat,
                                child: Row(
                                  children: [
                                    Icon(cat.icon, color: cat.color),
                                    const SizedBox(width: 8),
                                    Text(cat.name),
                                  ],
                                ),
                              );
                            })
                            .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCategory = value;
                        _selectedSubcategory = null;
                      });
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Subcategory (if available)
                  if (_availableSubcategories.isNotEmpty) ...[
                    _buildSectionLabel('Subcategory'),
                    DropdownButtonFormField<String>(
                      value: _selectedSubcategory,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        hintText: 'Select subcategory',
                      ),
                      items: _availableSubcategories.map((sub) {
                        return DropdownMenuItem(value: sub, child: Text(sub));
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedSubcategory = value);
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],

                  // Date & Time
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionLabel('Date'),
                            _buildDatePicker(),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionLabel('Time'),
                            _buildTimePicker(),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Payment Method
                  _buildSectionLabel('Payment Method'),
                  DropdownButtonFormField<String>(
                    value: _paymentMethod,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      hintText: 'Select payment method',
                    ),
                    items: _paymentMethods.map((method) {
                      return DropdownMenuItem(
                        value: method,
                        child: Text(method),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _paymentMethod = value!);
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Location
                  _buildSectionLabel('Location (optional)'),
                  TextField(
                    controller: _locationController,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.location_on_outlined),
                      hintText: 'Add location',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Receipt
                  Row(
                    children: [
                      Switch(
                        value: _addReceipt,
                        onChanged: (value) {
                          setState(() => _addReceipt = value);
                        },
                        activeColor: AppColors.primary,
                      ),
                      const Text('Attach Receipt'),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Notes
                  _buildSectionLabel('Notes'),
                  TextField(
                    controller: _noteController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Add a note...',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Tags
                  _buildSectionLabel('Tags'),
                  TextField(
                    controller: _tagsController,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.local_offer_outlined),
                      hintText: 'Add tags (comma separated)',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Voice Input
                  Row(
                    children: [
                      Switch(
                        value: _useVoiceInput,
                        onChanged: (value) {
                          setState(() => _useVoiceInput = value);
                        },
                        activeColor: AppColors.primary,
                      ),
                      const Text('Voice Input'),
                      if (_useVoiceInput) ...[
                        const SizedBox(width: 8),
                        Icon(Icons.mic, color: AppColors.primary),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // ---------- Save Button ----------
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveTransaction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.medium),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Save Transaction',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- Helper Widgets ----------
  Widget _buildToggleButton(String label, TransactionType type) {
    final isSelected = _type == type;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _type = type;
            _selectedCategory = null;
            _selectedSubcategory = null;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.small),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Text(text, style: AppTextStyles.label),
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: _selectDate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppRadius.small),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              DateFormat('dd MMM yyyy').format(_selectedDate),
              style: AppTextStyles.bodyMedium,
            ),
            Icon(Icons.calendar_today, color: AppColors.primary, size: 18),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Widget _buildTimePicker() {
    return InkWell(
      onTap: _selectTime,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppRadius.small),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _selectedTime.format(context),
              style: AppTextStyles.bodyMedium,
            ),
            Icon(Icons.access_time, color: AppColors.primary, size: 18),
          ],
        ),
      ),
    );
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  // ---------- Save Logic ----------
  Future<void> _saveTransaction() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    if (_selectedCategory == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a category')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final dateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final transaction = TransactionModel(
        id: const Uuid().v4(),
        type: _type,
        amount: amount,
        category: _selectedCategory!.name,
        date: dateTime,
        note: _noteController.text.trim(),
        paymentMethod: _paymentMethod,
        userId: '',
        createdAt: DateTime.now(),
      );

      await _transactionService.addTransaction(transaction);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Transaction saved!')));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }

    setState(() => _isLoading = false);
  }
}
