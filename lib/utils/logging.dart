import 'package:flutter/foundation.dart';

class Log {
  static void i(String message) => debugPrint('[INFO] $message');

  static void w(String message) => debugPrint('[WARN] $message');

  static void e(String message) => debugPrint('[ERROR] $message');
}
