import 'package:coachmint/screens/sms_categorisation/sms_categorisation_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/transaction_model.dart';
import '../../utils/colors.dart';
import '../../utils/theme.dart';

// Top-level categories constant (unchanged — functional data)
const List<Map<String, dynamic>> kCategories = [
  {"label": "Food", "icon": Icons.restaurant_rounded, "color": Colors.orange},
  {"label": "Transport", "icon": Icons.train_rounded, "color": Colors.blue},
  {"label": "Bills", "icon": Icons.lightbulb_rounded, "color": Colors.red},
  {"label": "Shopping", "icon": Icons.shopping_cart_rounded, "color": Colors.green},
  {"label": "Health", "icon": Icons.local_hospital_rounded, "color": Colors.purple},
  {"label": "Other", "icon": Icons.category_rounded, "color": Colors.grey},
];

class SmsCategorizationScreen extends GetView<SmsCategorizationController> {
  const SmsCategorizationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        surfaceTintColor: AppColors.surface,
        title: const Text('Categorize Transactions'),
      ),
      body: Obx(() {
        if (!controller.isLoaded.value) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        final sorted = controller.transactions;
        final draggedIndex = controller.draggingIndex.value;

        if (sorted.isEmpty) {
          return Center(
            child: Text(
              'No transactions found from the last 7 days.',
              style: GoogleFonts.dmSans(
                color: AppColors.textMuted,
                fontSize: 14,
              ),
            ),
          );
        }

        final total = sorted.length + (draggedIndex != -1 ? 1 : 0);

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          itemCount: total,
          itemBuilder: (context, index) {
            if (draggedIndex != -1 && index == draggedIndex + 1) {
              return _buildCategoryInsertionPanel(context);
            }

            final realIndex = (draggedIndex != -1 && index > draggedIndex)
                ? index - 1
                : index;

            if (realIndex < 0 || realIndex >= sorted.length) {
              return const SizedBox.shrink();
            }

            return _buildTransactionTile(
                context, sorted[realIndex], realIndex);
          },
        );
      }),
    );
  }

  Widget _buildTransactionTile(
      BuildContext context, TransactionModel txn, int index) {
    final isIncome = txn.direction == 'in';
    final amountColor =
        isIncome ? AppColors.success : AppColors.danger;
    final categoryLabel = txn.category ?? 'Uncategorized';

    return LongPressDraggable<TransactionModel>(
      data: txn,
      onDragStarted: () {
        Future.microtask(() => controller.startCategorizing(index));
      },
      onDragEnd: (_) {
        Future.microtask(() => controller.stopCategorizing());
      },
      feedback: Material(
        color: Colors.transparent,
        clipBehavior: Clip.hardEdge,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
          child: Text(
            '₹${txn.amount.toStringAsFixed(2)} | $categoryLabel',
            style: GoogleFonts.dmSans(
              color: Colors.black,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
      childWhenDragging: Container(
        margin: const EdgeInsets.only(bottom: 10),
        height: 80,
        decoration: BoxDecoration(
          color: AppColors.surface.withOpacity(0.4),
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
          border: Border.all(
              color: AppColors.border, style: BorderStyle.solid),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            // ── Direction Icon ──────────────────────────────
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: amountColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: Icon(
                isIncome
                    ? Icons.arrow_upward_rounded
                    : Icons.arrow_downward_rounded,
                color: amountColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            // ── Payee + Date + Category ─────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    txn.payee?.trim().isNotEmpty == true
                        ? txn.payee!
                        : 'Unknown Merchant',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.dmSans(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    txn.formattedDate,
                    style: GoogleFonts.dmSans(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primaryMuted,
                      borderRadius: BorderRadius.circular(
                          AppTheme.radiusSm),
                    ),
                    child: Text(
                      categoryLabel,
                      style: GoogleFonts.dmSans(
                        color: AppColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // ── Amount + Drag Handle ────────────────────────
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹${txn.amount.toStringAsFixed(2)}',
                  style: GoogleFonts.dmSans(
                    color: amountColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 6),
                const Icon(Icons.drag_indicator_rounded,
                    size: 20, color: AppColors.textMuted),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryInsertionPanel(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16, top: 8),
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: AppColors.primary, width: 1.5),
      ),
      child: Column(
        children: [
          Text(
            'Drop Here to Categorize',
            style: GoogleFonts.dmSans(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 20,
              runSpacing: 16,
              children: kCategories.map((cat) {
                return _buildCategoryDragTarget(
                  cat['label'] as String,
                  cat['icon'] as IconData,
                  cat['color'] as Color,
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryDragTarget(
      String label, IconData icon, Color color) {
    return DragTarget<TransactionModel>(
      builder: (context, candidateData, rejectedData) {
        final hover = candidateData.isNotEmpty;
        return AnimatedScale(
          duration: const Duration(milliseconds: 150),
          scale: hover ? 1.15 : 1.0,
          child: Column(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: hover
                      ? color.withOpacity(0.8)
                      : color.withOpacity(0.12),
                  borderRadius:
                      BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: Icon(icon,
                    color: hover ? Colors.white : color, size: 24),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
      onAccept: (txn) {
        Future.microtask(() {
          controller.categorizeTransaction(txn, label);
          controller.stopCategorizing();

          Get.snackbar(
            'Categorized',
            'Transaction marked as $label',
            snackPosition: SnackPosition.TOP,
            backgroundColor: color.withOpacity(0.85),
            colorText: Colors.white,
          );
        });
      },
    );
  }
}
