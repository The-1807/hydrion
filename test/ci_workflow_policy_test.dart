import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:yaml/yaml.dart';

void main() {
  final flutterCiFile = File('.github/workflows/flutter-ci.yml');
  final releaseFile = File('.github/workflows/hydrion-release.yml');

  test('workflow YAML parses after Android job separation', () {
    expect(loadYaml(flutterCiFile.readAsStringSync()), isA<YamlMap>());
    expect(loadYaml(releaseFile.readAsStringSync()), isA<YamlMap>());
  });

  test('Apple CI discovers a paired destination before building and launching',
      () {
    final job = _jobBlock(flutterCiFile.readAsStringSync(), 'build-ios');
    expect(job, contains('tool/apple_simulator.py --create-pair'));
    expect(job, contains('--build-and-launch'));
    expect(job, contains('pod install --deployment'));
    expect(job, isNot(contains('run: flutter build ios --simulator')));
    expect(
        job,
        isNot(matches(RegExp(
          r'[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}',
        ))));
  });

  test('debug and release Android artifacts build on separate fresh jobs', () {
    final workflow = flutterCiFile.readAsStringSync();
    final debugJob = _jobBlock(workflow, 'build-android-debug');
    final releaseJob = _jobBlock(workflow, 'build-android-release');

    expect(debugJob, contains('runs-on: ubuntu-latest'));
    expect(debugJob, contains('needs: quality-gate'));
    expect(debugJob, contains('ci_run_android_build.sh debug'));
    expect(debugJob, isNot(contains('ci_run_android_build.sh release')));
    expect(debugJob, contains('app-debug.apk'));

    expect(releaseJob, contains('runs-on: ubuntu-latest'));
    expect(releaseJob, contains('needs: quality-gate'));
    expect(releaseJob, contains('ci_run_android_build.sh release'));
    expect(releaseJob, isNot(contains('ci_run_android_build.sh debug')));
    expect(releaseJob, contains('validate_android_release.dart'));
  });

  test('Android artifact runners restore no Flutter or Pub cache', () {
    final workflow = flutterCiFile.readAsStringSync();
    final release = releaseFile.readAsStringSync();

    for (final job in <String>[
      _jobBlock(workflow, 'build-android-debug'),
      _jobBlock(workflow, 'build-android-release'),
      _jobBlock(release, 'release-candidate'),
    ]) {
      expect(job, contains('cache: false'));
      expect(job, contains('pub-cache: false'));
      expect(job, isNot(contains('actions/cache@')));
      expect(job, isNot(contains('gradle/actions/setup-gradle@')));
    }
  });

  test('manual and protected release runs cannot be superseded', () {
    final workflow = flutterCiFile.readAsStringSync();
    final release = releaseFile.readAsStringSync();

    expect(
      workflow,
      contains(
        r'group: hydrion-flutter-ci-${{ github.event_name }}-${{ github.ref }}',
      ),
    );
    expect(
      workflow,
      contains(
        r"cancel-in-progress: ${{ github.event_name != 'workflow_dispatch' }}",
      ),
    );
    expect(release, contains('cancel-in-progress: false'));
  });

  test('Android APK and AAB builds retain bounded diagnostics', () {
    final workflow = flutterCiFile.readAsStringSync();
    final release = releaseFile.readAsStringSync();
    final helper = File('tool/ci_run_android_build.sh').readAsStringSync();

    expect(workflow, contains('Upload debug-build diagnostics'));
    expect(workflow, contains('Upload release-build diagnostics'));
    expect(release, contains('ci_run_android_build.sh appbundle'));
    expect(release, contains('Upload Android build diagnostics'));
    expect(helper, contains('timeout 1m bash tool/ci_disk_diagnostics.sh'));
    expect(helper, contains('duration_seconds='));
    expect(helper, contains('exit_code='));
    expect(helper, contains('record_heartbeat'));
  });
}

String _jobBlock(String source, String jobName) {
  final start = RegExp('^  ${RegExp.escape(jobName)}:', multiLine: true)
      .firstMatch(source);
  expect(start, isNotNull, reason: 'Missing workflow job $jobName');
  RegExpMatch? next;
  for (final match in RegExp(
    r'^  [a-zA-Z0-9_-]+:',
    multiLine: true,
  ).allMatches(source, start!.end)) {
    next = match;
    break;
  }
  return source.substring(start.start, next?.start ?? source.length);
}
