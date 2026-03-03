import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'stats_controller.dart';
import '../../utils/colors.dart';

class StatsScreen extends GetView<StatsController> {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(StatsController());
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text("Statistics", style: textTheme.headlineMedium),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.insights_rounded, size: 80, color: AppColors.secondaryText),
            const SizedBox(height: 16),
            Text(
              "Deeper insights coming soon!",
              style: textTheme.bodyLarge?.copyWith(color: AppColors.secondaryText),
            ),
          ],
        ),
      ),
    );
  }
}