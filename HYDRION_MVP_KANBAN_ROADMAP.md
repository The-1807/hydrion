# Hydrion MVP Kanban Roadmap

Date Generated: 2026-06-12

Repository audited: `E:\hydrion_app`

Current repo reconciliation: 2026-07-10 at
`C:\Users\Wildf\OneDrive\Desktop\hydrion`.

Historical path note from the original audit: the pasted request named
`C:\Users\Wildf\hydrion_app`, but that path was not present in that shell. The
active Hydrion repository was found at `E:\hydrion_app`, including the
currently open `docs/architecture/ADAPTER_BOUNDARY.md`.

## Executive Summary

- Where Hydrion started: the repo previously had CI/root confusion, broken
  Flutter imports, native dependency build failures, and mostly in-memory
  fallback runtime state.
- Where Hydrion is now: the root Flutter app is active, CI is structured around
  root `pubspec.yaml`, local persistence exists, runtime UX is usable, disabled
  native features are labeled honestly, `local_rules` is the default AI mode,
  Gemini is optional, and ELKA remains unconfigured/future.
- What MVP means: a standalone local hydration companion that can log, edit,
  persist, summarize, coach locally, localize EN/ES/FR, manage local reminders,
  show local challenges, and build for web/Android without cloud, ELKA, native
  integrations, or production AI secrets.
- What MVP does not mean: no BLE, HealthKit/Google Fit, connected devices, voice
  capture, OS notifications, cloud sync, social backend, ELKA runtime, or
  production shared Gemini key in the client.
- Top blockers:
  1. Production AI provider safety needs explicit consent, key policy, and
     provider health clarity before any non-local provider can be called
     MVP-ready.
  2. Local persistence needs versioned DTOs, validation boundaries, and a data
     protection decision because hydration data is personal.
  3. Date/time behavior needs a clock/time-zone boundary for analytics,
     challenges, reminders, and day rollovers.
  4. Config/scripts/scaffold folders still contain future or stale claims that
     can mislead contributors.
  5. Release metadata, signing, platform identity, PWA branding, and beta smoke
     criteria are not yet release-ready.
- Next sprint: focus on trust and release hygiene, not new integrations. The
  first sprint should close provider consent/key-policy risks, storage schema
  risks, time-boundary correctness, stale config truth, and CI release checks.

## V1 Release Tracking Reconciliation - 2026-07-10

This update reconciles existing MVP/V1 cards to the current repository state.
No new product scope was added.

| Card / area | Current lane | Repo evidence | Notes |
|---|---|---|---|
| Minimal Hydrion startup buffer | Done | `lib/ui/screens/startup_screen.dart`; `test/startup_buffer_test.dart` | Accepted flow is native splash, Flutter buffer with shark Lottie and two startup lines, then normal routing. Real Android appearance still needs video/manual acceptance. |
| Shared hydration source of truth | Done | `lib/repositories/hydration_repository.dart`; `test/persistence_test.dart`; `test/social_challenges_bottle_bingo_test.dart` | Home logging, challenge hydration actions, daily progress, dashboard/history, and coach context all read/write the normal hydration log. |
| Challenge hydration logging | Done | `lib/repositories/challenge_repository.dart`; `lib/ui/screens/social_challenges_screen.dart`; `test/social_challenges_bottle_bingo_test.dart` | Bottle Bingo hydration tiles create one normal hydration log and do not create challenge-only hydration records. |
| Safe-area and fixed-header polish | Done | `lib/ui/screens/hydrion_shell.dart`; `test/responsive_layout_test.dart` | Tab bodies now sit below the top safe area; embedded challenge screen no longer stacks a second top safe area. |
| Progress gauge and weekly rhythm clarity | Done | `lib/ui/components/intake_ring.dart`; `lib/ui/screens/analytics_screen.dart`; `test/hydration_progress_gauge_test.dart` | Gauge is a clean proportional arc; low-data weekly rhythm avoids repeated noisy zero-liter labels. |
| Button and coach input polish | Done | `lib/ui/theme/hydrion_design.dart`; `lib/ui/screens/chat_coach_screen.dart`; `test/coach_suggestion_cards_test.dart` | Shared button states are more consistent; coach send stays disabled until text exists. |
| Local lifecycle reconciliation | Done | `lib/ui/screens/hydrion_shell.dart`; `lib/services/notifications.dart`; `test/notification_service_test.dart` | App resume reconciles local notification schedules and weather-informed goal state when applicable. |
| Unused runtime media cleanup | Done | Asset tree audit; previous V1 cleanup removed unreferenced `assets/UI_BETA/hyd-ad/*` runtime clutter | Remaining referenced media are kept; uncertain/design/archive media are not deleted. |
| Real-device Android startup acceptance | Blocking human verification | N/A | Widget tests prove text/timing/routing logic only. A fresh install and relaunch video/manual pass is still required. |
| BLE, Health, voice, cloud sync, ELKA runtime, social backend | V1.1 or later | Existing roadmap and disabled-feature tests | These remain intentionally out of V1 and should not be moved into V1 release scope. |

## Current Completed Work

| Area | What is done | Evidence | Remaining risk |
|---|---|---|---|
| Flutter root recovery | Root `pubspec.yaml`, `lib/`, and `test/` are active. | `.github/workflows/flutter-ci.yml` validates `pubspec.yaml` and `lib` at repo root. | Developer docs and scripts can still reference older layouts. |
| CI baseline | CI runs pub get, secret scan, analyze, tests with coverage, web build, and APK build. | `.github/workflows/flutter-ci.yml`; `README.md` Validation section. | No coverage threshold or generated localization drift check yet. |
| Runtime shell | App exposes `HydrionApp`, routes, providers, and service graph. | `lib/main.dart`; `test/widget_test.dart`. | `HydrionServices` is growing into a large composition root. |
| Hydration persistence | Hydration logs persist through a local store and support edit/delete. | `lib/repositories/hydration_repository.dart`; `lib/storage/local_store.dart`; `test/persistence_test.dart`; `test/runtime_ux_test.dart`. | DTOs are not versioned; shared preferences is not encrypted. |
| Settings persistence | Locale is persisted and app-localized. | `lib/repositories/settings_repository.dart`; `lib/utils/i18n_resolver.dart`; `lib/l10n/*.arb`. | Only EN/ES/FR are active; future locale list must stay honest. |
| Reminder definitions | Local reminder definitions persist as app data. | `lib/repositories/reminder_repository.dart`; `lib/ui/screens/reminders_screen.dart`. | OS notifications are disabled and not scheduled. |
| Local challenges | Local challenge join state and progress exist. | `lib/repositories/challenge_repository.dart`; `lib/ui/screens/social_challenges_screen.dart`. | One active local challenge only; no completion history. |
| Analytics and eco estimates | Analytics, eco estimate, Home, Log, and Coach read from saved hydration data. | `lib/ui/screens/analytics_screen.dart`; `lib/services/eco_tracker.dart`; `test/runtime_ux_test.dart`. | Trend windows and formula assumptions are shallow. |
| AI adapter boundary | UI depends on domain contracts; providers are behind adapters. | `docs/architecture/ADAPTER_BOUNDARY.md`; `lib/domain/hydration_contracts.dart`; `test/boundary_architecture_test.dart`. | Contracts are large and may need splitting as MVP grows. |
| Local AI default | `local_rules` works without network and remains default/fallback. | `lib/adapters/local/local_hydrion_adapters.dart`; `lib/services/ai_provider_config.dart`; `test/gemini_provider_test.dart`. | Product copy must keep local/default status visible. |
| Optional Gemini | Gemini is optional, Dart-define based, provider-backed, and falls back to local rules. | `lib/adapters/gemini/gemini_adapter.dart`; `docs/architecture/PROVIDER_SECURITY.md`; `test/gemini_provider_test.dart`. | Client-shipped shared keys are not production-safe. |
| ELKA boundary | ELKA is compile-safe but unconfigured and non-networked. | `lib/adapters/elka/elka_adapter.dart`; `test/adapter_contract_test.dart`. | No ELKA integration should be started before MVP safety work. |
| Honest disabled features | Connected devices, BLE, Health, voice, OS notifications, cloud sync, and social sync are labeled disabled/local/future. | `lib/ui/screens/settings_screen.dart`; `docs/CONNECTED_DEVICES_ROADMAP.md`; `test/runtime_ux_test.dart`. | Native work remains post-MVP. |
| Secret hygiene | Basic repo scanner and tests prevent obvious API keys/private keys. | `tool/secret_scan.dart`; `test/secret_hygiene_test.dart`; CI workflow. | Scanner is lightweight; release process needs stronger guardrails. |
| Stale scaffold audit | Active, dormant, future, and stale folders are classified. | `docs/architecture/STALE_SCAFFOLD_AUDIT.md`; `docs/architecture/may5th.md`. | Stale config/scripts remain in repo and need clear treatment. |

## MVP Definition

### Included In MVP

- Standalone Flutter app from the repository root.
- Local hydration logging with amount selection, edit, delete, and persistence.
- Home summary, Log, Analytics, Eco estimate, Coach context, local reminders,
  and local challenges all derived from the same saved hydration source.
- Local reminder definitions stored as app data, clearly not OS notifications.
- Local challenge join/progress state with no social backend.
- Local `local_rules` coach/provider mode as the default and fallback.
- Optional Gemini only for local development behind explicit configuration,
  validation, safe diagnostics, and local fallback.
- EN/ES/FR localization using Flutter `gen_l10n`.
- Honest capability UI for disabled/future features.
- CI green for pub get, secret scan, analyze, tests, web build, and Android APK.
- Basic release metadata and documentation sufficient for an internal beta.

### Excluded From MVP

- ELKA runtime integration.
- Cloud sync, accounts, authentication, backend storage, or Firebase deploy.
- BLE/smart bottle sync.
- HealthKit, Google Fit, or wearable sync.
- Connected-device adapters or fake smart-bottle/watch data.
- Voice capture, microphone permissions, or speech recognition.
- OS notification scheduling.
- Social challenge backend or multiplayer/social graph.
- Rust core/FFI activation.
- Production shared Gemini key in client artifacts.
- OpenAI, BYOK, edge LLM packs, or additional provider SDKs.

### Post-MVP

- Native platform adapters for OS notifications, BLE, Health/wearables, voice, and connected devices.
- ELKA as an optional adapter only after the Hydrion boundary is stable.
- Cloud/social sync with explicit privacy and conflict-resolution design.
- BYOK or backend-proxy AI strategy if non-local providers become a product
  feature.
- Rust/core/model work only after ownership and integration paths are defined.

## GitHub Project Board Structure

### Columns

| Column | Meaning | Entry rule | Exit rule |
|---|---|---|---|
| Backlog | Valid work not ready for implementation. | New issue with unresolved scope, dependencies, or product decision. | Acceptance criteria and dependencies are clear. |
| Ready | Scoped and implementable. | Issue has type, priority, milestone, labels, evidence, tests, and DoD. | Work starts and an owner is assigned. |
| In Progress | Actively being implemented. | Branch/PR or local work exists. | PR opened or work needs review. |
| In Review | Code/docs are ready for review. | PR opened with checklist and tests. | Reviewer approves or requests changes. |
| Testing | Reviewable work is being validated. | Tests/manual QA/release checks are running. | Validation passes or blocker is found. |
| Blocked | Work cannot continue without a decision or dependency. | Blocker is explicit and linked. | Blocker is resolved and issue returns to Ready/In Progress. |
| Done | Merged and verified. | Acceptance criteria, tests, docs, and DoD are complete. | None. |

### Labels

Required type labels:

- `type:user-story`
- `type:bug`
- `type:task`
- `type:security`
- `type:docs`
- `type:test`
- `type:release`
- `type:tech-debt`

Required area labels:

- `area:frontend`
- `area:ai-provider`
- `area:coach`
- `area:persistence`
- `area:localization`
- `area:security`
- `area:ci-cd`
- `area:release`
- `area:docs`
- `area:platform`
- `area:settings`
- `area:reminders`
- `area:analytics`
- `area:challenges`

Required priority labels:

- `priority:p0`
- `priority:p1`
- `priority:p2`
- `priority:p3`

Required status labels:

- `status:blocked`
- `status:needs-review`
- `status:ready`

### Milestones

| Milestone | Goal | Exit criteria |
|---|---|---|
| MVP Stabilization | Make the standalone local app dependable and maintainable. | Storage, time, config, docs, and CI truth are clear. |
| MVP Product UX | Make the local app useful and honest for users. | Core flows are complete enough for beta users. |
| MVP AI Provider Safety | Make local/default AI safe and optional provider paths transparent. | Non-local AI cannot be mistaken for default or production-safe. |
| MVP Release Readiness | Prepare web/Android/internal beta release mechanics. | Metadata, signing docs, smoke tests, and release notes are ready. |
| Post-MVP Native Integrations | Add native features only after MVP. | Adapters, permissions, tests, and privacy copy exist. |
| Post-MVP ELKA Integration | Add ELKA only as an optional adapter. | Hydrion remains standalone; UI does not import ELKA. |
| Post-MVP Cloud/Social Sync | Add backend sync/social only after local model is solid. | Privacy, auth, conflict model, and backend exist. |

### Workflow Rules

- Every issue must have one type label, one or more area labels, one priority,
  one milestone, and one suggested board column.
- `priority:p0` blocks MVP release.
- `priority:p1` blocks MVP beta unless explicitly deferred by product owner.
- Post-MVP issues must not be pulled into MVP unless the milestone is changed
  and acceptance criteria are rewritten.
- Native, cloud, ELKA, and provider work must preserve standalone local mode.
- No issue may mark BLE, Health, connected devices, voice, OS notifications, cloud sync, social
  sync, Gemini production, or ELKA as active unless the implementation, tests,
  permissions, and privacy docs prove it.
- AI/provider issues must include security/privacy notes.
- Release issues must include validation commands and artifacts.

## User Story Template

```md
## Title

Type: type:user-story
Milestone:
Priority:
Labels:
Suggested Kanban column:

### User Story
As a [user/persona], I want [capability], so that [outcome].

### Problem Statement

### Evidence
- Path:
- Current behavior:

### Acceptance Criteria
- [ ]

### Checklist
- [ ]

### Test Requirements
- [ ]

### Security / Privacy

### Definition Of Done
- [ ]

### Dependencies / Blockers
```

## Bug Template

```md
## Title

Type: type:bug
Milestone:
Priority:
Labels:
Suggested Kanban column:

### Problem Statement

### Evidence
- Path:
- Reproduction:
- Expected:
- Actual:

### Acceptance Criteria
- [ ]

### Checklist
- [ ]

### Test Requirements
- [ ]

### Security / Privacy

### Definition Of Done
- [ ]

### Dependencies / Blockers
```

## Technical Task Template

```md
## Title

Type: type:task
Milestone:
Priority:
Labels:
Suggested Kanban column:

### Problem Statement

### Evidence
- Path:
- Current behavior:

### Acceptance Criteria
- [ ]

### Checklist
- [ ]

### Test Requirements
- [ ]

### Security / Privacy

### Definition Of Done
- [ ]

### Dependencies / Blockers
```

## MVP Issues And User Stories

### Milestone: MVP Stabilization

#### MVP-STAB-001 - Version local persistence DTOs and validate stored data

- Issue type: `type:task`
- Milestone: `MVP Stabilization`
- Priority: `priority:p0`
- Labels: `area:persistence`, `area:security`, `type:task`, `priority:p0`, `status:ready`
- User story: As a standalone Hydrion user, I want saved hydration data to load
  predictably after app updates, so that my history is not corrupted.
- Problem statement: Local repositories store JSON through shared preferences,
  but DTOs are not versioned and validation is minimal.
- Evidence: `lib/repositories/hydration_repository.dart`,
  `lib/repositories/reminder_repository.dart`,
  `lib/repositories/challenge_repository.dart`, `lib/storage/local_store.dart`.
- Acceptance criteria:
  - [ ] Hydration, reminder, settings, and challenge payloads include schema
        version metadata or a documented migration policy.
  - [ ] Invalid, negative, extreme, malformed, or future-incompatible records
        are rejected or quarantined without crashing.
  - [ ] Existing valid stored data still loads.
  - [ ] Repository tests cover corrupted JSON, missing fields, unknown versions,
        and upper/lower bounds.
- Checklist:
  - [ ] Define DTO version shape.
  - [ ] Add bounded volume and date validation.
  - [ ] Add migration/no-migration policy docs.
- Test requirements: `flutter test` with repository tests for valid, invalid,
  and legacy payloads.
- Security/privacy: Hydration data is personal. Do not log raw stored payloads.
- Definition of done: storage behavior is documented, tested, and still passes
  analyze/test/web/APK CI.
- Dependencies/blockers: none.
- Suggested Kanban column: Ready.

#### MVP-STAB-002 - Add a clock and local-day boundary abstraction

- Issue type: `type:task`
- Milestone: `MVP Stabilization`
- Priority: `priority:p1`
- Labels: `area:persistence`, `area:analytics`, `area:reminders`, `area:challenges`, `type:task`, `priority:p1`, `status:ready`
- User story: As a user, I want Hydrion's "today", streak, reminder, and
  challenge calculations to stay correct across midnight and time zones.
- Problem statement: Direct `DateTime.now()` usage is spread across UI,
  repositories, and services.
- Evidence: `lib/ui/screens/home_screen.dart`, `lib/ui/screens/analytics_screen.dart`,
  `lib/ui/screens/chat_coach_screen.dart`, `lib/repositories/challenge_repository.dart`.
- Acceptance criteria:
  - [ ] App code reads current time through an injectable clock/day service.
  - [ ] Tests cover day rollover, DST-like boundary, challenge progress windows,
        reminders, and analytics totals.
  - [ ] No user-facing behavior regresses.
- Checklist:
  - [ ] Define clock interface.
  - [ ] Inject through `HydrionServices`.
  - [ ] Replace direct runtime `DateTime.now()` where domain behavior depends on it.
- Test requirements: unit tests for time boundaries plus widget smoke tests.
- Security/privacy: not directly applicable.
- Definition of done: deterministic tests can assert any date/time scenario.
- Dependencies/blockers: none.
- Suggested Kanban column: Ready.

#### MVP-STAB-003 - Make stale config truth match runtime capability state

- Issue type: `type:bug`
- Milestone: `MVP Stabilization`
- Priority: `priority:p1`
- Labels: `area:docs`, `area:settings`, `area:platform`, `type:bug`, `priority:p1`, `status:ready`
- Problem statement: Dormant config can claim future features are enabled even
  when the runtime capability dashboard says they are disabled.
- Evidence: `docs/architecture/STALE_SCAFFOLD_AUDIT.md` flags
  `config/app.yaml` as dormant and contradictory.
- Acceptance criteria:
  - [ ] `config/app.yaml` either matches runtime capabilities or is clearly
        marked dormant/template-only.
  - [ ] README and architecture docs state that Settings capability status is
        runtime truth.
  - [ ] No config file implies BLE, voice, wearable/Health, connected devices, cloud, or ELKA
        is active in MVP.
- Checklist:
  - [ ] Audit `config/` claims.
  - [ ] Update docs/config comments only.
  - [ ] Add a test or doc check if feasible.
- Test requirements: analyze/test; optional text fixture test for forbidden
  active-claim phrases.
- Security/privacy: avoids misleading users about unavailable privacy-sensitive
  integrations.
- Definition of done: stale configs cannot be mistaken for active feature flags.
- Dependencies/blockers: none.
- Suggested Kanban column: Ready.

#### MVP-STAB-004 - Split HydrionServices into smaller composition builders

- Issue type: `type:tech-debt`
- Milestone: `MVP Stabilization`
- Priority: `priority:p2`
- Labels: `area:frontend`, `area:ai-provider`, `area:persistence`, `type:tech-debt`, `priority:p2`, `status:ready`
- Problem statement: `HydrionServices` wires storage, repositories, AI, ELKA
  shell, capability reporting, and UI providers in one growing root.
- Evidence: `lib/main.dart`.
- Acceptance criteria:
  - [ ] Service creation is split by local storage, domain services, provider
        services, and optional adapters.
  - [ ] Public app behavior and tests remain unchanged.
  - [ ] Provider selection still defaults to `local_rules`.
- Checklist:
  - [ ] Extract builders without introducing new behavior.
  - [ ] Keep `HydrionApp` constructor stable for tests.
- Test requirements: existing widget, provider, persistence, and boundary tests.
- Security/privacy: provider construction must not introduce network calls by
  default.
- Definition of done: composition is easier to audit and does not change runtime.
- Dependencies/blockers: MVP-STAB-001 recommended first.
- Suggested Kanban column: Backlog.

#### MVP-STAB-005 - Add generated localization drift and ARB parity checks

- Issue type: `type:test`
- Milestone: `MVP Stabilization`
- Priority: `priority:p1`
- Labels: `area:localization`, `area:ci-cd`, `type:test`, `priority:p1`, `status:ready`
- User story: As a contributor, I want CI to catch missing localized strings
  before review, so localized screens do not silently regress.
- Problem statement: EN/ES/FR localization is active, but CI does not explicitly
  verify generated files or ARB key parity.
- Evidence: `l10n.yaml`, `lib/l10n/app_en.arb`, `lib/l10n/app_es.arb`,
  `lib/l10n/app_fr.arb`, `.github/workflows/flutter-ci.yml`.
- Acceptance criteria:
  - [ ] CI runs or verifies `flutter gen-l10n`.
  - [ ] A test fails when ARB keys differ across supported locales.
  - [ ] Generated localization files do not drift from ARB inputs.
- Checklist:
  - [ ] Add a deterministic CI step or test.
  - [ ] Document localization workflow.
- Test requirements: localization test plus CI command.
- Security/privacy: not directly applicable.
- Definition of done: missing keys fail before release.
- Dependencies/blockers: none.
- Suggested Kanban column: Ready.

#### MVP-STAB-006 - Classify and quarantine stale scripts without deleting future work

- Issue type: `type:tech-debt`
- Milestone: `MVP Stabilization`
- Priority: `priority:p2`
- Labels: `area:docs`, `area:ci-cd`, `type:tech-debt`, `priority:p2`, `status:ready`
- Problem statement: Several scripts still reference old paths or future
  systems and can mislead contributors.
- Evidence: `docs/architecture/STALE_SCAFFOLD_AUDIT.md` flags
  `scripts/test_all.sh`, `scripts/lint_all.sh`, `scripts/dev_setup.sh`,
  and `scripts/deploy_firebase.sh`.
- Acceptance criteria:
  - [ ] Active scripts are documented as supported.
  - [ ] Dormant/future scripts are labeled clearly and are not linked from
        setup instructions.
  - [ ] No script claims CI/CD or cloud deployment readiness unless those files
        actually exist.
- Checklist:
  - [ ] Add script inventory docs.
  - [ ] Update README references.
  - [ ] Do not delete `core/`, `packs/`, `models/`, or future folders.
- Test requirements: docs-only unless script links are tested.
- Security/privacy: prevents accidental deploy/cloud assumptions.
- Definition of done: contributors know which scripts are safe to run.
- Dependencies/blockers: none.
- Suggested Kanban column: Ready.

### Milestone: MVP Product UX

#### MVP-UX-001 - Let users set daily hydration target and unit preference

- Issue type: `type:user-story`
- Milestone: `MVP Product UX`
- Priority: `priority:p1`
- Labels: `area:frontend`, `area:settings`, `area:persistence`, `area:analytics`, `type:user-story`, `priority:p1`, `status:ready`
- User story: As a hydration tracker user, I want to set my daily goal and
  preferred units, so Home, Analytics, Reminders, and Coach reflect my actual
  plan.
- Problem statement: The app currently uses a fixed target such as `2200 ml`
  in summaries and UI.
- Evidence: `lib/ui/screens/home_screen.dart`, `lib/adapters/local/local_hydrion_adapters.dart`,
  `test/runtime_ux_test.dart`.
- Acceptance criteria:
  - [ ] User can set daily target in Settings.
  - [ ] Target persists locally.
  - [ ] Home ring, Log context, Analytics, Reminders, Challenges, and Coach use
        the saved target.
  - [ ] Metric units remain the MVP default; imperial can be included only if
        fully localized and tested.
- Checklist:
  - [ ] Extend settings model.
  - [ ] Update summary and context builders.
  - [ ] Add validation bounds and localized errors.
- Test requirements: repository tests, widget tests, localization tests.
- Security/privacy: target is personal app data; keep local and do not send to
  non-local provider without consent.
- Definition of done: changing the goal visibly updates all relevant local
  screens.
- Dependencies/blockers: MVP-STAB-001.
- Suggested Kanban column: Backlog.

#### MVP-UX-002 - Add quick-add customization, undo, and optional notes

- Issue type: `type:user-story`
- Milestone: `MVP Product UX`
- Priority: `priority:p2`
- Labels: `area:frontend`, `area:persistence`, `type:user-story`, `priority:p2`, `status:ready`
- User story: As a frequent logger, I want customizable quick amounts and undo,
  so logging common drinks is fast and recoverable.
- Problem statement: Home has a fixed amount list and no undo/notes flow.
- Evidence: `lib/ui/screens/home_screen.dart`, `lib/repositories/hydration_repository.dart`.
- Acceptance criteria:
  - [ ] User can customize quick-add amounts locally.
  - [ ] Adding a log offers undo.
  - [ ] Optional log notes are supported only if repository schema and UI are
        both implemented.
  - [ ] Invalid amounts are rejected with localized copy.
- Checklist:
  - [ ] Extend settings or logging model.
  - [ ] Update Home and Log edit UI.
  - [ ] Ensure Analytics ignores invalid/deleted entries.
- Test requirements: widget tests for quick amount, undo, notes if included.
- Security/privacy: notes may be sensitive; if added, include data disclosure in
  privacy docs.
- Definition of done: quick logging is still fast and safer than a fixed-only
  flow.
- Dependencies/blockers: MVP-STAB-001.
- Suggested Kanban column: Backlog.

#### MVP-UX-003 - Add weekly and monthly analytics trends

- Issue type: `type:user-story`
- Milestone: `MVP Product UX`
- Priority: `priority:p1`
- Labels: `area:analytics`, `area:frontend`, `type:user-story`, `priority:p1`, `status:ready`
- User story: As a user, I want weekly and monthly trends, so I can understand
  whether my hydration is improving.
- Problem statement: Analytics currently derives local totals but trend depth is
  shallow.
- Evidence: `lib/ui/screens/analytics_screen.dart`; `docs/architecture/may5th.md`
  "Feature Improvements Needed".
- Acceptance criteria:
  - [ ] Analytics shows 7-day and 30-day totals/averages from persisted logs.
  - [ ] Empty and sparse data states are explicit.
  - [ ] Charts or trend rows have accessible labels.
  - [ ] Date boundaries use the clock/day abstraction.
- Checklist:
  - [ ] Define analytics view model.
  - [ ] Add accessible visual or tabular trend UI.
  - [ ] Localize all labels.
- Test requirements: service tests for date windows and widget tests for empty,
  sparse, and populated states.
- Security/privacy: data remains local.
- Definition of done: users can see trend direction without fake data.
- Dependencies/blockers: MVP-STAB-002.
- Suggested Kanban column: Backlog.

#### MVP-UX-004 - Complete local reminder management

- Issue type: `type:user-story`
- Milestone: `MVP Product UX`
- Priority: `priority:p1`
- Labels: `area:reminders`, `area:frontend`, `area:persistence`, `type:user-story`, `priority:p1`, `status:ready`
- User story: As a standalone user, I want to create, edit, repeat, and delete
  local reminder definitions, so I can plan hydration prompts even before OS
  notifications exist.
- Problem statement: Reminder definitions persist, but OS notifications are
  disabled and local reminder management is limited.
- Evidence: `lib/repositories/reminder_repository.dart`,
  `lib/ui/components/reminder_tile.dart`, `lib/ui/screens/reminders_screen.dart`.
- Acceptance criteria:
  - [ ] User can create a local reminder definition from Reminders screen.
  - [ ] User can edit time/message/repeat fields.
  - [ ] User can delete reminder definitions.
  - [ ] UI clearly says these are local definitions, not OS notifications.
  - [ ] Quiet hours are either implemented locally or explicitly deferred.
- Checklist:
  - [ ] Extend repository model if needed.
  - [ ] Add edit form.
  - [ ] Preserve existing Home reminder suggestion flow.
- Test requirements: repository and widget tests for create/edit/delete/repeat.
- Security/privacy: no platform notification permission requests in MVP.
- Definition of done: local reminder data is useful without pretending to notify.
- Dependencies/blockers: MVP-STAB-001, MVP-STAB-002.
- Suggested Kanban column: Backlog.

#### MVP-UX-005 - Add challenge leave, completion, and local history

- Issue type: `type:user-story`
- Milestone: `MVP Product UX`
- Priority: `priority:p2`
- Labels: `area:challenges`, `area:persistence`, `area:frontend`, `type:user-story`, `priority:p2`, `status:ready`
- User story: As a user, I want to leave, complete, and review local challenges,
  so challenges feel real without social sync.
- Problem statement: The app supports one active local challenge with progress,
  but history and completion behavior are shallow.
- Evidence: `lib/repositories/challenge_repository.dart`,
  `lib/ui/screens/social_challenges_screen.dart`, `test/runtime_ux_test.dart`.
- Acceptance criteria:
  - [ ] User can leave/reset an active challenge.
  - [ ] Completion is calculated from local logs and stored locally.
  - [ ] Completed challenge history is visible or explicitly deferred.
  - [ ] UI says "local challenge mode" and does not imply social sync.
- Checklist:
  - [ ] Extend challenge model carefully.
  - [ ] Add local history or explicit no-history copy.
  - [ ] Add localized empty/completed states.
- Test requirements: repository and widget tests for join/progress/leave/complete.
- Security/privacy: no social backend or account model.
- Definition of done: local challenge lifecycle is honest and recoverable.
- Dependencies/blockers: MVP-STAB-002.
- Suggested Kanban column: Backlog.

#### MVP-UX-006 - Add local data export and delete controls

- Issue type: `type:user-story`
- Milestone: `MVP Product UX`
- Priority: `priority:p1`
- Labels: `area:settings`, `area:security`, `area:persistence`, `type:user-story`, `priority:p1`, `status:ready`
- User story: As a privacy-conscious user, I want to export and delete my local
  Hydrion data, so I control personal hydration history.
- Problem statement: Local persistence exists, but user-facing data management
  controls are not complete.
- Evidence: `lib/repositories/*_repository.dart`, `lib/ui/screens/settings_screen.dart`,
  `docs/architecture/PROVIDER_SECURITY.md`.
- Acceptance criteria:
  - [ ] Settings includes "export local data" and "delete local data" flows.
  - [ ] Export contains hydration logs, settings, reminder definitions, and local
        challenge state in a documented JSON shape.
  - [ ] Delete requires confirmation and clears local app data.
  - [ ] Coach/provider state updates after deletion.
- Checklist:
  - [ ] Add export DTO.
  - [ ] Add destructive confirmation dialog.
  - [ ] Add privacy docs.
- Test requirements: repository tests and widget tests for export/delete.
- Security/privacy: exported data is sensitive; do not upload it or log it.
- Definition of done: users can leave with their data and remove it locally.
- Dependencies/blockers: MVP-STAB-001.
- Suggested Kanban column: Backlog.

#### MVP-UX-007 - Add accessibility and visual regression coverage for core screens

- Issue type: `type:test`
- Milestone: `MVP Product UX`
- Priority: `priority:p2`
- Labels: `area:frontend`, `area:localization`, `type:test`, `priority:p2`, `status:ready`
- Problem statement: Runtime widget tests cover behavior, but there is no
  golden/viewport/accessibility pass for key screens and languages.
- Evidence: `test/runtime_ux_test.dart`, `test/product_qa_test.dart`,
  `docs/architecture/may5th.md`.
- Acceptance criteria:
  - [ ] Home, Log, Analytics, Reminders, Coach, Challenges, and Settings are
        checked at mobile and desktop widths.
  - [ ] EN/ES/FR long labels do not overflow.
  - [ ] Important buttons/cards have semantic labels.
  - [ ] Visual tests are stable in CI or documented as manual QA if not.
- Checklist:
  - [ ] Add test helpers for locale/viewport.
  - [ ] Add accessibility assertions.
  - [ ] Add manual QA fallback if golden tests are too noisy.
- Test requirements: widget/golden/accessibility tests.
- Security/privacy: screenshots must not include real user/provider secrets.
- Definition of done: MVP screens are usable across supported locales and viewports.
- Dependencies/blockers: MVP-STAB-005.
- Suggested Kanban column: Backlog.

### Milestone: MVP AI Provider Safety

#### MVP-AI-001 - Add explicit non-local AI consent and context preview

- Issue type: `type:security`
- Milestone: `MVP AI Provider Safety`
- Priority: `priority:p0`
- Labels: `area:ai-provider`, `area:coach`, `area:security`, `area:settings`, `type:security`, `priority:p0`, `status:ready`
- User story: As a user, I want to see what hydration context may leave my
  device before enabling a non-local AI provider, so I can make an informed
  privacy choice.
- Problem statement: Optional Gemini can send typed hydration context when
  configured, but production consent UX is not complete.
- Evidence: `docs/architecture/PROVIDER_SECURITY.md`,
  `docs/architecture/AI_ACTION_CONTRACT.md`,
  `lib/services/hydration_context_builder.dart`.
- Acceptance criteria:
  - [ ] Non-local provider enablement requires explicit consent.
  - [ ] Settings shows a readable preview of categories sent, not raw secrets or
        raw prompts.
  - [ ] User can disable non-local provider and return to `local_rules`.
  - [ ] Default remains `local_rules`.
  - [ ] Tests prove no network provider is used without opt-in.
- Checklist:
  - [ ] Add consent state to settings.
  - [ ] Add context category preview.
  - [ ] Wire provider selection to consent.
- Test requirements: provider selection tests, Settings widget tests,
  architecture tests.
- Security/privacy: do not display raw prompts, raw context JSON, response body,
  or full API key.
- Definition of done: a non-local provider cannot be used accidentally.
- Dependencies/blockers: none.
- Suggested Kanban column: Ready.

#### MVP-AI-002 - Lock production key policy so shared Gemini keys cannot ship

- Issue type: `type:security`
- Milestone: `MVP AI Provider Safety`
- Priority: `priority:p0`
- Labels: `area:ai-provider`, `area:security`, `area:release`, `type:security`, `priority:p0`, `status:ready`
- Problem statement: Dart defines are acceptable for local development, but
  shared provider keys must not be embedded in web/mobile/desktop client builds.
- Evidence: `docs/architecture/PROVIDER_SECURITY.md`, `README.md`,
  `lib/services/ai_provider_config.dart`, `tool/secret_scan.dart`.
- Acceptance criteria:
  - [ ] Release docs explicitly forbid shared production Gemini/OpenAI/BYOK keys
        in client artifacts.
  - [ ] CI scans committed files for high-risk key patterns.
  - [ ] Release checklist requires local-only, BYOK, or backend-proxy decision.
  - [ ] Optional Gemini remains disabled by default.
- Checklist:
  - [ ] Expand release checklist.
  - [ ] Strengthen secret scan patterns if needed.
  - [ ] Add tests for scanner fixtures.
- Test requirements: secret scan test and CI run.
- Security/privacy: this is a release-blocking security issue.
- Definition of done: no release path can honestly claim production Gemini via a
  shared client key.
- Dependencies/blockers: none.
- Suggested Kanban column: Ready.

#### MVP-AI-003 - Harden provider output schema and fuzz malformed responses

- Issue type: `type:task`
- Milestone: `MVP AI Provider Safety`
- Priority: `priority:p1`
- Labels: `area:ai-provider`, `area:coach`, `area:security`, `type:task`, `priority:p1`, `status:ready`
- User story: As a Hydrion user, I want provider suggestions to be rejected if
  malformed or unsafe, so AI output cannot mutate my app incorrectly.
- Problem statement: Typed actions and validation exist, but provider output
  parsing should be stress-tested against malformed, oversized, and unsafe data.
- Evidence: `lib/adapters/gemini/gemini_adapter.dart`,
  `lib/domain/hydration_contracts.dart`, `test/gemini_provider_test.dart`.
- Acceptance criteria:
  - [ ] Parser rejects unknown action types, wrong shapes, too many actions,
        oversized fields, invalid capabilities, and unsafe claims.
  - [ ] Provider fallback records safe diagnostic codes.
  - [ ] Fuzz/table tests cover malformed JSON, natural language, arrays, nested
        garbage, and boundary values.
  - [ ] No raw provider response is shown in UI.
- Checklist:
  - [ ] Add parser boundary tests.
  - [ ] Add validator boundary tests.
  - [ ] Keep `local_rules` fallback.
- Test requirements: provider tests, action validator tests.
- Security/privacy: never persist raw provider output unless explicitly redacted.
- Definition of done: bad provider output fails closed and leaves the app local.
- Dependencies/blockers: none.
- Suggested Kanban column: Ready.

#### MVP-AI-004 - Finish provider health diagnostics without leaking secrets

- Issue type: `type:task`
- Milestone: `MVP AI Provider Safety`
- Priority: `priority:p1`
- Labels: `area:ai-provider`, `area:settings`, `area:coach`, `area:security`, `type:task`, `priority:p1`, `status:ready`
- Problem statement: Settings and Coach show provider state, but MVP needs a
  clear, safe diagnostic model for configured, attempted, failed, timed out,
  validation fallback, and successful states.
- Evidence: `lib/services/provider_health.dart`,
  `lib/services/hydration_ai_orchestrator.dart`, `lib/ui/screens/settings_screen.dart`,
  `test/product_qa_test.dart`.
- Acceptance criteria:
  - [ ] UI distinguishes selected provider, active provider, configured state,
        last attempt, last safe status class, last parser/validator code, and
        fallback reason.
  - [ ] Full API keys, raw prompts, raw hydration context, and successful raw
        responses are never displayed.
  - [ ] Tests cover no key, HTTP failure, timeout, malformed response, unsafe
        capability claim, and success.
- Checklist:
  - [ ] Audit current health fields.
  - [ ] Add missing diagnostic codes.
  - [ ] Add localized UI strings.
- Test requirements: provider tests and product QA widget tests.
- Security/privacy: redaction is required.
- Definition of done: users and developers can debug provider status safely.
- Dependencies/blockers: MVP-AI-002.
- Suggested Kanban column: Ready.

#### MVP-AI-005 - Productize coach suggestion confirmation and audit trail

- Issue type: `type:user-story`
- Milestone: `MVP AI Provider Safety`
- Priority: `priority:p1`
- Labels: `area:coach`, `area:ai-provider`, `area:persistence`, `type:user-story`, `priority:p1`, `status:ready`
- User story: As a user, I want to confirm, dismiss, and understand AI/local
  suggestions before they change my data, so I stay in control.
- Problem statement: Suggestion cards and executor exist, but MVP should prove
  state-changing suggestions are user-confirmed, localized, and auditable.
- Evidence: `lib/services/coach_suggestion_service.dart`,
  `lib/services/hydration_ai_action_executor.dart`,
  `lib/ui/screens/chat_coach_screen.dart`,
  `docs/architecture/AI_ACTION_CONTRACT.md`.
- Acceptance criteria:
  - [ ] Suggested hydration logs, reminders, and challenges require explicit
        user confirmation.
  - [ ] Applied actions write only through Hydrion repositories/services.
  - [ ] Dismissed/rejected/display-only status is visible.
  - [ ] Optional local audit history is implemented or explicitly deferred.
  - [ ] No provider directly mutates app state.
- Checklist:
  - [ ] Verify every action path through executor.
  - [ ] Add confirmation UX tests.
  - [ ] Decide whether suggestion history persists for MVP.
- Test requirements: action executor tests, coach suggestion card widget tests.
- Security/privacy: avoid storing raw prompts or provider responses in audit
  history.
- Definition of done: all state-changing AI suggestions are user-owned.
- Dependencies/blockers: MVP-AI-003.
- Suggested Kanban column: Ready.

#### MVP-AI-006 - Keep UI provider-blind through architecture tests

- Issue type: `type:test`
- Milestone: `MVP AI Provider Safety`
- Priority: `priority:p1`
- Labels: `area:ai-provider`, `area:frontend`, `type:test`, `priority:p1`, `status:ready`
- Problem statement: The adapter boundary is strong today, but future provider
  work can leak SDKs or ELKA imports into UI.
- Evidence: `docs/architecture/ADAPTER_BOUNDARY.md`,
  `test/boundary_architecture_test.dart`, `lib/ui/**`.
- Acceptance criteria:
  - [ ] Tests fail if `lib/ui/**` imports Gemini, ELKA, OpenAI, BYOK, cloud, or
        provider SDK paths directly.
  - [ ] Tests fail if UI imports deprecated bridge/services that bypass domain
        contracts.
  - [ ] Local `local_rules` remains default.
- Checklist:
  - [ ] Expand import graph checks.
  - [ ] Document allowed UI dependencies.
- Test requirements: architecture test.
- Security/privacy: preserves standalone local boundary.
- Definition of done: provider expansion cannot quietly couple UI to providers.
- Dependencies/blockers: none.
- Suggested Kanban column: Ready.

### Milestone: MVP Release Readiness

#### MVP-REL-001 - Replace default platform identity and release metadata

- Issue type: `type:release`
- Milestone: `MVP Release Readiness`
- Priority: `priority:p0`
- Labels: `area:release`, `area:platform`, `area:docs`, `type:release`, `priority:p0`, `status:ready`
- Problem statement: Before MVP beta, Android/iOS/web/desktop metadata must
  reflect Hydrion, not default Flutter/scaffold identities.
- Evidence: `pubspec.yaml`, `android/`, `ios/`, `web/`, `macos/`, `windows/`,
  `README.md`.
- Acceptance criteria:
  - [ ] Android namespace/applicationId/label are final for MVP.
  - [ ] Web title, manifest, icons, and PWA metadata are Hydrion-branded.
  - [ ] iOS/macOS bundle identifiers are decided or explicitly deferred.
  - [ ] Desktop platform support is declared honestly.
  - [ ] No platform claims native BLE/Health/voice/OS notifications or connected devices are active.
- Checklist:
  - [ ] Audit platform metadata.
  - [ ] Update release docs.
  - [ ] Verify APK and web artifacts.
- Test requirements: `flutter build apk --release`; `flutter build web --release`;
  smoke test launched web app.
- Security/privacy: permissions must match enabled features only.
- Definition of done: artifacts are identifiable as Hydrion and do not overclaim.
- Dependencies/blockers: product owner must approve bundle IDs/app IDs.
- Suggested Kanban column: Ready.

#### MVP-REL-002 - Document Android signing and internal beta build process

- Issue type: `type:docs`
- Milestone: `MVP Release Readiness`
- Priority: `priority:p1`
- Labels: `area:release`, `area:platform`, `area:docs`, `area:security`, `type:docs`, `priority:p1`, `status:ready`
- Problem statement: CI can build APKs, but release signing, key handling, and
  beta distribution instructions are not complete.
- Evidence: `.github/workflows/flutter-ci.yml`, `README.md`, `android/`.
- Acceptance criteria:
  - [ ] Internal debug/release distinction is documented.
  - [ ] Production signing credentials are explicitly excluded from git.
  - [ ] Steps describe how to build and where artifacts are produced.
  - [ ] APK smoke test checklist exists.
- Checklist:
  - [ ] Add release doc.
  - [ ] Link from README.
  - [ ] Add `.gitignore` entries if any signing outputs are missing.
- Test requirements: docs review plus APK build.
- Security/privacy: signing keys must never be committed.
- Definition of done: a developer can produce an internal beta APK safely.
- Dependencies/blockers: MVP-REL-001.
- Suggested Kanban column: Backlog.

#### MVP-REL-003 - Add coverage threshold and release quality gates

- Issue type: `type:task`
- Milestone: `MVP Release Readiness`
- Priority: `priority:p1`
- Labels: `area:ci-cd`, `area:release`, `type:task`, `priority:p1`, `status:ready`
- Problem statement: CI uploads coverage but does not enforce a threshold or
  release-specific quality gate.
- Evidence: `.github/workflows/flutter-ci.yml` runs `flutter test --coverage`
  and uploads `coverage/lcov.info`.
- Acceptance criteria:
  - [ ] Reasonable initial coverage threshold is selected and documented.
  - [ ] CI fails when coverage falls below threshold.
  - [ ] Release gate includes pub get, secret scan, analyze, tests, web build,
        APK build, localization check, and artifact upload.
- Checklist:
  - [ ] Choose threshold based on current coverage.
  - [ ] Add coverage parser/check.
  - [ ] Document how to update threshold.
- Test requirements: CI dry run or local script validation.
- Security/privacy: release gate must keep secret scan.
- Definition of done: green release builds have measurable quality guarantees.
- Dependencies/blockers: MVP-STAB-005.
- Suggested Kanban column: Backlog.

#### MVP-REL-004 - Create MVP beta smoke test script and manual checklist

- Issue type: `type:test`
- Milestone: `MVP Release Readiness`
- Priority: `priority:p1`
- Labels: `area:release`, `area:ci-cd`, `area:frontend`, `type:test`, `priority:p1`, `status:ready`
- Problem statement: Automated tests are good, but release needs a repeatable
  manual smoke checklist for real artifacts.
- Evidence: `test/product_qa_test.dart`, `test/runtime_ux_test.dart`,
  `.github/workflows/flutter-ci.yml`.
- Acceptance criteria:
  - [ ] Checklist covers first launch, logging, edit/delete, analytics,
        reminders, challenges, settings, locale change, coach local mode, and
        disabled feature labels.
  - [ ] Checklist covers web and Android APK.
  - [ ] Checklist states that ELKA/cloud/native integrations are not active.
- Checklist:
  - [ ] Add smoke test doc.
  - [ ] Include screenshots or expected text where useful.
- Test requirements: manual run before MVP beta.
- Security/privacy: do not use real provider keys during smoke unless testing
  explicit local-dev provider flows.
- Definition of done: beta readiness can be verified by a non-author.
- Dependencies/blockers: MVP-REL-001.
- Suggested Kanban column: Backlog.

#### MVP-REL-005 - Decide local data protection level for MVP

- Issue type: `type:security`
- Milestone: `MVP Release Readiness`
- Priority: `priority:p0`
- Labels: `area:security`, `area:persistence`, `area:release`, `type:security`, `priority:p0`, `status:ready`
- Problem statement: Hydration data is health-adjacent personal data, but MVP
  currently uses shared preferences rather than encrypted local storage.
- Evidence: `lib/storage/local_store.dart`, `docs/architecture/may5th.md`,
  `docs/architecture/PROVIDER_SECURITY.md`.
- Acceptance criteria:
  - [ ] Product/security decision classifies hydration logs and settings data.
  - [ ] If shared preferences remains acceptable for MVP, docs say why and what
        is excluded from MVP.
  - [ ] If encryption is required, a scoped local encrypted storage task is
        created before beta.
  - [ ] Export/delete behavior aligns with the decision.
- Checklist:
  - [ ] Write data classification note.
  - [ ] Review platform storage options.
  - [ ] Update privacy docs.
- Test requirements: not applicable unless storage implementation changes.
- Security/privacy: release-blocking privacy decision.
- Definition of done: MVP storage risk is explicit and accepted or fixed.
- Dependencies/blockers: MVP-UX-006.
- Suggested Kanban column: Ready.

#### MVP-REL-006 - Update README and onboarding docs to current MVP scope

- Issue type: `type:docs`
- Milestone: `MVP Release Readiness`
- Priority: `priority:p1`
- Labels: `area:docs`, `area:release`, `type:docs`, `priority:p1`, `status:ready`
- Problem statement: README is improved, but MVP needs contributor onboarding
  docs that match current architecture, active features, and non-MVP boundaries.
- Evidence: `README.md`, `docs/architecture/ADAPTER_BOUNDARY.md`,
  `docs/architecture/STALE_SCAFFOLD_AUDIT.md`.
- Acceptance criteria:
  - [ ] README states active MVP features and excluded features.
  - [ ] Setup commands match CI.
  - [ ] Optional Gemini instructions are local-dev only and include security
        warning.
  - [ ] Docs link adapter boundary, provider security, stale scaffold audit,
        and this roadmap.
- Checklist:
  - [ ] Update README.
  - [ ] Add onboarding doc if needed.
  - [ ] Remove references that imply ELKA/native/cloud are active.
- Test requirements: docs review.
- Security/privacy: docs must not include real keys or secrets.
- Definition of done: a new contributor can run and understand the MVP safely.
- Dependencies/blockers: MVP-REL-005.
- Suggested Kanban column: Backlog.

### Milestone: Post-MVP Native Integrations

#### POST-NATIVE-001 - Add real OS notification adapter

- Issue type: `type:user-story`
- Milestone: `Post-MVP Native Integrations`
- Priority: `priority:p2`
- Labels: `area:reminders`, `area:platform`, `type:user-story`, `priority:p2`, `status:blocked`
- User story: As a user, I want Hydrion to deliver scheduled device reminders,
  so local reminder definitions become real notifications.
- Problem statement: MVP stores reminder definitions only; OS notifications are
  disabled.
- Evidence: `lib/services/notifications.dart`, `lib/ui/screens/reminders_screen.dart`.
- Acceptance criteria:
  - [ ] Platform notification plugin/adapter is selected.
  - [ ] Permission flow, scheduling, cancellation, quiet hours, and repeat rules
        are implemented.
  - [ ] Web unsupported state remains honest.
  - [ ] Tests cover adapter boundaries and fallback state.
- Checklist:
  - [ ] Write adapter interface.
  - [ ] Implement platform adapter.
  - [ ] Update permissions and privacy copy.
- Test requirements: unit/widget tests plus manual Android/iOS checks.
- Security/privacy: notification contents may reveal hydration behavior.
- Definition of done: reminders fire on supported platforms and are gated elsewhere.
- Dependencies/blockers: MVP-UX-004; native plugin choice.
- Suggested Kanban column: Blocked.

#### POST-NATIVE-002 - Add BLE smart bottle adapter

- Issue type: `type:user-story`
- Milestone: `Post-MVP Native Integrations`
- Priority: `priority:p3`
- Labels: `area:platform`, `area:persistence`, `type:user-story`, `priority:p3`, `status:blocked`
- User story: As a user with a supported smart bottle, I want Hydrion to import
  bottle readings, so my log can include device-sourced hydration.
- Problem statement: BLE is disabled/fallback-only in MVP.
- Evidence: `lib/services/ble_service.dart`, `lib/services/wearable_service.dart`,
  `lib/ui/screens/settings_screen.dart`.
- Acceptance criteria:
  - [ ] BLE adapter is behind interface/capability reporter.
  - [ ] Permissions and platform gates exist.
  - [ ] Imported logs have source attribution and conflict handling.
  - [ ] UI never claims BLE is active unless connected.
- Checklist:
  - [ ] Select plugin after Android/iOS namespace compatibility review.
  - [ ] Add device model and sync policy.
  - [ ] Add privacy docs.
- Test requirements: adapter tests and hardware/manual test plan.
- Security/privacy: device data and Bluetooth permissions need explicit copy.
- Definition of done: smart bottle sync is real, optional, and disableable.
- Dependencies/blockers: supported hardware/protocol decision.
- Suggested Kanban column: Blocked.

#### POST-NATIVE-003 - Add HealthKit/Google Fit wearable adapter

- Issue type: `type:user-story`
- Milestone: `Post-MVP Native Integrations`
- Priority: `priority:p3`
- Labels: `area:platform`, `area:persistence`, `area:security`, `type:user-story`, `priority:p3`, `status:blocked`
- User story: As a user, I want optional health/wearable sync, so Hydrion can
  consider activity and hydration context from trusted platform sources.
- Problem statement: Health/wearable sync is disabled in MVP.
- Evidence: `lib/services/wearable_service.dart`, `lib/ui/screens/settings_screen.dart`.
- Acceptance criteria:
  - [ ] Health adapter is optional and permission-gated.
  - [ ] Data source attribution is visible.
  - [ ] Conflict handling and privacy copy are documented.
  - [ ] Web/desktop unsupported states remain honest.
- Checklist:
  - [ ] Define health source model.
  - [ ] Choose plugin/adapters.
  - [ ] Add platform usage strings only when active.
- Test requirements: adapter tests plus platform manual tests.
- Security/privacy: high sensitivity; requires explicit consent and data policy.
- Definition of done: health sync is optional and trustworthy.
- Dependencies/blockers: privacy/storage decision, plugin review.
- Suggested Kanban column: Blocked.

#### POST-NATIVE-004 - Add voice capture adapter

- Issue type: `type:user-story`
- Milestone: `Post-MVP Native Integrations`
- Priority: `priority:p3`
- Labels: `area:frontend`, `area:platform`, `area:settings`, `type:user-story`, `priority:p3`, `status:blocked`
- User story: As a user, I want to log hydration by voice, so I can use Hydrion
  hands-free when the platform supports it.
- Problem statement: Voice input is disabled; command parsing exists but no
  microphone/speech adapter is active.
- Evidence: `lib/services/voice_client.dart`, `lib/services/voice_llm_bridge.dart`,
  `lib/ui/components/voice_input_widget.dart`.
- Acceptance criteria:
  - [ ] Voice capture is permission-gated and locale-aware.
  - [ ] Transcript is visible before action is applied.
  - [ ] Parsed hydration log still requires confirmation.
  - [ ] Unsupported platforms show disabled state.
- Checklist:
  - [ ] Define speech adapter interface.
  - [ ] Add permission flow.
  - [ ] Add confirmation UX and tests.
- Test requirements: parser tests, widget tests, platform manual tests.
- Security/privacy: microphone permission and speech transcripts require clear copy.
- Definition of done: voice does not bypass user confirmation or privacy.
- Dependencies/blockers: native plugin choice and MVP-AI-005.
- Suggested Kanban column: Blocked.

#### POST-NATIVE-005 - Add connected-device adapter boundary

- Issue type: `type:user-story`
- Milestone: `Post-MVP Native Integrations`
- Priority: `priority:p3`
- Labels: `area:frontend`, `area:platform`, `type:user-story`, `priority:p3`, `status:blocked`
- User story: As a user, I want optional smart bottle and smartwatch support, so
  connected-device hydration context can complement my manual logs when I opt in.
- Problem statement: connected devices are roadmap-only; Hydrion must not
  request Bluetooth/Health permissions or emit fake device data before real
  adapters and privacy copy exist.
- Evidence: `docs/CONNECTED_DEVICES_ROADMAP.md`,
  `lib/services/ble_service.dart`, `lib/services/wearable_service.dart`.
- Acceptance criteria:
  - [ ] BLE smart bottle adapter boundary is defined and capability-gated.
  - [ ] Smartwatch/Health adapter boundary is defined and capability-gated.
  - [ ] Permission copy and source attribution are owner-approved.
  - [ ] No fake bottle level, watch, or Health data is shown.
- Checklist:
  - [ ] Research maintained BLE and Health/wearable plugins.
  - [ ] Build adapter boundary.
  - [ ] Add platform permissions, tests, and real-device validation.
- Test requirements: build tests, adapter contract tests, and manual device tests.
- Security/privacy: Bluetooth and Health permissions require explicit justification.
- Definition of done: connected devices are real and opt-in, or remain inactive.
- Dependencies/blockers: plugin selection, device hardware, and privacy approval.
- Suggested Kanban column: Blocked.

### Milestone: Post-MVP ELKA Integration

#### POST-ELKA-001 - Define real ELKA adapter contract without UI coupling

- Issue type: `type:task`
- Milestone: `Post-MVP ELKA Integration`
- Priority: `priority:p2`
- Labels: `area:ai-provider`, `area:coach`, `type:task`, `priority:p2`, `status:blocked`
- Problem statement: ELKA currently exists only as an unconfigured shell. A real
  adapter must not change Hydrion's standalone default.
- Evidence: `lib/adapters/elka/elka_adapter.dart`,
  `docs/architecture/ADAPTER_BOUNDARY.md`, `test/adapter_contract_test.dart`.
- Acceptance criteria:
  - [ ] ELKA adapter implements existing Hydrion domain/provider contracts.
  - [ ] UI does not import ELKA.
  - [ ] `local_rules` remains default when ELKA is absent/unconfigured.
  - [ ] Provider health and consent cover ELKA separately.
- Checklist:
  - [ ] Write adapter contract tests.
  - [ ] Define configuration and failure states.
  - [ ] Keep non-networked shell behavior for unconfigured mode.
- Test requirements: adapter and boundary tests.
- Security/privacy: context leaving Hydrion must require consent.
- Definition of done: Hydrion can run with or without ELKA.
- Dependencies/blockers: MVP-AI-001 through MVP-AI-006.
- Suggested Kanban column: Blocked.

#### POST-ELKA-002 - Add ELKA privacy and provider health UX

- Issue type: `type:user-story`
- Milestone: `Post-MVP ELKA Integration`
- Priority: `priority:p2`
- Labels: `area:ai-provider`, `area:settings`, `area:security`, `type:user-story`, `priority:p2`, `status:blocked`
- User story: As a user, I want ELKA status, consent, and fallback to be clear,
  so I know when Hydrion is standalone and when ELKA is involved.
- Problem statement: ELKA is not active today and must remain optional.
- Evidence: `lib/ui/screens/settings_screen.dart`,
  `docs/architecture/ADAPTER_BOUNDARY.md`.
- Acceptance criteria:
  - [ ] Settings shows ELKA configured/unconfigured/active/fallback states.
  - [ ] ELKA cannot be selected without consent.
  - [ ] Turning ELKA off returns to local standalone mode.
  - [ ] Tests prove UI remains provider-blind.
- Checklist:
  - [ ] Add safe diagnostics.
  - [ ] Add consent copy.
  - [ ] Add tests.
- Test requirements: widget tests and boundary tests.
- Security/privacy: never expose raw ELKA payloads or credentials.
- Definition of done: ELKA is optional, visible, and reversible.
- Dependencies/blockers: POST-ELKA-001.
- Suggested Kanban column: Blocked.

### Milestone: Post-MVP Cloud/Social Sync

#### POST-CLOUD-001 - Design cloud sync model before implementation

- Issue type: `type:task`
- Milestone: `Post-MVP Cloud/Social Sync`
- Priority: `priority:p3`
- Labels: `area:persistence`, `area:security`, `area:platform`, `type:task`, `priority:p3`, `status:blocked`
- Problem statement: Cloud sync requires auth, privacy, conflict resolution,
  encryption decisions, and backend targets that do not exist in MVP.
- Evidence: `docs/architecture/STALE_SCAFFOLD_AUDIT.md` marks cloud-related
  files future/stale; no active cloud runtime exists.
- Acceptance criteria:
  - [ ] Data model and conflict policy are documented.
  - [ ] Auth/account model is documented.
  - [ ] Privacy and deletion/export requirements are documented.
  - [ ] No cloud code is added until design is approved.
- Checklist:
  - [ ] Draft architecture proposal.
  - [ ] Define sync boundaries.
  - [ ] Link to privacy policy.
- Test requirements: design review only.
- Security/privacy: high sensitivity; must be opt-in.
- Definition of done: cloud sync is specified before code.
- Dependencies/blockers: MVP release and privacy decision.
- Suggested Kanban column: Blocked.

#### POST-CLOUD-002 - Design social challenge backend and moderation model

- Issue type: `type:task`
- Milestone: `Post-MVP Cloud/Social Sync`
- Priority: `priority:p3`
- Labels: `area:challenges`, `area:security`, `type:task`, `priority:p3`, `status:blocked`
- Problem statement: Social challenges are local-only in MVP; real social sync
  needs identity, privacy, moderation, and backend behavior.
- Evidence: `lib/repositories/challenge_repository.dart`,
  `lib/ui/screens/social_challenges_screen.dart`.
- Acceptance criteria:
  - [ ] Social identity and privacy model is documented.
  - [ ] Challenge invite/progress/completion sync is specified.
  - [ ] Abuse/moderation/reporting assumptions are documented.
  - [ ] Local-only challenge mode remains available.
- Checklist:
  - [ ] Draft social model.
  - [ ] Define backend API shape.
  - [ ] Define opt-in UX.
- Test requirements: design review only.
- Security/privacy: social hydration data is sensitive and must be opt-in.
- Definition of done: social sync has a responsible product design.
- Dependencies/blockers: POST-CLOUD-001.
- Suggested Kanban column: Blocked.

#### POST-CLOUD-003 - Decide Rust/core/models/packs active vs archive strategy

- Issue type: `type:tech-debt`
- Milestone: `Post-MVP Cloud/Social Sync`
- Priority: `priority:p3`
- Labels: `area:docs`, `area:platform`, `area:ai-provider`, `type:tech-debt`, `priority:p3`, `status:blocked`
- Problem statement: `core/`, `models/`, and `packs/` contain future or
  experimental work that is not active in the Flutter MVP.
- Evidence: `docs/architecture/STALE_SCAFFOLD_AUDIT.md`,
  `docs/architecture/may5th.md`.
- Acceptance criteria:
  - [ ] Each folder is marked active, dormant, experimental, future, or archived.
  - [ ] No README/setup path implies these folders are required for MVP.
  - [ ] If Rust/core becomes active, a separate CI plan exists.
  - [ ] If packs become active, provider boundary tests exist first.
- Checklist:
  - [ ] Review folder ownership.
  - [ ] Update docs.
  - [ ] Create follow-up implementation issues only after decision.
- Test requirements: docs review; optional CI if a folder becomes active.
- Security/privacy: future packs must not introduce committed model/provider secrets.
- Definition of done: stale scaffolds no longer confuse MVP scope.
- Dependencies/blockers: MVP release.
- Suggested Kanban column: Blocked.

## Priority Order

1. MVP-AI-002 - Lock production key policy so shared Gemini keys cannot ship.
2. MVP-AI-001 - Add explicit non-local AI consent and context preview.
3. MVP-REL-005 - Decide local data protection level for MVP.
4. MVP-STAB-001 - Version local persistence DTOs and validate stored data.
5. MVP-STAB-002 - Add a clock and local-day boundary abstraction.
6. MVP-STAB-003 - Make stale config truth match runtime capability state.
7. MVP-AI-003 - Harden provider output schema and fuzz malformed responses.
8. MVP-AI-004 - Finish provider health diagnostics without leaking secrets.
9. MVP-AI-005 - Productize coach suggestion confirmation and audit trail.
10. MVP-STAB-005 - Add generated localization drift and ARB parity checks.
11. MVP-REL-001 - Replace default platform identity and release metadata.
12. MVP-UX-001 - Let users set daily hydration target and unit preference.
13. MVP-UX-004 - Complete local reminder management.
14. MVP-UX-006 - Add local data export and delete controls.
15. MVP-REL-003 - Add coverage threshold and release quality gates.
16. MVP-REL-004 - Create MVP beta smoke test script and manual checklist.
17. MVP-REL-006 - Update README and onboarding docs to current MVP scope.
18. MVP-UX-003 - Add weekly and monthly analytics trends.
19. MVP-UX-005 - Add challenge leave, completion, and local history.
20. MVP-UX-007 - Add accessibility and visual regression coverage for core screens.

## Suggested Sprint 1

Sprint goal: make Hydrion's MVP trustworthy before adding new product depth.

| Order | Issue | Why now | Suggested column |
|---|---|---|---|
| 1 | MVP-AI-002 | Prevents unsafe production provider key handling. | Ready |
| 2 | MVP-AI-001 | Makes non-local provider use explicit and consent-based. | Ready |
| 3 | MVP-REL-005 | Decides whether local storage is acceptable for beta. | Ready |
| 4 | MVP-STAB-001 | Protects persisted data before more schema changes. | Ready |
| 5 | MVP-STAB-002 | Removes date/time flakiness from analytics/reminders/challenges. | Ready |
| 6 | MVP-STAB-003 | Makes configs/docs match runtime truth. | Ready |
| 7 | MVP-STAB-005 | Prevents localization drift as UX changes continue. | Ready |

Sprint 1 explicitly does not include ELKA, cloud sync, BLE, Health, connected devices, voice,
OS notifications, or new provider SDKs.

## Definition Of Done

### Feature DoD

- Acceptance criteria are complete.
- User-visible copy is localized for EN/ES/FR.
- Empty, loading, error, disabled, and unsupported states are covered.
- The feature reads/writes through the correct repository/service boundary.
- Standalone local mode still works without network/provider/native services.
- `flutter analyze` and `flutter test` pass.

### AI DoD

- `local_rules` remains default and fallback.
- Non-local provider use requires explicit user consent.
- Provider output is typed, validated, bounded, and rejected on unsafe claims.
- State-changing suggestions require user confirmation.
- Providers never write app state directly.
- UI does not import provider SDKs, Gemini, ELKA, OpenAI, BYOK, cloud, or pack
  code directly.
- No raw prompt, raw context, raw successful response, or full API key appears
  in UI, logs, tests, or docs.

### Security DoD

- No committed secrets, private keys, production signing credentials, `.env`
  files, or generated secret reports.
- Secret scan passes in CI.
- Sensitive local data handling is documented.
- Export/delete behavior exists or is explicitly deferred with rationale.
- Permissions match active features only.

### Localization DoD

- ARB keys are in parity across active locales.
- Generated localization files match ARB sources.
- EN/ES/FR core flows render without overflow in tested viewports.
- Future languages are not claimed active until ARB coverage exists.

### Release DoD

- CI passes pub get, secret scan, analyze, tests, web build, and APK build.
- Release metadata and app identifiers are correct or explicitly deferred.
- APK/web artifacts are uploaded or locally produced.
- MVP smoke checklist passes.
- README and release docs match actual runtime.

### MVP DoD

- Hydrion runs standalone without ELKA, Gemini, cloud, or native integrations.
- Home, Log, Analytics, Reminders, Challenges, Settings, and Coach are usable.
- Local persisted data survives restart.
- Disabled/future features are clearly labeled.
- No feature is represented as active without implementation and tests.

## Post-MVP Roadmap

| Phase | Theme | Candidate issues |
|---|---|---|
| Post-MVP Native Integrations | Real device/platform features. | POST-NATIVE-001 through POST-NATIVE-005. |
| Post-MVP ELKA Integration | Optional ELKA adapter behind Hydrion contracts. | POST-ELKA-001, POST-ELKA-002. |
| Post-MVP Cloud/Social Sync | Accounts, sync, and social features after privacy design. | POST-CLOUD-001, POST-CLOUD-002. |
| Post-MVP Core/Models/Packs | Decide whether experimental scaffolds become product code. | POST-CLOUD-003 and follow-up scoped issues. |

## Non-MVP Guardrails

- Do not add ELKA before MVP AI provider safety is complete.
- Do not add Gemini/OpenAI/BYOK/edge providers as production features before
  consent, key policy, and provider health are complete.
- Do not add connected-device plugins for placeholder UI.
- Do not add BLE, Health, voice, OS notifications, cloud sync, or social sync
  without adapter interfaces, permissions, privacy copy, and tests.
- Do not delete `core/`, `packs/`, `models/`, or future asset folders just
  because they are inactive.
- Do not let stale config files become runtime truth.
- Keep Hydrion standalone-first.
