import 'dart:convert';

import '../domain/daily_hydration_context.dart';
import 'protected_settings_record.dart';

enum ProtectedReadStatus { found, absent, unavailable, corrupt, unsupported }

enum ProtectedWriteStatus {
  committed,
  unavailable,
  failed,
  verificationFailed,
  unsupported,
}

enum ProtectedDeleteStatus {
  verifiedAbsent,
  unavailable,
  failed,
  verificationFailed,
  unsupported,
}

enum ContextRecordPhase { provisional, active, deleted }

final class ProtectedContextSchemaUnsupported implements Exception {
  const ProtectedContextSchemaUnsupported();
  @override
  String toString() => 'ProtectedContextSchemaUnsupported';
}

/// The only payload owned by the app-store pilot. No arbitrary map API.
final class ProtectedContextRecord {
  static const schemaVersion = 1;
  static const maximumDays = 14;
  final int revision;
  final ContextRecordPhase phase;
  final List<DailyHydrationContext> contexts;

  ProtectedContextRecord({
    required this.revision,
    required this.phase,
    required Iterable<DailyHydrationContext> contexts,
  }) : contexts = List.unmodifiable(contexts.toList()
          ..sort((a, b) => b.localDateKey.compareTo(a.localDateKey))) {
    if (revision < 1 ||
        this.contexts.length > maximumDays ||
        (phase == ContextRecordPhase.deleted && this.contexts.isNotEmpty) ||
        this.contexts.map((e) => e.localDateKey).toSet().length !=
            this.contexts.length) {
      throw const FormatException('Invalid protected context record');
    }
    for (final context in this.contexts) {
      _decodeContext(context.toJson());
    }
  }

  String encodePayload() => jsonEncode({
        'schemaVersion': schemaVersion,
        'contexts': contexts.map((e) => e.toJson()).toList(),
      });

  static List<DailyHydrationContext> decodePayload(String payload,
      {bool legacy = false}) {
    final Object? value;
    try {
      value = jsonDecode(payload);
    } catch (_) {
      throw const FormatException('Malformed protected context');
    }
    if (value is Map &&
        value['schemaVersion'] is int &&
        (value['schemaVersion'] as int) > schemaVersion) {
      throw const ProtectedContextSchemaUnsupported();
    }
    if (value is! Map ||
        value['schemaVersion'] != schemaVersion ||
        value.keys.any((key) => key != 'schemaVersion' && key != 'contexts') ||
        value['contexts'] is! List) {
      throw const FormatException('Unsupported protected context schema');
    }
    final records = (value['contexts'] as List).map(_decodeContext).toList()
      ..sort((a, b) => b.localDateKey.compareTo(a.localDateKey));
    if (records.map((e) => e.localDateKey).toSet().length != records.length ||
        (!legacy && records.length > maximumDays)) {
      throw const FormatException('Invalid protected context collection');
    }
    return records.take(maximumDays).toList();
  }

  static DailyHydrationContext _decodeContext(Object? value) {
    if (value is! Map) {
      throw const FormatException('Invalid protected context');
    }
    const fields = {
      'localDateKey',
      'activityIntensity',
      'activityMinutes',
      'environment',
      'sweatLevel',
      'temporaryCondition',
      'userAdjustmentMl',
      'updatedAt'
    };
    if (value.keys.any((key) => !fields.contains(key))) {
      throw const FormatException('Unknown protected context fields');
    }
    final record = DailyHydrationContext.fromJson(value);
    if (record == null ||
        value['activityMinutes'] is! int ||
        value['userAdjustmentMl'] is! int ||
        record.userAdjustmentMl != value['userAdjustmentMl'] ||
        record.activityIntensity.name != value['activityIntensity'] ||
        record.environment.name != value['environment'] ||
        record.sweatLevel.name != value['sweatLevel'] ||
        record.temporaryCondition.name != value['temporaryCondition']) {
      throw const FormatException('Invalid protected context fields');
    }
    final date = DateTime.tryParse(record.localDateKey);
    if (date == null || hydrionLocalDateKey(date) != record.localDateKey) {
      throw const FormatException('Invalid protected context date');
    }
    return record;
  }

  bool equivalentTo(ProtectedContextRecord other) =>
      revision == other.revision &&
      phase == other.phase &&
      encodePayload() == other.encodePayload();

  @override
  String toString() => 'ProtectedContextRecord(${phase.name})';
}

final class ProtectedContextRead {
  final ProtectedReadStatus status;
  final ProtectedContextRecord? record;
  const ProtectedContextRead(this.status, [this.record]);

  @override
  String toString() => 'ProtectedContextRead(${status.name})';
}

abstract interface class ProtectedAppStore {
  Future<ProtectedContextRead> readDailyContext();
  Future<ProtectedWriteStatus> writeDailyContext(ProtectedContextRecord record);
  Future<ProtectedDeleteStatus> deleteDailyContext(int revision);
  Future<void> close();
}

final class UnavailableProtectedAppStore
    implements ProtectedAppStore, ProtectedSettingsStore {
  final ProtectedReadStatus status;
  const UnavailableProtectedAppStore(
      [this.status = ProtectedReadStatus.unsupported]);

  @override
  Future<ProtectedSettingsRead> readSettings() async =>
      ProtectedSettingsRead(status);
  @override
  Future<ProtectedWriteStatus> writeSettings(
          ProtectedSettingsRecord record) async =>
      status == ProtectedReadStatus.unsupported
          ? ProtectedWriteStatus.unsupported
          : ProtectedWriteStatus.unavailable;

  @override
  Future<ProtectedContextRead> readDailyContext() async =>
      ProtectedContextRead(status);
  @override
  Future<ProtectedWriteStatus> writeDailyContext(
          ProtectedContextRecord record) async =>
      status == ProtectedReadStatus.unsupported
          ? ProtectedWriteStatus.unsupported
          : ProtectedWriteStatus.unavailable;
  @override
  Future<ProtectedDeleteStatus> deleteDailyContext(int revision) async =>
      status == ProtectedReadStatus.unsupported
          ? ProtectedDeleteStatus.unsupported
          : ProtectedDeleteStatus.unavailable;
  @override
  Future<void> close() async {}
}
