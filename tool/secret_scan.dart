import 'dart:io';

final _secretPatterns = <String, RegExp>{
  'Google API key': RegExp(r'AIza[0-9A-Za-z_-]{35}'),
  'OpenAI API key': RegExp(r'sk-[A-Za-z0-9]{32,}'),
  'Anthropic API key': RegExp(r'sk-ant-[A-Za-z0-9_-]{32,}'),
  'Private key block':
      RegExp(r'-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----'),
};

final _ignoredDirectories = <String>{
  '.git',
  '.dart_tool',
  '.idea',
  '.pub-cache',
  'build',
  'coverage',
};

final _ignoredExtensions = <String>{
  '.class',
  '.ico',
  '.iml',
  '.jar',
  '.jpg',
  '.jpeg',
  '.lock',
  '.png',
  '.pyc',
  '.so',
  '.swp',
  '.ttf',
};

void main() {
  final findings = <String>[];
  for (final entity in Directory.current.listSync(recursive: true)) {
    if (entity is! File) {
      continue;
    }
    final path = entity.path.replaceAll('\\', '/');
    if (_shouldSkip(path)) {
      continue;
    }
    String content;
    try {
      content = entity.readAsStringSync();
    } on FileSystemException {
      continue;
    } on FormatException {
      continue;
    }
    for (final entry in _secretPatterns.entries) {
      for (final match in entry.value.allMatches(content)) {
        final value = match.group(0) ?? '';
        if (_isPlaceholder(value)) {
          continue;
        }
        final line = _lineForOffset(content, match.start);
        findings.add('$path:$line: ${entry.key}');
      }
    }
  }

  if (findings.isNotEmpty) {
    stderr.writeln('Potential committed secrets found:');
    for (final finding in findings) {
      stderr.writeln('- $finding');
    }
    exitCode = 1;
    return;
  }

  stdout.writeln('No committed API keys or private key blocks found.');
}

bool _shouldSkip(String path) {
  final segments = path.split('/');
  if (segments.any(_ignoredDirectories.contains)) {
    return true;
  }
  final extension = path.contains('.') ? '.${path.split('.').last}' : '';
  return _ignoredExtensions.contains(extension.toLowerCase());
}

bool _isPlaceholder(String value) {
  final upper = value.toUpperCase();
  return upper.contains('YOUR_') ||
      upper.contains('PLACEHOLDER') ||
      upper.contains('EXAMPLE');
}

int _lineForOffset(String content, int offset) {
  return '\n'.allMatches(content.substring(0, offset)).length + 1;
}
