import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../models/transaction_model.dart';
import '../../utils/colors.dart';

class CategorizedTransactionsScreen extends StatefulWidget {
  const CategorizedTransactionsScreen({super.key});

  @override
  State<CategorizedTransactionsScreen> createState() =>
      _CategorizedTransactionsScreenState();
}

class _CategorizedTransactionsScreenState
    extends State<CategorizedTransactionsScreen> {
  final List<String> filters = [
    "All",
    "Food",
    "Transport",
    "Bills",
    "Shopping",
    "Health",
    "Other"
  ];

  String selected = "All";

  Future<List<TransactionModel>> _loadCategorizedFromDb() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return [];

    final snap = await FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .collection("transactions")
        .orderBy("timestamp", descending: true)
        .get();

    return snap.docs.map((d) {
      final data = d.data();

      // timestamp can be Timestamp or int/millis; handle both
      DateTime timestamp;
      final tsField = data["timestamp"];
      if (tsField is Timestamp) {
        timestamp = tsField.toDate();
      } else if (tsField is int) {
        timestamp = DateTime.fromMillisecondsSinceEpoch(tsField);
      } else if (tsField is String) {
        timestamp = DateTime.tryParse(tsField) ?? DateTime.now();
      } else {
        timestamp = DateTime.now();
      }

      return TransactionModel(
        category: data["category"] as String?,
        amount: (data["amount"] ?? 0).toDouble(),
        payee: data["payee"] as String?,
        direction: (data["direction"] ?? "out") as String,
        source: (data["source"] ?? "sms") as String,
        text: (data["raw"] ?? "") as String,
        status: TxnStatus.processed,
        timestamp: timestamp,
        formattedDate: (data["formattedDate"] ??
            TransactionModel.dateToDDMMYYYY(timestamp))
        as String,

        /// ✅ REQUIRED NOW
        txnId: data["txnId"] as String, // ← ADDED THIS LINE
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        surfaceTintColor: AppColors.cardBackground,
        title: const Text("Categorized Transactions"),
      ),
      body: FutureBuilder<List<TransactionModel>>(
        future: _loadCategorizedFromDb(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Error loading transactions: ${snapshot.error}",
                style: textTheme.bodyMedium,
              ),
            );
          }

          final allCategorized = snapshot.data ?? [];

          // Apply filter
          final filtered = selected == "All"
              ? allCategorized
              : allCategorized.where((t) => t.category == selected).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // FILTER TABS
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: Row(
                  children: filters.map((f) {
                    final bool active = f == selected;

                    return GestureDetector(
                      onTap: () => setState(() => selected = f),
                      child: Container(
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: active
                              ? AppColors.primary
                              : AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(13),
                          border: Border.all(
                            color: active
                                ? AppColors.primary
                                : AppColors.secondaryText.withOpacity(0.4),
                          ),
                        ),
                        child: Text(
                          f,
                          style: TextStyle(
                            color: active ? Colors.white : AppColors.mainText,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              // RESULT LIST
              Expanded(
                child: filtered.isEmpty
                    ? const Center(
                  child: Text("No transactions found in this category"),
                )
                    : ListView.builder(
                  itemCount: filtered.length,
                  padding: const EdgeInsets.all(12),
                  itemBuilder: (context, i) {
                    final txn = filtered[i];
                    final color = txn.direction == "in"
                        ? AppColors.greenAccent
                        : AppColors.redAccent;

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        title: Text(txn.payee ?? "Unknown", style: TextStyle(color: AppColors.mainText),),
                        subtitle: Text(
                            "${txn.formattedDate} • ${txn.category}", style: TextStyle(color: AppColors.secondaryText),),
                        trailing: Text(
                          "₹${txn.amount.toStringAsFixed(2)}",
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
