import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('issue-sync secret guard runs before GitHub mutations', () {
    final script = File('Publish-HydrionUserStories.ps1').readAsStringSync();

    expect(script, contains('function Assert-NoSecretLikeContent'));
    expect(script, contains(r'Assert-NoSecretLikeContent -Text $content'));

    _expectGuardBeforeMutation(
      script,
      functionName: 'New-UserStoryIssue',
      guard: 'Assert-HydrionGithubMutationSafe',
    );
    _expectGuardBeforeMutation(
      script,
      functionName: 'Sync-UserStoryIssueContent',
      guard: 'Assert-HydrionGithubMutationSafe',
    );
    _expectGuardBeforeMutation(
      script,
      functionName: 'Sync-UserStoryIssueMetadata',
      guard: 'Assert-HydrionGithubMutationSafe',
    );
  });

  test(
    'normal user-story metadata validates for issue sync',
    () async {
      final result = await Process.run(
        'powershell',
        <String>[
          '-NoProfile',
          '-ExecutionPolicy',
          'Bypass',
          '-File',
          'Publish-HydrionUserStories.ps1',
          '-ValidateOnly',
        ],
      );

      expect(
        '${result.stdout}\n${result.stderr}',
        contains('validation passed'),
      );
      expect(result.exitCode, 0);
    },
    skip: !Platform.isWindows,
  );

  test(
    'issue-sync input with fake credential is rejected before GitHub requests',
    () async {
      final tempDir =
          Directory.systemTemp.createTempSync('hydrion-story-sync-');
      addTearDown(() => tempDir.deleteSync(recursive: true));

      final source = File('Hydrion_UserStories.md').readAsStringSync();
      final fakeKey = _fakeGoogleKey();
      final unsafeSource = source.replaceFirst(
        '## Business Value',
        'Leaked provider key: $fakeKey\n\n## Business Value',
      );
      final unsafePath = '${tempDir.path}${Platform.pathSeparator}stories.md';
      File(unsafePath).writeAsStringSync(unsafeSource);

      final result = await Process.run(
        'powershell',
        <String>[
          '-NoProfile',
          '-ExecutionPolicy',
          'Bypass',
          '-File',
          'Publish-HydrionUserStories.ps1',
          '-ValidateOnly',
          '-MarkdownPath',
          unsafePath,
        ],
      );
      final output = '${result.stdout}\n${result.stderr}';

      expect(result.exitCode, isNot(0));
      expect(output, contains('Refusing to send secret-looking content'));
      expect(output, contains('Google API key'));
      expect(output, isNot(contains(fakeKey)));
    },
    skip: !Platform.isWindows,
  );
}

void _expectGuardBeforeMutation(
  String script, {
  required String functionName,
  required String guard,
}) {
  final functionStart = script.indexOf('function $functionName');
  expect(functionStart, isNonNegative);

  final guardIndex = script.indexOf(guard, functionStart);
  final mutationIndex =
      script.indexOf('Invoke-MutationWithRetry', functionStart);

  expect(guardIndex, isNonNegative);
  expect(mutationIndex, isNonNegative);
  expect(guardIndex, lessThan(mutationIndex));
}

String _fakeGoogleKey() => 'AIza${'A' * 35}';
