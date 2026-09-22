import 'dart:convert';
import 'dart:io';

const _locales = ['fr', 'es'];

// These French labels have the same spelling as English; Spanish must still
// translate them. Keep language-specific exceptions out of the global list.
const _localeIdenticalAllowlist = <String, Set<String>>{
  'fr': {'reportsDate', 'reportsPage'},
};

// Values whose spelling intentionally does not change across supported locales.
const _identicalValueAllowlist = <String>{
  'appTitle',
  'baselineMlValue',
  'capabilityStatus',
  'centimetresLabel',
  'coachPreviewTitle',
  'coachReplyMessageLabel',
  'coachRoute',
  'dailyGoalRange',
  'documentVersion',
  'elkaProvider',
  'geminiProvider',
  'healthDataAppleHealth',
  'healthDataDistance',
  'healthDataHealthConnect',
  'kilogramsLabel',
  'logSourceTimestamp',
  'messageLabel',
  'no',
  'pauseAction',
  'poundsLabel',
  'relativeDateTime',
  'reportsDate',
  'reportsPage',
  'suggestionDelayValue',
  'suggestionDetailVolume',
  'suggestionVolumeValue',
  'volumeMlValue',
};

// French and Spanish express the disabled state grammatically and do not need
// the English-only verb fragment supplied by this legacy template.
const _placeholderExceptionKeys = {'savedLocallySyncDisabled'};

void main() {
  final english = _messages(File('lib/l10n/app_en.arb'));
  var failed = false;

  for (final locale in _locales) {
    final localized = _messages(File('lib/l10n/app_$locale.arb'));
    final identical = <String>[];
    final placeholderDrift = <String>[];
    for (final entry in english.entries) {
      final translated = localized[entry.key];
      if (translated == null) continue;
      if (translated == entry.value &&
          _containsWords(entry.value) &&
          !_identicalValueAllowlist.contains(entry.key) &&
          !(_localeIdenticalAllowlist[locale]?.contains(entry.key) ?? false)) {
        identical.add(entry.key);
      }
      if (!_placeholderExceptionKeys.contains(entry.key) &&
          !_samePlaceholders(entry.value, translated)) {
        placeholderDrift.add(entry.key);
      }
    }
    stdout.writeln(
      '$locale: identical=${identical.length}; '
      'placeholderDrift=${placeholderDrift.length}',
    );
    if (identical.isNotEmpty) {
      stdout.writeln('  identical: ${identical.join(', ')}');
      failed = true;
    }
    if (placeholderDrift.isNotEmpty) {
      stdout.writeln('  placeholder drift: ${placeholderDrift.join(', ')}');
      failed = true;
    }
  }

  if (failed) exitCode = 1;
}

Map<String, String> _messages(File file) {
  final json = jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
  return {
    for (final entry in json.entries)
      if (!entry.key.startsWith('@') && entry.value is String)
        entry.key: entry.value! as String,
  };
}

bool _containsWords(String value) => RegExp(r'[A-Za-z]').hasMatch(
      value.replaceAll(RegExp(r'\{[A-Za-z_]\w*\}'), ''),
    );

bool _samePlaceholders(String english, String localized) {
  Set<String> placeholders(String value) => RegExp(r'\{([A-Za-z_]\w*)\}')
      .allMatches(value)
      .map((match) => match.group(1)!)
      .toSet();
  final source = placeholders(english);
  final target = placeholders(localized);
  return source.length == target.length && source.containsAll(target);
}
