import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hydrion/domain/avatar_manifest.dart';
import 'package:hydrion/domain/ui_asset_manifest.dart';
import 'package:hydrion/repositories/settings_repository.dart';

void main() {
  test('profile sex selection maps to lifestyle presentation only', () {
    expect(
      HydrionLifestyleArtResolver.presentationFor(HydrionSex.male),
      HydrionLifestylePresentation.male,
    );
    expect(
      HydrionLifestyleArtResolver.presentationFor(HydrionSex.female),
      HydrionLifestylePresentation.female,
    );
    expect(
      HydrionLifestyleArtResolver.presentationFor(HydrionSex.intersex),
      HydrionLifestylePresentation.neutral,
    );
    expect(
      HydrionLifestyleArtResolver.presentationFor(
        HydrionSex.preferNotToSay,
      ),
      HydrionLifestylePresentation.neutral,
    );
    expect(
      HydrionLifestyleArtResolver.presentationFor(null),
      HydrionLifestylePresentation.neutral,
    );
  });

  test('lifestyle resolver returns stable scene defaults for every surface',
      () {
    expect(
      HydrionLifestyleArtResolver.sceneFor(
        surface: HydrionLifestyleSurface.profile,
        sex: HydrionSex.male,
      ).id,
      'app-check',
    );
    expect(
      HydrionLifestyleArtResolver.sceneFor(
        surface: HydrionLifestyleSurface.profile,
        sex: HydrionSex.female,
      ).id,
      'studio-bottle',
    );
    expect(
      HydrionLifestyleArtResolver.sceneFor(
        surface: HydrionLifestyleSurface.profile,
        sex: HydrionSex.intersex,
      ).id,
      'blue-kit',
    );
    expect(
      HydrionLifestyleArtResolver.sceneFor(
        surface: HydrionLifestyleSurface.profile,
        sex: HydrionSex.preferNotToSay,
      ).id,
      'blue-kit',
    );
    expect(
      HydrionLifestyleArtResolver.sceneFor(
        surface: HydrionLifestyleSurface.profile,
        sex: null,
      ).id,
      'blue-kit',
    );

    for (final sex in <HydrionSex?>[
      HydrionSex.male,
      HydrionSex.female,
      HydrionSex.intersex,
      HydrionSex.preferNotToSay,
      null,
    ]) {
      final rail = HydrionLifestyleArtResolver.homeRailScenes(sex);
      expect(rail, hasLength(4));
      expect(rail.map((scene) => scene.id).toSet(), hasLength(4));
      for (final scene in rail) {
        expect(File(scene.assetPath).existsSync(), isTrue);
      }
    }
  });

  test('manual profile avatar selection remains independent', () {
    final human = HydrionAvatarManifest.byId('hydrion-human-river');
    final shark = HydrionAvatarManifest.byId('superhappy_shark');

    expect(human.kind, HydrionAvatarKind.human);
    expect(shark.kind, HydrionAvatarKind.shark);
    expect(
      HydrionAvatarManifest.companionByProfileAvatarId(human.id).id,
      'savvy-eco_shark',
    );
    expect(
      HydrionAvatarManifest.companionByProfileAvatarId(shark.id).id,
      shark.id,
    );
  });
}
