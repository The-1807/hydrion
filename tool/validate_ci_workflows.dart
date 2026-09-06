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

  if (problems.isNotEmpty) _fail(problems.join('\n'));
  stdout.writeln('Validated ${files.length} GitHub Actions workflows.');
}

Never _fail(String message) {
  stderr.writeln(message);
  exit(1);
}
