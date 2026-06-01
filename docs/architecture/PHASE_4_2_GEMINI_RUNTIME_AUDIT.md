# Hydrion Phase 4.2 Gemini Runtime Audit

Generated: 2026-05-26

Scope: static repo inspection, official Gemini REST shape check, and a
key-free CORS preflight probe. No API keys were read or logged, and no runtime
code was changed.

## Executive Summary

- Gemini configured? The current shell environment does not expose
  `HYDRION_AI_PROVIDER`, `HYDRION_GEMINI_API_KEY`, or `HYDRION_GEMINI_MODEL`.
  That does not prove the launched Flutter app is unconfigured, because
  Hydrion reads these as compile-time Dart defines. If the UI shows Gemini as
  configured, then the running build has `HYDRION_AI_PROVIDER=gemini` and a
  non-empty `HYDRION_GEMINI_API_KEY`.
- Gemini request attempted? Yes, when the selected provider is `gemini` and a
  coach request runs. If the key is missing, the Gemini provider throws before
  making a network request.
- Gemini HTTP response status class? Not currently visible. The adapter throws
  a status-specific exception for non-2xx responses, but the orchestrator stores
  only a generic fallback reason.
- Parser result? Not currently visible. Hydrion rejects malformed JSON, missing
  `actions`, unknown action types, too many actions, oversized strings, invalid
  amounts, invalid reminder delays, and invalid challenge shapes.
- Validator result? Partly visible. If Gemini returns actions but none survive
  `HydrationAiActionValidator`, Settings can show "Provider returned no safe
  actions after validation." Individual rejection reasons are not surfaced.
- Fallback reason? Current user-visible reasons collapse into broad buckets:
  "Provider failed or timed out; local_rules is active." or "Provider returned
  no safe actions after validation."
- Most likely root cause: request orchestration is working by design and the
  REST shape is broadly correct. Once the UI shows Gemini configured, the most
  likely causes are an HTTP/model/key/quota failure, a timeout, Gemini returning
  text or JSON that does not match Hydrion's strict `{"actions":[...]}` schema,
  or validator rejection. The current app cannot tell those apart at runtime.

## Runtime Configuration

| Setting | Observed behavior | Risk | Recommendation |
|---|---|---|---|
| `HYDRION_AI_PROVIDER` | Read with `String.fromEnvironment`; parsed values are `local_rules` and `gemini`; default is `local_rules`. Current shell env was empty. | If omitted from `flutter run` or build commands, Hydrion silently stays in local rules mode. | Keep local default. Add debug-safe provider diagnostics showing selected provider without secrets. |
| `HYDRION_GEMINI_API_KEY` | Read with `String.fromEnvironment`; only non-empty presence matters. Current shell env presence check was false. | A missing key makes Gemini unavailable. A client-shipped key is extractable from web/mobile artifacts. | Never log the key. Keep local-dev/BYOK/proxy-only policy. Show presence/configured state only. |
| `HYDRION_GEMINI_MODEL` | Read with `String.fromEnvironment`; default is `gemini-2.5-flash`. Current shell env was empty. | Invalid or unavailable model ids cause HTTP failure that currently becomes a generic fallback. | Surface the selected model id and status class in safe diagnostics. |
| Gemini API base URL | `https://generativelanguage.googleapis.com` in `GeminiProviderConfig`. | Low; this matches the public Gemini REST endpoint family. | Keep configurable only for tests/dev diagnostics. |
| Gemini configured flag | `GeminiProviderConfig.isConfigured` is true when the key string is non-empty. | "Configured" currently means local config exists, not that a network call succeeded. | Split "configured" from "last request succeeded" in provider health UI. |
| Capability state | `geminiConfigured` and `cloudAi` are true only when provider is Gemini and a key exists. | Capability state can imply cloud AI is ready before the first request has proven health. | Add provider health fields for last attempt, status class, parser phase, and fallback cause. |
| Timeouts | HTTP client timeout is 12 seconds; orchestrator timeout is 14 seconds. | Timeout and HTTP/parser failures are indistinguishable to the user. | Preserve timeout as a separate safe failure code. |

## Gemini Request Audit

| Area | Current implementation | Expected implementation | Finding | Recommendation |
|---|---|---|---|---|
| Endpoint URL | `GeminiProviderConfig.generateContentUri` builds `{base}/v1beta/{modelPath}:generateContent`. | Official REST examples use `https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent`. | Matches expected generateContent path shape. | Keep path construction; add safe diagnostics for model path only. |
| Model path | Prefixes `models/` unless the configured model already starts with `models/`. | REST path includes `models/{model}`. | Matches expected model path convention. | Validate or smoke-test configured model ids in dev mode. |
| Headers | Sends `Content-Type: application/json` and `x-goog-api-key`. | Official Gemini API requires `x-goog-api-key`; examples also send JSON content type. | Matches expected auth/header shape. | Never log header values. Log only key presence. |
| Request body | Sends `contents: [{ parts: [{ text: prompt }] }]` and `generationConfig.temperature = 0.2`, `responseMimeType = application/json`. | Official REST text prompts use `contents[].parts[].text`; JSON output can use JSON response configuration. | Basic request shape is correct. | Add a formal output schema/response format so Gemini is guided by machine-readable structure, not prompt text alone. |
| Prompt | Includes typed `HydrationContext`, capability state, provider rules, allowed JSON shape, and supported action fields. | Provider should consume typed context and return typed action proposals only. | Good contract framing. | Keep prompt, but pair it with structured output schema. |
| Request attempt | `ProviderBackedHydrationCoach` calls the primary Gemini provider when `selectedProvider == gemini`. | Gemini should be attempted only when selected; unconfigured provider should not network-call. | Correct. Missing key throws before network. | Add safe "attempted" and "not attempted: no key" health reasons. |
| Timeout | HTTP call has 12 second timeout; orchestrator wraps provider calls with 14 second timeout. | Provider failure should fall back to local rules. | Safe fallback exists. | Preserve timeout class separately instead of broad catch-all. |
| Provider mutation | Gemini adapter imports domain/config/http only; no repositories/storage imports. | Providers may propose actions only. | Boundary holds. | Keep architecture tests. |

## Gemini Response Parsing Audit

| Area | Expected | Observed | Risk | Recommendation |
|---|---|---|---|---|
| HTTP status | 2xx proceeds; non-2xx should expose safe status class. | Adapter throws `Gemini request failed with HTTP {statusCode}`; orchestrator catches it and records a generic fallback. | A 400, 401, 403, 404, 429, 500, or timeout all look the same in UI. | Store a redacted provider failure code/status class in provider health. |
| Empty body | 2xx responses should contain JSON. | Empty or invalid JSON will throw during `jsonDecode` and become generic fallback. | User cannot tell empty/malformed body from network failure. | Add parser phase diagnostics such as `response_json_decode_failed`. |
| Response envelope | Expects `candidates[0].content.parts[].text`. | Adapter requires candidates, content, parts, and non-empty joined text. | Safety blocks, no candidates, or altered envelope become generic fallback. | Capture safe envelope flags: has candidates, has text, empty text. |
| Returned text | Should be JSON text containing a top-level object with `actions`. | Parser accepts fenced JSON or substring object extraction, then requires object payload. Plain text or a top-level array is rejected. | Gemini can return natural language or JSON that is syntactically valid but not Hydrion-shaped. | Use structured output schema and keep strict parser. |
| Action schema | Requires `{"actions":[{...}]}` with 1 to 3 entries. | Empty list, missing list, top-level list, and more than 3 actions are rejected. | A valid Gemini answer can still fail Hydrion shape. | Document exact schema in a machine-readable schema object. |
| Accepted action names | `coachMessage`, `suggestHydrationLog`, `suggestReminder`, `explainTrend`, `suggestChallenge`, `unsupportedCapabilityNotice`. | Unknown action types throw `GeminiProviderException`. | Provider wording drift can cause fallback. | Keep rejection, but expose `unknown_action_type` safely. |
| Required fields | Every action requires `type` and `message`; state-changing actions require their specific fields. | Missing or wrong-type fields throw. String integers are accepted for numeric fields. | Missing fields become generic fallback. | Add field-specific safe diagnostics in dev mode. |
| Max limits | Max 3 actions; message 600 chars; ids 96; names 120; descriptions 400; reminder delay 0-1440 minutes; challenge duration 1-365 days. | Parser enforces these limits before validator. | Oversized but otherwise useful output falls back. | Keep limits; ask Gemini for short responses with schema constraints. |
| Capability fields | `requiredCapabilities` must use recognized Hydrion capability names. | Unknown capability names throw. | Provider may invent names like `notificationsEnabled`. | Prefer enum schema for capability values. |
| Structured output | Official docs support structured outputs with JSON schema/response format for predictable type-safe results. | Hydrion currently sets JSON MIME type but does not send a formal response schema. | The model may return syntactically valid JSON that fails Hydrion's action schema. | Add schema-guided output in the next implementation phase. |

## Validator/Fallback Audit

| Condition | What triggers fallback | Whether currently visible to user | Recommendation |
|---|---|---|---|
| Provider is `local_rules` | Gemini is not selected. | Settings shows local provider state. | No change needed. |
| Gemini selected without key | `GeminiProviderUnavailable` before network request. | Initial health can say no key, but a coach attempt may replace it with generic provider failure. | Preserve `no_api_key` as a distinct fallback reason. |
| Gemini HTTP non-2xx | Adapter throws with HTTP status. | Not specifically visible after orchestration. | Preserve status class and sanitized status code. |
| Gemini timeout | HTTP or provider timeout throws. | Not distinguishable from other failures. | Preserve `timeout` as a distinct failure reason. |
| Malformed response envelope | Missing JSON, candidates, content, parts, or text throws. | Not specifically visible. | Preserve response-envelope failure phase. |
| Invalid action JSON | Parser rejects missing `actions`, empty actions, unknown types, wrong fields, invalid ranges, or oversized strings. | Not specifically visible. | Preserve parser rejection reason without raw model text. |
| Validator blocks all actions | `_allowedActions` returns empty after validation. | Settings can show "Provider returned no safe actions after validation." | Add first safe validator reason and blocked capability list. |
| Unsafe capability claim | Message claims disabled voice, OS notifications, BLE, Health, AR, social sync, cloud sync, ELKA, or unavailable cloud AI/Gemini is active. | Only broad validation fallback is visible. | Surface blocked capability labels safely. |
| Valid text-only action | First allowed action message is shown. | User sees Gemini response; health success clears fallback. | Keep this path. |
| State-changing action | Allowed state-changing proposal can be returned by provider, but Hydrion should execute only through the executor with confirmation. | Coach currently displays first action message; auto-apply is not present. | Keep provider output as proposals; add action confirmation UI later. |

## Web Runtime Notes

- Flutter web uses browser networking through `package:http`, so CORS and
  browser fetch failures can surface as exceptions.
- A key-free CORS preflight probe on 2026-05-26 against
  `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent`
  returned HTTP 200 and allowed `POST`, `content-type`, and `x-goog-api-key`
  for a localhost origin. This makes a local Chrome preflight block less likely
  for the inspected endpoint shape.
- This does not prove an authenticated POST will succeed. A real call can still
  fail because of API key restrictions, billing/quota, model id, safety block,
  malformed request, rate limits, or network policy.
- Browser console checks should look for:
  - CORS/fetch errors before a response status exists.
  - HTTP status class only, not full bodies containing user context.
  - Whether the response has `candidates`, `content`, `parts`, and `text`.
  - Whether the candidate text is plain text or Hydrion action JSON.
  - Whether local fallback reason changes after the failed request.
- Debug-safe diagnostics must not log API keys. They also should not log full
  raw prompts or full raw responses containing hydration context unless behind
  explicit debug/dev controls.

## Recommended Fix Plan

### 1. Provider diagnostics

- Add a small redacted provider diagnostic model with:
  - selected provider
  - configured boolean
  - model id
  - request attempted boolean
  - HTTP status class or timeout
  - response envelope phase
  - parser rejection code
  - validator rejection code and blocked capability labels
- Store this through `ProviderHealthReporter` without secrets, raw prompts, or
  raw user hydration context.

### 2. Schema/prompt adjustment

- Keep the current strict `HydrationAiAction` parser and validator.
- Add machine-readable Gemini structured output schema for:
  - top-level object
  - required `actions`
  - supported action type enum
  - required fields per action shape
  - maximum action count and string lengths where supported
- Keep prompt instructions as secondary guidance, not the only schema control.

### 3. Provider status UI improvement

- In Settings and Coach, distinguish:
  - Gemini configured but not yet proven healthy
  - no API key
  - HTTP failure
  - timeout
  - invalid response envelope
  - invalid action schema
  - capability validator rejection
  - local_rules fallback active
- Keep UI provider-blind by reading only app/domain-facing health contracts.

### 4. Runtime smoke test

- Add a dev-only smoke path that can be run with dart defines and a real key,
  but never in CI and never with committed secrets.
- For web, run in Chrome and inspect Network/Console for:
  - OPTIONS preflight result
  - POST status class
  - response envelope shape flags
  - safe fallback code
- Prefer a fake Gemini HTTP client in automated tests and a manual real-provider
  checklist for local development.

## Audit Conclusion

Hydrion's Gemini adapter is being selected and attempted when the runtime config
selects Gemini. The request shape matches the official generateContent endpoint
family, and local web preflight did not show an immediate CORS block. The reason
the user still sees local deterministic fallback is probably not that the UI is
ignoring Gemini; it is that Gemini output is not reaching the "validated safe
action" stage, and the current health model hides the specific failure class.

The next implementation should add redacted provider diagnostics and structured
Gemini output schema before changing product behavior.
