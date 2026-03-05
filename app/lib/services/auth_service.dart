import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<AuthResponse> registerWithEmail({
    required String email,
    required String password,
  }) async {
    // 1. Create the user securely in Supabase Auth
    final response = await _client.auth.signUp(
      email: email,
      password: password,
    );

    // 2. Insert their profile into your public table
    if (response.user != null) {
      try {
        await _client.from('users').insert({
          'id': response.user!.id,
          'email': response.user!.email,
          // Add any other non-sensitive defaults here if needed in the future
        });
      } catch (e) {
        print('Error inserting into public.users: $e');
        rethrow;
      }
    }

    return response;
  }

  // Your existing login method
  Future<AuthResponse> loginWithEmail({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}