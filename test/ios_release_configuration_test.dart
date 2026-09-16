// Pure file-based configuration checks for the iOS Xcode project.
//
// These do not require a macOS/Xcode toolchain to run, so they execute in
// ordinary `flutter test` (including on CI runners that only have the
// Android/web toolchain). They exist to catch the specific class of defect
// where the HydrionWidgets extension's bundle metadata drifts from the
// Runner host app — previously the cause of a broken simulator install.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:yaml/yaml.dart';

void main() {
  final repoRoot = Directory.current.path;
  final pbxprojFile = File('$repoRoot/ios/Runner.xcodeproj/project.pbxproj');
  final runnerEntitlementsFile = File(
    '$repoRoot/ios/Runner/Runner.entitlements',
  );
  final widgetsEntitlementsFile = File(
    '$repoRoot/ios/HydrionWidgets/HydrionWidgets.entitlements',
  );
  final widgetInfoFile = File('$repoRoot/ios/HydrionWidgets/Info.plist');
  final runnerInfoFile = File('$repoRoot/ios/Runner/Info.plist');
  final appDelegateFile = File('$repoRoot/ios/Runner/AppDelegate.swift');
  final healthKitHostFile = File('$repoRoot/ios/Runner/HealthKitHost.swift');
  final pubspecFile = File('$repoRoot/pubspec.yaml');

  late String pbxproj;
  late String expectedBuildNumber;
  late String expectedVersionName;

  setUpAll(() {
    pbxproj = pbxprojFile.readAsStringSync();
    final pubspec = loadYaml(pubspecFile.readAsStringSync()) as YamlMap;
    final version = (pubspec['version'] as String).split('+');
    expectedVersionName = version[0];
    expectedBuildNumber = version.length > 1 ? version[1] : '1';
  });

  group('iOS Xcode project configuration', () {
    test(
        'Runner and HydrionWidgets bundle identifiers use the expected '
        'namespace', () {
      expect(
        pbxproj,
        contains('PRODUCT_BUNDLE_IDENTIFIER = com.the1807.hydrion;'),
      );
      expect(
        pbxproj,
        contains('PRODUCT_BUNDLE_IDENTIFIER = com.the1807.hydrion.widgets;'),
      );
    });

    test(
        'HydrionWidgets extension declares an sdk-pinned build number '
        'matching pubspec.yaml, so it does not rely on FLUTTER_BUILD_NUMBER '
        'resolving inside the extension target', () {
      final pinned = RegExp(
        r'"CURRENT_PROJECT_VERSION\[sdk=\*\]"\s*=\s*(\S+);',
      ).allMatches(pbxproj).map((m) => m.group(1)).toSet();
      expect(
        pinned,
        isNotEmpty,
        reason: 'Expected at least one sdk-pinned CURRENT_PROJECT_VERSION '
            'override for the widget extension targets.',
      );
      for (final value in pinned) {
        expect(
          value,
          expectedBuildNumber,
          reason: 'HydrionWidgets CURRENT_PROJECT_VERSION[sdk=*] ($value) '
              'must match the build number in pubspec.yaml '
              '($expectedBuildNumber). A mismatch here is the exact class '
              'of defect that previously broke simulator installs.',
        );
      }
    });

    test(
        'HydrionWidgets extension declares an sdk-pinned marketing '
        'version matching pubspec.yaml', () {
      final pinned = RegExp(
        r'"MARKETING_VERSION\[sdk=\*\]"\s*=\s*(\S+);',
      ).allMatches(pbxproj).map((m) => m.group(1)).toSet();
      expect(pinned, isNotEmpty);
      for (final value in pinned) {
        expect(value, expectedVersionName);
      }
    });

    test('Runner and HydrionWidgets both target the same App Group', () {
      final runnerGroups = _appGroups(runnerEntitlementsFile);
      final widgetGroups = _appGroups(widgetsEntitlementsFile);
      expect(runnerGroups, isNotEmpty);
      expect(widgetGroups, isNotEmpty);
      expect(
        widgetGroups,
        runnerGroups,
        reason: 'Runner and HydrionWidgets must share the exact same App '
            'Group set, or shared hydration state cannot cross the process '
            'boundary between the app and the widget extension.',
      );
      expect(runnerGroups, contains('group.com.the1807.hydrion'));
    });

    test('HydrionWidgets target is declared as a widget extension', () {
      expect(pbxproj, contains('productName = HydrionWidgets;'));
    });

    test('HydrionWidgets source plist declares installable extension metadata',
        () {
      final plist = widgetInfoFile.readAsStringSync();
      for (final key in <String>[
        'CFBundleIdentifier',
        'CFBundleExecutable',
        'CFBundlePackageType',
        'CFBundleShortVersionString',
        'CFBundleVersion',
        'NSExtensionPointIdentifier',
      ]) {
        expect(plist, contains('<key>$key</key>'));
      }
      expect(plist, contains('<string>XPC!</string>'));
      expect(plist, contains('<string>com.apple.widgetkit-extension</string>'));
    });

    test(
        'every app and widget build configuration explicitly supports the '
        'home_widget Swift package minimum iOS version', () {
      final deploymentTargets = RegExp(
        r'IPHONEOS_DEPLOYMENT_TARGET\s*=\s*14\.0;',
      ).allMatches(pbxproj);

      expect(
        deploymentTargets,
        hasLength(9),
        reason: 'Runner, the Xcode project, and HydrionWidgets must each pin '
            'Debug, Release, and Profile to iOS 14.0. A missing Runner target '
            'override lets Xcode resolve the home-widget consumer as iOS 13.',
      );
    });

    test('Runner declares a read-only HealthKit integration', () {
      final entitlements = runnerEntitlementsFile.readAsStringSync();
      final info = runnerInfoFile.readAsStringSync();
      final appDelegate = appDelegateFile.readAsStringSync();
      final healthKitHost = healthKitHostFile.readAsStringSync();

      expect(entitlements, contains('com.apple.developer.healthkit'));
      expect(info, contains('<key>NSHealthShareUsageDescription</key>'));
      expect(info, isNot(contains('NSHealthUpdateUsageDescription')));
      expect(healthKitHost, contains('requestAuthorization(toShare: [],'));
      expect(healthKitHost, isNot(contains('store.save(')));
      expect(appDelegate, contains('HealthKitHost(messenger:'));
      expect(pbxproj, contains('HealthKitHost.swift in Sources'));
      expect(pbxproj, contains('InfoPlist.strings in Resources'));
      for (final locale in ['en', 'fr', 'es']) {
        final localized = File(
          '$repoRoot/ios/Runner/$locale.lproj/InfoPlist.strings',
        ).readAsStringSync();
        expect(localized, contains('NSHealthShareUsageDescription'));
        expect(
          localized,
          anyOf(
            contains('workout'),
            contains('entrainements'),
            contains('entrenamientos'),
          ),
        );
      }
    });

    test('HealthKit capability remains isolated from the widget extension', () {
      expect(
        widgetsEntitlementsFile.readAsStringSync(),
        isNot(contains('com.apple.developer.healthkit')),
      );
      expect(
        widgetInfoFile.readAsStringSync(),
        isNot(contains('NSHealthShareUsageDescription')),
      );
    });
  });
}

Set<String> _appGroups(File entitlementsFile) {
  final xml = entitlementsFile.readAsStringSync();
  final matches = RegExp(r'<string>(group\.[^<]+)</string>').allMatches(xml);
  return matches.map((m) => m.group(1)!).toSet();
}
