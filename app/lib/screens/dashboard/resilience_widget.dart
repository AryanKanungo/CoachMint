import 'package:flutter/material.dart';
import '../../../utils/colors.dart';

class ResilienceWidget extends StatelessWidget {
  final int score;
  const ResilienceWidget({super.key, required this.score});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text("RESILIENCE SCORE",
            style: TextStyle(color: AppColors.secondaryText, fontSize: 12, letterSpacing: 2)),
        const SizedBox(height: 15),
        TweenAnimationBuilder(
          tween: IntTween(begin: 0, end: score),
          duration: const Duration(milliseconds: 1500),
          builder: (context, value, child) {
            return Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.greenAccent.withOpacity(0.5), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.greenAccent.withOpacity(0.15),
                    blurRadius: 40,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: Text(
                "$value",
                style: const TextStyle(
                  fontSize: 80,
                  fontWeight: FontWeight.bold,
                  color: AppColors.greenAccent,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}