# Hydrion Language Readiness

Generated against the final-completion working tree on 2026-08-01. Run
`dart run tool/localization_audit.dart` for current machine-readable counts.

No locale in this table has recorded native-speaker review. Medical, legal,
privacy, and safety wording requires native-speaker review before a translated
locale can be described as linguistically release-ready.

| Locale | Required keys | Translated keys | Missing | Fallbacks | Flutter | Android widgets | Notifications | Accessibility | Legal/safety | Layout | Native review | Enabled |
|---|---:|---:|---:|---:|---|---|---|---|---|---|---|---|
| English | 559 | 559 | 0 | 0 | Key-complete; visible-literal audit open | 22/22 | Timed-session copy present | ARB coverage present; literal audit open | Present | Existing responsive tests pass | Not required for source language; editorial review remains | Yes |
| French | 559 | 559 | 0 | Not yet proven zero | Key-complete; mixed-language audit open | 22/22 | Timed-session actions present | ARB coverage present; literal audit open | Present; native review required | Existing targeted layouts pass; full audit open | Not recorded | Yes, existing availability; release gate open |
| Spanish | 559 | 559 | 0 | Not yet proven zero | Key-complete; mixed-language audit open | 22/22 | Timed-session actions present | ARB coverage present; literal audit open | Present; native review required | Existing targeted layouts pass; full audit open | Not recorded | Yes, existing availability; release gate open |
| Portuguese (Brazil) | 559 | 0 | 559 | Not applicable while hidden | Missing | 0/22 | Missing | Missing | Missing | Not run | Not recorded | No |
| German | 559 | 0 | 559 | Not applicable while hidden | Missing | 0/22 | Missing | Missing | Missing | Not run | Not recorded | No |

## Current Blockers

- `tool/production_string_audit.dart` reports 235 likely production-facing
  literals: 11 reviewed with explicit reasons and 224 unresolved. The genuine
  literals must move into ARB/native resources; the audit must not be suppressed.
- French and Spanish must not be called mixed-language-clean until that audit
  reaches zero relevant findings and representative screen tests pass.
- Portuguese-Brazil and German have no ARB or Android resource pack and remain
  unavailable in `HydrionLocaleRegistry`.
- Plural, date, time, number, volume-unit, notification, widget, TalkBack, and
  narrow-layout matrices still require explicit per-locale tests.

The language preference is stored separately from profile-owned health data and
is intentionally preserved by ordinary profile deletion.
