import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../models/app_models.dart';
import '../../../utils/colors.dart';
import '../../../utils/theme.dart';

class BillTile extends StatelessWidget {
  final BillModel bill;

  const BillTile({super.key, required this.bill});

  @override
  Widget build(BuildContext context) {
    // Highlight bills due within 3 days with a warning accent
    final daysUntilDue =
        bill.dueDate.difference(DateTime.now()).inDays;
    final isUrgent = daysUntilDue <= 3;
    final borderAccent =
        isUrgent ? AppColors.warning : AppColors.border;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: borderAccent),
      ),
      child: Row(
        children: [
          // ── Icon Badge ──────────────────────────────────────
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isUrgent
                  ? AppColors.warning.withOpacity(0.12)
                  : AppColors.primaryMuted,
              borderRadius:
                  BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: Icon(
              isUrgent
                  ? Icons.access_time_filled_rounded
                  : Icons.receipt_rounded,
              color: isUrgent ? AppColors.warning : AppColors.primary,
              size: 18,
            ),
          ),

          const SizedBox(width: 14),

          // ── Bill Name & Due Date ────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bill.name.toUpperCase(),
                  style: GoogleFonts.dmSans(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Due ${DateFormat('dd MMM').format(bill.dueDate)}',
                  style: GoogleFonts.dmSans(
                    color: isUrgent
                        ? AppColors.warning
                        : AppColors.textMuted,
                    fontSize: 12,
                    fontWeight:
                        isUrgent ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),

          // ── Amount ─────────────────────────────────────────
          Text(
            '₹${bill.amount.toStringAsFixed(0)}',
            style: GoogleFonts.dmSans(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }
}
