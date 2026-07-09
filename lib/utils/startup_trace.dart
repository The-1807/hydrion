import 'package:flutter/foundation.dart';

class HydrionStartupTrace {
  static const buildCommit = String.fromEnvironment(
    'HYDRION_BUILD_COMMIT',
    defaultValue: 'unknown',
  );
  static const buildDirty = String.fromEnvironment(
    'HYDRION_BUILD_DIRTY',
    defaultValue: 'unknown',
  );
  static const buildSource = String.fromEnvironment(
    'HYDRION_BUILD_SOURCE',
    defaultValue: 'local',
  );

  static void log(String event, {Map<String, Object?> data = const {}}) {
    if (kReleaseMode) {
      return;
    }
    const mode = kDebugMode
        ? 'debug'
        : kProfileMode
            ? 'profile'
            : 'unknown';
    final fields = <String, Object?>{
      'mode': mode,
      'commit': buildCommit,
      'dirty': buildDirty,
      'source': buildSource,
      ...data,
    };
    final payload = fields.entries
        .map((entry) => '${entry.key}=${entry.value ?? 'null'}')
        .join(' ');
    debugPrint('HYDRION_STARTUP $event $payload');
  }
}
