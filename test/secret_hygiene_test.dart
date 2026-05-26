import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final secretPatterns = <RegExp>[
    RegExp(r'AIza[0-9A-Za-z_-]{35}'),
    RegExp(r'sk-[A-Za-z0-9]{32,}'),
    RegExp(r'sk-ant-[A-Za-z0-9_-]{32,}'),
    RegExp(r'-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----'),
  ];

  test('.gitignore excludes local secret files', () {
    final gitignore = File('.gitignore').readAsStringSync();

    expect(gitignore, contains('.env'));
    expect(gitignore, contains('.env.*'));
    expect(gitignore, contains('*.secrets.json'));
    expect(gitignore, contains('secrets/'));
    expect(gitignore, contains('gitleaks-report.*'));
  });

  test('repo contains no committed API keys or private key blocks', () {
    final findings = <String>[];

    for (final entity in Directory.current.listSync(recursive: true)) {
      if (entity is! File) {
        continue;
      }
      final path = entity.path.replaceAll('\\', '/');
      if (_shouldSkip(path)) {
        continue;
      }
      final content = _readText(entity);
      if (content == null) {
        continue;
      }
      for (final pattern in secretPatterns) {
        for (final match in pattern.allMatches(content)) {
          final value = match.group(0) ?? '';
          if (_isPlaceholder(value)) {
            continue;
          }
          findings.add(path);
        }
      }
    }

    expect(findings, isEmpty);
  });

  test('documented placeholder keys are not treated as real secrets', () {
    final firebaseConfig =
        File('config/firebase_config.json').readAsStringSync();

    expect(firebaseConfig, contains('YOUR_WEB_API_KEY'));
    expect(
      secretPatterns.any((pattern) => pattern.hasMatch('YOUR_WEB_API_KEY')),
      isFalse,
    );
  });
}

bool _shouldSkip(String path) {
  const ignoredDirectories = {
    '.git',
    '.dart_tool',
    '.idea',
    '.pub-cache',
    'build',
    'coverage',
  };
  const ignoredExtensions = {
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

  final segments = path.split('/');
  if (segments.any(ignoredDirectories.contains)) {
    return true;
  }
  final extension = path.contains('.') ? '.${path.split('.').last}' : '';
  return ignoredExtensions.contains(extension.toLowerCase());
}

String? _readText(File file) {
  try {
    return file.readAsStringSync();
  } on FileSystemException {
    return null;
  } on FormatException {
    return null;
  }
}

bool _isPlaceholder(String value) {
  final upper = value.toUpperCase();
  return upper.contains('YOUR_') ||
      upper.contains('PLACEHOLDER') ||
      upper.contains('EXAMPLE');
}
