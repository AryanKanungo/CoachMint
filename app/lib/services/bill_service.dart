 //.eq('user_id', '1');

 import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/bill_model.dart';
import 'package:flutter/material.dart';

class BillService {
  final _supabase = Supabase.instance.client;

  Future<List<BillModel>> fetchBills() async {
    try {
      // Get the ID of the currently logged-in user from the Supabase session
      final userId = _supabase.auth.currentUser?.id;

      if (userId == null) {
        debugPrint("No logged-in user found.");
        return [];
      }

      // Query the 'bills' table using the dynamic userId
      final response = await _supabase
          .from('bills')
          .select()
          .eq('user_id', userId); 
      
      return (response as List).map((json) => BillModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint("Supabase Fetch Error: $e");
      return [];
    }
  }

Future<void> deleteBill(String id) async {
  await _supabase.from('bills').delete().eq('id', id);
}

Future<void> createBill(BillModel bill) async {
  await _supabase.from('bills').insert(bill.toJson());
}

Future<void> updateBill(BillModel bill) async {
  await _supabase.from('bills').update(bill.toJson()).eq('id', bill.id);
}

}