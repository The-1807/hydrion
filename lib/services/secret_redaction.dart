class SecretRedactor {
  SecretRedactor._();

  static final List<_SecretRedactionPattern> _patterns =
      <_SecretRedactionPattern>[
    _SecretRedactionPattern(
      RegExp(
        r'-----BEGIN [A-Z0-9 ]*PRIVATE KEY-----[\s\S]*?-----END [A-Z0-9 ]*PRIVATE KEY-----',
        multiLine: true,
      ),
      '[redacted:private-key]',
    ),
    _SecretRedactionPattern(
      RegExp(r'AIza[0-9A-Za-z_-]{35}'),
      '[redacted:google-api-key]',
    ),
    _SecretRedactionPattern(
      RegExp(r'sk-(?:proj-|svcacct-)?[A-Za-z0-9_-]{32,}'),
      '[redacted:openai-api-key]',
    ),
    _SecretRedactionPattern(
      RegExp(r'sk-ant-[A-Za-z0-9_-]{32,}'),
      '[redacted:anthropic-api-key]',
    ),
    _SecretRedactionPattern(
      RegExp(
        r'\b(authorization\s*[:=]\s*)(?:bearer\s+)?[A-Za-z0-9._~+/\-]+=*',
        caseSensitive: false,
      ),
      r'$1[redacted:authorization]',
    ),
    _SecretRedactionPattern(
      RegExp(
        r'''\b((?:x-goog-api-key|api[_-]?key|client[_-]?secret|access[_-]?token|refresh[_-]?token|password|secret)\s*[:=]\s*['"]?)[^'"\s,;}]+''',
        caseSensitive: false,
      ),
      r'$1[redacted:credential]',
    ),
    _SecretRedactionPattern(
      RegExp(
        r'([?&](?:api_key|key|token|access_token|client_secret)=)[^&#\s]+',
        caseSensitive: false,
      ),
      r'$1[redacted:credential]',
    ),
    _SecretRedactionPattern(
      RegExp(r'://[^/\s:@]+:[^@\s/]+@'),
      '://[redacted-credentials]@',
    ),
  ];

  static String sanitize(String value) {
    var safe = value;

    for (final pattern in _patterns) {
      safe = safe.replaceAllMapped(pattern.expression, (match) {
        var replacement = pattern.replacement;
        for (var index = 1; index < match.groupCount + 1; index++) {
          replacement = replacement.replaceAll(
            '\$$index',
            match.group(index) ?? '',
          );
        }
        return replacement;
      });
    }

    return safe;
  }

  static bool containsSecretLikeText(String value) => sanitize(value) != value;

  static String? fingerprint(String? secret) {
    final normalized = secret?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }

    return 'fp:${_fnv1a32(normalized).toRadixString(16).padLeft(8, '0')}';
  }

  static int _fnv1a32(String value) {
    var hash = 0x811c9dc5;

    for (final codeUnit in value.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 0x01000193) & 0xffffffff;
    }

    return hash;
  }
}

class _SecretRedactionPattern {
  final RegExp expression;
  final String replacement;

  const _SecretRedactionPattern(this.expression, this.replacement);
}
