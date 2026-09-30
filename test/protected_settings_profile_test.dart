import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:hydrion/repositories/settings_repository.dart';
import 'package:hydrion/repositories/settings_protection.dart';
import 'package:hydrion/services/validated_profile_photo.dart';
import 'package:hydrion/storage/encrypted_app_store.dart';
import 'package:hydrion/storage/local_store.dart';
import 'package:hydrion/storage/protected_app_store.dart';
import 'package:hydrion/storage/protected_settings_record.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;
import 'support/profile_photo_fixture.dart';

// Synthetic PNG construction is shared with consumer regression fixtures.

class RejectingPreferences extends MemoryHydrionStore {
  bool reject = false;
  bool mismatch = false;
  String? rejectRemoval;
  RejectingPreferences(super.values);
  @override
  Future<bool> writeString(String key, String value) async {
    if (reject) return false;
    if (mismatch) return true;
    return super.writeString(key, value);
  }

  @override
  Future<bool> removeAcknowledged(String key) async =>
      key == rejectRemoval ? false : super.removeAcknowledged(key);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  late EncryptedAppStore db;
  AppStoreStage? failure;
  final key = Uint8List.fromList(List.generate(32, (i) => i + 37));
  setUp(() async {
    failure = null;
    directory = await Directory.systemTemp.createTemp('hydrion-profile-test-');
    db = await EncryptedAppStore.open(
        path: '${directory.path}/app.db',
        key: key,
        failureInjector: (stage) async {
          if (stage == failure) throw StateError('synthetic failure');
        });
  });
  tearDown(() async {
    await db.close();
    await directory.delete(recursive: true);
  });
  Map<String, dynamic> source([String? photo]) => const UserSettings(
          locale: ui.Locale('fr'),
          nickname: 'SYNTHETIC-PROFILE',
          age: 37,
          sex: HydrionSex.intersex,
          dailyGoalMl: 2700,
          baselineDailyGoalMl: 2700,
          nonLocalProviderConsentGranted: true,
          volumeUnit: HydrionVolumeUnit.ounces,
          containerSizeMl: 650)
      .copyWith(profilePhotoBase64: photo)
      .toJson();

  test('migration strips classified fields and preserves every ordinary field',
      () async {
    final original = source(base64Encode(await syntheticPng(720, 720)));
    final prefs = MemoryHydrionStore(
        {SettingsProtection.storageKey: jsonEncode(original)});
    final repo = await UserSettingsRepository.load(prefs, protectedStore: db);
    expect(repo.isKnown, isTrue);
    expect(repo.settings.nickname, 'SYNTHETIC-PROFILE');
    final sanitized =
        jsonDecode(prefs.snapshot[SettingsProtection.storageKey]!) as Map;
    for (final field in ProtectedProfileFields.fieldNames) {
      expect(sanitized.containsKey(field), isFalse, reason: field);
    }
    expect(sanitized.containsKey('profilePhotoBase64'), isFalse);
    for (final field in SettingsProtection.ordinaryFields) {
      expect(sanitized[field], original[field], reason: field);
    }
    expect((await db.readSettings()).record!.photo!.bytes,
        base64Decode(original['profilePhotoBase64']));
    final reloaded =
        await UserSettingsRepository.load(prefs, protectedStore: db);
    expect(reloaded.settings.toJson(), repo.settings.toJson());
    expect((await db.readSettings()).record!.revision, 1);
  });

  for (final reconstruct in [false, true]) {
    test('H1 provisional photo deletion recovers: reconstruct=$reconstruct',
        () async {
      final original = source(base64Encode(await syntheticPng(20, 20)));
      final prefs = MemoryHydrionStore(
          {SettingsProtection.storageKey: jsonEncode(original)});
      failure = AppStoreStage.beforeVerification;
      var repo = await UserSettingsRepository.load(prefs, protectedStore: db);
      expect((await db.readSettings()).record!.phase,
          ContextRecordPhase.provisional);
      failure = AppStoreStage.recordWritten;
      await expectLater(
          repo.clearProfilePhoto(), throwsA(isA<SettingsProtectionFailure>()));
      expect(prefs.snapshot[SettingsProtection.photoDeletionKey], 'pending');
      await repo.retryProtection();
      expect(repo.isKnown, isFalse);
      expect(repo.settings.profilePhotoBase64, isNull);
      expect((await db.readSettings()).record!.phase,
          ContextRecordPhase.provisional);
      failure = null;
      if (reconstruct) {
        repo = await UserSettingsRepository.load(prefs, protectedStore: db);
      } else {
        await repo.retryProtection();
      }
      expect(repo.protectionStatus, SettingsProtectionStatus.ready);
      expect(repo.settings.nickname, 'SYNTHETIC-PROFILE');
      expect((await db.readSettings()).record!.photo, isNull);
      expect(prefs.snapshot.containsKey(SettingsProtection.photoDeletionKey),
          isFalse);
      final revision = (await db.readSettings()).record!.revision;
      await repo.retryProtection();
      expect((await db.readSettings()).record!.revision, revision);
    });
  }

  test('H2 reset retires old photo deletion before accepting a new photo',
      () async {
    final prefs = MemoryHydrionStore();
    var repo = await UserSettingsRepository.load(prefs, protectedStore: db);
    await repo.setProfilePhotoBytes(await syntheticPng(10, 10));
    failure = AppStoreStage.recordWritten;
    await expectLater(
        repo.clearProfilePhoto(), throwsA(isA<SettingsProtectionFailure>()));
    failure = null;
    await repo.resetLocalProfile();
    final newPhoto = await syntheticPng(30, 30);
    expect(await repo.setProfilePhotoBytes(newPhoto), isTrue);
    await repo.retryProtection();
    repo = await UserSettingsRepository.load(prefs, protectedStore: db);
    expect((await db.readSettings()).record!.photo?.bytes, newPhoto);
    expect(prefs.snapshot.containsKey(SettingsProtection.photoDeletionKey),
        isFalse);
    expect(
        prefs.snapshot.values.join(), isNot(contains(base64Encode(newPhoto))));
  });

  test('M1 migrated ordinary edit survives protected unavailability', () async {
    final prefs = MemoryHydrionStore();
    await UserSettingsRepository.load(prefs, protectedStore: db);
    final before = (await db.readSettings()).record!;
    final repo = await UserSettingsRepository.load(prefs,
        protectedStore: const UnavailableProtectedAppStore(
            ProtectedReadStatus.unavailable));
    await repo.setThemePreference(HydrionThemePreference.dark);
    expect(repo.settings.themePreference, HydrionThemePreference.dark);
    expect(repo.isKnown, isFalse);
    expect((await db.readSettings()).record!.equivalentTo(before), isTrue);
    expect(
        jsonDecode(prefs.snapshot[SettingsProtection.storageKey]!)[
            '_protectedRevision'],
        before.revision);
  });

  for (final phase in [
    'legacy',
    'provisional',
    'cleanup',
    'protected',
    'absent'
  ]) {
    test('H1 deletion precedence from $phase', () async {
      final original = source(base64Encode(await syntheticPng(20, 20)));
      final prefs = RejectingPreferences(
          {SettingsProtection.storageKey: jsonEncode(original)});
      if (phase == 'legacy') failure = AppStoreStage.recordWritten;
      if (phase == 'provisional') failure = AppStoreStage.beforeVerification;
      if (phase == 'cleanup') prefs.reject = true;
      final repo = await UserSettingsRepository.load(prefs, protectedStore: db);
      failure = null;
      prefs.reject = false;
      if (phase == 'absent') await repo.clearProfilePhoto();
      await repo.clearProfilePhoto();
      expect(repo.protectionStatus, SettingsProtectionStatus.ready);
      final record = (await db.readSettings()).record!;
      expect(record.phase, ContextRecordPhase.active);
      expect(record.photo, isNull);
      expect(record.profile.encode(),
          SettingsProtection.profileFrom(original).encode());
      expect(prefs.snapshot.containsKey(SettingsProtection.photoDeletionKey),
          isFalse);
      expect(
          prefs.snapshot.values.join(), isNot(contains('profilePhotoBase64')));
      final restarted =
          await UserSettingsRepository.load(prefs, protectedStore: db);
      expect(restarted.settings.profilePhotoBase64, isNull);
      expect(restarted.settings.nickname, 'SYNTHETIC-PROFILE');
    });
  }

  test('H1 authorized photo deletion still quarantines non-photo conflict',
      () async {
    final original = source(base64Encode(await syntheticPng(20, 20)));
    final prefs = MemoryHydrionStore(
        {SettingsProtection.storageKey: jsonEncode(original)});
    failure = AppStoreStage.beforeVerification;
    final repo = await UserSettingsRepository.load(prefs, protectedStore: db);
    final before = (await db.readSettings()).record!;
    failure = null;
    original['nickname'] = 'CONFLICT';
    final raw = jsonEncode(original);
    await prefs.writeString(SettingsProtection.storageKey, raw);
    await expectLater(
        repo.clearProfilePhoto(), throwsA(isA<SettingsProtectionFailure>()));
    await repo.retryProtection();
    expect(repo.protectionStatus, SettingsProtectionStatus.corrupt);
    expect((await db.readSettings()).record!.equivalentTo(before), isTrue);
    expect(prefs.snapshot[SettingsProtection.storageKey], raw);
    expect(prefs.snapshot[SettingsProtection.photoDeletionKey], 'pending');
  });

  for (final keyToReject in [
    SettingsProtection.photoDeletionKey,
    SettingsProtection.resetKey
  ]) {
    test(
        'H2 reset cannot complete with unacknowledged intent removal: $keyToReject',
        () async {
      final prefs = RejectingPreferences({});
      var repo = await UserSettingsRepository.load(prefs, protectedStore: db);
      await repo.setProfilePhotoBytes(await syntheticPng(10, 10));
      failure = AppStoreStage.recordWritten;
      await expectLater(
          repo.clearProfilePhoto(), throwsA(isA<SettingsProtectionFailure>()));
      failure = null;
      prefs.rejectRemoval = keyToReject;
      await expectLater(
          repo.resetLocalProfile(), throwsA(isA<SettingsProtectionFailure>()));
      expect(repo.protectionStatus, SettingsProtectionStatus.deletionPending);
      expect(prefs.snapshot[SettingsProtection.resetKey], 'keepLegal');
      final replacement = await syntheticPng(30, 30);
      expect(await repo.setProfilePhotoBytes(replacement), isFalse);
      prefs.rejectRemoval = null;
      repo = await UserSettingsRepository.load(prefs, protectedStore: db);
      expect(repo.protectionStatus, SettingsProtectionStatus.ready);
      expect(prefs.snapshot.containsKey(SettingsProtection.resetKey), isFalse);
      expect(prefs.snapshot.containsKey(SettingsProtection.photoDeletionKey),
          isFalse);
      expect(await repo.setProfilePhotoBytes(replacement), isTrue);
      await repo.retryProtection();
      expect((await db.readSettings()).record!.photo!.bytes, replacement);
    });
  }

  test('M1 all ordinary setters preserve unavailable protected generation',
      () async {
    final prefs = MemoryHydrionStore();
    await UserSettingsRepository.load(prefs, protectedStore: db);
    final before = (await db.readSettings()).record!;
    final repo = await UserSettingsRepository.load(prefs,
        protectedStore: const UnavailableProtectedAppStore(
            ProtectedReadStatus.unavailable));
    await repo.setLocale(const ui.Locale('fr', 'CA'));
    expect(await repo.setAvatarId('superhappy_shark'), isTrue);
    await repo.setVolumeUnit(HydrionVolumeUnit.ounces);
    expect(await repo.setContainerSizeMl(650), isTrue);
    await repo.clearContainerSize();
    await repo.setReusableContainerEnabled(true);
    await repo.setThemePreference(HydrionThemePreference.dark);
    expect(await repo.setProfile(nickname: 'BLOCKED'), isFalse);
    expect(await repo.setDailyGoalMl(2900), isFalse);
    await expectLater(repo.setNonLocalProviderConsentGranted(true),
        throwsA(isA<SettingsProtectionFailure>()));
    final facade = SettingsProtection(
        prefs,
        const UnavailableProtectedAppStore(ProtectedReadStatus.unavailable),
        (value) => UserSettings.fromJson(value).toJson());
    await facade.reload();
    await expectLater(
        facade.save({
          ...repo.settings.toJson(),
          'nickname': 'BLOCKED',
          'themePreference': 'light'
        }),
        throwsA(isA<SettingsProtectionFailure>()));
    await expectLater(
        facade.save({...repo.settings.toJson(), 'nickname': 'BLOCKED'},
            ordinaryOnly: true),
        throwsA(isA<SettingsProtectionFailure>()));
    final restarted =
        await UserSettingsRepository.load(prefs, protectedStore: db);
    expect(restarted.settings.locale, const ui.Locale('fr', 'CA'));
    expect(restarted.settings.avatarId, 'superhappy_shark');
    expect(restarted.settings.volumeUnit, HydrionVolumeUnit.ounces);
    expect(restarted.settings.containerSizeMl, 650);
    expect(restarted.settings.reusableContainerEnabled, isTrue);
    expect(restarted.settings.themePreference, HydrionThemePreference.dark);
    expect((await db.readSettings()).record!.equivalentTo(before), isTrue);
    expect(
        jsonDecode(prefs.snapshot[SettingsProtection.storageKey]!)[
            '_protectedRevision'],
        before.revision);
  });

  test('M1 ordinary rejection preserves both stores and recovers', () async {
    final prefs = RejectingPreferences({});
    await UserSettingsRepository.load(prefs, protectedStore: db);
    final before = Map.of(prefs.snapshot);
    final repo = await UserSettingsRepository.load(prefs,
        protectedStore: const UnavailableProtectedAppStore(
            ProtectedReadStatus.unavailable));
    prefs.reject = true;
    await expectLater(repo.setThemePreference(HydrionThemePreference.dark),
        throwsA(isA<SettingsProtectionFailure>()));
    expect(await repo.setAvatarId('superhappy_shark'), isFalse);
    expect(prefs.snapshot, before);
    prefs.reject = false;
    await repo.setThemePreference(HydrionThemePreference.dark);
    expect(repo.settings.themePreference, HydrionThemePreference.dark);
  });

  for (final stage in [
    AppStoreStage.recordWritten,
    AppStoreStage.beforeVerification
  ]) {
    test('migration preserves exact source on ${stage.name}', () async {
      final raw = jsonEncode(source());
      final prefs = MemoryHydrionStore({SettingsProtection.storageKey: raw});
      failure = stage;
      final repo = await UserSettingsRepository.load(prefs, protectedStore: db);
      expect(repo.isKnown, isFalse);
      expect(prefs.snapshot[SettingsProtection.storageKey], raw);
      failure = null;
      await repo.retryProtection();
      expect(repo.isKnown, isTrue);
    });
  }

  for (final mismatch in [false, true]) {
    test(
        'cleanup ${mismatch ? 'verification' : 'acknowledgement'} failure is restartable',
        () async {
      final raw = jsonEncode(source());
      final prefs = RejectingPreferences({SettingsProtection.storageKey: raw})
        ..reject = !mismatch
        ..mismatch = mismatch;
      final repo = await UserSettingsRepository.load(prefs, protectedStore: db);
      expect(repo.protectionStatus, SettingsProtectionStatus.cleanupPending);
      expect(prefs.snapshot[SettingsProtection.storageKey], raw);
      prefs.reject = false;
      prefs.mismatch = false;
      final restarted =
          await UserSettingsRepository.load(prefs, protectedStore: db);
      expect(restarted.protectionStatus, SettingsProtectionStatus.ready);
      expect(restarted.settings.nickname, 'SYNTHETIC-PROFILE');
    });
  }

  for (final dimensions in [(720, 720), (721, 720), (720, 721)]) {
    test('hard photo dimensions ${dimensions.$1} by ${dimensions.$2}',
        () async {
      final bytes = await syntheticPng(dimensions.$1, dimensions.$2);
      if (dimensions == (720, 720)) {
        final photo = await ValidatedProfilePhoto.fromBytes(bytes);
        expect(photo.width, 720);
        expect(photo.height, 720);
      } else {
        await expectLater(ValidatedProfilePhoto.fromBytes(bytes),
            throwsA(isA<InvalidProfilePhoto>()));
      }
    });
  }

  for (final size in [1200000, 1200001]) {
    test('decoded payload boundary $size', () async {
      final bytes = paddedPng(await syntheticPng(720, 720), size);
      if (size == 1200000) {
        expect(
            (await ValidatedProfilePhoto.fromLegacy(base64Encode(bytes)))
                .bytes
                .length,
            size);
      } else {
        await expectLater(ValidatedProfilePhoto.fromBytes(bytes),
            throwsA(isA<InvalidProfilePhoto>()));
      }
    });
  }

  for (final invalid in [
    'A',
    'AAAA====',
    base64Encode([1, 2, 3])
  ]) {
    test(
        'invalid legacy is retained and explicitly reselectable: ${invalid.length}',
        () async {
      final raw = jsonEncode(source(invalid));
      final prefs = MemoryHydrionStore({SettingsProtection.storageKey: raw});
      final repo = await UserSettingsRepository.load(prefs, protectedStore: db);
      expect(
          repo.protectionStatus, SettingsProtectionStatus.invalidLegacyPhoto);
      expect(prefs.snapshot[SettingsProtection.storageKey], raw);
      expect((await db.readSettings()).status, ProtectedReadStatus.absent);
      expect(
          await repo.setProfilePhotoBytes(await syntheticPng(20, 20)), isTrue);
      expect(repo.protectionStatus, SettingsProtectionStatus.ready);
    });
  }

  test('protected-only changes never write photo text into preferences',
      () async {
    final prefs = MemoryHydrionStore();
    final repo = await UserSettingsRepository.load(prefs, protectedStore: db);
    expect(await repo.setProfile(nickname: 'OTHER-SYNTHETIC', age: 42), isTrue);
    expect(await repo.setProfilePhotoBytes(await syntheticPng(20, 20)), isTrue);
    final serialized = prefs.snapshot.values.join();
    expect(serialized, isNot(contains('OTHER-SYNTHETIC')));
    expect(serialized, isNot(contains('profilePhotoBase64')));
    await repo.clearProfilePhoto();
    expect((await db.readSettings()).record!.photo, isNull);
    expect(prefs.snapshot.containsKey(SettingsProtection.photoDeletionKey),
        isFalse);
  });

  test('photo deletion failure preserves intent and retries after restart',
      () async {
    final prefs = MemoryHydrionStore();
    final repo = await UserSettingsRepository.load(prefs, protectedStore: db);
    await repo.setProfilePhotoBytes(await syntheticPng(20, 20));
    failure = AppStoreStage.recordWritten;
    await expectLater(
        repo.clearProfilePhoto(), throwsA(isA<SettingsProtectionFailure>()));
    expect(prefs.snapshot[SettingsProtection.photoDeletionKey], 'pending');
    failure = null;
    final restarted =
        await UserSettingsRepository.load(prefs, protectedStore: db);
    expect(restarted.protectionStatus, SettingsProtectionStatus.ready);
    expect(restarted.settings.profilePhotoBase64, isNull);
  });

  test('unsupported store preserves source without granting consent', () async {
    final raw = jsonEncode(source());
    final prefs = MemoryHydrionStore({SettingsProtection.storageKey: raw});
    final repo = await UserSettingsRepository.load(prefs,
        protectedStore: const UnavailableProtectedAppStore());
    expect(repo.isKnown, isFalse);
    expect(repo.settings.nonLocalProviderConsentGranted, isFalse);
    expect(await repo.setProfile(nickname: 'MUST-NOT-SAVE'), isFalse);
    expect(prefs.snapshot[SettingsProtection.storageKey], raw);
  });

  test(
      'failed write is not published and queued newer mutation cannot restore old snapshot',
      () async {
    final prefs = MemoryHydrionStore();
    final repo = await UserSettingsRepository.load(prefs, protectedStore: db);
    failure = AppStoreStage.beforeVerification;
    expect(await repo.setDailyGoalMl(2800), isFalse);
    expect(repo.isKnown, isFalse);
    failure = null;
    await repo.retryProtection();
    expect(repo.settings.dailyGoalMl, 2800);
    expect(await repo.setDailyGoalMl(2900), isTrue);
    expect((await db.readSettings()).record!.profile.dailyGoalMl, 2900);
  });

  test('every settings serializer field is explicitly classified', () {
    expect(source().keys.toSet(), {
      ...SettingsProtection.ordinaryFields,
      ...ProtectedProfileFields.fieldNames,
      'profilePhotoBase64',
    });
  });

  for (final stage in [
    AppStoreStage.recordWritten,
    AppStoreStage.beforeVerification
  ]) {
    test('new photo ${stage.name} failure never creates a plaintext shadow',
        () async {
      final prefs = MemoryHydrionStore();
      final repo = await UserSettingsRepository.load(prefs, protectedStore: db);
      final previous = await syntheticPng(10, 10);
      final candidate = await syntheticPng(20, 20);
      expect(await repo.setProfilePhotoBytes(previous), isTrue);
      failure = stage;
      expect(await repo.setProfilePhotoBytes(candidate), isFalse);
      expect(repo.isKnown, isFalse);
      expect(prefs.snapshot.values.join(),
          isNot(contains(base64Encode(candidate))));
      failure = null;
      await repo.retryProtection();
      expect(base64Decode(repo.settings.profilePhotoBase64!),
          stage == AppStoreStage.recordWritten ? previous : candidate);
    });
  }

  test(
      'unknown profile cannot report a no-op target or consent save as successful',
      () async {
    final repo = await UserSettingsRepository.load(MemoryHydrionStore(),
        protectedStore: const UnavailableProtectedAppStore());
    expect(await repo.setDailyGoalMl(2200, markManualEdit: false), isFalse);
    await expectLater(repo.setNonLocalProviderConsentGranted(false),
        throwsA(isA<SettingsProtectionFailure>()));
  });

  test(
      'legacy photo cleanup failure retains source until protected-only restart',
      () async {
    final photo = base64Encode(await syntheticPng(40, 40));
    final raw = jsonEncode(source(photo));
    final prefs = RejectingPreferences({SettingsProtection.storageKey: raw})
      ..reject = true;
    final repo = await UserSettingsRepository.load(prefs, protectedStore: db);
    expect(repo.protectionStatus, SettingsProtectionStatus.cleanupPending);
    expect(repo.settings.profilePhotoBase64, photo);
    expect(prefs.snapshot[SettingsProtection.storageKey], raw);
    prefs.reject = false;
    await db.close();
    db = await EncryptedAppStore.open(
        path: '${directory.path}/app.db', key: key);
    final restarted =
        await UserSettingsRepository.load(prefs, protectedStore: db);
    expect(restarted.settings.profilePhotoBase64, photo);
    expect(prefs.snapshot.values.join(), isNot(contains(photo)));
  });

  for (final shape in [(721, 20), (20, 721), (720, 720)]) {
    test('nonconforming legacy ${shape.$1}x${shape.$2} preserves exact source',
        () async {
      var bytes = await syntheticPng(shape.$1, shape.$2);
      if (shape == (720, 720)) bytes = paddedPng(bytes, 1200001);
      final raw = jsonEncode(source(base64Encode(bytes)));
      final prefs = MemoryHydrionStore({SettingsProtection.storageKey: raw});
      final repo = await UserSettingsRepository.load(prefs, protectedStore: db);
      expect(
          repo.protectionStatus, SettingsProtectionStatus.invalidLegacyPhoto);
      expect(prefs.snapshot[SettingsProtection.storageKey], raw);
      expect((await db.readSettings()).status, ProtectedReadStatus.absent);
    });
  }

  test(
      'exact photo byte cap migrates as BLOB and survives actual database reopen',
      () async {
    final bytes = paddedPng(await syntheticPng(720, 720), 1200000);
    final prefs = MemoryHydrionStore({
      SettingsProtection.storageKey: jsonEncode(source(base64Encode(bytes)))
    });
    final repo = await UserSettingsRepository.load(prefs, protectedStore: db);
    expect(repo.isKnown, isTrue);
    await db.close();
    db = await EncryptedAppStore.open(
        path: '${directory.path}/app.db', key: key);
    expect((await db.readSettings()).record!.photo!.bytes, bytes);
    final raw = sqlite.sqlite3.open('${directory.path}/app.db');
    final hex =
        key.map((value) => value.toRadixString(16).padLeft(2, '0')).join();
    raw.execute('PRAGMA key = "x\'$hex\'"');
    expect(
        raw
            .select(
                'SELECT typeof(photo) AS kind, length(photo) AS size FROM settings_profile')
            .single,
        containsPair('kind', 'blob'));
    expect(
        raw
            .select('SELECT length(photo) AS size FROM settings_profile')
            .single['size'],
        1200000);
    raw.close();
    expect(prefs.snapshot.values.join(), isNot(contains(base64Encode(bytes))));
  });

  for (final future in [false, true]) {
    test('corrupt or future protected record stays quarantined: future=$future',
        () async {
      final prefs = MemoryHydrionStore();
      await UserSettingsRepository.load(prefs, protectedStore: db);
      await db.close();
      final raw = sqlite.sqlite3.open('${directory.path}/app.db');
      final hex =
          key.map((value) => value.toRadixString(16).padLeft(2, '0')).join();
      raw.execute('PRAGMA key = "x\'$hex\'"');
      if (future) {
        raw.execute('UPDATE settings_profile SET schema_version = 99');
      } else {
        raw.execute("UPDATE settings_profile SET profile = '{}'");
      }
      raw.close();
      db = await EncryptedAppStore.open(
          path: '${directory.path}/app.db', key: key);
      final before = Map.of(prefs.snapshot);
      final repo = await UserSettingsRepository.load(prefs, protectedStore: db);
      expect(
          repo.protectionStatus,
          future
              ? SettingsProtectionStatus.unsupported
              : SettingsProtectionStatus.corrupt);
      expect(await repo.setProfile(nickname: 'MUST-NOT-OVERWRITE'), isFalse);
      expect(prefs.snapshot, before);
    });
  }

  test('ordinary edits never modify protected revision', () async {
    final prefs = MemoryHydrionStore();
    final repo = await UserSettingsRepository.load(prefs, protectedStore: db);
    final before = (await db.readSettings()).record!;
    await repo.setThemePreference(HydrionThemePreference.dark);
    await repo.setLocale(const ui.Locale('es'));
    await repo.setVolumeUnit(HydrionVolumeUnit.ounces);
    expect((await db.readSettings()).record!.equivalentTo(before), isTrue);
  });

  test('schema-one pilot upgrades without changing its accepted record',
      () async {
    final context = ProtectedContextRecord(
        revision: 7, phase: ContextRecordPhase.active, contexts: const []);
    expect(await db.writeDailyContext(context), ProtectedWriteStatus.committed);
    await db.close();
    final raw = sqlite.sqlite3.open('${directory.path}/app.db');
    final hex =
        key.map((value) => value.toRadixString(16).padLeft(2, '0')).join();
    raw.execute('PRAGMA key = "x\'$hex\'"');
    raw.execute('DROP TABLE settings_profile');
    raw.execute('PRAGMA user_version = 1');
    raw.close();
    db = await EncryptedAppStore.open(
        path: '${directory.path}/app.db', key: key);
    expect((await db.readDailyContext()).record!.revision, 7);
    expect(
        (await db.readDailyContext()).record!.phase, ContextRecordPhase.active);
    expect((await db.readSettings()).status, ProtectedReadStatus.absent);
    final repo = await UserSettingsRepository.load(MemoryHydrionStore(),
        protectedStore: db);
    expect(repo.isKnown, isTrue);
    expect((await db.readDailyContext()).record!.revision, 7);
  });

  for (final conflict in [false, true]) {
    test('provisional restart verifies matching source: conflict=$conflict',
        () async {
      final original = source();
      final profile = SettingsProtection.profileFrom(original);
      expect(
          await db.writeSettings(ProtectedSettingsRecord(
              revision: 1,
              phase: ContextRecordPhase.provisional,
              profile: profile)),
          ProtectedWriteStatus.committed);
      if (conflict) original['nickname'] = 'CONFLICT';
      final text = jsonEncode(original);
      final prefs = MemoryHydrionStore({SettingsProtection.storageKey: text});
      final repo = await UserSettingsRepository.load(prefs, protectedStore: db);
      expect(repo.isKnown, !conflict);
      if (conflict) {
        expect(repo.protectionStatus, SettingsProtectionStatus.corrupt);
        expect(prefs.snapshot[SettingsProtection.storageKey], text);
        expect((await db.readSettings()).record!.phase,
            ContextRecordPhase.provisional);
      } else {
        expect(
            (await db.readSettings()).record!.phase, ContextRecordPhase.active);
        expect(repo.settings.nickname, profile.nickname);
      }
    });
  }

  test('ordinary edits remain possible while protected data is unavailable',
      () async {
    final original = source();
    final prefs = MemoryHydrionStore(
        {SettingsProtection.storageKey: jsonEncode(original)});
    final repo = await UserSettingsRepository.load(prefs,
        protectedStore: const UnavailableProtectedAppStore(
            ProtectedReadStatus.unavailable));
    expect(repo.protectionStatus, SettingsProtectionStatus.unavailable);
    await repo.setThemePreference(HydrionThemePreference.dark);
    final saved =
        jsonDecode(prefs.snapshot[SettingsProtection.storageKey]!) as Map;
    for (final key in ProtectedProfileFields.fieldNames) {
      expect(saved[key], original[key]);
    }
    expect(saved['themePreference'], 'dark');
    expect(repo.isKnown, isFalse);
  });

  test('ahead-of-protected generation is not resolved by location preference',
      () async {
    final prefs = MemoryHydrionStore();
    await UserSettingsRepository.load(prefs, protectedStore: db);
    final values = jsonDecode(prefs.snapshot[SettingsProtection.storageKey]!)
        as Map<String, dynamic>;
    values['_protectedRevision'] = 99;
    final conflicting = jsonEncode(values);
    await prefs.writeString(SettingsProtection.storageKey, conflicting);
    final repo = await UserSettingsRepository.load(prefs, protectedStore: db);
    expect(repo.protectionStatus, SettingsProtectionStatus.corrupt);
    expect(prefs.snapshot[SettingsProtection.storageKey], conflicting);
  });

  test(
      'mixed update failure retains committed profile and prior ordinary configuration',
      () async {
    final prefs = RejectingPreferences(
        {SettingsProtection.storageKey: jsonEncode(source())});
    final facade = SettingsProtection(
        prefs, db, (value) => UserSettings.fromJson(value).toJson());
    await facade.reload();
    prefs.reject = true;
    await expectLater(
        facade.save({
          ...source(),
          'nickname': 'NEW-PROTECTED',
          'volumeUnit': 'milliliters'
        }),
        throwsA(isA<SettingsProtectionFailure>()));
    expect(facade.record!.profile.nickname, 'NEW-PROTECTED');
    expect(facade.ordinary['volumeUnit'], 'ounces');
    expect(facade.status, SettingsProtectionStatus.partialFailure);
    prefs.reject = false;
    await facade.reload();
    expect(facade.record!.profile.nickname, 'NEW-PROTECTED');
    expect(facade.ordinary['volumeUnit'], 'ounces');
  });

  test(
      'reset failure retains intent, clears photo on retry and preserves legal versions',
      () async {
    final prefs = MemoryHydrionStore();
    final repo = await UserSettingsRepository.load(prefs, protectedStore: db);
    await repo.completeOnboardingWithLegalReview(
        reviewedAt: DateTime(2026, 9, 29));
    final terms = repo.settings.acceptedTermsVersion;
    await repo.setProfilePhotoBytes(await syntheticPng(10, 10));
    failure = AppStoreStage.recordWritten;
    await expectLater(
        repo.resetLocalProfile(), throwsA(isA<SettingsProtectionFailure>()));
    expect(prefs.snapshot[SettingsProtection.resetKey], 'keepLegal');
    failure = null;
    final restarted =
        await UserSettingsRepository.load(prefs, protectedStore: db);
    expect(restarted.settings.profilePhotoBase64, isNull);
    expect(restarted.settings.acceptedTermsVersion, terms);
    expect(restarted.settings.onboardingCompleted, isFalse);
    expect(prefs.snapshot.containsKey(SettingsProtection.resetKey), isFalse);
  });
}
