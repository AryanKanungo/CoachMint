import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/transaction_controller.dart';
import '../../models/transaction_model.dart';

/// screens/sms_categorisation/categorized_transactions_screen.dart
class CategorizedTransactionsScreen extends StatefulWidget {
  const CategorizedTransactionsScreen({super.key});

  @override
  State<CategorizedTransactionsScreen> createState() =>
      _CategorizedTransactionsScreenState();
}

class _CategorizedTransactionsScreenState
    extends State<CategorizedTransactionsScreen> {
  final _ctrl = Get.find<TransactionController>();

  @override
  void initState() {
    super.initState();
    _ctrl.loadCategorized();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF0F2F5),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
          title: const Text(
            'Records',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
          bottom: const TabBar(
            labelColor: Color(0xFF6C63FF),
            unselectedLabelColor: Colors.grey,
            indicatorColor: Color(0xFF6C63FF),
            labelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            tabs: [
              Tab(text: 'Essential'),
              Tab(text: 'Non-Essential'),
              Tab(text: 'Savings'),
            ],
          ),
        ),
        body: Obx(() {
          if (_ctrl.isLoading.value) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF)));
          }
          if (_ctrl.errorMsg.value.isNotEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_ctrl.errorMsg.value,
                      style: TextStyle(color: Colors.grey[600])),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _ctrl.loadCategorized,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C63FF),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final essential    = _ctrl.categorized.where((t) => t.category == 'essential').toList();
          final nonEssential = _ctrl.categorized.where((t) => t.category == 'non_essential').toList();
          final savings      = _ctrl.categorized.where((t) => t.category == 'savings_investments').toList();

          return TabBarView(
            children: [
              _TxnList(txns: essential,    emptyLabel: 'No essential transactions yet',          color: const Color(0xFF4CAF50)),
              _TxnList(txns: nonEssential, emptyLabel: 'No non-essential transactions yet',      color: const Color(0xFFFF7043)),
              _TxnList(txns: savings,      emptyLabel: 'No savings/investment transactions yet', color: const Color(0xFF6C63FF)),
            ],
          );
        }),
      ),
    );
  }
}

class _TxnList extends StatelessWidget {
  final List<TransactionModel> txns;
  final String emptyLabel;
  final Color  color;

  const _TxnList({
    required this.txns,
    required this.emptyLabel,
    required this.color,
  });

  double get _total => txns.fold(0.0, (s, t) => s + t.amount);

  @override
  Widget build(BuildContext context) {
    if (txns.isEmpty) {
      return Center(
        child: Text(emptyLabel, style: TextStyle(color: Colors.grey[400])),
      );
    }

    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Text('${txns.length} transaction${txns.length == 1 ? '' : 's'}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              const Spacer(),
              Text(
                'Total  ₹${_total.toStringAsFixed(0)}',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: color, fontSize: 14),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: txns.length,
            itemBuilder: (_, i) => _TxnTile(txn: txns[i], accentColor: color),
          ),
        ),
      ],
    );
  }
}

class _TxnTile extends StatelessWidget {
  final TransactionModel txn;
  final Color accentColor;
  const _TxnTile({required this.txn, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    final isDebit  = txn.direction == 'debit';
    final amtColor = isDebit ? const Color(0xFFFF7043) : const Color(0xFF4CAF50);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 4, height: 44,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(txn.payee,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Text(txn.formattedDate,
                    style: TextStyle(fontSize: 11, color: Colors.grey[500])),
              ],
            ),
          ),
          Text(
            '${isDebit ? '−' : '+'}₹${txn.amount.toStringAsFixed(0)}',
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 15, color: amtColor),
          ),
        ],
      ),
    );
  }
}