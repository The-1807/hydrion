import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hydrion/domain/avatar_manifest.dart';
import 'package:hydrion/domain/ui_asset_manifest.dart';

void main() {
  test('runtime asset registries point to optimized existing assets', () {
    final paths = <String>{
      HydrionAvatarManifest.mascotAssetPath,
      for (final avatar in HydrionAvatarManifest.avatars) avatar.assetPath,
      for (final scene in HydrionUiAssetManifest.lifestyleScenes)
        scene.assetPath,
      HydrionUiAssetManifest.successCheckAssetPath,
      'assets/icons/icon1807.jpg',
    };

    expect(HydrionAvatarManifest.humanAvatars, isEmpty);
    for (final path in paths) {
      expect(path, isNot(contains('assets_source_original')));
      expect(File(path).existsSync(), isTrue, reason: path);
      expect(File(path).lengthSync(), greaterThan(0), reason: path);
    }

    for (final scene in HydrionUiAssetManifest.lifestyleScenes) {
      expect(scene.assetPath, endsWith('.png'), reason: scene.id);
      expect(
        _pngColorType(scene.assetPath),
        anyOf(3, 4, 6),
        reason: scene.assetPath,
      );
    }
    expect(
      _pngColorType(HydrionUiAssetManifest.successCheckAssetPath),
      anyOf(2, 6),
    );
  });

  test('runtime identifiers are unique and stale source assets stay unbundled',
      () {
    expect(
      HydrionAvatarManifest.avatars.map((avatar) => avatar.id).toSet(),
      hasLength(HydrionAvatarManifest.avatars.length),
    );
    expect(
      HydrionUiAssetManifest.lifestyleScenes.map((scene) => scene.id).toSet(),
      hasLength(HydrionUiAssetManifest.lifestyleScenes.length),
    );

    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, isNot(contains('assets_source_original')));
    expect(pubspec, isNot(contains('assets/pfp_mascot/hpfp/')));
    expect(pubspec, isNot(contains('1000064425.mp4')));
    expect(pubspec, isNot(contains('icon1807.png')));
    expect(pubspec, isNot(contains('hydrion-lifestyle-')));
  });
}

int _pngColorType(String path) {
  final bytes = File(path).readAsBytesSync();
  expect(bytes.take(8), [137, 80, 78, 71, 13, 10, 26, 10], reason: path);
  return bytes[25];
}
