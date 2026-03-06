import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/transaction_model.dart';
import '../../utils/colors.dart';
import '../../utils/theme.dart';

class CategorizedTransactionsScreen extends StatefulWidget {
  const CategorizedTransactionsScreen({super.key});

  @override
  State<CategorizedTransactionsScreen> createState() =>
      _CategorizedTransactionsScreenState();
}

class _CategorizedTransactionsScreenState
    extends State<CategorizedTransactionsScreen> {
  final List<String> filters = [
    'All',
    'Food',
    'Transport',
    'Bills',
    'Shopping',
    'Health',
    'Other',
  ];

  String selected = 'All';

  // Unchanged — functional Firebase logic
  Future<List<TransactionModel>> _loadCategorizedFromDb() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return [];

    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('transactions')
        .orderBy('timestamp', descending: true)
        .get();

    return snap.docs.map((d) {
      final data = d.data();

      DateTime timestamp;
      final tsField = data['timestamp'];
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
        category: data['category'] as String?,
        amount: (data['amount'] ?? 0).toDouble(),
        payee: data['payee'] as String?,
        direction: (data['direction'] ?? 'out') as String,
        source: (data['source'] ?? 'sms') as String,
        text: (data['raw'] ?? '') as String,
        status: TxnStatus.processed,
        timestamp: timestamp,
        formattedDate: (data['formattedDate'] ??
            TransactionModel.dateToDDMMYYYY(timestamp)) as String,
        txnId: data['txnId'] as String,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        surfaceTintColor: AppColors.surface,
        title: const Text('Categorized Transactions'),
      ),
      body: FutureBuilder<List<TransactionModel>>(
        future: _loadCategorizedFromDb(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading transactions: ${snapshot.error}',
                style: GoogleFonts.dmSans(
                    color: AppColors.textMuted, fontSize: 14),
              ),
            );
          }

          final allCategorized = snapshot.data ?? [];
          final filtered = selected == 'All'
              ? allCategorized
              : allCategorized
                  .where((t) => t.category == selected)
                  .toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Filter Chips ──────────────────────────────
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: filters.map((f) {
                    final bool active = f == selected;
                    return GestureDetector(
                      onTap: () => setState(() => selected = f),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: active
                              ? AppColors.primary
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(
                              AppTheme.radiusMd),
                          border: Border.all(
                            color: active
                                ? AppColors.primary
                                : AppColors.border,
                          ),
                        ),
                        child: Text(
                          f,
                          style: GoogleFonts.dmSans(
                            color: active
                                ? Colors.black
                                : AppColors.textSecondary,
                            fontWeight: active
                                ? FontWeight.w700
                                : FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              // ── Transaction List ─────────────────────────
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Text(
                          'No transactions in this category',
                          style: GoogleFonts.dmSans(
                            color: AppColors.textMuted,
                            fontSize: 14,
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: filtered.length,
                        padding: const EdgeInsets.fromLTRB(
                            16, 4, 16, 24),
                        itemBuilder: (context, i) {
                          final txn = filtered[i];
                          final isIncome = txn.direction == 'in';
                          final amountColor = isIncome
                              ? AppColors.success
                              : AppColors.danger;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(
                                  AppTheme.radiusCard),
                              border: Border.all(
                                  color: AppColors.border),
                            ),
                            child: Row(
                              children: [
                                // Direction icon
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: amountColor.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(
                                        AppTheme.radiusSm),
                                  ),
                                  child: Icon(
                                    isIncome
                                        ? Icons.arrow_upward_rounded
                                        : Icons.arrow_downward_rounded,
                                    color: amountColor,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Text content
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        txn.payee ?? 'Unknown',
                                        style: GoogleFonts.dmSans(
                                          color: AppColors.textPrimary,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        '${txn.formattedDate} · ${txn.category ?? 'Uncategorized'}',
                                        style: GoogleFonts.dmSans(
                                          color: AppColors.textMuted,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Amount
                                Text(
                                  '₹${txn.amount.toStringAsFixed(2)}',
                                  style: GoogleFonts.dmSans(
                                    color: amountColor,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
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
