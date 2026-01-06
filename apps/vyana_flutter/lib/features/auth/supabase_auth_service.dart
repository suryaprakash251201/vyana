import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabaseAuthServiceProvider = Provider<SupabaseAuthService>((ref) {
  return SupabaseAuthService();
});

final supabaseUserProvider = StreamProvider<User?>((ref) {
  return ref.watch(supabaseAuthServiceProvider).authStateChanges.map((state) => state.session?.user);
});

class SupabaseAuthService {
  final SupabaseClient _client = Supabase.instance.client;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;
  User? get currentUser => _client.auth.currentUser;

  Future<void> signInWithPassword(String email, String password) async {
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<void> sendPasswordResetEmail(String email) async {
    final redirectUrl = 'io.supabase.vyana://login-callback'; 
    await _client.auth.resetPasswordForEmail(email, redirectTo: redirectUrl);
  }
}
