class StorageRecoveryEvent {
  final String category;
  final String code;
  final String action;
  final String errorType;
  final int skippedRecords;
  final int? schemaVersion;

  const StorageRecoveryEvent({
    required this.category,
    required this.code,
    required this.action,
    this.errorType = '',
    this.skippedRecords = 0,
    this.schemaVersion,
  });

  Map<String, Object?> toSafeJson() {
    return {
      'category': category,
      'code': code,
      'action': action,
      if (errorType.isNotEmpty) 'errorType': errorType,
      if (skippedRecords > 0) 'skippedRecords': skippedRecords,
      if (schemaVersion != null) 'schemaVersion': schemaVersion,
    };
  }

  @override
  String toString() {
    return toSafeJson().entries.map((entry) {
      return '${entry.key}=${entry.value}';
    }).join(';');
  }
}

class StorageRecoveryCodes {
  static const malformedJson = 'malformed_json';
  static const wrongTopLevelType = 'wrong_top_level_type';
  static const invalidRecord = 'invalid_record';
  static const invalidValue = 'invalid_value';
  static const unsupportedSchemaVersion = 'unsupported_schema_version';
}

class StorageRecoveryActions {
  static const fallbackEmpty = 'fallback_empty';
  static const skipInvalidRecords = 'skip_invalid_records';
  static const clearCategory = 'clear_category';
  static const fallbackDefaults = 'fallback_defaults';
  static const preserveRawFallback = 'preserve_raw_fallback';
}

int? storageSchemaVersion(Object? value) {
  if (value is! Map) {
    return null;
  }
  final schemaVersion = value['schemaVersion'];
  if (schemaVersion is num && schemaVersion.isFinite) {
    return schemaVersion.round();
  }
  return null;
}
