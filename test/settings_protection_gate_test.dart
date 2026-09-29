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

void main() {
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
