import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/hydration_contracts.dart';
import '../../l10n/app_localizations.dart';
import '../../repositories/hydration_repository.dart';

class ChatCoachScreen extends StatefulWidget {
  const ChatCoachScreen({super.key});

  @override
  State<ChatCoachScreen> createState() => _ChatCoachScreenState();
}

class _ChatCoachScreenState extends State<ChatCoachScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final List<Map<String, String>> _messages = <Map<String, String>>[];
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final userMessage = _controller.text.trim();
    if (userMessage.isEmpty || _sending) {
      return;
    }

    setState(() {
      _sending = true;
      _messages.add({'role': 'user', 'content': userMessage});
      _controller.clear();
    });

    try {
      final coach = await context.read<HydrationCoach>().getCoachingAdvice(
            userQuery: userMessage,
            digestKey: HydrationCoachDigestKey.weeklyDigest,
          );
      if (!mounted) {
        return;
      }
      setState(() {
        _messages.add({'role': 'coach', 'content': coach});
      });
      await Future<void>.delayed(Duration.zero);
      if (_scroll.hasClients) {
        await _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.chatError)),
      );
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hydrationRepository = context.watch<HydrationRepository>();
    final todayMl = hydrationRepository.totalForDay(DateTime.now());
    final lifetimeMl = hydrationRepository.totalMl;
    final eventCount = hydrationRepository.eventCount;
    final capabilities = context.watch<AppCapabilityReporter>().capabilities;
    final mode = capabilities.elkaConfigured
        ? l10n.elkaAdapterConfiguredMode
        : l10n.standaloneLocalMode;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.chatCoachTitle),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Material(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: ListTile(
              dense: true,
              leading: const Icon(Icons.lock_outline),
              title: Text(l10n.localFallbackCoach),
              subtitle: Text(
                l10n.coachContextBanner(
                  mode: mode,
                  todayMl: todayMl,
                  lifetimeMl: lifetimeMl,
                  eventCount: eventCount,
                ),
              ),
            ),
          ),
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        l10n.askCoachEmpty,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scroll,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final isUser = message['role'] == 'user';
                      return Align(
                        alignment: isUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 520),
                          child: Card(
                            color: isUser
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest,
                            elevation: 0,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Text(
                                message['content'] ?? '',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: isUser
                                          ? Theme.of(context)
                                              .colorScheme
                                              .onPrimary
                                          : Theme.of(context)
                                              .colorScheme
                                              .onSurface,
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
                        hintText: l10n.chatHint,
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
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
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
