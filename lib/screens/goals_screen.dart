import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../services/goal_service.dart';
import '../models/goal_model.dart';
import '../utils/constants.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  final GoalService _goalService = GoalService();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _targetController = TextEditingController();
  final TextEditingController _currentController = TextEditingController();

  DateTime _selectedDeadline = DateTime.now().add(const Duration(days: 30));
  bool _isLoading = false;
  bool _isAddingGoal = false;

  // Predefined goal suggestions
  final List<String> _suggestedGoals = [
    'Travel',
    'Emergency Fund',
    'Laptop',
    'Bike',
    'Car',
    'Home Renovation',
    'Education',
    'Health',
    'Investments',
    'Vacation',
    'Gadgets',
    'Wedding',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Savings Goals'),
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: AppGradients.primary),
        ),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddGoalDialog(),
          ),
        ],
      ),
      body: StreamBuilder<List<GoalModel>>(
        stream: _goalService.getGoals(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          final goals = snapshot.data ?? [];
          final activeGoals = goals.where((g) => !g.isCompleted).toList();
          final completedGoals = goals.where((g) => g.isCompleted).toList();

          if (goals.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.emoji_events_outlined,
                    size: 80,
                    color: AppColors.textTertiary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Savings Goals Yet',
                    style: AppTextStyles.heading4.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Set your first financial goal today!',
                    style: AppTextStyles.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _showAddGoalDialog(),
                    icon: const Icon(Icons.add),
                    label: const Text('Create Goal'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.medium),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.only(
              left: AppSpacing.md,
              right: AppSpacing.md,
              top: AppSpacing.md,
              bottom: 80,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ---------- Summary Card ----------
                _buildSummaryCard(activeGoals, completedGoals),
                const SizedBox(height: AppSpacing.lg),

                // ---------- Active Goals ----------
                if (activeGoals.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Active Goals', style: AppTextStyles.heading4),
                      Text(
                        '${activeGoals.length} goals',
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ...activeGoals.map((goal) => _buildGoalCard(goal)),
                  const SizedBox(height: AppSpacing.lg),
                ],

                // ---------- Completed Goals ----------
                if (completedGoals.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Completed 🎉', style: AppTextStyles.heading4),
                      Text(
                        '${completedGoals.length} goals',
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ...completedGoals.map(
                    (goal) => _buildGoalCard(goal, isCompleted: true),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(
    List<GoalModel> activeGoals,
    List<GoalModel> completedGoals,
  ) {
    final totalGoals = activeGoals.length + completedGoals.length;
    final totalSaved =
        activeGoals.fold(0.0, (sum, g) => sum + g.currentAmount) +
        completedGoals.fold(0.0, (sum, g) => sum + g.currentAmount);
    final totalTarget =
        activeGoals.fold(0.0, (sum, g) => sum + g.targetAmount) +
        completedGoals.fold(0.0, (sum, g) => sum + g.targetAmount);
    final overallProgress = totalTarget > 0
        ? (totalSaved / totalTarget) * 100
        : 0;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: AppDecorations.glassCard(),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Text(
                  'Total Goals',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text('$totalGoals', style: AppTextStyles.heading3),
              ],
            ),
          ),
          Container(height: 40, width: 1, color: AppColors.border),
          Expanded(
            child: Column(
              children: [
                Text(
                  'Saved',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '₹${totalSaved.toStringAsFixed(0)}',
                  style: AppTextStyles.heading3.copyWith(
                    color: AppColors.income,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
          ),
          Container(height: 40, width: 1, color: AppColors.border),
          Expanded(
            child: Column(
              children: [
                Text(
                  'Progress',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${overallProgress.toStringAsFixed(0)}%',
                  style: AppTextStyles.heading3.copyWith(
                    color: AppColors.primary,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalCard(GoalModel goal, {bool isCompleted = false}) {
    final progress = goal.progress;
    final daysLeft = goal.deadline.difference(DateTime.now()).inDays;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: AppGradients.card,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: Border.all(
          color: isCompleted
              ? AppColors.income.withOpacity(0.3)
              : AppColors.border,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  goal.name,
                  style: AppTextStyles.bodyLarge.copyWith(
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                    color: isCompleted
                        ? AppColors.textSecondary
                        : AppColors.textPrimary,
                  ),
                ),
              ),
              if (isCompleted)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.income.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '✅ Done',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.income,
                    ),
                  ),
                ),
              if (!isCompleted)
                PopupMenuButton(
                  color: AppColors.card,
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      child: const Text('Add Money'),
                      onTap: () => _showAddMoneyDialog(goal),
                    ),
                    PopupMenuItem(
                      child: const Text('Edit'),
                      onTap: () => _showEditGoalDialog(goal),
                    ),
                    PopupMenuItem(
                      child: Text(
                        'Delete',
                        style: TextStyle(color: AppColors.expense),
                      ),
                      onTap: () => _confirmDelete(goal),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '₹${goal.currentAmount.toStringAsFixed(0)} saved',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isCompleted
                      ? AppColors.textSecondary
                      : AppColors.textPrimary,
                ),
              ),
              Text(
                '₹${goal.targetAmount.toStringAsFixed(0)} target',
                style: AppTextStyles.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress / 100,
              minHeight: 8,
              backgroundColor: AppColors.card,
              valueColor: AlwaysStoppedAnimation<Color>(
                isCompleted ? AppColors.income : AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${progress.toStringAsFixed(0)}% complete',
                style: TextStyle(
                  color: isCompleted
                      ? AppColors.income
                      : AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                daysLeft > 0
                    ? '$daysLeft days left'
                    : daysLeft == 0
                    ? 'Deadline today!'
                    : '${daysLeft.abs()} days overdue',
                style: TextStyle(
                  color: daysLeft < 0
                      ? AppColors.expense
                      : AppColors.textTertiary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------- Dialogs ----------

  void _showAddGoalDialog({GoalModel? existingGoal}) {
    final isEdit = existingGoal != null;
    if (isEdit) {
      _nameController.text = existingGoal.name;
      _targetController.text = existingGoal.targetAmount.toString();
      _currentController.text = existingGoal.currentAmount.toString();
      _selectedDeadline = existingGoal.deadline;
    } else {
      _nameController.clear();
      _targetController.clear();
      _currentController.text = '0';
      _selectedDeadline = DateTime.now().add(const Duration(days: 30));
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.large),
        ),
        title: Text(isEdit ? 'Edit Goal' : 'Create New Goal'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Goal Name with suggestions
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Goal Name',
                  hintText: 'e.g., Travel, Emergency Fund',
                ),
              ),
              const SizedBox(height: 8),
              // Quick suggestions
              Wrap(
                spacing: 6,
                children: _suggestedGoals.map((suggestion) {
                  return ActionChip(
                    label: Text(suggestion),
                    onPressed: () {
                      _nameController.text = suggestion;
                    },
                    backgroundColor: AppColors.primary.withOpacity(0.2),
                    labelStyle: TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _targetController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Target Amount (₹)',
                  prefixIcon: Icon(Icons.currency_rupee),
                ),
              ),
              const SizedBox(height: 12),
              if (!isEdit) ...[
                TextField(
                  controller: _currentController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Already Saved (₹)',
                    prefixIcon: Icon(Icons.currency_rupee),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              // Date Picker
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDeadline,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                  );
                  if (picked != null) {
                    setState(() => _selectedDeadline = picked);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(AppRadius.small),
                    border: Border.all(color: AppColors.border, width: 1),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Deadline: ${DateFormat('dd MMM yyyy').format(_selectedDeadline)}',
                        style: AppTextStyles.bodyMedium,
                      ),
                      Icon(
                        Icons.calendar_today,
                        color: AppColors.primary,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _saveGoal(context, isEdit, existingGoal),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.small),
              ),
            ),
            child: Text(isEdit ? 'Update' : 'Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveGoal(
    BuildContext context,
    bool isEdit,
    GoalModel? existingGoal,
  ) async {
    final name = _nameController.text.trim();
    final target = double.tryParse(_targetController.text);
    final current = double.tryParse(_currentController.text) ?? 0;

    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a goal name')));
      return;
    }
    if (target == null || target <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid target amount')),
      );
      return;
    }

    try {
      if (isEdit && existingGoal != null) {
        final updatedGoal = GoalModel(
          id: existingGoal.id,
          name: name,
          targetAmount: target,
          currentAmount: current,
          deadline: _selectedDeadline,
          userId: existingGoal.userId,
          createdAt: existingGoal.createdAt,
          updatedAt: DateTime.now(),
        );
        await _goalService.updateGoal(updatedGoal);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Goal updated!')));
      } else {
        final newGoal = GoalModel(
          id: const Uuid().v4(),
          name: name,
          targetAmount: target,
          currentAmount: current,
          deadline: _selectedDeadline,
          userId: '', // Will be set by service
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await _goalService.addGoal(newGoal);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Goal created! 🎯')));
      }
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }

  void _showAddMoneyDialog(GoalModel goal) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.large),
        ),
        title: Text('Add Money to ${goal.name}'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Amount (₹)',
            prefixIcon: Icon(Icons.currency_rupee),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(controller.text);
              if (amount == null || amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid amount')),
                );
                return;
              }
              try {
                await _goalService.addToGoal(goal.id, amount);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Added ₹${amount.toStringAsFixed(2)} to ${goal.name}!',
                    ),
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: ${e.toString()}')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.income,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.small),
              ),
            ),
            child: const Text('Add Money'),
          ),
        ],
      ),
    );
  }

  void _showEditGoalDialog(GoalModel goal) {
    _showAddGoalDialog(existingGoal: goal);
  }

  void _confirmDelete(GoalModel goal) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.large),
        ),
        title: const Text('Delete Goal'),
        content: Text('Are you sure you want to delete "${goal.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _goalService.deleteGoal(goal.id);
                Navigator.pop(context);
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Goal deleted')));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: ${e.toString()}')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.expense,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.small),
              ),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
