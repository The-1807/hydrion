import 'dart:io';

final List<SecretPattern> secretPatterns = <SecretPattern>[
  SecretPattern(
    category: 'Google API key',
    expression: RegExp(r'AIza[0-9A-Za-z_-]{35}'),
  ),
  SecretPattern(
    category: 'OpenAI API key',
    expression: RegExp(r'sk-(?:proj-|svcacct-)?[A-Za-z0-9_-]{32,}'),
  ),
  SecretPattern(
    category: 'Anthropic API key',
    expression: RegExp(r'sk-ant-[A-Za-z0-9_-]{32,}'),
  ),
  SecretPattern(
    category: 'Private key block',
    expression: RegExp(
      r'-----BEGIN [A-Z0-9 ]*PRIVATE KEY-----',
      multiLine: true,
    ),
    allowPlaceholder: false,
  ),
  SecretPattern(
    category: 'Authorization bearer token',
    expression: RegExp(
      r'\bAuthorization\s*[:=]\s*Bearer\s+([A-Za-z0-9._~+/\-]+=*)',
      caseSensitive: false,
    ),
    valueGroup: 1,
    requireSecretLikeValue: true,
  ),
  SecretPattern(
    category: 'Provider API key header',
    expression: RegExp(
      r'''\bx-goog-api-key\s*[:=]\s*['"]?([^'"\s,;}]+)''',
      caseSensitive: false,
    ),
    valueGroup: 1,
    requireSecretLikeValue: true,
  ),
  SecretPattern(
    category: 'Credential assignment',
    expression: RegExp(
      r'''\b(?:api[_-]?key|client[_-]?secret|access[_-]?token|refresh[_-]?token|password|secret)\s*[:=]\s*['"]?([^'"\s,;}]+)''',
      caseSensitive: false,
    ),
    valueGroup: 1,
    requireSecretLikeValue: true,
  ),
  SecretPattern(
    category: 'Credential URL',
    expression: RegExp(r'://[^/\s:@]+:([^@\s/]+)@'),
    valueGroup: 1,
  ),
  SecretPattern(
    category: 'Credential query parameter',
    expression: RegExp(
      r'[?&](?:api_key|key|token|access_token|client_secret)=([^&#\s]+)',
      caseSensitive: false,
    ),
    valueGroup: 1,
    requireSecretLikeValue: true,
  ),
];

const Set<String> ignoredDirectories = <String>{
  '.git',
  '.dart_tool',
  '.idea',
  '.pub-cache',
  '.hydrion-backups',
  '.gradle',
  'build',
  'coverage',
  'node_modules',
  'Pods',
};

const Set<String> ignoredExtensions = <String>{
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
  final findings = scanRepository();

  if (findings.isNotEmpty) {
    stderr.writeln('Potential committed secrets found:');
    for (final finding in formatFindings(findings)) {
      stderr.writeln('- $finding');
    }
    exitCode = 1;
    return;
  }

  stdout.writeln(
      'No committed API keys, credentials, or private key blocks found.');
}

List<SecretFinding> scanRepository({Directory? root}) {
  final rootDirectory = root ?? Directory.current;
  final files = _trackedFiles(rootDirectory);
  final findings = <SecretFinding>[];

  for (final file in files) {
    final normalizedPath = _normalizePath(file.path);
    if (shouldSkipPath(normalizedPath)) {
      continue;
    }

    final content = _readText(file);
    if (content == null) {
      continue;
    }

    findings.addAll(scanText(content, path: normalizedPath));
  }

  findings.sort(_compareFindings);
  return findings;
}

List<SecretFinding> scanText(String content, {String path = '<memory>'}) {
  final findings = <SecretFinding>[];

  for (final pattern in secretPatterns) {
    for (final match in pattern.expression.allMatches(content)) {
      final value = match.group(pattern.valueGroup) ?? match.group(0) ?? '';
      if (pattern.allowPlaceholder && isDocumentedPlaceholder(value)) {
        continue;
      }
      if (pattern.requireSecretLikeValue && !looksLikeSecretValue(value)) {
        continue;
      }

      findings.add(
        SecretFinding(
          path: path,
          line: _lineForOffset(content, match.start),
          category: pattern.category,
        ),
      );
    }
  }

  findings.sort(_compareFindings);
  return findings;
}

List<String> formatFindings(Iterable<SecretFinding> findings) {
  final formatted = findings.map((finding) => finding.toString()).toList();
  formatted.sort();
  return formatted;
}

bool shouldSkipPath(String path) {
  final segments = path.split('/');
  if (segments.any(ignoredDirectories.contains)) {
    return true;
  }

  final extension = path.contains('.') ? '.${path.split('.').last}' : '';
  return ignoredExtensions.contains(extension.toLowerCase());
}

bool isDocumentedPlaceholder(String value) {
  final normalized = _stripQuotes(value).trim();
  if (normalized.isEmpty) {
    return false;
  }
  if (_containsKnownSecretFormat(normalized)) {
    return false;
  }

  final upper = normalized.toUpperCase();
  return RegExp(r'^(YOUR|EXAMPLE|SAMPLE|PLACEHOLDER)[A-Z0-9_.:-]*$')
          .hasMatch(upper) ||
      RegExp(r'^\$\{?[A-Z][A-Z0-9_]*(API_KEY|TOKEN|SECRET|PASSWORD|CREDENTIALS?|ORG_ID)\}?$')
          .hasMatch(upper) ||
      RegExp(r'^\$ENV:[A-Z][A-Z0-9_]*$').hasMatch(upper) ||
      upper.contains('TEST-KEY') ||
      upper.contains('TEST_KEY') ||
      upper == 'REPLACE_ME' ||
      upper == 'NOT_A_REAL_KEY' ||
      upper == 'TEST_PLACEHOLDER_NOT_A_REAL_KEY' ||
      upper == '<YOUR_API_KEY>' ||
      upper == '<API_KEY>' ||
      upper == '...';
}

bool looksLikeSecretValue(String value) {
  final normalized = _stripQuotes(value).trim();
  if (normalized.isEmpty || isDocumentedPlaceholder(normalized)) {
    return false;
  }
  if (_containsKnownSecretFormat(normalized)) {
    return true;
  }
  if (normalized.length < 16) {
    return false;
  }
  if (RegExp(r'^[A-Za-z_][A-Za-z0-9_.]*(?:\([^)]*\))?$').hasMatch(normalized)) {
    return false;
  }
  if (RegExp(r'^[A-Za-z_][A-Za-z0-9_.]*\($').hasMatch(normalized)) {
    return false;
  }

  final hasLetter = RegExp(r'[A-Za-z]').hasMatch(normalized);
  final hasDigit = RegExp(r'\d').hasMatch(normalized);
  final hasTokenSeparator = RegExp(r'[._~+/\-=]').hasMatch(normalized);

  return hasLetter && (hasDigit || hasTokenSeparator);
}

String _stripQuotes(String value) {
  return value.replaceAll(RegExp(r'''^['"]|['"]$'''), '');
}

bool _containsKnownSecretFormat(String value) {
  return RegExp(r'AIza[0-9A-Za-z_-]{35}').hasMatch(value) ||
      RegExp(r'sk-(?:proj-|svcacct-)?[A-Za-z0-9_-]{32,}').hasMatch(value) ||
      RegExp(r'sk-ant-[A-Za-z0-9_-]{32,}').hasMatch(value) ||
      RegExp(r'-----BEGIN [A-Z0-9 ]*PRIVATE KEY-----').hasMatch(value);
}

List<File> _trackedFiles(Directory root) {
  final result = Process.runSync(
    'git',
    <String>['ls-files', '-z'],
    workingDirectory: root.path,
  );

  if (result.exitCode == 0 && result.stdout is String) {
    final paths = (result.stdout as String)
        .split('\u0000')
        .where((path) => path.trim().isNotEmpty);
    return [
      for (final path in paths)
        File('${root.path}${Platform.pathSeparator}$path'),
    ];
  }

  return root
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => !shouldSkipPath(_normalizePath(file.path)))
      .toList();
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

String _normalizePath(String path) => path.replaceAll('\\', '/');

int _lineForOffset(String content, int offset) {
  return '\n'.allMatches(content.substring(0, offset)).length + 1;
}

int _compareFindings(SecretFinding left, SecretFinding right) {
  final pathComparison = left.path.compareTo(right.path);
  if (pathComparison != 0) {
    return pathComparison;
  }
  final lineComparison = left.line.compareTo(right.line);
  if (lineComparison != 0) {
    return lineComparison;
  }
  return left.category.compareTo(right.category);
}

class SecretPattern {
  final String category;
  final RegExp expression;
  final int valueGroup;
  final bool allowPlaceholder;
  final bool requireSecretLikeValue;

  const SecretPattern({
    required this.category,
    required this.expression,
    this.valueGroup = 0,
    this.allowPlaceholder = true,
    this.requireSecretLikeValue = false,
  });
}

class SecretFinding {
  final String path;
  final int line;
  final String category;

  const SecretFinding({
    required this.path,
    required this.line,
    required this.category,
  });

  @override
  String toString() => '$path:$line: $category';
}
