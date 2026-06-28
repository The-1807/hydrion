# Hydrion User Stories

## 1. Product Overview

Hydrion is a standalone-first Flutter hydration companion. The current product lets a user log water intake manually, persist local hydration history, edit and delete records, view daily progress against a fixed 2200 ml goal, inspect analytics, track simple achievements and streaks, save local reminder definitions, join a local hydration challenge, and receive local hydration-coach guidance.

The repository shows a local-first operating model. Runtime data is stored on the device through `shared_preferences` behind `HydrionLocalStore`; there are no accounts, cloud sync, production provider credentials, HealthKit/Google Fit sync, BLE smart-bottle sync, microphone capture, OS notification scheduling, native AR sessions, or social backend calls in the current app. Provider and native integrations are represented by contracts, disabled services, capability reporting, documentation, or future scaffolds.

Supported active product targets are Flutter web and Android, as evidenced by README build commands and CI jobs for web release builds and Android APK builds. Flutter platform folders also exist for iOS, macOS, Windows, and Linux, but the current documented MVP validation focuses on web and Android. The web app includes PWA manifest assets and standalone display metadata, although some generated/default app metadata still needs release cleanup.

Major implemented capabilities include local hydration logging, local persistence, history edit/delete, daily summaries, analytics, hydration score, streak and achievement display, eco-impact estimation, local reminder definitions, local challenge join/progress, local deterministic coach responses, typed AI action proposals, safe provider diagnostics, capability gating, English/Spanish/French localization, secret hygiene checks, and CI quality gates. Major partial, gated, or future capabilities include configurable hydration goals, encrypted/export/delete data controls, real OS notifications, microphone voice capture, BLE, Health sync, AR, social/cloud sync, ELKA, BYOK/OpenAI/edge providers, Rust core activation, and dormant prompt/config pipelines.

## 2. Scope Classification

### Current MVP

* Standalone Flutter app from the repository root.
* Local hydration logging with preset ml amounts.
* Local persisted hydration logs, settings, reminders, and challenge state.
* Hydration history display, edit, and delete.
* Daily summary and fixed 2200 ml progress goal.
* Analytics screen with hydration score, daily total, local achievements, streak badge, and eco estimate.
* Local reminder definition creation, listing, and deletion without OS scheduling.
* Local challenge generation, join state, and progress.
* Local deterministic hydration coach and chat-style coach screen.
* Settings for language, local/provider status, permissions, and capability status.
* English, Spanish, and French generated localization.
* Web and Android build support with CI validation.

### Implemented Supporting Capabilities

* `HydrationContext` model for provider/coach context.
* Typed AI action proposal model and validation.
* Confirmable coach suggestion cards for logs, reminders, and challenges.
* Provider health snapshots, diagnostics, and local fallback reporting.
* Secret scanning and tests for provider credential hygiene.
* Architecture tests that keep UI isolated from adapters and provider SDKs.
* Local command parser for typed or future voice commands.
* Capability reporter that marks disabled integrations honestly.
* Empty states, basic retry/error handling, and responsive home controls.

### Partially Implemented or Capability-Gated Features

* Hydration goals are fixed at 2200 ml; configurable target/unit settings are planned but not implemented.
* Reminder definitions are stored locally; OS notifications are disabled.
* `ChallengeRepository.leave()` exists, but challenge leave/completion history is not exposed as a complete user workflow.
* Voice command parsing exists, but microphone capture and active voice input are disabled.
* Gemini can be selected only by Dart defines and an API key; it is local-development only and falls back to `local_rules`.
* Prompt templates can be loaded by `LLMPromptBuilder`, but the active local/Gemini coach path does not consume `config/prompt_templates.yaml`.
* PWA support exists through manifest/index assets, but product metadata remains default Flutter wording.
* Accessibility and responsive behavior have targeted support and tests, but not a full audit.
* Local data is persisted but not encrypted, exported, or deleted through dedicated user-facing privacy controls.

### Post-MVP or Future Integrations

* ELKA runtime integration.
* Real OS notification adapter.
* BLE smart-bottle adapter.
* HealthKit/Google Fit or wearable sync.
* Microphone speech capture and voice confirmation UX.
* Native AR/camera session.
* Cloud sync, accounts, backend storage, Firebase deploy, and social challenge backend.
* BYOK, OpenAI, edge LLM packs, and production non-local provider strategy.
* Rust core/FFI activation, SQLCipher storage, crypto keyring integration, and model training/runtime paths.

### Explicitly Out-of-Scope Functionality

* Medical-device claims or clinical hydration advice.
* Automatic provider mutation of app state without Hydrion validation and user confirmation.
* Shipping shared production Gemini/OpenAI/BYOK keys in web or mobile clients.
* Claiming disabled integrations are active before adapters, permissions, tests, and privacy copy exist.
* Treating stale config or blueprint files as runtime truth.

## 3. Personas and System Roles

* Application user: A person using Hydrion to log intake, review progress, receive local advice, and manage local app state.
* Returning user: A user who expects hydration logs, settings, reminders, and challenge state to survive app restart or refresh.
* Accessibility-focused user: A user relying on semantic labels, tooltips, scalable layouts, or clear empty/error states.
* Multilingual user: A user selecting or using English, Spanish, or French app strings.
* System or local application service: Hydrion repositories, services, validators, provider health reporter, and local storage components acting on behalf of the app.
* Optional external provider: Gemini today when explicitly configured for local development; ELKA, BYOK, OpenAI, edge, cloud, native, and social providers in future boundaries only.

## 4. User Stories

### HYD-US-001: Launch Standalone Local Application

**Epic:** Onboarding and Application Access  
**Status:** Implemented  
**Priority:** P0  
**Release Scope:** MVP

**As a** first-time application user  
**I need** Hydrion to open without account, network, provider, or native-service setup  
**So that** I can start tracking hydration immediately in standalone local mode.

#### Details and Assumptions

* Confirmed: `main()` initializes `HydrionServices.local()` and runs `HydrionApp`.
* Confirmed: `HydrionServices.memory()` supports tests and local-only operation without external services.
* Confirmed: default AI provider is `local_rules`, and optional Gemini is not required for boot.
* Inferred: "Onboarding" currently means direct app access; no guided onboarding wizard is implemented.

#### Acceptance Criteria

```gherkin
Given no provider API key, account, or network dependency is configured
When the app launches
Then the Home screen renders with Hydrion branding and local logging controls

Given optional providers are absent
When the app builds its service graph
Then local repositories, local coach, capability reporter, and local fallback remain available
```

#### Dependencies

* `HydrionServices`
* `HydrionApp`
* `HYD-US-031`

#### Out of Scope

* Account creation, sign-in, cloud onboarding, or medical-profile setup.

#### Repository Evidence

* `lib/main.dart`
* `README.md`
* `test/widget_test.dart`
* `test/gemini_provider_test.dart`

### HYD-US-002: Access Core Product Screens

**Epic:** Onboarding and Application Access  
**Status:** Implemented  
**Priority:** P0  
**Release Scope:** MVP

**As a** application user  
**I need** navigation to Home, Analytics, Log, Coach, Challenges, Reminders, Settings, and AR status screens  
**So that** I can reach every available hydration workflow from the app shell.

#### Details and Assumptions

* Confirmed: routes are registered for `/`, `/analytics`, `/chat`, `/log`, `/reminders`, `/settings`, `/challenges`, and `/ar`.
* Confirmed: Home exposes route chips for the main workflows.
* Confirmed: the AR route exists as a disabled/placeholder status screen, not a real AR session.

#### Acceptance Criteria

```gherkin
Given the user is on Home
When the user taps a core route chip or the Settings icon
Then the requested screen opens without requiring external service setup

Given a feature is disabled
When the user opens its route
Then the screen states the disabled or unavailable capability honestly
```

#### Dependencies

* `HYD-US-001`
* `HYD-US-031`

#### Out of Scope

* Deep links, authentication-protected routes, and remote navigation.

#### Repository Evidence

* `lib/main.dart`
* `lib/ui/screens/home_screen.dart`
* `lib/ui/screens/ar_visualization_screen.dart`
* `test/runtime_ux_test.dart`

### HYD-US-003: Log Hydration Manually

**Epic:** Hydration Logging  
**Status:** Implemented  
**Priority:** P0  
**Release Scope:** MVP

**As a** application user  
**I need** to select a water amount and log it locally  
**So that** Hydrion can calculate my daily hydration progress from saved intake records.

#### Details and Assumptions

* Confirmed: Home offers preset amounts of 150, 250, 350, 500, 750, and 1000 ml.
* Confirmed: tapping the log button creates a local hydration record with source `local`.
* Confirmed: repository validation rejects non-positive volumes.
* Inferred: custom log amount entry from Home is not implemented; custom values are available only through edit/provider paths.

#### Acceptance Criteria

```gherkin
Given the Home screen is open
When the user selects 500 ml and taps Log
Then a 500 ml local hydration record is saved

Given a non-positive volume reaches the repository
When the repository attempts to add it
Then no hydration log is created

Given the user logs water successfully
When the action completes
Then the user sees a localized confirmation message
```

#### Dependencies

* `HydrationRepository`
* `HYD-US-004`

#### Out of Scope

* Barcode/device import, voice capture, BLE intake, and arbitrary Home-screen amount entry.

#### Repository Evidence

* `lib/ui/screens/home_screen.dart`
* `lib/repositories/hydration_repository.dart`
* `test/runtime_ux_test.dart`

### HYD-US-004: Persist Hydration Logs Locally

**Epic:** Hydration Logging  
**Status:** Implemented  
**Priority:** P0  
**Release Scope:** MVP

**As a** returning user  
**I need** hydration records to persist on the device  
**So that** my history and analytics survive app restart or refresh.

#### Details and Assumptions

* Confirmed: hydration logs serialize to JSON under `hydrion.hydration_logs.v1`.
* Confirmed: `SharedPreferencesHydrionStore` is the production local store abstraction.
* Confirmed: repository reload restores valid logs and ignores malformed JSON or invalid records.
* Limitation: local storage is not encrypted and has no explicit export/delete UI.

#### Acceptance Criteria

```gherkin
Given a valid hydration log has been saved
When the hydration repository is reloaded from the same store
Then the log amount, timestamp, and day total are restored

Given stored hydration JSON is malformed
When the repository loads
Then Hydrion returns an empty log list without crashing
```

#### Dependencies

* `HydrionLocalStore`
* `SharedPreferencesHydrionStore`

#### Out of Scope

* Cloud sync, SQLCipher, encrypted export, and conflict resolution.

#### Repository Evidence

* `lib/storage/local_store.dart`
* `lib/repositories/hydration_repository.dart`
* `test/persistence_test.dart`

### HYD-US-005: View Recent Hydration History

**Epic:** Hydration History Management  
**Status:** Implemented  
**Priority:** P0  
**Release Scope:** MVP

**As a** returning user  
**I need** to review my recent hydration records with source and timestamp  
**So that** I can verify what Hydrion used for summaries and analytics.

#### Details and Assumptions

* Confirmed: Log screen fetches records from the last seven days.
* Confirmed: entries are shown with volume, localized source label, and formatted timestamp.
* Confirmed: an empty state explains that local entries can be added from Home.

#### Acceptance Criteria

```gherkin
Given saved logs exist in the recent history window
When the user opens the Log screen
Then each record shows its ml amount, source, timestamp, edit action, and delete action

Given no recent logs exist
When the user opens the Log screen
Then Hydrion shows a localized empty state explaining how to add local entries
```

#### Dependencies

* `HYD-US-003`
* `HYD-US-004`

#### Out of Scope

* Infinite history paging, filtering by source, export, or graphing history on this screen.

#### Repository Evidence

* `lib/ui/screens/log_screen.dart`
* `lib/repositories/hydration_repository.dart`
* `test/runtime_ux_test.dart`

### HYD-US-006: Edit Hydration Records

**Epic:** Hydration History Management  
**Status:** Implemented  
**Priority:** P1  
**Release Scope:** MVP

**As a** returning user  
**I need** to correct a saved hydration record  
**So that** mistakes do not distort my progress, analytics, score, achievements, or challenge progress.

#### Details and Assumptions

* Confirmed: Log screen opens an edit dialog for volume updates.
* Confirmed: invalid or non-positive edit input is discarded by the dialog/repository.
* Confirmed: edit values are clamped to 1 to 5000 ml in the UI.
* Confirmed: updated records persist across repository reload.

#### Acceptance Criteria

```gherkin
Given a saved hydration record exists
When the user edits the volume to 650 ml and saves
Then the record shows 650 ml and the repository persists the update

Given the user enters an invalid or non-positive edit value
When the dialog closes
Then no invalid hydration record is saved

Given the target log id no longer exists
When Hydrion attempts the edit
Then the user sees a localized "log not found" result
```

#### Dependencies

* `HYD-US-004`
* `HYD-US-005`

#### Out of Scope

* Editing timestamp or source from the UI.

#### Repository Evidence

* `lib/ui/screens/log_screen.dart`
* `lib/repositories/hydration_repository.dart`
* `test/persistence_test.dart`
* `test/runtime_ux_test.dart`

### HYD-US-007: Delete Hydration Records

**Epic:** Hydration History Management  
**Status:** Implemented  
**Priority:** P1  
**Release Scope:** MVP

**As a** returning user  
**I need** to delete incorrect hydration records  
**So that** my local summaries and derived insights reflect only valid intake.

#### Details and Assumptions

* Confirmed: Log screen delete action removes a record by id.
* Confirmed: delete persists across reload.
* Confirmed: the UI shows "deleted" or "not found" feedback.
* Limitation: there is no confirmation dialog before deletion.

#### Acceptance Criteria

```gherkin
Given a hydration record exists
When the user taps its delete action
Then the record is removed from history and local storage

Given the deleted record was the only record
When the Log screen refreshes
Then the empty state is shown

Given the target record id is missing
When deletion is attempted
Then Hydrion reports that the log was not found
```

#### Dependencies

* `HYD-US-004`
* `HYD-US-005`

#### Out of Scope

* Undo, batch delete, and account-level data erasure.

#### Repository Evidence

* `lib/ui/screens/log_screen.dart`
* `lib/repositories/hydration_repository.dart`
* `test/persistence_test.dart`
* `test/runtime_ux_test.dart`

### HYD-US-008: View Daily Summary and Progress Ring

**Epic:** Daily Goals and Progress  
**Status:** Implemented  
**Priority:** P0  
**Release Scope:** MVP

**As a** application user  
**I need** to see today's consumed ml, target ml, and progress percentage  
**So that** I can quickly decide whether to drink more water.

#### Details and Assumptions

* Confirmed: summary uses today's local logs and a fixed target of 2200 ml.
* Confirmed: `IntakeRing` clamps progress to 0 to 100 percent and includes semantic label/value/hint.
* Confirmed: Home updates after manual logging.
* Limitation: day boundary uses direct `DateTime.now()` calls rather than an injected clock.

#### Acceptance Criteria

```gherkin
Given no hydration is logged today
When the Home screen loads
Then the progress ring shows 0 / 2200 ml and 0 percent

Given the user logs 500 ml today
When the Home summary refreshes
Then the progress ring shows 500 / 2200 ml and a bounded progress percentage

Given consumed ml exceeds the target
When the progress ring renders
Then the displayed progress percentage does not exceed 100 percent
```

#### Dependencies

* `HYD-US-003`
* `HYD-US-004`

#### Out of Scope

* User-adjustable target, unit preference, activity/temperature target adjustment, or injected day-boundary service.

#### Repository Evidence

* `lib/adapters/local/local_hydrion_adapters.dart`
* `lib/ui/components/intake_ring.dart`
* `lib/ui/screens/home_screen.dart`
* `test/runtime_ux_test.dart`

### HYD-US-009: Configure Hydration Goals and Units

**Epic:** Daily Goals and Progress  
**Status:** Planned  
**Priority:** P1  
**Release Scope:** MVP

**As a** application user  
**I need** to configure my daily hydration target and unit preference  
**So that** Hydrion's progress reflects my personal hydration goal instead of a hardcoded default.

#### Details and Assumptions

* Confirmed: current Flutter runtime uses a fixed 2200 ml target in summary, analytics, and context.
* Confirmed: roadmap identifies target and unit preference as an MVP UX follow-up.
* Inferred requirement: configured goals should persist through `UserSettingsRepository` or another versioned local settings model.

#### Acceptance Criteria

```gherkin
Given a user has no custom hydration goal
When Hydrion calculates progress
Then the current 2200 ml default remains the fallback

Given the user sets a valid daily target
When Home, Analytics, Coach context, and Challenge calculations read goal data
Then they use the persisted target consistently

Given the user enters an invalid target or unit
When saving settings
Then Hydrion rejects the value without corrupting existing settings
```

#### Dependencies

* `HYD-US-008`
* `HYD-US-027`
* `HYD-US-042`

#### Out of Scope

* Medical target calculation, wearable-derived goals, or cloud profile sync.

#### Repository Evidence

* `lib/adapters/local/local_hydrion_adapters.dart`
* `lib/services/hydration_context_builder.dart`
* `lib/ui/screens/analytics_screen.dart`
* `HYDRION_MVP_KANBAN_ROADMAP.md`

### HYD-US-010: View Analytics Empty State and Daily Totals

**Epic:** Analytics and Insights  
**Status:** Implemented  
**Priority:** P1  
**Release Scope:** MVP

**As a** returning user  
**I need** analytics to reflect saved local hydration records  
**So that** I can understand today's intake and whether there is enough data for insights.

#### Details and Assumptions

* Confirmed: Analytics displays an empty state when no logs exist.
* Confirmed: Analytics displays today's ml against 2200 ml and local entry count.
* Confirmed: Analytics depends only on `HydrationRepository` and local services.

#### Acceptance Criteria

```gherkin
Given no hydration logs exist
When the user opens Analytics
Then Hydrion shows a localized "No analytics yet" state

Given local logs exist today
When the user opens Analytics
Then Hydrion shows today's consumed ml, target ml, and local entry count
```

#### Dependencies

* `HYD-US-004`
* `HYD-US-008`

#### Out of Scope

* Weekly/monthly trend charts, remote analytics, and telemetry.

#### Repository Evidence

* `lib/ui/screens/analytics_screen.dart`
* `test/runtime_ux_test.dart`
* `test/product_qa_test.dart`

### HYD-US-011: Calculate Hydration Score

**Epic:** Hydration Score  
**Status:** Implemented  
**Priority:** P1  
**Release Scope:** MVP

**As a** application user  
**I need** a simple hydration score  
**So that** I can interpret daily intake and logging consistency at a glance.

#### Details and Assumptions

* Confirmed: score is `80% hydrationPercent + 20% consistency`, where consistency is entry count capped at 4 logs.
* Confirmed: score is clamped to 0 to 100 and color-coded.
* Confirmed: localized tips vary by score threshold.
* Inferred: score is a wellness indicator, not a clinical metric.

#### Acceptance Criteria

```gherkin
Given today's hydration percent and entry count
When the hydration score card renders
Then it shows a 0 to 100 score based on the implemented weighted formula

Given entry count exceeds the consistency cap
When Hydrion calculates consistency
Then extra entries do not increase consistency beyond 100 percent

Given a score threshold is crossed
When the card renders
Then the displayed color and localized tip match the threshold
```

#### Dependencies

* `HYD-US-008`
* `HYD-US-010`

#### Out of Scope

* ML-based scoring, medical risk scoring, or personalized formula tuning.

#### Repository Evidence

* `lib/ui/components/hydration_score_card.dart`
* `lib/ui/screens/analytics_screen.dart`
* `test/product_qa_test.dart`

### HYD-US-012: Track Daily Goal Streaks

**Epic:** Streaks and Achievements  
**Status:** Implemented  
**Priority:** P1  
**Release Scope:** Supporting

**As a** returning user  
**I need** Hydrion to track consecutive days meeting the hydration target  
**So that** I can maintain a healthy habit over time.

#### Details and Assumptions

* Confirmed: Analytics computes streak days by checking up to 30 days backward.
* Confirmed: a seven-day streak unlocks a displayed achievement badge.
* Limitation: streak state is derived at render time and not persisted as its own record.

#### Acceptance Criteria

```gherkin
Given a user met the target today and on preceding consecutive days
When Analytics computes streaks
Then the streak count increments until the first non-target day

Given seven consecutive target days are present
When achievements render
Then the seven-day streak badge is unlocked
```

#### Dependencies

* `HYD-US-004`
* `HYD-US-013`

#### Out of Scope

* Streak repair, pause days, notifications for streak risk, or persisted streak history.

#### Repository Evidence

* `lib/ui/screens/analytics_screen.dart`
* `lib/ui/components/achievement_badge.dart`

### HYD-US-013: Display Local Achievement Badges

**Epic:** Streaks and Achievements  
**Status:** Implemented  
**Priority:** P1  
**Release Scope:** Supporting

**As a** application user  
**I need** visible achievement badges based on local hydration behavior  
**So that** Hydrion reinforces useful logging and intake habits.

#### Details and Assumptions

* Confirmed: current badges are 2L day, 3 logs today, and 7 day streak.
* Confirmed: badge semantics include badge name and locked/unlocked status.
* Limitation: achievements are not persisted or stored as historical unlock events.

#### Acceptance Criteria

```gherkin
Given today's total is at least 2000 ml
When Analytics renders achievements
Then the 2L day badge is unlocked

Given today's entry count is at least 3
When Analytics renders achievements
Then the 3 logs today badge is unlocked

Given a condition is not met
When the badge renders
Then it appears locked with appropriate accessible semantics
```

#### Dependencies

* `HYD-US-004`
* `HYD-US-012`

#### Out of Scope

* Achievement sound effects, sharing, backend leaderboards, or unlock history.

#### Repository Evidence

* `lib/ui/screens/analytics_screen.dart`
* `lib/ui/components/achievement_badge.dart`
* `lib/l10n/app_en.arb`

### HYD-US-014: Estimate Eco Impact From Local Logs

**Epic:** Eco-Impact Tracking  
**Status:** Implemented  
**Priority:** P2  
**Release Scope:** Supporting

**As a** sustainability-minded user  
**I need** an environmental impact estimate from my logged hydration  
**So that** I can see a simple local estimate of plastic saved.

#### Details and Assumptions

* Confirmed: eco estimate uses total lifetime ml from `HydrationRepository`.
* Confirmed: the formula treats each 500 ml as an avoided half-liter bottle and estimates 0.01 kg plastic saved per bottle.
* Inferred: this is a rough local estimate, not a verified environmental audit.

#### Acceptance Criteria

```gherkin
Given lifetime hydration logs total 500 ml
When the eco tracker calculates plastic saved
Then it returns approximately 0.01 kg

Given no logs exist
When Analytics renders eco impact
Then it shows 0.00 kg and explains the value is a local estimate from logs
```

#### Dependencies

* `HYD-US-004`
* `HYD-US-010`

#### Out of Scope

* Carbon accounting, bottle-material customization, or remote sustainability services.

#### Repository Evidence

* `lib/services/eco_tracker.dart`
* `lib/services/core_bridge.dart`
* `lib/ui/screens/analytics_screen.dart`
* `test/persistence_test.dart`

### HYD-US-015: Save Local Reminder Definitions

**Epic:** Reminders  
**Status:** Implemented  
**Priority:** P1  
**Release Scope:** MVP

**As a** application user  
**I need** Hydrion to save local reminder definitions based on hydration context  
**So that** I can review hydration nudges even when OS notifications are unavailable.

#### Details and Assumptions

* Confirmed: Home reminder tile calls `NotificationService.scheduleReminder`.
* Confirmed: reminder policy computes urgency, delay, message, and priority from shortfall, last drink age, hydration percent, and active time.
* Confirmed: reminder definitions persist under `hydrion.reminders.v1`.
* Limitation: OS notifications are not scheduled.

#### Acceptance Criteria

```gherkin
Given the reminder policy allows a reminder
When the user taps the Home reminder action
Then a local reminder definition is saved with trigger time, message, and priority

Given a reminder is saved
When the repository reloads
Then the reminder definition is restored from local storage

Given OS notifications are disabled
When the reminder is saved
Then the confirmation message says the definition is local only
```

#### Dependencies

* `ReminderRepository`
* `NotificationService`
* `HYD-US-017`

#### Out of Scope

* Real platform notification delivery, snooze, recurring schedules, or quiet-hour enforcement.

#### Repository Evidence

* `lib/services/notifications.dart`
* `lib/services/policy_service.dart`
* `lib/repositories/reminder_repository.dart`
* `lib/ui/components/reminder_tile.dart`
* `test/persistence_test.dart`
* `test/runtime_ux_test.dart`

### HYD-US-016: Manage Saved Reminder Definitions

**Epic:** Reminders  
**Status:** Implemented  
**Priority:** P1  
**Release Scope:** MVP

**As a** returning user  
**I need** to view and delete saved local reminder definitions  
**So that** stale reminders do not clutter my local app state.

#### Details and Assumptions

* Confirmed: Reminders screen lists saved reminders with timestamp and priority.
* Confirmed: the screen displays an empty state when none exist.
* Confirmed: delete removes the reminder and persists the change.

#### Acceptance Criteria

```gherkin
Given local reminder definitions exist
When the user opens Reminders
Then each reminder shows message, trigger timestamp, priority, and delete action

Given the user deletes a reminder definition
When the action completes
Then the reminder is removed and a localized confirmation appears

Given no reminders exist
When the user opens Reminders
Then Hydrion shows the local reminder empty state
```

#### Dependencies

* `HYD-US-015`

#### Out of Scope

* Editing reminder definitions or scheduling native notifications.

#### Repository Evidence

* `lib/ui/screens/reminders_screen.dart`
* `lib/repositories/reminder_repository.dart`
* `test/runtime_ux_test.dart`

### HYD-US-017: Gate OS Notification Scheduling

**Epic:** Reminders  
**Status:** Gated  
**Priority:** P1  
**Release Scope:** Supporting

**As an** application user  
**I need** Hydrion to clearly distinguish local reminders from real OS notifications  
**So that** I do not expect a device alert that will not fire.

#### Details and Assumptions

* Confirmed: `NotificationService.supportsOsNotifications` returns false.
* Confirmed: standalone capabilities set `osNotifications` to false.
* Confirmed: Settings and Reminders copy state that definitions remain local.
* Inferred: real notification scheduling is a post-MVP adapter requiring permissions and platform tests.

#### Acceptance Criteria

```gherkin
Given standalone mode is active
When the user views Settings or Reminders
Then OS notifications are labeled disabled

Given a provider suggests a reminder that claims OS notification scheduling
When Hydrion validates the action
Then the action is rejected because OS notifications are unavailable

Given a future notification adapter is enabled
When capability reporting changes
Then the UI must distinguish configured capability from actual scheduling support
```

#### Dependencies

* `HYD-US-015`
* `HYD-US-031`

#### Out of Scope

* Implementing platform notification permissions, repeat rules, cancellation, or background delivery.

#### Repository Evidence

* `lib/services/notifications.dart`
* `lib/domain/hydration_contracts.dart`
* `lib/ui/screens/reminders_screen.dart`
* `test/adapter_contract_test.dart`
* `HYDRION_MVP_KANBAN_ROADMAP.md`

### HYD-US-018: Join a Local Hydration Challenge

**Epic:** Challenges  
**Status:** Implemented  
**Priority:** P1  
**Release Scope:** MVP

**As a** motivation-focused user  
**I need** to join a local hydration challenge  
**So that** I can pursue a short-term goal without social sync or backend accounts.

#### Details and Assumptions

* Confirmed: local challenge generator creates a Seven Day Steady Sip challenge.
* Confirmed: beginner challenge target is 2000 ml/day for 7 days; other levels exist in the generator.
* Confirmed: UI exposes a Join action and persists one active challenge.
* Limitation: current UI loads the beginner challenge only.

#### Acceptance Criteria

```gherkin
Given no active challenge exists
When the user opens Challenges
Then Hydrion shows local challenge mode and a joinable local challenge

Given the user taps Join
When the repository saves the challenge
Then the challenge is marked joined and persisted locally

Given social sync is unavailable
When the challenge screen renders
Then it states challenge progress is saved on this device
```

#### Dependencies

* `ChallengeRepository`
* `ChallengeGenerator`
* `HYD-US-031`

#### Out of Scope

* Multiplayer/social invitations, leaderboards, or remote challenge catalogs.

#### Repository Evidence

* `lib/adapters/local/local_hydrion_adapters.dart`
* `lib/repositories/challenge_repository.dart`
* `lib/ui/screens/social_challenges_screen.dart`
* `test/runtime_ux_test.dart`
* `test/persistence_test.dart`

### HYD-US-019: Track Local Challenge Progress

**Epic:** Challenges  
**Status:** Implemented  
**Priority:** P1  
**Release Scope:** MVP

**As a** returning user in a challenge  
**I need** challenge progress to update from saved hydration logs  
**So that** I know how many challenge days I have completed.

#### Details and Assumptions

* Confirmed: progress counts completed days where local day total meets the challenge target.
* Confirmed: progress includes completed days, duration days, today's ml, and target ml.
* Limitation: `DateTime.now()` is used directly; there is no injected clock/time-zone boundary abstraction yet.

#### Acceptance Criteria

```gherkin
Given an active challenge exists
When the user logs enough water for a challenge day
Then the progress calculation counts that day as complete

Given today's intake is below the challenge target
When the challenge screen renders
Then Hydrion shows today's ml against the challenge target

Given no active challenge exists
When progress is requested
Then Hydrion returns zero completed days and zero target context
```

#### Dependencies

* `HYD-US-004`
* `HYD-US-018`

#### Out of Scope

* Time-zone migration, challenge completion history, or remote progress sync.

#### Repository Evidence

* `lib/repositories/challenge_repository.dart`
* `lib/ui/screens/social_challenges_screen.dart`
* `lib/services/hydration_context_builder.dart`

### HYD-US-020: Leave Challenges and Keep Completion History

**Epic:** Challenges  
**Status:** Partial  
**Priority:** P2  
**Release Scope:** Supporting

**As a** challenge participant  
**I need** to leave a challenge and retain local completion history  
**So that** challenge state remains controllable and auditable.

#### Details and Assumptions

* Confirmed: `ChallengeRepository.leave()` can clear the active challenge.
* Confirmed: roadmap notes missing local challenge leave, completion, and history work.
* Limitation: current UI does not expose Leave, does not persist completion events, and supports only one active challenge.

#### Acceptance Criteria

```gherkin
Given the user has joined a challenge
When the user chooses Leave in a future UI
Then the active challenge is cleared from local state

Given a challenge reaches its completion condition
When Hydrion records completion
Then completion history is saved locally without requiring social sync

Given no completion-history implementation exists
When current code runs
Then Hydrion must not claim challenge history is available
```

#### Dependencies

* `HYD-US-018`
* `HYD-US-019`

#### Out of Scope

* Social challenge history, remote moderation, or backend achievements.

#### Repository Evidence

* `lib/repositories/challenge_repository.dart`
* `lib/ui/screens/social_challenges_screen.dart`
* `HYDRION_MVP_KANBAN_ROADMAP.md`

### HYD-US-021: Show Local Hydration Advice on Home

**Epic:** Local Hydration Coach  
**Status:** Implemented  
**Priority:** P1  
**Release Scope:** MVP

**As a** application user  
**I need** local hydration advice based on progress and entry count  
**So that** I receive useful guidance without sending data off-device.

#### Details and Assumptions

* Confirmed: `LLMAdviceCard` uses `HydrationCoach`.
* Confirmed: local coach advice changes by hydration percent and adds context about heat and entry count.
* Confirmed: advice is localized on Home.
* Confirmed: failures render a retry UI.

#### Acceptance Criteria

```gherkin
Given local_rules mode is active
When Home renders advice
Then the advice is generated locally and localized for the active locale

Given advice loading fails
When the card renders
Then Hydrion shows a localized failure state with retry

Given hydration percent or locale changes
When the advice card updates
Then cached advice is refreshed
```

#### Dependencies

* `HYD-US-008`
* `HYD-US-029`

#### Out of Scope

* Clinical advice, remote provider requirement, or raw prompt display.

#### Repository Evidence

* `lib/ui/components/llm_advice_card.dart`
* `lib/adapters/local/local_hydrion_adapters.dart`
* `lib/main.dart`
* `test/localization_test.dart`

### HYD-US-022: Chat With Local Hydration Coach

**Epic:** Local Hydration Coach  
**Status:** Implemented  
**Priority:** P1  
**Release Scope:** MVP

**As a** local-first user  
**I need** to ask a hydration coach question  
**So that** I can receive deterministic guidance from saved local hydration context.

#### Details and Assumptions

* Confirmed: Coach screen shows today's ml, target, event count, selected provider, and active provider.
* Confirmed: local fallback replies include local deterministic mode and saved log summary.
* Confirmed: empty input and duplicate send while busy are ignored.
* Confirmed: provider errors show localized snack-bar errors or fallback notices.

#### Acceptance Criteria

```gherkin
Given local_rules is active
When the user asks the coach a question
Then Hydrion responds with deterministic local guidance based on saved logs

Given the user submits an empty message
When the send action runs
Then no coach request is made

Given a provider fallback occurs
When the coach turn completes
Then Hydrion shows a localized fallback notice
```

#### Dependencies

* `HYD-US-023`
* `HYD-US-031`

#### Out of Scope

* Long-term chat memory, cloud chat history, or free-form provider tool execution.

#### Repository Evidence

* `lib/ui/screens/chat_coach_screen.dart`
* `lib/adapters/local/local_hydrion_adapters.dart`
* `lib/services/hydration_ai_orchestrator.dart`
* `test/product_qa_test.dart`

### HYD-US-023: Build Typed Hydration Context

**Epic:** Local Hydration Coach  
**Status:** Implemented  
**Priority:** P1  
**Release Scope:** Supporting

**As a** local application service  
**I need** a typed hydration context for coaches and providers  
**So that** advice and provider proposals use consistent, bounded app state.

#### Details and Assumptions

* Confirmed: `LocalHydrationContextProvider` builds daily summary, lifetime ml, event count, reminder context, challenge context, and capabilities.
* Confirmed: context is built from repositories and capability reporter.
* Confirmed: optional providers receive typed context instead of mutating repositories.

#### Acceptance Criteria

```gherkin
Given saved logs, reminders, and challenge state exist
When Hydrion builds provider context
Then the context contains daily summary, lifetime totals, reminder state, challenge state, and capabilities

Given optional capabilities are disabled
When context is built
Then disabled capability flags remain false
```

#### Dependencies

* `HYD-US-004`
* `HYD-US-015`
* `HYD-US-018`
* `HYD-US-031`

#### Out of Scope

* Raw provider prompts, raw cloud payload storage, or external context sync.

#### Repository Evidence

* `lib/services/hydration_context_builder.dart`
* `lib/domain/hydration_contracts.dart`
* `docs/architecture/AI_ACTION_CONTRACT.md`
* `test/adapter_contract_test.dart`

### HYD-US-024: Confirm Coach Suggestions Before State Changes

**Epic:** Local Hydration Coach  
**Status:** Implemented  
**Priority:** P1  
**Release Scope:** Supporting

**As an** application user  
**I need** coach suggestions that change logs, reminders, or challenges to require confirmation  
**So that** no provider or coach output mutates my local data without consent.

#### Details and Assumptions

* Confirmed: suggestion cards can represent hydration log, reminder, challenge, trend insight, and unsupported capability proposals.
* Confirmed: state-changing actions require confirmation.
* Confirmed: executor writes only through repositories after validation.
* Confirmed: dismissing a card removes the pending proposal without changing state.

#### Acceptance Criteria

```gherkin
Given a valid hydration-log suggestion appears
When the user confirms it
Then Hydrion writes the log through `HydrationRepository`

Given a state-changing suggestion appears
When the user does not confirm it
Then no log, reminder, or challenge state is changed

Given an unsupported-capability notice appears
When the card renders
Then it is display-only and cannot be applied as a state change
```

#### Dependencies

* `HYD-US-022`
* `HYD-US-031`

#### Out of Scope

* Provider auto-execution, raw action class display, or long-term suggestion audit history.

#### Repository Evidence

* `lib/services/coach_suggestion_service.dart`
* `lib/services/hydration_ai_action_executor.dart`
* `lib/ui/screens/chat_coach_screen.dart`
* `test/coach_suggestion_service_test.dart`
* `test/coach_suggestion_cards_test.dart`

### HYD-US-025: Parse Hydration Commands for Typed or Future Voice Use

**Epic:** Local Hydration Coach  
**Status:** Partial  
**Priority:** P2  
**Release Scope:** Supporting

**As a** hands-free or typed-command user  
**I need** Hydrion to parse hydration-related commands into stable intents  
**So that** future voice or command surfaces can route requests safely.

#### Details and Assumptions

* Confirmed: local parser returns `log_hydration`, `schedule_reminder`, or `unknown_command`.
* Confirmed: numeric ml extraction supports simple commands like "log 450 ml".
* Confirmed: `VoiceLLMBridge` normalizes parser output.
* Limitation: there is no active voice capture UI or typed command UI that applies parsed commands.

#### Acceptance Criteria

```gherkin
Given the command "log 450 ml"
When the local parser runs
Then it returns intent `log_hydration` and `volumeMl` 450

Given a reminder command
When the local parser runs
Then it returns intent `schedule_reminder`

Given an unknown command
When the local parser runs
Then it returns `unknown_command` with the original command
```

#### Dependencies

* `HYD-US-026`
* `HYD-US-031`

#### Out of Scope

* Microphone permission, speech-to-text, command confirmation, or direct command execution.

#### Repository Evidence

* `lib/adapters/local/local_hydrion_adapters.dart`
* `lib/services/voice_llm_bridge.dart`
* `lib/services/voice_client.dart`
* `test/adapter_contract_test.dart`

### HYD-US-026: Gate Voice Capture Until a Real Adapter Exists

**Epic:** Local Hydration Coach  
**Status:** Gated  
**Priority:** P2  
**Release Scope:** Post-MVP

**As an** accessibility-focused or hands-free user  
**I need** voice capture to stay disabled until microphone capture and confirmation are real  
**So that** Hydrion does not pretend to support a privacy-sensitive feature.

#### Details and Assumptions

* Confirmed: `VoiceService.isAvailable` and `initialize()` return false.
* Confirmed: `VoiceInputWidget` is disabled and uses disabled semantics/tooltips.
* Confirmed: permissions service does not request microphone permissions in standalone mode.
* Inferred: future voice support needs permission flow, transcript preview, locale handling, and confirmation.

#### Acceptance Criteria

```gherkin
Given standalone mode is active
When the user views the voice floating action button
Then it is disabled and labeled as unavailable

Given a user checks permissions
When standalone permissions run
Then no microphone permission is requested

Given a future voice adapter is added
When a command is parsed
Then state changes still require user confirmation before execution
```

#### Dependencies

* `HYD-US-025`
* `HYD-US-031`

#### Out of Scope

* Implementing ASR, TTS, wake phrase, audio storage, or platform microphone permissions.

#### Repository Evidence

* `lib/services/voice_client.dart`
* `lib/ui/components/voice_input_widget.dart`
* `lib/utils/permissions.dart`
* `test/persistence_test.dart`
* `HYDRION_MVP_KANBAN_ROADMAP.md`

### HYD-US-027: Persist Language Settings

**Epic:** Settings and Personalization  
**Status:** Implemented  
**Priority:** P1  
**Release Scope:** MVP

**As a** multilingual user  
**I need** to select and persist my app language  
**So that** Hydrion continues in my preferred supported language after reload.

#### Details and Assumptions

* Confirmed: Settings exposes English, Spanish, and French in a locale picker.
* Confirmed: `I18nResolver` persists the resolved locale through `UserSettingsRepository`.
* Confirmed: unsupported locales fall back to English.

#### Acceptance Criteria

```gherkin
Given the user selects French
When settings save the locale
Then app strings update to French and the locale is stored locally

Given Hydrion reloads from the same local store
When services initialize
Then the previously selected locale is restored

Given an unsupported locale is requested
When the resolver processes it
Then Hydrion falls back to English
```

#### Dependencies

* `HYD-US-029`
* `HYD-US-004`

#### Out of Scope

* Downloadable language packs or partial runtime string maps outside `gen_l10n`.

#### Repository Evidence

* `lib/ui/screens/settings_screen.dart`
* `lib/utils/i18n_resolver.dart`
* `lib/repositories/settings_repository.dart`
* `test/localization_test.dart`
* `test/persistence_test.dart`

### HYD-US-028: Show Runtime Capability and Permission Status

**Epic:** Settings and Personalization  
**Status:** Implemented  
**Priority:** P1  
**Release Scope:** Supporting

**As an** application user  
**I need** Settings to show what Hydrion can and cannot do at runtime  
**So that** I understand which features are local, disabled, unconfigured, or future.

#### Details and Assumptions

* Confirmed: Settings shows local persistence, ELKA, cloud AI, voice, BLE, Health, OS notifications, AR, and social sync status.
* Confirmed: standalone permissions check reports that no platform permissions are requested.
* Confirmed: capability states come from `AppCapabilityReporter`.

#### Acceptance Criteria

```gherkin
Given standalone capabilities are active
When the user opens Settings
Then local persistence is shown on-device and optional integrations are shown disabled or unconfigured

Given the user taps the permission check
When standalone mode runs
Then Hydrion reports that no platform permissions were requested

Given Gemini is configured by runtime defines
When Settings renders
Then cloud AI/Gemini status reflects the configured provider state
```

#### Dependencies

* `HYD-US-031`
* `HYD-US-033`

#### Out of Scope

* Runtime toggles for disabled integrations or actual permission request flows.

#### Repository Evidence

* `lib/ui/screens/settings_screen.dart`
* `lib/utils/permissions.dart`
* `lib/domain/hydration_contracts.dart`
* `test/runtime_ux_test.dart`
* `test/product_qa_test.dart`

### HYD-US-029: Render English, Spanish, and French App Strings

**Epic:** Localization  
**Status:** Implemented  
**Priority:** P0  
**Release Scope:** MVP

**As a** multilingual user  
**I need** Hydrion's core UI in English, Spanish, and French  
**So that** I can use the main flows in a supported language.

#### Details and Assumptions

* Confirmed: `lib/l10n/app_en.arb`, `app_es.arb`, and `app_fr.arb` exist.
* Confirmed: Flutter `gen_l10n` output is committed under `lib/l10n`.
* Confirmed: tests verify core shell strings and provider status strings in all three locales.

#### Acceptance Criteria

```gherkin
Given the locale is English, Spanish, or French
When Hydrion renders Home and Settings
Then core labels appear in the selected language

Given generated localization lookup is used
When a localized widget renders
Then strings come from `AppLocalizations`

Given a user changes locale at runtime
When `I18nResolver` notifies the app
Then visible strings update without app restart
```

#### Dependencies

* `HYD-US-027`

#### Out of Scope

* Arabic, German, Portuguese, Chinese, or other future languages until ARB files exist.

#### Repository Evidence

* `l10n.yaml`
* `lib/l10n/app_en.arb`
* `lib/l10n/app_es.arb`
* `lib/l10n/app_fr.arb`
* `lib/l10n/app_localizations.dart`
* `test/localization_test.dart`
* `test/product_qa_test.dart`

### HYD-US-030: Handle Future and Unsupported Locales Safely

**Epic:** Localization  
**Status:** Partial  
**Priority:** P2  
**Release Scope:** Supporting

**As a** multilingual user outside current locale coverage  
**I need** Hydrion to fall back safely and label future languages honestly  
**So that** I am not shown incomplete localization as if it were shipped.

#### Details and Assumptions

* Confirmed: `I18nResolver.futureLocales` includes Arabic, German, Portuguese, and Chinese.
* Confirmed: unsupported and future locales fall back to English for active UI.
* Confirmed: RTL helper exists for locale text direction.
* Limitation: no future-locale ARB files are active in the Flutter app.

#### Acceptance Criteria

```gherkin
Given the user requests German
When locale resolution runs
Then Hydrion falls back to English and identifies German as future

Given the user requests an unsupported locale
When locale status is checked
Then Hydrion identifies it as unsupported

Given a future RTL locale becomes active
When text direction is requested
Then the resolver can report RTL direction for that locale
```

#### Dependencies

* `HYD-US-027`
* `HYD-US-029`

#### Out of Scope

* Shipping future translations before ARB parity and UI validation exist.

#### Repository Evidence

* `lib/utils/i18n_resolver.dart`
* `test/localization_test.dart`
* `docs/architecture/AI_ACTION_CONTRACT.md`

### HYD-US-031: Enforce Capability Gating and Safe Action Validation

**Epic:** Capability Gating  
**Status:** Implemented  
**Priority:** P0  
**Release Scope:** Supporting

**As a** local application service  
**I need** unavailable features and unsafe provider claims to be blocked  
**So that** Hydrion cannot mislead users or mutate state through unsupported capabilities.

#### Details and Assumptions

* Confirmed: standalone capabilities disable ELKA, Gemini, cloud AI, cloud sync, voice, BLE, Health, OS notifications, AR, and social sync by default.
* Confirmed: `HydrationAiActionValidator` blocks unavailable required capabilities and unsafe capability claims.
* Confirmed: invalid hydration amounts outside 1 to 5000 ml are rejected for provider suggestions.

#### Acceptance Criteria

```gherkin
Given an action claims disabled voice, BLE, cloud sync, ELKA, Gemini, AR, Health, social sync, or notifications are active
When Hydrion validates the action
Then the action is rejected and converted to an unsupported-capability notice

Given a state-changing provider suggestion is structurally valid
When it lacks user confirmation
Then Hydrion does not execute it

Given standalone capabilities are reported
When Settings and Coach render
Then they use capability state instead of guessing feature availability
```

#### Dependencies

* `HYD-US-023`
* `HYD-US-024`

#### Out of Scope

* Enabling disabled integrations or bypassing confirmation for provider output.

#### Repository Evidence

* `lib/domain/hydration_contracts.dart`
* `lib/adapters/local/local_hydrion_adapters.dart`
* `test/ai_action_contract_test.dart`
* `test/adapter_contract_test.dart`
* `docs/architecture/AI_ACTION_CONTRACT.md`

### HYD-US-032: Use Optional Gemini Provider With Local Fallback

**Epic:** External Provider Integration  
**Status:** Gated  
**Priority:** P2  
**Release Scope:** Supporting

**As an** optional provider evaluator  
**I need** Gemini to run only when explicitly configured  
**So that** Hydrion keeps local_rules as default and avoids unsafe production key handling.

#### Details and Assumptions

* Confirmed: Gemini selection uses Dart defines `HYDRION_AI_PROVIDER=gemini`, `HYDRION_GEMINI_API_KEY`, and optional `HYDRION_GEMINI_MODEL`.
* Confirmed: missing key, timeout, HTTP error, malformed response, parser rejection, and validator rejection fall back to `local_rules`.
* Confirmed: Gemini returns typed `HydrationAiAction` proposals only.
* Limitation: production shared client keys are explicitly not allowed.

#### Acceptance Criteria

```gherkin
Given no Gemini runtime defines are present
When Hydrion starts
Then selected provider remains local_rules

Given Gemini is selected but no API key is configured
When the coach requests provider output
Then no Gemini network request is attempted and local_rules handles the reply

Given Gemini returns valid typed action JSON
When parser and validator accept it
Then Hydrion may display the validated response or suggestion

Given Gemini fails or returns unsafe output
When Hydrion handles the request
Then the user receives local_rules fallback without raw prompt, context, response, or full key leakage
```

#### Dependencies

* `HYD-US-023`
* `HYD-US-031`
* `HYD-US-033`
* `HYD-US-051`

#### Out of Scope

* Production shared Gemini key shipping, Gemini SDK dependency, OpenAI/BYOK routing, or provider auto-execution.

#### Repository Evidence

* `lib/services/ai_provider_config.dart`
* `lib/adapters/gemini/gemini_adapter.dart`
* `lib/services/hydration_ai_orchestrator.dart`
* `test/gemini_provider_test.dart`
* `docs/architecture/GEMINI_API_INTEGRATION_AUDIT.md`
* `docs/architecture/PROVIDER_SECURITY.md`

### HYD-US-033: Display Safe Provider Health Diagnostics

**Epic:** External Provider Integration  
**Status:** Implemented  
**Priority:** P1  
**Release Scope:** Supporting

**As an** application user or developer  
**I need** provider status and safe diagnostics in Settings and Coach  
**So that** I can understand whether local_rules or an optional provider handled a response.

#### Details and Assumptions

* Confirmed: provider health tracks selected provider, active provider, configured state, fallback state, diagnostics, and privacy disclosure.
* Confirmed: Settings displays safe Gemini diagnostics such as endpoint host, model path, key presence, key length, first/last four characters, request attempted, HTTP status class, parser/validator codes, and fallback code.
* Confirmed: normal Coach UI hides raw diagnostic internals and full secrets.

#### Acceptance Criteria

```gherkin
Given local_rules is active
When Settings renders provider health
Then it shows local_rules as selected/active and local-only privacy copy

Given Gemini is configured
When Settings renders diagnostics
Then it shows safe key/request metadata without full API key, raw prompt, raw context, or raw response

Given provider fallback occurs
When Settings and Coach render
Then the user can see fallback is active without private query leakage
```

#### Dependencies

* `HYD-US-032`
* `HYD-US-051`

#### Out of Scope

* Logging full provider payloads or exposing secret values for debugging.

#### Repository Evidence

* `lib/services/provider_health.dart`
* `lib/ui/screens/settings_screen.dart`
* `lib/ui/screens/chat_coach_screen.dart`
* `test/gemini_provider_test.dart`
* `test/product_qa_test.dart`

### HYD-US-034: Keep ELKA as an Optional Adapter Boundary

**Epic:** External Provider Integration  
**Status:** Post-MVP  
**Priority:** P2  
**Release Scope:** Post-MVP

**As an** external provider integrator  
**I need** ELKA to plug in behind Hydrion contracts only when configured  
**So that** Hydrion remains standalone and UI-provider independent.

#### Details and Assumptions

* Confirmed: `ElkaAdapterShell.unconfigured()` exists and is compile-safe.
* Confirmed: shell methods throw `UnsupportedError` and `isConfigured` is false.
* Confirmed: UI import rules forbid direct ELKA adapter imports.
* Inferred: a real ELKA adapter must implement existing domain contracts and require consent/provider health UX.

#### Acceptance Criteria

```gherkin
Given the current app build
When ELKA shell status is checked
Then ELKA is unconfigured and unavailable

Given UI code is inspected
When architecture tests run
Then UI files do not import ELKA adapters directly

Given a future ELKA adapter is implemented
When Hydrion runs without ELKA configuration
Then local_rules remains the default fallback
```

#### Dependencies

* `HYD-US-031`
* `HYD-US-049`
* `HYD-US-051`

#### Out of Scope

* ELKA network calls, ELKA credentials, ELKA-specific UI coupling, or replacing local mode.

#### Repository Evidence

* `lib/adapters/elka/elka_adapter.dart`
* `docs/architecture/ADAPTER_BOUNDARY.md`
* `test/adapter_contract_test.dart`
* `test/boundary_architecture_test.dart`

### HYD-US-035: Add Native BLE, Health, and AR Integrations Later

**Epic:** Platform and Native Capabilities  
**Status:** Post-MVP  
**Priority:** P3  
**Release Scope:** Post-MVP

**As a** user with device or platform integrations  
**I need** BLE smart-bottle, Health, and AR capabilities only after real adapters exist  
**So that** Hydrion does not request sensitive permissions or show fake integration behavior.

#### Details and Assumptions

* Confirmed: BLE service reports unavailable, returns empty scans, and reads no water level.
* Confirmed: wearable service reports BLE and Health sync unsupported.
* Confirmed: AR screen states no plugin, camera permission, or native AR session is active.
* Confirmed: stale config may claim BLE/voice/wearable enabled, but runtime capabilities are authoritative.

#### Acceptance Criteria

```gherkin
Given standalone mode is active
When users inspect capability status
Then BLE, Health, and AR are disabled or unavailable

Given a user opens the AR screen
When no AR adapter is configured
Then no camera or native AR session starts

Given a future native adapter is added
When permissions are required
Then Hydrion must gate the feature with explicit permission, privacy copy, and tests
```

#### Dependencies

* `HYD-US-028`
* `HYD-US-031`

#### Out of Scope

* Implementing BLE protocols, HealthKit/Google Fit permissions, or AR camera rendering in the current MVP.

#### Repository Evidence

* `lib/services/ble_service.dart`
* `lib/services/wearable_service.dart`
* `lib/ui/screens/ar_visualization_screen.dart`
* `lib/ui/screens/settings_screen.dart`
* `docs/architecture/STALE_SCAFFOLD_AUDIT.md`

### HYD-US-036: Run as a Web App With PWA Metadata

**Epic:** Platform and PWA Capabilities  
**Status:** Partial  
**Priority:** P1  
**Release Scope:** MVP

**As a** web user  
**I need** Hydrion to build and launch as a Flutter web app with PWA metadata  
**So that** I can use the local-first hydration experience in a browser.

#### Details and Assumptions

* Confirmed: README includes `flutter run -d chrome` and `flutter build web --release`.
* Confirmed: CI builds and uploads `build/web`.
* Confirmed: web manifest includes standalone display, icons, orientation, and manifest link.
* Limitation: manifest/index title and description still use default Flutter `hydrion_app` / "A new Flutter project" metadata.

#### Acceptance Criteria

```gherkin
Given Flutter dependencies are installed
When `flutter build web --release` runs in CI
Then Hydrion produces a web build artifact

Given the web app is installed or launched
When the manifest is read
Then standalone display and icon metadata are available

Given release readiness work is performed
When metadata is audited
Then default Flutter title/description are replaced with Hydrion product metadata
```

#### Dependencies

* `HYD-US-001`
* `HYD-US-050`

#### Out of Scope

* Service-worker custom offline caching strategy beyond Flutter defaults, web push notifications, or cloud hosting.

#### Repository Evidence

* `README.md`
* `web/manifest.json`
* `web/index.html`
* `.github/workflows/flutter-ci.yml`

### HYD-US-037: Build Android APK

**Epic:** Platform and PWA Capabilities  
**Status:** Implemented  
**Priority:** P1  
**Release Scope:** MVP

**As an** Android tester  
**I need** Hydrion to build as an Android APK  
**So that** the MVP can be validated on Android devices or internal release channels.

#### Details and Assumptions

* Confirmed: README includes `flutter build apk --release`.
* Confirmed: CI build job builds and uploads the Android APK.
* Confirmed: Android manifest and Gradle config are standard Flutter output.
* Limitation: application id, app label, and release signing remain default/debug-oriented and need release cleanup.

#### Acceptance Criteria

```gherkin
Given Android SDK and Flutter are configured
When `flutter build apk --release` runs
Then Hydrion produces a release APK artifact

Given CI completes the Android build job
When artifacts are uploaded
Then `hydrion-android-apk` contains the generated APK

Given release metadata is audited
When Android config is reviewed
Then default app id, label, and debug signing are flagged before production release
```

#### Dependencies

* `HYD-US-001`
* `HYD-US-050`

#### Out of Scope

* Store listing, production signing, Play Console deployment, or native integrations.

#### Repository Evidence

* `README.md`
* `android/app/build.gradle.kts`
* `android/app/src/main/AndroidManifest.xml`
* `.github/workflows/flutter-ci.yml`

### HYD-US-038: Design Cloud, Social, BYOK, OpenAI, and Edge Integrations

**Epic:** External Provider Integration  
**Status:** Post-MVP  
**Priority:** P3  
**Release Scope:** Post-MVP

**As a** future integration owner  
**I need** cloud/social/provider integrations to be designed before implementation  
**So that** user privacy, consent, credentials, moderation, and sync conflicts are handled responsibly.

#### Details and Assumptions

* Confirmed: Firebase and OpenAI configs are placeholders/future only.
* Confirmed: BYOK, edge LLM, and separate Gemini connector packs are not wired into Flutter runtime.
* Confirmed: local challenges have no social backend.
* Confirmed: README and architecture docs prohibit production shared provider keys in clients.

#### Acceptance Criteria

```gherkin
Given the current MVP runtime
When cloud sync, OpenAI, BYOK, edge, Firebase, or social sync is inspected
Then no active runtime path depends on those systems

Given a future cloud or social sync feature is proposed
When implementation begins
Then the design includes auth, privacy, consent, conflict handling, export/delete behavior, and tests

Given a future provider credential is required
When productizing the provider
Then shared production secrets are not shipped in client artifacts
```

#### Dependencies

* `HYD-US-031`
* `HYD-US-041`
* `HYD-US-051`

#### Out of Scope

* Implementing cloud sync, accounts, social backend, OpenAI, BYOK, or edge LLM in the current MVP.

#### Repository Evidence

* `config/open_ai_config.yaml`
* `config/firebase_config.json`
* `packs/byok_llm/`
* `packs/edge_llm/`
* `packs/gemini_connector/`
* `docs/architecture/STALE_SCAFFOLD_AUDIT.md`
* `docs/architecture/PROVIDER_SECURITY.md`

### HYD-US-039: Manage Coach Prompt Templates Safely

**Epic:** Local Hydration Coach  
**Status:** Partial  
**Priority:** P2  
**Release Scope:** Supporting

**As a** coach-content maintainer  
**I need** prompt templates and active provider prompts to be managed without confusing dormant scaffolds for runtime behavior  
**So that** provider guidance stays auditable and safe.

#### Details and Assumptions

* Confirmed: `LLMPromptBuilder` can load `config/prompt_templates.yaml`.
* Confirmed: architecture audit classifies `config/prompt_templates.yaml` as dormant because active Gemini/local coach does not use it.
* Confirmed: Gemini adapter builds its active prompt inline from typed `HydrationContext` and action rules.
* Inferred: future prompt-template work should preserve typed action schema and capability safety.

#### Acceptance Criteria

```gherkin
Given prompt templates are loaded through `LLMPromptBuilder`
When a known template key is requested
Then variables are interpolated and empty or missing templates throw a prompt builder error

Given the active Gemini provider runs today
When it builds a prompt
Then it uses typed context and action-contract instructions, not dormant template config

Given a future prompt pipeline is enabled
When templates affect provider output
Then tests verify schema, capability safety, localization, and no clinical claims
```

#### Dependencies

* `HYD-US-023`
* `HYD-US-031`
* `HYD-US-032`

#### Out of Scope

* Activating OpenAI prompts, remote prompt management, or untyped provider prompts.

#### Repository Evidence

* `lib/utils/llm_prompt_builder.dart`
* `config/prompt_templates.yaml`
* `lib/adapters/gemini/gemini_adapter.dart`
* `docs/architecture/STALE_SCAFFOLD_AUDIT.md`

### HYD-US-040: Keep Stale and Future Scaffolds Truthful

**Epic:** Maintenance and Quality Requirements  
**Status:** Partial  
**Priority:** P1  
**Release Scope:** Supporting

**As a** contributor  
**I need** stale configs, scripts, and blueprints to be labeled separately from active runtime behavior  
**So that** Hydrion's MVP scope stays honest and maintainable.

#### Details and Assumptions

* Confirmed: `docs/architecture/STALE_SCAFFOLD_AUDIT.md` classifies active, dormant, future, stale, and experimental folders.
* Confirmed: `config/app.yaml` claims BLE, voice, and wearable sync enabled, contradicting runtime capabilities.
* Confirmed: `scripts/test_all.sh` references old `app/`, KMP/Gradle, and integration paths.
* Confirmed: `overview`, `hydrion.txt`, and `p1.txt` describe a broader future/historical architecture not fully present in the repo.

#### Acceptance Criteria

```gherkin
Given a contributor reads configs or scripts
When those files describe future or stale features
Then documentation marks them as non-runtime truth before release

Given runtime capability state conflicts with a dormant config
When Hydrion renders user-facing status
Then capability reporter and Settings are treated as runtime truth

Given a future scaffold becomes active
When it is wired into runtime
Then implementation, tests, docs, and capability status are updated together
```

#### Dependencies

* `HYD-US-028`
* `HYD-US-031`
* `HYD-US-050`

#### Out of Scope

* Deleting future work solely because it is inactive.

#### Repository Evidence

* `docs/architecture/STALE_SCAFFOLD_AUDIT.md`
* `config/app.yaml`
* `scripts/test_all.sh`
* `overview`
* `hydrion.txt`
* `p1.txt`

## 5. Non-Functional User Stories

### HYD-US-041: Preserve Local-First Privacy Baseline

**Epic:** Privacy and Local-First Operation  
**Status:** Implemented  
**Priority:** P0  
**Release Scope:** MVP

**As a** privacy-conscious user  
**I need** Hydrion to work locally by default  
**So that** my hydration history remains on the device unless I explicitly configure a non-local provider.

#### Details and Assumptions

* Confirmed: local_rules is default and requires no network.
* Confirmed: Settings privacy copy says local_rules keeps hydration context on device.
* Confirmed: optional Gemini is local-development only and requires explicit configuration.
* Limitation: local data is persisted in shared preferences without encryption.

#### Acceptance Criteria

```gherkin
Given no non-local provider is configured
When the user logs, reviews, analyzes, and asks the coach
Then Hydrion uses local repositories and local_rules without provider network dependency

Given Gemini is configured
When Settings displays provider privacy
Then Hydrion discloses that typed hydration context may leave the device

Given production provider work is proposed
When requirements are reviewed
Then explicit consent and a provider disable path are required before release
```

#### Dependencies

* `HYD-US-001`
* `HYD-US-031`
* `HYD-US-032`

#### Out of Scope

* Full privacy policy text, encrypted local storage, export/delete controls, or legal compliance certification.

#### Repository Evidence

* `README.md`
* `lib/ui/screens/settings_screen.dart`
* `lib/services/ai_provider_config.dart`
* `docs/architecture/PROVIDER_SECURITY.md`
* `test/product_qa_test.dart`

### HYD-US-042: Protect, Export, and Delete Local Personal Data

**Epic:** Privacy and Local-First Operation  
**Status:** Partial  
**Priority:** P0  
**Release Scope:** MVP

**As a** privacy-conscious returning user  
**I need** clear protection, export, and deletion controls for local hydration data  
**So that** I can manage personal wellness data responsibly.

#### Details and Assumptions

* Confirmed: hydration logs, settings, reminders, and challenge state persist locally.
* Confirmed: repositories expose clear methods in code, but no complete user-facing data export/delete settings workflow exists.
* Confirmed: local storage is shared preferences, not SQLCipher or OS-vault-backed encryption.
* Confirmed: roadmap flags local data protection as a release decision.

#### Acceptance Criteria

```gherkin
Given local hydration data exists
When the user requests export in a future privacy workflow
Then Hydrion produces a documented local export without sending data to a backend

Given the user requests deletion in a future privacy workflow
When deletion completes
Then hydration logs, reminders, settings, and challenge state are removed or reset according to documented policy

Given current MVP lacks encryption/export/delete UI
When release readiness is assessed
Then the gap is explicitly accepted or implemented before beta
```

#### Dependencies

* `HYD-US-004`
* `HYD-US-015`
* `HYD-US-018`
* `HYD-US-027`

#### Out of Scope

* Cloud account deletion or synced-data conflict resolution.

#### Repository Evidence

* `lib/storage/local_store.dart`
* `lib/repositories/hydration_repository.dart`
* `lib/repositories/reminder_repository.dart`
* `lib/repositories/challenge_repository.dart`
* `HYDRION_MVP_KANBAN_ROADMAP.md`
* `docs/architecture/PROVIDER_SECURITY.md`

### HYD-US-043: Recover Gracefully From Invalid Stored Data

**Epic:** Data Persistence and Recovery  
**Status:** Implemented  
**Priority:** P0  
**Release Scope:** Supporting

**As a** returning user  
**I need** Hydrion to handle corrupt or invalid local data without crashing  
**So that** a bad stored payload does not block app access.

#### Details and Assumptions

* Confirmed: repositories catch malformed JSON and return default/empty state.
* Confirmed: hydration log decode drops invalid entries.
* Confirmed: settings fallback to English.
* Limitation: invalid records are silently ignored rather than quarantined or reported.

#### Acceptance Criteria

```gherkin
Given malformed hydration JSON is stored
When Hydrion loads logs
Then it returns an empty log list without throwing

Given a reminder entry is missing trigger time, message, or numeric priority
When reminders load
Then the invalid reminder is skipped

Given settings JSON is missing or malformed
When settings load
Then Hydrion uses English defaults
```

#### Dependencies

* `HYD-US-004`
* `HYD-US-027`

#### Out of Scope

* Versioned migrations, user-visible quarantine reports, or repair UI.

#### Repository Evidence

* `lib/repositories/hydration_repository.dart`
* `lib/repositories/reminder_repository.dart`
* `lib/repositories/challenge_repository.dart`
* `lib/repositories/settings_repository.dart`
* `test/persistence_test.dart`

### HYD-US-044: Provide Reliable Error Handling and Fallback UX

**Epic:** Error Handling and Reliability  
**Status:** Implemented  
**Priority:** P1  
**Release Scope:** Supporting

**As an** application user  
**I need** Hydrion to fail gracefully across local and optional-provider flows  
**So that** errors do not corrupt data or leave me without usable guidance.

#### Details and Assumptions

* Confirmed: advice card has loading, error, and retry states.
* Confirmed: chat catches coach errors and shows a localized error snack bar.
* Confirmed: provider failures fall back to local_rules with safe diagnostics.
* Confirmed: repository edit/delete failures show "log not found" feedback.

#### Acceptance Criteria

```gherkin
Given a coach advice request fails
When the advice card renders
Then the user sees a retryable localized error state

Given an optional provider times out or returns invalid output
When the coach handles the request
Then local_rules fallback remains available

Given an edit or delete target is missing
When the operation completes
Then Hydrion shows localized not-found feedback without crashing
```

#### Dependencies

* `HYD-US-006`
* `HYD-US-007`
* `HYD-US-021`
* `HYD-US-032`

#### Out of Scope

* Crash reporting, telemetry, or remote incident monitoring.

#### Repository Evidence

* `lib/ui/components/llm_advice_card.dart`
* `lib/ui/screens/chat_coach_screen.dart`
* `lib/services/hydration_ai_orchestrator.dart`
* `lib/ui/screens/log_screen.dart`
* `test/gemini_provider_test.dart`

### HYD-US-045: Support Accessibility Semantics

**Epic:** Accessibility and Responsive Design  
**Status:** Partial  
**Priority:** P1  
**Release Scope:** Supporting

**As an** accessibility-focused user  
**I need** meaningful labels, tooltips, semantics, and clear states  
**So that** Hydrion is usable with assistive technology.

#### Details and Assumptions

* Confirmed: Hydrion logo, progress ring, hydration score, achievement badges, and disabled voice button include semantics.
* Confirmed: important icon buttons include tooltips.
* Confirmed: disabled/future capabilities are labeled in UI text.
* Limitation: no complete accessibility audit, keyboard traversal test, contrast audit, or screen-reader test suite is present.

#### Acceptance Criteria

```gherkin
Given the progress ring renders
When assistive technology queries it
Then it exposes progress label, percent value, and consumed/target hint

Given an achievement badge renders
When assistive technology queries it
Then it exposes badge name and locked/unlocked status

Given release accessibility validation runs in the future
When core screens are audited
Then navigation, focus order, labels, contrast, and text scaling issues are documented or fixed
```

#### Dependencies

* `HYD-US-008`
* `HYD-US-011`
* `HYD-US-013`
* `HYD-US-026`

#### Out of Scope

* WCAG certification or full platform accessibility certification.

#### Repository Evidence

* `lib/ui/components/intake_ring.dart`
* `lib/ui/components/hydration_score_card.dart`
* `lib/ui/components/achievement_badge.dart`
* `lib/ui/components/voice_input_widget.dart`
* `lib/ui/screens/home_screen.dart`

### HYD-US-046: Keep Core Screens Usable on Small Viewports

**Epic:** Accessibility and Responsive Design  
**Status:** Partial  
**Priority:** P1  
**Release Scope:** Supporting

**As a** mobile or narrow-screen user  
**I need** core Hydrion controls to remain usable on small screens  
**So that** logging and navigation do not depend on desktop layout.

#### Details and Assumptions

* Confirmed: Home stacks the amount picker and log button under narrow width.
* Confirmed: tests verify Home usability at a 360x640 viewport.
* Confirmed: screens use scrollable layouts.
* Limitation: not every screen has visual regression or small-viewport coverage.

#### Acceptance Criteria

```gherkin
Given a 360x640 viewport
When the Home screen renders
Then logo, volume picker, log button, and progress remain reachable

Given controls do not fit horizontally
When Home measures narrow constraints
Then the picker and log button stack vertically

Given future responsive validation runs
When all core screens are tested
Then overflow and inaccessible controls are fixed before release
```

#### Dependencies

* `HYD-US-002`
* `HYD-US-003`

#### Out of Scope

* Full visual regression infrastructure or tablet-specific layouts.

#### Repository Evidence

* `lib/ui/screens/home_screen.dart`
* `test/product_qa_test.dart`

### HYD-US-047: Maintain Localization Quality Gates

**Epic:** Localization  
**Status:** Partial  
**Priority:** P1  
**Release Scope:** Supporting

**As a** contributor  
**I need** localization quality checks to catch missing or stale strings  
**So that** supported locales do not regress as features change.

#### Details and Assumptions

* Confirmed: active ARB files exist for EN/ES/FR and tests cover many visible strings.
* Confirmed: CI does not explicitly run `flutter gen-l10n` or ARB parity checks in the workflow.
* Confirmed: roadmap identifies generated localization drift and ARB parity checks as needed.

#### Acceptance Criteria

```gherkin
Given a new localized key is added
When localization quality checks run
Then missing EN/ES/FR keys fail before release

Given generated localization files drift from ARB inputs
When CI runs
Then the drift is detected

Given future locales are not fully translated
When user-facing locale lists render
Then future locales are not presented as active
```

#### Dependencies

* `HYD-US-029`
* `HYD-US-030`
* `HYD-US-050`

#### Out of Scope

* Professional translation review or runtime language downloads.

#### Repository Evidence

* `l10n.yaml`
* `lib/l10n/app_en.arb`
* `lib/l10n/app_es.arb`
* `lib/l10n/app_fr.arb`
* `test/localization_test.dart`
* `.github/workflows/flutter-ci.yml`
* `HYDRION_MVP_KANBAN_ROADMAP.md`

### HYD-US-048: Preserve Local Performance and Responsiveness

**Epic:** Error Handling and Reliability  
**Status:** Partial  
**Priority:** P2  
**Release Scope:** Supporting

**As an** application user  
**I need** local logging, summaries, and coach fallback to respond quickly  
**So that** Hydrion feels dependable during repeated daily use.

#### Details and Assumptions

* Confirmed: current repositories are in-memory lists persisted to shared preferences.
* Confirmed: local summary, analytics, and coach calculations run locally over repository data.
* Confirmed: provider calls have timeouts and fallback.
* Limitation: no explicit performance budgets, benchmark tests, or large-history scalability tests are present.

#### Acceptance Criteria

```gherkin
Given local_rules mode and normal local history size
When the user logs water
Then the UI updates without waiting for provider or network calls

Given Gemini is configured but slow
When the provider exceeds timeout
Then Hydrion falls back to local_rules within the configured timeout window

Given large-history performance work is planned
When acceptance criteria are defined
Then measurable latency budgets and regression tests are added
```

#### Dependencies

* `HYD-US-003`
* `HYD-US-010`
* `HYD-US-032`

#### Out of Scope

* Database indexing, Rust core optimization, or advanced profiling in the current MVP.

#### Repository Evidence

* `lib/repositories/hydration_repository.dart`
* `lib/adapters/local/local_hydrion_adapters.dart`
* `lib/services/hydration_ai_orchestrator.dart`
* `test/gemini_provider_test.dart`

### HYD-US-049: Maintain Adapter Boundary and Testability

**Epic:** Maintenance and Quality Requirements  
**Status:** Implemented  
**Priority:** P0  
**Release Scope:** Supporting

**As a** maintainer  
**I need** UI, providers, repositories, and future integrations separated by contracts  
**So that** Hydrion can evolve without coupling screens to provider SDKs or mutable state layers.

#### Details and Assumptions

* Confirmed: UI depends on domain contracts and repositories, not provider SDKs.
* Confirmed: architecture tests forbid UI imports of adapters, provider SDKs, raw AI action types, validators, and executor internals.
* Confirmed: provider adapter shells cannot import mutable app state layers.
* Confirmed: app shell can swap fake domain adapters in widget tests.

#### Acceptance Criteria

```gherkin
Given UI files are inspected
When architecture tests run
Then UI does not import forbidden adapters, packs, SDKs, or deprecated wrappers

Given provider adapter files are inspected
When architecture tests run
Then provider shells do not import repositories or storage directly

Given fake domain adapters are supplied
When the app shell renders
Then UI works through contracts without provider-specific changes
```

#### Dependencies

* `HYD-US-023`
* `HYD-US-031`
* `HYD-US-034`

#### Out of Scope

* Refactoring `HydrionServices` composition into smaller builders, which is tracked as tech debt.

#### Repository Evidence

* `docs/architecture/ADAPTER_BOUNDARY.md`
* `test/boundary_architecture_test.dart`
* `test/adapter_contract_test.dart`
* `lib/domain/hydration_contracts.dart`
* `lib/main.dart`

### HYD-US-050: Keep CI and Build Quality Gates Stable

**Epic:** Maintenance and Quality Requirements  
**Status:** Implemented  
**Priority:** P0  
**Release Scope:** Supporting

**As a** maintainer  
**I need** CI to validate core Flutter quality and release build artifacts  
**So that** MVP changes stay shippable for web and Android.

#### Details and Assumptions

* Confirmed: GitHub workflow runs root validation, `flutter pub get`, secret scan, dependency graph, analyze, tests with coverage, web build, and Android APK build.
* Confirmed: artifacts are uploaded for coverage, web build, and Android APK.
* Limitation: no coverage threshold, generated localization drift check, or complete release smoke checklist is enforced.

#### Acceptance Criteria

```gherkin
Given code changes are pushed or opened as a PR to main/develop
When CI runs
Then quality-gate, web build, and Android build jobs run from repository root

Given tests run in CI
When the test step completes
Then coverage output is uploaded as an artifact

Given release-readiness gaps remain
When CI is expanded
Then coverage thresholds, localization drift checks, and smoke validation are added
```

#### Dependencies

* `HYD-US-036`
* `HYD-US-037`
* `HYD-US-047`
* `HYD-US-051`

#### Out of Scope

* iOS, desktop, cloud, Rust workspace, or model-training CI as active MVP gates.

#### Repository Evidence

* `.github/workflows/flutter-ci.yml`
* `README.md`
* `scripts/build_release.sh`
* `docs/architecture/STALE_SCAFFOLD_AUDIT.md`

### HYD-US-051: Prevent Secret Leakage and Unsafe Provider Credentials

**Epic:** Maintenance and Quality Requirements  
**Status:** Implemented  
**Priority:** P0  
**Release Scope:** Supporting

**As a** security-conscious maintainer  
**I need** committed secrets and provider credentials to be detected or avoided  
**So that** Hydrion does not leak API keys, private keys, or production provider secrets.

#### Details and Assumptions

* Confirmed: `.gitignore` excludes `.env`, `.env.*`, `*.secrets.json`, `secrets/`, and secret reports.
* Confirmed: `tool/secret_scan.dart` scans for common Google/OpenAI/Anthropic API keys and private key blocks.
* Confirmed: tests assert no committed keys/private key blocks and placeholder keys are not treated as real secrets.
* Confirmed: docs prohibit shipping shared production Gemini keys in clients.

#### Acceptance Criteria

```gherkin
Given a real API key or private key block is committed in a scanned file
When `dart run tool/secret_scan.dart` runs
Then the scan fails and reports the file and secret type

Given placeholder API key text is present
When secret hygiene tests run
Then placeholders are not treated as real secrets

Given a production non-local provider is proposed
When credentials are designed
Then shared production keys are kept out of web/mobile/desktop client artifacts
```

#### Dependencies

* `HYD-US-032`
* `HYD-US-033`
* `HYD-US-038`
* `HYD-US-050`

#### Out of Scope

* Full enterprise secret management, key rotation automation, or external security audit.

#### Repository Evidence

* `tool/secret_scan.dart`
* `test/secret_hygiene_test.dart`
* `.gitignore`
* `.github/workflows/flutter-ci.yml`
* `docs/architecture/PROVIDER_SECURITY.md`

## 6. Story Dependency Map

| Story ID | Story Title | Depends On | Blocks | Release Scope |
| -------- | ----------- | ---------- | ------ | ------------- |
| HYD-US-001 | Launch Standalone Local Application | None | HYD-US-002, HYD-US-036, HYD-US-037, HYD-US-041 | MVP |
| HYD-US-002 | Access Core Product Screens | HYD-US-001, HYD-US-031 | HYD-US-005, HYD-US-010, HYD-US-016, HYD-US-018, HYD-US-022, HYD-US-028 | MVP |
| HYD-US-003 | Log Hydration Manually | HYD-US-004 | HYD-US-008, HYD-US-010, HYD-US-011, HYD-US-014 | MVP |
| HYD-US-004 | Persist Hydration Logs Locally | None | HYD-US-003, HYD-US-005, HYD-US-006, HYD-US-007, HYD-US-008, HYD-US-010, HYD-US-019, HYD-US-042, HYD-US-043 | MVP |
| HYD-US-005 | View Recent Hydration History | HYD-US-003, HYD-US-004 | HYD-US-006, HYD-US-007 | MVP |
| HYD-US-006 | Edit Hydration Records | HYD-US-004, HYD-US-005 | HYD-US-044 | MVP |
| HYD-US-007 | Delete Hydration Records | HYD-US-004, HYD-US-005 | HYD-US-044 | MVP |
| HYD-US-008 | View Daily Summary and Progress Ring | HYD-US-003, HYD-US-004 | HYD-US-009, HYD-US-010, HYD-US-011, HYD-US-021, HYD-US-045 | MVP |
| HYD-US-009 | Configure Hydration Goals and Units | HYD-US-008, HYD-US-027, HYD-US-042 | None | MVP |
| HYD-US-010 | View Analytics Empty State and Daily Totals | HYD-US-004, HYD-US-008 | HYD-US-011, HYD-US-012, HYD-US-013, HYD-US-014 | MVP |
| HYD-US-011 | Calculate Hydration Score | HYD-US-008, HYD-US-010 | HYD-US-045 | MVP |
| HYD-US-012 | Track Daily Goal Streaks | HYD-US-004, HYD-US-013 | HYD-US-013 | Supporting |
| HYD-US-013 | Display Local Achievement Badges | HYD-US-004, HYD-US-012 | HYD-US-045 | Supporting |
| HYD-US-014 | Estimate Eco Impact From Local Logs | HYD-US-004, HYD-US-010 | None | Supporting |
| HYD-US-015 | Save Local Reminder Definitions | HYD-US-017 | HYD-US-016, HYD-US-023, HYD-US-024, HYD-US-042 | MVP |
| HYD-US-016 | Manage Saved Reminder Definitions | HYD-US-015 | HYD-US-023 | MVP |
| HYD-US-017 | Gate OS Notification Scheduling | HYD-US-015, HYD-US-031 | HYD-US-015, HYD-US-024 | Supporting |
| HYD-US-018 | Join a Local Hydration Challenge | HYD-US-031 | HYD-US-019, HYD-US-020, HYD-US-023, HYD-US-024, HYD-US-042 | MVP |
| HYD-US-019 | Track Local Challenge Progress | HYD-US-004, HYD-US-018 | HYD-US-020 | MVP |
| HYD-US-020 | Leave Challenges and Keep Completion History | HYD-US-018, HYD-US-019 | None | Supporting |
| HYD-US-021 | Show Local Hydration Advice on Home | HYD-US-008, HYD-US-029 | HYD-US-044 | MVP |
| HYD-US-022 | Chat With Local Hydration Coach | HYD-US-023, HYD-US-031 | HYD-US-024, HYD-US-032, HYD-US-044 | MVP |
| HYD-US-023 | Build Typed Hydration Context | HYD-US-004, HYD-US-015, HYD-US-018, HYD-US-031 | HYD-US-022, HYD-US-024, HYD-US-032, HYD-US-039, HYD-US-049 | Supporting |
| HYD-US-024 | Confirm Coach Suggestions Before State Changes | HYD-US-022, HYD-US-031 | None | Supporting |
| HYD-US-025 | Parse Hydration Commands for Typed or Future Voice Use | HYD-US-026, HYD-US-031 | HYD-US-026 | Supporting |
| HYD-US-026 | Gate Voice Capture Until a Real Adapter Exists | HYD-US-025, HYD-US-031 | None | Post-MVP |
| HYD-US-027 | Persist Language Settings | HYD-US-029, HYD-US-004 | HYD-US-009, HYD-US-030 | MVP |
| HYD-US-028 | Show Runtime Capability and Permission Status | HYD-US-031, HYD-US-033 | HYD-US-035, HYD-US-040 | Supporting |
| HYD-US-029 | Render English, Spanish, and French App Strings | HYD-US-027 | HYD-US-021, HYD-US-027, HYD-US-030, HYD-US-047 | MVP |
| HYD-US-030 | Handle Future and Unsupported Locales Safely | HYD-US-027, HYD-US-029 | None | Supporting |
| HYD-US-031 | Enforce Capability Gating and Safe Action Validation | HYD-US-023, HYD-US-024 | HYD-US-002, HYD-US-017, HYD-US-018, HYD-US-022, HYD-US-024, HYD-US-032, HYD-US-034, HYD-US-035, HYD-US-041, HYD-US-049 | Supporting |
| HYD-US-032 | Use Optional Gemini Provider With Local Fallback | HYD-US-023, HYD-US-031, HYD-US-033, HYD-US-051 | None | Supporting |
| HYD-US-033 | Display Safe Provider Health Diagnostics | HYD-US-032, HYD-US-051 | HYD-US-028, HYD-US-032 | Supporting |
| HYD-US-034 | Keep ELKA as an Optional Adapter Boundary | HYD-US-031, HYD-US-049, HYD-US-051 | None | Post-MVP |
| HYD-US-035 | Add Native BLE, Health, and AR Integrations Later | HYD-US-028, HYD-US-031 | None | Post-MVP |
| HYD-US-036 | Run as a Web App With PWA Metadata | HYD-US-001, HYD-US-050 | None | MVP |
| HYD-US-037 | Build Android APK | HYD-US-001, HYD-US-050 | None | MVP |
| HYD-US-038 | Design Cloud, Social, BYOK, OpenAI, and Edge Integrations | HYD-US-031, HYD-US-041, HYD-US-051 | None | Post-MVP |
| HYD-US-039 | Manage Coach Prompt Templates Safely | HYD-US-023, HYD-US-031, HYD-US-032 | None | Supporting |
| HYD-US-040 | Keep Stale and Future Scaffolds Truthful | HYD-US-028, HYD-US-031, HYD-US-050 | None | Supporting |
| HYD-US-041 | Preserve Local-First Privacy Baseline | HYD-US-001, HYD-US-031, HYD-US-032 | HYD-US-038 | MVP |
| HYD-US-042 | Protect, Export, and Delete Local Personal Data | HYD-US-004, HYD-US-015, HYD-US-018, HYD-US-027 | HYD-US-009 | MVP |
| HYD-US-043 | Recover Gracefully From Invalid Stored Data | HYD-US-004, HYD-US-027 | None | Supporting |
| HYD-US-044 | Provide Reliable Error Handling and Fallback UX | HYD-US-006, HYD-US-007, HYD-US-021, HYD-US-032 | None | Supporting |
| HYD-US-045 | Support Accessibility Semantics | HYD-US-008, HYD-US-011, HYD-US-013, HYD-US-026 | None | Supporting |
| HYD-US-046 | Keep Core Screens Usable on Small Viewports | HYD-US-002, HYD-US-003 | None | Supporting |
| HYD-US-047 | Maintain Localization Quality Gates | HYD-US-029, HYD-US-030, HYD-US-050 | None | Supporting |
| HYD-US-048 | Preserve Local Performance and Responsiveness | HYD-US-003, HYD-US-010, HYD-US-032 | None | Supporting |
| HYD-US-049 | Maintain Adapter Boundary and Testability | HYD-US-023, HYD-US-031, HYD-US-034 | HYD-US-034, HYD-US-038 | Supporting |
| HYD-US-050 | Keep CI and Build Quality Gates Stable | HYD-US-036, HYD-US-037, HYD-US-047, HYD-US-051 | HYD-US-036, HYD-US-037, HYD-US-040 | Supporting |
| HYD-US-051 | Prevent Secret Leakage and Unsafe Provider Credentials | HYD-US-032, HYD-US-033, HYD-US-038, HYD-US-050 | HYD-US-032, HYD-US-034, HYD-US-038 | Supporting |

## 7. MVP Delivery Order

1. Application and persistence foundation
   * HYD-US-001, HYD-US-002, HYD-US-004, HYD-US-041, HYD-US-043, HYD-US-050, HYD-US-051
2. Core hydration logging
   * HYD-US-003, HYD-US-008
3. History and record management
   * HYD-US-005, HYD-US-006, HYD-US-007, HYD-US-044
4. Goals and daily summaries
   * HYD-US-009, HYD-US-010, HYD-US-011
5. Analytics and scoring
   * HYD-US-012, HYD-US-013, HYD-US-014
6. Engagement capabilities
   * HYD-US-015, HYD-US-016, HYD-US-017, HYD-US-018, HYD-US-019, HYD-US-020
7. Coach and capability gating
   * HYD-US-021, HYD-US-022, HYD-US-023, HYD-US-024, HYD-US-025, HYD-US-031, HYD-US-032, HYD-US-033, HYD-US-039
8. Accessibility, localization, reliability, and release validation
   * HYD-US-027, HYD-US-028, HYD-US-029, HYD-US-030, HYD-US-036, HYD-US-037, HYD-US-040, HYD-US-042, HYD-US-045, HYD-US-046, HYD-US-047, HYD-US-048, HYD-US-049
9. Post-MVP integration design and activation
   * HYD-US-026, HYD-US-034, HYD-US-035, HYD-US-038

## 8. Traceability Matrix

| Capability | Story IDs | Implementation Status | Repository Evidence |
| ---------- | --------- | --------------------- | ------------------- |
| Standalone local launch | HYD-US-001, HYD-US-041 | Implemented | `lib/main.dart`; `README.md`; `test/widget_test.dart` |
| Core screen navigation | HYD-US-002 | Implemented | `lib/main.dart`; `lib/ui/screens/home_screen.dart` |
| Manual hydration logging | HYD-US-003 | Implemented | `lib/ui/screens/home_screen.dart`; `lib/repositories/hydration_repository.dart`; `test/runtime_ux_test.dart` |
| Persisted hydration history | HYD-US-004, HYD-US-043 | Implemented | `lib/storage/local_store.dart`; `lib/repositories/hydration_repository.dart`; `test/persistence_test.dart` |
| Hydration history display | HYD-US-005 | Implemented | `lib/ui/screens/log_screen.dart` |
| Editing hydration records | HYD-US-006 | Implemented | `lib/ui/screens/log_screen.dart`; `test/runtime_ux_test.dart` |
| Deleting hydration records | HYD-US-007 | Implemented | `lib/ui/screens/log_screen.dart`; `test/runtime_ux_test.dart` |
| Daily hydration summaries | HYD-US-008 | Implemented | `lib/adapters/local/local_hydrion_adapters.dart`; `lib/ui/components/intake_ring.dart` |
| Hydration goals | HYD-US-009 | Planned | `lib/adapters/local/local_hydrion_adapters.dart`; `HYDRION_MVP_KANBAN_ROADMAP.md` |
| Analytics | HYD-US-010 | Implemented | `lib/ui/screens/analytics_screen.dart`; `test/product_qa_test.dart` |
| Hydration score | HYD-US-011 | Implemented | `lib/ui/components/hydration_score_card.dart` |
| Streak tracking | HYD-US-012 | Implemented | `lib/ui/screens/analytics_screen.dart` |
| Achievements | HYD-US-013 | Implemented | `lib/ui/components/achievement_badge.dart`; `lib/ui/screens/analytics_screen.dart` |
| Eco-impact tracking | HYD-US-014 | Implemented | `lib/services/eco_tracker.dart`; `lib/services/core_bridge.dart` |
| Local reminder creation | HYD-US-015 | Implemented | `lib/services/notifications.dart`; `lib/ui/components/reminder_tile.dart` |
| Reminder management | HYD-US-016 | Implemented | `lib/ui/screens/reminders_screen.dart`; `lib/repositories/reminder_repository.dart` |
| OS notification boundary | HYD-US-017 | Gated | `lib/services/notifications.dart`; `lib/domain/hydration_contracts.dart` |
| Hydration challenges | HYD-US-018, HYD-US-019, HYD-US-020 | Implemented/Partial | `lib/repositories/challenge_repository.dart`; `lib/ui/screens/social_challenges_screen.dart` |
| Local home coach | HYD-US-021 | Implemented | `lib/ui/components/llm_advice_card.dart`; `lib/adapters/local/local_hydrion_adapters.dart` |
| Chat coach | HYD-US-022 | Implemented | `lib/ui/screens/chat_coach_screen.dart`; `test/product_qa_test.dart` |
| Hydration context | HYD-US-023 | Implemented | `lib/services/hydration_context_builder.dart`; `docs/architecture/AI_ACTION_CONTRACT.md` |
| Coach suggestion cards | HYD-US-024 | Implemented | `lib/services/coach_suggestion_service.dart`; `test/coach_suggestion_cards_test.dart` |
| Command parsing | HYD-US-025 | Partial | `lib/adapters/local/local_hydrion_adapters.dart`; `lib/services/voice_llm_bridge.dart` |
| Voice capture | HYD-US-026 | Gated/Post-MVP | `lib/services/voice_client.dart`; `lib/ui/components/voice_input_widget.dart` |
| Language settings | HYD-US-027 | Implemented | `lib/ui/screens/settings_screen.dart`; `lib/utils/i18n_resolver.dart` |
| Capability dashboard | HYD-US-028 | Implemented | `lib/ui/screens/settings_screen.dart` |
| EN/ES/FR localization | HYD-US-029 | Implemented | `lib/l10n/*.arb`; `test/localization_test.dart` |
| Future locale fallback | HYD-US-030 | Partial | `lib/utils/i18n_resolver.dart` |
| Capability gating and validation | HYD-US-031 | Implemented | `lib/domain/hydration_contracts.dart`; `test/ai_action_contract_test.dart` |
| Gemini provider | HYD-US-032, HYD-US-033 | Gated/Implemented diagnostics | `lib/adapters/gemini/gemini_adapter.dart`; `test/gemini_provider_test.dart` |
| ELKA boundary | HYD-US-034 | Post-MVP | `lib/adapters/elka/elka_adapter.dart`; `docs/architecture/ADAPTER_BOUNDARY.md` |
| BLE, Health, AR integrations | HYD-US-035 | Post-MVP | `lib/services/ble_service.dart`; `lib/services/wearable_service.dart`; `lib/ui/screens/ar_visualization_screen.dart` |
| Web/PWA | HYD-US-036 | Partial | `web/manifest.json`; `web/index.html`; `.github/workflows/flutter-ci.yml` |
| Android | HYD-US-037 | Implemented build support | `android/app/build.gradle.kts`; `.github/workflows/flutter-ci.yml` |
| Cloud/social/BYOK/OpenAI/edge | HYD-US-038 | Post-MVP | `config/open_ai_config.yaml`; `config/firebase_config.json`; `packs/` |
| Prompt templates | HYD-US-039 | Partial/dormant | `lib/utils/llm_prompt_builder.dart`; `config/prompt_templates.yaml`; `lib/adapters/gemini/gemini_adapter.dart` |
| Stale scaffold classification | HYD-US-040 | Partial | `docs/architecture/STALE_SCAFFOLD_AUDIT.md`; `config/app.yaml`; `scripts/test_all.sh` |
| Local data protection/export/delete | HYD-US-042 | Partial | `lib/storage/local_store.dart`; `HYDRION_MVP_KANBAN_ROADMAP.md` |
| Error handling | HYD-US-044 | Implemented | `lib/ui/components/llm_advice_card.dart`; `lib/services/hydration_ai_orchestrator.dart` |
| Accessibility | HYD-US-045 | Partial | `lib/ui/components/intake_ring.dart`; `lib/ui/components/achievement_badge.dart` |
| Responsive behavior | HYD-US-046 | Partial | `lib/ui/screens/home_screen.dart`; `test/product_qa_test.dart` |
| Localization quality gates | HYD-US-047 | Partial | `l10n.yaml`; `.github/workflows/flutter-ci.yml`; `HYDRION_MVP_KANBAN_ROADMAP.md` |
| Performance and responsiveness | HYD-US-048 | Partial | `lib/repositories/hydration_repository.dart`; `lib/services/hydration_ai_orchestrator.dart` |
| Adapter boundary/testability | HYD-US-049 | Implemented | `test/boundary_architecture_test.dart`; `docs/architecture/ADAPTER_BOUNDARY.md` |
| CI quality gates | HYD-US-050 | Implemented | `.github/workflows/flutter-ci.yml`; `README.md` |
| Secret hygiene | HYD-US-051 | Implemented | `tool/secret_scan.dart`; `test/secret_hygiene_test.dart`; `docs/architecture/PROVIDER_SECURITY.md` |
