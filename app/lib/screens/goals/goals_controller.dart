import 'package:coachmint/models/goal_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class GoalsController extends GetxController {
  final goals = <Goal>[].obs;

  void addGoal(Goal goal) {
    goals.add(goal);
  }

  void deleteGoal(Goal goal) {
    goals.remove(goal);
  }

  void clearGoals() {
    goals.clear();
  }

  /// Calculates the projected date to reach the goal based on the average saving rate.
  static DateTime? calculateProjectedReachDate({
    required double totalAmount,
    required double currentAmount,
    required DateTime creationDate,
  }) {
    // If goal is already reached or no amount is saved, there's no projection.
    if (currentAmount <= 0 || currentAmount >= totalAmount) return null;

    final now = DateTime.now();
    int daysSinceCreation = now.difference(creationDate).inDays;

    // *** LOGIC FIX ***
    // If it's the same day, assume a 1-day saving period to get an initial projection.
    if (daysSinceCreation == 0) {
      daysSinceCreation = 1;
    }

    final averageDailySaving = currentAmount / daysSinceCreation;
    if (averageDailySaving <= 0) return null;

    final remainingAmount = totalAmount - currentAmount;
    final daysToReachGoal = (remainingAmount / averageDailySaving).ceil();

    return now.add(Duration(days: daysToReachGoal));
  }
}
