import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'support/architecture_test_support.dart';

void main() {
  test('dependency guard resolves relative, package and conditional targets',
      () {
    final sourceFile = Uri.parse('file:///repo/lib/domain/example.dart');
    final targets = dependencyTargets('''
import
  '../ui/example.dart';
export 'package:hydrion/ui/example.dart';
import '../domain/example.dart'
  if (dart.library.io) '../ui/native.dart';
import 'dart:async';
// import '../ui/not_a_dependency.dart';
''', sourceFile);
    expect(targets.where(isHydrionUiDependency).map((uri) => uri.toString()), [
      'file:///repo/lib/ui/example.dart',
      'package:hydrion/ui/example.dart',
      'file:///repo/lib/ui/native.dart',
    ]);
    expect(targets, hasLength(5));
  });

  test('characterization registration requires finding and desired invariant',
      () {
    expect(
      () => characterizationTest('unlinked', 'example',
          desiredInvariant: '', body: () {}),
      throwsArgumentError,
    );
  });

  test('HTD retains all findings, unique ownership and an acyclic stage plan',
      () {
    final document = File('HTD.md').readAsStringSync();
    final findings = RegExp(r'^#### (HTD-[A-Z]+-\d{3}) -', multiLine: true)
        .allMatches(document)
        .map((match) => match.group(1)!)
        .toList();
    expect(findings, hasLength(46));
    expect(findings.toSet(), hasLength(46));
    final assignments = RegExp(r'^- \*\*Findings:\*\* (.*)$',
            multiLine: true, caseSensitive: false)
        .allMatches(document)
        .expand((line) => RegExp(r'HTD-[A-Z]+-\d{3}')
            .allMatches(line.group(1)!)
            .map((match) => match.group(0)!))
        .toList();
    expect(assignments, hasLength(46));
    expect(assignments.toSet(), findings.toSet());
    final stages = <String, List<String>>{
      for (final match
          in RegExp(r'^\| (0A|0B|[1-9]|10) \| ([^|]+) \|', multiLine: true)
              .allMatches(document))
        match.group(1)!: match.group(2)!.trim() == 'None'
            ? []
            : match.group(2)!.trim().split(', '),
    };
    expect(stages, hasLength(12));
    final active = <String>{};
    final visited = <String>{};
    void visit(String stage) {
      expect(stages, contains(stage));
      expect(active, isNot(contains(stage)), reason: 'dependency cycle');
      if (visited.contains(stage)) return;
      active.add(stage);
      for (final dependency in stages[stage]!) {
        visit(dependency);
      }
      active.remove(stage);
      visited.add(stage);
    }

    stages.keys.forEach(visit);
    for (final stage in ['1', '2', '4']) {
      expect(stages[stage], ['0A']);
    }
    final headings = RegExp(r'^### (?:Final )?Stage (\w+) -', multiLine: true)
        .allMatches(document)
        .map((match) => match.group(1))
        .toList();
    expect(headings.last, '10');
    expect(document,
        contains('PAUSED UNTIL HYDRION FOUNDATION REMEDIATION COMPLETES.'));
  });

  test('connector status distinguishes locked architecture from acceptance',
      () {
    final document = File('docs/architecture/HYDRION_CONNECTOR_ARCHITECTURE.md')
        .readAsStringSync();
    expect(document, contains('Gate 0 (architecture/topology lock) is CLOSED'));
    expect(document, contains('PARTIALLY IMPLEMENTED; NOT ACCEPTED'));
    expect(document, isNot(contains('Gate 1 has not started')));
    expect(
        document, isNot(contains('Requires, all verified and none yet fixed')));
    expect(document, contains('primitives. NOT STARTED.'));
    expect(document,
        contains('PAUSED UNTIL HYDRION FOUNDATION REMEDIATION COMPLETES.'));
  });

  test('acceptance discipline never treats missing completion as a pass', () {
    final document =
        File('docs/architecture/REMEDIATION_ACCEPTANCE.md').readAsStringSync();
    for (final required in [
      'baseline_sha',
      'implementation_sha',
      'finding_ids',
      'changed_files',
      'tests_added_or_changed',
      'focused_validation',
      'broader_validation',
      'known_failures',
      'evidence_limits',
      'independent_acceptance',
      'TIMEOUT is never PASS',
      'implementer cannot be the acceptance reviewer',
    ]) {
      expect(document, contains(required));
    }
  });
}
