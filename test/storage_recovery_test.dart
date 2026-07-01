import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:hydrion/main.dart';
import 'package:hydrion/repositories/challenge_repository.dart';
import 'package:hydrion/repositories/hydration_repository.dart';
import 'package:hydrion/repositories/reminder_repository.dart';
import 'package:hydrion/repositories/settings_repository.dart';
import 'package:hydrion/repositories/storage_recovery.dart';
import 'package:hydrion/storage/local_store.dart';

void main() {
  test('malformed hydration log JSON falls back without crashing', () async {
    const raw = '[{"volumeMl":250,"timestamp":';
    final store = MemoryHydrionStore({
      HydrationRepository.storageKey: raw,
    });

    final repository = await HydrationRepository.load(store);

    expect(repository.logs, isEmpty);
    expect(repository.recoveryEvents.single.code,
        StorageRecoveryCodes.malformedJson);
    expect(store.snapshot[HydrationRepository.storageKey], raw);
  });

  test('hydration JSON with wrong top-level type falls back safely', () async {
    final store = MemoryHydrionStore({
      HydrationRepository.storageKey: jsonEncode({'logs': []}),
    });

    final repository = await HydrationRepository.load(store);

    expect(repository.logs, isEmpty);
    expect(repository.recoveryEvents.single.code,
        StorageRecoveryCodes.wrongTopLevelType);
  });

  test('mixed hydration records keep valid records and skip invalid ones',
      () async {
    final newer = _hydrationJson(
      id: 'newer-valid',
      volumeMl: 500,
      timestamp: DateTime(2026, 5, 23, 12),
    );
    final older = _hydrationJson(
      id: 'older-valid',
      volumeMl: 250,
      timestamp: DateTime(2026, 5, 23, 8),
    );
    final store = MemoryHydrionStore({
      HydrationRepository.storageKey: jsonEncode([
        newer,
        'not an object',
        {'id': 'bad-date', 'volumeMl': 300, 'timestamp': 'not-a-date'},
        {'id': 'bad-volume', 'volumeMl': 0, 'timestamp': newer['timestamp']},
        older,
      ]),
    });

    final repository = await HydrationRepository.load(store);

    expect(repository.logs.map((log) => log.id), [
      'newer-valid',
      'older-valid',
    ]);
    expect(repository.recoveryEvents.single.skippedRecords, 3);
    expect(repository.recoveryEvents.single.action,
        StorageRecoveryActions.skipInvalidRecords);
  });

  test('valid hydration order survives invalid records under current sorting',
      () async {
    final first = _hydrationJson(
      id: 'first-valid',
      volumeMl: 300,
      timestamp: DateTime(2026, 5, 24, 9),
    );
    final second = _hydrationJson(
      id: 'second-valid',
      volumeMl: 350,
      timestamp: DateTime(2026, 5, 24, 8),
    );
    final store = MemoryHydrionStore({
      HydrationRepository.storageKey: jsonEncode([
        first,
        {'id': 'invalid', 'volumeMl': 'lots', 'timestamp': first['timestamp']},
        second,
      ]),
    });

    final repository = await HydrationRepository.load(store);

    expect(repository.logs.map((log) => log.id), [
      'first-valid',
      'second-valid',
    ]);
  });

  test('malformed reminder JSON falls back without scheduling anything',
      () async {
    const raw = '[{"message":"Drink","triggerTime":';
    final store = MemoryHydrionStore({
      ReminderRepository.storageKey: raw,
    });

    final repository = await ReminderRepository.load(store);

    expect(repository.reminders, isEmpty);
    expect(repository.recoveryEvents.single.code,
        StorageRecoveryCodes.malformedJson);
    expect(store.snapshot[ReminderRepository.storageKey], raw);
  });

  test('mixed reminder records preserve valid reminders where possible',
      () async {
    final early = _reminderJson(
      id: 'early-valid',
      triggerTime: DateTime(2026, 5, 23, 9),
    );
    final late = _reminderJson(
      id: 'late-valid',
      triggerTime: DateTime(2026, 5, 23, 12),
    );
    final store = MemoryHydrionStore({
      ReminderRepository.storageKey: jsonEncode([
        early,
        null,
        {'id': 'no-message', 'triggerTime': late['triggerTime'], 'priority': 1},
        {'id': 'bad-time', 'triggerTime': 'soon', 'message': 'Drink'},
        late,
      ]),
    });

    final repository = await ReminderRepository.load(store);

    expect(repository.reminders.map((reminder) => reminder.id), [
      'early-valid',
      'late-valid',
    ]);
    expect(repository.recoveryEvents.single.skippedRecords, 3);
  });

  test('invalid reminder data does not affect hydration logs', () async {
    final hydration = _hydrationJson(
      id: 'valid-log',
      volumeMl: 400,
      timestamp: DateTime(2026, 5, 23, 10),
    );
    final store = MemoryHydrionStore({
      HydrationRepository.storageKey: jsonEncode([hydration]),
      ReminderRepository.storageKey: '{bad reminder json',
    });

    final hydrationRepository = await HydrationRepository.load(store);
    final reminderRepository = await ReminderRepository.load(store);

    expect(hydrationRepository.logs.single.id, 'valid-log');
    expect(reminderRepository.reminders, isEmpty);
  });

  test('malformed active challenge JSON clears only challenge state', () async {
    final hydration = _hydrationJson(
      id: 'challenge-safe-log',
      volumeMl: 450,
      timestamp: DateTime(2026, 5, 23, 11),
    );
    final store = MemoryHydrionStore({
      HydrationRepository.storageKey: jsonEncode([hydration]),
      ChallengeRepository.storageKey: '{"id":',
    });

    final challengeRepository = await ChallengeRepository.load(store);
    final hydrationRepository = await HydrationRepository.load(store);

    expect(challengeRepository.activeChallenge, isNull);
    expect(challengeRepository.recoveryEvents.single.action,
        StorageRecoveryActions.clearCategory);
    expect(store.snapshot.containsKey(ChallengeRepository.storageKey), isFalse);
    expect(hydrationRepository.logs.single.id, 'challenge-safe-log');
  });

  test('invalid active challenge value results in no active challenge',
      () async {
    final store = MemoryHydrionStore({
      ChallengeRepository.storageKey: jsonEncode({
        'id': 'bad-challenge',
        'name': 'Bad',
        'description': 'Invalid target',
        'targetMl': 0,
        'durationDays': 7,
        'joinedAt': DateTime(2026, 5, 23).toIso8601String(),
      }),
    });

    final repository = await ChallengeRepository.load(store);

    expect(repository.activeChallenge, isNull);
    expect(repository.recoveryEvents.single.code,
        StorageRecoveryCodes.invalidValue);
    expect(store.snapshot.containsKey(ChallengeRepository.storageKey), isFalse);
  });

  test('malformed settings JSON falls back to a supported locale', () async {
    const raw = '{"languageCode":';
    final store = MemoryHydrionStore({
      UserSettingsRepository.storageKey: raw,
    });

    final repository = await UserSettingsRepository.load(store);

    expect(repository.settings.locale, UserSettings.fallbackLocale);
    expect(UserSettings.supportedLanguageCodes,
        contains(repository.settings.locale.languageCode));
    expect(repository.recoveryEvents.single.code,
        StorageRecoveryCodes.malformedJson);
  });

  test('unsupported settings locale falls back without losing valid consent',
      () async {
    final store = MemoryHydrionStore({
      UserSettingsRepository.storageKey: jsonEncode({
        'languageCode': 'de',
        'countryCode': 'DE',
        'nonLocalProviderConsentGranted': true,
      }),
    });

    final repository = await UserSettingsRepository.load(store);

    expect(repository.settings.locale, UserSettings.fallbackLocale);
    expect(repository.settings.nonLocalProviderConsentGranted, isTrue);
    expect(repository.recoveryEvents.single.code,
        StorageRecoveryCodes.invalidValue);
  });

  test('wrong or missing settings locale values use supported defaults',
      () async {
    final wrongTypeStore = MemoryHydrionStore({
      UserSettingsRepository.storageKey: jsonEncode({
        'languageCode': ['fr'],
      }),
    });
    final missingStore = MemoryHydrionStore({
      UserSettingsRepository.storageKey: jsonEncode({
        'countryCode': 'CA',
      }),
    });

    final wrongTypeRepository =
        await UserSettingsRepository.load(wrongTypeStore);
    final missingRepository = await UserSettingsRepository.load(missingStore);

    expect(wrongTypeRepository.settings.locale, UserSettings.fallbackLocale);
    expect(missingRepository.settings.locale, UserSettings.fallbackLocale);
    expect(UserSettings.supportedLanguageCodes,
        contains(wrongTypeRepository.settings.locale.languageCode));
    expect(UserSettings.supportedLanguageCodes,
        contains(missingRepository.settings.locale.languageCode));
  });

  test('invalid settings do not affect hydration logs', () async {
    final hydration = _hydrationJson(
      id: 'settings-safe-log',
      volumeMl: 375,
      timestamp: DateTime(2026, 5, 23, 12),
    );
    final store = MemoryHydrionStore({
      HydrationRepository.storageKey: jsonEncode([hydration]),
      UserSettingsRepository.storageKey: '{bad settings json',
    });

    final settingsRepository = await UserSettingsRepository.load(store);
    final hydrationRepository = await HydrationRepository.load(store);

    expect(settingsRepository.settings.locale, UserSettings.fallbackLocale);
    expect(hydrationRepository.logs.single.id, 'settings-safe-log');
  });

  test('unknown future schema data is not silently overwritten', () async {
    final futureHydration = jsonEncode({
      'schemaVersion': 99,
      'records': [_hydrationJson(id: 'future-log')],
    });
    final futureChallenge = jsonEncode({
      'schemaVersion': 99,
      'active': _challengeJson(id: 'future-challenge'),
    });
    final futureSettings = jsonEncode({
      'schemaVersion': 99,
      'languageCode': 'es',
    });
    final store = MemoryHydrionStore({
      HydrationRepository.storageKey: futureHydration,
      ChallengeRepository.storageKey: futureChallenge,
      UserSettingsRepository.storageKey: futureSettings,
    });

    final hydrationRepository = await HydrationRepository.load(store);
    final challengeRepository = await ChallengeRepository.load(store);
    final settingsRepository = await UserSettingsRepository.load(store);

    expect(hydrationRepository.logs, isEmpty);
    expect(challengeRepository.activeChallenge, isNull);
    expect(settingsRepository.settings.locale, UserSettings.fallbackLocale);
    expect(store.snapshot[HydrationRepository.storageKey], futureHydration);
    expect(store.snapshot[ChallengeRepository.storageKey], futureChallenge);
    expect(store.snapshot[UserSettingsRepository.storageKey], futureSettings);
    expect(
      [
        ...hydrationRepository.recoveryEvents,
        ...challengeRepository.recoveryEvents,
        ...settingsRepository.recoveryEvents,
      ].map((event) => event.code),
      everyElement(StorageRecoveryCodes.unsupportedSchemaVersion),
    );
  });

  test('startup services recover when persisted categories are malformed',
      () async {
    final store = MemoryHydrionStore({
      HydrationRepository.storageKey: '[bad',
      ReminderRepository.storageKey: '{"bad":"shape"}',
      ChallengeRepository.storageKey: '{"id":',
      UserSettingsRepository.storageKey: jsonEncode({'languageCode': 42}),
    });

    final services = await HydrionServices.fromStore(store);

    expect(services.hydrationRepository.logs, isEmpty);
    expect(services.reminderRepository.reminders, isEmpty);
    expect(services.challengeRepository.activeChallenge, isNull);
    expect(services.settingsRepository.settings.locale,
        UserSettings.fallbackLocale);
  });

  test('valid existing repository load behavior remains unchanged', () async {
    final hydration = _hydrationJson(id: 'valid-log', volumeMl: 600);
    final reminder = _reminderJson(id: 'valid-reminder');
    final challenge = _challengeJson(id: 'valid-challenge');
    final store = MemoryHydrionStore({
      HydrationRepository.storageKey: jsonEncode([hydration]),
      ReminderRepository.storageKey: jsonEncode([reminder]),
      ChallengeRepository.storageKey: jsonEncode(challenge),
      UserSettingsRepository.storageKey: jsonEncode({
        'languageCode': 'fr',
        'countryCode': 'CA',
        'nonLocalProviderConsentGranted': true,
      }),
    });

    final hydrationRepository = await HydrationRepository.load(store);
    final reminderRepository = await ReminderRepository.load(store);
    final challengeRepository = await ChallengeRepository.load(store);
    final settingsRepository = await UserSettingsRepository.load(store);

    expect(hydrationRepository.logs.single.id, 'valid-log');
    expect(reminderRepository.reminders.single.id, 'valid-reminder');
    expect(challengeRepository.activeChallenge?.id, 'valid-challenge');
    expect(settingsRepository.settings.locale, const Locale('fr', 'CA'));
    expect(settingsRepository.settings.nonLocalProviderConsentGranted, isTrue);
    expect(hydrationRepository.recoveryEvents, isEmpty);
    expect(reminderRepository.recoveryEvents, isEmpty);
    expect(challengeRepository.recoveryEvents, isEmpty);
    expect(settingsRepository.recoveryEvents, isEmpty);
  });

  test('recovery diagnostics never include complete persisted payloads',
      () async {
    const sensitivePayload = 'private hydration note';
    final store = MemoryHydrionStore({
      HydrationRepository.storageKey: jsonEncode([
        {'source': sensitivePayload, 'volumeMl': 250, 'timestamp': 'bad-date'},
      ]),
    });

    final repository = await HydrationRepository.load(store);
    final diagnosticText =
        repository.recoveryEvents.map((event) => event.toString()).join('\n');

    expect(repository.logs, isEmpty);
    expect(diagnosticText, isNot(contains(sensitivePayload)));
    expect(diagnosticText, contains(StorageRecoveryCodes.invalidRecord));
  });
}

Map<String, Object?> _hydrationJson({
  String id = 'hydration-log',
  int volumeMl = 250,
  DateTime? timestamp,
}) {
  return {
    'id': id,
    'volumeMl': volumeMl,
    'timestamp': (timestamp ?? DateTime(2026, 5, 23, 10)).toIso8601String(),
    'source': 'test',
  };
}

Map<String, Object?> _reminderJson({
  String id = 'reminder',
  DateTime? triggerTime,
}) {
  return {
    'id': id,
    'triggerTime': (triggerTime ?? DateTime(2026, 5, 23, 10)).toIso8601String(),
    'message': 'Drink water',
    'priority': 1,
  };
}

Map<String, Object?> _challengeJson({
  String id = 'challenge',
}) {
  return {
    'id': id,
    'name': 'Steady Sip',
    'description': 'Reach the target.',
    'targetMl': 2200,
    'durationDays': 7,
    'joinedAt': DateTime(2026, 5, 23).toIso8601String(),
  };
}
