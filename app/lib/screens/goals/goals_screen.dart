import 'package:coachmint/models/goal_model.dart';
import 'package:coachmint/screens/goals/add_edit_goal_screen.dart';
import 'package:coachmint/screens/goals/goals_controller.dart';
import 'package:coachmint/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final GoalsController controller = Get.put(GoalsController());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Goals', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.mainText)),
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined, color: Colors.redAccent, size: 34,),
            tooltip: 'Clear All Goals',
            onPressed: () {
              if (controller.goals.isEmpty) {
                Get.snackbar('No Goals', 'There are no goals to delete.', snackPosition: SnackPosition.BOTTOM);
                return;
              }
              Get.defaultDialog(
                // --- Dialog Styling ---
                title: "Confirm Deletion",
                titleStyle: GoogleFonts.inter(
                  color: AppColors.mainText, // Use your main text color
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
                middleText: "Are you sure you want to delete all goals? This cannot be undone.",
                middleTextStyle: GoogleFonts.inter(
                  color: AppColors.secondaryText, // Use your secondary text color
                  fontSize: 16,
                ),
                backgroundColor: AppColors.cardBackground, // Use your card color
                radius: 12, // Match your app's border radius
                contentPadding: const EdgeInsets.all(24),

                // --- Button Styling ---
                textCancel: "Cancel",
                textConfirm: "Delete", // More explicit than "OK"

                cancelTextColor: AppColors.secondaryText,
                confirmTextColor: Colors.white,
                buttonColor: AppColors.redAccent, // Use your "danger" color

                // --- Actions ---
                onConfirm: () {
                  controller.clearGoals();
                  Get.back(); // Close the dialog first

                  // --- Styled Snackbar ---
                  Get.snackbar(
                    'Success',
                    'All goals have been cleared.',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: AppColors.greenAccent, // Use your "success" color
                    colorText: Colors.white,
                    icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                    margin: const EdgeInsets.all(12),
                    borderRadius: 12,
                  );
                },
                onCancel: () {
                  // Get.back() is called automatically by textCancel
                },
              );
            },
          ),
        ],
      ),
      body: Obx(
            () => controller.goals.isEmpty
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.flag_outlined, size: 80, color: AppColors.secondaryText),
              const SizedBox(height: 20),
              Text(
                'No goals yet!\nTap the "+" button to add one.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: AppColors.secondaryText),
              ),
            ],
          ),
        )
            : ListView.builder(
          padding: const EdgeInsets.all(12.0),
          itemCount: controller.goals.length,
          itemBuilder: (context, index) {
            final goal = controller.goals[index];
            return GoalCard(
              goal: goal,
              onDelete: () => controller.deleteGoal(goal),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.to(() => const AddEditGoalScreen()),
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class GoalCard extends StatefulWidget {
  final Goal goal;
  final VoidCallback onDelete;

  const GoalCard({
    super.key,
    required this.goal,
    required this.onDelete,
  });

  @override
  State<GoalCard> createState() => _GoalCardState();
}

class _GoalCardState extends State<GoalCard> {
  bool _isExpanded = false;

  Color _getProgressColor(double progress) {
    if (progress >= 0.9) return Colors.green.shade600;
    if (progress <= 0.3) return Colors.orange.shade600;
    return Colors.blue.shade600;
  }

  // --- RECTIFIED FUNCTION ---
  // It now accepts a nullable GoalPriority and defaults to medium if null.
  Map<String, dynamic> _getPriorityInfo(GoalPriority? priority) {
    switch (priority) {
      case GoalPriority.high:
        return {'color': Colors.red.shade700, 'icon': Icons.arrow_upward};
      case GoalPriority.low:
        return {'color': Colors.grey.shade600, 'icon': Icons.arrow_downward};
      case GoalPriority.medium:
      case null: // Treat null as medium priority
      default:
        return {'color': Colors.blue.shade700, 'icon': Icons.remove};
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme
        .of(context)
        .textTheme;
    final progress = (widget.goal.totalAmount > 0)
        ? (widget.goal.currentAmount / widget.goal.totalAmount).clamp(0.0, 1.0)
        : 0.0;

    final priorityInfo = _getPriorityInfo(widget.goal.priority);
    final progressColor = _getProgressColor(progress);

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 10.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      child: InkWell(
        onTap: () => setState(() => _isExpanded = !_isExpanded),
        borderRadius: BorderRadius.circular(15.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: progressColor.withOpacity(0.15),
                    child: Icon(
                        widget.goal.icon, color: progressColor, size: 28),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Text(widget.goal.title,
                        style: textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.mainText)),
                  ),
                  Icon(priorityInfo['icon'], color: priorityInfo['color'],
                      size: 20),
                  // --- (Your AppColors and other imports) ---

                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: AppColors.secondaryText),
                    tooltip: "More options",
                    color: AppColors.cardBackground,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),

                    // --- THE FIX IS HERE ---
                    onSelected: (value) {
                      // Wait for the menu to close before running any Get.to or Get.snackbar
                      Future.delayed(Duration.zero, () {
                        if (value == 'edit') {
                          Get.to(() => AddEditGoalScreen(goal: widget.goal));
                        } else if (value == 'delete') {
                          widget.onDelete();

                          // Now this will work because the context is valid
                          Get.snackbar(
                            'Goal Deleted',
                            '"${widget.goal.title}" was removed.',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: AppColors.redAccent,
                            colorText: Colors.white,
                            icon: const Icon(Icons.delete_sweep_outlined, color: Colors.white),
                            margin: const EdgeInsets.all(12),
                            borderRadius: 12,
                          );
                        }
                      });
                    },
                    // --- END FIX ---

                    itemBuilder: (context) => [
                      PopupMenuItem<String>(
                        value: 'edit',
                        child: Row(
                          children: [
                            const Icon(Icons.edit_outlined, color: AppColors.secondaryText),
                            const SizedBox(width: 12),
                            Text('Edit Goal', style: GoogleFonts.inter(color: AppColors.mainText)),
                          ],
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'delete',
                        child: Row(
                          children: [
                            const Icon(Icons.delete_outline, color: AppColors.redAccent),
                            const SizedBox(width: 12),
                            Text(
                              'Delete Goal',
                              style: GoogleFonts.inter(color: AppColors.redAccent, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                ],
              ),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '₹${widget.goal.currentAmount.toInt()} / ₹${widget.goal
                        .totalAmount.toInt()}',
                    style: textTheme.titleMedium?.copyWith(
                        color: Colors.grey[700]),
                  ),
                  Text(
                    '${(progress * 100).toStringAsFixed(1)}%',
                    style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold, color: progressColor),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 12,
                  backgroundColor: Colors.grey[200],
                  color: progressColor,
                ),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: _isExpanded ? _buildSummaryView() : Container(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryView() {
    final goal = widget.goal;
    final hasContributionInfo =
        goal.lastContributionDate != null &&
            (goal.lastContributionAmount ?? 0) > 0;
    final hasProjectedDate = goal.projectedReachDate != null;
    final hasTargetDate = goal.targetDate != null;
    final hasNotes = goal.notes != null && goal.notes!.trim().isNotEmpty;
    final hasHistory = goal.contributions.isNotEmpty;

    final bool hasAnyData =
        hasContributionInfo || hasProjectedDate || hasTargetDate || hasNotes ||
            hasHistory;

    // Use an AnimatedSwitcher to fade between the empty and data states
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      transitionBuilder: (child, animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      child: hasAnyData
          ? _buildDataSummaryView(goal, hasContributionInfo, hasTargetDate,
          hasProjectedDate, hasNotes, hasHistory)
          : _buildEmptySummaryView(), // Use a dedicated empty state widget
    );
  }

// --- NEW: Helper for the Empty State ---

  Widget _buildEmptySummaryView() {
    // Use a ValueKey to help the AnimatedSwitcher
    return Container(
      key: const ValueKey('empty-summary'),
      padding: const EdgeInsets.symmetric(vertical: 48.0),
      child: const Column(
        children: [
          Icon(Icons.info_outline, color: AppColors.secondaryText, size: 32),
          SizedBox(height: 12),
          Text(
            'No summary details yet.',
            style: TextStyle(color: AppColors.secondaryText, fontSize: 16),
          ),
        ],
      ),
    );
  }

// --- NEW: Helper for the Data-Filled State ---

  Widget _buildDataSummaryView(Goal goal,
      bool hasContributionInfo,
      bool hasTargetDate,
      bool hasProjectedDate,
      bool hasNotes,
      bool hasHistory,) {
    // Use a ValueKey to help the AnimatedSwitcher
    return Container(
      key: const ValueKey('data-summary'),
      padding: const EdgeInsets.only(top: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // A more subtle divider
          Divider(color: AppColors.secondaryText.withOpacity(0.2), height: 1),
          const SizedBox(height: 20),
          const Text(
            'Summary',
            style: TextStyle(
              color: AppColors.mainText,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 16),

          // Use a Wrap for a flexible, card-based layout
          Wrap(
            spacing: 12, // Horizontal spacing
            runSpacing: 12, // Vertical spacing
            children: [
              if (hasContributionInfo)
                AnimatedFormItem(
                  delay: const Duration(milliseconds: 100),
                  child: _buildSummaryCard(
                    icon: Icons.history,
                    title: 'Last Saved',
                    value:
                    '₹${goal.lastContributionAmount?.toInt()} on ${DateFormat
                        .yMMMd().format(goal.lastContributionDate!)}',
                    iconColor: AppColors.greenAccent,
                  ),
                ),
              if (hasTargetDate)
                AnimatedFormItem(
                  delay: const Duration(milliseconds: 150),
                  child: _buildSummaryCard(
                    icon: Icons.flag_outlined,
                    title: 'Target Date',
                    value: DateFormat.yMMMd().format(goal.targetDate!),
                    iconColor: AppColors.redAccent,
                  ),
                ),
              if (hasProjectedDate)
                AnimatedFormItem(
                  delay: const Duration(milliseconds: 200),
                  child: _buildSummaryCard(
                    icon: Icons.calendar_today_outlined,
                    title: 'Projected Finish',
                    value: DateFormat.yMMMd().format(goal.projectedReachDate!),
                    iconColor: AppColors.primaryLight,
                  ),
                ),
            ],
          ),

          // Notes and History are kept separate from the Wrap
          if (hasNotes)
            AnimatedFormItem(
              delay: const Duration(milliseconds: 250),
              child: _buildNotesView(goal.notes!),
            ),

          if (hasHistory)
            AnimatedFormItem(
              delay: const Duration(milliseconds: 300),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () {
                    Get.snackbar(
                      'Coming Soon',
                      'Contribution history view is not yet implemented.',
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: AppColors.cardBackground,
                      colorText: AppColors.mainText,
                    );
                  },
                  icon: const Icon(Icons.receipt_long_outlined, size: 20),
                  label: const Text('View History'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primaryLight,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

// --- NEW: Reusable Summary Card Widget ---

  Widget _buildSummaryCard({
    required IconData icon,
    required String title,
    required String value,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min, // Keep row tight
            children: [
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.secondaryText,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.mainText,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

// --- NEW: Dedicated Notes View Widget ---

  Widget _buildNotesView(String notes) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.notes, size: 18, color: AppColors.secondaryText),
              SizedBox(width: 8),
              Text(
                'Notes',
                style: TextStyle(
                  color: AppColors.secondaryText,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background, // Slightly different from card bg
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              notes,
              style: const TextStyle(
                color: AppColors.mainText,
                fontStyle: FontStyle.italic,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
