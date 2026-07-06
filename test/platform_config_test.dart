import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

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
    final humanAssets =
        Directory('assets/pfp_mascot/hpfp').listSync().whereType<File>();
    final uiAssets = Directory('assets/UI_BETA').listSync().whereType<File>();

    expect(pubspec, contains('assets/UI_BETA/'));
    expect(pubspec, contains('assets/pfp_mascot/hpfp/'));
    expect(pubspec, contains('docs/Hydrion_Legal_Pack_Markdown/'));
    expect(humanAssets, hasLength(19));
    expect(uiAssets, hasLength(9));
    for (final file in [...humanAssets, ...uiAssets]) {
      expect(file.path, isNot(contains('ChatGPT Image')));
      expect(file.path, isNot(contains(' ')));
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
