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
      'assets/icons/icon1807.jpg',
    };

    expect(paths, hasLength(40));
    for (final path in paths) {
      expect(path, isNot(endsWith('.png')), reason: path);
      expect(path, isNot(contains('assets_source_original')));
      expect(File(path).existsSync(), isTrue, reason: path);
      expect(File(path).lengthSync(), lessThan(130000), reason: path);
    }
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
    expect(pubspec, isNot(contains('1000064425.mp4')));
    expect(pubspec, isNot(contains('icon1807.png')));
  });
}
