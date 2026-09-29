import 'dart:convert';

import '../services/validated_profile_photo.dart';
import '../storage/local_store.dart';
import '../storage/protected_app_store.dart';
import '../storage/protected_settings_record.dart';

enum SettingsProtectionStatus {
  ready,
  cleanupPending,
  unavailable,
  unsupported,
  corrupt,
  invalidLegacyPhoto,
  deletionPending,
  partialFailure,
}

final class SettingsProtectionFailure implements Exception {
  const SettingsProtectionFailure();
  @override
  String toString() => 'SettingsProtectionFailure';
}

/// Owns only the M3 split. Calls are serialized by UserSettingsRepository.
final class SettingsProtection {
  static const storageKey = 'hydrion.user_settings.v1';
  static const photoDeletionKey = 'hydrion.profile_photo.deletion.v1';
  static const resetKey = 'hydrion.settings_profile.reset.v1';
  static const ordinaryFields = {
    'languageCode',
    'countryCode',
    'reusableContainerEnabled',
    'avatarId',
    'volumeUnit',
    'themePreference',
    'containerSizeMl',
  };
  final HydrionLocalStore legacy;
  ProtectedSettingsStore? protected;
  final Map<String, dynamic> Function(Map<String, dynamic>) normalize;
  SettingsProtectionStatus status = SettingsProtectionStatus.unavailable;
  ProtectedSettingsRecord? record;
  Map<String, dynamic> ordinary = {};

  SettingsProtection(this.legacy, this.protected, this.normalize);

  bool get isKnown =>
      record != null &&
      (status == SettingsProtectionStatus.ready ||
          status == SettingsProtectionStatus.cleanupPending ||
          status == SettingsProtectionStatus.partialFailure);

  static Map<String, dynamic> ordinaryFrom(Map<String, dynamic> values) => {
        for (final key in ordinaryFields)
          if (values.containsKey(key)) key: values[key]
      };

  static ProtectedProfileFields profileFrom(Map<String, dynamic> values) =>
      ProtectedProfileFields.fromJson({
        for (final key in ProtectedProfileFields.fieldNames) key: values[key]
      });

  Future<Map<String, dynamic>> _legacy() async {
    final raw = await legacy.readString(storageKey);
    if (raw == null) return {};
    final value = jsonDecode(raw);
    if (value is! Map<String, dynamic> ||
        (value['schemaVersion'] != null && value['schemaVersion'] != 1)) {
      throw const FormatException('Unsupported settings source');
    }
    // There is no existing allowlist for unknown ordinary metadata. Preserve
    // unclassified input intact rather than guessing that arbitrary data is D.
    final allowed = {
      ...ordinaryFields,
      ...ProtectedProfileFields.fieldNames,
      'profilePhotoBase64',
      'schemaVersion',
      '_protectedRevision'
    };
    if (value.keys.any((key) => !allowed.contains(key))) {
      throw const FormatException('Unclassified settings source');
    }
    return value;
  }

  Future<void> reload(
      {ValidatedProfilePhoto? replacement, bool replacePhoto = false}) async {
    status = SettingsProtectionStatus.unavailable;
    record = null;
    try {
      final source = await _legacy();
      ordinary = ordinaryFrom(normalize(source));
      if (protected == null) {
        status = SettingsProtectionStatus.unsupported;
        return;
      }
      final read = await protected!.readSettings();
      if (read.status != ProtectedReadStatus.found &&
          read.status != ProtectedReadStatus.absent) {
        status = switch (read.status) {
          ProtectedReadStatus.corrupt => SettingsProtectionStatus.corrupt,
          ProtectedReadStatus.unsupported =>
            SettingsProtectionStatus.unsupported,
          _ => SettingsProtectionStatus.unavailable,
        };
        return;
      }
      final intent = await legacy.readString(photoDeletionKey);
      if (intent != null && intent != 'pending') {
        status = SettingsProtectionStatus.corrupt;
        return;
      }
      final old = read.record;
      final reference = source['_protectedRevision'];
      if (source.containsKey('_protectedRevision') && old == null) {
        return;
      }
      if (source.containsKey('_protectedRevision') &&
          (reference is! int ||
              reference < 1 ||
              (old != null && reference > old.revision))) {
        status = SettingsProtectionStatus.corrupt;
        return;
      }
      final resetIntent = await legacy.readString(resetKey);
      if (resetIntent != null) {
        if (resetIntent != 'keepLegal' && resetIntent != 'clearLegal') {
          status = SettingsProtectionStatus.corrupt;
          return;
        }
        status = SettingsProtectionStatus.deletionPending;
        final values = old?.profile.toJson() ?? normalize(source);
        final retained = <String, dynamic>{
          'languageCode': ordinary['languageCode'],
          'countryCode': ordinary['countryCode'],
          'themePreference': ordinary['themePreference'],
          'onboardingCompleted': false,
          'missionIntroductionHandled': false,
          'onboardingStep': 0,
        };
        if (resetIntent == 'keepLegal') {
          for (final key in const [
            'legalAndHealthAcknowledged',
            'acceptedTermsVersion',
            'acceptedTermsAt',
            'acknowledgedHealthDisclaimerVersion',
            'acknowledgedHealthDisclaimerAt',
            'privacyPolicyVersionShown',
            'privacyPolicyShownAt'
          ]) {
            retained[key] = values[key];
          }
        }
        final target = profileFrom(normalize(retained));
        final candidate = ProtectedSettingsRecord(
            revision: (old?.revision ?? 0) + 1,
            phase: ContextRecordPhase.active,
            profile: target);
        if (await protected!.writeSettings(candidate) !=
            ProtectedWriteStatus.committed) {
          return;
        }
        record = candidate;
        final resetOrdinary = ordinaryFrom(normalize(retained));
        if (!await cleanup(ordinaryOverride: resetOrdinary) ||
            !await _removeIntent(resetKey)) {
          status = SettingsProtectionStatus.deletionPending;
          return;
        }
        ordinary = resetOrdinary;
        return;
      }
      if (old != null && old.phase != ContextRecordPhase.provisional) {
        if (profileFrom(normalize({...ordinary, ...old.profile.toJson()}))
                .encode() !=
            old.profile.encode()) {
          status = SettingsProtectionStatus.corrupt;
          return;
        }
        record = old;
        if (intent != null) {
          status = SettingsProtectionStatus.deletionPending;
          await _commitPhoto(null);
          await _finishPhotoDeletion();
        } else {
          status = SettingsProtectionStatus.ready;
          await cleanup();
        }
        return;
      }
      // Sanitized preferences cannot authorize fresh defaults if the protected
      // record has disappeared. That is unavailable data, not a new profile.
      if (source.containsKey('_protectedRevision')) return;
      final normalized = normalize(source);
      final profile = profileFrom(normalized);
      for (final key in ProtectedProfileFields.fieldNames) {
        if (source.containsKey(key) &&
            jsonEncode(source[key]) != jsonEncode(normalized[key])) {
          throw const FormatException('Noncanonical legacy profile');
        }
      }
      final text = source['profilePhotoBase64'];
      final photo = intent != null
          ? null
          : replacePhoto
              ? replacement
              : text == null
                  ? null
                  : await ValidatedProfilePhoto.fromLegacy(text as String);
      final candidate = ProtectedSettingsRecord(
          revision: old?.revision ?? 1,
          phase: ContextRecordPhase.provisional,
          profile: profile,
          photo: photo);
      if (old != null && !old.equivalentTo(candidate)) {
        status = SettingsProtectionStatus.corrupt;
        return;
      }
      if (old == null &&
          await protected!.writeSettings(candidate) !=
              ProtectedWriteStatus.committed) {
        return;
      }
      final active = ProtectedSettingsRecord(
          revision: candidate.revision,
          phase: ContextRecordPhase.active,
          profile: profile,
          photo: photo);
      if (await protected!.writeSettings(active) !=
          ProtectedWriteStatus.committed) {
        return;
      }
      record = active;
      status = SettingsProtectionStatus.ready;
      await cleanup();
      if (intent != null) await _finishPhotoDeletion();
    } on InvalidProfilePhoto {
      status = SettingsProtectionStatus.invalidLegacyPhoto;
    } on FormatException {
      status = SettingsProtectionStatus.corrupt;
    } on TypeError {
      status = SettingsProtectionStatus.corrupt;
    } catch (_) {
      status = SettingsProtectionStatus.unavailable;
    }
  }

  Future<bool> cleanup({Map<String, dynamic>? ordinaryOverride}) async {
    try {
      final source = await _legacy();
      final value = <String, dynamic>{
        ...ordinaryOverride ?? ordinaryFrom(source),
        '_protectedRevision': record!.revision
      };
      final encoded = jsonEncode(value);
      if (await legacy.readString(storageKey) != encoded &&
          !await legacy.writeString(storageKey, encoded)) {
        status = SettingsProtectionStatus.cleanupPending;
        return false;
      }
      if (await legacy.readString(storageKey) != encoded) {
        status = SettingsProtectionStatus.cleanupPending;
        return false;
      }
      status = SettingsProtectionStatus.ready;
      return true;
    } catch (_) {
      status = SettingsProtectionStatus.cleanupPending;
      return false;
    }
  }

  Future<void> save(Map<String, dynamic> next) async {
    // Recheck the mixed source before any destructive stripping. Unknown
    // fields introduced since load cannot silently become disposable data.
    final currentSource = await _legacy();
    final reference = currentSource['_protectedRevision'];
    if (reference != null &&
        (reference is! int || reference > (record?.revision ?? 0))) {
      throw const SettingsProtectionFailure();
    }
    final nextOrdinary = ordinaryFrom(next);
    final nextProfile = profileFrom(next);
    if (profileFrom(normalize(next)).encode() != nextProfile.encode()) {
      throw const SettingsProtectionFailure();
    }
    if (!isKnown) {
      final deniedDefaults = profileFrom(normalize(ordinary));
      if (nextProfile.encode() != deniedDefaults.encode()) {
        throw const SettingsProtectionFailure();
      }
      // Ordinary changes may not strip or reinterpret an unverified legacy
      // source. Keep classified and forward fields byte-for-value intact.
      final source = await _legacy();
      final encoded = jsonEncode({...source, ...nextOrdinary});
      if (!await legacy.writeString(storageKey, encoded) ||
          await legacy.readString(storageKey) != encoded) {
        throw const SettingsProtectionFailure();
      }
      ordinary = nextOrdinary;
      return;
    }
    final current = record!;
    if (nextProfile.encode() != current.profile.encode()) {
      final candidate = ProtectedSettingsRecord(
          revision: current.revision + 1,
          phase: ContextRecordPhase.active,
          profile: nextProfile,
          photo: current.photo);
      if (await protected!.writeSettings(candidate) !=
          ProtectedWriteStatus.committed) {
        status = SettingsProtectionStatus.unavailable;
        throw const SettingsProtectionFailure();
      }
      record = candidate;
    }
    try {
      final encoded =
          jsonEncode({...nextOrdinary, '_protectedRevision': record!.revision});
      if (!await legacy.writeString(storageKey, encoded) ||
          await legacy.readString(storageKey) != encoded) {
        status = SettingsProtectionStatus.partialFailure;
        throw const SettingsProtectionFailure();
      }
      ordinary = nextOrdinary;
      status = SettingsProtectionStatus.ready;
    } catch (_) {
      status = SettingsProtectionStatus.partialFailure;
      throw const SettingsProtectionFailure();
    }
  }

  Future<void> _commitPhoto(ValidatedProfilePhoto? photo) async {
    final current = record!;
    final candidate = ProtectedSettingsRecord(
        revision: current.revision + 1,
        phase: ContextRecordPhase.active,
        profile: current.profile,
        photo: photo);
    if (await protected!.writeSettings(candidate) !=
        ProtectedWriteStatus.committed) {
      status = SettingsProtectionStatus.unavailable;
      throw const SettingsProtectionFailure();
    }
    record = candidate;
  }

  Future<void> setPhoto(ValidatedProfilePhoto photo) async {
    if (status == SettingsProtectionStatus.invalidLegacyPhoto) {
      await reload(replacement: photo, replacePhoto: true);
    } else {
      if (!isKnown) throw const SettingsProtectionFailure();
      await _commitPhoto(photo);
      await cleanup();
    }
    if (status != SettingsProtectionStatus.ready) {
      throw const SettingsProtectionFailure();
    }
  }

  Future<void> deletePhoto() async {
    // No payload or guessed revision in intent. Restart must resolve protected
    // truth before replaying the deletion or attempting legacy migration.
    if (!await legacy.writeString(photoDeletionKey, 'pending') ||
        await legacy.readString(photoDeletionKey) != 'pending') {
      throw const SettingsProtectionFailure();
    }
    status = SettingsProtectionStatus.deletionPending;
    await reload();
    if (status != SettingsProtectionStatus.ready) {
      throw const SettingsProtectionFailure();
    }
  }

  Future<void> reset({required bool preserveLegalAcceptance}) async {
    final intent = preserveLegalAcceptance ? 'keepLegal' : 'clearLegal';
    if (!await legacy.writeString(resetKey, intent) ||
        await legacy.readString(resetKey) != intent) {
      throw const SettingsProtectionFailure();
    }
    await reload();
    if (status != SettingsProtectionStatus.ready) {
      throw const SettingsProtectionFailure();
    }
  }

  Future<bool> _removeIntent(String key) async {
    final store = legacy;
    final removed = store is SharedPreferencesHydrionStore
        ? await store.removeAcknowledged(key)
        : store is MemoryHydrionStore
            ? await store.removeAcknowledged(key)
            : false;
    return removed && await store.readString(key) == null;
  }

  Future<void> _finishPhotoDeletion() async {
    if (record?.photo != null || !await cleanup()) {
      status = SettingsProtectionStatus.deletionPending;
      return;
    }
    final store = legacy;
    final removed = store is SharedPreferencesHydrionStore
        ? await store.removeAcknowledged(photoDeletionKey)
        : store is MemoryHydrionStore
            ? await store.removeAcknowledged(photoDeletionKey)
            : false;
    if (!removed || await legacy.readString(photoDeletionKey) != null) {
      status = SettingsProtectionStatus.deletionPending;
    }
  }
}
