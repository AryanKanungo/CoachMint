import 'package:flutter/material.dart';
import '../../utils/colors.dart';

class GovtSchemesScreen extends StatelessWidget {
  const GovtSchemesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Govt Schemes', style: TextStyle(color: AppColors.mainText, fontSize: 24)),
    );
  }
}