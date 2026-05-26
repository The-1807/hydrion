# Hydrion Current-State Audit

Generated: 2026-05-26

Requested path note: this file is intentionally placed in
`docs/archictecture/` because that was the requested path. The canonical
architecture docs folder currently remains `docs/architecture/`.

## Executive Summary

Hydrion is now a functional standalone Flutter app with local persistence,
localized runtime UI, an adapter boundary, typed AI action proposals, and an
optional Gemini provider behind fallback rules. The strongest part of the
system is the local runtime: hydration logs, reminders, settings, challenges,
analytics, eco estimates, and coach context are all tied to one local source of
truth.

The main risks are no longer "does the app work?" but "can the system remain
honest, secure, and maintainable as real providers and native integrations are
added?" The next phase should focus on security, action execution, provider
health, runtime capability modeling, and product workflow depth before adding
more external systems.

## Current Baseline

| Area | Current state | Maturity |
|---|---|---|
| Flutter app shell | Root Flutter app with Home, Log, Analytics, Eco, Coach, Reminders, Settings, Challenges, and AR placeholder routes. | Usable |
| Persistence | `shared_preferences` via `HydrionLocalStore`; memory store for tests. | Good for local MVP |
| Hydration data | Persisted logs are the app source of truth. | Strong |
| Runtime UX | Amount picker, edit/delete logs, empty states, disabled feature labels. | Good |
| Localization | Flutter `gen_l10n` with English, Spanish, and French ARB files. | Good foundation |
| AI/domain boundary | Typed `HydrationContext`, `HydrationAiAction`, validator, provider interfaces. | Strong foundation |
| Local rules mode | Default deterministic provider with no network requirement. | Strong |
| Gemini | Optional configured provider behind `HydrationAiProvider`; falls back to local rules. | Early integration |
| ELKA | Compile-safe unconfigured shell only. | Placeholder |
| Native features | AR, BLE, Health, voice, and OS notifications are explicitly disabled or fallback-only. | Honest but incomplete |
| CI/CD | GitHub workflow runs pub get, deps, analyze, tests with coverage, web build, APK build. | Solid Flutter baseline |
| Scripts | Several scripts still assume old `app/`, `cloud/`, Gradle/KMP, logs, or FFI paths. | Stale |
| Rust/core/packs/models | Aspirational scaffolds exist but are not active Flutter runtime dependencies. | Unsettled |

## Implemented Features

| Feature | Implemented files/layers | What is real now | Needs improvement |
|---|---|---|---|
| Hydration logging | `HydrationRepository`, `HomeScreen`, `LogScreen` | User can select amount, save local logs, edit/delete entries, and persist across reloads. | Add volume bounds in repository beyond `> 0`; add units/goals; consider UUIDs for ids. |
| Home summary | `LocalHydrationSummaryService`, `IntakeRing`, `LLMAdviceCard` | Summary derives from persisted logs; advice card is localized and refreshes on locale change. | Make summary use injectable clock/user goal; reduce screen-level future rebuilding. |
| Analytics | `AnalyticsScreen`, `HydrationScoreCard`, `EcoTracker` | Analytics and eco estimates derive from logs. | Add real trend windows, streaks, goal history, charting, and tests around date edges. |
| Eco impact | `EcoTracker`, `CoreBridge` | Local estimate from lifetime hydration ml. | Replace simple formula with documented assumptions and product copy. |
| Reminders | `ReminderRepository`, `NotificationService`, `ReminderTile`, `RemindersScreen` | Reminder definitions persist locally; UI labels OS notifications disabled. | Add edit/repeat/quiet hours; eventually add real OS notification adapter behind capability gate. |
| Challenges | `ChallengeRepository`, `SocialChallengesScreen`, `LocalChallengeGenerator` | One active local challenge can be joined and progress derives from hydration logs. | Add leave/reset/completion history; fix time-zone/day-boundary risk; support multiple challenge definitions. |
| Coach | `HydrationCoach`, `LocalHydrationCoach`, `ProviderBackedHydrationCoach` | Local coach uses persisted hydration context; Gemini can propose typed actions when explicitly configured. | Add conversation persistence decision; add action confirmation UX and execution pathway. |
| Settings | `SettingsScreen`, `I18nResolver`, `AppCapabilityReporter` | Locale persists; capability dashboard labels disabled/fallback features. | Make provider health and selected AI mode visible; avoid static capability state where runtime availability can change. |
| Localization | `lib/l10n/*.arb`, generated localizations, `I18nResolver` | English, Spanish, and French active; unsupported locales safely fall back. | Continue replacing any remaining service-origin user text; add localization lint/key parity checks in CI. |
| App logo | `assets/icons/icon1807.png`, `HydrionLogo` | Logo is active runtime asset. | Align platform launcher icons/web favicon with brand if not already final. |
| Optional Gemini | `GeminiHydrationAiProvider`, `HydrionAiRuntimeConfig` | Optional REST provider, no SDK, no boot requirement, local fallback on failure. | See provider/security hardening below before production use. |

## Layer Audit

| Layer | Active files | Health | Key concerns |
|---|---|---|---|
| UI screens | `lib/ui/screens/*` | Broadly coherent and localized. | Some screens still directly read repositories; move toward use-case/view-model contracts as complexity grows. |
| UI components | `lib/ui/components/*` | Usable and tested. | Advice and reminder components depend on service outputs; ensure all user-visible service text is localized. |
| Domain contracts | `lib/domain/hydration_contracts.dart` | Strong contract-first center. | File is growing large; split by context/actions/capabilities when churn increases. |
| Local adapters | `lib/adapters/local/*` | Good default mode. | Local adapter imports repository for summaries, which is accepted only for local adapters; keep architecture tests sharp. |
| Gemini adapter | `lib/adapters/gemini/gemini_adapter.dart` | Compile-safe optional provider. | Direct client-side API keys are not production-safe for web; parsing needs stricter schema handling. |
| ELKA adapter | `lib/adapters/elka/elka_adapter.dart` | Honest unconfigured shell. | No real ELKA contract tests beyond shell behavior; do not expand until action execution is hardened. |
| Repositories | `lib/repositories/*` | Simple, reliable local persistence. | No migrations/versioned DTOs beyond keys; no encryption; limited validation; no conflict/sync model. |
| Storage | `lib/storage/local_store.dart` | Clean adapter around shared preferences. | Shared preferences is not encrypted and is not ideal for health-like data. |
| Services | `lib/services/*` | Mostly local/fallback facades. | Capability availability is spread between services and `AppCapabilityReporter`; centralize dynamic capability state. |
| Localization | `lib/l10n`, `I18nResolver` | Correct Flutter-native foundation. | Future language list exists in controller but ARB files are active only for en/es/fr; keep this honest. |
| Tests | `test/*` | Strong for current runtime. | Add golden/visual regressions and provider schema fuzz tests; add test for secret/config hygiene. |
| CI/CD | `.github/workflows/flutter-ci.yml` | Green Flutter baseline. | No Rust/model/script CI; no coverage threshold; no secret scanning; no generated l10n verification step. |
| Scripts | `scripts/*` | Partially useful. | `test_all.sh`, `lint_all.sh`, `deploy_firebase.sh`, and `dev_setup.sh` are stale relative to current root Flutter app. |
| Rust core | `core/*` | Scaffold only. | Cargo workspace lists hyphenated crates that do not match underscore directories; not integrated with Flutter. |
| Packs | `packs/*` | Placeholder/experimental. | Pack strategy is unclear; stale BYOK/Gemini pack code can confuse the active adapter boundary. |
| Models | `models/training/*` | Aspirational ML tooling. | Not wired to product; no model CI; no active asset path in Flutter runtime. |
| Config | `config/*` | Prompt/config placeholders and app YAML. | `config/app.yaml` claims BLE/voice/wearables enabled while runtime disables them; this can mislead contributors. |

## Hardening Priorities

| Priority | Area | Risk | Recommended action |
|---|---|---|---|
| P0 | Secret hygiene | API keys must never be committed or embedded in distributable web/mobile builds. Current `.gitignore` is clean, but any key previously pasted locally should be treated as exposed. | Rotate any exposed key, add secret scanning, document safe local run patterns, and keep real keys out of Git and web builds. |
| P0 | Gemini key model | `--dart-define=HYDRION_GEMINI_API_KEY` can be extracted from web/mobile artifacts. | For production, use BYOK with explicit user entry, a minimal backend proxy, or a platform-secure provider strategy. Do not ship a shared app Gemini key in the client. |
| P0 | Action execution | Providers can propose state-changing actions, but there is no central executor/confirmation UX. | Add `HydrationAiActionExecutor` that validates, asks for confirmation, and writes only through repositories/services. |
| P1 | Provider output schema | Gemini JSON parsing is manually mapped and may accept partial/malformed action objects into fallback defaults. | Add strict schema validation, structured parse errors, max lengths, allowed action counts, and provider output fuzz tests. |
| P1 | Capability honesty | Validator uses keyword windows to detect capability claims in text. | Keep message scanning as defense-in-depth, but require structured capability claims/requirements from providers. |
| P1 | Privacy boundary | Gemini prompt includes typed hydration context; current docs explain the boundary but no runtime consent UX exists. | Add explicit provider enablement screen, context preview, and "data leaves device" copy before non-local provider use. |
| P1 | Local data protection | Shared preferences is not encrypted. Hydration logs can be health-adjacent personal data. | Decide data classification; consider encrypted local storage before real health/provider integrations. |
| P1 | Time/date correctness | `DateTime.now()` is spread across repositories/services/screens. | Add clock abstraction for day boundaries, time zones, challenges, reminders, and analytics. |
| P1 | Config consistency | `config/app.yaml` still says BLE/voice/wearable enabled while UI reports disabled. | Either remove stale runtime claims or document `config/` as dormant templates. |
| P1 | Stale scripts | Scripts still reference missing `app/`, `cloud/`, Gradle/KMP, old logs, and FFI paths. | Update scripts to current root Flutter app or archive them outside active workflow. |
| P2 | Rust workspace | Workspace members do not match some crate directory names and are not active. | Decide whether Rust is Phase 5+; fix workspace or move to archive/experimental docs. |
| P2 | Pack strategy | `packs/byok_llm`, `packs/gemini_connector`, and `packs/edge_llm` are not active app integrations. | Document as future packs, delete from active mental model, or define formal adapter contracts. |
| P2 | Platform metadata | Default Flutter runner metadata remains in places. | Align app id, signing, web manifest, launcher icons, and platform naming before release. |

## Feature Improvements Needed

| Feature area | Improvement |
|---|---|
| Hydration goals | Add user-specific daily target, units, body/activity/weather inputs, and goal history. |
| Logging | Add quick-add customization, validation upper bounds, undo, notes/source filters, and import/export path. |
| Analytics | Add weekly/monthly trends, streaks, goal completion, time-of-day distribution, and accessible charts. |
| Coach | Add clear local/Gemini mode labels, optional chat history, suggested action cards, and confirmation flows. |
| Reminders | Add edit, repeat cadence, quiet hours, snooze, and later OS notification adapter. |
| Challenges | Add completion state, rewards, multiple challenges, leave/reset, and local history. |
| Settings | Add provider configuration UI, privacy explanations, data reset/export controls, and app version/build info. |
| Localization | Add CI key parity checks, screenshot/viewport QA per locale, and avoid hardcoded service strings. |
| Accessibility | Add semantic audits for charts/cards, larger text checks, focus order checks, and contrast review. |
| Release readiness | Replace scaffold README, document setup, add signing/release notes, and ensure app identifiers are real. |

## Disabled Or Fallback Features

| Feature | Current status | Required before activation |
|---|---|---|
| AR visualization | Disabled placeholder route. | Native/plugin adapter, camera permission, assets, capability reporter, and tests. |
| BLE bottle sync | Disabled facade returns unavailable/no scan. | Native BLE plugin, device model, reconnection/sync policy, permissions, privacy copy. |
| Health/wearable sync | Disabled facade except local helper write path. | HealthKit/Google Fit adapter, permission flow, source attribution, conflict handling. |
| Voice input | Disabled UI and service; typed command parser exists. | Microphone/speech adapter, permission flow, locale handling, privacy copy. |
| OS notifications | Reminder definitions only; no platform notification. | Notification plugin, scheduling policy, quiet hours, permission UX, integration tests. |
| Social sync | Local challenge only. | Backend/social adapter, account model, privacy controls, sync conflict rules. |
| Cloud sync | Not implemented. | Account/auth, encrypted transport/storage, sync schema, conflict resolution, opt-in UX. |
| ELKA | Unconfigured shell only. | Adapter contract tests, privacy rules, provider health, action executor. |
| BYOK/OpenAI/edge packs | Not active. | Formal pack strategy and boundary tests before reactivation. |

## Placeholder And Scaffold Inventory

| Path | Current role | Audit recommendation |
|---|---|---|
| `assets/ar/.gitkeep` | Empty future AR asset folder. | Keep only if AR remains planned; not in `pubspec.yaml`. |
| `assets/sounds/.gitkeep` | Empty future sound folder. | Keep as future placeholder; not active. |
| `assets/ui/.gitkeep` | Empty future UI asset folder. | Keep as future placeholder or archive later. |
| `i18n/.gitkeep` | Old inactive i18n folder. | Safe to archive later; active l10n is `lib/l10n`. |
| `packs/edge_llm/bindings/.gitkeep` | Future edge LLM placeholder. | Archive unless Phase 5 includes edge models. |
| `packs/edge_llm/model_pack/.gitkeep` | Future edge model assets. | Archive unless Phase 5 includes edge models. |
| `packs/gemini_connector/client/lib/.gitkeep` | Old pack placeholder separate from active adapter. | Mark stale or archive to avoid confusion with `lib/adapters/gemini`. |
| `core/*` | Rust aspirational core. | Decide active vs archive; fix Cargo workspace if active. |
| `models/training/*` | ML training scaffold. | Keep experimental; do not imply shipped model behavior. |
| `config/open_ai_config.yaml` | Placeholder OpenAI config. | Rename/archive unless OpenAI/BYOK is a near-term phase. |
| `config/firebase_config.json` | Placeholder Firebase values. | Archive until cloud work starts. |
| `config/app.yaml` | Stale feature flags. | Update to match runtime or mark as dormant. |

## Architecture Improvements

| Topic | Current shape | Recommended shape |
|---|---|---|
| Composition root | `HydrionServices` wires repositories, local adapters, Gemini, ELKA shell, and UI providers. | Keep root wiring, but split service graph creation into smaller builders as provider count grows. |
| UI dependencies | UI mostly depends on contracts plus repositories for direct data display. | Add application use cases/view models for Home, Analytics, Log, Reminders, Settings, and Coach. |
| AI actions | Typed proposals plus validator. | Add executor and confirmation UI; no state-changing action should be applied outside executor. |
| Capabilities | Static `AppCapabilities` from reporter. | Add dynamic capability state with provider health, selected provider, last failure, and privacy status. |
| Provider output | REST text parsed into action models. | Use strict schema, structured decode result, max lengths, and explicit rejection reasons. |
| Persistence | JSON lists in shared preferences. | Version DTOs, migrations, encryption decision, backup/export story. |
| Time | Direct `DateTime.now()` usage. | Inject clock/time-zone service across repositories and services. |
| Localization | Good gen_l10n foundation. | Add tooling to prevent hardcoded visible strings and verify ARB parity. |

## CI And Testing Improvements

| Current coverage | Gap | Recommendation |
|---|---|---|
| Widget/runtime tests cover logging, empty states, settings, localization, Gemini fallback, and boundaries. | No golden/visual tests. | Add key viewport screenshots for Home, Settings, Coach, Log, Analytics in en/es/fr. |
| Architecture tests guard UI imports and provider SDK dependencies. | Regex checks can miss indirect architectural drift. | Add stricter import graph checks or custom analyzer rule if the codebase grows. |
| CI runs Flutter analyze/test/web/APK. | No secret scanning. | Add Gitleaks or equivalent before provider work expands. |
| CI uploads coverage. | No coverage threshold. | Add a modest threshold after stabilizing tests. |
| CI does not run Rust/Python/scripts. | Scaffold code can silently rot. | Either add separate experimental CI or archive those areas. |
| `flutter gen-l10n` is not an explicit workflow step. | Generated files can drift. | Add gen-l10n check or build step verification. |

## Security And Privacy Notes

| Area | Status | Concern |
|---|---|---|
| Local-only default | Strong privacy default. | Preserve this as the baseline for all future providers. |
| Gemini optional provider | Explicit Dart-define opt-in, local fallback. | Client-side API keys are not production-safe, especially on web. |
| Provider context | Typed hydration context sent only when provider configured. | Needs consent UX and context visibility before real user rollout. |
| Local storage | Shared preferences. | Not encrypted; consider risk if hydration data is treated as health data. |
| Logs/telemetry | No central telemetry pipeline. | Good for privacy; add explicit policy before analytics/crash telemetry. |
| Config files | Placeholder API keys and cloud configs. | Keep placeholders out of active runtime and document dormant status. |

## Recommended Next Phase

The strongest next move is **Phase 4.1: Provider Safety, Action Execution, and
Release Hygiene**.

| Step | Outcome |
|---|---|
| 1. Add secret hygiene guardrails | Rotate any exposed keys, add secret scanning, document safe provider setup, and prevent API keys in client builds. |
| 2. Build `HydrationAiActionExecutor` | Central place for validation, capability checks, user confirmation, and repository/service writes. |
| 3. Add provider configuration UX | Settings should show selected provider, configured/unconfigured state, last failure, and privacy warning. |
| 4. Harden Gemini parsing | Strict schema, action count/length limits, structured validation failures, tests for malformed provider output. |
| 5. Add privacy consent for non-local AI | User sees what context leaves device before Gemini is enabled. |
| 6. Clean stale config/scripts docs | Update or archive stale scripts/configs that contradict current runtime. |
| 7. Add release metadata cleanup | App id, README, web manifest, launcher icons, signing notes, and Android SDK setup docs. |

Phase 4.1 should happen before ELKA or more providers. It protects the product
from the most likely failure mode: external intelligence suggesting or implying
behavior that Hydrion cannot safely execute.

## Phase 4.1 Acceptance Criteria

| Criterion | Done when |
|---|---|
| Secret hygiene | CI fails on committed secrets and docs show safe local provider configuration. |
| Client key policy | Audit explicitly says whether Gemini is BYOK, proxy-backed, or local-dev only. |
| Action executor | State-changing AI actions can only be executed through one tested executor. |
| Confirmation UX | Suggested hydration logs, reminders, and challenges require user confirmation. |
| Provider health | Settings and Coach show selected provider and fallback state honestly. |
| Strict schemas | Malformed Gemini output is rejected without defaulting into plausible actions. |
| Privacy UX | Enabling non-local providers requires explicit consent and context disclosure. |
| Stale scaffolds | Scripts/config/core/packs are marked active, experimental, or archived. |

## Bottom Line

Hydrion's standalone product core is in a good place. The app now has a real
local data loop, honest disabled states, localization, and a provider boundary.
The next work should not be another provider or a native integration. The next
work should be trust infrastructure: secrets, consent, action execution, strict
provider schemas, and runtime capability health.
