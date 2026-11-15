import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/supabase/supabase_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/sign_in_sheet.dart';
import '../../domain/chat_message.dart';
import '../live_tv_providers.dart';

/// Chat en direct sous la vidéo.
/// • Lecture pour tous ; écriture après connexion.
/// • Modérateurs : appui long sur un message pour le retirer.
class LiveChat extends ConsumerStatefulWidget {
  const LiveChat({super.key, required this.liveStreamId});

  final String liveStreamId;

  @override
  ConsumerState<LiveChat> createState() => _LiveChatState();
}

class _LiveChatState extends ConsumerState<LiveChat> {
  final _input = TextEditingController();
  bool _cooldown = false; // anti-spam simple côté appli (3 s entre deux messages)

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final body = _input.text.trim();
    if (body.isEmpty || _cooldown) return;
    setState(() => _cooldown = true);
    try {
      await ref.read(chatRepositoryProvider).send(widget.liveStreamId, body);
      _input.clear();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Message non envoyé. Le chat est peut-être fermé.')),
        );
      }
    } finally {
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _cooldown = false);
      });
    }
  }

  Future<void> _moderate(ChatMessage m) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Retirer ce message ?'),
        content: Text('« ${m.body} » — ${m.authorName}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Retirer')),
        ],
      ),
    );
    if (confirm == true) await ref.read(chatRepositoryProvider).remove(m.id);
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatMessagesProvider(widget.liveStreamId));
    final session = ref.watch(authStateProvider).valueOrNull;
    final role = ref.watch(currentUserRoleProvider).valueOrNull;
    final isModerator = role == 'moderator' || role == 'admin';
    final time = DateFormat.Hm('fr_FR');

    return Column(
      children: [
        Expanded(
          child: messages.when(
            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.lilac)),
            error: (_, __) => const Center(child: Text('Chat indisponible', style: TextStyle(color: AppColors.mist))),
            data: (list) => list.isEmpty
                ? const Center(
                    child: Text('Soyez le premier à saluer l\'assemblée',
                        style: TextStyle(color: AppColors.mist)),
                  )
                : ListView.builder(
                    reverse: true, // le plus récent en bas
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    itemCount: list.length,
                    itemBuilder: (context, i) {
                      final m = list[i];
                      return GestureDetector(
                        onLongPress: isModerator ? () => _moderate(m) : null,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: Text.rich(
                            TextSpan(children: [
                              TextSpan(
                                text: '${m.authorName}  ',
                                style: const TextStyle(color: AppColors.lilacPale, fontWeight: FontWeight.w700),
                              ),
                              TextSpan(text: m.body, style: const TextStyle(color: Colors.white)),
                              TextSpan(
                                text: '  ${time.format(m.createdAt)}',
                                style: const TextStyle(color: AppColors.mist, fontSize: 11),
                              ),
                            ]),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
            child: session == null
                ? SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: AppColors.lilac),
                        shape: const StadiumBorder(),
                      ),
                      onPressed: () => showSignInSheet(context),
                      icon: const Icon(Icons.chat_bubble_outline_rounded),
                      label: const Text('Se connecter pour participer au chat'),
                    ),
                  )
                : Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _input,
                          maxLength: 500,
                          minLines: 1,
                          maxLines: 3,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _send(),
                          decoration: const InputDecoration(hintText: 'Écrire un message…', counterText: ''),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        tooltip: 'Envoyer',
                        style: IconButton.styleFrom(backgroundColor: AppColors.violet),
                        onPressed: _cooldown ? null : _send,
                        icon: const Icon(Icons.send_rounded),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}
