# Hydrion Adapter Boundary

Hydrion must run as a standalone local app. ELKA, Gemini, OpenAI, BYOK packs,
edge model packs, cloud services, and native platform plugins are optional
adapters. The UI must never depend on any of them directly.

## Domain Contracts

The UI may depend on the contracts in `lib/domain/hydration_contracts.dart`:

| Contract | Purpose |
|---|---|
| `HydrationSummaryService` | Provides today's hydration summary from the active runtime source. |
| `HydrationCoach` | Provides short advice and chat-style coaching from hydration context. |
| `ChallengeGenerator` | Creates challenge definitions for the challenge UI. |
| `HydrationCommandParser` | Parses typed or future voice commands into stable intent JSON. |
| `AppCapabilityReporter` | Reports which optional capabilities are actually available. |

These contracts are the only AI/provider-facing boundary that UI screens should
know about.

## Local Rules Mode

The default implementation is local rules mode in
`lib/adapters/local/local_hydrion_adapters.dart`.

Local rules mode:

- Reads hydration data from local repositories.
- Produces deterministic hydration summaries, coach messages, command parsing,
  and challenge definitions.
- Requires no network, provider SDK, cloud account, ELKA runtime, native plugin,
  or platform permission.
- Keeps disabled features explicit through `AppCapabilities.standalone()`.

Hydrion must keep this path working even when every optional adapter is absent.

## Provider Swap Rules

Provider swaps happen in the composition root, currently `HydrionServices` in
`lib/main.dart`.

Allowed:

- `lib/main.dart` may wire local adapters or a future configured adapter into
  the domain contracts.
- Tests may use fake adapters to prove swappability.
- Adapter implementations may import provider SDKs only when the provider is
  intentionally added in a future phase.

Forbidden:

- `lib/ui/**` must not import `lib/adapters/**`.
- `lib/ui/**` must not import ELKA, Gemini, OpenAI, BYOK, edge packs, or cloud
  SDKs.
- `lib/ui/**` must not import deprecated compatibility wrappers such as
  `AIBridge` or `LLMService`.
- `lib/ui/**` must not decide feature availability by guessing. It must read
  `AppCapabilityReporter` when capability state affects user-facing behavior.

The architecture tests in `test/boundary_architecture_test.dart` enforce the UI
import rules.

## Gemini Adapter

Gemini is available as an optional provider in `lib/adapters/gemini/`. It is
not required for boot, is unavailable until configured with Dart defines, and is
wired only from the composition root.

Gemini implements `HydrationAiProvider` and returns typed
`HydrationAiAction` proposals. `ProviderBackedHydrationCoach` validates those
proposals and falls back to local rules when Gemini is absent, unavailable,
failed, timed out, or unsafe.

UI screens continue reading `HydrationCoach`, `ChallengeGenerator`, and
`HydrationCommandParser` without knowing Gemini exists.

## ELKA Plug-In Point

ELKA should plug in later as an adapter behind the same contracts. The current
`lib/adapters/elka/elka_adapter.dart` is a compile-safe unconfigured shell. It
does not call ELKA and does not perform network work.

A future configured ELKA adapter may implement:

- `HydrationSummaryService`, if ELKA owns summary decisions.
- `HydrationCoach`, if ELKA provides advice or chat responses.
- `ChallengeGenerator`, if ELKA generates challenges.
- `HydrationCommandParser`, if ELKA parses commands.
- `AppCapabilityReporter`, if ELKA changes available capability state.

ELKA must remain optional. Hydrion must boot and pass tests with the local
fallback adapters only.

## UI Must Never Import

`lib/ui/**` must never import:

- `lib/adapters/elka/**`
- `lib/adapters/local/**`
- `packs/**`
- Gemini SDKs
- OpenAI SDKs
- BYOK pack clients
- edge LLM packs
- cloud provider SDKs
- deprecated `AIBridge`
- deprecated `LLMService`

If the UI needs a new behavior, add or extend a domain contract first, then wire
an implementation in `HydrionServices`.
