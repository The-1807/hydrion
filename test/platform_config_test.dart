import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hydrion/domain/challenge_catalog.dart';
import 'package:hydrion/domain/challenge_visual_registry.dart';

void main() {
  test('Android identity and signing workflow are install-ready', () {
    final gradle = File('android/app/build.gradle.kts').readAsStringSync();
    final activity = File(
      'android/app/src/main/kotlin/com/the1807/hydrion/MainActivity.kt',
    ).readAsStringSync();
    final workflow =
        File('.github/workflows/flutter-ci.yml').readAsStringSync();

    expect(gradle, contains('namespace = "com.the1807.hydrion"'));
    expect(gradle, contains('applicationId = "com.the1807.hydrion"'));
    expect(gradle, isNot(contains('com.example.hydrion_app')));
    expect(activity, contains('package com.the1807.hydrion'));
    expect(workflow, contains('FLUTTER_VERSION: "3.35.6"'));
    expect(workflow, contains('dart format --set-exit-if-changed .'));
    expect(workflow, contains('release_signing_kind=ci-ephemeral'));
    expect(workflow, contains('apksigner'));
  });

  test('iOS bundle id, permissions, Podfile, and privacy manifest are present',
      () {
    final infoPlist = File('ios/Runner/Info.plist').readAsStringSync();
    final project =
        File('ios/Runner.xcodeproj/project.pbxproj').readAsStringSync();
    final podfile = File('ios/Podfile').readAsStringSync();
    final privacyManifest =
        File('ios/Runner/PrivacyInfo.xcprivacy').readAsStringSync();

    expect(
        project, contains('PRODUCT_BUNDLE_IDENTIFIER = com.the1807.hydrion'));
    expect(
        project,
        contains(
            'PRODUCT_BUNDLE_IDENTIFIER = com.the1807.hydrion.RunnerTests'));
    expect(infoPlist, contains('<string>Hydrion</string>'));
    expect(infoPlist, contains('NSLocationWhenInUseUsageDescription'));
    expect(infoPlist, contains('NSPhotoLibraryUsageDescription'));
    expect(podfile, contains("platform :ios, '13.0'"));
    expect(podfile, contains('flutter_install_all_ios_pods'));
    expect(privacyManifest, contains('NSPrivacyTracking'));
    expect(privacyManifest, contains('<false/>'));
    expect(
      privacyManifest,
      contains('NSPrivacyCollectedDataTypeLocationCoarse'),
    );
  });

  test('new asset folders are declared and generated filenames are removed',
      () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final humanRuntimeDirectory = Directory('assets/pfp_mascot/hpfp');
    final humanAssets = humanRuntimeDirectory.existsSync()
        ? humanRuntimeDirectory.listSync().whereType<File>().toList()
        : <File>[];
    final archivedHumanAssets = Directory(
      'assets_source_original/removed_runtime_assets/assets/pfp_mascot/hpfp',
    ).listSync().whereType<File>().toList();
    final uiAssets =
        Directory('assets/UI_BETA').listSync().whereType<File>().toList();
    final hydAdRuntimeDirectory = Directory('assets/UI_BETA/hyd-ad');

    expect(pubspec, contains('assets/UI_BETA/'));
    expect(pubspec, contains('assets/buffer/Shark.json'));
    expect(pubspec, isNot(contains('assets/buffer/Shark.lottie')));
    expect(pubspec, isNot(contains('assets/pfp_mascot/hpfp/')));
    expect(pubspec, contains('docs/Hydrion_Legal_Pack_Markdown/'));
    expect(hydAdRuntimeDirectory.existsSync(), isFalse);
    expect(humanAssets, isEmpty);
    expect(archivedHumanAssets, hasLength(19));
    expect(uiAssets, hasLength(33));
    expect(File('assets/UI_BETA/sunny.png').existsSync(), isFalse);
    expect(File('assets/UI_BETA/hot-summer.pnh').existsSync(), isFalse);
    expect(File('assets/UI_BETA/frontloader.png').existsSync(), isFalse);
    expect(
      uiAssets.map((file) => file.path.toLowerCase()),
      isNot(contains('frontloader')),
    );
    expect(
      uiAssets.map((file) => file.path.toLowerCase()),
      isNot(contains('hydration-bingo')),
    );
    for (final file in [...archivedHumanAssets, ...uiAssets]) {
      expect(file.path, isNot(contains('ChatGPT Image')));
      expect(file.path, isNot(contains(' ')));
    }
    for (final file in uiAssets) {
      expect(file.path, matches(RegExp(r'\.(png|jpg)$')));
      expect(file.path, isNot(contains('hydrion-lifestyle-')));
    }
    final mapped = <String>[];
    final ownersByAsset = <String, Set<String>>{};
    for (final challenge in HydrionChallengeCatalog.challenges) {
      final visual = ChallengeVisualRegistry.forId(challenge.id);
      for (final path in [
        visual.cardAsset,
        visual.neutralAsset,
        visual.maleAsset,
        visual.femaleAsset,
      ].whereType<String>()) {
        mapped.add(path);
        ownersByAsset.putIfAbsent(path, () => <String>{}).add(challenge.id);
      }
    }
    expect(mapped, isNotEmpty);
    expect(
      ownersByAsset.values.every((owners) => owners.length == 1),
      isTrue,
      reason: 'Artwork may serve multiple surfaces for one challenge but '
          'must not be shared across different challenges.',
    );
    for (final path in mapped) {
      expect(File(path).existsSync(), isTrue, reason: path);
    }
  });

  test('image asset filenames do not expose AI provider or generator names',
      () {
    final disallowedImageName = RegExp(
      r'(chatgpt|gemini|openai|dall[-_ ]?e|midjourney|stable[-_ ]?diffusion|generated[-_ ]?image|ai[-_ ]?generated)',
      caseSensitive: false,
    );
    final assetRoots = [
      Directory('assets'),
      Directory('assets_source_original'),
    ].where((directory) => directory.existsSync());

    for (final root in assetRoots) {
      final imageFiles = root
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => _isImageAsset(file.path));
      for (final file in imageFiles) {
        final fileName = file.uri.pathSegments.last;
        expect(
          disallowedImageName.hasMatch(fileName),
          isFalse,
          reason: file.path,
        );
      }
    }
  });

  test('Codemagic primary workflows are named, gated, and artifacted', () {
    final codemagic = File('codemagic.yaml').readAsStringSync();

    expect(codemagic, contains('hydrion-validation'));
    expect(codemagic, contains('hydrion-android'));
    expect(codemagic, contains('hydrion-ios-compatibility'));
    expect(codemagic, contains('hydrion-ios-signed-testflight-prep'));
    expect(codemagic, contains('flutter: 3.35.6'));
    expect(
      codemagic,
      contains('hydrion-android-debug-smoke.apk'),
    );
    expect(
      codemagic,
      contains('hydrion-android-ci-ephemeral-signed-release.apk'),
    );
    expect(
      codemagic,
      contains('hydrion-android-production-signed-release.aab'),
    );
    expect(codemagic, contains('--split-per-abi'));
    expect(codemagic, contains('hydrion-android-size-audit.txt'));
    expect(
      codemagic,
      contains('hydrion-ios-simulator-compatibility.app.zip'),
    );
    expect(
      codemagic,
      contains('hydrion-ios-production-signed-release.ipa'),
    );
    expect(codemagic, contains('HYDRION_SIGNED_IOS_ENABLED=true'));
    expect(codemagic, isNot(contains('SHOREBIRD_TOKEN')));
    expect(codemagic.toLowerCase(), isNot(contains('shorebird release')));
  });
}

bool _isImageAsset(String path) {
  final lower = path.toLowerCase();
  return lower.endsWith('.png') ||
      lower.endsWith('.jpg') ||
      lower.endsWith('.jpeg') ||
      lower.endsWith('.webp') ||
      lower.endsWith('.gif');
}
