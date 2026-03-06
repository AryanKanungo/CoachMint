import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/app_models.dart';
import '../../../utils/colors.dart';

class BillTile extends StatelessWidget {
  // 1. This variable name must match the constructor below
  final BillModel bill;

  // 2. The constructor must be exactly this:
  const BillTile({super.key, required this.bill});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.white.withOpacity(0.05)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  bill.name.toUpperCase(),
                  style: const TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14
                  )
              ),
              const SizedBox(height: 4),
              Text(
                "Due ${DateFormat('dd MMM').format(bill.dueDate)}",
                style: const TextStyle(color: AppColors.secondaryText, fontSize: 12),
              ),
            ],
          ),
          Text(
            "₹${bill.amount.toStringAsFixed(0)}",
            style: const TextStyle(
                color: AppColors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold
            ),
          ),
        ],
      ),
    );
  }
}