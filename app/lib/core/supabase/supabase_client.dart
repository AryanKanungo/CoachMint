import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

String get currentUserId {
  final id = supabase.auth.currentUser?.id;
  if (id == null) throw Exception('User not authenticated');
  return id;
}

bool get isAuthenticated => supabase.auth.currentUser != null;