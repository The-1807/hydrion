# Hydrion AI Action Contract

Hydrion is standalone-first. Gemini is available as an optional configured provider in Phase 4. ELKA, BYOK, edge models, cloud sync, and native plugins remain inactive future adapters.

## Phase 3.2 Checkpoint

| Area | Status |
|---|---|
| Localization | Flutter `gen_l10n` is active with `lib/l10n/app_en.arb`, `app_es.arb`, and `app_fr.arb`. |
| Active locales | English, Spanish, and French only. |
| Future locales | Arabic, German, Portuguese, and Chinese remain future candidates until real ARB files exist. |
| Runtime i18n assets | The old `/i18n` folder is not restored as a runtime asset. |
| `assets/icons/.gitkeep` | Not tracked in the current checkpoint; `assets/icons/icon1807.jpg` is the active icon asset. |
| `web/favicon.png` | Tracked and intentional as the current web favicon. It was not changed in Phase 3.3. |
| `flutter_01.png` | Tracked but not a Flutter runtime asset in `pubspec.yaml`. It was left untouched for later asset review. |

## Typed Context Models

Hydrion providers receive typed context instead of stringly JSON.

| Model | Purpose |
|---|---|
| `DailyHydrationSummary` | Today date, consumed ml, target ml, entry count, and derived hydration percent. |
| `ReminderContext` | Saved reminder count, next local reminder definition, and OS notification availability. |
| `ChallengeContext` | Active local challenge state, target, duration, completed days, today ml, and derived progress. |
| `CapabilityContext` | Capability snapshot for local persistence, ELKA, Gemini, cloud AI, cloud sync, voice, BLE, Health, OS notifications, AR, and social sync. |
| `HydrationContext` | Complete typed provider context: daily summary, lifetime ml, event count, reminder, challenge, and capabilities. |

`LocalHydrationContextProvider` builds this context from repositories and
`AppCapabilityReporter`. Future providers must consume this typed context
instead of parsing JSON payloads.

## Typed Action Outputs

Providers may propose actions, but Hydrion validates and executes. Provider
outputs use `HydrationAiAction` variants:

| Action | Meaning |
|---|---|
| `CoachMessageAction` | A text-only coaching message. |
| `SuggestReminderAction` | A suggested local reminder definition. |
| `SuggestHydrationLogAction` | A suggested hydration log amount. |
| `ExplainTrendAction` | A trend explanation derived from typed hydration context. |
| `SuggestChallengeAction` | A suggested challenge definition. |
| `UnsupportedCapabilityNoticeAction` | A safe notice that a requested capability is not available. |

Provider outputs are proposals. Screens must not directly execute provider
actions.

## Action Execution Rule

Providers never mutate app state directly.

A provider may return a typed `HydrationAiAction`, but Hydrion must:

1. validate the action with `HydrationAiActionValidator`,
2. check capability state,
3. require user confirmation for state-changing actions when appropriate,
4. execute the action only through Hydrion repositories or app services.

Provider adapters must not write hydration logs, reminders, challenge state,
settings, local storage, cloud state, or platform state directly.

In Phase 3.4 there is no central action executor yet. State-changing actions
such as `SuggestHydrationLogAction`, `SuggestReminderAction`, and
`SuggestChallengeAction` are typed proposals only. They expose
`changesAppState`, require confirmation by default, and can only become
executable after validation returns an allowed result and
`canExecute(userConfirmed: true)` passes.

In Phase 4.1, `HydrationAiActionExecutionService` is the central execution
contract. The local executor validates the action, checks current capability
state, rejects unconfirmed state-changing actions, and writes only through
Hydrion repositories. Provider adapters still never mutate app state directly.

In Phase 4.4, `CoachSuggestionService` is the app-facing bridge between
validated provider proposals and Coach UI suggestion cards. The Coach screen
renders neutral `CoachSuggestionCard` DTOs, not provider action classes.
Hydration log, reminder, and challenge suggestions require explicit user
confirmation before `CoachSuggestionService` calls
`HydrationAiActionExecutionService`. Text-only messages, trend explanations,
and unsupported-capability notices remain display-only. Dismissing a card only
removes that pending proposal from the UI/service; it does not mutate app
state.

## Capability Validation

`HydrationAiActionValidator` checks every action before Hydrion trusts it.

Validation blocks:

- actions requiring unavailable capabilities
- claimed OS notification delivery when OS notifications are unavailable
- claimed social sync when social sync is unavailable
- invalid hydration log amounts outside 1 to 5000 ml
- negative reminder delays
- invalid challenge targets or durations
- messages claiming disabled capabilities are active, available, connected,
  configured, scheduled, started, syncing, or working

Capabilities that must remain honest unless explicitly enabled:

- voice input
- OS notifications
- BLE bottle sync
- Health sync
- AR visualization
- social sync
- cloud AI
- cloud sync
- Gemini
- ELKA

## Local Rules Mode

The local fallback coach implements `HydrationAiProvider` and `HydrationCoach`.
It proposes a typed `CoachMessageAction`, validates it against
`CapabilityContext`, and then returns the safe message to the existing UI.

This preserves standalone behavior while enforcing the same contract future
providers must follow.

## Provider Boundaries

UI may depend on domain contracts such as `HydrationCoach`,
`CoachSuggestionService`, `HydrationSummaryService`, `ChallengeGenerator`,
`HydrationCommandParser`, and `AppCapabilityReporter`.

UI must never import:

- ELKA adapters
- Gemini, OpenAI, BYOK, or edge packs
- provider SDKs
- local adapter implementations
- deprecated `AIBridge` or `LLMService` wrappers
- AI action validators, executor internals, provider implementations, or raw
  provider action classes

Architecture tests enforce these rules.

## Phase 4 Optional Gemini Provider

Gemini is the first optional real provider behind `HydrationAiProvider`.
`local_rules` remains the default provider and Hydrion must boot without any
Gemini configuration.

Phase 4.3 confirms the Gemini REST provider can run successfully in local
development while preserving the same typed action contract. A successful
Gemini response is still only trusted after it parses into
`HydrationAiAction` proposals and passes `HydrationAiActionValidator`.

Configuration is compile-time and explicit:

| Dart define | Meaning | Default |
|---|---|---|
| `HYDRION_AI_PROVIDER` | Provider selection. Supported values are `local_rules` and `gemini`. | `local_rules` |
| `HYDRION_GEMINI_API_KEY` | Gemini API key. Empty means Gemini is unavailable. | empty |
| `HYDRION_GEMINI_MODEL` | Gemini model id used by the REST adapter. | `gemini-2.5-flash` |

Example:

```sh
flutter run \
  --dart-define=HYDRION_AI_PROVIDER=gemini \
  --dart-define=HYDRION_GEMINI_API_KEY=...
```

This Dart-define key path is local development only. Production web/mobile
builds must not ship a shared Gemini key inside client artifacts. Future
production options are BYOK, a secure backend proxy, or another provider
strategy that keeps shared secrets out of the client.

The Gemini adapter lives in `lib/adapters/gemini/` and is wired only from the
composition root. It consumes `HydrationContext`, serializes that typed context
into a provider prompt, calls Gemini only when explicitly configured, and parses
the provider response back into `HydrationAiAction` proposals.

Gemini proposals are not trusted directly. `ProviderBackedHydrationCoach`
validates proposals with `HydrationAiActionValidator`, drops invalid or
capability-unsafe output, and falls back to `local_rules` when Gemini is
unconfigured, unavailable, timed out, failed, or returned no valid action.

The Gemini adapter uses the REST endpoint directly through a generic HTTP
client. No Gemini SDK, OpenAI SDK, BYOK SDK, edge model SDK, cloud sync, native
plugin, or ELKA call is added in Phase 4.

Provider UX may show that Gemini is configured, active, and healthy, but this
does not change execution authority: Gemini cannot write logs, reminders,
settings, challenge state, local storage, cloud state, or platform state.
`local_rules` remains available as the fallback path.

Phase 4.4 adds user-facing suggestion cards for validated Gemini/local_rules
proposals. Cards show a readable action type, provider source, validation
state, safe details, and confirmation controls for state-changing proposals.
They never display full API keys, raw prompts, raw hydration context, or raw
successful provider responses.

## Gemini Plug-In Point

Gemini now plugs in by implementing `HydrationAiProvider`. It receives
`HydrationContext` and returns typed `HydrationAiAction` proposals. It must not
be imported by UI screens.

## ELKA Plug-In Point

ELKA will plug in later behind the same contracts. The current ELKA shell
remains unconfigured and non-networked. A configured ELKA adapter must provide
typed action proposals and pass `HydrationAiActionValidator` before Hydrion
executes anything.
