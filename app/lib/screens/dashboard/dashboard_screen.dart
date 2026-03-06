import 'package:flutter/material.dart';
import '../../utils/colors.dart';
import '../../services/bill_service.dart';
import '../../models/bill_model.dart';
import '../ai_agent/ai_agent_screen.dart';
import '../goals/track_goals_screen.dart';
import '../govt_schemes/govt_schemes_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const HomeContent(),
    const AIAgentScreen(),
    const TrackGoalsScreen(),
    const GovtSchemesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.cardBackground,
        selectedItemColor: AppColors.greenAccent, // Neon Green Accent
        unselectedItemColor: AppColors.secondaryText,
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.smart_toy), label: 'AI Agent'),
          BottomNavigationBarItem(icon: Icon(Icons.track_changes), label: 'Goals'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance), label: 'Schemes'),
        ],
      ),
    );
  }
}



// lib/screens/dashboard/dashboard_screen.dart

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  // Function to refresh the list after changes
  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.greenAccent,
        child: const Icon(Icons.add, color: AppColors.black),
        onPressed: () => _showBillDialog(context), // Add New Bill
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 40, 20, 10),
              child: Text(
                "Upcoming Bills",
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.white),
              ),
            ),
            Expanded(
              child: FutureBuilder<List<BillModel>>(
                future: BillService().fetchBills(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: AppColors.greenAccent));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text("No bills found", style: TextStyle(color: AppColors.secondaryText)));
                  }

                  final bills = snapshot.data!;
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: bills.length,
                    itemBuilder: (context, index) {
                      final bill = bills[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.white.withOpacity(0.05)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(bill.name.toUpperCase(), 
                                      style: const TextStyle(color: AppColors.secondaryText, fontSize: 12, letterSpacing: 1.2)),
                                    const SizedBox(height: 8),
                                    Text("₹${bill.amount.toStringAsFixed(0)}", 
                                      style: const TextStyle(color: AppColors.greenAccent, fontSize: 24, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                // Action Buttons: Update and Delete
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: AppColors.primary, size: 20),
                                      onPressed: () => _showBillDialog(context, bill: bill), // Update
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: AppColors.redAccent, size: 20),
                                      onPressed: () async {
                                        await BillService().deleteBill(bill.id);
                                        _refresh();
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const Divider(color: Colors.white10),
                            Row(
                              children: [
                                const Icon(Icons.access_time_filled, size: 14, color: AppColors.secondaryText),
                                const SizedBox(width: 6),
                                Text("Due ${bill.dueDate.day}/${bill.dueDate.month}", 
                                  style: const TextStyle(color: AppColors.secondaryText, fontSize: 13)),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Dialog for Adding or Updating a bill
  void _showBillDialog(BuildContext context, {BillModel? bill}) {
    // Implement logic to show a dialog with TextFields 
    // and call BillService().createBill() or updateBill()
  }
}

// class HomeContent extends StatelessWidget {
//   const HomeContent({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return SafeArea(
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Padding(
//             padding: EdgeInsets.fromLTRB(20, 40, 20, 10),
//             child: Text(
//               "Upcoming Bills",
//               style: TextStyle(
//                 fontSize: 26, 
//                 fontWeight: FontWeight.bold, 
//                 color: AppColors.white
//               ),
//             ),
//           ),

//           //hardcodeded
//           // Expanded( 
//           //   child: FutureBuilder<List<BillModel>>(
//           //     future: BillService().fetchBills(),
//           //     builder: (context, snapshot) {
//           //       if (snapshot.connectionState == ConnectionState.waiting) {
//           //         return const Center(
//           //           child: CircularProgressIndicator(color: AppColors.greenAccent)
//           //         );
//           //       }
                

//                 // Inside the HomeContent widget of dashboard_screen.dart
// Expanded(
//   child: FutureBuilder<List<BillModel>>(
//     // The service now automatically detects the logged-in user ID
//     future: BillService().fetchBills(), 
//     builder: (context, snapshot) {
//       if (snapshot.connectionState == ConnectionState.waiting) {
//         return const Center(
//           child: CircularProgressIndicator(color: AppColors.greenAccent)
//         );
//       }

//       if (!snapshot.hasData || snapshot.data!.isEmpty) {
//                   return const Center(
//                     child: Text("No bills found", style: TextStyle(color: AppColors.secondaryText))
//                   );
//                 }

//                 final bills = snapshot.data!;
//                 return ListView.builder(
//                   padding: const EdgeInsets.all(16),
//                   itemCount: bills.length,
//                   itemBuilder: (context, index) {
//                     final bill = bills[index];
//                     return Container(
//                       margin: const EdgeInsets.only(bottom: 16),
//                       padding: const EdgeInsets.all(24),
//                       decoration: BoxDecoration(
//                         color: AppColors.cardBackground,
//                         borderRadius: BorderRadius.circular(20),
//                         border: Border.all(color: AppColors.white.withOpacity(0.05)),
//                       ),
//                       child: Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text(
//                                 bill.name.toUpperCase(),
//                                 style: const TextStyle(
//                                   color: AppColors.secondaryText, 
//                                   fontSize: 12, 
//                                   letterSpacing: 1.2
//                                 ),
//                               ),
//                               const SizedBox(height: 8),
//                               Row(
//                                 children: [
//                                   const Icon(Icons.access_time_filled, size: 14, color: AppColors.secondaryText),
//                                   const SizedBox(width: 6),
//                                   Text(
//                                     "Due ${bill.dueDate.day}/${bill.dueDate.month}",
//                                     style: const TextStyle(color: AppColors.secondaryText, fontSize: 13),
//                                   ),
//                                 ],
//                               ),
//                             ],
//                           ),
//                           Text(
//                             "₹${bill.amount.toStringAsFixed(0)}",
//                             style: const TextStyle(
//                               color: AppColors.greenAccent, 
//                               fontSize: 24, 
//                               fontWeight: FontWeight.bold
//                             ),
//                           ),
//                         ],
//                       ),
//                     );
//                   },
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }