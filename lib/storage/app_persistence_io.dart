import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'app_database_key_store.dart';
import 'encrypted_app_store.dart';
import 'protected_app_store.dart';

Future<ProtectedAppStore> openProtectedAppStore({
  Directory? supportDirectory,
  AppDatabaseKeyStore? keyStore,
}) async {
  if (defaultTargetPlatform != TargetPlatform.android &&
      defaultTargetPlatform != TargetPlatform.iOS) {
    return const UnavailableProtectedAppStore();
  }
  try {
    final support = supportDirectory ?? await getApplicationSupportDirectory();
    final directory = Directory('${support.path}/protected_app');
    final path = '${directory.path}/app.db';
    // Listing a present directory must succeed before absence permits a key.
    // Sidecars also count as existing encrypted material after an interruption.
    final parentEntries = await support.list(followLinks: false).toList();
    final matches = parentEntries.where((entry) =>
        entry.uri.pathSegments.where((e) => e.isNotEmpty).last ==
        'protected_app');
    if (matches.isNotEmpty && matches.single is! Directory) {
      return const UnavailableProtectedAppStore(ProtectedReadStatus.corrupt);
    }
    final entries = matches.isNotEmpty
        ? await directory.list(followLinks: false).toList()
        : <FileSystemEntity>[];
    final exists = entries.any((e) {
      final name = e.uri.pathSegments.where((s) => s.isNotEmpty).last;
      return name == 'app.db' || name.startsWith('app.db-');
    });
    final key = await (keyStore ?? AppDatabaseKeyStore())
        .obtain(databaseExists: exists);
    if (key.status != AppDatabaseKeyStatus.available) {
      return UnavailableProtectedAppStore(
          key.status == AppDatabaseKeyStatus.unsupported
              ? ProtectedReadStatus.unsupported
              : ProtectedReadStatus.unavailable);
    }
    // Never initialize over orphaned encrypted sidecars.
    if (exists && !await File(path).exists()) {
      return const UnavailableProtectedAppStore(ProtectedReadStatus.corrupt);
    }
    await directory.create(recursive: true);
    return await EncryptedAppStore.open(path: path, key: key.key!);
  } on AppStoreOpenFailure catch (error) {
    return UnavailableProtectedAppStore(error.status);
  } catch (_) {
    return const UnavailableProtectedAppStore(ProtectedReadStatus.unavailable);
  }
}
