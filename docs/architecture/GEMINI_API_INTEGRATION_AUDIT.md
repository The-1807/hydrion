# Gemini API Integration Audit

Generated: 2026-06-01

Scope: Official Gemini REST documentation, Hydrion's Gemini adapter/config,
orchestrator, provider health, action contract, main service wiring, Settings
and Coach provider status UI, and Gemini tests. ELKA is out of scope and remains
uninvolved.

Primary official references:

- Gemini text generation REST guide:
  https://ai.google.dev/gemini-api/docs/text-generation
- Gemini API key guide:
  https://ai.google.dev/gemini-api/docs/api-key
- `models.generateContent` REST reference:
  https://ai.google.dev/api/generate-content
- Gemini structured output guide:
  https://ai.google.dev/gemini-api/docs/structured-output
- Gemini models and model listing reference:
  https://ai.google.dev/api/models

## Executive Summary

Correct Gemini features for Hydrion:

- Standard REST `generateContent` text generation.
- JSON response mode for `candidates[].content.parts[].text`.
- Strict local parsing into Hydrion's typed `HydrationAiAction` contract.
- Safe HTTP/status/error diagnostics that avoid full keys, prompts, responses,
  and hydration context.
- Optional manual model listing for debugging, not a required preflight for
  every coach request.

Features Hydrion should not use yet:

- Live API, native audio, image/video generation, embeddings, function calling,
  tools, SDK-only chat abstractions, file upload, or automatic provider actions.
- Client-shipped shared production keys. Official API key guidance says keys in
  web/mobile client code are extractable; Hydrion should use local dev keys,
  future BYOK, or a backend proxy for production.

Current implementation status:

- The previous connection approach was partially correct. The endpoint family,
  `models/{model}:generateContent` path, `x-goog-api-key` header, JSON content
  type, `contents[].parts[].text`, and schema-free JSON mode were aligned with
  the official REST examples.
- Phase 4.3 local QA confirmed the Gemini runtime can reach a healthy success
  state: active provider Gemini, no fallback in use, and last diagnostic
  `success`.
- Phase 4.4 adds Coach suggestion cards for validated provider proposals.
  Gemini/local_rules proposals remain typed, validated, and user-confirmed
  before any state-changing executor call.
- Two implementation gaps were found:
  - Hydrion checked `apiKey.trim()` for configuration but sent the untrimmed
    key in the auth header.
  - The optional structured-output path used `generationConfig.responseSchema`,
    which had already produced 4xx diagnostics and no longer matches the
    current structured-output REST guide's preferred `responseFormat.text.schema`
    shape.
- Diagnostics were already careful about Google error messages, but did not
  expose safe key-delivery and request-shape facts needed to compare Hydrion with
  a known-good curl call.

Most likely root cause of the reported failures:

- The original `responseSchema` 4xx was caused by the optional schema request
  shape.
- The later "API key not valid" symptom cannot be proven without the live key,
  but the code had a real key-delivery gap: whitespace could make Hydrion send a
  different header value than curl. Stale Flutter web builds or old Dart defines
  can also explain a curl/app mismatch. New diagnostics now show the trimmed key
  length, prefix/suffix, whitespace/trim status, and auth header length without
  exposing the full key.

Required fixes made:

- Send `config.trimmedApiKey` in the Gemini REST header.
- Keep `responseSchema` off by default.
- Change the optional structured-output body to `generationConfig.responseFormat
  .text.schema` instead of `responseSchema`.
- Add safe key and request diagnostics to provider health and Settings.
- Add tests for trimmed key sending, safe diagnostics, and schema-free fallback.
- Polish Coach and Settings provider UX so normal surfaces show readable
  provider status while detailed safe diagnostics remain in Settings.
- Add suggestion-card UX for hydration logs, reminders, challenges, trend
  explanations, and unsupported capability notices without exposing provider
  internals to UI.

## Official Gemini REST Shape

Endpoint:

```text
POST https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent
```

Headers:

```text
Content-Type: application/json
x-goog-api-key: <trimmed Gemini API key>
```

Auth:

- REST examples use `x-goog-api-key`.
- Model listing examples may also use `?key=...`, but Hydrion's generation path
  should continue using the header because it matches the generateContent docs
  and avoids placing the key in the URL.

Minimal Hydrion body:

```json
{
  "contents": [
    {
      "parts": [
        {
          "text": "Hydrion prompt with typed context and action contract"
        }
      ]
    }
  ],
  "generationConfig": {
    "temperature": 0.2,
    "responseMimeType": "application/json"
  }
}
```

Model naming:

- The REST path uses `models/{model}`.
- Hydrion can accept either `gemini-2.5-flash` or `models/gemini-2.5-flash` and
  normalize to the model path.
- The model listing API can be used manually to confirm a model supports
  `generateContent`, but Hydrion should not block every request on an extra list
  call.

Response shape:

```text
candidates[0].content.parts[].text
```

Structured output guidance:

- The current structured-output guide shows `generationConfig.responseFormat
  .text.mimeType = application/json` and `generationConfig.responseFormat.text
  .schema = { ... }` for REST.
- The API reference also documents legacy/alternate schema fields, including
  `responseSchema` and `responseJsonSchema`. Hydrion should avoid depending on
  them by default because schema-free JSON mode plus local validation is enough
  for the current product need.
- Gemini 2.5 Flash supports structured output, but schema complexity and field
  compatibility can still cause request rejection. Hydrion's strict local parser
  and validator remain mandatory even when structured output is enabled.

## Hydrion Current Implementation

Files inspected:

- `lib/adapters/gemini/gemini_adapter.dart`
- `lib/services/ai_provider_config.dart`
- `lib/services/hydration_ai_orchestrator.dart`
- `lib/services/provider_health.dart`
- `lib/services/coach_suggestion_service.dart`
- `lib/domain/hydration_contracts.dart`
- `lib/main.dart`
- `lib/ui/screens/settings_screen.dart`
- `lib/ui/screens/chat_coach_screen.dart`
- `test/gemini_provider_test.dart`
- `test/coach_suggestion_service_test.dart`
- `test/coach_suggestion_cards_test.dart`
- `test/product_qa_test.dart`
- `docs/architecture/PHASE_4_2_GEMINI_RUNTIME_AUDIT.md`
- `docs/architecture/PROVIDER_SECURITY.md`

Current request shape:

- `GeminiProviderConfig.generateContentUri` builds
  `{apiBaseUrl}/v1beta/{modelPath}:generateContent`.
- `GeminiHttpContentClient` sends JSON with `contents[].parts[].text`.
- Schema-free mode sends `generationConfig.temperature` and
  `responseMimeType: application/json`.
- Optional schema mode now sends `generationConfig.responseFormat.text.schema`.

Current config:

- `local_rules` is default.
- Gemini is selected only through Dart defines:
  - `HYDRION_AI_PROVIDER=gemini`
  - `HYDRION_GEMINI_API_KEY=<key>`
  - `HYDRION_GEMINI_MODEL=<model>`, default `gemini-2.5-flash`
- Gemini is considered configured only when the trimmed key is non-empty.

Current diagnostics:

- Provider health tracks selected/active provider, configured state, model,
  request attempted, HTTP status class, response envelope phase, parser code,
  validator code, blocked capabilities, sanitized Google error status/message,
  detail types, fallback reason, and timestamps.
- New safe key diagnostics track key presence, trimmed length, first 4, last 4,
  whitespace, trim status, and expected `AIza` prefix status.
- New safe request diagnostics track endpoint host, model id/path, auth header
  presence, and auth header value length.

Current fallback path:

- Missing key, HTTP failure, timeout, malformed response envelope, invalid
  provider JSON, parser rejection, and validator rejection all fall back to
  local rules.
- Gemini never mutates app state directly. It only returns typed proposals that
  Hydrion parses, validates, and later executes through app-owned services.
- Coach suggestion cards are built from validated proposal summaries. Hydration
  log, reminder, and challenge suggestions require explicit user confirmation
  before `HydrationAiActionExecutionService` writes through local repositories.
- ELKA remains future/unconfigured and is not called by the Gemini runtime path.

## Gap Analysis

| Area | Official expected behavior | Hydrion previous behavior | Gap | Fix |
|---|---|---|---|---|
| Endpoint | `POST /v1beta/models/{model}:generateContent` | Built `/v1beta/{modelPath}:generateContent` with `modelPath` normalized to `models/...` | None | Kept |
| Model path | `models/{model}` path | Accepted bare or prefixed model ids | None | Kept |
| API key header | `x-goog-api-key` with the exact key value intended for REST | Checked trimmed key for configured state but sent raw `apiKey` | Whitespace could make Hydrion differ from curl | Send `trimmedApiKey` |
| Key placement | Header for generateContent | Header | None | Kept; docs recommend not shipping shared client keys |
| Body contents | `contents[].parts[].text` | Same | None | Kept |
| JSON mode | `generationConfig` can request JSON candidate text | Used `responseMimeType: application/json` | None for minimal JSON mode | Kept |
| Structured output | Current guide prefers `responseFormat.text.schema`; schema fields vary by model/API version | Optional mode used `responseSchema` | Known 4xx risk and inconsistent docs | Replaced optional mode with `responseFormat.text.schema`; default remains off |
| Response parsing | Read candidate text from response envelope | Strictly extracts non-empty parts text | None | Kept |
| Local validation | Apps should validate generated structured data | Parser and validator enforce Hydrion action contract | None | Kept |
| Diagnostics | Debug without leaking secrets or context | Sanitized error status/message existed, but no key/request comparison facts | Could not compare app delivery to curl | Added safe key/request diagnostics |
| Model listing | Available as a REST diagnostic | Not used before generation | No required product gap | Leave as manual/debug-only check |
| Browser/web | API keys in client artifacts are extractable | Dart defines can configure local web builds | Production risk if shared key shipped | Documented local-dev/BYOK/proxy strategy |

## Gemini Feature Decision Matrix

| Gemini feature | Use now? | Why | Hydrion implementation path |
|---|---:|---|---|
| Text generation | Yes | Needed for optional coaching copy | REST `generateContent` |
| JSON response mode | Yes | Hydrion expects machine-readable action proposals | `responseMimeType: application/json` in default request |
| Structured outputs | Not by default | Useful, but previous schema shape caused 4xx and local validation already protects Hydrion | Optional flag only; use current `responseFormat.text.schema` shape |
| Model listing | Manual only | Useful for debugging model/key/project issues, unnecessary request latency otherwise | Manual curl/docs checklist |
| Safety/error handling | Yes | Provider failures must stay local-first and understandable | Safe status class, error status/message, parser/validator diagnostics |
| Live API | No | Not needed for hydration coach | Do not add |
| Native audio | No | No voice provider is wired | Do not add |
| Image/video generation | No | Not part of Hydrion action contract | Do not add |
| Embeddings | No | No retrieval/indexing requirement | Do not add |
| Function calling/tools | No | Providers must not mutate app state or call app tools directly | Keep typed action proposal contract |
| Gemini SDK | No | REST is correct and already sufficient | Keep REST |

## Safe Diagnostics

Displayed:

- Key present: yes/no.
- Trimmed key length.
- First 4 and last 4 characters only.
- Whether the original key string contained whitespace.
- Whether the key was trimmed before sending.
- Whether the trimmed key starts with the expected Google API key prefix
  `AIza`.
- Endpoint host.
- Model id and normalized model path.
- Auth header present: yes/no.
- Auth header value length.
- HTTP status class, not full status body.
- Sanitized Google error status/message/detail types.
- Parser and validator rejection codes.

Never displayed:

- Full Gemini API key.
- Raw prompt.
- Raw hydration context.
- Raw user query.
- Raw provider response text.
- Full Google error body if it appears to contain Hydrion context or secrets.

Safe curl comparison:

- Compare model id/model path and endpoint host exactly.
- Compare key length, first 4, last 4, whitespace, and trim status.
- Compare whether Hydrion says auth header present and whether its value length
  matches the trimmed key used by curl.
- If curl succeeds but Hydrion still reports invalid key, rebuild/re-run the
  Flutter target with fresh Dart defines and check browser devtools for stale
  assets or an older compiled key.

## Fixes Applied

Files changed:

- `lib/services/ai_provider_config.dart`
  - Added `trimmedApiKey`.
  - Made `isConfigured` use the trimmed key.
  - Added safe key diagnostics.
  - Added safe request diagnostics.
- `lib/adapters/gemini/gemini_adapter.dart`
  - Sends `config.trimmedApiKey` in `x-goog-api-key`.
  - Keeps schema-free JSON mode as the default.
  - Replaces optional `responseSchema` with
    `generationConfig.responseFormat.text.schema`.
- `lib/domain/hydration_contracts.dart`
  - Added safe key/request fields to `ProviderDiagnosticSnapshot`.
  - Added app-facing Coach suggestion DTOs and service contract.
- `lib/services/coach_suggestion_service.dart`
  - Added the UI-safe bridge from validated provider proposals to suggestion
    cards and executor confirmation.
- `lib/services/provider_health.dart`
  - Seeds provider health with safe key/request diagnostics.
  - Preserves them through fallback updates.
- `lib/services/hydration_ai_orchestrator.dart`
  - Preserves safe key/request diagnostics on provider failure and validator
    rejection snapshots.
- `lib/ui/screens/settings_screen.dart`
  - Displays safe key/request diagnostics in the provider health card.
- `lib/ui/screens/chat_coach_screen.dart`
  - Renders normal coach messages separately from suggestion cards, fallback
    notices, and confirmation results.
- `lib/l10n/app_en.arb`
- `lib/l10n/app_es.arb`
- `lib/l10n/app_fr.arb`
  - Added labels for the new safe diagnostics and suggestion-card UX.
- `test/gemini_provider_test.dart`
  - Added tests for trimmed key sending.
  - Added tests that safe diagnostics do not include the full key.
  - Updated structured-output request expectations.
  - Extended HTTP failure diagnostics assertions.
- `test/coach_suggestion_service_test.dart`
  - Added tests for text-only messages, confirmed state-changing suggestions,
    and invalid suggestion rejection.
- `test/coach_suggestion_cards_test.dart`
  - Added widget tests for rendering, confirming, dismissing, localization, and
    no secret/debug leakage in normal Coach UI.

Why each change was made:

- Key trimming removes a real mismatch between configuration checks and the
  actual REST header.
- Safe diagnostics make the app/curl comparison possible without leaking a key
  or hydration context.
- `responseSchema` remains off by default because Hydrion only needs JSON text
  plus strict local parsing today.
- The optional schema path now follows the current structured output guide for
  REST, reducing the chance of repeating the known 4xx.
- Suggestion cards improve runtime UX without weakening provider boundaries:
  UI does not import provider implementations, validators, executor internals,
  or raw provider action classes.

## Remaining Manual Test

Curl baseline in PowerShell:

```powershell
$env:HYDRION_GEMINI_API_KEY = "<your Gemini API key>"
curl.exe "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent" `
  -H "x-goog-api-key: $env:HYDRION_GEMINI_API_KEY" `
  -H "Content-Type: application/json" `
  -X POST `
  -d "{`"contents`":[{`"parts`":[{`"text`":`"Return JSON only: {\\`"ok\\`":true}`"}]}],`"generationConfig`":{`"responseMimeType`":`"application/json`"}}"
```

Hydrion run command:

```powershell
flutter run -d chrome `
  "--dart-define=HYDRION_AI_PROVIDER=gemini" `
  "--dart-define=HYDRION_GEMINI_API_KEY=$env:HYDRION_GEMINI_API_KEY" `
  "--dart-define=HYDRION_GEMINI_MODEL=gemini-2.5-flash"
```

What Settings should show:

- Selected provider: Gemini.
- Gemini configured: Configured.
- Endpoint host: `generativelanguage.googleapis.com`.
- Model path: `models/gemini-2.5-flash`.
- API key present: Yes.
- API key length matching the trimmed key length used by curl.
- First 4 and last 4 matching the curl key, with no full key shown.
- Key has whitespace: No, unless the Dart define included surrounding
  whitespace.
- Key was trimmed: No, unless the Dart define included surrounding whitespace.
- Auth header present: Yes.
- Auth header length matching the trimmed key length.

What Coach should show:

- Before the first successful Gemini response, Gemini may be "configured but not
  yet proven healthy."
- After a successful provider response that passes parser and validator,
  `activeProvider` should be Gemini and the last diagnostic should be success.
- Validated provider suggestions should appear as cards. Hydration log,
  reminder, and challenge cards should require confirmation; trend and
  unsupported capability cards should remain display-only.
- If Gemini fails, local_rules remains active and Settings should show the safe
  failure class: HTTP status class, timeout, response envelope phase, parser
  code, or validator code.

Expected fallback diagnostics:

- Bad/missing key: 4xx HTTP status class plus sanitized Google error status and
  message, or `no_api_key` before a network attempt.
- Stale web build: Settings key prefix/suffix/length will not match the curl key
  until the Flutter app is rebuilt or relaunched with fresh Dart defines.
- Malformed provider output: parser rejection code such as
  `json_decode_failed`, `missing_actions`, or `unknown_action_type`.
- Unsafe capability claim: validator code `unsafe_capability_claim` plus blocked
  capability labels.

## Validation Results

- `flutter pub get`: passed.
- `flutter gen-l10n`: passed.
- `dart run tool/secret_scan.dart`: passed, no committed API keys or private key
  blocks found.
- `flutter analyze`: passed, no issues found.
- `flutter test`: passed, all tests passed, including Phase 4.4 suggestion-card
  service/widget QA and UI boundary tests.
- `flutter build web --release`: passed, built `build\web`.
- `flutter build apk --release`: blocked because no Android SDK was found;
  `ANDROID_HOME` is not set in this environment.
