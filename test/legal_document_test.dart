import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:hydrion/domain/legal_document_registry.dart';
import 'package:hydrion/domain/release_metadata.dart';
import 'package:hydrion/main.dart';
import 'package:hydrion/repositories/settings_repository.dart';
import 'package:hydrion/services/location_service.dart';
import 'package:hydrion/services/notifications.dart';
import 'package:hydrion/storage/local_store.dart';
import 'package:hydrion/ui/screens/legal_about_screen.dart';
import 'package:provider/provider.dart';

void main() {
  test('registered legal documents have unique metadata and real files', () {
    final ids = <String>{};
    final routes = <String>{};

    for (final document in HydrionLegalDocumentRegistry.documents) {
      expect(document.id.trim(), isNotEmpty);
      expect(ids.add(document.id), isTrue, reason: document.id);
      expect(document.title.trim(), isNotEmpty);
      expect(document.version, matches(RegExp(r'^\d+\.\d+\.\d+$')));
      expect(routes.add(document.routeName), isTrue, reason: document.id);
      expect(
          document.assetPath, startsWith('docs/Hydrion_Legal_Pack_Markdown/'));
      expect(File(document.assetPath).existsSync(), isTrue);

      final metadata =
          _frontMatter(File(document.assetPath).readAsStringSync());
      expect(metadata['document_id'], document.id);
      expect(metadata['title'], contains(document.title.split(' ').first));
      expect(metadata['version'], document.version);
      expect(DateTime.tryParse(metadata['effective_date'] ?? ''), isNotNull);
      expect(DateTime.tryParse(metadata['last_updated'] ?? ''), isNotNull);
    }
  });

  test('user-facing legal documents are clean and internal docs stay internal',
      () {
    final userFacing =
        HydrionLegalDocumentRegistry.userFacingDocuments.toList();
    final internal = HydrionLegalDocumentRegistry.internalDocuments.toList();

    expect(userFacing.map((document) => document.id), [
      'terms',
      'privacy',
      'health',
      'beta',
    ]);
    expect(internal.map((document) => document.id), [
      'internal_publish_note',
      'internal_drafting_references',
    ]);

    final prohibited = [
      'TODO',
      'FIXME',
      'INSERT COMPANY',
      'COMPANY NAME',
      'YOUR ADDRESS',
      'YOUR EMAIL',
      'EXAMPLE.COM',
      'TBD',
      'LOREM IPSUM',
      '[OPERATOR',
      '[SUPPORT',
      '[EFFECTIVE',
    ];

    for (final document in userFacing) {
      final contents = File(document.assetPath).readAsStringSync();
      final upper = contents.toUpperCase();
      for (final pattern in prohibited) {
        expect(
          upper,
          isNot(contains(pattern)),
          reason: '${document.id} contains $pattern',
        );
      }
    }
  });

  test('legal acceptance policy distinguishes material version changes', () {
    expect(
      HydrionLegalAcceptancePolicy.needsReview(
        onboardingCompleted: true,
        acceptedTermsVersion:
            HydrionLegalAcceptancePolicy.requiredTermsAcceptanceVersion,
        acknowledgedHealthDisclaimerVersion:
            HydrionLegalAcceptancePolicy.requiredHealthAcknowledgementVersion,
      ),
      isFalse,
    );
    expect(
      HydrionLegalAcceptancePolicy.needsReview(
        onboardingCompleted: true,
        acceptedTermsVersion:
            HydrionLegalAcceptancePolicy.requiredTermsAcceptanceVersion,
        acknowledgedHealthDisclaimerVersion:
            HydrionLegalAcceptancePolicy.requiredHealthAcknowledgementVersion,
        requiredTermsVersion: '2.0.0',
      ),
      isTrue,
    );
    expect(
      HydrionLegalAcceptancePolicy.needsReview(
        onboardingCompleted: true,
        acceptedTermsVersion: '2.0.0',
        acknowledgedHealthDisclaimerVersion:
            HydrionLegalAcceptancePolicy.requiredHealthAcknowledgementVersion,
        requiredTermsVersion: '2.0.0',
      ),
      isFalse,
      reason: 'same acceptance version represents a nonmaterial content change',
    );
  });

  test('ordinary build configuration does not require Shorebird', () {
    final ordinaryBuildFiles = [
      'codemagic.yaml',
      '.github/workflows/flutter-ci.yml',
      'pubspec.yaml',
      'scripts/build_release.sh',
      'scripts/test_all.sh',
      'scripts/lint_all.sh',
    ];

    for (final path in ordinaryBuildFiles) {
      final file = File(path);
      if (!file.existsSync()) {
        continue;
      }
      final contents = file.readAsStringSync().toLowerCase();
      expect(contents, isNot(contains('shorebird_token')), reason: path);
      expect(contents, isNot(contains('shorebird release')), reason: path);
      expect(contents, isNot(contains('shorebird patch')), reason: path);
      expect(contents, isNot(contains('shorebird init')), reason: path);
    }
  });

  testWidgets('legal hub renders, opens docs, licenses, and hides internals',
      (tester) async {
    await _pumpLegalApp(tester);

    expect(find.text('About & Legal'), findsOneWidget);
    expect(find.text('Terms of Use'), findsOneWidget);
    expect(find.text('Privacy Policy'), findsOneWidget);
    expect(find.text('Health and Safety Disclaimer'), findsOneWidget);
    expect(find.text('Alpha and Beta Testing Notice'), findsOneWidget);
    expect(find.text('Read Before Publishing'), findsNothing);

    await tester.tap(find.byKey(const Key('legal-document-tile-terms')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('legal-document-terms')), findsOneWidget);
    expect(find.text('Hydrion Terms of Use'), findsOneWidget);
    final markdown = tester.widget<Markdown>(
      find.byKey(const Key('legal-document-terms')),
    );
    expect(markdown.noScroll, isFalse);
    expect(markdown.data.length, greaterThan(3000));
    expect(markdown.data, contains('## Contact'));

    Navigator.of(
      tester.element(find.byKey(const Key('legal-document-terms'))),
    ).pop();
    await tester.pumpAndSettle();
    final licenses = find.byKey(const Key('legal-open-source-licenses'));
    await tester.scrollUntilVisible(
      licenses,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(licenses);
    await tester.pumpAndSettle();
    expect(find.byType(LicensePage), findsOneWidget);
  });

  testWidgets('legal screens render in dark theme and large text',
      (tester) async {
    await _pumpLegalApp(
      tester,
      themeMode: ThemeMode.dark,
      textScaler: const TextScaler.linear(1.6),
      home: const LegalDocumentScreen(documentId: 'health'),
    );

    await tester.pumpAndSettle();
    expect(find.byKey(const Key('legal-document-health')), findsOneWidget);
    expect(find.text('Hydrion Health and Safety Disclaimer'), findsOneWidget);
  });

  testWidgets('missing legal document fails safely', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: LegalDocumentScreen(documentId: 'missing')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Document unavailable'), findsOneWidget);
  });

  testWidgets('legal checkbox is blocked until document version is opened',
      (tester) async {
    await _pumpLegalPanel(tester);

    tester
        .widget<CheckboxListTile>(
          find.byKey(const Key('onboarding-terms-accept')),
        )
        .onChanged
        ?.call(true);
    await tester.pump();

    expect(
      tester
          .widget<CheckboxListTile>(
            find.byKey(const Key('onboarding-terms-accept')),
          )
          .value,
      isFalse,
    );
    expect(find.text('fahhhhhhh!!! open legal pack'), findsOneWidget);
    expect(find.text('Terms of Use opened'), findsNothing);
  });

  testWidgets('opening a legal document does not check acceptance',
      (tester) async {
    await _pumpLegalPanel(tester);

    final termsOpener = tester
        .widget<OutlinedButton>(find.byKey(const Key('legal-open-terms')));
    expect(termsOpener.onPressed, isNotNull);
    termsOpener.onPressed!();
    await _pumpUntilFound(
      tester,
      find.byKey(const Key('legal-document-shell-terms')),
    );
    expect(find.byKey(const Key('legal-document-shell-terms')), findsOneWidget);
    await tester.pageBack();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Terms of Use opened'), findsOneWidget);
    expect(
      tester
          .widget<CheckboxListTile>(
            find.byKey(const Key('onboarding-terms-accept')),
          )
          .value,
      isFalse,
    );

    tester
        .widget<CheckboxListTile>(
          find.byKey(const Key('onboarding-terms-accept')),
        )
        .onChanged
        ?.call(true);
    await tester.pump();
    expect(
      tester
          .widget<CheckboxListTile>(
            find.byKey(const Key('onboarding-terms-accept')),
          )
          .value,
      isTrue,
    );
  });

  testWidgets('production legal gate uses restrained copy', (tester) async {
    await _pumpLegalPanel(
      tester,
      buildStage: HydrionBuildStage.production,
    );

    tester
        .widget<CheckboxListTile>(
          find.byKey(const Key('onboarding-health-ack')),
        )
        .onChanged
        ?.call(true);
    await tester.pump();

    expect(
      find.text('Open the required legal document before continuing.'),
      findsOneWidget,
    );
    expect(find.text('fahhhhhhh!!! open legal pack'), findsNothing);
  });

  testWidgets('legal review never requests platform permissions',
      (tester) async {
    final store = MemoryHydrionStore();
    await store.writeString(
      UserSettingsRepository.storageKey,
      jsonEncode({
        'languageCode': 'en',
        'dailyGoalMl': 2200,
        'onboardingCompleted': true,
        'legalAndHealthAcknowledged': true,
      }),
    );
    final locationService = FakeHydrionLocationService(
      permission: HydrionLocationPermissionState.denied,
    );
    final notificationAdapter = FakeHydrionNotificationAdapter(
      permission: HydrionNotificationPermissionState.denied,
    );
    final services = await HydrionServices.fromStore(
      store,
      locationService: locationService,
      notificationAdapter: notificationAdapter,
    );

    await tester.pumpWidget(HydrionApp(services: services));
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();

    expect(find.text('Review Hydrion terms'), findsOneWidget);
    await tester.tap(find.byKey(const Key('legal-open-health')));
    await tester.pump(const Duration(milliseconds: 400));

    expect(locationService.requestCount, 0);
    expect(notificationAdapter.requestCount, 0);
  });
}

Future<void> _pumpLegalApp(
  WidgetTester tester, {
  ThemeMode themeMode = ThemeMode.light,
  TextScaler textScaler = TextScaler.noScaling,
  Widget home = const LegalAboutScreen(),
}) async {
  final repository = UserSettingsRepository.memory();
  await tester.pumpWidget(
    ChangeNotifierProvider<UserSettingsRepository>.value(
      value: repository,
      child: MaterialApp(
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        themeMode: themeMode,
        routes: {
          for (final document
              in HydrionLegalDocumentRegistry.userFacingDocuments)
            document.routeName: (_) =>
                LegalDocumentScreen(documentId: document.id),
        },
        home: MediaQuery(
          data: MediaQueryData(textScaler: textScaler),
          child: home,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpLegalPanel(
  WidgetTester tester, {
  HydrionBuildStage buildStage = HydrionBuildStage.alpha,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      routes: {
        for (final document in HydrionLegalDocumentRegistry.userFacingDocuments)
          document.routeName: (_) =>
              LegalDocumentScreen(documentId: document.id),
      },
      home: _LegalPanelHarness(buildStage: buildStage),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 5),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) {
      return;
    }
  }
}

class _LegalPanelHarness extends StatefulWidget {
  final HydrionBuildStage buildStage;

  const _LegalPanelHarness({required this.buildStage});

  @override
  State<_LegalPanelHarness> createState() => _LegalPanelHarnessState();
}

class _LegalPanelHarnessState extends State<_LegalPanelHarness> {
  bool termsAccepted = false;
  bool healthAcknowledged = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          LegalAcceptancePanel(
            termsAccepted: termsAccepted,
            healthAcknowledged: healthAcknowledged,
            buildStage: widget.buildStage,
            onTermsChanged: (value) {
              setState(() => termsAccepted = value);
            },
            onHealthChanged: (value) {
              setState(() => healthAcknowledged = value);
            },
          ),
        ],
      ),
    );
  }
}

Map<String, String> _frontMatter(String markdown) {
  final match = RegExp(r'^---\s*\n([\s\S]*?)\n---').firstMatch(markdown);
  expect(match, isNotNull);
  final metadata = <String, String>{};
  for (final line in match!.group(1)!.split('\n')) {
    final separator = line.indexOf(':');
    if (separator <= 0) {
      continue;
    }
    metadata[line.substring(0, separator).trim()] =
        line.substring(separator + 1).trim();
  }
  return metadata;
}
