// lib/screens/pin_screen.dart
import 'package:flutter/material.dart';
import '../services/pin_service.dart';
import '../utils/constants.dart';

enum PinMode { setup, verify }

class PinScreen extends StatefulWidget {
  final PinMode mode;
  const PinScreen({super.key, this.mode = PinMode.setup});

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  final PinService _pinService = PinService();
  final List<int> _pin = [];
  final int _maxLength = 4;
  String _error = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Enter PIN',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                widget.mode == PinMode.setup
                    ? 'Set a 4-digit PIN'
                    : 'Enter your PIN',
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: 40),
              // PIN circles
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_maxLength, (index) {
                  final filled = index < _pin.length;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: filled ? AppColors.primary : Colors.transparent,
                      border: Border.all(
                        color: filled ? AppColors.primary : Colors.grey,
                        width: 2,
                      ),
                    ),
                  );
                }),
              ),
              if (_error.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    _error,
                    style: const TextStyle(color: AppColors.expense),
                  ),
                ),
              const SizedBox(height: 40),
              // Number pad
              Column(
                children: [
                  _buildRow(['1', '2', '3']),
                  _buildRow(['4', '5', '6']),
                  _buildRow(['7', '8', '9']),
                  _buildRow(['delete', '0', 'enter']),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow(List<String> labels) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: labels.map((label) {
        return Expanded(
          child: GestureDetector(
            onTap: () => _handleInput(label),
            child: Container(
              height: 70,
              alignment: Alignment.center,
              child: label == 'delete'
                  ? const Icon(Icons.backspace_outlined, size: 28)
                  : label == 'enter'
                  ? const Icon(
                      Icons.check_circle_outline,
                      size: 28,
                      color: AppColors.primary,
                    )
                  : Text(label, style: const TextStyle(fontSize: 28)),
            ),
          ),
        );
      }).toList(),
    );
  }

  void _handleInput(String label) {
    setState(() => _error = '');
    if (label == 'delete') {
      if (_pin.isNotEmpty) _pin.removeLast();
    } else if (label == 'enter') {
      _submitPin();
    } else {
      if (_pin.length < _maxLength) {
        _pin.add(int.parse(label));
        if (_pin.length == _maxLength) {
          _submitPin();
        }
      }
    }
  }

  void _submitPin() async {
    if (_pin.length < _maxLength) {
      setState(() => _error = 'Please enter all 4 digits');
      return;
    }

    final entered = _pin.join('');
    if (widget.mode == PinMode.setup) {
      // For setup, save PIN and return success
      await _pinService.setPin(entered);
      Navigator.pop(context, true);
    } else {
      // Verify
      final isValid = await _pinService.verifyPin(entered);
      if (isValid) {
        Navigator.pop(context, true);
      } else {
        setState(() {
          _error = 'Incorrect PIN';
          _pin.clear();
        });
      }
    }
  }
}
