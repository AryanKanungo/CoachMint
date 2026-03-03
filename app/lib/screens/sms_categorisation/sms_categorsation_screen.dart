import 'package:coachmint/screens/sms_categorisation/sms_categorisation_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/transaction_model.dart';
import '../../utils/colors.dart';

// Top-level categories constant
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
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        surfaceTintColor: AppColors.cardBackground,
        title: const Text("Categorize Transactions"),
      ),
      body: Obx(() {
        if (!controller.isLoaded.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final sorted = controller.transactions;
        final draggedIndex = controller.draggingIndex.value;

        if (sorted.isEmpty) {
          return Center(
            child: Text(
              "No transactions found from the last 7 days.",
              style: textTheme.bodyMedium,
            ),
          );
        }

        final total = sorted.length + (draggedIndex != -1 ? 1 : 0);

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          itemCount: total,
          itemBuilder: (context, index) {
            if (draggedIndex != -1 && index == draggedIndex + 1) {
              return _buildCategoryInsertionPanel(context);
            }

            final realIndex =
            (draggedIndex != -1 && index > draggedIndex) ? index - 1 : index;

            if (realIndex < 0 || realIndex >= sorted.length) {
              return const SizedBox.shrink();
            }

            return _buildTransactionTile(context, sorted[realIndex], realIndex);
          },
        );
      }),
    );
  }

  Widget _buildTransactionTile(BuildContext context, TransactionModel txn, int index) {
    final textTheme = Theme.of(context).textTheme;

    final isIncome = txn.direction == "in";
    final amountColor = isIncome ? AppColors.greenAccent : AppColors.redAccent;
    final categoryLabel = txn.category ?? "Uncategorized";

    return LongPressDraggable<TransactionModel>(
      data: txn,
      onDragStarted: () {
        // schedule state change outside render pipeline
        Future.microtask(() => controller.startCategorizing(index));
      },
      onDragEnd: (_) {
        Future.microtask(() => controller.stopCategorizing());
      },
      feedback: Material(
        color: Colors.transparent,
        clipBehavior: Clip.hardEdge,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            "₹${txn.amount.toStringAsFixed(2)} | $categoryLabel",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
      childWhenDragging: Container(
        margin: const EdgeInsets.only(bottom: 12),
        height: 80,
        decoration: BoxDecoration(
          color: AppColors.cardBackground.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: amountColor.withOpacity(0.15),
                child: Icon(
                  isIncome ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                  color: amountColor,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (txn.payee?.trim().isNotEmpty == true ? txn.payee! : "Unknown Merchant"),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: AppColors.mainText,
                      fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      txn.formattedDate,
                      style: textTheme.bodySmall?.copyWith(color: AppColors.secondaryText),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        categoryLabel,
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "₹${txn.amount.toStringAsFixed(2)}",
                    style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: amountColor),
                  ),
                  const SizedBox(height: 6),
                  Icon(Icons.drag_indicator_rounded, size: 22, color: AppColors.secondaryText),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryInsertionPanel(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18, top: 12),
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary, width: 2),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))],
      ),
      child: Column(
        children: [
          Text(
            "Drop Here to Categorize",
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: AppColors.mainText),
          ),
          const SizedBox(height: 18), // Added a bit more space

          // --- THIS IS THE UPDATED PART ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0), // Give the wrap some side padding
            child: Wrap(
              alignment: WrapAlignment.center, // Center the categories
              spacing: 16, // Horizontal space between icons
              runSpacing: 16, // Vertical space between rows
              children: kCategories.map((cat) {
                // We no longer need the extra horizontal Padding
                // around each item, as the Wrap's 'spacing' handles it.
                return _buildCategoryDragTarget(
                  cat["label"] as String,
                  cat["icon"] as IconData,
                  cat["color"] as Color,
                );
              }).toList(),
            ),
          ),
          // --- END OF UPDATE ---

        ],
      ),
    );
  }

// THIS WIDGET IS PERFECT! No changes needed.
  Widget _buildCategoryDragTarget(String label, IconData icon, Color color) {
    return DragTarget<TransactionModel>(
      builder: (context, candidateData, rejectedData) {
        final hover = candidateData.isNotEmpty;
        return AnimatedScale(
          duration: const Duration(milliseconds: 150),
          scale: hover ? 1.15 : 1.0,
          child: Column(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: hover ? color.withOpacity(0.8) : color.withOpacity(0.15),
                child: Icon(icon, color: hover ? Colors.white : color, size: 26),
              ),
              const SizedBox(height: 6),
              Text(label, style: const TextStyle(fontSize: 12, color: AppColors.mainText)),
            ],
          ),
        );
      },
      onAccept: (txn) {
        Future.microtask(() {
          controller.categorizeTransaction(txn, label);
          controller.stopCategorizing();

          Get.snackbar(
            "Success ",
            "Transaction categorized as $label!",
            snackPosition: SnackPosition.TOP,
            backgroundColor: color.withOpacity(0.7),
            colorText: Colors.white,
          );
        });
      },
    );
  }}
