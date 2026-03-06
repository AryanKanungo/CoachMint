import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/app_models.dart';
 // Ensure correct path
import '../models/bill_model.dart' hide BillModel;
import '../services/dashboard_services.dart';     // Ensure correct path

class DashboardController {
  final _service = DashboardService();
  final _userId = Supabase.instance.client.auth.currentUser!.id;

  // Handles real-time updates for the Snapshot
  Stream<FinancialSnapshotModel> get snapshotStream {
    return _service.getSnapshotStream(_userId).map((data) {
      if (data.isEmpty) {
        return FinancialSnapshotModel(
          userId: _userId, snapshotDate: DateTime.now(),
          cb: 0, ub: 0, nd: 0, ade: 0, minReserve: 0,
          spd: 0, resilienceScore: 0, survivalDays: 0,
        );
      }
      return FinancialSnapshotModel.fromJson(data.first);
    });
  }

  // Processes bills and filters 'is_paid' on the client-side
  Stream<List<BillModel>> get upcomingBillsStream {
    return _service.getBillsStream(_userId).map((data) {
      return data
          .map((json) => BillModel.fromJson(json))
          .where((bill) => bill.isPaid == false) // Fixed underline error logic
          .toList();
    });
  }
}