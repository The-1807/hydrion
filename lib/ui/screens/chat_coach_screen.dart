import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/hydration_contracts.dart';
import '../../l10n/app_localizations.dart';
import '../../repositories/hydration_repository.dart';
import '../../repositories/settings_repository.dart';

class ChatCoachScreen extends StatefulWidget {
  const ChatCoachScreen({super.key});

  @override
  State<ChatCoachScreen> createState() => _ChatCoachScreenState();
}

class _ChatCoachScreenState extends State<ChatCoachScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final List<_CoachMessageEntry> _messages = <_CoachMessageEntry>[];
  final List<CoachSuggestionCard> _suggestions = <CoachSuggestionCard>[];
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

    final suggestionService = context.read<CoachSuggestionService>();
    final l10n = AppLocalizations.of(context);
    setState(() {
      _sending = true;
      _messages.add(_CoachMessageEntry.user(userMessage));
      _controller.clear();
    });

    try {
      final turn = await suggestionService.ask(
        userQuery: userMessage,
        digestKey: HydrationCoachDigestKey.weeklyDigest,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        final coachMessage = turn.message.trim();
        if (coachMessage.isNotEmpty) {
          _messages.add(_CoachMessageEntry.coach(coachMessage));
        }
        _suggestions.addAll(turn.suggestions);
        if (turn.usedFallback) {
          _messages.add(_CoachMessageEntry.notice(l10n.coachFallbackNotice));
        }
      });
      await _scrollToEnd();
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.chatError)),
      );
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  Future<void> _confirmSuggestion(CoachSuggestionCard card) async {
    final l10n = AppLocalizations.of(context);
    final result =
        await context.read<CoachSuggestionService>().confirm(card.id);
    if (!mounted) {
      return;
    }
    _updateSuggestionStatus(card.id, result.status);
    final message = switch (result.status) {
      CoachSuggestionStatus.applied => l10n.suggestionApplied,
      CoachSuggestionStatus.displayOnly => l10n.suggestionDisplayOnly,
      CoachSuggestionStatus.rejected => l10n.suggestionRejected,
      CoachSuggestionStatus.dismissed => l10n.suggestionDismissed,
      CoachSuggestionStatus.validated => l10n.suggestionValidated,
    };
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _dismissSuggestion(CoachSuggestionCard card) {
    context.read<CoachSuggestionService>().dismiss(card.id);
    _updateSuggestionStatus(card.id, CoachSuggestionStatus.dismissed);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).suggestionDismissed)),
    );
  }

  void _updateSuggestionStatus(
    String suggestionId,
    CoachSuggestionStatus status,
  ) {
    setState(() {
      final index = _suggestions.indexWhere((card) => card.id == suggestionId);
      if (index == -1) {
        return;
      }
      _suggestions[index] = _suggestions[index].copyWith(status: status);
    });
  }

  Future<void> _scrollToEnd() async {
    await Future<void>.delayed(Duration.zero);
    if (_scroll.hasClients) {
      await _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hydrationRepository = context.watch<HydrationRepository>();
    context.watch<UserSettingsRepository>();
    final todayMl = hydrationRepository.totalForDay(DateTime.now());
    final eventCount = hydrationRepository.eventCount;
    final capabilities = context.watch<AppCapabilityReporter>().capabilities;
    final providerHealth =
        context.watch<ProviderHealthReporter>().providerHealth;
    final activeProvider = _providerLabel(providerHealth.activeProvider, l10n);
    final visibleSuggestions = _suggestions
        .where((card) => card.status != CoachSuggestionStatus.dismissed)
        .toList(growable: false);
    final hasThreadContent =
        _messages.isNotEmpty || visibleSuggestions.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.chatCoachTitle),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Material(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: FutureBuilder<HydrationSummary>(
              future:
                  context.read<HydrationSummaryService>().getHydrationSummary(),
              builder: (context, snapshot) {
                final targetMl = snapshot.data?.targetMl ?? 2200;
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.lock_outline),
                  title: Text(
                    capabilities.cloudAi
                        ? l10n.providerCoachTitle
                        : l10n.localFallbackCoach,
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.coachContextSnapshot(
                          todayMl: todayMl,
                          targetMl: targetMl,
                          eventCount: eventCount,
                          activeProvider: activeProvider,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _coachProviderStatus(
                          health: providerHealth,
                          l10n: l10n,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _StatusChip(
                    icon: Icons.psychology_outlined,
                    label: '${l10n.selectedProvider}: '
                        '${_providerLabel(providerHealth.selectedProvider, l10n)}',
                  ),
                  _StatusChip(
                    icon: Icons.verified_outlined,
                    label: '${l10n.activeProvider}: $activeProvider',
                  ),
                  _StatusChip(
                    icon: providerHealth.fallbackReason == null
                        ? Icons.check_circle_outline
                        : Icons.replay_outlined,
                    label: providerHealth.fallbackReason == null
                        ? l10n.providerFallbackReady
                        : l10n.providerFallbackInUse,
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: !hasThreadContent
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
                    itemCount: _messages.length + visibleSuggestions.length,
                    itemBuilder: (context, index) {
                      if (index >= _messages.length) {
                        final card =
                            visibleSuggestions[index - _messages.length];
                        return _SuggestionCard(
                          card: card,
                          onConfirm: () => _confirmSuggestion(card),
                          onDismiss: () => _dismissSuggestion(card),
                        );
                      }
                      return _MessageBubble(entry: _messages[index]);
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

  String _coachProviderStatus({
    required ProviderHealthSnapshot health,
    required AppLocalizations l10n,
  }) {
    if (health.diagnostic.responseEnvelopePhase ==
        ProviderDiagnosticCodes.providerConsentRequired) {
      return l10n.coachProviderConsentRequired;
    }
    if (health.fallbackReason != null) {
      return l10n.coachProviderFallbackActive;
    }
    if (health.activeProvider == HydrionAiProviderKind.localRules) {
      return l10n.coachLocalProviderReady;
    }
    return l10n.coachProviderReady(
      activeProvider: _providerLabel(health.activeProvider, l10n),
    );
  }
}

enum _CoachMessageRole {
  user,
  coach,
  notice,
}

class _CoachMessageEntry {
  final _CoachMessageRole role;
  final String content;

  const _CoachMessageEntry._({
    required this.role,
    required this.content,
  });

  factory _CoachMessageEntry.user(String content) {
    return _CoachMessageEntry._(
      role: _CoachMessageRole.user,
      content: content,
    );
  }

  factory _CoachMessageEntry.coach(String content) {
    return _CoachMessageEntry._(
      role: _CoachMessageRole.coach,
      content: content,
    );
  }

  factory _CoachMessageEntry.notice(String content) {
    return _CoachMessageEntry._(
      role: _CoachMessageRole.notice,
      content: content,
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final _CoachMessageEntry entry;

  const _MessageBubble({required this.entry});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final isUser = entry.role == _CoachMessageRole.user;
    final isNotice = entry.role == _CoachMessageRole.notice;
    final background = isUser
        ? colorScheme.primary
        : isNotice
            ? colorScheme.tertiaryContainer
            : colorScheme.surfaceContainerHighest;
    final foreground = isUser
        ? colorScheme.onPrimary
        : isNotice
            ? colorScheme.onTertiaryContainer
            : colorScheme.onSurface;
    final labelColor = isUser
        ? colorScheme.onPrimary
        : isNotice
            ? colorScheme.onTertiaryContainer
            : colorScheme.onSurfaceVariant;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Card(
          color: background,
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  switch (entry.role) {
                    _CoachMessageRole.user => l10n.coachUserMessageLabel,
                    _CoachMessageRole.coach => l10n.coachReplyMessageLabel,
                    _CoachMessageRole.notice => l10n.coachFallbackNoticeLabel,
                  },
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: labelColor,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  entry.content,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: foreground,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  final CoachSuggestionCard card;
  final VoidCallback onConfirm;
  final VoidCallback onDismiss;

  const _SuggestionCard({
    required this.card,
    required this.onConfirm,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final canConfirm = card.requiresConfirmation &&
        card.status == CoachSuggestionStatus.validated;

    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Card(
          key: Key('coach-suggestion-${card.id}'),
          elevation: 0,
          color: colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: colorScheme.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      _suggestionIcon(card.kind),
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _suggestionTitle(card.kind, l10n),
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            card.message,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _StatusChip(
                      icon: Icons.account_tree_outlined,
                      label: l10n.suggestionProviderSource(
                        provider: _providerLabel(card.providerSource, l10n),
                      ),
                    ),
                    _StatusChip(
                      icon: Icons.fact_check_outlined,
                      label: l10n.suggestionValidationStatus(
                        status: _suggestionStatusLabel(card.status, l10n),
                      ),
                    ),
                    _StatusChip(
                      icon: card.requiresConfirmation
                          ? Icons.verified_user_outlined
                          : Icons.visibility_outlined,
                      label: card.requiresConfirmation
                          ? l10n.suggestionConfirmationRequired
                          : l10n.suggestionDisplayOnly,
                    ),
                  ],
                ),
                if (card.details.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  for (final detail in card.details)
                    _SuggestionDetailLine(
                      label: _suggestionDetailLabel(detail.kind, l10n),
                      value: _suggestionDetailValue(detail, l10n),
                    ),
                ],
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (canConfirm)
                      FilledButton.icon(
                        key: Key('coach-suggestion-confirm-${card.id}'),
                        onPressed: onConfirm,
                        icon: const Icon(Icons.check),
                        label: Text(l10n.suggestionApply),
                      ),
                    TextButton.icon(
                      key: Key('coach-suggestion-dismiss-${card.id}'),
                      onPressed: onDismiss,
                      icon: const Icon(Icons.close),
                      label: Text(l10n.suggestionDismiss),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SuggestionDetailLine extends StatelessWidget {
  final String label;
  final String value;

  const _SuggestionDetailLine({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StatusChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _providerLabel(
  HydrionAiProviderKind provider,
  AppLocalizations l10n,
) {
  return switch (provider) {
    HydrionAiProviderKind.localRules => l10n.localRulesProvider,
    HydrionAiProviderKind.gemini => l10n.geminiProvider,
    HydrionAiProviderKind.elka => l10n.elkaProvider,
  };
}

String _capabilityLabel(
  HydrionCapability capability,
  AppLocalizations l10n,
) {
  return switch (capability) {
    HydrionCapability.localPersistence => l10n.localPersistence,
    HydrionCapability.elka => l10n.elkaAdapter,
    HydrionCapability.gemini => l10n.geminiProvider,
    HydrionCapability.cloudAi => l10n.cloudAi,
    HydrionCapability.cloudSync => l10n.cloudSync,
    HydrionCapability.voiceInput => l10n.voiceInput,
    HydrionCapability.bleSync => l10n.bleBottleSync,
    HydrionCapability.healthSync => l10n.healthSync,
    HydrionCapability.osNotifications => l10n.osNotifications,
    HydrionCapability.arVisualization => l10n.arVisualization,
    HydrionCapability.socialSync => l10n.socialSync,
  };
}

IconData _suggestionIcon(CoachSuggestionKind kind) {
  return switch (kind) {
    CoachSuggestionKind.hydrationLog => Icons.water_drop_outlined,
    CoachSuggestionKind.reminder => Icons.schedule_outlined,
    CoachSuggestionKind.challenge => Icons.emoji_events_outlined,
    CoachSuggestionKind.trendInsight => Icons.insights_outlined,
    CoachSuggestionKind.unsupportedCapability => Icons.info_outline,
  };
}

String _suggestionTitle(
  CoachSuggestionKind kind,
  AppLocalizations l10n,
) {
  return switch (kind) {
    CoachSuggestionKind.hydrationLog => l10n.suggestionHydrationLogTitle,
    CoachSuggestionKind.reminder => l10n.suggestionReminderTitle,
    CoachSuggestionKind.challenge => l10n.suggestionChallengeTitle,
    CoachSuggestionKind.trendInsight => l10n.suggestionTrendTitle,
    CoachSuggestionKind.unsupportedCapability =>
      l10n.suggestionUnsupportedTitle,
  };
}

String _suggestionStatusLabel(
  CoachSuggestionStatus status,
  AppLocalizations l10n,
) {
  return switch (status) {
    CoachSuggestionStatus.validated => l10n.suggestionValidated,
    CoachSuggestionStatus.applied => l10n.suggestionApplied,
    CoachSuggestionStatus.dismissed => l10n.suggestionDismissed,
    CoachSuggestionStatus.rejected => l10n.suggestionRejected,
    CoachSuggestionStatus.displayOnly => l10n.suggestionDisplayOnly,
  };
}

String _suggestionDetailLabel(
  CoachSuggestionDetailKind kind,
  AppLocalizations l10n,
) {
  return switch (kind) {
    CoachSuggestionDetailKind.volumeMl => l10n.suggestionDetailVolume,
    CoachSuggestionDetailKind.delayMinutes => l10n.suggestionDetailDelay,
    CoachSuggestionDetailKind.priority => l10n.suggestionDetailPriority,
    CoachSuggestionDetailKind.challengeName => l10n.suggestionDetailChallenge,
    CoachSuggestionDetailKind.targetMl => l10n.suggestionDetailTarget,
    CoachSuggestionDetailKind.durationDays => l10n.suggestionDetailDuration,
    CoachSuggestionDetailKind.capability => l10n.suggestionDetailCapability,
  };
}

String _suggestionDetailValue(
  CoachSuggestionDetail detail,
  AppLocalizations l10n,
) {
  return switch (detail.kind) {
    CoachSuggestionDetailKind.volumeMl =>
      l10n.suggestionVolumeValue(volumeMl: detail.intValue ?? 0),
    CoachSuggestionDetailKind.delayMinutes =>
      l10n.suggestionDelayValue(minutes: detail.intValue ?? 0),
    CoachSuggestionDetailKind.priority => (detail.intValue ?? 0).toString(),
    CoachSuggestionDetailKind.challengeName =>
      detail.textValue ?? l10n.providerNotAvailable,
    CoachSuggestionDetailKind.targetMl =>
      l10n.suggestionTargetValue(targetMl: detail.intValue ?? 0),
    CoachSuggestionDetailKind.durationDays =>
      l10n.suggestionDurationValue(days: detail.intValue ?? 0),
    CoachSuggestionDetailKind.capability => detail.capability == null
        ? l10n.providerNotAvailable
        : _capabilityLabel(detail.capability!, l10n),
  };
}
