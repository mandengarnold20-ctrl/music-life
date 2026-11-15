import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Client Supabase partagé (injectable pour les tests).
final supabaseClientProvider = Provider<SupabaseClient>((ref) => Supabase.instance.client);

/// Session courante (null = visiteur non connecté). Se met à jour à la connexion / déconnexion.
final authStateProvider = StreamProvider<Session?>((ref) {
  final auth = ref.watch(supabaseClientProvider).auth;
  return auth.onAuthStateChange.map((event) => event.session);
});

/// Rôle de l'utilisateur connecté ('user', 'moderator', 'admin') — null si visiteur.
final currentUserRoleProvider = FutureProvider<String?>((ref) async {
  final session = ref.watch(authStateProvider).valueOrNull;
  if (session == null) return null;
  final row = await ref
      .watch(supabaseClientProvider)
      .from('app_users')
      .select('role')
      .eq('id', session.user.id)
      .maybeSingle();
  return row?['role'] as String?;
});
