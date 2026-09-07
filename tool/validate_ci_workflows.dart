import 'dart:io';

import 'package:yaml/yaml.dart';

void main() {
  final directory = Directory('.github/workflows');
  final files = directory
      .listSync()
      .whereType<File>()
      .where(
          (file) => file.path.endsWith('.yml') || file.path.endsWith('.yaml'))
      .toList(growable: false)
    ..sort((a, b) => a.path.compareTo(b.path));
  if (files.isEmpty) _fail('No GitHub Actions workflows were found.');

  final problems = <String>[];
  for (final file in files) {
    final source = file.readAsStringSync();
    Object? document;
    try {
      document = loadYaml(source);
    } on YamlException catch (error) {
      problems.add('${file.path}: invalid YAML: ${error.message}');
      continue;
    }
    if (document is! YamlMap || document['jobs'] is! YamlMap) {
      problems.add('${file.path}: missing jobs map');
      continue;
    }
    for (final match in RegExp(r'^\s*uses:\s*([^\s#]+)', multiLine: true)
        .allMatches(source)) {
      final action = match.group(1)!;
      final separator = action.lastIndexOf('@');
      final revision = separator < 0 ? '' : action.substring(separator + 1);
      if (!RegExp(r'^[0-9a-f]{40}$').hasMatch(revision)) {
        problems.add('${file.path}: action is not commit-pinned: $action');
      }
      if (action.startsWith('actions/cache@') ||
          action.startsWith('gradle/actions/setup-gradle@')) {
        problems
            .add('${file.path}: forbidden overlapping cache action: $action');
      }
    }
    if (RegExp(r'^\s*cache:\s*true\s*$', multiLine: true).hasMatch(source)) {
      problems.add('${file.path}: Flutter SDK caching must remain disabled');
    }
    for (final path in const [
      '~/.gradle',
      'android/.gradle',
      'build/',
      'coverage/',
    ]) {
      final cacheBlock = RegExp(
        r'uses:\s*actions/cache@[^\n]+[\s\S]{0,600}?path:\s*[^\n]*' +
            RegExp.escape(path),
      );
      if (cacheBlock.hasMatch(source)) {
        problems.add('${file.path}: disposable output is cached: $path');
      }
    }
  }

  final flutterCi = File('.github/workflows/flutter-ci.yml').readAsStringSync();
  final release =
      File('.github/workflows/hydrion-release.yml').readAsStringSync();

  _requireContains(
    flutterCi,
    r'group: hydrion-flutter-ci-${{ github.event_name }}-${{ github.ref }}',
    'normal CI concurrency must separate event types',
    problems,
  );
  _requireContains(
    flutterCi,
    r"cancel-in-progress: ${{ github.event_name != 'workflow_dispatch' }}",
    'manual CI runs must not be superseded',
    problems,
  );
  _requireContains(
    flutterCi,
    'build-android-debug:',
    'debug Android packaging must have its own job',
    problems,
  );
  _requireContains(
    flutterCi,
    'build-android-release:',
    'release Android packaging must have its own job',
    problems,
  );
  _requireContains(
    flutterCi,
    'bash tool/ci_run_android_build.sh debug',
    'debug Android build must use bounded diagnostics',
    problems,
  );
  _requireContains(
    flutterCi,
    'bash tool/ci_run_android_build.sh release',
    'release Android build must use bounded diagnostics',
    problems,
  );
  _requireContains(
    release,
    'cancel-in-progress: false',
    'release-candidate runs must not be superseded',
    problems,
  );
  _requireContains(
    release,
    'bash tool/ci_run_android_build.sh appbundle',
    'release AAB build must use bounded diagnostics',
    problems,
  );

  for (final job in <String>[
    _jobBlock(flutterCi, 'build-android-debug'),
    _jobBlock(flutterCi, 'build-android-release'),
    _jobBlock(release, 'release-candidate'),
  ]) {
    if (!job.contains('cache: false') || !job.contains('pub-cache: false')) {
      problems.add(
        'Android artifact jobs must not restore Flutter or Pub caches',
      );
    }
  }

  final debugJob = _jobBlock(flutterCi, 'build-android-debug');
  final normalReleaseJob = _jobBlock(flutterCi, 'build-android-release');
  if (debugJob.contains('flutter build apk --release') ||
      debugJob.contains('ci_run_android_build.sh release')) {
    problems.add('Debug Android job must not compile the release variant');
  }
  if (normalReleaseJob.contains('flutter build apk --debug') ||
      normalReleaseJob.contains('ci_run_android_build.sh debug')) {
    problems.add('Release Android job must not compile the debug variant');
  }

  if (problems.isNotEmpty) _fail(problems.join('\n'));
  stdout.writeln('Validated ${files.length} GitHub Actions workflows.');
}

void _requireContains(
  String source,
  String expected,
  String description,
  List<String> problems,
) {
  if (!source.contains(expected)) problems.add(description);
}

String _jobBlock(String source, String jobName) {
  final start = RegExp('^  ${RegExp.escape(jobName)}:', multiLine: true)
      .firstMatch(source);
  if (start == null) return '';
  RegExpMatch? next;
  for (final match in RegExp(
    r'^  [a-zA-Z0-9_-]+:',
    multiLine: true,
  ).allMatches(source, start.end)) {
    next = match;
    break;
  }
  return source.substring(start.start, next?.start ?? source.length);
}

Never _fail(String message) {
  stderr.writeln(message);
  exit(1);
}
