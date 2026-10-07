import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/app_locale_channel_fake.dart';
import 'support/platform_channel_guard.dart';

/// Applied by `flutter test` to every file under test/.
///
/// * Platform channels without a mock handler fail fast with a descriptive
///   [MissingPluginException] instead of waiting on a real engine reply, which
///   never arrives inside a widget test's fake-async zone (the historical
///   startup/onboarding hangs). Any such call also fails the test, so a test
///   must inject a fake adapter (`test/support/test_services.dart`) or mock
///   the channel explicitly.
/// * Hydrion's own `hydrion/app_locale` channel gets a documented default
///   fake ([AppLocaleChannelFake]); plugin channels get none.
/// * Process-wide caches that outlive a test (the root asset bundle) are
///   cleared between tests so results do not depend on test order.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  PlatformChannelGuard.install();

  setUp(() {
    rootBundle.clear();
    PlatformChannelGuard.reset();
    AppLocaleChannelFake.install();
  });
  tearDown(() {
    rootBundle.clear();
    final unmocked = PlatformChannelGuard.takeUnmockedCalls();
    if (unmocked.isNotEmpty) {
      fail(
        'Unmocked platform channel call(s): ${unmocked.join(', ')}. Inject a '
        'fake adapter (test/support/test_services.dart) or mock the channel.',
      );
    }
  });

  await testMain();
}

