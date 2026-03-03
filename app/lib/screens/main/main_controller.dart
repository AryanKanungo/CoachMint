import 'package:coachmint/screens/goals/goals_screen.dart';
import 'package:coachmint/screens/stats/stats_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../home/home_screen.dart'; // Placeholder

class MainController extends GetxController {
  var selectedIndex = 1.obs;

  final List<Widget> pages = [
    const GoalsScreen(),
    const HomeScreen(),
    const StatsScreen(), // Placeholder for stats
  ];

  void onItemTapped(int index) {
    selectedIndex.value = index;
  }
}