import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../hydrion/app/lib/services/llm_service.dart';
import '../../utils/i18n_resolver.dart';

/// ChatCoachScreen — minimal conversational UI for hydration coaching.
/// - Queues messages, disables send while awaiting response
/// - Keeps scroll pinned to latest message
class ChatCoachScreen extends StatefulWidget {
  const ChatCoachScreen({super.key});

  @override
  State<ChatCoachScreen> createState() => _ChatCoachScreenState();
}

class _ChatCoachScreenState extends State<ChatCoachScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  final List<Map<String, String>> _messages = [];
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final llm = context.read<LLMService>();
    final i18n = context.read<I18nResolver>();
    final dir = Directionality.of(context);

    final userMessage = _controller.text.trim();
    if (userMessage.isEmpty || _sending) return;

    setState(() {
      _sending = true;
      _messages.add({'role': 'user', 'content': userMessage});
      _controller.clear();
    });

    await Future<void>.delayed(Duration.zero);
    _scroll.animateTo(
      _scroll.position.maxScrollExtent + 80,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );

    try {
      // Use your real context here (pull hydration/activity/weather from DB).
      final coach = await llm.getHydrationCoachResponse(
        hydrationPercent: 75.0,
        activityMinutes: 30,
        temperatureC: 25.0,
      );
      if (!mounted) return;
      setState(() {
        _messages.add({'role': 'coach', 'content': coach});
      });
      await Future<void>.delayed(Duration.zero);
      _scroll.animateTo(
        _scroll.position.maxScrollExtent + 120,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            i18n.getText('chat_error', 'Couldn’t fetch coach reply'),
            textDirection: dir,
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final i18n = context.read<I18nResolver>();
    final dir = Directionality.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          i18n.getText('chat_coach_title', 'Hydration Coach'),
          textDirection: dir,
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: _messages.length,
              itemBuilder: (context, i) {
                final m = _messages[i];
                final isUser = m['role'] == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Card(
                      color: isUser
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.surfaceVariant,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          m['content'] ?? '',
                          textDirection: dir,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: isUser
                                    ? Theme.of(context).colorScheme.onPrimary
                                    : Theme.of(context).colorScheme.onSurface,
                              ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      enabled: !_sending,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: i18n.getText('chat_hint', 'Ask your coach...'),
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 48,
                    width: 48,
                    child: FilledButton(
                      onPressed: _sending ? null : _send,
                      child: _sending
                          ? const SizedBox(
                              width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
