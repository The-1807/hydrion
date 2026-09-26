import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

/// A passing characterization preserves evidence, not the desired final policy.
void characterizationTest(
  String finding,
  String description, {
  required String desiredInvariant,
  required FutureOr<void> Function() body,
}) {
  if (!RegExp(r'^HTD-[A-Z]+-\d{3}$').hasMatch(finding) ||
      desiredInvariant.trim().isEmpty) {
    throw ArgumentError(
        'Characterization needs a finding and desired invariant');
  }
  test('CHARACTERIZATION [$finding] $description; desired: $desiredInvariant',
      body);
}

/// A desired invariant must also reject an explicit counterexample.
void architectureInvariantTest<T>(
  String description, {
  required FutureOr<T> Function() observe,
  required Matcher invariant,
  required T counterexample,
}) {
  test('INVARIANT $description', () async {
    expect(await observe(), invariant);
  });
  test('INVARIANT NEGATIVE CONTROL $description', () {
    expect(counterexample, isNot(invariant),
        reason: 'The invariant must detect its deliberate violation');
  });
}

/// Literal dependency guard, not a Dart compiler or a runtime call graph.
/// Includes alternate URIs in conditional directives and multiline imports.
List<Uri> dependencyTargets(String source, Uri sourceFile) {
  final directives = RegExp(
    r'^\s*(?:import|export|part)\s+([^;]+);',
    multiLine: true,
  );
  final quoted = RegExp(r'''['"]([^'"]+)['"]''');
  return [
    for (final directive in directives.allMatches(source))
      for (final target in quoted.allMatches(directive.group(1)!))
        sourceFile.resolve(target.group(1)!),
  ];
}

bool isHydrionUiDependency(Uri target) =>
    (target.scheme == 'package' && target.path.startsWith('hydrion/ui/')) ||
    (target.scheme == 'file' && target.path.contains('/lib/ui/'));
