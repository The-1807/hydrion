import 'dart:convert';
import 'dart:io';

const enabledLocales = ['en', 'fr', 'es'];
const deferredLocales = ['pt_BR', 'de'];

void main() {
  final root = Directory.current;
  final templateFile = File('${root.path}/lib/l10n/app_en.arb');
  if (!templateFile.existsSync()) {
    stderr.writeln('Run this audit from the Hydrion repository root.');
    exitCode = 2;
    return;
  }
  final template = _messages(templateFile);
  var failed = false;
  stdout.writeln('Required Flutter messages: ${template.length}');
  for (final locale in enabledLocales) {
    final file = File('${root.path}/lib/l10n/app_$locale.arb');
    if (!file.existsSync()) {
      stdout.writeln('$locale: missing ARB (${template.length} missing keys)');
      failed = true;
      continue;
    }
    final messages = _messages(file);
    final missing = template.difference(messages);
    final extra = messages.difference(template);
    stdout.writeln(
      '$locale: ${messages.length}/${template.length}; '
      'missing=${missing.length}; extra=${extra.length}',
    );
    if (missing.isNotEmpty) {
      stdout.writeln('  missing: ${missing.take(20).join(', ')}');
      failed = true;
    }
  }
  for (final locale in deferredLocales) {
    final file = File('${root.path}/lib/l10n/app_$locale.arb');
    final messages = file.existsSync() ? _messages(file).length : 0;
    stdout.writeln(
      '$locale: deferred and hidden; $messages/${template.length} messages',
    );
  }

  final nativeFiles = {
    'en': 'android/app/src/main/res/values/strings.xml',
    'fr': 'android/app/src/main/res/values-fr/strings.xml',
    'es': 'android/app/src/main/res/values-es/strings.xml',
    'pt_BR': 'android/app/src/main/res/values-pt-rBR/strings.xml',
    'de': 'android/app/src/main/res/values-de/strings.xml',
  };
  final nativeTemplate = _androidNames(File(nativeFiles['en']!));
  stdout.writeln('Required Android messages: ${nativeTemplate.length}');
  for (final entry in nativeFiles.entries.where(
    (entry) => enabledLocales.contains(entry.key),
  )) {
    final file = File(entry.value);
    if (!file.existsSync()) {
      stdout.writeln('${entry.key}: missing Android resources');
      failed = true;
      continue;
    }
    final names = _androidNames(file);
    final missing = nativeTemplate.difference(names);
    stdout.writeln(
      '${entry.key}: Android ${names.length}/${nativeTemplate.length}; '
      'missing=${missing.length}',
    );
    if (missing.isNotEmpty) failed = true;
  }
  for (final locale in deferredLocales) {
    final file = File(nativeFiles[locale]!);
    final names = file.existsSync() ? _androidNames(file).length : 0;
    stdout.writeln(
      '$locale: Android deferred and hidden; '
      '$names/${nativeTemplate.length} resources',
    );
  }
  if (failed) exitCode = 1;
}

Set<String> _messages(File file) {
  final value = jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
  return value.keys
      .where((key) => !key.startsWith('@') && key != '@@locale')
      .toSet();
}

Set<String> _androidNames(File file) {
  if (!file.existsSync()) return {};
  return RegExp(r'<string\s+name="([^"]+)"')
      .allMatches(file.readAsStringSync())
      .map((match) => match.group(1)!)
      .toSet();
}
