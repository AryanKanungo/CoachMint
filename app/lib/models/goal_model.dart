import 'package:flutter/material.dart';

// Defines the priority level of a goal.
enum GoalPriority { low, medium, high }

/// Represents a single contribution made towards a goal.
class Contribution {
  final double amount;
  final DateTime date;

  Contribution({
    required this.amount,
    required this.date,
  });
}

/// The core data model for a financial goal.
class Goal {
  final String title;
  final double totalAmount;
  final double currentAmount;
  final IconData icon;

  // --- Core Tracking Properties ---
  final DateTime creationDate;
  final DateTime? lastContributionDate;
  final double? lastContributionAmount;
  final DateTime? projectedReachDate;

  // --- Rich Feature Properties ---
  final GoalPriority priority;
  final DateTime? targetDate; // An optional user-defined deadline.
  final String? notes; // Optional user notes.
  final List<Contribution> contributions; // A history of all savings.

  Goal({
    required this.title,
    required this.totalAmount,
    required this.currentAmount,
    required this.icon,
    required this.creationDate,
    this.lastContributionDate,
    this.lastContributionAmount,
    this.projectedReachDate,
    this.priority = GoalPriority.medium, // Default priority
    this.targetDate,
    this.notes,
    this.contributions = const [], // Default to an empty list
  });
}
