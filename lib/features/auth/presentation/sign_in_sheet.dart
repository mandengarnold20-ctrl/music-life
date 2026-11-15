import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/chamfered_button.dart';

/// Lien de retour après clic dans l'e-mail (à déclarer dans Supabase >
/// Authentication > URL Configuration, et dans AndroidManifest / Info.plist).
const kAuthRedirect = 'com.musiclife.app://login-callback';

/// Feuille de connexion par lien magique (sans mot de passe).
/// Renvoie true si l'utilisateur est connecté à la fermeture.
Future<bool> showSignInSheet(BuildContext context) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => const _SignInSheet(),
  );
  return result ?? false;
}

class _SignInSheet extends StatefulWidget {
  const _SignInSheet();

  @override
  State<_SignInSheet> createState() => _SignInSheetState();
}

class _SignInSheetState extends State<_SignInSheet> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  bool _sending = false;
  bool _sent = false;
  String? _error;
  StreamSubscription<AuthState>? _authSub;

  @override
  void initState() {
    super.initState();
    // Ferme la feuille dès que l'utilisateur revient connecté via le lien.
    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((state) {
      if (state.event == AuthChangeEvent.signedIn && mounted) Navigator.of(context).pop(true);
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await Supabase.instance.client.auth.signInWithOtp(
        email: _email.text.trim(),
        // Version web : le lien de l'e-mail ramène sur le site lui-même.
        emailRedirectTo: kIsWeb ? Uri.base.origin : kAuthRedirect,
        data: {'display_name': _name.text.trim()},
      );
      setState(() => _sent = true);
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Envoi impossible. Vérifiez votre connexion.');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + MediaQuery.of(context).viewInsets.bottom),
      child: _sent
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.mark_email_read_rounded, size: 48, color: AppColors.lilac),
                const SizedBox(height: 12),
                Text('Vérifiez votre boîte mail', style: text.titleLarge),
                const SizedBox(height: 8),
                Text(
                  'Nous avons envoyé un lien de connexion à ${_email.text.trim()}. '
                  'Ouvrez-le sur ce téléphone.',
                  textAlign: TextAlign.center,
                  style: text.bodyMedium,
                ),
                const SizedBox(height: 16),
              ],
            )
          : Form(
              key: _form,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Connexion', style: text.titleLarge),
                  const SizedBox(height: 4),
                  Text('Recevez un lien par e-mail, sans mot de passe.', style: text.bodyMedium),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _name,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(labelText: 'Votre nom (affiché dans le chat)'),
                    validator: (v) => (v == null || v.trim().length < 2) ? 'Indiquez votre nom' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    decoration: const InputDecoration(labelText: 'Adresse e-mail'),
                    validator: (v) =>
                        (v == null || !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim())) ? 'Adresse invalide' : null,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: const TextStyle(color: AppColors.live)),
                  ],
                  const SizedBox(height: 20),
                  ChamferedButton(
                    label: _sending ? 'Envoi…' : 'Recevoir le lien',
                    onPressed: _sending ? null : _send,
                  ),
                ],
              ),
            ),
    );
  }
}
