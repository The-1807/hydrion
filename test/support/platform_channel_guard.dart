import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Routes every outgoing platform message in tests.
///
/// Mocked channels reach their mock handler; framework (`flutter/…`) channels
/// keep the default test engine behaviour; every other channel fails
/// immediately with a [MissingPluginException] naming the channel and method,
/// and is recorded so the test can be failed by `flutter_test_config.dart`.
abstract final class PlatformChannelGuard {
  static final List<String> _unmocked = <String>[];
  static bool _installed = false;

  static void install() {
    if (_installed) return;
    _installed = true;
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.allMessagesHandler = (channel, handler, message) {
      if (handler != null) return handler(message);
      if (channel.startsWith('flutter/')) {
        return messenger.delegate.send(channel, message);
      }
      final call = '$channel#${_methodName(message)}';
      _unmocked.add(call);
      return Future<ByteData?>.error(MissingPluginException(
        'No test mock handler for platform channel $call.',
      ));
    };
  }

  static void reset() => _unmocked.clear();

  /// Returns and clears the unmocked calls recorded since the last reset.
  static List<String> takeUnmockedCalls() {
    final calls = List<String>.of(_unmocked);
    _unmocked.clear();
    return calls;
  }

  static String _methodName(ByteData? message) {
    if (message == null) return '?';
    try {
      return const StandardMethodCodec().decodeMethodCall(message).method;
    } catch (_) {
      try {
        return const JSONMethodCodec().decodeMethodCall(message).method;
      } catch (_) {
        return '?';
      }
    }
  }
}
