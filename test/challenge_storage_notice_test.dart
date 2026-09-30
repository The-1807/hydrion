import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:hydrion/l10n/app_localizations.dart';
import 'package:hydrion/repositories/challenge_repository.dart';
import 'package:hydrion/storage/local_store.dart';
import 'package:hydrion/storage/protected_app_store.dart';
import 'package:hydrion/ui/screens/social_challenges_screen.dart';
import 'package:hydrion/ui/components/challenge_storage_notice.dart';

import 'support/memory_protected_app_store.dart';

void main() {
  for (final language in ['en', 'fr', 'es']) {
    testWidgets(
        '$language does not display an unknown store as an empty challenge list',
        (tester) async {
      final repo = await ChallengeRepository.load(MemoryHydrionStore(),
          protectedStore: const UnavailableProtectedAppStore());
      await tester.pumpWidget(ChangeNotifierProvider.value(
          value: repo,
          child: MaterialApp(
              locale: Locale(language),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: const SocialChallengesScreen())));
      await tester.pumpAndSettle();
      expect(find.byType(ChallengeStorageNotice), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);
      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pumpAndSettle();
      expect(repo.storageStatus, ChallengeStorageStatus.unsupported);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets(
      'retry restores protected storage and deletion stays explicitly pending',
      (tester) async {
    final store = MemoryProtectedAppStore()
      ..challengeReadFailure = ProtectedReadStatus.unavailable;
    final repo = await ChallengeRepository.load(MemoryHydrionStore(),
        protectedStore: store);
    await tester.pumpWidget(ChangeNotifierProvider.value(
        value: repo,
        child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: ChallengeStorageNotice())));
    await tester.pumpAndSettle();
    store.challengeReadFailure = null;
    await tester.tap(find.byIcon(Icons.refresh));
    await tester.pumpAndSettle();
    expect(repo.isKnown, isTrue);
    store.challengeWriteFailure = ProtectedWriteStatus.failed;
    await expectLater(
        repo.clear(), throwsA(isA<ChallengeStorageUnavailable>()));
    await tester.pumpAndSettle();
    expect(
        find.text(
            'Challenge deletion is incomplete. Retry to finish local cleanup.'),
        findsOneWidget);
    expect(repo.isKnown, isFalse);
    expect(tester.takeException(), isNull);
  });
}
