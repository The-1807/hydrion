import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrion/l10n/app_localizations.dart';
import 'package:hydrion/repositories/app_locale_repository.dart';
import 'package:hydrion/repositories/settings_repository.dart';
import 'package:hydrion/repositories/settings_protection.dart';
import 'package:hydrion/services/profile_photo_service.dart';
import 'package:hydrion/storage/local_store.dart';
import 'package:hydrion/storage/protected_app_store.dart';
import 'package:hydrion/ui/components/settings_protection_gate.dart';
import 'package:provider/provider.dart';
import 'package:hydrion/adapters/local/local_hydrion_adapters.dart';
import 'package:hydrion/domain/hydration_contracts.dart';
import 'package:hydrion/repositories/reminder_repository.dart';
import 'package:hydrion/ui/screens/profile_screen.dart';

import 'support/memory_protected_app_store.dart';
import 'support/profile_photo_fixture.dart';

class ProfileSaveFaultStore extends MemoryHydrionStore {
  int? failAt;
  int writes = 0;
  bool throwFailure = false;
  @override
  Future<bool> writeString(String key, String value) async {
    if (key == SettingsProtection.storageKey && ++writes == failAt) {
      if (throwFailure) throw StateError('synthetic persistence failure');
      return false;
    }
    return super.writeString(key, value);
  }
}

void main() {
  for (final fault in [0, 1, 2, 3, 4, 5, 6, 7]) {
    testWidgets('M2 compound profile save retains failure at operation $fault',
        (tester) async {
      tester.view.physicalSize = const Size(1000, 3000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final prefs = ProfileSaveFaultStore();
      final db = MemoryProtectedAppStore();
      final repo = (await tester.runAsync(() async {
        final result =
            await UserSettingsRepository.load(prefs, protectedStore: db);
        await result.setProfile(nickname: 'SYNTHETIC');
        return result;
      }))!;
      await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider<UserSettingsRepository>.value(value: repo),
          ChangeNotifierProvider(create: (_) => ReminderRepository.memory()),
          Provider<AppCapabilityReporter>(
              create: (_) => LocalAppCapabilityReporter()),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ProfileScreen(),
        ),
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('profile-edit-action')));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.byKey(const Key('profile-edit-nickname')), 'NEW-SYNTHETIC');
      tester
          .widget<DropdownButtonFormField<String>>(
              find.byType(DropdownButtonFormField<String>))
          .onChanged!('superhappy_shark');
      final fields = find.descendant(
          of: find.byKey(const Key('profile-editor-list')),
          matching: find.byType(TextField));
      await tester.enterText(fields.at(1), '2800');
      await tester.enterText(fields.at(2), '650');
      await tester.pump();
      prefs
        ..writes = 0
        ..failAt = fault
        ..throwFailure = fault == 3;
      if (fault == 7) {
        db.settingsWriteFailure = ProtectedWriteStatus.unavailable;
      }
      final save = tester
          .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Save profile'))
          .onPressed!;
      await tester.runAsync(() async {
        await (save as Future<void> Function())();
      });
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      if (fault == 0) {
        expect(find.byKey(const Key('profile-editor-list')), findsNothing);
        expect(repo.settings.dailyGoalMl, 2800);
        return;
      }
      expect(find.byKey(const Key('profile-editor-list')), findsOneWidget);
      expect(find.textContaining('Some profile changes'), findsOneWidget);
      final feedback = tester
          .widget<Text>(find.textContaining('Some profile changes'))
          .data!;
      expect(feedback, isNot(contains('NEW-SYNTHETIC')));
      if (fault < 7) expect(prefs.writes, 6);
      if (fault == 2) {
        expect(repo.settings.avatarId, isNot('superhappy_shark'));
        expect(repo.settings.dailyGoalMl, 2800);
        expect(repo.settings.containerSizeMl, 650);
      }
      prefs.failAt = null;
      await tester.runAsync(() async {
        db.settingsWriteFailure = null;
        await repo.retryProtection();
        await (save as Future<void> Function())();
      });
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('profile-editor-list')), findsNothing);
      expect(repo.settings.nickname, 'NEW-SYNTHETIC');
      expect(repo.settings.avatarId, 'superhappy_shark');
      expect(repo.settings.dailyGoalMl, 2800);
      expect(repo.settings.containerSizeMl, 650);
    });
  }

  Future<void> pumpGate(WidgetTester tester, UserSettingsRepository repo,
      HydrionProfilePhotoPicker picker) async {
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider<UserSettingsRepository>.value(value: repo),
        ChangeNotifierProvider(create: (_) => AppLocaleRepository.memory()),
        Provider<HydrionProfilePhotoPicker>.value(value: picker),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: SettingsProtectionGate(child: Text('trusted-profile-screen')),
      ),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets(
      'unavailable profile hides consumers but exposes retry and config',
      (tester) async {
    final repo = await UserSettingsRepository.load(MemoryHydrionStore(),
        protectedStore: const UnavailableProtectedAppStore());
    await pumpGate(tester, repo, FakeHydrionProfilePhotoPicker());
    expect(find.text('trusted-profile-screen'), findsNothing);
    expect(find.byIcon(Icons.refresh), findsOneWidget);
    expect(find.byType(DropdownButton<HydrionThemePreference>), findsOneWidget);
    expect(find.byType(DropdownButton<String>), findsOneWidget);
    expect(repo.isKnown, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('invalid legacy photo survives until explicit valid reselection',
      (tester) async {
    final raw = jsonEncode(
        const UserSettings(locale: Locale('en'), nickname: 'synthetic')
            .copyWith(profilePhotoBase64: 'not-base64')
            .toJson());
    final prefs = MemoryHydrionStore({SettingsProtection.storageKey: raw});
    final db = MemoryProtectedAppStore();
    late UserSettingsRepository repo;
    late FakeHydrionProfilePhotoPicker picker;
    await tester.runAsync(() async {
      repo = await UserSettingsRepository.load(prefs, protectedStore: db);
      picker = FakeHydrionProfilePhotoPicker(await syntheticPng(20, 20));
    });
    await pumpGate(tester, repo, picker);
    expect(find.text('trusted-profile-screen'), findsNothing);
    expect(prefs.snapshot[SettingsProtection.storageKey], raw);
    final button = tester.widget<OutlinedButton>(find.byType(OutlinedButton));
    expect(repo.protectionStatus, SettingsProtectionStatus.invalidLegacyPhoto);
    await tester.runAsync(() async {
      await (button.onPressed! as Future<void> Function())();
    });
    await tester.pumpAndSettle();
    expect(repo.isKnown, isTrue);
    expect(repo.settings.nickname, 'synthetic');
    expect(find.text('trusted-profile-screen'), findsOneWidget);
    expect(db.settingsRecord!.photo!.bytes, picker.nextPhoto!.bytes);
    expect(jsonDecode(prefs.snapshot[SettingsProtection.storageKey]!) as Map,
        isNot(contains('profilePhotoBase64')));
    expect(tester.takeException(), isNull);
  });

  testWidgets('protected photo renders through repository after reload',
      (tester) async {
    final prefs = MemoryHydrionStore();
    final db = MemoryProtectedAppStore();
    late UserSettingsRepository repo;
    await tester.runAsync(() async {
      final writer =
          await UserSettingsRepository.load(prefs, protectedStore: db);
      expect(await writer.setProfilePhotoBytes(await syntheticPng(20, 20)),
          isTrue);
      repo = await UserSettingsRepository.load(prefs, protectedStore: db);
    });
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider<UserSettingsRepository>.value(value: repo),
        ChangeNotifierProvider(create: (_) => ReminderRepository.memory()),
        Provider<AppCapabilityReporter>(
            create: (_) => LocalAppCapabilityReporter()),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ProfileScreen(),
      ),
    ));
    await tester.pumpAndSettle();
    final photo = tester.widget<Image>(find.descendant(
      of: find.byKey(const Key('profile-photo-avatar')),
      matching: find.byType(Image),
    ));
    expect(photo.image, isA<MemoryImage>());
    expect((photo.image as MemoryImage).bytes, db.settingsRecord!.photo!.bytes);
    expect(repo.isKnown, isTrue);
    expect(tester.takeException(), isNull);
  });
}
