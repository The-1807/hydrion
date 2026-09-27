import 'dart:async';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
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

/// Parses directive URIs only; this is not a transitive dependency graph.
/// Syntax errors fail closed rather than returning an incomplete dependency set.
List<Uri> dependencyTargets(String source, Uri sourceFile) {
  final unit = parseString(content: source, path: sourceFile.toString()).unit;
  final targets = <Uri>[];
  void add(StringLiteral literal) {
    final value = literal.stringValue;
    if (value == null) {
      throw ArgumentError('Dependency URI must be literal: $sourceFile');
    }
    targets.add(sourceFile.resolve(value));
  }

  for (final directive in unit.directives) {
    if (directive is UriBasedDirective) {
      add(directive.uri);
      if (directive is NamespaceDirective) {
        for (final configuration in directive.configurations) {
          add(configuration.uri);
        }
      }
    } else if (directive is PartOfDirective && directive.uri != null) {
      add(directive.uri!);
    }
  }
  return targets;
}

List<String> domainUiViolations(String source, Uri sourceFile) => [
      for (final target in dependencyTargets(source, sourceFile))
        if (isHydrionUiDependency(target)) '$sourceFile -> $target',
    ];

void expectNoDomainUiDependencies(Iterable<String> violations) =>
    expect(violations, isEmpty, reason: 'Domain must not depend on UI');

bool isHydrionUiDependency(Uri target) =>
    (target.scheme == 'package' && target.path.startsWith('hydrion/ui/')) ||
    (target.scheme == 'file' && target.path.contains('/lib/ui/'));
