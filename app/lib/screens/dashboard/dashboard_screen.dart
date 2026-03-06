import 'package:coachmint/screens/dashboard/prediction_chart.dart';
import 'package:coachmint/screens/dashboard/resilience_widget.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/app_models.dart';
import '../../utils/colors.dart';
import '../../controllers/dashboard_controller.dart';
import 'bill_tile.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = DashboardController();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("CoachMint", style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long_rounded, color: AppColors.greenAccent),
            onPressed: () => context.push('/sms-categorization'), // Direct path
          ),
          const SizedBox(width: 15),
        ],
      ),
      body: StreamBuilder<FinancialSnapshotModel>(
        stream: controller.snapshotStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: AppColors.greenAccent));
          }

          final data = snapshot.data!;

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                const SizedBox(height: 20),
                _buildMainBalanceTile(data.cb, data.spd),
                const SizedBox(height: 40),
                ResilienceWidget(score: data.resilienceScore),
                const SizedBox(height: 30),
                _buildDerivativeRow(data.survivalDays, data.ade),
                const SizedBox(height: 40),
                const PredictionChart(), // Hardcoded as requested
                const SizedBox(height: 40),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text("UPCOMING BILLS", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.white)),
                ),
                const SizedBox(height: 15),
                _buildBillsList(controller),
                const SizedBox(height: 50),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMainBalanceTile(double cb, double spd) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          const Text("TOTAL BALANCE", style: TextStyle(color: AppColors.secondaryText, fontSize: 12)),
          const SizedBox(height: 8),
          Text("₹${cb.toStringAsFixed(0)}",
              style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: AppColors.white)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.flash_on, color: AppColors.greenAccent, size: 18),
              Text(" SAFE TO SPEND: ₹${spd.toStringAsFixed(0)}",
                  style: const TextStyle(color: AppColors.greenAccent, fontWeight: FontWeight.bold)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildDerivativeRow(double survival, double ade) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _derivativeItem("SURVIVAL", "${survival.toInt()} DAYS"),
        _derivativeItem("DAILY AVG", "₹${ade.toInt()}"),
      ],
    );
  }

  Widget _derivativeItem(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: AppColors.secondaryText, fontSize: 10, letterSpacing: 1)),
        const SizedBox(height: 5),
        Text(value, style: const TextStyle(color: AppColors.white, fontSize: 20, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildBillsList(DashboardController controller) {
    return StreamBuilder<List<BillModel>>(
      stream: controller.upcomingBillsStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Text("No pending bills", style: TextStyle(color: AppColors.secondaryText));
        }
        final bills = snapshot.data!;
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: bills.length,
          itemBuilder: (context, index) => BillTile(bill: bills[index]),
        );
      },
    );
  }
}