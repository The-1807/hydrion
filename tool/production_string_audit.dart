import 'dart:convert';
import 'dart:io';

enum ProductionStringClassification {
  userFacing('A'),
  accessibility('B'),
  properName('C'),
  stableIdentifier('D'),
  platformConstant('E'),
  diagnostic('F'),
  testFixture('G'),
  formattingValue('H'),
  falsePositive('I');

  const ProductionStringClassification(this.code);
  final String code;
}

class ProductionStringFinding {
  const ProductionStringFinding({
    required this.source,
    required this.lineStart,
    required this.lineEnd,
    required this.symbol,
    required this.expression,
    required this.classification,
    required this.resolved,
    required this.resolution,
    this.allowlistReason,
  });

  final String source;
  final int lineStart;
  final int lineEnd;
  final String symbol;
  final String expression;
  final ProductionStringClassification classification;
  final bool resolved;
  final String resolution;
  final String? allowlistReason;

  Map<String, Object?> toJson() => {
        'source': source.replaceAll('\\', '/'),
        'lineStart': lineStart,
        'lineEnd': lineEnd,
        'symbol': symbol,
        'expression': expression,
        'classification': classification.code,
        'resolved': resolved,
        'resolution': resolution,
        'allowlistReason': allowlistReason,
      };
}

class _StringToken {
  const _StringToken(this.start, this.end, this.value, this.source);
  final int start;
  final int end;
  final String value;
  final String source;
}

const _technicalValues = {'mL', 'oz'};
const _properNames = {'Hydrion', 'HYDRION'};
const _languagePickerAutonyms = {
  'Choisissez votre langue',
  'Elige tu idioma',
  r'Puedes cambiar esta opci\u00f3n m\u00e1s tarde en Ajustes.',
  'Choose your language',
  'You can change this later in Settings.',
  r'Vous pourrez modifier ce choix plus tard dans les r\u00e9glages.',
  r'Utiliser la langue de l\u2019appareil',
  'Usar el idioma del dispositivo',
  'Continuer',
  'Continuar',
  r'Enregistrement\u2026',
  r'Guardando\u2026',
};
const _unusedLegacyBottleBingoCopy = {
  'Before lunch',
  'Log water before noon.',
  'Refill ritual',
  'Refill your usual bottle once.',
  'Flavor swap',
  'Try citrus, mint, cucumber, or plain.',
  'Desk reset',
  'Place water where your hand lands.',
  'Tiny sip',
  'Take a small comfortable sip.',
  'Evening ease',
  'Slow down before bed; no forcing.',
  'Reset board',
};

final _visibleContext = RegExp(
  r'(?:\bText\s*\(|\bSelectableText\s*\(|\bSnackBar\s*\(|'
  r'\bAlertDialog\s*\(|\bTooltip\s*\(|\bSemantics\s*\(|'
  r'\b(?:semanticLabel|semanticsLabel|labelText|helperText|hintText|tooltip|'
  r'message|title|subtitle|body|content|label|description|purpose|actions|'
  r'whatCounts|whatDoesNotCount|schedule|setupSummary|safetyMessage)\s*:\s*|'
  r'(?:\breturn|=>)\s*)$',
  multiLine: true,
);

final _accessibilityContext = RegExp(
  r'(?:semanticLabel|semanticsLabel|tooltip|message)\s*:\s*$',
  multiLine: true,
);

List<ProductionStringFinding> scanDartSource(
  String source, {
  required String path,
}) {
  final normalizedPath = path.replaceAll('\\', '/');
  if (normalizedPath.startsWith('test/') || normalizedPath.contains('/test/')) {
    return const [];
  }
  final tokens = _combineAdjacentStrings(source, _tokenizeStrings(source));
  final indirectRanges = _indirectVisibleRanges(source);
  final visibleHelpers = _visibleHelperNames(source);
  final findings = <ProductionStringFinding>[];
  final domainLayer = normalizedPath.startsWith('lib/services/') ||
      normalizedPath.startsWith('lib/repositories/') ||
      normalizedPath.startsWith('lib/adapters/');
  for (final token in tokens) {
    if (!_containsWords(token.value)) continue;
    final prefixStart = token.start > 240 ? token.start - 240 : 0;
    final prefix = source.substring(prefixStart, token.start);
    final indirectlyVisible = indirectRanges.any(
      (range) => token.start >= range.$1 && token.end <= range.$2,
    );
    final directlyVisible = _visibleContext.hasMatch(prefix) ||
        (domainLayer && _looksLikeCompleteSentence(token.value));
    late final String symbol;
    if (!directlyVisible && !indirectlyVisible) {
      if (visibleHelpers.isEmpty) continue;
      symbol = _containingSymbol(source, token.start);
      if (!visibleHelpers.contains(symbol)) continue;
    } else {
      symbol = _containingSymbol(source, token.start);
    }
    final accessibility = _accessibilityContext.hasMatch(prefix);
    findings.add(_classify(
      path,
      source,
      token,
      accessibility
          ? ProductionStringClassification.accessibility
          : ProductionStringClassification.userFacing,
    ));
  }
  final rawDiagnosticFlow = RegExp(
    r'(?:Text\s*\(|SelectableText\s*\(|semanticLabel\s*:\s*|'
    r'message\s*:\s*)\s*(?:(?:error|exception|failure|caught|stackTrace)\w*\.(?:toString\s*\(\)|message\b|stackTrace\b)|'
    r'[^;\n]*\$\{?(?:error|exception|stackTrace)\b)',
    multiLine: true,
  );
  for (final match in rawDiagnosticFlow.allMatches(source)) {
    findings.add(ProductionStringFinding(
      source: path,
      lineStart: _lineAt(source, match.start),
      lineEnd: _lineAt(source, match.end),
      symbol: _containingSymbol(source, match.start),
      expression: match.group(0)!.trim(),
      classification: ProductionStringClassification.userFacing,
      resolved: false,
      resolution:
          'Map the diagnostic to a stable typed result and localized safe copy.',
    ));
  }
  return findings;
}

Set<String> _visibleHelperNames(String source) {
  final names = <String>{};
  final visibleCall = RegExp(
    r'(?:\bText\s*\(|\bSelectableText\s*\(|(?:label|title|subtitle|body|content|message|semanticLabel)\s*:\s*)\s*([A-Za-z_]\w*)\s*\(',
    multiLine: true,
  );
  for (final match in visibleCall.allMatches(source)) {
    names.add(match.group(1)!);
  }
  return names;
}

List<(int, int)> _indirectVisibleRanges(String source) {
  final names = <String>{};
  final visibleReference = RegExp(
    r'(?:\bText\s*\(|\bSelectableText\s*\(|(?:label|title|subtitle|body|content|message|semanticLabel)\s*:\s*)\s*([A-Za-z_]\w*)\s*(?:\[|\.)',
    multiLine: true,
  );
  for (final match in visibleReference.allMatches(source)) {
    names.add(match.group(1)!);
  }

  final ranges = <(int, int)>[];
  for (final name in names) {
    final declaration = RegExp(
      '(?:final|const|var|List<[^>]+>|Map<[^>]+>)\\s+${RegExp.escape(name)}'
      r'\s*=\s*',
      multiLine: true,
    ).firstMatch(source);
    if (declaration == null) continue;
    final end = source.indexOf(';', declaration.end);
    if (end >= 0) ranges.add((declaration.start, end + 1));
  }
  return ranges;
}

List<ProductionStringFinding> scanAndroidResourceCoverage({
  required String english,
  required String french,
  required String spanish,
  String source = 'android/app/src/main/res/values/strings.xml',
}) {
  Set<String> names(String xml) => RegExp(r'<string\s+name="([^"]+)"')
      .allMatches(xml)
      .map((match) => match.group(1)!)
      .toSet();

  final englishNames = names(english);
  final frenchNames = names(french);
  final spanishNames = names(spanish);
  final findings = <ProductionStringFinding>[];
  for (final name in englishNames) {
    final missing = <String>[
      if (!frenchNames.contains(name)) 'fr',
      if (!spanishNames.contains(name)) 'es',
    ];
    if (missing.isEmpty) continue;
    final offset = english.indexOf('name="$name"');
    findings.add(ProductionStringFinding(
      source: source,
      lineStart: _lineAt(english, offset),
      lineEnd: _lineAt(english, offset),
      symbol: name,
      expression: name,
      classification: ProductionStringClassification.userFacing,
      resolved: false,
      resolution: 'Add the Android resource to: ${missing.join(', ')}.',
    ));
  }
  return findings;
}

List<ProductionStringFinding> scanAndroidSource(
  String source, {
  required String path,
}) {
  final findings = <ProductionStringFinding>[];
  for (final token
      in _combineAdjacentStrings(source, _tokenizeStrings(source))) {
    if (!_containsWords(token.value)) continue;
    final prefixStart = token.start > 180 ? token.start - 180 : 0;
    final prefix = source.substring(prefixStart, token.start);
    if (!RegExp(
      r'(?:setContentText|setContentTitle|setTicker|Toast\.makeText|'
      r'contentDescription\s*=|text\s*=)\s*\(?\s*$',
      multiLine: true,
    ).hasMatch(prefix)) {
      continue;
    }
    findings.add(_classify(
      path,
      source,
      token,
      ProductionStringClassification.userFacing,
    ));
  }
  return findings;
}

List<ProductionStringFinding> scanAndroidXmlSource(
  String source, {
  required String path,
}) {
  final findings = <ProductionStringFinding>[];
  final hardcodedAttribute = RegExp(
    r'''android:(?:text|hint|contentDescription)\s*=\s*(["'])(?!@string/)(.*?)\1''',
    dotAll: true,
  );
  for (final match in hardcodedAttribute.allMatches(source)) {
    final value = match.group(2)!.trim();
    if (!_containsWords(value)) continue;
    final token = _StringToken(match.start, match.end, value, match.group(0)!);
    findings.add(_classify(
      path,
      source,
      token,
      match.group(0)!.contains('contentDescription')
          ? ProductionStringClassification.accessibility
          : ProductionStringClassification.userFacing,
    ));
  }
  return findings;
}

ProductionStringFinding _classify(
  String path,
  String source,
  _StringToken token,
  ProductionStringClassification defaultClassification,
) {
  final value = token.value.trim();
  final diagnosticContextStart = token.start > 180 ? token.start - 180 : 0;
  final diagnosticContext =
      source.substring(diagnosticContextStart, token.start);
  final healthBoundaryFile =
      path.endsWith('encrypted_health_data_repository.dart') ||
          path.endsWith('health_data_repository.dart') ||
          path.endsWith('android_health_provider_discovery.dart') ||
          path.endsWith('health_connect_provider.dart') ||
          path.endsWith('health_kit_provider.dart');
  final healthMachineIdentifier = value == 'serviceName' ||
      value == 'historyEnd' ||
      value.startsWith('SELECT * FROM health_') ||
      value.startsWith('DELETE FROM health_');
  if (healthBoundaryFile && healthMachineIdentifier) {
    return _finding(
        path,
        source,
        token,
        ProductionStringClassification.stableIdentifier,
        true,
        'Health storage or platform-channel identifier.',
        allowlistReason:
            'This value is used only for SQL or structured platform-channel lookup and is never rendered.');
  }
  if (healthBoundaryFile &&
      (value.startsWith('HealthRepositoryOpenException(') ||
          diagnosticContext.contains('throw ') ||
          diagnosticContext.contains('ArgumentError(') ||
          diagnosticContext.contains('StateError('))) {
    return _finding(
        path,
        source,
        token,
        ProductionStringClassification.diagnostic,
        true,
        'Typed health-boundary diagnostic.',
        allowlistReason:
            'The connection controller catches provider and persistence failures and exposes only stable codes mapped to localized safe copy; exception text is never rendered.');
  }
  if (path.endsWith('hydration_report_pdf.dart') &&
      (value == 'x' || value.startsWith(r'x ${labels.'))) {
    return _finding(
        path,
        source,
        token,
        ProductionStringClassification.formattingValue,
        true,
        'Locale-neutral missing-data chart marker.',
        allowlistReason:
            'The x is a chart symbol; its adjacent missing-data label is localized.');
  }
  if ((path.endsWith('gemini_adapter.dart') &&
          (diagnosticContext.contains('GeminiProviderException(') ||
              diagnosticContext.contains('GeminiProviderUnavailable('))) ||
      (path.endsWith('weather_goal_service.dart') &&
          diagnosticContext.contains('WeatherProviderException(')) ||
      (path.endsWith('reminder_repository.dart') &&
          diagnosticContext.contains('ArgumentError.value(')) ||
      (path.endsWith('notifications.dart') &&
          diagnosticContext.contains('ArgumentError.value('))) {
    return _finding(
        path,
        source,
        token,
        ProductionStringClassification.diagnostic,
        true,
        'Typed developer exception context.',
        allowlistReason:
            'This text is carried only by a provider or argument exception; production result mapping drops exception text and exposes stable typed states.');
  }
  if (path.endsWith('elka_adapter.dart') &&
      source.indexOf('const ElkaAdapterShell.unconfigured') <= token.start &&
      token.start < source.indexOf('bool get isConfigured')) {
    return _finding(
        path,
        source,
        token,
        ProductionStringClassification.diagnostic,
        true,
        'Unconfigured adapter diagnostic.',
        allowlistReason:
            'The shell reason is used only as UnsupportedError context; the production coach falls back through typed provider health and never renders it.');
  }
  if (path.endsWith('hydration_ai_orchestrator.dart') &&
      source.indexOf('userQuery:') <= token.start &&
      token.start < source.indexOf('if (actions.isNotEmpty)', token.start)) {
    return _finding(
        path,
        source,
        token,
        ProductionStringClassification.diagnostic,
        true,
        'Machine-facing provider prompt.',
        allowlistReason:
            'This structured English request is sent to the selected model and is never rendered, announced, notified, persisted as history, or exported.');
  }
  if (path.endsWith('reminder_feedback_presenter.dart')) {
    return _finding(
        path,
        source,
        token,
        ProductionStringClassification.userFacing,
        true,
        'Typed reminder-result presentation mapping.',
        allowlistReason:
            'ReminderFeedbackCode is mapped through challengeText with distinct EN, FR, and ES regression coverage; service/plugin messages are ignored.');
  }
  if (path.endsWith('ai_result_presenter.dart') ||
      (path.endsWith('challenge_copy.dart') &&
          source.indexOf('String challengeEditMessage') <= token.start &&
          token.start < source.indexOf('class ChallengeCopy'))) {
    return _finding(
        path,
        source,
        token,
        ProductionStringClassification.userFacing,
        true,
        'Typed result presentation source key.',
        allowlistReason:
            'The presentation mapper passes this source key through challengeText; EN, FR, and ES tests require localized output and the domain exposes only an enum code.');
  }
  if (path.endsWith('hydration_ai_orchestrator.dart')) {
    final start = source.indexOf('String _failureReason');
    final end = source.indexOf('Future<String> _localCoachResponse');
    if (start >= 0 &&
        end > start &&
        token.start >= start &&
        token.start < end) {
      return _finding(
          path,
          source,
          token,
          ProductionStringClassification.diagnostic,
          true,
          'Provider-health diagnostic metadata.',
          allowlistReason:
              'Stored only in LocalProviderHealthReporter diagnostics; repository search proves no lib/ui, notification, widget, history, or export consumer.');
    }
  }
  if (path.endsWith('hydration_contracts.dart')) {
    final structuralStart = source.indexOf('String? _structuralReason');
    final structuralEnd = source.indexOf('List<HydrionCapability> _claimed');
    final labelsStart = source.indexOf('String _capabilityLabel');
    final labelsEnd = source.indexOf('abstract class HydrationSummaryService');
    if ((structuralStart >= 0 &&
            token.start >= structuralStart &&
            token.start < structuralEnd) ||
        (labelsStart >= 0 &&
            token.start >= labelsStart &&
            token.start < labelsEnd)) {
      return _finding(
          path,
          source,
          token,
          ProductionStringClassification.diagnostic,
          true,
          'AI validator diagnostic metadata.',
          allowlistReason:
              'The production coach screen is a localized non-interactive preview; executor results expose only HydrationAiExecutionMessageCode and never copy validator reason text.');
    }
  }
  if ((path.endsWith('challenge_repository.dart') &&
          (value == 'hydrion.joined_challenge.v1' ||
              value == 'description' ||
              value.startsWith('challenge:'))) ||
      (path.endsWith('weather_goal_service.dart') &&
          value == 'hydrion.weather_forecast_cache.v1') ||
      (path.endsWith('android_widget_service.dart') &&
          value == 'active_challenge_id') ||
      (path.endsWith('coach_suggestion_service.dart') &&
          value.startsWith('coach-suggestion-')) ||
      (path.endsWith('ai_provider_config.dart') &&
          value.startsWith('models/'))) {
    return _finding(
        path,
        source,
        token,
        ProductionStringClassification.stableIdentifier,
        true,
        'Stable storage, entity, model, or platform identifier.',
        allowlistReason:
            'Machine-readable identifier participates only in lookup, persistence, routing, or provider addressing and is never rendered.');
  }
  if (path.endsWith('hydration_ai_orchestrator.dart') &&
      (_containingSymbol(source, token.start) == '_failureReason' ||
          _containingSymbol(source, token.start) == '_statusClass' ||
          _containingSymbol(source, token.start) == '_capabilityLabel')) {
    return _finding(
        path,
        source,
        token,
        ProductionStringClassification.diagnostic,
        true,
        'Provider-health diagnostic metadata.',
        allowlistReason:
            'Used only by LocalProviderHealthReporter and diagnostic tests; no lib/ui, notification, widget, history, or export consumer reads provider-health diagnostics.');
  }
  if ((value.startsWith(r'\') ||
          value.startsWith(r'[_') ||
          value.startsWith(r'^[')) &&
      (value.contains(r'\s') || value.contains(r'\d') || value.contains('{'))) {
    return _finding(
        path,
        source,
        token,
        ProductionStringClassification.formattingValue,
        true,
        'Regular-expression pattern.',
        allowlistReason:
            'Parser normalization pattern is not display text and cannot reach presentation.');
  }
  if (path.endsWith('android_widget_service.dart') &&
      (value == r'^[a-z0-9-]+$' || value == r'^[A-Za-z0-9-]+$')) {
    return _finding(
        path,
        source,
        token,
        ProductionStringClassification.formattingValue,
        true,
        'Regular-expression pattern.',
        allowlistReason:
            'Deep-link validation pattern is not display text and cannot reach presentation.');
  }
  if (path.endsWith('secret_redaction.dart') &&
      source.indexOf('static String? fingerprint') <= token.start &&
      token.start < source.indexOf('static int _fnv1a32')) {
    return _finding(
        path,
        source,
        token,
        ProductionStringClassification.diagnostic,
        true,
        'Redacted diagnostic fingerprint format.',
        allowlistReason:
            'One-way diagnostic fingerprint is never rendered in production UI and contains no source secret.');
  }
  if (path.endsWith('weather_goal_service.dart') &&
      source.indexOf('String _conditionFromCode') <= token.start &&
      token.start < source.indexOf('class CachedWeatherForecast')) {
    return _finding(
        path,
        source,
        token,
        ProductionStringClassification.userFacing,
        true,
        'Localized weather-condition source key.',
        allowlistReason:
            'Every weather condition is mapped by HydrionWeatherLocalizations.weatherCondition before presentation.');
  }
  if (path.endsWith('weather_goal_service.dart') &&
      (_containingSymbol(source, token.start) == 'WeatherProviderException' ||
          value.startsWith('WeatherProviderException('))) {
    return _finding(
        path,
        source,
        token,
        ProductionStringClassification.diagnostic,
        true,
        'Developer exception description.',
        allowlistReason:
            'WeatherForecastResult stores only status and diagnosticCode; provider exception text is never copied to a user result.');
  }
  if (path.endsWith('challenge_experience.dart') ||
      path.endsWith('challenge_activity.dart') ||
      path.endsWith('bottle_bingo.dart') ||
      path.endsWith('challenge_catalog.dart')) {
    return _finding(
        path,
        source,
        token,
        ProductionStringClassification.userFacing,
        true,
        'Localized source-catalog key.',
        allowlistReason:
            'Presentation resolves this immutable English source key through challengeText or challengeCopy; coverage tests require distinct French and Spanish output.');
  }
  if (path.endsWith('challenge_experience_screen.dart') &&
      source.indexOf('bool _isVisibleParameter') <= token.start &&
      token.start < source.indexOf('.contains(entry.key)')) {
    return _finding(
        path,
        source,
        token,
        ProductionStringClassification.stableIdentifier,
        true,
        'Stable challenge parameter key.',
        allowlistReason:
            'The key selects structured challenge metadata; _parameterLabel localizes its display label and the raw key is never rendered.');
  }
  if (path.endsWith('legal_document_registry.dart')) {
    return _finding(
        path,
        source,
        token,
        ProductionStringClassification.userFacing,
        true,
        'Localized legal source-catalog key.',
        allowlistReason:
            'Legal/About presentation resolves registry metadata by stable document ID through legal_localizations.dart.');
  }
  if ((path.endsWith('gemini_adapter.dart') ||
          path.endsWith('llm_prompt_builder.dart')) &&
      (value.contains('JSON') ||
          value.contains('HydrationContext') ||
          value.contains('PromptBuilderException'))) {
    return _finding(
        path,
        source,
        token,
        ProductionStringClassification.diagnostic,
        true,
        'Provider protocol or developer diagnostic.',
        allowlistReason:
            'Machine-facing provider instructions and exception diagnostics are never rendered as application copy.');
  }
  if (path.endsWith('i18n_resolver.dart') &&
      RegExp(r'^[a-z]{2}(?:-[A-Z]{2})?$').hasMatch(value)) {
    return _finding(
        path,
        source,
        token,
        ProductionStringClassification.platformConstant,
        true,
        'BCP 47 locale identifier.',
        allowlistReason:
            'Locale codes are machine-readable platform constants.');
  }
  if (path.endsWith('social_challenges_screen.dart')) {
    final legacyStart = source.indexOf('class _BottleBingoBoard');
    final legacyEnd = source.indexOf('class _ChallengeCard');
    if (legacyStart >= 0 &&
        legacyEnd > legacyStart &&
        token.start >= legacyStart &&
        token.start < legacyEnd) {
      return _finding(
          path,
          source,
          token,
          ProductionStringClassification.falsePositive,
          true,
          'Excluded from production rendering.',
          allowlistReason:
              'The legacy Bottle Bingo board and tile classes have no constructor call in production.');
    }
  }
  if (path.endsWith('ui_asset_manifest.dart')) {
    final contextStart = token.start > 80 ? token.start - 80 : 0;
    final context = source.substring(contextStart, token.start);
    if (RegExp(r'\bdescription\s*:\s*$', multiLine: true).hasMatch(context)) {
      return _finding(
          path,
          source,
          token,
          ProductionStringClassification.accessibility,
          true,
          'Scene description resolved from stable scene ID.',
          allowlistReason:
              'Every production scene consumer calls sceneDescription for EN, FR, or ES semantics.');
    }
    return _finding(
        path,
        source,
        token,
        ProductionStringClassification.falsePositive,
        true,
        'Non-rendered asset manifest metadata.',
        allowlistReason:
            'Scene labels are not consumed by production UI; asset paths and intended-use notes are metadata.');
  }
  if (path.endsWith('avatar_manifest.dart')) {
    final contextStart = token.start > 80 ? token.start - 80 : 0;
    final context = source.substring(contextStart, token.start);
    if (RegExp(r'\bdisplayName\s*:\s*$', multiLine: true).hasMatch(context)) {
      return _finding(
          path,
          source,
          token,
          ProductionStringClassification.properName,
          true,
          'Approved avatar proper name.',
          allowlistReason:
              'Avatar display names are named character identities shared across locales.');
    }
    return _finding(
        path,
        source,
        token,
        ProductionStringClassification.falsePositive,
        true,
        'Non-rendered avatar catalog description.',
        allowlistReason:
            'Avatar descriptions are not consumed by production presentation.');
  }
  final contextStart = token.start > 100 ? token.start - 100 : 0;
  final sourceContext = source.substring(contextStart, token.start);
  if (RegExp(r'\bLocale\s*\(\s*$', multiLine: true).hasMatch(sourceContext) &&
      RegExp(r'^[a-z]{2}(?:-[A-Z]{2})?$').hasMatch(value)) {
    return _finding(
        path,
        source,
        token,
        ProductionStringClassification.platformConstant,
        true,
        'BCP 47 locale identifier.',
        allowlistReason:
            'The Locale constructor consumes this machine-readable language code; it is never rendered.');
  }
  if (value.startsWith('assets/') ||
      value.startsWith('/') ||
      value.startsWith('package:')) {
    return _finding(
        path,
        source,
        token,
        ProductionStringClassification.platformConstant,
        true,
        'Route, asset, or package constant.',
        allowlistReason:
            'Machine-readable navigation or asset value is never rendered.');
  }
  if (RegExp(r'\.(?:legalText|challengeText)\s*\(\s*$', multiLine: true)
      .hasMatch(sourceContext)) {
    return _finding(
        path,
        source,
        token,
        ProductionStringClassification.formattingValue,
        true,
        'Source key resolved by the locale presentation mapper.',
        allowlistReason:
            'The literal is a lookup key; the mapper returns EN, FR, or ES display copy.');
  }
  if (RegExp(r'\b(?:Key|ValueKey)(?:<[^>]+>)?\s*\(\s*$', multiLine: true)
      .hasMatch(sourceContext)) {
    return _finding(
        path,
        source,
        token,
        ProductionStringClassification.stableIdentifier,
        true,
        'Stable widget-test identifier.',
        allowlistReason:
            'Key value identifies a widget and is never rendered.');
  }
  final symbol = _containingSymbol(source, token.start);
  final suffixEnd =
      token.end + 30 < source.length ? token.end + 30 : source.length;
  final sourceSuffix = source.substring(token.end, suffixEnd);
  if (_looksLikeStableIdentifier(value) &&
      (RegExp(r'^\s*=>').hasMatch(sourceSuffix) ||
          RegExp(r'\.challengeCopy\s*\(\s*$', multiLine: true)
              .hasMatch(sourceContext))) {
    return _finding(
        path,
        source,
        token,
        ProductionStringClassification.stableIdentifier,
        true,
        'Stable switch or presentation lookup identifier.',
        allowlistReason:
            'The identifier selects localized copy and is never rendered.');
  }
  if (_looksLikeStableIdentifier(value) && value.contains('-')) {
    return _finding(
        path,
        source,
        token,
        ProductionStringClassification.stableIdentifier,
        true,
        'Stable kebab-case domain identifier.',
        allowlistReason:
            'Kebab-case challenge or tile ID is used for lookup and never rendered.');
  }
  if (path.endsWith('health_data_connection_screen.dart') &&
      {
        'permission_request_failed',
        'permissionRequired',
        'health_kit_unavailable',
      }.contains(value)) {
    return _finding(
        path,
        source,
        token,
        ProductionStringClassification.stableIdentifier,
        true,
        'Stable health-provider state code.',
        allowlistReason:
            'The code selects localized connection guidance and is never rendered directly.');
  }
  if ({
    '_shortTitle',
    '_stateLabel',
    '_whyItCounts',
    '_timeWindow',
    '_choiceLabel',
    '_parameterLabel',
    '_parameterHelp',
    '_parameterChoices',
    '_isVisibleParameter',
  }.contains(symbol)) {
    return _finding(
        path,
        source,
        token,
        ProductionStringClassification.formattingValue,
        true,
        'Source key resolved by challengeText in the containing helper.',
        allowlistReason:
            'The helper routes the switch result through the EN, FR, or ES challenge mapper.');
  }
  if (symbol == '_parameterSummary' && _looksLikeStableIdentifier(value)) {
    return _finding(
        path,
        source,
        token,
        ProductionStringClassification.stableIdentifier,
        true,
        'Stable parameter key used to select localized formatting.',
        allowlistReason:
            'The key selects a branch and is never included in rendered copy.');
  }
  if (symbol == '_checkpointTile' &&
      {'Completed', 'Available', 'Waiting'}.contains(value)) {
    return _finding(
        path,
        source,
        token,
        ProductionStringClassification.formattingValue,
        true,
        'Checkpoint state key resolved through challenge localization.',
        allowlistReason:
            'The state is passed to challengeText or challengeCheckpointSemantics before rendering.');
  }
  if (symbol == '_versionKey') {
    return _finding(
        path,
        source,
        token,
        ProductionStringClassification.stableIdentifier,
        true,
        'Stable document-version storage key.',
        allowlistReason:
            'Document ID and version are composed for local state lookup only.');
  }
  if (symbol == '_dateLabel' || RegExp(r'^v\$\{.+\}$').hasMatch(value)) {
    return _finding(
        path,
        source,
        token,
        ProductionStringClassification.formattingValue,
        true,
        'Technical date or version formatting pattern.',
        allowlistReason:
            'Expression adds only locale-independent version/date punctuation.');
  }
  if (_looksLikeStableIdentifier(value) &&
      RegExp(
        r'(?:\bKey\s*\(|\b(?:id|challengeId|parameterKey|heroTag)\s*:\s*|'
        r'parameters\s*\[\s*|\bcase\s*|=>\s*)$',
        multiLine: true,
      ).hasMatch(sourceContext)) {
    return _finding(
        path,
        source,
        token,
        ProductionStringClassification.stableIdentifier,
        true,
        'Stable identifier used for state or widget lookup.',
        allowlistReason:
            'Machine-readable key is never rendered as user-facing copy.');
  }
  if (path.endsWith('social_challenges_screen.dart') &&
      _unusedLegacyBottleBingoCopy.contains(value)) {
    return _finding(
        path,
        source,
        token,
        ProductionStringClassification.falsePositive,
        true,
        'Excluded from production rendering.',
        allowlistReason:
            'Unreachable copy in the explicitly unused legacy Bottle Bingo migration renderer.');
  }
  if (path.endsWith('language_selection_screen.dart') &&
      _languagePickerAutonyms.contains(value)) {
    return _finding(
        path,
        source,
        token,
        ProductionStringClassification.userFacing,
        true,
        'Approved pre-locale autonym.',
        allowlistReason:
            'Locale autonym must be readable before an application locale exists.');
  }
  if (_properNames.contains(value)) {
    return _finding(
        path,
        source,
        token,
        ProductionStringClassification.properName,
        true,
        'Approved proper name.',
        allowlistReason: 'Hydrion is the registered application name.');
  }
  if (_technicalValues.contains(value)) {
    return _finding(
        path,
        source,
        token,
        ProductionStringClassification.formattingValue,
        true,
        'Standard unit symbol.',
        allowlistReason: 'Locale-independent volume-unit symbol.');
  }
  if (value.contains('l10n.') && !_hasUnlocalizedWords(value)) {
    return _finding(
        path,
        source,
        token,
        ProductionStringClassification.formattingValue,
        true,
        'Localized values composed with punctuation.',
        allowlistReason:
            'Expression contains only localization lookups and formatting characters.');
  }
  if (!_hasUnlocalizedWords(value)) {
    return _finding(
        path,
        source,
        token,
        ProductionStringClassification.formattingValue,
        true,
        'Locale-neutral interpolation and punctuation.',
        allowlistReason:
            'The expression contains no literal words outside runtime values.');
  }
  final withoutExpressions = value
      .replaceAll(RegExp(r'\$\{[^}]+\}'), '')
      .replaceAll(RegExp(r'\$[A-Za-z_]\w*'), '')
      .trim();
  if ({'min', 'ml', 'oz', 'mL', '/', '·'}.contains(withoutExpressions)) {
    return _finding(
        path,
        source,
        token,
        ProductionStringClassification.formattingValue,
        true,
        'Locale-independent minute abbreviation.',
        allowlistReason: 'The abbreviation min is shared by EN, FR, and ES.');
  }
  return _finding(
      path,
      source,
      token,
      defaultClassification,
      false,
      defaultClassification == ProductionStringClassification.accessibility
          ? 'Move accessibility copy into localization.'
          : 'Move user-facing production copy into localization.');
}

ProductionStringFinding _finding(
  String path,
  String source,
  _StringToken token,
  ProductionStringClassification classification,
  bool resolved,
  String resolution, {
  String? allowlistReason,
}) {
  return ProductionStringFinding(
    source: path,
    lineStart: _lineAt(source, token.start),
    lineEnd: _lineAt(source, token.end),
    symbol: _containingSymbol(source, token.start),
    expression: token.source.replaceAll(RegExp(r'\s+'), ' ').trim(),
    classification: classification,
    resolved: resolved,
    resolution: resolution,
    allowlistReason: allowlistReason,
  );
}

List<_StringToken> _tokenizeStrings(String source) {
  final tokens = <_StringToken>[];
  var index = 0;
  while (index < source.length) {
    if (source.startsWith('//', index)) {
      index = source.indexOf('\n', index);
      if (index < 0) break;
      continue;
    }
    if (source.startsWith('/*', index)) {
      final end = source.indexOf('*/', index + 2);
      index = end < 0 ? source.length : end + 2;
      continue;
    }
    var quoteIndex = index;
    var raw = false;
    if ((source[index] == 'r' || source[index] == 'R') &&
        index + 1 < source.length &&
        (source[index + 1] == "'" || source[index + 1] == '"')) {
      raw = true;
      quoteIndex++;
    }
    final quote = source[quoteIndex];
    if (quote != "'" && quote != '"') {
      index++;
      continue;
    }
    final triple = source.startsWith(quote * 3, quoteIndex);
    final delimiter = triple ? quote * 3 : quote;
    var cursor = quoteIndex + delimiter.length;
    while (cursor < source.length) {
      if (!raw && source[cursor] == '\\') {
        cursor += 2;
        continue;
      }
      if (!raw && source.startsWith(r'${', cursor)) {
        cursor = _interpolationEnd(source, cursor + 2);
        continue;
      }
      if (!raw && source[cursor] == r'$' && cursor + 1 < source.length) {
        final identifier =
            RegExp(r'[A-Za-z_]\w*').matchAsPrefix(source, cursor + 1);
        if (identifier != null) {
          cursor = identifier.end;
          continue;
        }
      }
      if (source.startsWith(delimiter, cursor)) break;
      cursor++;
    }
    if (cursor >= source.length) break;
    final end = cursor + delimiter.length;
    final value = source.substring(quoteIndex + delimiter.length, cursor);
    tokens.add(_StringToken(index, end, value, source.substring(index, end)));
    index = end;
  }
  return tokens;
}

int _interpolationEnd(String source, int cursor) {
  var depth = 1;
  var index = cursor;
  while (index < source.length && depth > 0) {
    if (source.startsWith('//', index)) {
      final end = source.indexOf('\n', index);
      index = end < 0 ? source.length : end + 1;
      continue;
    }
    if (source.startsWith('/*', index)) {
      final end = source.indexOf('*/', index + 2);
      index = end < 0 ? source.length : end + 2;
      continue;
    }
    final char = source[index];
    if (char == "'" || char == '"') {
      final delimiter = source.startsWith(char * 3, index) ? char * 3 : char;
      index += delimiter.length;
      while (index < source.length && !source.startsWith(delimiter, index)) {
        index += source[index] == '\\' ? 2 : 1;
      }
      index += delimiter.length;
      continue;
    }
    if (char == '{') depth++;
    if (char == '}') depth--;
    index++;
  }
  return index;
}

List<_StringToken> _combineAdjacentStrings(
  String source,
  List<_StringToken> tokens,
) {
  if (tokens.isEmpty) return tokens;
  final combined = <_StringToken>[];
  var current = tokens.first;
  for (final next in tokens.skip(1)) {
    final between = source.substring(current.end, next.start);
    if (RegExp(r'^\s*$').hasMatch(between)) {
      current = _StringToken(
        current.start,
        next.end,
        '${current.value}${next.value}',
        source.substring(current.start, next.end),
      );
    } else {
      combined.add(current);
      current = next;
    }
  }
  combined.add(current);
  return combined;
}

int _lineAt(String source, int offset) =>
    '\n'
        .allMatches(source.substring(0, offset.clamp(0, source.length)))
        .length +
    1;

String _containingSymbol(String source, int offset) {
  const lookupWindow = 12000;
  final start = offset > lookupWindow ? offset - lookupWindow : 0;
  final prefix = source.substring(start, offset);
  final classes = RegExp(r'\bclass\s+([A-Za-z_]\w*)').allMatches(prefix);
  final functions = RegExp(
    r'(?:^|\n)\s*(?:[A-Za-z_]\w*(?:<[^>\n]+>)?[?]?\s+)?'
    r'([A-Za-z_]\w*)\s*\([^;{}]*\)\s*(?:async\s*)?\{',
    multiLine: true,
  ).allMatches(prefix);
  final classMatch = classes.isEmpty ? null : classes.last;
  final functionMatch = functions.isEmpty ? null : functions.last;
  if (classMatch == null && functionMatch == null) return '<top-level>';
  if (functionMatch == null ||
      (classMatch != null && classMatch.start > functionMatch.start)) {
    return classMatch!.group(1)!;
  }
  return functionMatch.group(1)!;
}

bool _containsWords(String value) =>
    RegExp(r'[A-Za-z]').hasMatch(value.replaceAll(RegExp(r'\\[nrt]'), ''));

bool _looksLikeCompleteSentence(String value) {
  final text = value.trim();
  return RegExp(r'^[A-Z][^\n]*\s+[^\n]*[.!?]$').hasMatch(text);
}

bool _looksLikeStableIdentifier(String value) =>
    !value.contains(RegExp(r'\s')) &&
    RegExp(r'^[A-Za-z][A-Za-z0-9_.-]*$').hasMatch(value);

bool _hasUnlocalizedWords(String value) {
  final withoutExpressions = value
      .replaceAll(RegExp(r'\$\{[^}]+\}'), '')
      .replaceAll(RegExp(r'\$[A-Za-z_]\w*'), '');
  return RegExp(r'[A-Za-z]').hasMatch(withoutExpressions);
}

List<ProductionStringFinding> scanProductionTree({String? pathFilter}) {
  final records = <ProductionStringFinding>[];
  for (final root in [Directory('lib'), Directory('android/app/src/main')]) {
    if (!root.existsSync()) continue;
    for (final entity in root.listSync(recursive: true, followLinks: false)) {
      if (entity is! File) continue;
      final path = entity.path.replaceAll('\\', '/');
      if (path.contains('/generated/') || path.contains('/l10n/')) {
        continue;
      }
      if (pathFilter != null && !path.contains(pathFilter)) continue;
      final supported = path.endsWith('.dart') ||
          path.endsWith('.kt') ||
          path.endsWith('.java') ||
          path.endsWith('.xml');
      if (!supported) continue;
      final source = entity.readAsStringSync();
      if (path.endsWith('.dart')) {
        records.addAll(scanDartSource(source, path: path));
      } else if (path.endsWith('.kt') || path.endsWith('.java')) {
        records.addAll(scanAndroidSource(source, path: path));
      } else if (path.endsWith('.xml') && path.contains('/res/')) {
        records.addAll(scanAndroidXmlSource(source, path: path));
      }
    }
  }
  final valuesRoot = Directory('android/app/src/main/res');
  final english = File('${valuesRoot.path}/values/strings.xml');
  final french = File('${valuesRoot.path}/values-fr/strings.xml');
  final spanish = File('${valuesRoot.path}/values-es/strings.xml');
  if ((pathFilter == null || english.path.contains(pathFilter)) &&
      english.existsSync() &&
      french.existsSync() &&
      spanish.existsSync()) {
    records.addAll(scanAndroidResourceCoverage(
      english: english.readAsStringSync(),
      french: french.readAsStringSync(),
      spanish: spanish.readAsStringSync(),
      source: english.path,
    ));
  }
  return records;
}

void main(List<String> arguments) {
  final pathFilter = arguments
      .where((argument) => argument.startsWith('--path='))
      .map((argument) => argument.substring('--path='.length))
      .firstOrNull;
  final records = scanProductionTree(pathFilter: pathFilter);
  final limit = arguments
      .where((argument) => argument.startsWith('--limit='))
      .map((argument) => int.tryParse(argument.substring('--limit='.length)))
      .whereType<int>()
      .firstOrNull;
  final unresolved = records.where((record) => !record.resolved).toList();
  if (arguments.contains('--json')) {
    stdout.writeln(const JsonEncoder.withIndent('  ').convert({
      'summary': {
        'findings': records.length,
        'resolved': records.length - unresolved.length,
        'unresolved': unresolved.length,
        'userFacingUnresolved': unresolved
            .where((f) =>
                f.classification == ProductionStringClassification.userFacing)
            .length,
        'accessibilityUnresolved': unresolved
            .where((f) =>
                f.classification ==
                ProductionStringClassification.accessibility)
            .length,
      },
      'findings': records.map((record) => record.toJson()).toList(),
    }));
  } else {
    stdout.writeln(
      'Production literal audit: ${records.length} findings; '
      '${records.length - unresolved.length} reviewed; '
      '${unresolved.length} unresolved.',
    );
    if (arguments.contains('--by-file')) {
      final counts = <String, int>{};
      for (final record in unresolved) {
        counts.update(record.source, (count) => count + 1, ifAbsent: () => 1);
      }
      final entries = counts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      for (final entry in entries) {
        stdout.writeln('${entry.value}\t${entry.key}');
      }
    }
    if (!arguments.contains('--summary')) {
      final displayed =
          arguments.contains('--unresolved-only') ? unresolved : records;
      for (final record in limit == null ? displayed : displayed.take(limit)) {
        final state = record.resolved ? 'REVIEWED' : 'UNRESOLVED';
        stdout.writeln(
          '$state ${record.classification.code} ${record.source}:'
          '${record.lineStart}-${record.lineEnd} ${record.symbol}: '
          '${record.expression} [${record.resolution}]',
        );
      }
    }
  }
  if (unresolved.isNotEmpty) exitCode = 1;
}
