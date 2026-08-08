import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../repositories/app_locale_repository.dart';
import '../l10n/app_localizations.dart';

enum HydrionTimedSessionKind { pomodoro, homework }

enum HydrionTimedSessionLifecycle { running, paused, stopped }

class HydrionTimedSessionNotification {
  final HydrionTimedSessionKind kind;
  final HydrionTimedSessionLifecycle lifecycle;
  final Duration remaining;
  final DateTime? completionAt;

  const HydrionTimedSessionNotification({
    required this.kind,
    required this.lifecycle,
    required this.remaining,
    this.completionAt,
  });
}

abstract class HydrionTimedSessionNotificationAdapter {
  Future<void> show(
      HydrionTimedSessionNotification notification, Locale locale);
  Future<void> cancel(HydrionTimedSessionKind kind);
  Future<void> cancelAll();
}

class AndroidTimedSessionNotificationAdapter
    implements HydrionTimedSessionNotificationAdapter {
  static const _channel = MethodChannel('hydrion/timed_session');

  const AndroidTimedSessionNotificationAdapter();

  bool get _supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  Future<void> show(
    HydrionTimedSessionNotification notification,
    Locale locale,
  ) async {
    if (!_supported) return;
    final l10n = lookupAppLocalizations(locale);
    try {
      await _channel.invokeMethod<void>('show', {
        'id': _id(notification.kind),
        'challengeId': _challengeId(notification.kind),
        'title': notification.kind == HydrionTimedSessionKind.homework
            ? l10n.homeworkSessionNotificationTitle
            : l10n.pomodoroSessionNotificationTitle,
        'state': notification.lifecycle.name,
        'pausedText': l10n.sessionPaused,
        'remainingSeconds': notification.remaining.inSeconds.clamp(0, 86400),
        'completionAtMillis': notification.completionAt?.millisecondsSinceEpoch,
        'pauseLabel':
            notification.lifecycle == HydrionTimedSessionLifecycle.paused
                ? l10n.resumeAction
                : l10n.pauseAction,
        'stopLabel': l10n.stopAction,
        'openLabel': l10n.openAction,
      });
    } on PlatformException {
      // The canonical timer remains valid if the optional OS surface fails.
    } on MissingPluginException {
      // Tests and non-Android hosts do not install the native channel.
    } catch (_) {
      // Isolated domain tests may run before a Flutter binding exists.
    }
  }

  @override
  Future<void> cancel(HydrionTimedSessionKind kind) async {
    if (!_supported) return;
    try {
      await _channel.invokeMethod<void>('cancel', {'id': _id(kind)});
    } on PlatformException {
      // Cleanup is retried during reconciliation and profile deletion.
    } on MissingPluginException {
      // Tests and non-Android hosts do not install the native channel.
    } catch (_) {
      // Isolated domain tests may run before a Flutter binding exists.
    }
  }

  @override
  Future<void> cancelAll() async {
    await cancel(HydrionTimedSessionKind.pomodoro);
    await cancel(HydrionTimedSessionKind.homework);
  }

  static int _id(HydrionTimedSessionKind kind) => switch (kind) {
        HydrionTimedSessionKind.pomodoro => 48101,
        HydrionTimedSessionKind.homework => 48102,
      };

  static String _challengeId(HydrionTimedSessionKind kind) => switch (kind) {
        HydrionTimedSessionKind.pomodoro => 'pomodoro-sip',
        HydrionTimedSessionKind.homework => 'homework-hydration',
      };
}

class FakeTimedSessionNotificationAdapter
    implements HydrionTimedSessionNotificationAdapter {
  final Map<HydrionTimedSessionKind, HydrionTimedSessionNotification> active =
      {};
  int showCount = 0;

  @override
  Future<void> show(
    HydrionTimedSessionNotification notification,
    Locale locale,
  ) async {
    showCount += 1;
    active[notification.kind] = notification;
  }

  @override
  Future<void> cancel(HydrionTimedSessionKind kind) async {
    active.remove(kind);
  }

  @override
  Future<void> cancelAll() async => active.clear();
}

class TimedSessionNotificationService {
  final AppLocaleRepository _localeRepository;
  final HydrionTimedSessionNotificationAdapter _adapter;
  final Map<HydrionTimedSessionKind, String> _signatures = {};
  final Map<HydrionTimedSessionKind, HydrionTimedSessionNotification> _active =
      {};

  TimedSessionNotificationService({
    required AppLocaleRepository localeRepository,
    HydrionTimedSessionNotificationAdapter adapter =
        const AndroidTimedSessionNotificationAdapter(),
  })  : _localeRepository = localeRepository,
        _adapter = adapter {
    _localeRepository.addListener(_handleLocaleChange);
  }

  Future<void> sync(HydrionTimedSessionNotification notification) async {
    if (notification.lifecycle == HydrionTimedSessionLifecycle.stopped ||
        notification.remaining <= Duration.zero) {
      _signatures.remove(notification.kind);
      _active.remove(notification.kind);
      await _adapter.cancel(notification.kind);
      return;
    }
    final signature = '${notification.lifecycle.name}:'
        '${notification.remaining.inSeconds}:'
        '${notification.completionAt?.millisecondsSinceEpoch ?? 0}:'
        '${_localeRepository.locale.toLanguageTag()}';
    if (_signatures[notification.kind] == signature) return;
    await _adapter.show(notification, _localeRepository.locale);
    _signatures[notification.kind] = signature;
    _active[notification.kind] = notification;
  }

  Future<void> cancel(HydrionTimedSessionKind kind) async {
    _signatures.remove(kind);
    _active.remove(kind);
    await _adapter.cancel(kind);
  }

  Future<void> cancelAll() async {
    _signatures.clear();
    _active.clear();
    await _adapter.cancelAll();
  }

  void _handleLocaleChange() {
    _signatures.clear();
    for (final notification in _active.values.toList(growable: false)) {
      unawaited(sync(notification));
    }
  }
}
