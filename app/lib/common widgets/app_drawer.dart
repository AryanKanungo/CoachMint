import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../utils/colors.dart';
import 'package:coachmint/screens/sms_categorisation/categorized_transactions_screen.dart';

import '../utils/routes.dart';

// --- (Make sure to define these routes in your GetMaterialApp) ---
// These are needed for the "selected" state to work.
// ---

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  // Animation state
  late final List<bool> _showItems;
  final int _itemCount = 6; // Header + 3 items + Divider + Logout
  final int _baseDelay = 150; // Base delay for drawer to open
  final int _stagger = 75;

  @override
  void initState() {
    super.initState();
    _showItems = List.filled(_itemCount, false);
    _triggerAnimations();
  }

  /// Triggers a staggered animation for each item
  void _triggerAnimations() async {
    for (int i = 0; i < _itemCount; i++) {
      final delay = (i == 0 ? _baseDelay : 0) + _stagger;
      await Future.delayed(Duration(milliseconds: delay));
      if (mounted) setState(() => _showItems[i] = true);
    }
  }

  /// Reusable animation wrapper
  Widget _buildAnimatedItem(int index, Widget child) {
    return AnimatedSlide(
      offset: _showItems[index] ? Offset.zero : const Offset(-0.2, 0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      child: AnimatedOpacity(
        opacity: _showItems[index] ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 300),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get the current route name from GetX to set the "selected" state
    final String currentRoute = Get.currentRoute;

    return Drawer(
      backgroundColor: AppColors.cardBackground,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ---------- 1. ENGAGING HEADER ----------
          _buildAnimatedItem(0, _buildDrawerHeader(context)),

          // ---------- 2. CONTEXT-AWARE MENU ----------
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Column(
              children: [
                _buildAnimatedItem(
                  1,
                  _DrawerMenuItem(
                    title: 'Categorize Transactions',
                    icon: Icons.sort_rounded,
                    routeName: AppRoutes.smsCategorization,
                    isSelected: currentRoute == AppRoutes.smsCategorization,
                    onTap: () {
                      Navigator.pop(context);
                      // Use Get.toNamed so the route name is updated
                      Get.toNamed(AppRoutes.smsCategorization);
                    },
                  ),
                ),
                _buildAnimatedItem(
                  2,
                  _DrawerMenuItem(
                    title: 'Categorized Transactions',
                    icon: Icons.label_rounded,
                    routeName: AppRoutes.categorizedTransactions,
                    isSelected:
                    currentRoute == AppRoutes.categorizedTransactions,
                    onTap: () {
                      Navigator.pop(context);
                      // Use Get.toNamed for this too
                      Get.toNamed(AppRoutes.categorizedTransactions);

                      // OLD: Get.to(() => const CategorizedTransactionsScreen());
                      // NOTE: Get.to() doesn't update Get.currentRoute,
                      // so we MUST use Get.toNamed() for the "selected"
                      // state to work.
                    },
                  ),
                ),
                _buildAnimatedItem(
                  3,
                  _DrawerMenuItem(
                    title: 'Settings',
                    icon: Icons.settings_rounded,
                    routeName: AppRoutes.settings,
                    isSelected: currentRoute == AppRoutes.settings,
                    onTap: () {
                      Navigator.pop(context);
                      // TODO: Create a settings page and route
                      // Get.toNamed(AppRoutes.settings);
                    },
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          // ---------- 3. PREMIUM LOGOUT ----------
          _buildAnimatedItem(
            4,
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Divider(color: AppColors.secondaryText.withOpacity(0.2)),
            ),
          ),
          _buildAnimatedItem(
            5,
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: _DrawerMenuItem(
                title: 'Logout',
                icon: Icons.logout,
                routeName: '/logout',
                isSelected: false, // Never selected
                onTap: () async {
                  Navigator.pop(context);
                  await AuthService().signOut();
                  Get.snackbar(
                    "Logged Out",
                    "You have been signed out successfully.",
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: AppColors.greenAccent,
                    colorText: Colors.white,
                  );
                  Get.offAllNamed('/login');
                },
                // Destructive action styling
                color: AppColors.redAccent,
              ),
            ),
          ),
          const SafeArea(top: false, child: SizedBox(height: 8)),
        ],
      ),
    );
  }

  /// A more personal and well-styled header
  Widget _buildDrawerHeader(BuildContext context) {
    // We use a Container instead of DrawerHeader for more control
    return Container(
      padding:
      const EdgeInsets.only(left: 24, right: 24, top: 60, bottom: 24),
      decoration: const BoxDecoration(
        color: Color(0xFF111111), // A very dark, subtle background
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 56,
            width: 56,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(16), // Softer edges
            ),
            child: const Icon(Icons.account_balance_wallet,
                size: 30, color: Colors.white),
          ),
          const SizedBox(height: 16),
          Text(
            'CoachMint',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppColors.mainText,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'v1.0.0', // You could replace this with a user's email
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.secondaryText,
            ),
          ),
        ],
      ),
    );
  }
}

/// --- NEW WIDGET: A "Context-Aware" Menu Item ---
/// This is the "engaging" part. It knows if it's selected.
class _DrawerMenuItem extends StatelessWidget {
  const _DrawerMenuItem({
    required this.title,
    required this.icon,
    required this.routeName,
    required this.isSelected,
    required this.onTap,
    this.color, // For special cases like logout
  });

  final String title;
  final IconData icon;
  final String routeName;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    // --- Define active vs. inactive styles ---
    final Color backgroundColor =
    isSelected ? AppColors.primary : Colors.transparent;
    final Color contentColor = isSelected
        ? Colors.white
        : color ?? AppColors.secondaryText; // Use special color if provided
    final FontWeight fontWeight =
    isSelected ? FontWeight.bold : FontWeight.normal;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      // Use ClipRRect for the splash animation to follow the border
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Material(
          color: backgroundColor,
          child: InkWell(
            onTap: onTap,
            splashColor: (color ?? AppColors.primary).withOpacity(0.1),
            highlightColor: (color ?? AppColors.primary).withOpacity(0.05),
            child: Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Icon(icon, size: 22, color: contentColor),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : color ?? AppColors.mainText,
                        fontSize: 16,
                        fontWeight: fontWeight,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}