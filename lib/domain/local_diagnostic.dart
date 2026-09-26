/// Interpretation of a diagnostic, not a replacement for domain result types.
enum DiagnosticDisposition {
  success,
  degraded,
  retryableFailure,
  permanentFailure,
  unavailable,
  unsupported,
  partialCompletion,
}

/// Closed vocabulary: adding a code requires review of its disclosure and meaning.
enum LocalDiagnosticCode {
  storageReadUnavailable('storage', 'read', DiagnosticDisposition.unavailable),
  storageWriteUnverified('storage', 'write', DiagnosticDisposition.degraded),
  storageDeleteUnverified(
      'storage', 'delete', DiagnosticDisposition.retryableFailure),
  storageCorrupt('storage', 'open', DiagnosticDisposition.permanentFailure),
  providerDeadline(
      'health_provider', 'request', DiagnosticDisposition.retryableFailure),
  providerUnsupported(
      'health_provider', 'discover', DiagnosticDisposition.unsupported),
  synchronizationPartial('health_provider', 'synchronize',
      DiagnosticDisposition.partialCompletion),
  operationVerified('control', 'verify', DiagnosticDisposition.success);

  final String subsystem;
  final String operation;
  final DiagnosticDisposition disposition;

  const LocalDiagnosticCode(this.subsystem, this.operation, this.disposition);
}

/// Process-local correlation only; never accepts a user/provider identifier.
final class DiagnosticOperation {
  static int _next = 0;
  final int _sequence;

  DiagnosticOperation.start() : _sequence = ++_next;

  String get id => 'operation-$_sequence';
}

/// In-process contract only: no sink, persistence, telemetry or raw metadata.
final class LocalDiagnostic {
  final LocalDiagnosticCode code;
  final DiagnosticOperation operation;
  final DateTime observedAt;

  LocalDiagnostic.capture({
    required this.code,
    required this.operation,
    required DateTime Function() clock,
  }) : observedAt = clock().toUtc();

  Map<String, Object> toSafeJson() => Map.unmodifiable({
        'schemaVersion': 1,
        'code': code.name,
        'subsystem': code.subsystem,
        'operation': code.operation,
        'disposition': code.disposition.name,
        'correlationId': operation.id,
        'observedAt': observedAt.toIso8601String(),
      });
}
