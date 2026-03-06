import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import '../../controllers/transaction_controller.dart';
import '../../models/transaction_model.dart';
import '../../utils/routes.dart';

// File-level RegExp — never recreated on rebuild
final _vpaDisplayRe = RegExp(r'[\w.\-]+@\w+', caseSensitive: false);

/// screens/sms_categorisation/sms_categorsation_screen.dart
class SmsCategorizationScreen extends StatefulWidget {
  const SmsCategorizationScreen({super.key});

  @override
  State<SmsCategorizationScreen> createState() =>
      _SmsCategorizationScreenState();
}

class _SmsCategorizationScreenState extends State<SmsCategorizationScreen> {
  late final TransactionController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = Get.find<TransactionController>();
    // Always load on open — Supabase dedup prevents re-inserting old txns
    _ctrl.loadSmsTransactions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Categorize',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => context.push(AppRoutes.categorizedTxns),
            child: const Text(
              'Records',
              style: TextStyle(color: Color(0xFF6C63FF), fontSize: 13),
            ),
          ),
          IconButton(
            onPressed: () => context.go(AppRoutes.dashboard),
            icon: const Icon(Icons.home_outlined, color: Colors.black87),
            tooltip: 'Dashboard',
          ),
        ],
      ),
      body: Obx(() {
        if (_ctrl.isLoading.value) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Color(0xFF6C63FF)),
                SizedBox(height: 14),
                Text('Reading your SMS...',
                    style: TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
          );
        }

        if (_ctrl.errorMsg.value.isNotEmpty) {
          return _ErrorState(ctrl: _ctrl);
        }

        if (_ctrl.uncategorized.isEmpty) {
          return _EmptyState(ctrl: _ctrl);
        }

        return _Body(ctrl: _ctrl);
      }),
    );
  }
}

// ─── Body ─────────────────────────────────────────────────────────────────────

class _Body extends StatelessWidget {
  final TransactionController ctrl;
  const _Body({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Banner
        Container(
          width: double.infinity,
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Obx(() {
            final debits  = ctrl.uncategorized.where((t) => t.direction == 'debit').length;
            final credits = ctrl.uncategorized.where((t) => t.direction == 'credit').length;
            final parts   = <String>[];
            if (debits > 0)  parts.add('$debits expense${debits == 1 ? '' : 's'} to sort');
            if (credits > 0) parts.add('$credits income (view only)');
            parts.add('drag into a bucket');
            return Text(
              parts.join('  ·  '),
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            );
          }),
        ),

        // Scrollable tile list
        Expanded(
          child: Obx(
                () => ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              itemCount: ctrl.uncategorized.length,
              itemBuilder: (_, i) => _TxnTile(txn: ctrl.uncategorized[i]),
            ),
          ),
        ),

        // Drop zone — pinned bottom
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Drop expenses here to categorize',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: const [
                  _DropBucket(
                    label: 'Essential',
                    category: 'essential',
                    icon: Icons.home_outlined,
                    color: Color(0xFF4CAF50),
                  ),
                  SizedBox(width: 8),
                  _DropBucket(
                    label: 'Non-Essential',
                    category: 'non_essential',
                    icon: Icons.shopping_bag_outlined,
                    color: Color(0xFFFF7043),
                  ),
                  SizedBox(width: 8),
                  _DropBucket(
                    label: 'Savings',
                    category: 'savings_investments',
                    icon: Icons.trending_up,
                    color: Color(0xFF6C63FF),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Transaction tile ─────────────────────────────────────────────────────────

class _TxnTile extends StatelessWidget {
  final TransactionModel txn;
  const _TxnTile({required this.txn});

  @override
  Widget build(BuildContext context) {
    final isDebit = txn.direction == 'debit';

    if (!isDebit) {
      // Income — show but not draggable
      return _TxnCard(txn: txn, locked: true);
    }

    return Draggable<TransactionModel>(
      data: txn,
      feedback: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: MediaQuery.of(context).size.width - 24,
          child: _TxnCard(txn: txn, isGhost: true),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.25,
        child: _TxnCard(txn: txn),
      ),
      child: _TxnCard(txn: txn),
    );
  }
}

class _TxnCard extends StatelessWidget {
  final TransactionModel txn;
  final bool isGhost;
  final bool locked;

  const _TxnCard({
    required this.txn,
    this.isGhost = false,
    this.locked  = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDebit  = txn.direction == 'debit';
    final amtColor = isDebit ? const Color(0xFFFF7043) : const Color(0xFF4CAF50);

    // Subtitle: if payee is already a VPA show date only,
    // else show VPA from raw + date underneath
    final payeeIsVpa  = txn.payee.contains('@');
    final vpaFromRaw  = _vpaDisplayRe.firstMatch(txn.raw)?.group(0) ?? '';
    final showVpaSub  = !payeeIsVpa && vpaFromRaw.isNotEmpty;

    return Opacity(
      opacity: locked ? 0.5 : 1.0,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isGhost ? 0.14 : 0.05),
              blurRadius: isGhost ? 18 : 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Direction icon
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: amtColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isDebit ? Icons.arrow_upward : Icons.arrow_downward,
                size: 18,
                color: amtColor,
              ),
            ),
            const SizedBox(width: 12),

            // Payee + subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    txn.payee,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  if (showVpaSub) ...[
                    Text(
                      vpaFromRaw,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      txn.formattedDate,
                      style: TextStyle(fontSize: 10, color: Colors.grey[400]),
                    ),
                  ] else
                    Text(
                      txn.formattedDate,
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                ],
              ),
            ),

            // Amount
            Text(
              '${isDebit ? '−' : '+'}₹${txn.amount.toStringAsFixed(0)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: amtColor,
              ),
            ),
            const SizedBox(width: 6),

            Icon(
              locked ? Icons.lock_outline : Icons.drag_indicator,
              size: locked ? 15 : 20,
              color: Colors.grey[350],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Drop bucket ──────────────────────────────────────────────────────────────

class _DropBucket extends StatefulWidget {
  final String   label;
  final String   category;
  final IconData icon;
  final Color    color;

  const _DropBucket({
    required this.label,
    required this.category,
    required this.icon,
    required this.color,
  });

  @override
  State<_DropBucket> createState() => _DropBucketState();
}

class _DropBucketState extends State<_DropBucket> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<TransactionController>();

    return Expanded(
      child: DragTarget<TransactionModel>(
        // Hard-reject credits — only debits accepted
        onWillAcceptWithDetails: (details) {
          if (details.data.direction != 'debit') return false;
          setState(() => _hover = true);
          return true;
        },
        onLeave: (_) => setState(() => _hover = false),
        onAcceptWithDetails: (details) {
          setState(() => _hover = false);
          ctrl.categorize(details.data, widget.category);
        },
        builder: (_, candidateData, __) {
          final active = _hover || candidateData.isNotEmpty;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: widget.color.withOpacity(active ? 0.14 : 0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: widget.color.withOpacity(active ? 1.0 : 0.25),
                width: active ? 2.0 : 1.0,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(widget.icon, color: widget.color, size: 22),
                const SizedBox(height: 6),
                Text(
                  widget.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: widget.color,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final TransactionController ctrl;
  const _EmptyState({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'All caught up!',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'No new UPI transactions to categorize.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[400], fontSize: 14),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: 220,
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => context.push(AppRoutes.categorizedTxns),
                      icon: const Icon(Icons.history, size: 16),
                      label: const Text('View Records'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C63FF),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => context.go(AppRoutes.dashboard),
                      icon: const Icon(Icons.home_outlined, size: 16),
                      label: const Text('Dashboard'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black87,
                        side: const BorderSide(color: Colors.black26),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Error state ──────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  final TransactionController ctrl;
  const _ErrorState({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 56, color: Colors.red[300]),
            const SizedBox(height: 16),
            Obx(() => Text(
              ctrl.errorMsg.value,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            )),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: ctrl.loadSmsTransactions,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}