import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hydrion/services/secret_redaction.dart';

import '../tool/secret_scan.dart' as secret_scan;

void main() {
  test('.gitignore excludes local secret files without hiding templates', () {
    final gitignore = File('.gitignore').readAsStringSync();

    expect(gitignore, contains('.env'));
    expect(gitignore, contains('.env.*'));
    expect(gitignore, contains('!.env.example'));
    expect(gitignore, contains('*.secrets.json'));
    expect(gitignore, contains('*.credentials.json'));
    expect(gitignore, contains('*.pem'));
    expect(gitignore, contains('android/key.properties'));
    expect(gitignore, contains('secrets/'));
    expect(gitignore, contains('gitleaks-report.*'));
  });

  test(
      'repo contains no committed API keys, credentials, or private key blocks',
      () {
    final findings = secret_scan.scanRepository();

    expect(secret_scan.formatFindings(findings), isEmpty);
  });

  test('realistic fake Google or Gemini API key is detected', () {
    final fakeKey = _fakeGoogleKey();
    final findings = secret_scan.scanText(
      'provider_api_key: $fakeKey',
      path: 'fixture/provider.yaml',
    );

    expect(findings.map((finding) => finding.category),
        contains('Google API key'));
  });

  test('realistic fake OpenAI API key is detected', () {
    final fakeKey = _fakeOpenAiKey();
    final findings = secret_scan.scanText(
      'OPENAI_API_KEY=$fakeKey',
      path: 'fixture/provider.env',
    );

    expect(findings.map((finding) => finding.category),
        contains('OpenAI API key'));
  });

  test('private key block is detected', () {
    final findings = secret_scan.scanText(
      [
        'certificate:',
        _privateKeyBegin(),
        'not-a-real-private-key-body',
        _privateKeyEnd(),
      ].join('\n'),
      path: 'fixture/key.pem',
    );

    expect(findings.map((finding) => finding.category),
        contains('Private key block'));
  });

  test('credential URL is detected without printing credential material', () {
    final credentialUrl = _fakeCredentialUrl();
    final findings = secret_scan.scanText(
      'provider_url: $credentialUrl',
      path: 'fixture/provider.env',
    );
    final output = secret_scan.formatFindings(findings).join('\n');

    expect(findings.map((finding) => finding.category),
        contains('Credential URL'));
    expect(output, contains('fixture/provider.env:1: Credential URL'));
    expect(output, isNot(contains('hydrion-user')));
    expect(output, isNot(contains('hydrion-password')));
    expect(output, isNot(contains(credentialUrl)));
  });

  test(
      'credential URL sanitizer removes credentials without re-triggering scan',
      () {
    final credentialUrl = _fakeCredentialUrl();

    final sanitized = SecretRedactor.sanitize(credentialUrl);
    final findings = secret_scan.scanText(
      sanitized,
      path: 'fixture/sanitized.txt',
    );

    expect(sanitized, 'https://[redacted-credentials]@example.invalid/api');
    expect(sanitized, isNot(contains('hydrion-user')));
    expect(sanitized, isNot(contains('hydrion-password')));
    expect(
      findings.where((finding) => finding.category == 'Credential URL'),
      isEmpty,
    );
  });

  test('documented placeholder values are allowed', () {
    final findings = secret_scan.scanText(
      [
        'api_key: YOUR_WEB_API_KEY',
        'client_secret: REPLACE_ME',
        'token: TEST_PLACEHOLDER_NOT_A_REAL_KEY',
      ].join('\n'),
      path: 'fixture/example.env',
    );

    expect(findings, isEmpty);
  });

  test('realistic-looking credential labeled as placeholder is still rejected',
      () {
    final fakeKey = _fakeGoogleKey();
    final findings = secret_scan.scanText(
      'placeholder_google_key: PLACEHOLDER_$fakeKey',
      path: 'fixture/example.md',
    );

    expect(findings.map((finding) => finding.category),
        contains('Google API key'));
  });

  test('scanner output omits the complete detected value', () {
    final fakeKey = _fakeGoogleKey();
    final findings = secret_scan.scanText(
      'provider_api_key: $fakeKey',
      path: 'fixture/provider.yaml',
    );
    final output = secret_scan.formatFindings(findings).join('\n');

    expect(output, contains('fixture/provider.yaml:1: Google API key'));
    expect(output, isNot(contains(fakeKey)));
  });
}

String _fakeGoogleKey() => 'AIza${'A' * 35}';

String _fakeOpenAiKey() => 'sk-${'A' * 36}';

String _fakeCredentialUrl() =>
    'https://' 'hydrion-user' ':' 'hydrion-password' '@example.invalid/api';

String _privateKeyBegin() => '-----BEGIN ' 'PRIVATE KEY-----';

String _privateKeyEnd() => '-----END ' 'PRIVATE KEY-----';
