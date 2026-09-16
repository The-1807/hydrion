import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrion/l10n/app_localizations.dart';
import 'package:hydrion/repositories/health_data_repository.dart';
import 'package:hydrion/services/health_connection_controller.dart';
import 'package:hydrion/services/health_data_sync_coordinator.dart';
import 'package:hydrion/services/health_kit_provider.dart';
import 'package:hydrion/storage/local_store.dart';
import 'package:hydrion/ui/screens/health_data_connection_screen.dart';
import 'package:provider/provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Apple Health consent is explicit and starts only by user action',
      (tester) async {
    final bridge = _HealthKitScreenBridge();
    final controller = await _pumpScreen(tester, bridge);

    expect(find.textContaining('Apple Health'), findsOneWidget);
    expect(find.textContaining('read-only access'), findsOneWidget);
    expect(find.textContaining('encrypted on this device'), findsOneWidget);
    expect(bridge.permissionRequests, 0);

    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('health-data-connect')));
    await tester.pumpAndSettle();

    expect(bridge.permissionRequests, 1);
    expect(controller.isConnected, isTrue);
    expect(
      find.textContaining('cannot display which read categories'),
      findsOneWidget,
    );
  });

  testWidgets('empty Apple Health query stays truthful and offers retry',
      (tester) async {
    final bridge = _HealthKitScreenBridge();
    final controller = await _pumpScreen(tester, bridge);
    await controller.connect();
    final result = await controller.synchronize();
    await tester.pumpAndSettle();

    expect(result.importedCount, 0);
    expect(
      controller.state,
      HealthConnectionViewState.synchronizedNoRecords,
    );
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.textContaining('no readable workout'), findsOneWidget);
    expect(find.textContaining('read access was not allowed'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
    expect(find.text('Manage access'), findsOneWidget);
  });
}

Future<HealthConnectionController> _pumpScreen(
  WidgetTester tester,
  _HealthKitScreenBridge bridge,
) async {
  final repository = MemoryHealthDataRepository();
  final provider = AppleHealthKitProvider(
    bridge: bridge,
    clock: () => DateTime.utc(2026, 9, 15, 12),
  );
  final controller = HealthConnectionController(
    provider: provider,
    coordinator: HealthDataSyncCoordinator(
      providers: [provider],
      repository: repository,
      clock: () => DateTime.utc(2026, 9, 15, 12),
    ),
    repository: repository,
    store: MemoryHydrionStore(),
    clock: () => DateTime.utc(2026, 9, 15, 12),
  );
  await controller.initialize();
  await tester.pumpWidget(
    ChangeNotifierProvider.value(
      value: controller,
      child: const MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: HealthDataConnectionScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return controller;
}

class _HealthKitScreenBridge implements HealthKitBridge {
  int permissionRequests = 0;
  bool requestCompleted = false;

  @override
  Future<Map<String, Object?>> invoke(
    String method, [
    Map<String, Object?> arguments = const {},
  ]) async =>
      switch (method) {
        'availability' => {'available': true},
        'authorizationState' => {
            'requestStatus': requestCompleted ? 'unnecessary' : 'shouldRequest',
          },
        'requestPermissions' => _completeRequest(),
        'readAnchored' => {
            'schemaVersion': 1,
            'records': <Object?>[],
            'anchor': 'empty-anchor',
            'hasMore': false,
          },
        _ => throw UnimplementedError(method),
      };

  Map<String, Object?> _completeRequest() {
    permissionRequests += 1;
    requestCompleted = true;
    return {'requestStatus': 'unnecessary'};
  }

  @override
  Future<void> openSettings() async {}
}
