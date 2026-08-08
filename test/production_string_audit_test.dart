import 'package:flutter_test/flutter_test.dart';

import '../tool/production_string_audit.dart';

void main() {
  group('Dart production-string scanner', () {
    test('detects multiline single-quoted constructor text', () {
      final findings = _dart("""Text(
  'Visible single quote',
);""");
      expect(findings.single.expression, contains('Visible single quote'));
    });

    test('detects multiline double-quoted constructor text', () {
      final findings = _dart('''Text(
  "Visible double quote",
);''');
      expect(findings, hasLength(1));
    });

    test('detects triple-quoted text', () {
      final findings = _dart("Text('''Visible\ntriple quote''');");
      expect(findings.single.lineEnd, greaterThan(findings.single.lineStart));
    });

    test('combines adjacent string literals', () {
      final findings = _dart("Text('First part ' 'second part');");
      expect(
          findings.single.expression, contains("'First part ' 'second part'"));
    });

    test('retains interpolated visible text', () {
      final findings = _dart(r"Text('Value: $amount');");
      expect(findings.single.expression, contains(r'$amount'));
    });

    test('does not terminate at quotes nested inside interpolation', () {
      final findings = _dart(
        r"Text('${l10n.challengeText('Value')} $amount');",
      );
      expect(findings, hasLength(1));
      expect(findings.single.expression, contains("challengeText('Value')"));
    });

    test('detects visible text returned by a helper', () {
      final findings = _dart("String label() => 'Visible helper label';");
      expect(findings, hasLength(1));
    });

    test('detects visible switch branches returned by a helper', () {
      final findings = _dart('''
String status(int value) => switch (value) {
  1 => 'First visible status',
  _ => 'Other visible status',
};
Text(status(1));
''');
      expect(findings, hasLength(2));
    });

    test('detects strings in a list referenced by visible text', () {
      final findings = _dart('''
const labels = <String>[
  'First visible list label',
  'Second visible list label',
];
Text(labels[index]);
''');
      expect(findings, hasLength(2));
    });

    test('detects strings in a map referenced by visible text', () {
      final findings = _dart('''
const labels = <String, String>{
  'first': 'First visible map label',
  'second': 'Second visible map label',
};
Text(labels[id]!);
''');
      expect(
        findings.map((finding) => finding.expression),
        containsAll([
          contains('First visible map label'),
          contains('Second visible map label'),
        ]),
      );
    });

    test('detects multiline dialog content', () {
      final findings = _dart("""AlertDialog(
  content: Text(
    'Visible dialog body',
  ),
);""");
      expect(findings, hasLength(1));
    });

    test('classifies multiline semantics copy as accessibility', () {
      final findings = _dart("""Semantics(
  semanticLabel:
      'Accessible control label',
);""");
      expect(findings.single.classification,
          ProductionStringClassification.accessibility);
    });

    test('ignores paths, routes, and storage keys outside visible contexts',
        () {
      final findings = _dart("""
const asset = 'assets/images/drop.png';
const route = '/settings';
const storageKey = 'challenge_state_v2';
""");
      expect(findings, isEmpty);
    });

    test('ignores test fixtures', () {
      final findings = scanDartSource("Text('Fixture label');",
          path: 'test/example_test.dart');
      expect(findings, isEmpty);
    });

    test('classifies Hydrion as an approved proper name', () {
      final findings = _dart("Text('Hydrion');");
      expect(findings.single.classification,
          ProductionStringClassification.properName);
      expect(findings.single.allowlistReason, isNotEmpty);
    });

    test('detects service-returned sentences', () {
      final findings = scanDartSource(
        "String result() => 'Unable to update your profile.';",
        path: 'lib/services/profile_service.dart',
      );
      expect(findings, hasLength(1));
      expect(findings.single.resolved, isFalse);
    });

    test('detects repository-returned sentences', () {
      final findings = scanDartSource(
        "String failure() => 'The saved session could not be restored.';",
        path: 'lib/repositories/session_repository.dart',
      );
      expect(findings, hasLength(1));
      expect(findings.single.resolved, isFalse);
    });

    test('detects interpolated service failures', () {
      final findings = scanDartSource(
        r"String failure() => 'Cleanup failed for $recordId.';",
        path: 'lib/services/profile_cleanup_service.dart',
      );
      expect(findings.single.expression, contains(r'$recordId'));
    });

    test('detects raw exception-to-UI flow without a string literal', () {
      final findings = _dart('Text(error.toString());');
      expect(findings, hasLength(1));
      expect(findings.single.resolution, contains('stable typed result'));
    });
  });

  test('detects Android notification source literals', () {
    final findings = scanAndroidSource(
      'builder.setContentTitle(\n  "Visible notification"\n)',
      path: 'android/app/src/main/kotlin/Notice.kt',
    );
    expect(findings, hasLength(1));
  });

  test('detects hardcoded Android XML text and semantics', () {
    final findings = scanAndroidXmlSource(
      '''<TextView android:text="Visible label"
          android:contentDescription="Accessible label" />''',
      path: 'android/app/src/main/res/layout/widget.xml',
    );
    expect(findings, hasLength(2));
    expect(
      findings.map((finding) => finding.classification),
      contains(ProductionStringClassification.accessibility),
    );
  });

  test('detects missing Android locale resources', () {
    final findings = scanAndroidResourceCoverage(
      english:
          '<resources><string name="widget_title">Title</string></resources>',
      french: '<resources></resources>',
      spanish:
          '<resources><string name="widget_title">Titulo</string></resources>',
    );
    expect(findings.single.resolution, contains('fr'));
  });
}

List<ProductionStringFinding> _dart(String source) =>
    scanDartSource(source, path: 'lib/ui/example.dart');
