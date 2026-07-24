import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrion/domain/challenge_catalog.dart';
import 'package:hydrion/domain/challenge_visual_registry.dart';
import 'package:hydrion/domain/profile_art_registry.dart';
import 'package:hydrion/domain/ui_asset_manifest.dart';
import 'package:hydrion/main.dart';
import 'package:hydrion/repositories/guided_tour_repository.dart';
import 'package:hydrion/repositories/settings_repository.dart';
import 'package:hydrion/storage/local_store.dart';
import 'package:hydrion/ui/components/guided_tour_overlay.dart';
import 'package:hydrion/ui/components/hydrion_system_ui.dart';
import 'package:provider/provider.dart';

String _assetName(ImageProvider provider) {
  final resolved = provider is ResizeImage ? provider.imageProvider : provider;
  return (resolved as AssetImage).assetName;
}

void main() {
  group('RC2 profile artwork contract', () {
    test('normalizes supported and legacy values without a Male default', () {
      expect(
        HydrionProfileArtResolver.presentationFor(HydrionSex.male),
        HydrionProfileArtPresentation.male,
      );
      expect(
        HydrionProfileArtResolver.presentationFor(HydrionSex.female),
        HydrionProfileArtPresentation.female,
      );
      expect(
        HydrionProfileArtResolver.presentationFor(HydrionSex.intersex),
        HydrionProfileArtPresentation.intersex,
      );
      for (final value in <Object?>[
        HydrionSex.preferNotToSay,
        null,
        'unknown-legacy-value',
        7,
      ]) {
        expect(
          HydrionProfileArtResolver.presentationFor(value),
          HydrionProfileArtPresentation.neutral,
          reason: '$value must be neutral',
        );
      }
    });

    test('missing variants fall back only to the neutral asset', () {
      const slot = HydrionProfileArtSlot(
        neutralAsset: 'neutral.png',
        maleAsset: 'male.png',
      );
      expect(
        HydrionProfileArtResolver.resolve(
          profileValue: HydrionSex.female,
          slot: slot,
        ),
        'neutral.png',
      );
      expect(
        HydrionProfileArtResolver.resolve(
          profileValue: HydrionSex.intersex,
          slot: slot,
        ),
        'neutral.png',
      );
      expect(
        HydrionProfileArtResolver.resolve(
          profileValue: 'unsupported',
          slot: slot,
        ),
        'neutral.png',
      );
    });

    test('every resolved lifestyle and challenge asset exists', () {
      const values = <Object?>[
        HydrionSex.male,
        HydrionSex.female,
        HydrionSex.intersex,
        HydrionSex.preferNotToSay,
        null,
        'legacy-unsupported',
      ];
      for (final surface in HydrionLifestyleSurface.values) {
        for (final value in values) {
          final scene = HydrionLifestyleArtResolver.sceneFor(
            surface: surface,
            sex: value,
          );
          expect(File(scene.assetPath).existsSync(), isTrue,
              reason: '${surface.name}: ${scene.assetPath}');
        }
      }
      for (final challenge in HydrionChallengeCatalog.challenges) {
        final visual = ChallengeVisualRegistry.forId(challenge.id);
        for (final value in values) {
          final asset = visual.dashboardAssetFor(value);
          expect(File(asset).existsSync(), isTrue,
              reason: '${challenge.id}: $asset');
        }
        if (visual.maleAsset != null && visual.femaleAsset != null) {
          expect(
            visual.dashboardAssetFor(HydrionSex.male),
            isNot(visual.dashboardAssetFor(HydrionSex.female)),
            reason: challenge.id,
          );
        }
      }
    });

    test('unknown persisted profile values reload as neutral', () async {
      final store = MemoryHydrionStore();
      await store.writeString(
        UserSettingsRepository.storageKey,
        jsonEncode({'languageCode': 'en', 'sex': 'retired-value'}),
      );
      final repository = await UserSettingsRepository.load(store);
      expect(repository.settings.sex, isNull);
      expect(
        HydrionLifestyleArtResolver.sceneFor(
          surface: HydrionLifestyleSurface.profile,
          sex: repository.settings.sex,
        ).id,
        'neutral-infusion',
      );
    });

    testWidgets('profile art renders and reacts immediately to profile edits',
        (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.reset);
      final services = HydrionServices.memory();

      await services.settingsRepository.setProfile(
        nickname: 'River',
        sex: HydrionSex.male,
      );
      await tester.pumpWidget(
        HydrionApp(services: services, initialRoute: '/profile'),
      );
      await tester.pumpAndSettle();

      String renderedAsset() {
        final image = tester.widget<Image>(
          find.byKey(const Key('profile-lifestyle-art')),
        );
        return _assetName(image.image);
      }

      expect(renderedAsset(), 'assets/UI_BETA/man-checking-app.png');
      await services.settingsRepository.setProfile(
        nickname: 'River',
        sex: HydrionSex.female,
      );
      await tester.pumpAndSettle();
      expect(renderedAsset(), 'assets/UI_BETA/workout-lady.png');

      await services.settingsRepository.setProfile(
        nickname: 'River',
        sex: HydrionSex.intersex,
      );
      await tester.pumpAndSettle();
      expect(renderedAsset(), 'assets/UI_BETA/pride/gender_icon.png');

      await services.settingsRepository.setProfile(
        nickname: 'River',
        sex: HydrionSex.preferNotToSay,
      );
      await tester.pumpAndSettle();
      expect(renderedAsset(), 'assets/UI_BETA/arounddworld.png');

      await services.settingsRepository.setProfile(nickname: 'River');
      await tester.pumpAndSettle();
      expect(renderedAsset(), 'assets/UI_BETA/arounddworld.png');
      expect(tester.takeException(), isNull);
    });

    testWidgets('home and progress use live profile artwork on phones',
        (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.reset);
      final services = HydrionServices.memory(
        guidedTourRepository: GuidedTourRepository.memory(completed: true),
      );
      await services.settingsRepository.setProfile(
        nickname: 'River',
        sex: HydrionSex.male,
      );
      await tester.pumpWidget(
        HydrionApp(services: services, initialRoute: '/home'),
      );
      await tester.pumpAndSettle();

      String renderedAsset(Key key) {
        final image = tester.widget<Image>(find.byKey(key));
        return _assetName(image.image);
      }

      await tester.scrollUntilVisible(
        find.byKey(const Key('home-profile-art')),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(
        renderedAsset(const Key('home-profile-art')),
        endsWith('men-goals.png'),
      );
      final navigationBar = tester.widget<NavigationBar>(
        find.byKey(const Key('hydrion-bottom-nav')),
      );
      navigationBar.onDestinationSelected?.call(2);
      await tester.pumpAndSettle();
      expect(
        renderedAsset(const Key('progress-profile-art')),
        endsWith('running-man.png'),
      );

      await services.settingsRepository.setProfile(
        nickname: 'River',
        sex: HydrionSex.female,
      );
      await tester.pumpAndSettle();
      navigationBar.onDestinationSelected?.call(0);
      await tester.pumpAndSettle();
      expect(
        renderedAsset(const Key('home-profile-art')),
        endsWith('drinking-lady.png'),
      );
      navigationBar.onDestinationSelected?.call(2);
      await tester.pumpAndSettle();
      expect(
        renderedAsset(const Key('progress-profile-art')),
        endsWith('running-lady.png'),
      );

      await services.settingsRepository.setProfile(
        nickname: 'River',
        sex: HydrionSex.intersex,
      );
      await tester.pumpAndSettle();
      navigationBar.onDestinationSelected?.call(0);
      await tester.pumpAndSettle();
      expect(
        renderedAsset(const Key('home-profile-art')),
        endsWith('pride-bottle.png'),
      );
      navigationBar.onDestinationSelected?.call(2);
      await tester.pumpAndSettle();
      expect(
        renderedAsset(const Key('progress-profile-art')),
        endsWith('be-proud.png'),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('challenge dashboard uses the same live profile resolver',
        (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.reset);
      final services = HydrionServices.memory(
        guidedTourRepository:
            GuidedTourRepository.memory(contextualToursCompleted: true),
      );
      await services.settingsRepository.setProfile(
        nickname: 'River',
        sex: HydrionSex.male,
      );
      final challenge = HydrionChallengeCatalog.byId('temperature-roulette');
      await services.challengeRepository.join(
        id: challenge.id,
        name: challenge.name,
        description: challenge.description,
        targetMl: 2200,
        durationDays: challenge.durationDays,
        parameters: const {
          'amountMl': 250,
          'weatherOrdering': 'disabled',
          'temperatureSchedule': [
            'Cool',
            'Room temperature',
            'Comfortably warm',
            'Cool',
            'Room temperature',
          ],
        },
      );
      await tester.pumpWidget(
        HydrionApp(services: services, initialRoute: '/home'),
      );
      await tester.pumpAndSettle();
      tester
          .widget<NavigationBar>(
            find.byKey(const Key('hydrion-bottom-nav')),
          )
          .onDestinationSelected
          ?.call(1);
      await tester.pumpAndSettle();
      final card = find.byKey(const Key('challenge-card-temperature-roulette'));
      await tester.scrollUntilVisible(
        card,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(card);
      await tester.pumpAndSettle();

      String renderedAsset() {
        final image = tester.widget<Image>(
          find.byKey(const Key('challenge-dashboard-art')),
        );
        return _assetName(image.image);
      }

      expect(renderedAsset(), endsWith('temp-roulette-man.png'));
      await services.settingsRepository.setProfile(
        nickname: 'River',
        sex: HydrionSex.female,
      );
      await tester.pumpAndSettle();
      expect(renderedAsset(), endsWith('temp-roulette-lady.png'));
      await services.settingsRepository.setProfile(
        nickname: 'River',
        sex: HydrionSex.intersex,
      );
      await tester.pumpAndSettle();
      expect(renderedAsset(), endsWith('temp-roulette.png'));
      expect(tester.takeException(), isNull);
    });
  });

  group('RC2 edge-to-edge and scroll contract', () {
    test('system overlays follow Day and Night themes', () {
      final day = HydrionSystemUi.styleFor(ThemeData.light());
      final night = HydrionSystemUi.styleFor(ThemeData.dark());
      expect(day.statusBarColor, Colors.transparent);
      expect(day.statusBarIconBrightness, Brightness.dark);
      expect(day.systemNavigationBarIconBrightness, Brightness.dark);
      expect(day.systemNavigationBarContrastEnforced, isFalse);
      expect(night.statusBarIconBrightness, Brightness.light);
      expect(night.systemNavigationBarIconBrightness, Brightness.light);
      expect(night.systemNavigationBarContrastEnforced, isFalse);
    });

    testWidgets('shell consumes top and bottom insets once', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.reset);
      const insets = EdgeInsets.only(top: 36, bottom: 24);
      final services = HydrionServices.memory(
        guidedTourRepository: GuidedTourRepository.memory(completed: true),
      );
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(390, 844),
            padding: insets,
            viewPadding: insets,
          ),
          child: HydrionApp(services: services, initialRoute: '/home'),
        ),
      );
      await tester.pumpAndSettle();

      final background =
          tester.getRect(find.byKey(const Key('hydrion-edge-background')));
      final navigationBackground = tester
          .getRect(find.byKey(const Key('hydrion-bottom-nav-background')));
      final navigation =
          tester.getRect(find.byKey(const Key('hydrion-bottom-nav')));
      final safeStack =
          tester.getRect(find.byKey(const Key('hydrion-tab-safe-stack')));
      expect(background.top, 0);
      expect(safeStack.top, 36);
      expect(background.bottom, navigationBackground.top);
      expect(navigationBackground.bottom, 844);
      expect(navigation.bottom, navigationBackground.bottom - 24);
      expect(tester.takeException(), isNull);
    });

    testWidgets('final profile card ends with only normal navigation spacing',
        (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(360, 640);
      addTearDown(tester.view.reset);
      final services = HydrionServices.memory(
        guidedTourRepository: GuidedTourRepository.memory(completed: true),
      );
      await tester.pumpWidget(
        HydrionApp(services: services, initialRoute: '/home'),
      );
      await tester.pumpAndSettle();
      tester
          .widget<NavigationBar>(
            find.byKey(const Key('hydrion-bottom-nav')),
          )
          .onDestinationSelected
          ?.call(3);
      await tester.pumpAndSettle();
      final finalCard = find.byKey(const Key('profile-support-card'));
      await tester.scrollUntilVisible(
        finalCard,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.drag(find.byType(ListView).first, const Offset(0, -900));
      await tester.pumpAndSettle();
      final navigationTop = tester
          .getTopLeft(find.byKey(const Key('hydrion-bottom-nav-background')))
          .dy;
      final gap = navigationTop - tester.getBottomLeft(finalCard).dy;
      expect(gap, inInclusiveRange(20, 36));
      expect(tester.takeException(), isNull);
    });
  });

  group('RC2 tutorial geometry and rendering', () {
    test('top, bottom, wide and obstructed targets never overlap the card', () {
      const viewport = Size(390, 844);
      const card = Size(350, 230);
      const padding = EdgeInsets.only(top: 32, bottom: 24);
      const obstruction = Rect.fromLTWH(0, 748, 390, 96);
      for (final target in const [
        Rect.fromLTWH(130, 80, 120, 48),
        Rect.fromLTWH(130, 360, 120, 48),
        Rect.fromLTWH(240, 760, 110, 60),
      ]) {
        final geometry = GuidedTourLayout.calculate(
          viewport: viewport,
          safePadding: padding,
          viewInsets: EdgeInsets.zero,
          cardSize: card,
          targetRect: target,
          obstructionRect: obstruction,
        );
        expect(geometry.cardRect.overlaps(geometry.spotlightRect!), isFalse,
            reason: '$target');
        expect(geometry.cardRect.top, greaterThanOrEqualTo(44));
        expect(
            geometry.cardRect.bottom, lessThanOrEqualTo(obstruction.top - 12));
      }

      final wide = GuidedTourLayout.calculate(
        viewport: const Size(1280, 800),
        safePadding: const EdgeInsets.all(8),
        viewInsets: EdgeInsets.zero,
        cardSize: const Size(400, 260),
        targetRect: const Rect.fromLTWH(500, 340, 120, 60),
        expanded: true,
      );
      expect(wide.cardRect.overlaps(wide.spotlightRect!), isFalse);
      expect(
        wide.placement,
        isIn([TourCardPlacement.left, TourCardPlacement.right]),
      );
    });

    for (final variant in <(String, bool, double, Alignment)>[
      ('Day top target', false, 1, const Alignment(0, -0.75)),
      ('Night bottom target', true, 1, const Alignment(0, 0.55)),
      ('Day large text', false, 1.8, const Alignment(0, -0.55)),
    ]) {
      testWidgets('${variant.$1} keeps readable content away from its target',
          (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(390, 844);
        addTearDown(tester.view.reset);
        final target = GlobalKey();
        final obstruction = GlobalKey();
        final repository = GuidedTourRepository.memory(completed: false);
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.light(),
            darkTheme: ThemeData.dark(),
            themeMode: variant.$2 ? ThemeMode.dark : ThemeMode.light,
            home: MediaQuery(
              data: MediaQueryData(
                size: const Size(390, 844),
                textScaler: TextScaler.linear(variant.$3),
                padding: const EdgeInsets.only(top: 24, bottom: 20),
                viewPadding: const EdgeInsets.only(top: 24, bottom: 20),
              ),
              child: ChangeNotifierProvider.value(
                value: repository,
                child: GuidedTourOverlay(
                  obstructionKey: obstruction,
                  steps: [
                    GuidedTourStep(
                      targetKey: target,
                      title: 'Review hydration',
                      body: 'This instruction remains readable and separate.',
                    ),
                  ],
                  child: Scaffold(
                    body: Stack(
                      children: [
                        Align(
                          alignment: variant.$4,
                          child: FilledButton(
                            key: target,
                            onPressed: () {},
                            child: const Text('Actual target'),
                          ),
                        ),
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: SizedBox(
                            key: obstruction,
                            height: 92,
                            width: double.infinity,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final cardRect = tester.getRect(find.byType(Card));
        final targetRect = tester.getRect(find.byKey(target));
        final obstructionRect = tester.getRect(find.byKey(obstruction));
        expect(find.text('Step 1 of 1'), findsOneWidget);
        expect(find.text('Review hydration'), findsOneWidget);
        expect(find.text('This instruction remains readable and separate.'),
            findsOneWidget);
        expect(find.text('Skip'), findsOneWidget);
        expect(find.text('Finish'), findsOneWidget);
        expect(cardRect.overlaps(targetRect), isFalse);
        expect(cardRect.bottom, lessThanOrEqualTo(obstructionRect.top - 12));
        expect(tester.takeException(), isNull);
      });
    }
  });
}
