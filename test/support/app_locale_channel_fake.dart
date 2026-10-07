import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Default fake for Hydrion's own `hydrion/app_locale` Android channel,
/// installed before every test by `flutter_test_config.dart`.
///
/// It models an Android host with no per-app locale override: reads return
/// [applicationLocale] (null by default, so the saved Hydrion locale stays
/// authoritative) and writes are recorded. A test that needs other platform
/// behaviour installs its own handler, which replaces this one for that test.
abstract final class AppLocaleChannelFake {
  static const channel = MethodChannel('hydrion/app_locale');

  /// Reply to `getApplicationLocale`, e.g. `{'usesDeviceLocale': false,
  /// 'languageTag': 'fr'}`.
  static Map<String, Object?>? applicationLocale;
  static final List<MethodCall> calls = <MethodCall>[];

  static void install() {
    applicationLocale = null;
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return call.method == 'getApplicationLocale' ? applicationLocale : null;
    });
  }
}
