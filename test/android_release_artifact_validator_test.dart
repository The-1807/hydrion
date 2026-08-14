import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../tool/validate_android_release.dart';

void main() {
  const badging = '''
package: name='com.the1807.hydrion' versionCode='3' versionName='1.1.0'
sdkVersion:'24'
targetSdkVersion:'36'
native-code: 'arm64-v8a' 'armeabi-v7a' 'x86_64'
''';
  const signer = '''
Verifies
V2 Signer: certificate SHA-256 digest: 0e:72:fe:a1
''';

  test('parses canonical pubspec version and Android artifact metadata', () {
    final version = parsePubspecVersion('name: hydrion\nversion: 1.1.0+3\n');
    final metadata = parseAndroidArtifactMetadata(
      badging: badging,
      signerOutput: signer,
    );

    expect(version.name, '1.1.0');
    expect(version.build, 3);
    expect(metadata.packageId, expectedAndroidPackageId);
    expect(metadata.versionCode, 3);
    expect(metadata.versionName, '1.1.0');
    expect(metadata.minSdk, expectedAndroidMinSdk);
    expect(metadata.targetSdk, expectedAndroidTargetSdk);
    expect(metadata.abis, expectedUniversalAbis);
    expect(metadata.certificateSha256, '0e72fea1');
  });

  test('production artifacts require the configured certificate', () {
    final metadata = parseAndroidArtifactMetadata(
      badging: badging,
      signerOutput: signer,
    );

    expect(
      () => validateAndroidArtifact(
        metadata: metadata,
        expectedVersion: const AppVersion('1.1.0', 3),
        signingKind: 'production',
      ),
      throwsStateError,
    );
    expect(
      () => validateAndroidArtifact(
        metadata: metadata,
        expectedVersion: const AppVersion('1.1.0', 3),
        signingKind: 'production',
        expectedCertificateSha256: '0e:72:fe:a1',
      ),
      returnsNormally,
    );
  });

  test('rejects version drift and incomplete universal APKs', () {
    final metadata = parseAndroidArtifactMetadata(
      badging: badging
          .replaceFirst("versionCode='3'", "versionCode='2'")
          .replaceFirst(
            " 'x86_64'",
            '',
          ),
      signerOutput: signer,
    );

    expect(
      () => validateAndroidArtifact(
        metadata: metadata,
        expectedVersion: const AppVersion('1.1.0', 3),
        signingKind: 'ci-ephemeral',
      ),
      throwsStateError,
    );
  });

  test('release infrastructure never treats debug artifacts as candidates', () {
    final workflow = File(
      '.github/workflows/hydrion-release.yml',
    ).readAsStringSync();
    final normalCi = File(
      '.github/workflows/flutter-ci.yml',
    ).readAsStringSync();
    final script = File('scripts/build_release.sh').readAsStringSync();

    expect(workflow, isNot(contains('app-debug.apk')));
    expect(workflow, isNot(contains('hydrion-v1.0.0')));
    expect(script, isNot(contains('hydrion-android.apk')));
    expect(normalCi, isNot(contains('secrets.HYDRION_ANDROID_')));
    expect(
      workflow,
      contains('secrets.HYDRION_ANDROID_SIGNING_CERT_SHA256'),
    );
    expect(workflow, contains('refs/heads/main'));
  });

  test('debug builds cannot occupy the production package identity', () {
    final gradle = File('android/app/build.gradle.kts').readAsStringSync();

    expect(gradle, contains('applicationIdSuffix = ".debug"'));
    expect(gradle, contains('versionNameSuffix = "-debug"'));
    expect(gradle, contains('applicationId = "com.the1807.hydrion"'));
  });
}
