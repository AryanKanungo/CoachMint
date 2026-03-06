import 'package:flutter/material.dart';
import '../../utils/colors.dart';

class TrackGoalsScreen extends StatelessWidget {
  const TrackGoalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Track Goals', style: TextStyle(color: AppColors.mainText, fontSize: 24)),
    );
  }
}