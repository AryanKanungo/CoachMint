import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/app_models.dart'; // Make sure this points to your final models file

class OnboardingService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<void> saveOnboardingData({
    required String rawIncomeType,
    required UserProfileModel profile,
    BillModel? firstBill,
  }) async {
    // 1. Update core user table (income_type)
    await _client
        .from('users')
        .update({'income_type': rawIncomeType})
        .eq('id', profile.userId);

    // 2. Upsert user profile using your model's toJson
    await _client.from('user_profile').upsert(profile.toJson());

    // 3. Insert first bill if it exists using your model's toJson
    if (firstBill != null) {
      await _client.from('bills').insert(firstBill.toJson());
    }
  }
}