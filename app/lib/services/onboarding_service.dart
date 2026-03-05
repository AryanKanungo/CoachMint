import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/app_models.dart'; // Adjust import path if necessary

class OnboardingService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Saves the user's initial financial profile and optional first bill.
  Future<void> saveOnboardingData({
    required UserProfileModel profile,
    BillModel? firstBill,
  }) async {

    // 1. Upsert the user profile data
    // This will create a new row if it doesn't exist, or update it if it does.
    await _client.from('user_profile').upsert(profile.toJson());

    // 2. Insert the first bill if the user provided one during Step 4
    if (firstBill != null) {
      await _client.from('bills').insert(firstBill.toJson());
    }
  }
}