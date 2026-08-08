import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrion/l10n/app_localizations.dart';
import 'package:hydrion/repositories/settings_repository.dart';
import 'package:hydrion/storage/local_store.dart';
import 'package:hydrion/ui/components/recognition_moment.dart';

void main() {
  test('recognition event can be claimed exactly once across restart',
      () async {
    final store = MemoryHydrionStore();
    final first = await UserSettingsRepository.load(store);
    expect(await first.claimRecognition('daily-goal:2026-07-30'), isTrue);
    expect(await first.claimRecognition('daily-goal:2026-07-30'), isFalse);

    final second = await UserSettingsRepository.load(store);
    expect(await second.claimRecognition('daily-goal:2026-07-30'), isFalse);
  });

  testWidgets('recognition retains equivalent text with reduced motion',
      (tester) async {
    final repository = UserSettingsRepository.memory();
    late BuildContext context;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (value) {
              context = value;
              return const Scaffold(body: Text('Ready'));
            },
          ),
        ),
      ),
    );

    expect(
      await RecognitionMoment.showOnce(
        context,
        repository: repository,
        eventId: 'challenge-day:test',
        message: 'Today’s challenge activity is complete.',
      ),
      isTrue,
    );
    await tester.pump();
    expect(
      find.text('Today’s challenge activity is complete.'),
      findsOneWidget,
    );
    expect(
      await RecognitionMoment.showOnce(
        context,
        repository: repository,
        eventId: 'challenge-day:test',
        message: 'Today’s challenge activity is complete.',
      ),
      isFalse,
    );
  });
}
