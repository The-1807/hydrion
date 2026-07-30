import 'dart:convert';
import 'dart:io';

void main() {
  const manifestPath =
      'assets/images/challenges/artwork_manifest.json';
  final manifestFile = File(manifestPath);
  if (!manifestFile.existsSync()) {
    stderr.writeln('Missing artwork manifest: $manifestPath');
    exitCode = 1;
    return;
  }

  final decoded = jsonDecode(manifestFile.readAsStringSync());
  if (decoded is! Map<String, dynamic> || decoded['artwork'] is! List) {
    stderr.writeln('Artwork manifest has an invalid structure.');
    exitCode = 1;
    return;
  }

  final entries = decoded['artwork'] as List;
  final ids = <String>{};
  final paths = <String>{};
  var invalid = false;
  for (final value in entries) {
    if (value is! Map<String, dynamic>) {
      invalid = true;
      continue;
    }
    final id = value['challenge_id'];
    final path = value['path'];
    if (id is! String || id.isEmpty || !ids.add(id)) {
      stderr.writeln('Missing or duplicate challenge_id: $id');
      invalid = true;
    }
    if (path is! String ||
        !RegExp(r'^assets/images/challenges/[a-z0-9_]+\.png$')
            .hasMatch(path) ||
        !paths.add(path)) {
      stderr.writeln('Missing, invalid, or duplicate artwork path: $path');
      invalid = true;
    }
  }

  final supplied = entries
      .whereType<Map<String, dynamic>>()
      .where((entry) => File(entry['path'] as String).existsSync())
      .length;
  stdout.writeln(
    'Artwork manifest: ${entries.length} unique requests, '
    '$supplied supplied, ${entries.length - supplied} using fallbacks.',
  );
  if (invalid) exitCode = 1;
}
