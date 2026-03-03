import 'dart:async';

import 'package:coachmint/models/goal_model.dart';
import 'package:coachmint/screens/goals/goals_controller.dart';
import 'package:coachmint/screens/goals/icon_picker_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../utils/colors.dart';
class AddEditGoalScreen extends StatefulWidget {
  final Goal? goal;
  const AddEditGoalScreen({super.key, this.goal});

  @override
  State<AddEditGoalScreen> createState() => _AddEditGoalScreenState();
}

class _AddEditGoalScreenState extends State<AddEditGoalScreen> {
  // --- State and Controllers (unchanged) ---
  final _formKey = GlobalKey<FormState>();
  final _goalsController = Get.find<GoalsController>();
  late TextEditingController _nameCtrl;
  late TextEditingController _targetAmountCtrl;
  late TextEditingController _notesCtrl;
  late double _currentAmount;
  late IconData _icon;
  late GoalPriority _priority;
  late DateTime? _targetDate;
  bool get _isEditing => widget.goal != null;

  @override
  void initState() {
    super.initState();
    final g = widget.goal;
    _nameCtrl = TextEditingController(text: g?.title ?? '');
    _targetAmountCtrl =
        TextEditingController(text: g?.totalAmount.toStringAsFixed(0) ?? '');
    _notesCtrl = TextEditingController(text: g?.notes ?? '');
    _currentAmount = g?.currentAmount ?? 0.0;
    _icon = g?.icon ?? Icons.star_border_rounded;
    _priority = g?.priority ?? GoalPriority.medium;
    _targetDate = g?.targetDate;
  }

  // --- Form Logic (unchanged) ---
  void _submitForm() {
    if (!_formKey.currentState!.validate()) return;
    // ... (Your existing submit logic is perfect and doesn't need to change)
    // ... (Omitted for brevity, paste your _submitForm logic back here)
    final name = _nameCtrl.text.trim();
    final notes = _notesCtrl.text.trim();
    final totalAmount = double.tryParse(_targetAmountCtrl.text.trim()) ?? 0.0;
    final currentAmount = _currentAmount.clamp(0.0, totalAmount);
    double? lastContributionAmount;
    DateTime? lastContributionDate;
    DateTime creationDate;
    List<Contribution> contributions;
    if (_isEditing) {
      creationDate = widget.goal!.creationDate;
      contributions = List.from(widget.goal!.contributions);
      final originalAmount = widget.goal!.currentAmount;
      if (currentAmount > originalAmount) {
        lastContributionAmount = currentAmount - originalAmount;
        lastContributionDate = DateTime.now();
        contributions.add(Contribution(
            amount: lastContributionAmount, date: lastContributionDate));
      } else {
        lastContributionAmount = widget.goal!.lastContributionAmount;
        lastContributionDate = widget.goal!.lastContributionDate;
      }
    } else {
      creationDate = DateTime.now();
      contributions = [];
      if (currentAmount > 0) {
        lastContributionAmount = currentAmount;
        lastContributionDate = DateTime.now();
        contributions.add(Contribution(
            amount: lastContributionAmount, date: lastContributionDate));
      }
    }
    final projectedReachDate = GoalsController.calculateProjectedReachDate(
      totalAmount: totalAmount,
      currentAmount: currentAmount,
      creationDate: creationDate,
    );
    final newGoal = Goal(
      title: name,
      icon: _icon,
      totalAmount: totalAmount,
      currentAmount: currentAmount,
      creationDate: creationDate,
      lastContributionAmount: lastContributionAmount,
      lastContributionDate: lastContributionDate,
      projectedReachDate: projectedReachDate,
      priority: _priority,
      targetDate: _targetDate,
      notes: notes,
      contributions: contributions,
    );
    if (_isEditing) {
      final index = _goalsController.goals.indexOf(widget.goal!);
      if (index != -1) {
        _goalsController.goals[index] = newGoal;
      }
    } else {
      _goalsController.addGoal(newGoal);
    }
    Get.back();
  }

  Future<void> _pickIcon() async {
    final selectedIcon = await Get.to<IconData>(() => const IconPickerScreen());
    if (selectedIcon != null) {
      setState(() => _icon = selectedIcon);
    }
  }

  Future<void> _pickTargetDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _targetDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              onPrimary: AppColors.white,
              surface: AppColors.cardBackground,
              onSurface: AppColors.mainText,
            ),
            dialogBackgroundColor: AppColors.background,
          ),
          child: child!,
        );
      },
    );
    if (pickedDate != null) {
      setState(() => _targetDate = pickedDate);
    }
  }

  // --- Main Build Method (Refactored) ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        surfaceTintColor: AppColors.cardBackground,
        title: Text(
          _isEditing ? 'Edit Goal' : 'Create Goal',
          style: const TextStyle(
              color: AppColors.mainText, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.mainText),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // We wrap each "section" in our new animation widget
              AnimatedFormItem(
                delay: const Duration(milliseconds: 100),
                child: _buildIconPicker(),
              ),
              const SizedBox(height: 24),
              AnimatedFormItem(
                delay: const Duration(milliseconds: 200),
                child: _buildGoalDetailsSection(),
              ),
              const SizedBox(height: 24),
              AnimatedFormItem(
                delay: const Duration(milliseconds: 300),
                child: _buildSettingsSection(),
              ),
              const SizedBox(height: 24),
              AnimatedFormItem(
                delay: const Duration(milliseconds: 400),
                child: _buildFormSection(
                  child: _buildNotes(),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _submitForm,
        icon: const Icon(Icons.check_circle_outline),
        label: Text(_isEditing ? 'Save Changes' : 'Create Goal'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  // --- NEW: Section-based Build Widgets ---

  /// A styled container for a form section
  Widget _buildFormSection({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }

  /// Section 1: Goal Name and Amounts
  Widget _buildGoalDetailsSection() {
    return _buildFormSection(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildNameField(),
          const SizedBox(height: 20),
          _buildTargetAmount(),
          const SizedBox(height: 20),
          _buildCurrentAmountSlider(),
        ],
      ),
    );
  }

  /// Section 2: Priority and Date
  Widget _buildSettingsSection() {
    return _buildFormSection(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPrioritySelector(),
          const SizedBox(height: 20),
          _buildTargetDate(),
        ],
      ),
    );
  }

  // --- Helper for Text Field Styling ---
  InputDecoration _buildInputDecoration(String label, {String? prefix}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppColors.secondaryText),
      prefixText: prefix,
      prefixStyle: const TextStyle(
          color: AppColors.mainText, fontSize: 20, fontWeight: FontWeight.bold),
      filled: true,
      fillColor: AppColors.background, // Slightly darker than card
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
    );
  }

  // --- Refactored & Interactive Build Widgets ---

  Widget _buildIconPicker() {
    return Center(
      child: GestureDetector(
        onTap: _pickIcon,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.cardBackground,
            border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 2),
          ),
          child: Column(
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, animation) {
                  return ScaleTransition(scale: animation, child: child);
                },
                child: Icon(
                  _icon,
                  key: ValueKey<IconData>(_icon), // Important!
                  size: 48,
                  color: AppColors.primaryLight,
                ),
              ),
              const SizedBox(height: 8),
              const Text('Change Icon',
                  style: TextStyle(color: AppColors.secondaryText, fontSize: 12))
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameCtrl,
      decoration: _buildInputDecoration('Goal Name'),
      style: const TextStyle(
          color: AppColors.mainText, fontWeight: FontWeight.w600, fontSize: 16),
      validator: (v) =>
      (v == null || v.trim().isEmpty) ? 'Please enter a name' : null,
    );
  }

  Widget _buildTargetAmount() {
    return TextFormField(
      controller: _targetAmountCtrl,
      style: const TextStyle(
          color: AppColors.mainText, fontWeight: FontWeight.bold, fontSize: 24),
      decoration: _buildInputDecoration('Target Amount', prefix: '₹ '),
      keyboardType: const TextInputType.numberWithOptions(decimal: false),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Please enter a target amount';
        if (double.tryParse(v) == null || double.parse(v) <= 0) {
          return 'Enter a valid amount';
        }
        return null;
      },
      onChanged: (_) => setState(() {
        final newMax = double.tryParse(_targetAmountCtrl.text.trim()) ?? 0.0;
        if (_currentAmount > newMax) _currentAmount = newMax;
      }),
    );
  }

  Widget _buildCurrentAmountSlider() {
    final maxSliderValue = double.tryParse(_targetAmountCtrl.text.trim()) ?? 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Current Amount:',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: AppColors.secondaryText),
            ),
            // --- INTERACTIVE WIDGET ---
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position:
                    Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero)
                        .animate(animation),
                    child: child,
                  ),
                );
              },
              child: Text(
                '₹${_currentAmount.toInt()}',
                // Use a key to tell the switcher the widget is different
                key: ValueKey<int>(_currentAmount.toInt()),
                style: const TextStyle(
                  color: AppColors.primaryLight,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.primary,
            inactiveTrackColor: AppColors.background,
            thumbColor: AppColors.primaryLight,
            overlayColor: AppColors.primary.withOpacity(0.2),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12.0),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 24.0),
          ),
          child: Slider(
            value: _currentAmount,
            min: 0,
            max: maxSliderValue > 0 ? maxSliderValue : 100.0,
            // Add more divisions for a smoother feel if max is large
            divisions: (maxSliderValue > 1)
                ? (maxSliderValue > 1000 ? 1000 : maxSliderValue.toInt())
                : 100,
            label: '₹${_currentAmount.toInt()}',
            onChanged: (value) => setState(() => _currentAmount = value),
          ),
        ),
      ],
    );
  }

  Widget _buildPrioritySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Priority Level',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(color: AppColors.mainText),
        ),
        const SizedBox(height: 12),
        SegmentedButton<GoalPriority>(
          segments: const [
            ButtonSegment(
                value: GoalPriority.low,
                label: Text('Low'),
                icon: Icon(Icons.arrow_downward)),
            ButtonSegment(
                value: GoalPriority.medium,
                label: Text('Medium'),
                icon: Icon(Icons.remove)),
            ButtonSegment(
                value: GoalPriority.high,
                label: Text('High'),
                icon: Icon(Icons.arrow_upward)),
          ],
          selected: {_priority},
          onSelectionChanged: (newSelection) =>
              setState(() => _priority = newSelection.first),
          style: SegmentedButton.styleFrom(
            backgroundColor: AppColors.background,
            foregroundColor: AppColors.secondaryText,
            selectedBackgroundColor: AppColors.primary,
            selectedForegroundColor: AppColors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            textStyle: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _buildTargetDate() {
    return InkWell(
      onTap: _pickTargetDate,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined,
                color: AppColors.secondaryText),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                _targetDate == null
                    ? 'Optional: Target Date'
                    : DateFormat.yMMMd().format(_targetDate!),
                style: TextStyle(
                  color: _targetDate == null
                      ? AppColors.secondaryText
                      : AppColors.mainText,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (_targetDate != null)
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.clear,
                    color: AppColors.secondaryText, size: 20),
                onPressed: () {
                  setState(() => _targetDate = null);
                },
              )
          ],
        ),
      ),
    );
  }

  Widget _buildNotes() {
    return TextFormField(
      controller: _notesCtrl,
      decoration: _buildInputDecoration('Notes (Optional)')
          .copyWith(alignLabelWithHint: true),
      style: const TextStyle(color: AppColors.mainText),
      maxLines: 4,
      textCapitalization: TextCapitalization.sentences,
    );
  }
}

// --- NEW: Animation Helper Widget ---
/// This widget handles the staggered fade-in and slide-up animation.
class AnimatedFormItem extends StatefulWidget {
  final Widget child;
  final Duration delay;

  const AnimatedFormItem({
    super.key,
    required this.child,
    required this.delay,
  });

  @override
  State<AnimatedFormItem> createState() => _AnimatedFormItemState();
}

class _AnimatedFormItemState extends State<AnimatedFormItem> {
  double _opacity = 0.0;
  Offset _offset = const Offset(0, 0.1);

  @override
  void initState() {
    super.initState();
    // Start the animation after the specified delay
    Timer(widget.delay, () {
      if (mounted) {
        setState(() {
          _opacity = 1.0;
          _offset = Offset.zero;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _opacity,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      child: AnimatedSlide(
        offset: _offset,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }}