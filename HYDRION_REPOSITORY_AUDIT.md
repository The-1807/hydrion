# Hydrion Repository Audit

## Executive Summary

- Current build status: not build-ready. `flutter pub get` succeeds from the repository root, but `dart analyze --format=json` reports 166 errors, 9 warnings, and 60 infos. `flutter build web --release` reaches Dart compilation and fails on unresolved packages, broken imports, missing types, and a syntax error in `lib/sevices/llm_service.dart`. `flutter build apk --release` could not be completed locally because no Android SDK is configured in this environment.
- Current test status: failing. `flutter test` fails while loading `test/widget_test.dart` because it imports `package:hydrion_app/main.dart`, but the actual package name is `hydrion`; it also expects a `MyApp` widget that does not exist.
- Current app readiness: not bootable. `lib/main.dart` references missing imports, missing classes, mismatched constructors, missing dependencies, and private fallback classes with recursive construction risks.
- Real Flutter app root: repository root (`pubspec.yaml` is at `./pubspec.yaml`).
- Top 5 blockers:
  1. Broken import architecture: many imports still target nonexistent `app/`, `services/`, `../hydrion/app/lib`, `package:hydrion_app`, or missing KMP/ELKA-like bindings.
  2. `lib/main.dart` cannot compile because it references missing packages (`firebase_core`, `sqflite`), missing services (`AIBridge`, `NotificationService`, etc.), and APIs that do not match current service implementations.
  3. `lib/sevices/llm_service.dart` is syntactically incomplete and depends on empty or missing AI/core adapter files.
  4. UI and service contracts do not match: `I18nResolver`, `Permissions`, `EcoTracker`, `VoiceService`, and `LLMService` APIs used by UI/main differ from the actual implementations.
  5. Tests are still the default counter-app smoke test and target the wrong package/app widget.

Command evidence:

```text
dart analyze --format=json
ERROR: 166
WARNING: 9
INFO: 60

flutter test
Failed to load "test/widget_test.dart":
Error: Couldn't resolve the package 'hydrion_app' in 'package:hydrion_app/main.dart'.
Error: Couldn't find constructor 'MyApp'.

flutter build web --release
Target dart2js failed: Couldn't resolve packages firebase_core and sqflite, plus broken project imports.

flutter build apk --release
[!] No Android SDK found. Try setting the ANDROID_HOME environment variable.
```

## Repository Structure Findings

| Severity | Path | Issue | Evidence | Recommended Fix |
|---|---|---|---|---|
| Critical | `.` | Flutter project root is the repository root, not `app/`. | `pubspec.yaml`, `lib/`, `android/`, `ios/`, `web/`, and `test/` are all at repo root. | Keep CI and local scripts rooted at `.`. Remove or update all stale `app/` assumptions. |
| Critical | `lib/sevices/` | Service folder is misspelled and does not match imports that expect `lib/services/`. | Analyzer errors for `/services/voice_service.dart`, `package:hydrion/services/ble_service.dart`, and many `../hydrion/app/lib/services/...` imports. | Choose one architecture. Preferred: rename to `lib/services/` and use `package:hydrion/services/...` imports. |
| Critical | `lib/sevices/core_bridge.dart`, `lib/utils/logging.dart` | Empty runtime files are imported as if they provide production APIs. | Both files are 0 bytes. Analyzer reports missing `CoreBridge` and `Log`. | Implement real interfaces or remove references after dependency tracing. Do not leave empty runtime files as adapters. |
| Critical | `core/cargo.toml`, `core/crates/*` | Rust workspace manifest names hyphenated crates that do not exist, while underscore directories exist and are empty. | Workspace lists `hydrion-ml`, `hydrion-storage`, `hydrion-ble`, `hydrion-ffi`; actual folders include `hydrion_ml`, `hydrion_storage`, `hydrion_ble`, `hydrion_ffi`. | Reconcile Rust crate names and folder names before adding Rust CI. Fill or remove empty crate shells only after tracing intended ownership. |
| High | `packs/` | AI pack folders are declared as assets but mostly empty or malformed. | `byok_client.dart`, server files, and upload digest files are 0 bytes; `packs/gemini_connector/client/lib/gemini_client.dart` is a directory, not a Dart file. | Convert packs into real Dart packages/adapters or move them out of Flutter assets until implemented. |
| High | `models/` | Training scripts are declared as Flutter assets. | `pubspec.yaml` includes `models/`; folder contains Python training scripts, not runtime model artifacts. | Split runtime model assets from training source. Declare only runtime artifacts under Flutter assets. |
| Medium | `assets/icons/`, `assets/ui/`, `assets/sounds/`, `assets/ar/`, `i18n/` | Declared asset folders exist but are empty. | File counts are zero for all listed folders. | Keep folders if intentionally reserved, but do not rely on them at runtime until assets exist. |
| Medium | `hydrion.txt`, `p1.txt`, `overview` | Planning/spec files describe an older `app/`-based architecture. | `p1.txt` creates `app/{lib,assets,android,ios,web,test}` and scripts still use `cd app`. | Treat these as design notes only. Update or archive after current architecture is decided. |
| Medium | `scripts/` | Several scripts still assume `app/`, `cloud/functions`, `integration_tests/`, or Gradle/KMP layout that is absent. | `scripts/lint_all.sh:20`, `scripts/test_all.sh:20`, `scripts/deploy_firebase.sh:17`. | Update scripts only after build blockers are fixed; do not add deployment automation until targets exist. |
| Low | `README.md`, web metadata, Android/iOS/macOS bundle IDs | Project still carries default Flutter naming in docs and platform metadata. | README title is `hydrion_app`; web description says "A new Flutter project"; package IDs are `com.example...`. | Update branding after the app compiles. |

Major folder map:

| Path | Current Purpose | Audit Notes |
|---|---|---|
| `.github/workflows/` | GitHub Actions CI. | Root path issue is fixed; remaining failures are real project failures. |
| `android/`, `ios/`, `web/`, `macos/`, `windows/`, `linux/` | Flutter platform scaffolds. | Mostly default generated scaffolds; release readiness is incomplete. |
| `lib/` | Flutter app source. | Contains entrypoint, UI, utilities, and misspelled service layer. Does not compile. |
| `test/` | Flutter tests. | Contains one stale default counter test. |
| `assets/` | Declared Flutter asset folders. | Empty. |
| `config/` | YAML/JSON app, OpenAI, Firebase, prompt config. | Contains placeholders and paths that do not match code. |
| `i18n/` | Declared localization asset folder. | Empty; localization currently only delegates Material/Cupertino/Widgets. |
| `models/` | Python model training scripts. | Not runtime Flutter assets. |
| `packs/` | Intended AI provider/local model packs. | Mostly empty; imports do not resolve. |
| `core/` | Intended Rust core workspace. | Workspace is structurally inconsistent and not wired to Flutter. |
| `scripts/` | Dev/build/deploy helpers. | Several scripts target old architecture. |

## Build and CI Findings

| Severity | Path | Issue | Evidence | Recommended Fix |
|---|---|---|---|---|
| Critical | `.github/workflows/flutter-ci.yml` | CI now correctly runs from root, but `quality-gate` fails on real analyzer/test errors. | Lines 30-32 set `working-directory: .`; lines 68-72 run `flutter analyze` and `flutter test --coverage`. | Fix source/test failures. Do not suppress analyzer or test failures. |
| Critical | `lib/` | Web build fails at Dart compilation. | `flutter build web --release` fails on missing `firebase_core`, `sqflite`, broken imports, missing types, and `llm_service.dart` syntax. | Resolve analyzer errors before expecting web or APK builds to pass. |
| High | `.github/workflows/flutter-ci.yml` | Workflow pins Flutter `3.24.x`, while `.metadata` shows project generated with Flutter revision `9f455d...` from local Flutter 3.35.6. | Workflow line 22: `FLUTTER_VERSION: "3.24.x"`; `.metadata` revision matches local 3.35.6 output. | Choose and document a single supported Flutter SDK version. Prefer matching project metadata or regenerating metadata intentionally. |
| High | `android/app/build.gradle.kts` | Android release build signs with debug config and uses default `com.example` application ID. | Lines 23-36 include TODOs, `applicationId = "com.example.hydrion_app"`, and `signingConfig = signingConfigs.getByName("debug")`. | Add real application ID and release signing strategy before release automation. |
| High | `scripts/lint_all.sh`, `scripts/test_all.sh` | Scripts still fail structurally because they `cd app`. | `scripts/lint_all.sh:20`, `scripts/test_all.sh:20`. | Change to root commands after the source tree is repaired. |
| High | `scripts/deploy_firebase.sh` | Deployment script targets absent `cloud/functions`. | `scripts/deploy_firebase.sh:17`, no `cloud/` folder exists. | Do not create deploy workflow until backend/cloud target exists. |
| Medium | `.github/workflows/flutter-ci.yml` | CI uses `flutter-action` built-in cache only. This is functional, but no explicit pub cache key is visible. | Lines 44-49, 102-107, and 136-141 use `cache: true`. | Keep as-is unless cache misses become a problem. If adding explicit cache later, use root `pubspec.lock`. |
| Medium | `.github/workflows/flutter-ci.yml` | Build jobs depend on quality gate, so artifacts are never attempted until analyze/test pass. | Lines 83-86 and 123-126. | Correct for CI quality gating; no change needed now. |
| Medium | Local environment | Android build could not be audited past SDK discovery locally. | `flutter build apk --release` reports no Android SDK / `ANDROID_HOME`. | Validate on GitHub-hosted runner after Dart compile errors are fixed. |
| Low | `.github/workflows/flutter-ci.yml` | Coverage artifact is uploaded even on failed tests. | `if: always()` at line 75. | This is acceptable; keep it if test diagnostics are useful. |

## Dart and Flutter Findings

| Severity | Path | Issue | Evidence | Recommended Fix |
|---|---|---|---|---|
| Critical | `lib/main.dart` | Entrypoint does not compile and app cannot boot. | Broken imports at lines 7, 13, 18-23, 31, 35, 41; missing `HomeScreen`; missing services; mismatched constructors. | Rebuild app bootstrap around real services, public app widget, and root-level package imports. |
| Critical | `lib/main.dart` | Service initialization order is not reliable because dependencies are missing or mismatched. | `LLMService()` is called without required `CoreBridge`; `EcoTracker(db:)` does not match current `EcoTracker(coreBridge:)`; `Permissions.requestPermissions()` does not exist. | First define stable service interfaces and constructors, then initialize in deterministic order with failure boundaries. |
| Critical | `lib/main.dart` | Fallback voice classes recursively instantiate each other. | `_DummyVoice` constructs `_DummyBridge`; `_DummyBridge` constructs `_NoopVoice`; `_NoopVoice` constructs `_DummyBridge`. | Replace with non-recursive no-op implementations behind interfaces. |
| Critical | `lib/sevices/llm_service.dart` | Syntax is incomplete. | Analyzer `expected_token` at line 216: missing closing `}`. | Fix syntax before deeper LLM behavior can be tested. |
| Critical | `lib/sevices/llm_service.dart` | AI service depends on missing/empty adapters. | Imports missing pack clients and empty `core_bridge.dart`/`logging.dart`; loads missing `config/llm_packs.yaml`. | Introduce real `AiProvider`/`CoreDigestProvider` interfaces and a standalone fallback implementation. |
| Critical | `lib/ui/screens/HomeScreen.dart`, `lib/ui/screens/AnalyticScreen.dart` | Duplicate/misnamed screens block routing. | `HomeScreen.dart` defines `AnalyticsScreen`, not `HomeScreen`; `AnalyticScreen.dart` also defines `AnalyticsScreen`; `main.dart` imports missing `AnalyticsScreen.dart`. | Decide canonical screen names and filenames; expose an actual `HomeScreen`. |
| High | `lib/utils/i18n_resolver.dart` | UI expects instance localization methods that do not exist. | UI calls `getText`, `getTextDirection`, `loadLocale`; resolver only has static locale helpers. | Add a real localization service or update UI to use static helpers and generated localizations. |
| High | `lib/utils/permissions.dart` | Permission API does not match callers and uses outdated health package API. | Callers use `requestPermissions`; class defines `requestAll`; analyzer cannot resolve `HealthFactory`. | Align method names and update `health` API usage for installed version. |
| High | `lib/sevices/ble_service.dart` | BLE code uses obsolete `flutter_blue_plus` instance APIs. | Analyzer errors for `FlutterBluePlus.instance`, `_ble.state`, `_ble.startScan`, `_ble.scanResults`, `_ble.stopScan`. | Update to current static/adapter-state API or pin a compatible package with justification. |
| High | `lib/ui/screens/ArVisualizationScreen.dart` | AR plugin API usage does not match installed package. | Analyzer cannot find `ARSessionManager`, `ARObjectManager`, `ARNode`, `NodeType`, `PlaneDetectionConfig`. | Verify `ar_flutter_plugin` API/version or isolate AR behind a platform adapter and feature flag. |
| Medium | `lib/ui/screens/*`, `lib/ui/components/*` | UI directly reads hardware, health, notification, AI, and storage-like services. | `context.read<LLMService>()`, `context.read<WearableService>()`, `Provider.of<EcoTracker>()`, `context.read<AIBridge>()`. | Keep UI dependent on view models/application services, not provider-specific hardware/cloud implementations. |
| Low | `lib/ui/**/*` | File naming style is inconsistent with Dart conventions. | Analyzer reports `file_names` for PascalCase Dart files. | Rename after import graph is stable. |

Analyzer error inventory from `dart analyze --format=json`:

```text
lib/main.dart:7:8 | uri_does_not_exist | Target of URI doesn't exist: 'package:firebase_core/firebase_core.dart'.
lib/main.dart:13:8 | uri_does_not_exist | Target of URI doesn't exist: 'package:sqflite/sqflite.dart'.
lib/main.dart:18:8 | uri_does_not_exist | Target of URI doesn't exist: '/services/voice_service.dart'.
lib/main.dart:19:8 | uri_does_not_exist | Target of URI doesn't exist: '/services/voice_llm_bridge.dart'.
lib/main.dart:20:8 | uri_does_not_exist | Target of URI doesn't exist: '/services/wearable_service.dart'.
lib/main.dart:21:8 | uri_does_not_exist | Target of URI doesn't exist: '/services/notifications.dart'.
lib/main.dart:22:8 | uri_does_not_exist | Target of URI doesn't exist: '/services/ai_bridge.dart'.
lib/main.dart:23:8 | uri_does_not_exist | Target of URI doesn't exist: '/services/eco_tracker.dart'.
lib/main.dart:31:8 | uri_does_not_exist | Target of URI doesn't exist: '../hydrion/app/lib/ui/screens/AnalyticsScreen.dart'.
lib/main.dart:35:8 | uri_does_not_exist | Target of URI doesn't exist: '../hydrion/app/lib/ui/screens/SocialChallengesScreen.dart'.
lib/main.dart:41:8 | uri_does_not_exist | Target of URI doesn't exist: 'package:hydrion/policy/policy.dart'.
lib/main.dart:102:29 | creation_with_non_type | The name 'HomeScreen' isn't a class.
lib/main.dart:111:43 | creation_with_non_type | The name 'SocialChallengesScreen' isn't a class.
lib/main.dart:160:9 | undefined_class | Undefined class 'NotificationService'.
lib/main.dart:161:9 | undefined_class | Undefined class 'LLMService'.
lib/main.dart:162:9 | undefined_class | Undefined class 'VoiceService'.
lib/main.dart:163:9 | undefined_class | Undefined class 'VoiceLLMBridge'.
lib/main.dart:164:9 | undefined_class | Undefined class 'WearableService'.
lib/main.dart:165:9 | undefined_class | Undefined class 'AIBridge'.
lib/main.dart:166:9 | undefined_class | Undefined class 'EcoTracker'.
lib/main.dart:189:33 | undefined_method | The method 'NotificationService' isn't defined for the type '_AppBundle'.
lib/main.dart:194:17 | undefined_method | The method 'LLMService' isn't defined for the type '_AppBundle'.
lib/main.dart:195:25 | undefined_method | The method 'VoiceLLMBridge' isn't defined for the type '_AppBundle'.
lib/main.dart:196:19 | undefined_method | The method 'VoiceService' isn't defined for the type '_AppBundle'.
lib/main.dart:197:23 | undefined_method | The method 'WearableService' isn't defined for the type '_AppBundle'.
lib/main.dart:198:22 | undefined_method | The method 'AIBridge' isn't defined for the type '_AppBundle'.
lib/main.dart:199:24 | undefined_method | The method 'EcoTracker' isn't defined for the type '_AppBundle'.
lib/main.dart:222:11 | undefined_identifier | Undefined name 'Firebase'.
lib/main.dart:234:15 | undefined_function | The function 'LLMService' isn't defined.
lib/main.dart:238:23 | undefined_function | The function 'VoiceLLMBridge' isn't defined.
lib/main.dart:242:17 | undefined_function | The function 'VoiceService' isn't defined.
lib/main.dart:245:21 | undefined_function | The function 'WearableService' isn't defined.
lib/main.dart:248:20 | undefined_function | The function 'AIBridge' isn't defined.
lib/main.dart:252:22 | undefined_function | The function 'EcoTracker' isn't defined.
lib/main.dart:257:22 | undefined_function | The function 'ReminderPolicy' isn't defined.
lib/main.dart:262:31 | undefined_function | The function 'NotificationService' isn't defined.
lib/main.dart:268:25 | undefined_method | The method 'requestPermissions' isn't defined for the type 'Permissions'.
lib/main.dart:300:19 | undefined_method | The method 'requestPermission' isn't defined for the type 'AndroidFlutterLocalNotificationsPlugin'.
lib/main.dart:319:8 | non_type_as_type_argument | The name 'Database' isn't a type, so it can't be used as a type argument.
lib/main.dart:320:21 | undefined_function | The function 'getDatabasesPath' isn't defined.
lib/main.dart:322:10 | undefined_function | The function 'openDatabase' isn't defined.
lib/main.dart:358:27 | extends_non_class | Classes can only extend other classes.
lib/main.dart:359:25 | undefined_named_parameter | The named parameter 'voiceLLMBridge' isn't defined.
lib/main.dart:362:28 | extends_non_class | Classes can only extend other classes.
lib/main.dart:363:38 | undefined_method | The method 'LLMService' isn't defined for the type '_DummyBridge'.
lib/main.dart:363:52 | undefined_named_parameter | The named parameter 'voiceService' isn't defined.
lib/main.dart:363:26 | undefined_named_parameter | The named parameter 'llmService' isn't defined.
lib/main.dart:368:26 | extends_non_class | Classes can only extend other classes.
lib/main.dart:369:24 | undefined_named_parameter | The named parameter 'voiceLLMBridge' isn't defined.
lib/main.dart:373:28 | implements_non_class | Classes and mixins can only implement other classes and mixins.
lib/main.dart:376:90 | undefined_class | Undefined class 'ConflictAlgorithm'.
lib/sevices/ble_service.dart:13:32 | use_of_void_result | This expression has a type of 'void' so its value can't be used.
lib/sevices/ble_service.dart:36:32 | instance_access_to_static_member | The static getter 'state' can't be accessed through an instance.
lib/sevices/ble_service.dart:40:18 | instance_access_to_static_member | The static method 'startScan' can't be accessed through an instance.
lib/sevices/ble_service.dart:46:23 | instance_access_to_static_member | The static getter 'scanResults' can't be accessed through an instance.
lib/sevices/ble_service.dart:61:18 | instance_access_to_static_member | The static method 'stopScan' can't be accessed through an instance.
lib/sevices/ble_service.dart:70:20 | instance_access_to_static_member | The static method 'stopScan' can't be accessed through an instance.
lib/sevices/ble_service.dart:131:18 | instance_access_to_static_member | The static method 'stopScan' can't be accessed through an instance.
lib/sevices/eco_tracker.dart:2:8 | uri_does_not_exist | Target of URI doesn't exist: 'package:hydrion/services/ble_service.dart'.
lib/sevices/eco_tracker.dart:9:9 | undefined_class | Undefined class 'CoreBridge'.
lib/sevices/eco_tracker.dart:12:24 | undefined_class | Undefined class 'CoreBridge'.
lib/sevices/llm_service.dart:12:8 | uri_does_not_exist | Target of URI doesn't exist: '.../packs/edge_llm/bindings/lib/edge_llm_client.dart'.
lib/sevices/llm_service.dart:15:8 | uri_does_not_exist | Target of URI doesn't exist: 'package:hydrion/pack/byok_llm/client/lib/byok_client.dart'.
lib/sevices/llm_service.dart:16:8 | uri_does_not_exist | Target of URI doesn't exist: 'package:hydrion/packs/gemini_connector/client/lib/gemini_client.dart'.
lib/sevices/llm_service.dart:17:8 | uri_does_not_exist | Target of URI doesn't exist: 'package:hydrion/packs/edge_llm/client/lib/edge_llm_client.dart'.
lib/sevices/llm_service.dart:30:9 | undefined_class | Undefined class 'CoreBridge'.
lib/sevices/llm_service.dart:31:14 | undefined_class | Undefined class 'ByokClient'.
lib/sevices/llm_service.dart:32:14 | undefined_class | Undefined class 'GeminiClient'.
lib/sevices/llm_service.dart:33:14 | undefined_class | Undefined class 'EdgeLlmClient'.
lib/sevices/llm_service.dart:56:21 | undefined_method | The method 'ByokClient' isn't defined for the type 'LlmService'.
lib/sevices/llm_service.dart:60:23 | undefined_method | The method 'GeminiClient' isn't defined for the type 'LlmService'.
lib/sevices/llm_service.dart:64:24 | undefined_method | The method 'EdgeLlmClient' isn't defined for the type 'LlmService'.
lib/sevices/llm_service.dart:71:7 | undefined_identifier | Undefined name 'Log'.
lib/sevices/llm_service.dart:73:7 | undefined_identifier | Undefined name 'Log'.
lib/sevices/llm_service.dart:97:55 | undefined_method | The method 'buildPrompt' isn't defined for the type 'LLMPromptBuilder'.
lib/sevices/llm_service.dart:109:38 | undefined_method | The method 'ifEmpty' isn't defined for the type 'String'.
lib/sevices/llm_service.dart:112:7 | undefined_identifier | Undefined name 'Log'.
lib/sevices/llm_service.dart:115:7 | undefined_identifier | Undefined name 'Log'.
lib/sevices/llm_service.dart:128:35 | undefined_method | The method 'buildCommandParsingPrompt' isn't defined for the type 'LLMPromptBuilder'.
lib/sevices/llm_service.dart:143:7 | undefined_identifier | Undefined name 'Log'.
lib/sevices/llm_service.dart:158:9 | undefined_identifier | Undefined name 'Log'.
lib/sevices/llm_service.dart:163:11 | undefined_identifier | Undefined name 'Log'.
lib/sevices/llm_service.dart:171:11 | undefined_identifier | Undefined name 'Log'.
lib/sevices/llm_service.dart:216:56 | expected_token | Expected to find '}'.
lib/sevices/voice_client.dart:4:8 | uri_does_not_exist | Target of URI doesn't exist: 'package:speech_to_text/speech_to_text.dart'.
lib/sevices/voice_client.dart:11:9 | undefined_class | Undefined class 'SpeechToText'.
lib/sevices/voice_client.dart:11:32 | undefined_method | The method 'SpeechToText' isn't defined for the type 'VoiceService'.
lib/sevices/voice_llm_bridge.dart:9:9 | undefined_class | Undefined class 'LLMService'.
lib/sevices/voice_llm_bridge.dart:13:14 | undefined_class | Undefined class 'LLMService'.
lib/sevices/wearable_service.dart:12:9 | undefined_class | Undefined class 'HealthFactory'.
lib/sevices/wearable_service.dart:17:19 | undefined_method | The method 'HealthFactory' isn't defined for the type 'WearableService'.
lib/sevices/wearable_service.dart:54:14 | undefined_identifier | Undefined name 'HealthFactory'.
lib/ui/components/LLMAdviceCard.dart:4:8 | uri_does_not_exist | Target of URI doesn't exist: '../../../hydrion/app/lib/services/llm_service.dart'.
lib/ui/components/LLMAdviceCard.dart:49:30 | non_type_as_type_argument | The name 'LLMService' isn't a type, so it can't be used as a type argument.
lib/ui/components/ReminderTile.dart:3:8 | uri_does_not_exist | Target of URI doesn't exist: '../../../hydrion/app/lib/services/notifications.dart'.
lib/ui/components/ReminderTile.dart:34:34 | non_type_as_type_argument | The name 'NotificationService' isn't a type, so it can't be used as a type argument.
lib/ui/components/VoiceInputWidget.dart:3:8 | uri_does_not_exist | Target of URI doesn't exist: '../../../hydrion/app/lib/services/voice_service.dart'.
lib/ui/components/VoiceInputWidget.dart:31:35 | non_type_as_type_argument | The name 'VoiceService' isn't a type, so it can't be used as a type argument.
lib/ui/components/VoiceInputWidget.dart:45:31 | non_type_as_type_argument | The name 'VoiceService' isn't a type, so it can't be used as a type argument.
lib/ui/screens/AnalyticScreen.dart:4:8 | uri_does_not_exist | Target of URI doesn't exist: '../../../hydrion/app/lib/services/ai_bridge.dart'.
lib/ui/screens/AnalyticScreen.dart:5:8 | uri_does_not_exist | Target of URI doesn't exist: '../../../hydrion/app/lib/services/eco_tracker.dart'.
lib/ui/screens/AnalyticScreen.dart:31:18 | non_type_as_type_argument | The name 'AIBridge' isn't a type, so it can't be used as a type argument.
lib/ui/screens/AnalyticScreen.dart:32:30 | non_type_as_type_argument | The name 'EcoTracker' isn't a type, so it can't be used as a type argument.
lib/ui/screens/AnalyticScreen.dart:37:16 | undefined_method | The method 'getText' isn't defined for the type 'I18nResolver'.
lib/ui/screens/AnalyticScreen.dart:53:20 | undefined_method | The method 'getText' isn't defined for the type 'I18nResolver'.
lib/ui/screens/AnalyticScreen.dart:68:20 | undefined_method | The method 'getText' isn't defined for the type 'I18nResolver'.
lib/ui/screens/AnalyticScreen.dart:78:24 | undefined_method | The method 'getText' isn't defined for the type 'I18nResolver'.
lib/ui/screens/ArVisualizationScreen.dart:18:3 | undefined_class | Undefined class 'ARSessionManager'.
lib/ui/screens/ArVisualizationScreen.dart:19:3 | undefined_class | Undefined class 'ARObjectManager'.
lib/ui/screens/ArVisualizationScreen.dart:23:72 | undefined_class | Undefined class 'ARAnchorManager'.
lib/ui/screens/ArVisualizationScreen.dart:23:91 | undefined_class | Undefined class 'ARLocationManager'.
lib/ui/screens/ArVisualizationScreen.dart:23:33 | undefined_class | Undefined class 'ARSessionManager'.
lib/ui/screens/ArVisualizationScreen.dart:23:53 | undefined_class | Undefined class 'ARObjectManager'.
lib/ui/screens/ArVisualizationScreen.dart:38:9 | undefined_method | The method 'ARNode' isn't defined for the type '_ArVisualizationScreenState'.
lib/ui/screens/ArVisualizationScreen.dart:39:17 | undefined_identifier | Undefined name 'NodeType'.
lib/ui/screens/ArVisualizationScreen.dart:65:26 | undefined_method | The method 'getText' isn't defined for the type 'I18nResolver'.
lib/ui/screens/ArVisualizationScreen.dart:72:35 | undefined_identifier | Undefined name 'PlaneDetectionConfig'.
lib/ui/screens/ArVisualizationScreen.dart:85:24 | undefined_method | The method 'getText' isn't defined for the type 'I18nResolver'.
lib/ui/screens/ChatCoachScreen.dart:4:8 | uri_does_not_exist | Target of URI doesn't exist: '../../../hydrion/app/lib/services/llm_service.dart'.
lib/ui/screens/ChatCoachScreen.dart:31:30 | non_type_as_type_argument | The name 'LLMService' isn't a type, so it can't be used as a type argument.
lib/ui/screens/ChatCoachScreen.dart:73:18 | undefined_method | The method 'getText' isn't defined for the type 'I18nResolver'.
lib/ui/screens/ChatCoachScreen.dart:91:16 | undefined_method | The method 'getText' isn't defined for the type 'I18nResolver'.
lib/ui/screens/ChatCoachScreen.dart:151:40 | undefined_method | The method 'getText' isn't defined for the type 'I18nResolver'.
lib/ui/screens/HomeScreen.dart:3:8 | uri_does_not_exist | Target of URI doesn't exist: '../../../hydrion/app/lib/services/ai_bridge.dart'.
lib/ui/screens/HomeScreen.dart:4:8 | uri_does_not_exist | Target of URI doesn't exist: '../../../hydrion/app/lib/services/eco_tracker.dart'.
lib/ui/screens/HomeScreen.dart:19:34 | non_type_as_type_argument | The name 'AIBridge' isn't a type, so it can't be used as a type argument.
lib/ui/screens/HomeScreen.dart:20:36 | non_type_as_type_argument | The name 'EcoTracker' isn't a type, so it can't be used as a type argument.
lib/ui/screens/HomeScreen.dart:26:16 | undefined_method | The method 'getText' isn't defined for the type 'I18nResolver'.
lib/ui/screens/HomeScreen.dart:27:56 | undefined_getter | The getter 'locale' isn't defined for the type 'BuildContext'.
lib/ui/screens/HomeScreen.dart:27:31 | undefined_method | The method 'getTextDirection' isn't defined for the type 'I18nResolver'.
lib/ui/screens/HomeScreen.dart:41:20 | undefined_method | The method 'getText' isn't defined for the type 'I18nResolver'.
lib/ui/screens/HomeScreen.dart:43:60 | undefined_getter | The getter 'locale' isn't defined for the type 'BuildContext'.
lib/ui/screens/HomeScreen.dart:43:35 | undefined_method | The method 'getTextDirection' isn't defined for the type 'I18nResolver'.
lib/ui/screens/HomeScreen.dart:54:20 | undefined_method | The method 'getText' isn't defined for the type 'I18nResolver'.
lib/ui/screens/HomeScreen.dart:56:60 | undefined_getter | The getter 'locale' isn't defined for the type 'BuildContext'.
lib/ui/screens/HomeScreen.dart:56:35 | undefined_method | The method 'getTextDirection' isn't defined for the type 'I18nResolver'.
lib/ui/screens/HomeScreen.dart:62:24 | undefined_method | The method 'getText' isn't defined for the type 'I18nResolver'.
lib/ui/screens/HomeScreen.dart:67:64 | undefined_getter | The getter 'locale' isn't defined for the type 'BuildContext'.
lib/ui/screens/HomeScreen.dart:67:39 | undefined_method | The method 'getTextDirection' isn't defined for the type 'I18nResolver'.
lib/ui/screens/LogScreen.dart:5:8 | uri_does_not_exist | Target of URI doesn't exist: '../../../hydrion/app/lib/services/wearable_service.dart'.
lib/ui/screens/LogScreen.dart:26:35 | non_type_as_type_argument | The name 'WearableService' isn't a type, so it can't be used as a type argument.
lib/ui/screens/LogScreen.dart:39:26 | undefined_method | The method 'getText' isn't defined for the type 'I18nResolver'.
lib/ui/screens/LogScreen.dart:53:24 | undefined_method | The method 'getText' isn't defined for the type 'I18nResolver'.
lib/ui/screens/LogScreen.dart:62:24 | undefined_method | The method 'getText' isn't defined for the type 'I18nResolver'.
lib/ui/screens/LogScreen.dart:78:41 | type_test_with_undefined_name | The name 'HealthDataValueNumeric' isn't defined, so it can't be used in an 'is' expression.
lib/ui/screens/LogScreen.dart:79:37 | cast_to_non_type | The name 'HealthDataValueNumeric' isn't a type, so it can't be used in an 'as' expression.
lib/ui/screens/LogScreen.dart:93:26 | undefined_method | The method 'getText' isn't defined for the type 'I18nResolver'.
lib/ui/screens/SettingsScreen.dart:33:26 | undefined_method | The method 'getText' isn't defined for the type 'I18nResolver'.
lib/ui/screens/SettingsScreen.dart:51:35 | undefined_method | The method 'getText' isn't defined for the type 'I18nResolver'.
lib/ui/screens/SettingsScreen.dart:69:40 | undefined_method | The method 'loadLocale' isn't defined for the type 'I18nResolver'.
lib/ui/screens/SettingsScreen.dart:72:59 | undefined_method | The method 'getText' isn't defined for the type 'I18nResolver'.
lib/ui/screens/SettingsScreen.dart:88:32 | undefined_method | The method 'getText' isn't defined for the type 'I18nResolver'.
lib/ui/screens/SettingsScreen.dart:90:22 | undefined_method | The method 'getText' isn't defined for the type 'I18nResolver'.
lib/ui/screens/SettingsScreen.dart:94:29 | undefined_method | The method 'requestPermissions' isn't defined for the type 'Permissions'.
lib/ui/screens/SettingsScreen.dart:97:47 | undefined_method | The method 'getText' isn't defined for the type 'I18nResolver'.
lib/ui/screens/SocialChallengeScreen.dart:4:8 | uri_does_not_exist | Target of URI doesn't exist: '../../../hydrion/app/lib/services/ai_bridge.dart'.
lib/ui/screens/SocialChallengeScreen.dart:6:8 | uri_does_not_exist | Target of URI doesn't exist: '../../../hydrion/app/lib/ai/ai.dart'.
lib/ui/screens/SocialChallengeScreen.dart:26:29 | non_type_as_type_argument | The name 'AIBridge' isn't a type, so it can't be used as a type argument.
lib/ui/screens/SocialChallengeScreen.dart:38:26 | undefined_method | The method 'getText' isn't defined for the type 'I18nResolver'.
lib/ui/screens/SocialChallengeScreen.dart:56:28 | undefined_method | The method 'getText' isn't defined for the type 'I18nResolver'.
lib/ui/screens/SocialChallengeScreen.dart:99:63 | undefined_method | The method 'getText' isn't defined for the type 'I18nResolver'.
lib/ui/screens/SocialChallengeScreen.dart:103:48 | undefined_method | The method 'getText' isn't defined for the type 'I18nResolver'.
lib/utils/permissions.dart:54:22 | undefined_method | The method 'HealthFactory' isn't defined for the type 'Permissions'.
lib/utils/permissions.dart:75:22 | undefined_method | The method 'HealthFactory' isn't defined for the type 'Permissions'.
test/widget_test.dart:11:8 | uri_does_not_exist | Target of URI doesn't exist: 'package:hydrion_app/main.dart'.
test/widget_test.dart:16:35 | creation_with_non_type | The name 'MyApp' isn't a class.
```

Warnings and style/info diagnostics are separate from real build blockers. Current warning/info themes:

- Warnings: invalid overrides in `lib/main.dart`, impossible null casts in `lib/sevices/ble_service.dart`, unused variables/imports in UI components.
- Infos/style: package import dependency hints, deprecated API usage, PascalCase Dart filenames, avoid-relative-lib-imports, missing `const`, async context-use warnings.

## Dependency Findings

| Severity | Path | Issue | Evidence | Recommended Fix |
|---|---|---|---|---|
| Critical | `pubspec.yaml` | Imported packages are missing as direct dependencies. | `firebase_core`, `sqflite`, `speech_to_text`, and `path` are imported; only `path` exists transitively and none are direct dependencies except via transitive lock. | Add direct dependencies only if features are retained; otherwise remove imports behind optional adapters. |
| Critical | `pubspec.yaml`, `lib/sevices/llm_service.dart` | Declared AI dependencies do not match implemented imports. | `dart_openai` is declared but never imported; pack clients are imported from nonexistent package paths. | Decide provider model. Keep direct provider SDKs behind adapters; remove unused provider SDKs from app surface. |
| High | `pubspec.yaml` | `any` constraints are used for critical native/FFI packages. | Lines 32-34: `flutter_rust_bridge: any`, `ffi: any`, `timezone: any`. | Pin compatible versions with tested ranges. |
| High | `pubspec.yaml` | Dependency overrides pin packages below latest and can hide conflicts. | Overrides for `intl`, `permission_handler`, and `flutter_local_notifications`; `flutter pub outdated` shows notification latest 21.0.0 and permission latest 12.0.1. | Remove overrides after compatibility testing or document why each override is required. |
| High | `pubspec.yaml` | Hardware/platform packages are used directly from app/UI. | `health`, `flutter_blue_plus`, `ar_flutter_plugin`, `flutter_local_notifications`, `permission_handler` are consumed directly. | Isolate behind app interfaces so unsupported platforms degrade cleanly. |
| Medium | `pubspec.yaml` | Several declared dependencies appear unused in `lib/` and `test/`. | No package imports found for `get_it`, `collection`, `intl`, `path_provider`, `http`, `dio`, `connectivity_plus`, `dart_openai`, `flutter_rust_bridge`, `ffi`, `cupertino_icons`. | Reassess after compile fixes; remove or move to adapters/packages if unused. |
| Medium | `pubspec.yaml` | Many dependencies are stale or locked below latest. | `flutter pub outdated` reports 34 upgradable locked dependencies and 15 constrained below resolvable versions. | Upgrade only after stabilizing compile and tests; do not combine mass upgrades with architecture repair. |
| Medium | `pubspec.yaml`, `pubspec.lock` | Package imports use `package:hydrion/...`, but files are outside `lib/` or missing. | `package:hydrion/packs/...` resolves under `lib/packs/...`, not top-level `packs/...`. | Use proper local package path dependencies, move runtime Dart code under `lib/`, or generate bindings into `lib/ffi/`. |

## Test Findings

| Severity | Path | Issue | Evidence | Recommended Fix |
|---|---|---|---|---|
| Critical | `test/widget_test.dart` | Test imports the wrong package name. | Line 11 imports `package:hydrion_app/main.dart`; actual `pubspec.yaml` name is `hydrion`. | Change to `package:hydrion/main.dart` after exposing a public app widget. |
| Critical | `test/widget_test.dart` | Test targets default counter app widget that does not exist. | Line 16 pumps `const MyApp()`; `lib/main.dart` defines private `_BootstrapApp`. | Replace with Hydrion smoke test around a public `HydrionApp`/bootstrap widget and mocked services. |
| High | `test/` | No service, adapter, or routing tests exist. | Only `test/widget_test.dart` exists. | Add focused tests for localization, permissions facade, notification policy, AI fallback, importable app shell, and route creation. |
| High | `integration_test/` | Dev dependency exists but integration test folder is absent. | `integration_test` appears in `pubspec.yaml`; `rg --files integration_test` fails because folder does not exist. | Add integration tests only after app can boot. |
| Medium | `scripts/test_all.sh` | Script targets wrong paths and nonexistent integration folder. | `cd app && flutter test`; `flutter test integration_tests/`. | Update to root `flutter test` and correct `integration_test/` path once tests exist. |

## Asset and Configuration Findings

| Severity | Path | Issue | Evidence | Recommended Fix |
|---|---|---|---|---|
| Critical | `config/llm_packs.yaml` | Referenced by LLM service but missing. | `lib/sevices/llm_service.dart:49` loads `config/llm_packs.yaml`; file does not exist. | Add real config only when pack clients exist, or make LLM service standalone/fallback without it. |
| Critical | `lib/utils/llm_prompt_builder.dart` | Default prompt path is wrong. | Line 9 defaults to `hydrion/config/prompt_templates.yaml`; declared asset path is `config/`. | Use `config/prompt_templates.yaml` if retaining root asset config. |
| High | `assets/ar/wave_effect.glb` | AR screen references missing asset. | `lib/ui/screens/ArVisualizationScreen.dart:40`; `assets/ar/` has 0 files. | Add real GLB asset or disable/hide AR route until asset and plugin are ready. |
| High | `i18n/` | Localization folder is declared but empty. | `pubspec.yaml` declares `i18n/`; file count is 0. | Add real ARB/JSON/YAML localization assets or remove declaration. |
| High | `config/firebase_config.json` | Firebase config contains placeholder IDs and keys and is not wired to FlutterFire generated files. | Values include `000000000000` and `YOUR_ANDROID_API_KEY`; no `google-services.json`, `GoogleService-Info.plist`, or `firebase_options.dart` found. | Do not use placeholder Firebase config at runtime. Generate proper environment-specific config if Firebase remains. |
| Medium | `config/app.yaml` | Placeholder weather API keys are committed. | `YOUR_OPENWEATHER_API_KEY`, `YOUR_ACCUWEATHER_API_KEY`. | Keep placeholders only in example config, not runtime config loaded by app. |
| Medium | `packs/` | Declared pack asset folders are mostly empty. | File counts: `edge_llm/bindings` 0, `edge_llm/model_pack` 0, Gemini client lib contains no file. | Remove from Flutter assets until runtime files exist, or split packs into separately versioned modules. |
| Medium | `models/` | Python training source is declared as app asset. | `models/training/*.py` and `requirements.txt` are included by `models/` asset glob. | Move runtime model files into a dedicated asset folder such as `assets/models/`. |

## AI and ELKA Readiness Findings

| Severity | Path | Issue | Evidence | Recommended Fix |
|---|---|---|---|---|
| Critical | `lib/sevices/llm_service.dart` | AI service cannot operate standalone because it assumes missing core bridge and pack clients. | Depends on `CoreBridge`, `ByokClient`, `GeminiClient`, `EdgeLlmClient`, and missing `llm_packs.yaml`. | Define interfaces such as `AiProvider`, `PromptRenderer`, `DigestProvider`, and `PolicyValidator`; provide a deterministic standalone fallback. |
| Critical | `lib/ui/screens/SocialChallengeScreen.dart`, `lib/ui/screens/HomeScreen.dart`, `lib/ui/screens/AnalyticScreen.dart` | UI depends on nonexistent `AIBridge`/KMP model imports. | Imports from `../../../hydrion/app/lib/services/ai_bridge.dart` and `../../../hydrion/app/lib/ai/ai.dart`. | UI should depend on app-level use cases, not ELKA/KMP bindings. |
| High | `lib/ui/screens/ChatCoachScreen.dart`, `lib/ui/components/LLMAdviceCard.dart` | UI directly consumes LLM implementation. | `context.read<LLMService>()` and direct method calls. | Insert a `HydrationCoachService` or view model boundary. |
| High | `config/open_ai_config.yaml` | OpenAI-style config exists, but no working OpenAI adapter is implemented. | `dart_openai` dependency is unused; config references endpoint, API key env placeholders, retries, and cache. | Move provider config into optional adapter configuration; do not load cloud providers unless explicitly configured. |
| High | `packs/byok_llm`, `packs/gemini_connector`, `packs/edge_llm` | Provider pack code is empty or structurally invalid. | 0-byte Dart/JS/package files; directory named `gemini_client.dart`. | Build real provider packages or remove from runtime until implemented. |
| Medium | Whole repo | No concrete ELKA code found in source search. | `rg -n "ELKA|elka"` found no runtime ELKA integration. | Treat ELKA as future optional integration. Hydrion must boot without it. |
| Medium | Architecture | Required direction is not yet represented in code. | UI references missing external bridges; no interfaces/adapters are present. | Enforce: Hydrion standalone core first; ELKA optional; providers behind interfaces; UI never imports ELKA. |

Recommended AI/ELKA boundary:

- `lib/core/ports/hydration_coach.dart`: app-facing interface.
- `lib/core/ports/challenge_generator.dart`: app-facing challenge interface.
- `lib/core/ports/voice_command_parser.dart`: app-facing voice command interface.
- `lib/infrastructure/ai/local_fallback_provider.dart`: no-network standalone provider.
- `lib/infrastructure/ai/openai_provider.dart`, `gemini_provider.dart`, `elka_provider.dart`: optional adapters.
- UI/view models depend only on ports. ELKA package imports live only in `infrastructure/ai/elka_provider.dart`.

## Security and Privacy Findings

| Severity | Path | Issue | Evidence | Recommended Fix |
|---|---|---|---|---|
| High | `config/firebase_config.json`, `config/app.yaml` | Placeholder secrets/config are committed as runtime config. | `YOUR_*` keys and `000000000000` project IDs. | Move to example files or environment-specific secure config. |
| High | `android/app/src/main/AndroidManifest.xml`, `ios/Runner/Info.plist`, `macos/Runner/*.entitlements` | Privacy-sensitive features are used in code but platform permissions/justifications are incomplete. | Code requests Bluetooth, notifications, health, speech, AR/camera-like capability; Android main manifest has no production permissions; iOS plist has no usage descriptions. | Add only required permissions with user-facing rationale after feature set is confirmed. |
| High | `lib/sevices/notifications.dart` | Notification scheduling swallows errors and prints them. | Catch-all at lines 88-90. | Use structured logging/error reporting; surface recoverable errors to caller. |
| Medium | `.gitignore` | Top-level `.env` is not ignored. | `.gitignore` does not include `.env` or `.env.*`; scripts refer to `.env`. | Add environment file ignore rules before real secrets are introduced. |
| Medium | `config/open_ai_config.yaml` | Request logging is configured true in LLM config. | `log_requests: true`, `log_file: "logs/llm_requests.log"`. | Default to not logging prompts or redact/minimize by adapter policy. |
| Medium | `pubspec.yaml` | Health, BLE, notifications, AI, and AR dependencies increase privacy surface. | Direct dependencies include `health`, `flutter_blue_plus`, `flutter_local_notifications`, `dart_openai`, `ar_flutter_plugin`. | Put all privacy-sensitive integrations behind explicit opt-in feature gates and adapter interfaces. |
| Low | Security scan | No real API keys/tokens were found in committed files during regex scan. | Scan found placeholders, not real tokens. | Continue scanning before commits; add CI secret scanning later. |

## Dead Code and Cleanup Findings

| Severity | Path | Issue | Evidence | Recommended Fix |
|---|---|---|---|---|
| Critical | `lib/sevices/core_bridge.dart`, `lib/utils/logging.dart` | Empty files imported by runtime code. | 0-byte files; analyzer missing `CoreBridge` and `Log`. | Implement or remove references after architecture decision. |
| High | `lib/ui/components/IntakeRing.dart`, `LLMAdviceCard.dart`, `ReminderTile.dart`, `VoiceInputWidget.dart` | Components are not imported by filename anywhere. | Import trace found no filename imports. | Do not delete yet; first repair screen architecture and confirm intended usage. |
| High | `lib/ui/screens/AnalyticScreen.dart`, `lib/ui/screens/HomeScreen.dart` | Duplicate `AnalyticsScreen` implementations and no real `HomeScreen`. | Class list shows `AnalyticsScreen` in both files; `HomeScreen` class is absent. | Consolidate into one analytics screen and create/restore home screen. |
| High | `lib/ui/screens/SocialChallengeScreen.dart` | File is not imported under its real name, while main imports a nonexistent plural filename. | Main imports `SocialChallengesScreen.dart`; real file is `SocialChallengeScreen.dart`. | Correct route import after deciding filename convention. |
| High | `packs/*`, `core/crates/hydrion_*` | Empty placeholder modules are present. | Multiple 0-byte pack files and empty underscore Rust crates. | Keep until tracing confirms intent; then either implement or remove in a dedicated cleanup PR. |
| Medium | `scripts/dev_setup.sh` | Generates bindings into old app path. | Lines 238-239 output to `app/lib/ffi/core_bridge.dart`. | Update only after Rust workspace and Flutter FFI boundary are real. |
| Medium | `hydrion.txt`, `p1.txt`, `overview` | Planning docs reference old app layout and future systems not in repo. | Multiple references to `app/`, `.env.example`, cloud functions, generated FFI. | Move to `docs/archive/` or update after source compiles. |
| Low | `hydrion2.txt` | File appears deleted in current working tree. | `git status` reports `D hydrion2.txt`. | Confirm with owner before restoring or removing. |

## Platform Readiness

| Platform | Current Status | Blockers | Required Fixes |
|---|---|---|---|
| Android | Not build-ready. Platform scaffold exists, but local build could not run without Android SDK and CI will currently stop at analyze/test. | Dart compile errors; local missing Android SDK; default `com.example` application ID; debug signing for release; missing production permissions for BLE/health/notifications/speech; no Firebase Android config. | Fix Dart compile first; configure SDK in local/CI; set real app ID/signing; add justified permissions; add real Firebase config only if Firebase remains. |
| iOS | Not build-ready. Scaffold exists, but plugin/privacy configuration is incomplete. | Dart compile errors; default bundle ID; no usage descriptions for health/Bluetooth/speech/camera/notifications; no visible `ios/Podfile`; no Firebase iOS config. | Fix Dart compile; add Podfile/plugin setup if required; set bundle ID/team; add privacy usage strings; configure Firebase only if needed. |
| Web | Not build-ready. Build reaches Dart compilation and fails. | Missing imports/dependencies; AR/health/BLE code not isolated; wasm dry run warns on geolocator web transitive `dart:html`; default web metadata. | Fix Dart compile; gate platform-specific features; update web title/manifest; decide whether wasm support matters. |
| macOS | Not build-ready. Scaffold exists and generated plugin registrant imports path provider only. | Dart compile errors; default bundle ID/copyright; no health/BLE/AI/native adapter strategy; sandbox entitlements only basic. | Fix Dart compile; define supported desktop feature set; configure entitlements and bundle metadata. |
| Windows | Not build-ready. Scaffold exists. | Dart compile errors; default `com.example` metadata; native FFI/health/BLE support not wired. | Fix Dart compile; decide whether Windows is supported; configure app metadata and adapters. |
| Linux | Folder exists but not declared in `pubspec.yaml` `platforms`. | Dart compile errors; `pubspec.yaml` lists android/ios/web/macos/windows only; desktop hardware/health features not supported. | Either declare and support Linux intentionally or remove/generated-folder support after tracing. |

## Recommended Refactor Plan

### Phase 1: Build blockers

1. Establish canonical package/folder layout: root Flutter app, `lib/services/` or a deliberate alternative.
2. Fix import paths and package name mismatches.
3. Restore a public app widget and actual `HomeScreen`.
4. Repair `lib/sevices/llm_service.dart` syntax or temporarily remove it from app bootstrap behind a fallback interface.
5. Align service constructor APIs used by `main.dart`.
6. Add only direct dependencies that are truly needed (`firebase_core`, `sqflite`, `speech_to_text`, `path`) or remove the corresponding feature imports.

### Phase 2: Test repair

1. Replace default counter widget test with a Hydrion app-shell smoke test.
2. Mock service interfaces instead of booting real hardware/cloud services.
3. Add tests for localization, permissions facade, notification policy, AI fallback, and route table construction.
4. Add integration tests only after the app boots reliably.

### Phase 3: Dead code cleanup

1. Trace all imports after compile passes.
2. Remove or archive empty placeholder files only when no runtime reference remains.
3. Consolidate duplicate `AnalyticsScreen` files and fix Dart filename conventions.
4. Move planning/spec notes into docs or archive.
5. Split training code from runtime assets.

### Phase 4: Hydrion standalone core

1. Define app-domain interfaces for hydration logging, reminders, coaching, challenges, voice parsing, and wearable sync.
2. Implement pure Dart/no-network fallback services so the app boots without ELKA, Firebase, cloud AI, BLE, health, or AR.
3. Gate hardware/platform features with capability checks.
4. Keep storage schema explicit and versioned.

### Phase 5: ELKA adapter boundary

1. Treat ELKA as optional infrastructure, not app core.
2. Put ELKA imports in one adapter package/file only.
3. Keep UI dependent on app interfaces/view models.
4. Add provider selection: standalone fallback first, optional ELKA/provider adapters when configured.
5. Add adapter contract tests to prove Hydrion works with and without ELKA.

### Phase 6: Real release/deployment automation

1. Keep current Flutter CI.
2. Add Android/web artifact builds after analyze/test pass.
3. Add Rust CI only after `core/cargo.toml` and crates are structurally valid.
4. Do not create deploy workflows until a real backend/cloud deployment target exists.
5. Add secret scanning, dependency review, and release signing checks after source is stable.

## Do Not Touch Yet

- `core/`: contains real Rust code plus broken/empty workspace entries. Do not delete until Rust ownership and Flutter FFI boundary are decided.
- `packs/`: empty now, but may represent intended AI provider boundaries. Do not delete until AI adapter plan is accepted.
- `models/training/`: not runtime Flutter assets, but may be useful training source. Move rather than delete after tracing.
- `lib/ui/components/IntakeRing.dart`, `LLMAdviceCard.dart`, `ReminderTile.dart`, `VoiceInputWidget.dart`: currently unreferenced by filename, but likely intended UI features.
- `hydrion.txt`, `p1.txt`, `overview`: stale architecture notes, but useful context for intended roadmap.
- `.github/workflows/flutter-ci.yml`: root path is fixed and CI/CD should stay. Do not remove CI/CD.
- `scripts/deploy_firebase.sh`: suspicious because no `cloud/functions` exists, but do not remove until deployment direction is confirmed.
- `hydrion2.txt`: currently deleted in the working tree; confirm intent before restoring or permanently removing.
