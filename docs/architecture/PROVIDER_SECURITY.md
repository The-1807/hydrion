# Provider Security And Secret Hygiene

Hydrion is local-first. Non-local AI providers are optional and must not weaken
the local privacy baseline.

## Secret Rules

API keys must never be committed to the repository.

Do not commit:

- `.env` or `.env.*`
- provider API keys
- private keys
- generated secret reports
- production signing credentials
- shared Gemini/OpenAI/BYOK credentials

The repository includes a lightweight secret scanner at
`tool/secret_scan.dart`. CI runs it before analysis and tests. It checks for
common committed API key formats and private key blocks. This is not a complete
security program, but it catches the highest-risk mistakes early.

## Gemini Key Policy

Gemini is currently supported only as an optional provider behind Hydrion's
typed action protocol.

Phase 4.3 confirmed local Gemini runtime success with Dart defines. That local
success does not change the production key policy: a shared Gemini key must not
be shipped inside web, mobile, desktop, or generated client artifacts.

Allowed:

- local development with Dart defines
- user-provided BYOK flows in a future phase
- secure backend proxy in a future phase
- another provider strategy that does not place shared production secrets in
  client artifacts

Not allowed:

- committing Gemini API keys
- hardcoding Gemini API keys in Dart, YAML, JSON, HTML, platform files, or docs
- shipping a shared production Gemini key inside web/mobile/desktop client
  artifacts

Local development example:

```sh
flutter run -d chrome \
  --dart-define=HYDRION_AI_PROVIDER=gemini \
  --dart-define=HYDRION_GEMINI_API_KEY=$HYDRION_GEMINI_API_KEY
```

For production web and mobile, Dart defines are not a safe place for a shared
provider key. Treat client bundles as inspectable.

Settings may display safe Gemini diagnostics for troubleshooting: key present,
key length, first four characters, last four characters, whitespace/trim state,
endpoint host, model path, auth header presence, auth header length, status
class, parser/validator codes, and fallback codes. It must never display the
full key, raw prompts, raw hydration context, or raw successful provider
responses.

Coach suggestion cards use only validated proposal summaries: readable action
type, provider source, validation state, safe details, and confirmation/dismiss
controls. They must not surface raw provider prompts, raw hydration context, raw
successful Gemini response bodies, or full API keys.

## Privacy Boundary

When Gemini is configured, Hydrion may send typed hydration context to Gemini.
That context can include daily hydration totals, lifetime tracked milliliters,
event counts, reminder context, challenge context, and capability state.

Before production use of any non-local provider, Hydrion must provide:

- explicit user consent
- a clear "data may leave this device" disclosure
- a visible active-provider status
- a local_rules fallback path
- a provider disable path

## Action Safety

Provider output is only a proposal. Hydrion must validate and execute proposals
through app-owned services:

1. `HydrationAiActionValidator` validates the proposal.
2. `CoachSuggestionService` converts allowed proposals into user-facing cards.
3. `HydrationAiActionExecutionService` requires user confirmation for
   state-changing actions.
4. The executor writes only through Hydrion repositories/services.
5. Providers never write hydration logs, reminders, challenges, settings,
   storage, cloud state, or platform state directly.

Gemini remains optional after local Phase 4.3 success, `local_rules` remains
the default and fallback path, and ELKA remains future/unconfigured in Phase
4.4. The Gemini runtime path and suggestion-card path do not call ELKA.
