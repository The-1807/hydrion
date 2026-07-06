import 'dart:io';

void main(List<String> args) {
  final outputIndex = args.indexOf('--output');
  String? outputPath;
  final inputs = <String>[];
  for (var index = 0; index < args.length; index += 1) {
    if (index == outputIndex) {
      outputPath = args[index + 1];
      index += 1;
    } else if (args[index] != '--output') {
      inputs.add(args[index]);
    }
  }

  final artifacts = _discoverArtifacts(inputs);
  final buffer = StringBuffer()
    ..writeln('# Hydrion Android Size Audit')
    ..writeln()
    ..writeln('Generated: ${DateTime.now().toUtc().toIso8601String()} UTC')
    ..writeln()
    ..writeln('## Runtime Assets')
    ..writeln();

  final assetFiles = _listFiles(
    Directory('assets'),
  ).where((file) => !_isPlaceholderFile(file)).toList();
  final assetBytes =
      assetFiles.fold<int>(0, (sum, file) => sum + file.lengthSync());
  buffer
    ..writeln('- Runtime asset files: ${assetFiles.length}')
    ..writeln('- Runtime asset bytes: ${_formatBytes(assetBytes)}')
    ..writeln();

  if (artifacts.isEmpty) {
    buffer
      ..writeln('## Android Artifacts')
      ..writeln()
      ..writeln('No APK or AAB artifacts were found in the supplied inputs.');
  } else {
    buffer
      ..writeln('## Android Artifacts')
      ..writeln();
    for (final artifact in artifacts) {
      _writeArtifactAudit(buffer, artifact);
    }
  }

  final report = buffer.toString();
  if (outputPath == null) {
    stdout.write(report);
    return;
  }
  final output = File(outputPath);
  output.parent.createSync(recursive: true);
  output.writeAsStringSync(report);
  stdout.writeln('Wrote Android size audit to ${output.path}');
}

List<File> _discoverArtifacts(List<String> inputs) {
  final artifacts = <File>[];
  final seen = <String>{};
  final candidates = inputs.isEmpty ? ['build', '.'] : inputs;
  for (final candidate in candidates) {
    final entityType = FileSystemEntity.typeSync(candidate);
    if (entityType == FileSystemEntityType.file) {
      final file = File(candidate);
      if (_isAndroidArtifact(file.path) && seen.add(file.absolute.path)) {
        artifacts.add(file);
      }
      continue;
    }
    if (entityType == FileSystemEntityType.directory) {
      for (final file in _listFiles(Directory(candidate))) {
        if (_isAndroidArtifact(file.path) && seen.add(file.absolute.path)) {
          artifacts.add(file);
        }
      }
    }
  }
  artifacts.sort((a, b) => a.path.compareTo(b.path));
  return artifacts;
}

List<File> _listFiles(Directory directory) {
  if (!directory.existsSync()) {
    return const [];
  }
  return directory
      .listSync(recursive: true, followLinks: false)
      .whereType<File>()
      .toList();
}

bool _isAndroidArtifact(String path) {
  final lower = path.toLowerCase();
  return lower.endsWith('.apk') || lower.endsWith('.aab');
}

bool _isPlaceholderFile(File file) {
  return file.uri.pathSegments.last == '.gitkeep';
}

void _writeArtifactAudit(StringBuffer buffer, File artifact) {
  buffer
    ..writeln('### ${artifact.path}')
    ..writeln()
    ..writeln('- File size: ${_formatBytes(artifact.lengthSync())}');

  final entries = _zipEntries(artifact);
  if (entries.isEmpty) {
    buffer
      ..writeln(
          '- Zip breakdown: unavailable. Install `unzip` to enable entry analysis.')
      ..writeln();
    return;
  }

  final groups = <String, int>{};
  for (final entry in entries) {
    groups.update(
      _groupForEntry(entry.name),
      (value) => value + entry.uncompressedBytes,
      ifAbsent: () => entry.uncompressedBytes,
    );
  }
  final sortedGroups = groups.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  buffer
    ..writeln()
    ..writeln('| Category | Uncompressed Size |')
    ..writeln('| --- | ---: |');
  for (final group in sortedGroups) {
    buffer.writeln('| ${group.key} | ${_formatBytes(group.value)} |');
  }

  final largest = entries.toList()
    ..sort((a, b) => b.uncompressedBytes.compareTo(a.uncompressedBytes));
  buffer
    ..writeln()
    ..writeln('Largest entries:')
    ..writeln();
  for (final entry in largest.take(20)) {
    buffer.writeln(
      '- ${_formatBytes(entry.uncompressedBytes)} ${entry.name}',
    );
  }
  buffer.writeln();
}

List<_ZipEntry> _zipEntries(File artifact) {
  final result = Process.runSync(
    'unzip',
    ['-l', artifact.path],
    stdoutEncoding: systemEncoding,
    stderrEncoding: systemEncoding,
  );
  if (result.exitCode != 0) {
    return const [];
  }
  final entries = <_ZipEntry>[];
  final linePattern =
      RegExp(r'^\s*(\d+)\s+\d{4}[-/]\d{2}[-/]\d{2}\s+\d{2}:\d{2}\s+(.+)$');
  for (final line in result.stdout.toString().split('\n')) {
    final match = linePattern.firstMatch(line);
    if (match == null) {
      continue;
    }
    final size = int.tryParse(match.group(1)!);
    final name = match.group(2)!.trim();
    if (size == null || name.isEmpty || name.endsWith('/')) {
      continue;
    }
    entries.add(_ZipEntry(name: name, uncompressedBytes: size));
  }
  return entries;
}

String _groupForEntry(String name) {
  final lower = name.toLowerCase();
  if (lower.contains('flutter_assets/assets/')) {
    return 'Flutter assets';
  }
  if (lower.contains('flutter_assets/fonts/') ||
      lower.endsWith('.ttf') ||
      lower.endsWith('.otf')) {
    return 'Fonts';
  }
  if (lower.endsWith('.so') || lower.contains('/lib/')) {
    return 'Native libraries';
  }
  if (lower.endsWith('.dex')) {
    return 'Dex bytecode';
  }
  if (lower.startsWith('res/') || lower.contains('/res/')) {
    return 'Android resources';
  }
  if (lower.endsWith('resources.arsc')) {
    return 'Android resources';
  }
  if (lower.startsWith('meta-inf/') || lower.contains('/meta-inf/')) {
    return 'Signing metadata';
  }
  if (lower.endsWith('androidmanifest.xml')) {
    return 'Android manifest';
  }
  if (lower.contains('flutter_assets/')) {
    return 'Flutter runtime assets';
  }
  return 'Other';
}

String _formatBytes(int bytes) {
  const units = ['B', 'KB', 'MB', 'GB'];
  var value = bytes.toDouble();
  var unitIndex = 0;
  while (value >= 1024 && unitIndex < units.length - 1) {
    value /= 1024;
    unitIndex += 1;
  }
  final text =
      unitIndex == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(2);
  return '$text ${units[unitIndex]}';
}

class _ZipEntry {
  final String name;
  final int uncompressedBytes;

  const _ZipEntry({
    required this.name,
    required this.uncompressedBytes,
  });
}
