import 'package:flutter/material.dart';

class ExpenseItem {
  final int index;
  final String label;
  final IconData icon;
  final TextEditingController amountController;

  ExpenseItem({
    required this.index,
    required this.label,
    required this.icon,
  }) : amountController = TextEditingController();
}