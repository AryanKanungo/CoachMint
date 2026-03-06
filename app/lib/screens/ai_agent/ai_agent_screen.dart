import 'package:flutter/material.dart';
import '../../utils/colors.dart';

class AIAgentScreen extends StatelessWidget {
  const AIAgentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('AI Agent', style: TextStyle(color: AppColors.mainText, fontSize: 24)),
    );
  }
}