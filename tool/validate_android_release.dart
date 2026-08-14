import 'dart:convert';
import 'dart:io';

import 'package:yaml/yaml.dart';

const expectedAndroidPackageId = 'com.the1807.hydrion';
const expectedAndroidMinSdk = 24;
const expectedAndroidTargetSdk = 36;
const expectedUniversalAbis = <String>{'arm64-v8a', 'armeabi-v7a', 'x86_64'};

final class AndroidArtifactMetadata {
  const AndroidArtifactMetadata({
    required this.packageId,
    required this.versionCode,
    required this.versionName,
    required this.minSdk,
    required this.targetSdk,
    required this.abis,
    required this.certificateSha256,
  });

  final String packageId;
  final int versionCode;
  final String versionName;
  final int minSdk;
  final int targetSdk;
  final Set<String> abis;
  final String certificateSha256;
}

final class AppVersion {
  const AppVersion(this.name, this.build);

  final String name;
  final int build;
}

AppVersion parsePubspecVersion(String source) {
  final yaml = loadYaml(source);
  if (yaml is! YamlMap || yaml['version'] is! String) {
    throw const FormatException('pubspec.yaml must contain a string version.');
  }
  final match = RegExp(r'^(\d+\.\d+\.\d+)\+(\d+)$').firstMatch(
    yaml['version'] as String,
  );
  if (match == null) {
    throw const FormatException(
      'pubspec version must use semantic-version+integer-build format.',
    );
  }
  return AppVersion(match.group(1)!, int.parse(match.group(2)!));
}

AndroidArtifactMetadata parseAndroidArtifactMetadata({
  required String badging,
  required String signerOutput,
}) {
  String requiredMatch(RegExp expression, String label, String source) {
    final match = expression.firstMatch(source);
    if (match == null) {
      throw FormatException(
          'Could not read $label from Android tooling output.');
    }
    return match.group(1)!;
  }

  final packageId = requiredMatch(
    RegExp(r"package: name='([^']+)'"),
    'package ID',
    badging,
  );
  final versionCode = int.parse(
    requiredMatch(RegExp(r"versionCode='(\d+)'"), 'versionCode', badging),
  );
  final versionName = requiredMatch(
    RegExp(r"versionName='([^']+)'"),
    'versionName',
    badging,
  );
  final minSdk = int.parse(
    requiredMatch(RegExp(r"sdkVersion:'(\d+)'"), 'minSdk', badging),
  );
  final targetSdk = int.parse(
    requiredMatch(
      RegExp(r"targetSdkVersion:'(\d+)'"),
      'targetSdk',
      badging,
    ),
  );
  final abiLine = requiredMatch(
    RegExp(r"native-code: ([^\r\n]+)"),
    'native ABIs',
    badging,
  );
  final abis = RegExp(r"'([^']+)'")
      .allMatches(abiLine)
      .map((match) => match.group(1)!)
      .toSet();
  final certificateSha256 = normalizeFingerprint(
    requiredMatch(
      RegExp(
        r'(?:certificate SHA-256 digest|certificate SHA-256):\s*([0-9a-fA-F:]+)',
        caseSensitive: false,
      ),
      'signing certificate SHA-256',
      signerOutput,
    ),
  );

  return AndroidArtifactMetadata(
    packageId: packageId,
    versionCode: versionCode,
    versionName: versionName,
    minSdk: minSdk,
    targetSdk: targetSdk,
    abis: abis,
    certificateSha256: certificateSha256,
  );
}

String normalizeFingerprint(String value) =>
    value.replaceAll(':', '').trim().toLowerCase();

void validateAndroidArtifact({
  required AndroidArtifactMetadata metadata,
  required AppVersion expectedVersion,
  required String signingKind,
  String? expectedCertificateSha256,
}) {
  void require(bool condition, String message) {
    if (!condition) throw StateError(message);
  }

  require(
    metadata.packageId == expectedAndroidPackageId,
    'Unexpected package ID: ${metadata.packageId}',
  );
  require(
    metadata.versionCode == expectedVersion.build,
    'APK versionCode ${metadata.versionCode} does not match '
    'pubspec build ${expectedVersion.build}.',
  );
  require(
    metadata.versionName == expectedVersion.name,
    'APK versionName ${metadata.versionName} does not match '
    'pubspec version ${expectedVersion.name}.',
  );
  require(
    metadata.minSdk == expectedAndroidMinSdk,
    'Unexpected minSdk: ${metadata.minSdk}',
  );
  require(
    metadata.targetSdk == expectedAndroidTargetSdk,
    'Unexpected targetSdk: ${metadata.targetSdk}',
  );
  require(
    metadata.abis.containsAll(expectedUniversalAbis),
    'Standalone APK is missing required ABIs: '
    '${expectedUniversalAbis.difference(metadata.abis).join(', ')}',
  );
  require(
    signingKind == 'production' || signingKind == 'ci-ephemeral',
    'Signing kind must be production or ci-ephemeral.',
  );

  final expectedFingerprint = normalizeFingerprint(
    expectedCertificateSha256 ?? '',
  );
  if (signingKind == 'production') {
    require(
      expectedFingerprint.isNotEmpty,
      'Production validation requires the expected certificate SHA-256.',
    );
    require(
      metadata.certificateSha256 == expectedFingerprint,
      'Production signing certificate fingerprint does not match policy.',
    );
  }
}

Future<void> main(List<String> arguments) async {
  final options = _parseArguments(arguments);
  final apk = File(options['apk']!);
  if (!apk.existsSync() || apk.lengthSync() == 0) {
    stderr.writeln('APK does not exist or is empty: ${apk.path}');
    exitCode = 1;
    return;
  }

  try {
    final version =
        parsePubspecVersion(File('pubspec.yaml').readAsStringSync());
    final tools = _findAndroidTools();
    await _requireSuccess(
        tools.jar, ['tf', apk.absolute.path], 'ZIP integrity');
    final badging = await _requireSuccess(
      tools.aapt,
      ['dump', 'badging', apk.absolute.path],
      'APK manifest inspection',
    );
    final signerOutput = await _requireSuccess(
      tools.apksigner,
      ['verify', '--verbose', '--print-certs', apk.absolute.path],
      'APK signature verification',
    );
    final metadata = parseAndroidArtifactMetadata(
      badging: badging,
      signerOutput: signerOutput,
    );
    final signingKind = options['signing-kind']!;
    validateAndroidArtifact(
      metadata: metadata,
      expectedVersion: version,
      signingKind: signingKind,
      expectedCertificateSha256: options['expected-certificate-sha256'],
    );

    final outputDirectory = Directory(options['output-dir']!)
      ..createSync(recursive: true);
    final artifactName =
        'hydrion-${version.name}-${version.build}-android-$signingKind-release.apk';
    final artifact = File(_join(outputDirectory.path, artifactName));
    apk.copySync(artifact.path);
    final digest = await _sha256(artifact);
    File('${artifact.path}.sha256')
        .writeAsStringSync('$digest  $artifactName\n');

    final manifest = <String, Object>{
      'product': 'Hydrion',
      'version': version.name,
      'build': version.build,
      'git_sha': options['git-sha']!,
      'platform': 'android',
      'artifact': artifactName,
      'size_bytes': artifact.lengthSync(),
      'sha256': digest,
      'package_id': metadata.packageId,
      'version_code': metadata.versionCode,
      'version_name': metadata.versionName,
      'min_sdk': metadata.minSdk,
      'target_sdk': metadata.targetSdk,
      'abis': metadata.abis.toList()..sort(),
      'signing_kind': signingKind,
      'signing_fingerprint_sha256': metadata.certificateSha256,
      'build_type': 'release',
    };
    File(_join(outputDirectory.path, '$artifactName.manifest.json'))
        .writeAsStringSync(
            '${const JsonEncoder.withIndent('  ').convert(manifest)}\n');
    stdout.writeln('Validated $artifactName');
    stdout.writeln('SHA-256: $digest');
  } on Object catch (error) {
    stderr.writeln('Android release artifact validation failed: $error');
    exitCode = 1;
  }
}

Map<String, String> _parseArguments(List<String> arguments) {
  final result = <String, String>{};
  for (var index = 0; index < arguments.length; index += 2) {
    if (index + 1 >= arguments.length || !arguments[index].startsWith('--')) {
      throw const FormatException('Arguments must be --name value pairs.');
    }
    result[arguments[index].substring(2)] = arguments[index + 1];
  }
  for (final required in ['apk', 'output-dir', 'signing-kind', 'git-sha']) {
    if ((result[required] ?? '').isEmpty) {
      throw FormatException('Missing required --$required argument.');
    }
  }
  return result;
}

final class _AndroidTools {
  const _AndroidTools({
    required this.aapt,
    required this.apksigner,
    required this.jar,
  });

  final String aapt;
  final String apksigner;
  final String jar;
}

_AndroidTools _findAndroidTools() {
  final sdk = Platform.environment['ANDROID_HOME'] ??
      Platform.environment['ANDROID_SDK_ROOT'];
  if (sdk == null || sdk.isEmpty) {
    throw StateError('ANDROID_HOME or ANDROID_SDK_ROOT is required.');
  }
  final buildTools = Directory(_join(sdk, 'build-tools'))
      .listSync()
      .whereType<Directory>()
      .toList()
    ..sort((left, right) => right.path.compareTo(left.path));
  if (buildTools.isEmpty) {
    throw StateError('Android build-tools were not found under $sdk.');
  }
  final suffix = Platform.isWindows ? '.exe' : '';
  final scriptSuffix = Platform.isWindows ? '.bat' : '';
  return _AndroidTools(
    aapt: _join(buildTools.first.path, 'aapt$suffix'),
    apksigner: _join(buildTools.first.path, 'apksigner$scriptSuffix'),
    jar: Platform.isWindows ? 'jar.exe' : 'jar',
  );
}

Future<String> _requireSuccess(
  String executable,
  List<String> arguments,
  String label,
) async {
  final result =
      await Process.run(executable, arguments, runInShell: Platform.isWindows);
  final output = '${result.stdout}\n${result.stderr}'.trim();
  if (result.exitCode != 0) {
    throw StateError('$label failed (exit ${result.exitCode}): $output');
  }
  return output;
}

String _join(String parent, String child) =>
    '$parent${Platform.pathSeparator}$child';

Future<String> _sha256(File file) async {
  final executable = Platform.isWindows
      ? 'certutil.exe'
      : Platform.isMacOS
          ? 'shasum'
          : 'sha256sum';
  final arguments = Platform.isWindows
      ? ['-hashfile', file.absolute.path, 'SHA256']
      : Platform.isMacOS
          ? ['-a', '256', file.absolute.path]
          : [file.absolute.path];
  final output = await _requireSuccess(
    executable,
    arguments,
    'SHA-256 generation',
  );
  final match = RegExp(r'\b[0-9a-fA-F]{64}\b').firstMatch(
    output.replaceAll(' ', ''),
  );
  if (match == null) {
    throw StateError('Could not parse SHA-256 tool output.');
  }
  return match.group(0)!.toLowerCase();
}
