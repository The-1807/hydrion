import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hydrion/domain/local_diagnostic.dart';

import 'support/architecture_test_support.dart';

void main() {
  final instant = DateTime.utc(2026, 1, 1);
  LocalDiagnostic capture(LocalDiagnosticCode code) => LocalDiagnostic.capture(
        code: code,
        operation: DiagnosticOperation.start(),
        clock: () => instant,
      );

  architectureInvariantTest<Set<String>>(
    'diagnostics expose only the reviewed envelope',
    observe: () => capture(LocalDiagnosticCode.storageReadUnavailable)
        .toSafeJson()
        .keys
        .toSet(),
    invariant: equals({
      'schemaVersion',
      'code',
      'subsystem',
      'operation',
      'disposition',
      'correlationId',
      'observedAt',
    }),
    counterexample: {'rawPayload'},
  );

  test('all diagnostic payload values come from closed vocabularies', () {
    for (final code in LocalDiagnosticCode.values) {
      final data = capture(code).toSafeJson();
      expect(data['code'], code.name);
      expect(data['subsystem'], code.subsystem);
      expect(data['operation'], code.operation);
      expect(data['disposition'], code.disposition.name);
      expect(data['schemaVersion'], 1);
      expect(data['observedAt'], instant.toIso8601String());
      expect(data['correlationId'], matches(r'^operation-\d+$'));
      expect(() => data['rawPayload'] = 'synthetic private text',
          throwsUnsupportedError);
      expect(jsonDecode(jsonEncode(data)), data);
    }
  });

  test('failure codes cannot be labelled as successful completion', () {
    for (final code in LocalDiagnosticCode.values) {
      if (code == LocalDiagnosticCode.operationVerified) continue;
      expect(code.disposition, isNot(DiagnosticDisposition.success));
    }
    expect(LocalDiagnosticCode.storageWriteUnverified.disposition,
        DiagnosticDisposition.degraded);
    expect(LocalDiagnosticCode.storageDeleteUnverified.disposition,
        DiagnosticDisposition.retryableFailure);
  });

  test('clock is sampled once and converted to UTC, not a domain event clock',
      () {
    var calls = 0;
    final operation = DiagnosticOperation.start();
    final event = LocalDiagnostic.capture(
      code: LocalDiagnosticCode.providerDeadline,
      operation: operation,
      clock: () {
        calls++;
        return instant.toLocal();
      },
    );
    expect(calls, 1);
    expect(event.observedAt, instant);
    expect(event.observedAt.isUtc, isTrue);
    expect(event.toSafeJson()['correlationId'], operation.id);
    expect(DiagnosticOperation.start().id, isNot(operation.id));
  });
}
