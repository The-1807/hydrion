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
**Story Type:** User Story  
**Implementation Status:** Implemented  
**Priority:** P0  
**Release Scope:** MVP
**Labels:** `user-story`, `type:user-story`, `priority:p0`, `status:implemented`, `scope:mvp`, `area:onboarding`, `area:frontend`, `area:local-first`, `size:2`  
**Milestone:** MVP Stabilization
**Story Size:** 2
**Project Column:** Product Backlog  
**Business Rank:** 009

#### User Story

**As a** first-time application user
**I need** Hydrion to open without account, network, provider, or native-service setup
**So that** I can start tracking hydration immediately in standalone local mode.

#### Description

* Hydrion launches straight into local mode so a new user can begin logging water without creating an account, configuring a provider, or granting native-service permissions.
* The app boot path must remain backed by local services and deterministic fallback behavior; provider setup is optional and must never block the home screen.

#### Details and Business Rules

* `main()` initializes `HydrionServices.local()` and runs `HydrionApp`.
* `HydrionServices.memory()` supports tests and local-only operation without external services.
* default AI provider is `local_rules`, and optional Gemini is not required for boot.
* Business rule: `HydrionServices.local()` remains the production boot path, and startup cannot depend on network, account, Gemini, ELKA, BLE, Health, AR, or notification adapters.
#### Data and State Requirements

* Provider-facing state must avoid persisted production secrets and must preserve local fallback behavior.
* Integration state must be represented through capability status, adapter contracts, or disabled placeholders until a real adapter is implemented.

#### Assumptions

* "Onboarding" currently means direct app access; no guided onboarding wizard is implemented.

#### Acceptance Criteria

- [x] The Home screen renders with Hydrion branding and local logging controls.
- [x] Local repositories, local coach, capability reporter, and local fallback remain available.

#### Acceptance Criteria Coverage

* Checked acceptance criteria: 2.
* Unchecked acceptance criteria: 0.
* Checked criteria are tied to the repository evidence listed in this story.
* Unchecked criteria represent work or verification still needed before the criterion can be claimed complete.

#### Dependencies

* `HydrionServices`
* `HydrionApp`
* `HYD-US-031`

#### Non-Functional Requirements

* Keep the behavior offline-tolerant and honest about local-first limits.
* Keep user-visible behavior responsive on the supported web and Android MVP targets.
* Do not expose secrets, provider diagnostics, or disabled integrations in a misleading way.

#### Out of Scope

* Account creation, sign-in, cloud onboarding, or medical-profile setup.

#### Repository Evidence

* `lib/main.dart`
* `README.md`
* `test/widget_test.dart`
* `test/gemini_provider_test.dart`

#### Story Quality Checklist

- [x] first-time application user and outcome are specific to Launch Standalone Local Application.
- [x] Scope is bounded to Implemented MVP behavior: Hydrion launches straight into local mode so a new user can begin logging water without creating....
- [x] Primary dependency is `HydrionServices`; full dependency list is explicit.
- [x] Checked claims cite repository evidence beginning with `lib/main.dart`.
- [x] Acceptance coverage is 2/2; 0 acceptance criteria remain open.

#### INVEST Check

- [x] Independent: 3 listed dependency link(s) for Launch Standalone Local Application.
- [x] Negotiable: implementation detail stays in repository evidence, not hidden in the User Story title.
- [x] Valuable: first-time application user needs Hydrion to open without account, network, provider, or native-service setup so I can start tracking hydration immediately in standalone local mode.
- [x] Estimable: story size is 2 with evidence and open criteria visible.
- [x] Small: size 2 is within a focused slice.
- [x] Testable: 2 checkbox criterion/criteria and test/build evidence are listed.

#### Definition of Ready

- [x] Metadata is complete: P0, MVP, MVP Stabilization, Product Backlog rank 009, size 2.
- [x] Dependencies are named for sequencing; first dependency is `HydrionServices`.
- [x] Acceptance criteria are checkbox-based and currently 2 checked / 0 unchecked.
- [x] Repository evidence is available for current claims; first evidence item is `lib/main.dart`.
- [x] Ready state reflects Implemented: ready to pull or maintain.

#### Definition of Done

- [x] Implementation status is Implemented for Launch Standalone Local Application.
- [x] All acceptance criteria are checked for this story (2/2).
- [x] Verification evidence includes automated tests or CI/docs.
- [x] Project workflow metadata is valid: Product Backlog, rank 009, size 2.
- [x] Done means implemented, verified, and no open criteria for Launch Standalone Local Application.

### HYD-US-002: Access Core Product Screens

**Epic:** Onboarding and Application Access  
**Story Type:** User Story  
**Implementation Status:** Implemented  
**Priority:** P0  
**Release Scope:** MVP
**Labels:** `user-story`, `type:user-story`, `priority:p0`, `status:implemented`, `scope:mvp`, `area:onboarding`, `area:frontend`, `size:3`  
**Milestone:** MVP Stabilization
**Story Size:** 3
**Project Column:** Product Backlog  
**Business Rank:** 010

#### User Story

**As a** application user
**I need** navigation to Home, Analytics, Log, Coach, Challenges, Reminders, Settings, and AR status screens
**So that** I can reach every available hydration workflow from the app shell.

#### Description

* The app shell exposes every committed workflow from the home/navigation surface: Home, Analytics, Log, Coach, Challenges, Reminders, Settings, and AR status.
* Routes that represent unavailable capabilities must open to honest status/placeholder screens instead of implying working native integrations.

#### Details and Business Rules

* routes are registered for `/`, `/analytics`, `/chat`, `/log`, `/reminders`, `/settings`, `/challenges`, and `/ar`.
* Home exposes route chips for the main workflows.
* the AR route exists as a disabled/placeholder status screen, not a real AR session.
* Business rule: Navigation must distinguish available local workflows from capability-gated routes, especially the AR placeholder.
#### Data and State Requirements

* Provider-facing state must avoid persisted production secrets and must preserve local fallback behavior.
* Integration state must be represented through capability status, adapter contracts, or disabled placeholders until a real adapter is implemented.

#### Assumptions

* No additional product assumption is made beyond the repository evidence and explicit out-of-scope notes.

#### Acceptance Criteria

- [x] The requested screen opens without requiring external service setup.
- [x] The screen states the disabled or unavailable capability honestly.

#### Acceptance Criteria Coverage

* Checked acceptance criteria: 2.
* Unchecked acceptance criteria: 0.
* Checked criteria are tied to the repository evidence listed in this story.
* Unchecked criteria represent work or verification still needed before the criterion can be claimed complete.

#### Dependencies

* `HYD-US-001`
* `HYD-US-031`

#### Non-Functional Requirements

* Keep the behavior offline-tolerant and honest about local-first limits.
* Keep user-visible behavior responsive on the supported web and Android MVP targets.
* Do not expose secrets, provider diagnostics, or disabled integrations in a misleading way.

#### Out of Scope

* Deep links, authentication-protected routes, and remote navigation.

#### Repository Evidence

* `lib/main.dart`
* `lib/ui/screens/home_screen.dart`
* `lib/ui/screens/ar_visualization_screen.dart`
* `test/runtime_ux_test.dart`

#### Story Quality Checklist

- [x] application user and outcome are specific to Access Core Product Screens.
- [x] Scope is bounded to Implemented MVP behavior: The app shell exposes every committed workflow from the home/navigation surface: Home, Analytics, Log, Coach, Challenges,....
- [x] Primary dependency is `HYD-US-001`; full dependency list is explicit.
- [x] Checked claims cite repository evidence beginning with `lib/main.dart`.
- [x] Acceptance coverage is 2/2; 0 acceptance criteria remain open.

#### INVEST Check

- [x] Independent: 2 listed dependency link(s) for Access Core Product Screens.
- [x] Negotiable: implementation detail stays in repository evidence, not hidden in the User Story title.
- [x] Valuable: application user needs navigation to Home, Analytics, Log, Coach, Challenges, Reminders, Settings, and AR status screens so I can reach every available hydration workflow from the app shell.
- [x] Estimable: story size is 3 with evidence and open criteria visible.
- [x] Small: size 3 is within a focused slice.
- [x] Testable: 2 checkbox criterion/criteria and test/build evidence are listed.

#### Definition of Ready

- [x] Metadata is complete: P0, MVP, MVP Stabilization, Product Backlog rank 010, size 3.
- [x] Dependencies are named for sequencing; first dependency is `HYD-US-001`.
- [x] Acceptance criteria are checkbox-based and currently 2 checked / 0 unchecked.
- [x] Repository evidence is available for current claims; first evidence item is `lib/main.dart`.
- [x] Ready state reflects Implemented: ready to pull or maintain.

#### Definition of Done

- [x] Implementation status is Implemented for Access Core Product Screens.
- [x] All acceptance criteria are checked for this story (2/2).
- [x] Verification evidence includes automated tests or CI/docs.
- [x] Project workflow metadata is valid: Product Backlog, rank 010, size 3.
- [x] Done means implemented, verified, and no open criteria for Access Core Product Screens.

### HYD-US-003: Log Hydration Manually

**Epic:** Hydration Logging  
**Story Type:** User Story  
**Implementation Status:** Implemented  
**Priority:** P0  
**Release Scope:** MVP
**Labels:** `user-story`, `type:user-story`, `priority:p0`, `status:implemented`, `scope:mvp`, `area:hydration-logging`, `area:persistence`, `area:frontend`, `size:3`  
**Milestone:** MVP Stabilization
**Story Size:** 3
**Project Column:** Product Backlog  
**Business Rank:** 007

#### User Story

**As a** application user
**I need** to select a water amount and log it locally
**So that** Hydrion can calculate my daily hydration progress from saved intake records.

#### Description

* Users can record hydration quickly through preset milliliter actions on the home screen and see their daily total update immediately.
* The logging path must validate amounts before persisting them so accidental or invalid entries do not pollute local history.

#### Details and Business Rules

* Home offers preset amounts of 150, 250, 350, 500, 750, and 1000 ml.
* tapping the log button creates a local hydration record with source `local`.
* repository validation rejects non-positive volumes.
* Business rule: Only positive hydration amounts are accepted for persisted log records.
#### Data and State Requirements

* Local application state must remain scoped to Hydrion repositories and the `shared_preferences` backed local store unless the story explicitly says otherwise.
* Integration state must be represented through capability status, adapter contracts, or disabled placeholders until a real adapter is implemented.

#### Assumptions

* custom log amount entry from Home is not implemented; custom values are available only through edit/provider paths.

#### Acceptance Criteria

- [x] A 500 ml local hydration record is saved.
- [x] No hydration log is created.
- [x] The user sees a localized confirmation message.

#### Acceptance Criteria Coverage

* Checked acceptance criteria: 3.
* Unchecked acceptance criteria: 0.
* Checked criteria are tied to the repository evidence listed in this story.
* Unchecked criteria represent work or verification still needed before the criterion can be claimed complete.

#### Dependencies

* `HydrationRepository`
* `HYD-US-004`

#### Non-Functional Requirements

* Keep the behavior offline-tolerant and honest about local-first limits.
* Keep user-visible behavior responsive on the supported web and Android MVP targets.
* Do not expose secrets, provider diagnostics, or disabled integrations in a misleading way.

#### Out of Scope

* Barcode/device import, voice capture, BLE intake, and arbitrary Home-screen amount entry.

#### Repository Evidence

* `lib/ui/screens/home_screen.dart`
* `lib/repositories/hydration_repository.dart`
* `test/runtime_ux_test.dart`

#### Story Quality Checklist

- [x] application user and outcome are specific to Log Hydration Manually.
- [x] Scope is bounded to Implemented MVP behavior: Users can record hydration quickly through preset milliliter actions on the home screen and see their....
- [x] Primary dependency is `HydrationRepository`; full dependency list is explicit.
- [x] Checked claims cite repository evidence beginning with `lib/ui/screens/home_screen.dart`.
- [x] Acceptance coverage is 3/3; 0 acceptance criteria remain open.

#### INVEST Check

- [x] Independent: 2 listed dependency link(s) for Log Hydration Manually.
- [x] Negotiable: implementation detail stays in repository evidence, not hidden in the User Story title.
- [x] Valuable: application user needs to select a water amount and log it locally so Hydrion can calculate my daily hydration progress from saved intake records.
- [x] Estimable: story size is 3 with evidence and open criteria visible.
- [x] Small: size 3 is within a focused slice.
- [x] Testable: 3 checkbox criterion/criteria and test/build evidence are listed.

#### Definition of Ready

- [x] Metadata is complete: P0, MVP, MVP Stabilization, Product Backlog rank 007, size 3.
- [x] Dependencies are named for sequencing; first dependency is `HydrationRepository`.
- [x] Acceptance criteria are checkbox-based and currently 3 checked / 0 unchecked.
- [x] Repository evidence is available for current claims; first evidence item is `lib/ui/screens/home_screen.dart`.
- [x] Ready state reflects Implemented: ready to pull or maintain.

#### Definition of Done

- [x] Implementation status is Implemented for Log Hydration Manually.
- [x] All acceptance criteria are checked for this story (3/3).
- [x] Verification evidence includes automated tests or CI/docs.
- [x] Project workflow metadata is valid: Product Backlog, rank 007, size 3.
- [x] Done means implemented, verified, and no open criteria for Log Hydration Manually.

### HYD-US-004: Persist Hydration Logs Locally

**Epic:** Hydration Logging  
**Story Type:** System Story  
**Implementation Status:** Implemented  
**Priority:** P0  
**Release Scope:** MVP
**Labels:** `user-story`, `type:system`, `priority:p0`, `status:implemented`, `scope:mvp`, `area:hydration-logging`, `area:persistence`, `area:frontend`, `size:3`  
**Milestone:** MVP Stabilization
**Story Size:** 3
**Project Column:** Product Backlog  
**Business Rank:** 006

#### User Story

**As a** returning user
**I need** hydration records to persist on the device
**So that** my history and analytics survive app restart or refresh.

#### Description

* Hydration logs survive refreshes and app restarts through the local store abstraction rather than an external backend.
* Persistence must tolerate malformed stored data by filtering invalid records and returning a safe local state.

#### Details and Business Rules

* hydration logs serialize to JSON under `hydrion.hydration_logs.v1`.
* `SharedPreferencesHydrionStore` is the production local store abstraction.
* repository reload restores valid logs and ignores malformed JSON or invalid records.
* Business rule: Local persistence is the source of truth for hydration logs until a future explicit sync story replaces it.
#### Data and State Requirements

* Local application state must remain scoped to Hydrion repositories and the `shared_preferences` backed local store unless the story explicitly says otherwise.
* Integration state must be represented through capability status, adapter contracts, or disabled placeholders until a real adapter is implemented.

#### Assumptions

* No additional product assumption is made beyond the repository evidence and explicit out-of-scope notes.

#### Acceptance Criteria

- [x] The log amount, timestamp, and day total are restored.
- [x] Hydrion returns an empty log list without crashing.

#### Acceptance Criteria Coverage

* Checked acceptance criteria: 2.
* Unchecked acceptance criteria: 0.
* Checked criteria are tied to the repository evidence listed in this story.
* Unchecked criteria represent work or verification still needed before the criterion can be claimed complete.

#### Dependencies

* `HydrionLocalStore`
* `SharedPreferencesHydrionStore`

#### Non-Functional Requirements

* Keep the behavior offline-tolerant and honest about local-first limits.
* Keep user-visible behavior responsive on the supported web and Android MVP targets.
* Do not expose secrets, provider diagnostics, or disabled integrations in a misleading way.

#### Out of Scope

* Cloud sync, SQLCipher, encrypted export, and conflict resolution.

#### Repository Evidence

* `lib/storage/local_store.dart`
* `lib/repositories/hydration_repository.dart`
* `test/persistence_test.dart`

#### Story Quality Checklist

- [x] returning user and outcome are specific to Persist Hydration Logs Locally.
- [x] Scope is bounded to Implemented MVP behavior: Hydration logs survive refreshes and app restarts through the local store abstraction rather than an external....
- [x] Primary dependency is `HydrionLocalStore`; full dependency list is explicit.
- [x] Checked claims cite repository evidence beginning with `lib/storage/local_store.dart`.
- [x] Acceptance coverage is 2/2; 0 acceptance criteria remain open.

#### INVEST Check

- [x] Independent: 2 listed dependency link(s) for Persist Hydration Logs Locally.
- [x] Negotiable: implementation detail stays in repository evidence, not hidden in the System Story title.
- [x] Valuable: returning user needs hydration records to persist on the device so my history and analytics survive app restart or refresh.
- [x] Estimable: story size is 3 with evidence and open criteria visible.
- [x] Small: size 3 is within a focused slice.
- [x] Testable: 2 checkbox criterion/criteria and test/build evidence are listed.

#### Definition of Ready

- [x] Metadata is complete: P0, MVP, MVP Stabilization, Product Backlog rank 006, size 3.
- [x] Dependencies are named for sequencing; first dependency is `HydrionLocalStore`.
- [x] Acceptance criteria are checkbox-based and currently 2 checked / 0 unchecked.
- [x] Repository evidence is available for current claims; first evidence item is `lib/storage/local_store.dart`.
- [x] Ready state reflects Implemented: ready to pull or maintain.

#### Definition of Done

- [x] Implementation status is Implemented for Persist Hydration Logs Locally.
- [x] All acceptance criteria are checked for this story (2/2).
- [x] Verification evidence includes automated tests or CI/docs.
- [x] Project workflow metadata is valid: Product Backlog, rank 006, size 3.
- [x] Done means implemented, verified, and no open criteria for Persist Hydration Logs Locally.

### HYD-US-005: View Recent Hydration History

**Epic:** Hydration History Management  
**Story Type:** User Story  
**Implementation Status:** Implemented  
**Priority:** P0  
**Release Scope:** MVP
**Labels:** `user-story`, `type:user-story`, `priority:p0`, `status:implemented`, `scope:mvp`, `area:history`, `area:persistence`, `area:frontend`, `size:2`  
**Milestone:** MVP Product UX
**Story Size:** 2
**Project Column:** Product Backlog  
**Business Rank:** 011

#### User Story

**As a** returning user
**I need** to review my recent hydration records with source and timestamp
**So that** I can verify what Hydrion used for summaries and analytics.

#### Description

* The log screen gives users a recent-history view of their locally stored hydration entries so they can verify what was captured.
* Empty history must be understandable and useful, not a blank panel or a misleading analytics result.

#### Details and Business Rules

* Log screen fetches records from the last seven days.
* entries are shown with volume, localized source label, and formatted timestamp.
* an empty state explains that local entries can be added from Home.
* Business rule: History views read from the local hydration repository and must not require network-backed data.
#### Data and State Requirements

* Local application state must remain scoped to Hydrion repositories and the `shared_preferences` backed local store unless the story explicitly says otherwise.
* Integration state must be represented through capability status, adapter contracts, or disabled placeholders until a real adapter is implemented.

#### Assumptions

* No additional product assumption is made beyond the repository evidence and explicit out-of-scope notes.

#### Acceptance Criteria

- [x] Each record shows its ml amount, source, timestamp, edit action, and delete action.
- [x] Hydrion shows a localized empty state explaining how to add local entries.

#### Acceptance Criteria Coverage

* Checked acceptance criteria: 2.
* Unchecked acceptance criteria: 0.
* Checked criteria are tied to the repository evidence listed in this story.
* Unchecked criteria represent work or verification still needed before the criterion can be claimed complete.

#### Dependencies

* `HYD-US-003`
* `HYD-US-004`

#### Non-Functional Requirements

* Keep the behavior offline-tolerant and honest about local-first limits.
* Keep user-visible behavior responsive on the supported web and Android MVP targets.
* Do not expose secrets, provider diagnostics, or disabled integrations in a misleading way.

#### Out of Scope

* Infinite history paging, filtering by source, export, or graphing history on this screen.

#### Repository Evidence

* `lib/ui/screens/log_screen.dart`
* `lib/repositories/hydration_repository.dart`
* `test/runtime_ux_test.dart`

#### Story Quality Checklist

- [x] returning user and outcome are specific to View Recent Hydration History.
- [x] Scope is bounded to Implemented MVP behavior: The log screen gives users a recent-history view of their locally stored hydration entries so they....
- [x] Primary dependency is `HYD-US-003`; full dependency list is explicit.
- [x] Checked claims cite repository evidence beginning with `lib/ui/screens/log_screen.dart`.
- [x] Acceptance coverage is 2/2; 0 acceptance criteria remain open.

#### INVEST Check

- [x] Independent: 2 listed dependency link(s) for View Recent Hydration History.
- [x] Negotiable: implementation detail stays in repository evidence, not hidden in the User Story title.
- [x] Valuable: returning user needs to review my recent hydration records with source and timestamp so I can verify what Hydrion used for summaries and analytics.
- [x] Estimable: story size is 2 with evidence and open criteria visible.
- [x] Small: size 2 is within a focused slice.
- [x] Testable: 2 checkbox criterion/criteria and test/build evidence are listed.

#### Definition of Ready

- [x] Metadata is complete: P0, MVP, MVP Product UX, Product Backlog rank 011, size 2.
- [x] Dependencies are named for sequencing; first dependency is `HYD-US-003`.
- [x] Acceptance criteria are checkbox-based and currently 2 checked / 0 unchecked.
- [x] Repository evidence is available for current claims; first evidence item is `lib/ui/screens/log_screen.dart`.
- [x] Ready state reflects Implemented: ready to pull or maintain.

#### Definition of Done

- [x] Implementation status is Implemented for View Recent Hydration History.
- [x] All acceptance criteria are checked for this story (2/2).
- [x] Verification evidence includes automated tests or CI/docs.
- [x] Project workflow metadata is valid: Product Backlog, rank 011, size 2.
- [x] Done means implemented, verified, and no open criteria for View Recent Hydration History.

### HYD-US-006: Edit Hydration Records

**Epic:** Hydration History Management  
**Story Type:** User Story  
**Implementation Status:** Implemented  
**Priority:** P1  
**Release Scope:** MVP
**Labels:** `user-story`, `type:user-story`, `priority:p1`, `status:implemented`, `scope:mvp`, `area:history`, `area:persistence`, `area:frontend`, `size:3`  
**Milestone:** MVP Product UX
**Story Size:** 3
**Project Column:** Product Backlog  
**Business Rank:** 016

#### User Story

**As a** returning user
**I need** to correct a saved hydration record
**So that** mistakes do not distort my progress, analytics, score, achievements, or challenge progress.

#### Description

* Users can correct an existing hydration entry when the amount or timestamp is wrong, preserving trust in the daily totals and analytics.
* Edit behavior must update the persisted record safely and reject invalid replacement values.

#### Details and Business Rules

* Log screen opens an edit dialog for volume updates.
* invalid or non-positive edit input is discarded by the dialog/repository.
* edit values are clamped to 1 to 5000 ml in the UI.
* updated records persist across repository reload.
* Business rule: Editing must preserve record identity and reject non-positive hydration amounts.
#### Data and State Requirements

* Local application state must remain scoped to Hydrion repositories and the `shared_preferences` backed local store unless the story explicitly says otherwise.
* Integration state must be represented through capability status, adapter contracts, or disabled placeholders until a real adapter is implemented.

#### Assumptions

* No additional product assumption is made beyond the repository evidence and explicit out-of-scope notes.

#### Acceptance Criteria

- [x] The record shows 650 ml and the repository persists the update.
- [x] No invalid hydration record is saved.
- [x] The user sees a localized "log not found" result.

#### Acceptance Criteria Coverage

* Checked acceptance criteria: 3.
* Unchecked acceptance criteria: 0.
* Checked criteria are tied to the repository evidence listed in this story.
* Unchecked criteria represent work or verification still needed before the criterion can be claimed complete.

#### Dependencies

* `HYD-US-004`
* `HYD-US-005`

#### Non-Functional Requirements

* Keep the behavior offline-tolerant and honest about local-first limits.
* Keep user-visible behavior responsive on the supported web and Android MVP targets.
* Do not expose secrets, provider diagnostics, or disabled integrations in a misleading way.

#### Out of Scope

* Editing timestamp or source from the UI.

#### Repository Evidence

* `lib/ui/screens/log_screen.dart`
* `lib/repositories/hydration_repository.dart`
* `test/persistence_test.dart`
* `test/runtime_ux_test.dart`

#### Story Quality Checklist

- [x] returning user and outcome are specific to Edit Hydration Records.
- [x] Scope is bounded to Implemented MVP behavior: Users can correct an existing hydration entry when the amount or timestamp is wrong, preserving trust....
- [x] Primary dependency is `HYD-US-004`; full dependency list is explicit.
- [x] Checked claims cite repository evidence beginning with `lib/ui/screens/log_screen.dart`.
- [x] Acceptance coverage is 3/3; 0 acceptance criteria remain open.

#### INVEST Check

- [x] Independent: 2 listed dependency link(s) for Edit Hydration Records.
- [x] Negotiable: implementation detail stays in repository evidence, not hidden in the User Story title.
- [x] Valuable: returning user needs to correct a saved hydration record so mistakes do not distort my progress, analytics, score, achievements, or challenge progress.
- [x] Estimable: story size is 3 with evidence and open criteria visible.
- [x] Small: size 3 is within a focused slice.
- [x] Testable: 3 checkbox criterion/criteria and test/build evidence are listed.

#### Definition of Ready

- [x] Metadata is complete: P1, MVP, MVP Product UX, Product Backlog rank 016, size 3.
- [x] Dependencies are named for sequencing; first dependency is `HYD-US-004`.
- [x] Acceptance criteria are checkbox-based and currently 3 checked / 0 unchecked.
- [x] Repository evidence is available for current claims; first evidence item is `lib/ui/screens/log_screen.dart`.
- [x] Ready state reflects Implemented: ready to pull or maintain.

#### Definition of Done

- [x] Implementation status is Implemented for Edit Hydration Records.
- [x] All acceptance criteria are checked for this story (3/3).
- [x] Verification evidence includes automated tests or CI/docs.
- [x] Project workflow metadata is valid: Product Backlog, rank 016, size 3.
- [x] Done means implemented, verified, and no open criteria for Edit Hydration Records.

### HYD-US-007: Delete Hydration Records

**Epic:** Hydration History Management  
**Story Type:** User Story  
**Implementation Status:** Implemented  
**Priority:** P1  
**Release Scope:** MVP
**Labels:** `user-story`, `type:user-story`, `priority:p1`, `status:implemented`, `scope:mvp`, `area:history`, `area:persistence`, `area:frontend`, `size:2`  
**Milestone:** MVP Product UX
**Story Size:** 2
**Project Column:** Product Backlog  
**Business Rank:** 017

#### User Story

**As a** returning user
**I need** to delete incorrect hydration records
**So that** my local summaries and derived insights reflect only valid intake.

#### Description

* Users can remove an incorrect hydration entry from local history when it should not count toward progress.
* Deletion must update the persisted local store and downstream totals without leaving stale UI state.

#### Details and Business Rules

* Log screen delete action removes a record by id.
* delete persists across reload.
* the UI shows "deleted" or "not found" feedback.
* Business rule: Delete actions must target a concrete log record and refresh dependent local summaries.
#### Data and State Requirements

* Local application state must remain scoped to Hydrion repositories and the `shared_preferences` backed local store unless the story explicitly says otherwise.
* Integration state must be represented through capability status, adapter contracts, or disabled placeholders until a real adapter is implemented.

#### Assumptions

* No additional product assumption is made beyond the repository evidence and explicit out-of-scope notes.

#### Acceptance Criteria

- [x] The record is removed from history and local storage.
- [x] The empty state is shown.
- [x] Hydrion reports that the log was not found.

#### Acceptance Criteria Coverage

* Checked acceptance criteria: 3.
* Unchecked acceptance criteria: 0.
* Checked criteria are tied to the repository evidence listed in this story.
* Unchecked criteria represent work or verification still needed before the criterion can be claimed complete.

#### Dependencies

* `HYD-US-004`
* `HYD-US-005`

#### Non-Functional Requirements

* Keep the behavior offline-tolerant and honest about local-first limits.
* Keep user-visible behavior responsive on the supported web and Android MVP targets.
* Do not expose secrets, provider diagnostics, or disabled integrations in a misleading way.

#### Out of Scope

* Undo, batch delete, and account-level data erasure.

#### Repository Evidence

* `lib/ui/screens/log_screen.dart`
* `lib/repositories/hydration_repository.dart`
* `test/persistence_test.dart`
* `test/runtime_ux_test.dart`

#### Story Quality Checklist

- [x] returning user and outcome are specific to Delete Hydration Records.
- [x] Scope is bounded to Implemented MVP behavior: Users can remove an incorrect hydration entry from local history when it should not count toward....
- [x] Primary dependency is `HYD-US-004`; full dependency list is explicit.
- [x] Checked claims cite repository evidence beginning with `lib/ui/screens/log_screen.dart`.
- [x] Acceptance coverage is 3/3; 0 acceptance criteria remain open.

#### INVEST Check

- [x] Independent: 2 listed dependency link(s) for Delete Hydration Records.
- [x] Negotiable: implementation detail stays in repository evidence, not hidden in the User Story title.
- [x] Valuable: returning user needs to delete incorrect hydration records so my local summaries and derived insights reflect only valid intake.
- [x] Estimable: story size is 2 with evidence and open criteria visible.
- [x] Small: size 2 is within a focused slice.
- [x] Testable: 3 checkbox criterion/criteria and test/build evidence are listed.

#### Definition of Ready

- [x] Metadata is complete: P1, MVP, MVP Product UX, Product Backlog rank 017, size 2.
- [x] Dependencies are named for sequencing; first dependency is `HYD-US-004`.
- [x] Acceptance criteria are checkbox-based and currently 3 checked / 0 unchecked.
- [x] Repository evidence is available for current claims; first evidence item is `lib/ui/screens/log_screen.dart`.
- [x] Ready state reflects Implemented: ready to pull or maintain.

#### Definition of Done

- [x] Implementation status is Implemented for Delete Hydration Records.
- [x] All acceptance criteria are checked for this story (3/3).
- [x] Verification evidence includes automated tests or CI/docs.
- [x] Project workflow metadata is valid: Product Backlog, rank 017, size 2.
- [x] Done means implemented, verified, and no open criteria for Delete Hydration Records.

### HYD-US-008: View Daily Summary and Progress Ring

**Epic:** Daily Goals and Progress  
**Story Type:** User Story  
**Implementation Status:** Implemented  
**Priority:** P0  
**Release Scope:** MVP
**Labels:** `user-story`, `type:user-story`, `priority:p0`, `status:implemented`, `scope:mvp`, `area:goals`, `area:analytics`, `area:frontend`, `size:3`  
**Milestone:** MVP Product UX
**Story Size:** 3
**Project Column:** Product Backlog  
**Business Rank:** 008

#### User Story

**As a** application user
**I need** to see today's consumed ml, target ml, and progress percentage
**So that** I can quickly decide whether to drink more water.

#### Description

* The home screen shows today's hydration total and progress toward the current fixed goal so users can understand their status at a glance.
* The progress ring is evidence-backed for the current MVP, but it must not pretend goal customization exists yet.

#### Details and Business Rules

* summary uses today's local logs and a fixed target of 2200 ml.
* `IntakeRing` clamps progress to 0 to 100 percent and includes semantic label/value/hint.
* Home updates after manual logging.
* Business rule: Daily progress is calculated against the current fixed 2200 ml target until configurable goals are implemented.
#### Data and State Requirements

* Provider-facing state must avoid persisted production secrets and must preserve local fallback behavior.
* Integration state must be represented through capability status, adapter contracts, or disabled placeholders until a real adapter is implemented.

#### Assumptions

* No additional product assumption is made beyond the repository evidence and explicit out-of-scope notes.

#### Acceptance Criteria

- [x] The progress ring shows 0 / 2200 ml and 0 percent.
- [x] The progress ring shows 500 / 2200 ml and a bounded progress percentage.
- [x] The displayed progress percentage does not exceed 100 percent.

#### Acceptance Criteria Coverage

* Checked acceptance criteria: 3.
* Unchecked acceptance criteria: 0.
* Checked criteria are tied to the repository evidence listed in this story.
* Unchecked criteria represent work or verification still needed before the criterion can be claimed complete.

#### Dependencies

* `HYD-US-003`
* `HYD-US-004`

#### Non-Functional Requirements

* Keep the behavior offline-tolerant and honest about local-first limits.
* Keep user-visible behavior responsive on the supported web and Android MVP targets.
* Do not expose secrets, provider diagnostics, or disabled integrations in a misleading way.

#### Out of Scope

* User-adjustable target, unit preference, activity/temperature target adjustment, or injected day-boundary service.

#### Repository Evidence

* `lib/adapters/local/local_hydrion_adapters.dart`
* `lib/ui/components/intake_ring.dart`
* `lib/ui/screens/home_screen.dart`
* `test/runtime_ux_test.dart`

#### Story Quality Checklist

- [x] application user and outcome are specific to View Daily Summary and Progress Ring.
- [x] Scope is bounded to Implemented MVP behavior: The home screen shows today's hydration total and progress toward the current fixed goal so users....
- [x] Primary dependency is `HYD-US-003`; full dependency list is explicit.
- [x] Checked claims cite repository evidence beginning with `lib/adapters/local/local_hydrion_adapters.dart`.
- [x] Acceptance coverage is 3/3; 0 acceptance criteria remain open.

#### INVEST Check

- [x] Independent: 2 listed dependency link(s) for View Daily Summary and Progress Ring.
- [x] Negotiable: implementation detail stays in repository evidence, not hidden in the User Story title.
- [x] Valuable: application user needs to see today's consumed ml, target ml, and progress percentage so I can quickly decide whether to drink more water.
- [x] Estimable: story size is 3 with evidence and open criteria visible.
- [x] Small: size 3 is within a focused slice.
- [x] Testable: 3 checkbox criterion/criteria and test/build evidence are listed.

#### Definition of Ready

- [x] Metadata is complete: P0, MVP, MVP Product UX, Product Backlog rank 008, size 3.
- [x] Dependencies are named for sequencing; first dependency is `HYD-US-003`.
- [x] Acceptance criteria are checkbox-based and currently 3 checked / 0 unchecked.
- [x] Repository evidence is available for current claims; first evidence item is `lib/adapters/local/local_hydrion_adapters.dart`.
- [x] Ready state reflects Implemented: ready to pull or maintain.

#### Definition of Done

- [x] Implementation status is Implemented for View Daily Summary and Progress Ring.
- [x] All acceptance criteria are checked for this story (3/3).
- [x] Verification evidence includes automated tests or CI/docs.
- [x] Project workflow metadata is valid: Product Backlog, rank 008, size 3.
- [x] Done means implemented, verified, and no open criteria for View Daily Summary and Progress Ring.

### HYD-US-009: Configure Hydration Goals and Units

**Epic:** Daily Goals and Progress  
**Story Type:** User Story  
**Implementation Status:** Planned  
**Priority:** P1  
**Release Scope:** MVP
**Labels:** `user-story`, `type:user-story`, `priority:p1`, `status:planned`, `scope:mvp`, `area:goals`, `area:analytics`, `area:frontend`, `size:5`  
**Milestone:** MVP Product UX
**Story Size:** 5
**Project Column:** Product Backlog  
**Business Rank:** 015

#### User Story

**As a** application user
**I need** to configure my daily hydration target and unit preference
**So that** Hydrion's progress reflects my personal hydration goal instead of a hardcoded default.

#### Description

* Users need future settings for personal hydration targets and units because the current fixed 2200 ml goal cannot fit every body, climate, or preference.
* This story remains planned: it must add real persisted settings and update summaries, rings, analytics, and copy together.

#### Details and Business Rules

* current Flutter runtime uses a fixed 2200 ml target in summary, analytics, and context.
* roadmap identifies target and unit preference as an MVP UX follow-up.
* Business rule: Do not claim configurable goals until target and unit settings are user-editable, persisted, and consumed by summary calculations.
#### Data and State Requirements

* Local application state must remain scoped to Hydrion repositories and the `shared_preferences` backed local store unless the story explicitly says otherwise.
* Integration state must be represented through capability status, adapter contracts, or disabled placeholders until a real adapter is implemented.

#### Assumptions

* No additional product assumption is made beyond the repository evidence and explicit out-of-scope notes.

#### Acceptance Criteria

- [ ] The current 2200 ml default remains the fallback.
- [ ] They use the persisted target consistently.
- [ ] Hydrion rejects the value without corrupting existing settings.
- [ ] Remaining end-to-end user behavior for this story is implemented, verified, and ready for release..

#### Acceptance Criteria Coverage

* Checked acceptance criteria: 0.
* Unchecked acceptance criteria: 4.
* Checked criteria are tied to the repository evidence listed in this story.
* Unchecked criteria represent work or verification still needed before the criterion can be claimed complete.

#### Dependencies

* `HYD-US-008`
* `HYD-US-027`
* `HYD-US-042`

#### Non-Functional Requirements

* Keep the behavior offline-tolerant and honest about local-first limits.
* Keep user-visible behavior responsive on the supported web and Android MVP targets.
* Do not expose secrets, provider diagnostics, or disabled integrations in a misleading way.
* Preserve capability gating until the unchecked acceptance criteria are implemented and verified.

#### Out of Scope

* Medical target calculation, wearable-derived goals, or cloud profile sync.

#### Repository Evidence

* `lib/adapters/local/local_hydrion_adapters.dart`
* `lib/services/hydration_context_builder.dart`
* `lib/ui/screens/analytics_screen.dart`
* `HYDRION_MVP_KANBAN_ROADMAP.md`

#### Story Quality Checklist

- [x] application user and outcome are specific to Configure Hydration Goals and Units.
- [x] Scope is bounded to Planned MVP behavior: Users need future settings for personal hydration targets and units because the current fixed 2200 ml....
- [x] Primary dependency is `HYD-US-008`; full dependency list is explicit.
- [x] Checked claims cite repository evidence beginning with `lib/adapters/local/local_hydrion_adapters.dart`.
- [ ] Acceptance coverage is 0/4; 4 acceptance criteria remain open.

#### INVEST Check

- [x] Independent: 3 listed dependency link(s) for Configure Hydration Goals and Units.
- [x] Negotiable: implementation detail stays in repository evidence, not hidden in the User Story title.
- [x] Valuable: application user needs to configure my daily hydration target and unit preference so Hydrion's progress reflects my personal hydration goal instead of a hardcoded default.
- [x] Estimable: story size is 5 with evidence and open criteria visible.
- [x] Small: size 5 is within a focused slice.
- [x] Testable: 4 checkbox criterion/criteria and planned verification are listed.

#### Definition of Ready

- [x] Metadata is complete: P1, MVP, MVP Product UX, Product Backlog rank 015, size 5.
- [x] Dependencies are named for sequencing; first dependency is `HYD-US-008`.
- [x] Acceptance criteria are checkbox-based and currently 0 checked / 4 unchecked.
- [x] Repository evidence is available for current claims; first evidence item is `lib/adapters/local/local_hydrion_adapters.dart`.
- [ ] Ready state reflects Planned: needs implementation, split, or uncertainty cleanup before sprint pull.

#### Definition of Done

- [ ] Implementation status is Implemented for Configure Hydration Goals and Units.
- [ ] All acceptance criteria are checked for this story (0/4).
- [ ] Verification evidence includes no automated test/CI evidence yet.
- [x] Project workflow metadata is valid: Product Backlog, rank 015, size 5.
- [ ] Done means implemented, verified, and no open criteria for Configure Hydration Goals and Units.

### HYD-US-010: View Analytics Empty State and Daily Totals

**Epic:** Analytics and Insights  
**Story Type:** User Story  
**Implementation Status:** Implemented  
**Priority:** P1  
**Release Scope:** MVP
**Labels:** `user-story`, `type:user-story`, `priority:p1`, `status:implemented`, `scope:mvp`, `area:analytics`, `area:frontend`, `size:3`  
**Milestone:** MVP Product UX
**Story Size:** 3
**Project Column:** Product Backlog  
**Business Rank:** 018

#### User Story

**As a** returning user
**I need** analytics to reflect saved local hydration records
**So that** I can understand today's intake and whether there is enough data for insights.

#### Description

* Analytics must be useful before and after the user has data: empty states should orient first-time users, and totals should reflect local logs once they exist.
* The screen should avoid remote analytics assumptions and derive its user-facing numbers from local state.

#### Details and Business Rules

* Analytics displays an empty state when no logs exist.
* Analytics displays today's ml against 2200 ml and local entry count.
* Analytics depends only on `HydrationRepository` and local services.
* Business rule: Analytics displays must handle zero-log and populated-log states without requiring backend telemetry.
#### Data and State Requirements

* Provider-facing state must avoid persisted production secrets and must preserve local fallback behavior.
* Integration state must be represented through capability status, adapter contracts, or disabled placeholders until a real adapter is implemented.

#### Assumptions

* No additional product assumption is made beyond the repository evidence and explicit out-of-scope notes.

#### Acceptance Criteria

- [x] Hydrion shows a localized "No analytics yet" state.
- [x] Hydrion shows today's consumed ml, target ml, and local entry count.

#### Acceptance Criteria Coverage

* Checked acceptance criteria: 2.
* Unchecked acceptance criteria: 0.
* Checked criteria are tied to the repository evidence listed in this story.
* Unchecked criteria represent work or verification still needed before the criterion can be claimed complete.

#### Dependencies

* `HYD-US-004`
* `HYD-US-008`

#### Non-Functional Requirements

* Keep the behavior offline-tolerant and honest about local-first limits.
* Keep user-visible behavior responsive on the supported web and Android MVP targets.
* Do not expose secrets, provider diagnostics, or disabled integrations in a misleading way.

#### Out of Scope

* Weekly/monthly trend charts, remote analytics, and telemetry.

#### Repository Evidence

* `lib/ui/screens/analytics_screen.dart`
* `test/runtime_ux_test.dart`
* `test/product_qa_test.dart`

#### Story Quality Checklist

- [x] returning user and outcome are specific to View Analytics Empty State and Daily Totals.
- [x] Scope is bounded to Implemented MVP behavior: Analytics must be useful before and after the user has data: empty states should orient first-time....
- [x] Primary dependency is `HYD-US-004`; full dependency list is explicit.
- [x] Checked claims cite repository evidence beginning with `lib/ui/screens/analytics_screen.dart`.
- [x] Acceptance coverage is 2/2; 0 acceptance criteria remain open.

#### INVEST Check

- [x] Independent: 2 listed dependency link(s) for View Analytics Empty State and Daily Totals.
- [x] Negotiable: implementation detail stays in repository evidence, not hidden in the User Story title.
- [x] Valuable: returning user needs analytics to reflect saved local hydration records so I can understand today's intake and whether there is enough data for insights.
- [x] Estimable: story size is 3 with evidence and open criteria visible.
- [x] Small: size 3 is within a focused slice.
- [x] Testable: 2 checkbox criterion/criteria and test/build evidence are listed.

#### Definition of Ready

- [x] Metadata is complete: P1, MVP, MVP Product UX, Product Backlog rank 018, size 3.
- [x] Dependencies are named for sequencing; first dependency is `HYD-US-004`.
- [x] Acceptance criteria are checkbox-based and currently 2 checked / 0 unchecked.
- [x] Repository evidence is available for current claims; first evidence item is `lib/ui/screens/analytics_screen.dart`.
- [x] Ready state reflects Implemented: ready to pull or maintain.

#### Definition of Done

- [x] Implementation status is Implemented for View Analytics Empty State and Daily Totals.
- [x] All acceptance criteria are checked for this story (2/2).
- [x] Verification evidence includes automated tests or CI/docs.
- [x] Project workflow metadata is valid: Product Backlog, rank 018, size 3.
- [x] Done means implemented, verified, and no open criteria for View Analytics Empty State and Daily Totals.

### HYD-US-011: Calculate Hydration Score

**Epic:** Hydration Score  
**Story Type:** User Story  
**Implementation Status:** Implemented  
**Priority:** P1  
**Release Scope:** MVP
**Labels:** `user-story`, `type:user-story`, `priority:p1`, `status:implemented`, `scope:mvp`, `area:analytics`, `size:2`  
**Milestone:** MVP Product UX
**Story Size:** 2
**Project Column:** Product Backlog  
**Business Rank:** 019

#### User Story

**As a** application user
**I need** a simple hydration score
**So that** I can interpret daily intake and logging consistency at a glance.

#### Description

* The hydration score card translates the user's daily intake into a simple local score that can be scanned quickly.
* The score must remain deterministic and explainable enough to test without an external AI or analytics service.

#### Details and Business Rules

* score is `80% hydrationPercent + 20% consistency`, where consistency is entry count capped at 4 logs.
* score is clamped to 0 to 100 and color-coded.
* localized tips vary by score threshold.
* Business rule: Hydration score calculation must be derived from local summary inputs, not provider output.
#### Data and State Requirements

* Integration state must be represented through capability status, adapter contracts, or disabled placeholders until a real adapter is implemented.

#### Assumptions

* score is a wellness indicator, not a clinical metric.

#### Acceptance Criteria

- [x] It shows a 0 to 100 score based on the implemented weighted formula.
- [x] Extra entries do not increase consistency beyond 100 percent.
- [x] The displayed color and localized tip match the threshold.

#### Acceptance Criteria Coverage

* Checked acceptance criteria: 3.
* Unchecked acceptance criteria: 0.
* Checked criteria are tied to the repository evidence listed in this story.
* Unchecked criteria represent work or verification still needed before the criterion can be claimed complete.

#### Dependencies

* `HYD-US-008`
* `HYD-US-010`

#### Non-Functional Requirements

* Keep the behavior offline-tolerant and honest about local-first limits.
* Keep user-visible behavior responsive on the supported web and Android MVP targets.
* Do not expose secrets, provider diagnostics, or disabled integrations in a misleading way.

#### Out of Scope

* ML-based scoring, medical risk scoring, or personalized formula tuning.

#### Repository Evidence

* `lib/ui/components/hydration_score_card.dart`
* `lib/ui/screens/analytics_screen.dart`
* `test/product_qa_test.dart`

#### Story Quality Checklist

- [x] application user and outcome are specific to Calculate Hydration Score.
- [x] Scope is bounded to Implemented MVP behavior: The hydration score card translates the user's daily intake into a simple local score that can....
- [x] Primary dependency is `HYD-US-008`; full dependency list is explicit.
- [x] Checked claims cite repository evidence beginning with `lib/ui/components/hydration_score_card.dart`.
- [x] Acceptance coverage is 3/3; 0 acceptance criteria remain open.

#### INVEST Check

- [x] Independent: 2 listed dependency link(s) for Calculate Hydration Score.
- [x] Negotiable: implementation detail stays in repository evidence, not hidden in the User Story title.
- [x] Valuable: application user needs a simple hydration score so I can interpret daily intake and logging consistency at a glance.
- [x] Estimable: story size is 2 with evidence and open criteria visible.
- [x] Small: size 2 is within a focused slice.
- [x] Testable: 3 checkbox criterion/criteria and test/build evidence are listed.

#### Definition of Ready

- [x] Metadata is complete: P1, MVP, MVP Product UX, Product Backlog rank 019, size 2.
- [x] Dependencies are named for sequencing; first dependency is `HYD-US-008`.
- [x] Acceptance criteria are checkbox-based and currently 3 checked / 0 unchecked.
- [x] Repository evidence is available for current claims; first evidence item is `lib/ui/components/hydration_score_card.dart`.
- [x] Ready state reflects Implemented: ready to pull or maintain.

#### Definition of Done

- [x] Implementation status is Implemented for Calculate Hydration Score.
- [x] All acceptance criteria are checked for this story (3/3).
- [x] Verification evidence includes automated tests or CI/docs.
- [x] Project workflow metadata is valid: Product Backlog, rank 019, size 2.
- [x] Done means implemented, verified, and no open criteria for Calculate Hydration Score.

### HYD-US-012: Track Daily Goal Streaks

**Epic:** Streaks and Achievements  
**Story Type:** User Story  
**Implementation Status:** Implemented  
**Priority:** P1  
**Release Scope:** Supporting
**Labels:** `user-story`, `type:user-story`, `priority:p1`, `status:implemented`, `scope:supporting`, `area:analytics`, `area:engagement`, `size:2`  
**Milestone:** MVP Product UX
**Story Size:** 2
**Project Column:** Product Backlog  
**Business Rank:** 041

#### User Story

**As a** returning user
**I need** Hydrion to track consecutive days meeting the hydration target
**So that** I can maintain a healthy habit over time.

#### Description

* Streak tracking rewards repeated daily progress so users can see consistency over time, not just a single day's intake.
* The current implementation is local and lightweight; it should not claim social streaks, cloud history, or cross-device recovery.

#### Details and Business Rules

* Analytics computes streak days by checking up to 30 days backward.
* a seven-day streak unlocks a displayed achievement badge.
* Business rule: Streaks are calculated from locally available log history only.
#### Data and State Requirements

* Local application state must remain scoped to Hydrion repositories and the `shared_preferences` backed local store unless the story explicitly says otherwise.
* Provider-facing state must avoid persisted production secrets and must preserve local fallback behavior.
* Integration state must be represented through capability status, adapter contracts, or disabled placeholders until a real adapter is implemented.

#### Assumptions

* No additional product assumption is made beyond the repository evidence and explicit out-of-scope notes.

#### Acceptance Criteria

- [x] The streak count increments until the first non-target day.
- [x] The seven-day streak badge is unlocked.

#### Acceptance Criteria Coverage

* Checked acceptance criteria: 2.
* Unchecked acceptance criteria: 0.
* Checked criteria are tied to the repository evidence listed in this story.
* Unchecked criteria represent work or verification still needed before the criterion can be claimed complete.

#### Dependencies

* `HYD-US-004`
* `HYD-US-013`

#### Non-Functional Requirements

* Keep the behavior offline-tolerant and honest about local-first limits.
* Keep user-visible behavior responsive on the supported web and Android MVP targets.
* Do not expose secrets, provider diagnostics, or disabled integrations in a misleading way.

#### Out of Scope

* Streak repair, pause days, notifications for streak risk, or persisted streak history.

#### Repository Evidence

* `lib/ui/screens/analytics_screen.dart`
* `lib/ui/components/achievement_badge.dart`

#### Story Quality Checklist

- [x] returning user and outcome are specific to Track Daily Goal Streaks.
- [x] Scope is bounded to Implemented Supporting behavior: Streak tracking rewards repeated daily progress so users can see consistency over time, not just a....
- [x] Primary dependency is `HYD-US-004`; full dependency list is explicit.
- [x] Checked claims cite repository evidence beginning with `lib/ui/screens/analytics_screen.dart`.
- [x] Acceptance coverage is 2/2; 0 acceptance criteria remain open.

#### INVEST Check

- [x] Independent: 2 listed dependency link(s) for Track Daily Goal Streaks.
- [x] Negotiable: implementation detail stays in repository evidence, not hidden in the User Story title.
- [x] Valuable: returning user needs Hydrion to track consecutive days meeting the hydration target so I can maintain a healthy habit over time.
- [x] Estimable: story size is 2 with evidence and open criteria visible.
- [x] Small: size 2 is within a focused slice.
- [ ] Testable: 2 checkbox criterion/criteria and planned verification are listed.

#### Definition of Ready

- [x] Metadata is complete: P1, Supporting, MVP Product UX, Product Backlog rank 041, size 2.
- [x] Dependencies are named for sequencing; first dependency is `HYD-US-004`.
- [x] Acceptance criteria are checkbox-based and currently 2 checked / 0 unchecked.
- [x] Repository evidence is available for current claims; first evidence item is `lib/ui/screens/analytics_screen.dart`.
- [x] Ready state reflects Implemented: ready to pull or maintain.

#### Definition of Done

- [x] Implementation status is Implemented for Track Daily Goal Streaks.
- [x] All acceptance criteria are checked for this story (2/2).
- [ ] Verification evidence includes no automated test/CI evidence yet.
- [x] Project workflow metadata is valid: Product Backlog, rank 041, size 2.
- [ ] Done means implemented, verified, and no open criteria for Track Daily Goal Streaks.

### HYD-US-013: Display Local Achievement Badges

**Epic:** Streaks and Achievements  
**Story Type:** User Story  
**Implementation Status:** Implemented  
**Priority:** P1  
**Release Scope:** Supporting
**Labels:** `user-story`, `type:user-story`, `priority:p1`, `status:implemented`, `scope:supporting`, `area:analytics`, `area:engagement`, `size:2`  
**Milestone:** MVP Product UX
**Story Size:** 2
**Project Column:** Product Backlog  
**Business Rank:** 042

#### User Story

**As a** application user
**I need** visible achievement badges based on local hydration behavior
**So that** Hydrion reinforces useful logging and intake habits.

#### Description

* Achievement badges give lightweight recognition for local hydration milestones and make analytics feel less sterile.
* Badges must stay tied to real local criteria rather than arbitrary or provider-generated praise.

#### Details and Business Rules

* current badges are 2L day, 3 logs today, and 7 day streak.
* badge semantics include badge name and locked/unlocked status.
* Business rule: A badge is shown only when its local achievement condition is satisfied.
#### Data and State Requirements

* Integration state must be represented through capability status, adapter contracts, or disabled placeholders until a real adapter is implemented.

#### Assumptions

* No additional product assumption is made beyond the repository evidence and explicit out-of-scope notes.

#### Acceptance Criteria

- [x] The 2L day badge is unlocked.
- [x] The 3 logs today badge is unlocked.
- [x] It appears locked with appropriate accessible semantics.

#### Acceptance Criteria Coverage

* Checked acceptance criteria: 3.
* Unchecked acceptance criteria: 0.
* Checked criteria are tied to the repository evidence listed in this story.
* Unchecked criteria represent work or verification still needed before the criterion can be claimed complete.

#### Dependencies

* `HYD-US-004`
* `HYD-US-012`

#### Non-Functional Requirements

* Keep the behavior offline-tolerant and honest about local-first limits.
* Keep user-visible behavior responsive on the supported web and Android MVP targets.
* Do not expose secrets, provider diagnostics, or disabled integrations in a misleading way.

#### Out of Scope

* Achievement sound effects, sharing, backend leaderboards, or unlock history.

#### Repository Evidence

* `lib/ui/screens/analytics_screen.dart`
* `lib/ui/components/achievement_badge.dart`
* `lib/l10n/app_en.arb`

#### Story Quality Checklist

- [x] application user and outcome are specific to Display Local Achievement Badges.
- [x] Scope is bounded to Implemented Supporting behavior: Achievement badges give lightweight recognition for local hydration milestones and make analytics feel less sterile..
- [x] Primary dependency is `HYD-US-004`; full dependency list is explicit.
- [x] Checked claims cite repository evidence beginning with `lib/ui/screens/analytics_screen.dart`.
- [x] Acceptance coverage is 3/3; 0 acceptance criteria remain open.

#### INVEST Check

- [x] Independent: 2 listed dependency link(s) for Display Local Achievement Badges.
- [x] Negotiable: implementation detail stays in repository evidence, not hidden in the User Story title.
- [x] Valuable: application user needs visible achievement badges based on local hydration behavior so Hydrion reinforces useful logging and intake habits.
- [x] Estimable: story size is 2 with evidence and open criteria visible.
- [x] Small: size 2 is within a focused slice.
- [ ] Testable: 3 checkbox criterion/criteria and planned verification are listed.

#### Definition of Ready

- [x] Metadata is complete: P1, Supporting, MVP Product UX, Product Backlog rank 042, size 2.
- [x] Dependencies are named for sequencing; first dependency is `HYD-US-004`.
- [x] Acceptance criteria are checkbox-based and currently 3 checked / 0 unchecked.
- [x] Repository evidence is available for current claims; first evidence item is `lib/ui/screens/analytics_screen.dart`.
- [x] Ready state reflects Implemented: ready to pull or maintain.

#### Definition of Done

- [x] Implementation status is Implemented for Display Local Achievement Badges.
- [x] All acceptance criteria are checked for this story (3/3).
- [ ] Verification evidence includes no automated test/CI evidence yet.
- [x] Project workflow metadata is valid: Product Backlog, rank 042, size 2.
- [ ] Done means implemented, verified, and no open criteria for Display Local Achievement Badges.

### HYD-US-014: Estimate Eco Impact From Local Logs

**Epic:** Eco-Impact Tracking  
**Story Type:** User Story  
**Implementation Status:** Implemented  
**Priority:** P2  
**Release Scope:** Supporting
**Labels:** `user-story`, `type:user-story`, `priority:p2`, `status:implemented`, `scope:supporting`, `area:analytics`, `area:eco-impact`, `size:1`  
**Milestone:** MVP Product UX
**Story Size:** 1
**Project Column:** Product Backlog  
**Business Rank:** 043

#### User Story

**As a** sustainability-minded user
**I need** an environmental impact estimate from my logged hydration
**So that** I can see a simple local estimate of plastic saved.

#### Description

* Eco-impact estimates translate logged hydration into an approximate sustainability signal for users who care about reusable-bottle habits.
* The feature should remain framed as an estimate and avoid scientific precision claims the repository does not support.

#### Details and Business Rules

* eco estimate uses total lifetime ml from `HydrationRepository`.
* the formula treats each 500 ml as an avoided half-liter bottle and estimates 0.01 kg plastic saved per bottle.
* Business rule: Eco impact values are derived estimates and must not be presented as audited environmental measurements.
#### Data and State Requirements

* Local application state must remain scoped to Hydrion repositories and the `shared_preferences` backed local store unless the story explicitly says otherwise.
* Integration state must be represented through capability status, adapter contracts, or disabled placeholders until a real adapter is implemented.

#### Assumptions

* this is a rough local estimate, not a verified environmental audit.

#### Acceptance Criteria

- [x] It returns approximately 0.01 kg.
- [x] It shows 0.00 kg and explains the value is a local estimate from logs.

#### Acceptance Criteria Coverage

* Checked acceptance criteria: 2.
* Unchecked acceptance criteria: 0.
* Checked criteria are tied to the repository evidence listed in this story.
* Unchecked criteria represent work or verification still needed before the criterion can be claimed complete.

#### Dependencies

* `HYD-US-004`
* `HYD-US-010`

#### Non-Functional Requirements

* Keep the behavior offline-tolerant and honest about local-first limits.
* Keep user-visible behavior responsive on the supported web and Android MVP targets.
* Do not expose secrets, provider diagnostics, or disabled integrations in a misleading way.

#### Out of Scope

* Carbon accounting, bottle-material customization, or remote sustainability services.

#### Repository Evidence

* `lib/services/eco_tracker.dart`
* `lib/services/core_bridge.dart`
* `lib/ui/screens/analytics_screen.dart`
* `test/persistence_test.dart`

#### Story Quality Checklist

- [x] sustainability-minded user and outcome are specific to Estimate Eco Impact From Local Logs.
- [x] Scope is bounded to Implemented Supporting behavior: Eco-impact estimates translate logged hydration into an approximate sustainability signal for users who care about reusable-bottle....
- [x] Primary dependency is `HYD-US-004`; full dependency list is explicit.
- [x] Checked claims cite repository evidence beginning with `lib/services/eco_tracker.dart`.
- [x] Acceptance coverage is 2/2; 0 acceptance criteria remain open.

#### INVEST Check

- [x] Independent: 2 listed dependency link(s) for Estimate Eco Impact From Local Logs.
- [x] Negotiable: implementation detail stays in repository evidence, not hidden in the User Story title.
- [x] Valuable: sustainability-minded user needs an environmental impact estimate from my logged hydration so I can see a simple local estimate of plastic saved.
- [x] Estimable: story size is 1 with evidence and open criteria visible.
- [x] Small: size 1 is within a focused slice.
- [x] Testable: 2 checkbox criterion/criteria and test/build evidence are listed.

#### Definition of Ready

- [x] Metadata is complete: P2, Supporting, MVP Product UX, Product Backlog rank 043, size 1.
- [x] Dependencies are named for sequencing; first dependency is `HYD-US-004`.
- [x] Acceptance criteria are checkbox-based and currently 2 checked / 0 unchecked.
- [x] Repository evidence is available for current claims; first evidence item is `lib/services/eco_tracker.dart`.
- [x] Ready state reflects Implemented: ready to pull or maintain.

#### Definition of Done

- [x] Implementation status is Implemented for Estimate Eco Impact From Local Logs.
- [x] All acceptance criteria are checked for this story (2/2).
- [x] Verification evidence includes automated tests or CI/docs.
- [x] Project workflow metadata is valid: Product Backlog, rank 043, size 1.
- [x] Done means implemented, verified, and no open criteria for Estimate Eco Impact From Local Logs.

### HYD-US-015: Save Local Reminder Definitions

**Epic:** Reminders  
**Story Type:** User Story  
**Implementation Status:** Implemented  
**Priority:** P1  
**Release Scope:** MVP
**Labels:** `user-story`, `type:user-story`, `priority:p1`, `status:implemented`, `scope:mvp`, `area:reminders`, `area:persistence`, `size:3`  
**Milestone:** MVP Product UX
**Story Size:** 3
**Project Column:** Product Backlog  
**Business Rank:** 020

#### User Story

**As a** application user
**I need** Hydrion to save local reminder definitions based on hydration context
**So that** I can review hydration nudges even when OS notifications are unavailable.

#### Description

* Users can save reminder definitions locally so Hydrion can remember their intended hydration prompts even before OS notification scheduling exists.
* The story separates reminder data management from actual native notification delivery.

#### Details and Business Rules

* Home reminder tile calls `NotificationService.scheduleReminder`.
* reminder policy computes urgency, delay, message, and priority from shortfall, last drink age, hydration percent, and active time.
* reminder definitions persist under `hydrion.reminders.v1`.
* Business rule: Saving a reminder creates a local definition only; it does not schedule an OS notification.
#### Data and State Requirements

* Local application state must remain scoped to Hydrion repositories and the `shared_preferences` backed local store unless the story explicitly says otherwise.
* Integration state must be represented through capability status, adapter contracts, or disabled placeholders until a real adapter is implemented.

#### Assumptions

* No additional product assumption is made beyond the repository evidence and explicit out-of-scope notes.

#### Acceptance Criteria

- [x] A local reminder definition is saved with trigger time, message, and priority.
- [x] The reminder definition is restored from local storage.
- [x] The confirmation message says the definition is local only.

#### Acceptance Criteria Coverage

* Checked acceptance criteria: 3.
* Unchecked acceptance criteria: 0.
* Checked criteria are tied to the repository evidence listed in this story.
* Unchecked criteria represent work or verification still needed before the criterion can be claimed complete.

#### Dependencies

* `ReminderRepository`
* `NotificationService`
* `HYD-US-017`

#### Non-Functional Requirements

* Keep the behavior offline-tolerant and honest about local-first limits.
* Keep user-visible behavior responsive on the supported web and Android MVP targets.
* Do not expose secrets, provider diagnostics, or disabled integrations in a misleading way.

#### Out of Scope

* Real platform notification delivery, snooze, recurring schedules, or quiet-hour enforcement.

#### Repository Evidence

* `lib/services/notifications.dart`
* `lib/services/policy_service.dart`
* `lib/repositories/reminder_repository.dart`
* `lib/ui/components/reminder_tile.dart`
* `test/persistence_test.dart`
* `test/runtime_ux_test.dart`

#### Story Quality Checklist

- [x] application user and outcome are specific to Save Local Reminder Definitions.
- [x] Scope is bounded to Implemented MVP behavior: Users can save reminder definitions locally so Hydrion can remember their intended hydration prompts even before....
- [x] Primary dependency is `ReminderRepository`; full dependency list is explicit.
- [x] Checked claims cite repository evidence beginning with `lib/services/notifications.dart`.
- [x] Acceptance coverage is 3/3; 0 acceptance criteria remain open.

#### INVEST Check

- [x] Independent: 3 listed dependency link(s) for Save Local Reminder Definitions.
- [x] Negotiable: implementation detail stays in repository evidence, not hidden in the User Story title.
- [x] Valuable: application user needs Hydrion to save local reminder definitions based on hydration context so I can review hydration nudges even when OS notifications are unavailable.
- [x] Estimable: story size is 3 with evidence and open criteria visible.
- [x] Small: size 3 is within a focused slice.
- [x] Testable: 3 checkbox criterion/criteria and test/build evidence are listed.

#### Definition of Ready

- [x] Metadata is complete: P1, MVP, MVP Product UX, Product Backlog rank 020, size 3.
- [x] Dependencies are named for sequencing; first dependency is `ReminderRepository`.
- [x] Acceptance criteria are checkbox-based and currently 3 checked / 0 unchecked.
- [x] Repository evidence is available for current claims; first evidence item is `lib/services/notifications.dart`.
- [x] Ready state reflects Implemented: ready to pull or maintain.

#### Definition of Done

- [x] Implementation status is Implemented for Save Local Reminder Definitions.
- [x] All acceptance criteria are checked for this story (3/3).
- [x] Verification evidence includes automated tests or CI/docs.
- [x] Project workflow metadata is valid: Product Backlog, rank 020, size 3.
- [x] Done means implemented, verified, and no open criteria for Save Local Reminder Definitions.

### HYD-US-016: Manage Saved Reminder Definitions

**Epic:** Reminders  
**Story Type:** User Story  
**Implementation Status:** Implemented  
**Priority:** P1  
**Release Scope:** MVP
**Labels:** `user-story`, `type:user-story`, `priority:p1`, `status:implemented`, `scope:mvp`, `area:reminders`, `area:persistence`, `size:3`  
**Milestone:** MVP Product UX
**Story Size:** 3
**Project Column:** Product Backlog  
**Business Rank:** 021

#### User Story

**As a** returning user
**I need** to view and delete saved local reminder definitions
**So that** stale reminders do not clutter my local app state.

#### Description

* The reminders screen lets users review and remove saved local reminder definitions so stale prompts do not accumulate.
* Management actions must operate on local reminder state and make the disabled notification boundary visible.

#### Details and Business Rules

* Reminders screen lists saved reminders with timestamp and priority.
* the screen displays an empty state when none exist.
* delete removes the reminder and persists the change.
* Business rule: Deleting a reminder removes the local definition and must not imply cancellation of an OS notification that was never scheduled.
#### Data and State Requirements

* Local application state must remain scoped to Hydrion repositories and the `shared_preferences` backed local store unless the story explicitly says otherwise.
* Integration state must be represented through capability status, adapter contracts, or disabled placeholders until a real adapter is implemented.

#### Assumptions

* No additional product assumption is made beyond the repository evidence and explicit out-of-scope notes.

#### Acceptance Criteria

- [x] Each reminder shows message, trigger timestamp, priority, and delete action.
- [x] The reminder is removed and a localized confirmation appears.
- [x] Hydrion shows the local reminder empty state.

#### Acceptance Criteria Coverage

* Checked acceptance criteria: 3.
* Unchecked acceptance criteria: 0.
* Checked criteria are tied to the repository evidence listed in this story.
* Unchecked criteria represent work or verification still needed before the criterion can be claimed complete.

#### Dependencies

* `HYD-US-015`

#### Non-Functional Requirements

* Keep the behavior offline-tolerant and honest about local-first limits.
* Keep user-visible behavior responsive on the supported web and Android MVP targets.
* Do not expose secrets, provider diagnostics, or disabled integrations in a misleading way.

#### Out of Scope

* Editing reminder definitions or scheduling native notifications.

#### Repository Evidence

* `lib/ui/screens/reminders_screen.dart`
* `lib/repositories/reminder_repository.dart`
* `test/runtime_ux_test.dart`

#### Story Quality Checklist

- [x] returning user and outcome are specific to Manage Saved Reminder Definitions.
- [x] Scope is bounded to Implemented MVP behavior: The reminders screen lets users review and remove saved local reminder definitions so stale prompts do....
- [x] Primary dependency is `HYD-US-015`; full dependency list is explicit.
- [x] Checked claims cite repository evidence beginning with `lib/ui/screens/reminders_screen.dart`.
- [x] Acceptance coverage is 3/3; 0 acceptance criteria remain open.

#### INVEST Check

- [x] Independent: 1 listed dependency link(s) for Manage Saved Reminder Definitions.
- [x] Negotiable: implementation detail stays in repository evidence, not hidden in the User Story title.
- [x] Valuable: returning user needs to view and delete saved local reminder definitions so stale reminders do not clutter my local app state.
- [x] Estimable: story size is 3 with evidence and open criteria visible.
- [x] Small: size 3 is within a focused slice.
- [x] Testable: 3 checkbox criterion/criteria and test/build evidence are listed.

#### Definition of Ready

- [x] Metadata is complete: P1, MVP, MVP Product UX, Product Backlog rank 021, size 3.
- [x] Dependencies are named for sequencing; first dependency is `HYD-US-015`.
- [x] Acceptance criteria are checkbox-based and currently 3 checked / 0 unchecked.
- [x] Repository evidence is available for current claims; first evidence item is `lib/ui/screens/reminders_screen.dart`.
- [x] Ready state reflects Implemented: ready to pull or maintain.

#### Definition of Done

- [x] Implementation status is Implemented for Manage Saved Reminder Definitions.
- [x] All acceptance criteria are checked for this story (3/3).
- [x] Verification evidence includes automated tests or CI/docs.
- [x] Project workflow metadata is valid: Product Backlog, rank 021, size 3.
- [x] Done means implemented, verified, and no open criteria for Manage Saved Reminder Definitions.

### HYD-US-017: Gate OS Notification Scheduling

**Epic:** Reminders  
**Story Type:** System Story  
**Implementation Status:** Gated  
**Priority:** P1  
**Release Scope:** Supporting
**Labels:** `user-story`, `type:system`, `priority:p1`, `status:gated`, `scope:supporting`, `area:reminders`, `area:persistence`, `area:platform`, `area:native-integrations`, `size:5`  
**Milestone:** Post-MVP Native Integrations
**Story Size:** 5
**Project Column:** Ice Box  
**Business Rank:** 001

#### User Story

**As a** Hydrion stakeholder
**I need** Hydrion to clearly distinguish local reminders from real OS notifications
**So that** I do not expect a device alert that will not fire.

#### Description

* Notification scheduling is deliberately gated until a real platform adapter, permissions flow, and tests exist.
* The product should expose the boundary honestly so users and maintainers do not confuse stored reminders with delivered notifications.

#### Details and Business Rules

* `NotificationService.supportsOsNotifications` returns false.
* standalone capabilities set `osNotifications` to false.
* Settings and Reminders copy state that definitions remain local.
* Business rule: OS notification delivery remains unavailable until adapter implementation, permission handling, and release validation are complete.
#### Data and State Requirements

* Local application state must remain scoped to Hydrion repositories and the `shared_preferences` backed local store unless the story explicitly says otherwise.
* Provider-facing state must avoid persisted production secrets and must preserve local fallback behavior.
* Integration state must be represented through capability status, adapter contracts, or disabled placeholders until a real adapter is implemented.

#### Assumptions

* real notification scheduling is a post-MVP adapter requiring permissions and platform tests.

#### Acceptance Criteria

- [x] OS notifications are labeled disabled.
- [x] The action is rejected because OS notifications are unavailable.
- [x] The UI must distinguish configured capability from actual scheduling support.
- [ ] Remaining end-to-end user behavior for this story is implemented, verified, and ready for release..

#### Acceptance Criteria Coverage

* Checked acceptance criteria: 3.
* Unchecked acceptance criteria: 1.
* Checked criteria are tied to the repository evidence listed in this story.
* Unchecked criteria represent work or verification still needed before the criterion can be claimed complete.

#### Dependencies

* `HYD-US-015`
* `HYD-US-031`

#### Non-Functional Requirements

* Keep the behavior offline-tolerant and honest about local-first limits.
* Keep user-visible behavior responsive on the supported web and Android MVP targets.
* Do not expose secrets, provider diagnostics, or disabled integrations in a misleading way.
* Preserve capability gating until the unchecked acceptance criteria are implemented and verified.

#### Out of Scope

* Implementing platform notification permissions, repeat rules, cancellation, or background delivery.

#### Repository Evidence

* `lib/services/notifications.dart`
* `lib/domain/hydration_contracts.dart`
* `lib/ui/screens/reminders_screen.dart`
* `test/adapter_contract_test.dart`
* `HYDRION_MVP_KANBAN_ROADMAP.md`

#### Story Quality Checklist

- [x] Hydrion stakeholder and outcome are specific to Gate OS Notification Scheduling.
- [x] Scope is bounded to Gated Supporting behavior: Notification scheduling is deliberately gated until a real platform adapter, permissions flow, and tests exist..
- [x] Primary dependency is `HYD-US-015`; full dependency list is explicit.
- [x] Checked claims cite repository evidence beginning with `lib/services/notifications.dart`.
- [ ] Acceptance coverage is 3/4; 1 acceptance criterion remains open.

#### INVEST Check

- [x] Independent: 2 listed dependency link(s) for Gate OS Notification Scheduling.
- [x] Negotiable: implementation detail stays in repository evidence, not hidden in the System Story title.
- [x] Valuable: Hydrion stakeholder needs Hydrion to clearly distinguish local reminders from real OS notifications so I do not expect a device alert that will not fire.
- [x] Estimable: story size is 5 with evidence and open criteria visible.
- [x] Small: size 5 is within a focused slice.
- [x] Testable: 4 checkbox criterion/criteria and test/build evidence are listed.

#### Definition of Ready

- [x] Metadata is complete: P1, Supporting, Post-MVP Native Integrations, Ice Box rank 001, size 5.
- [x] Dependencies are named for sequencing; first dependency is `HYD-US-015`.
- [x] Acceptance criteria are checkbox-based and currently 3 checked / 1 unchecked.
- [x] Repository evidence is available for current claims; first evidence item is `lib/services/notifications.dart`.
- [x] Ready state reflects Gated: ready to pull or maintain.

#### Definition of Done

- [ ] Implementation status is Implemented for Gate OS Notification Scheduling.
- [ ] All acceptance criteria are checked for this story (3/4).
- [x] Verification evidence includes automated tests or CI/docs.
- [x] Project workflow metadata is valid: Ice Box, rank 001, size 5.
- [ ] Done means implemented, verified, and no open criteria for Gate OS Notification Scheduling.

### HYD-US-018: Join a Local Hydration Challenge

**Epic:** Challenges  
**Story Type:** User Story  
**Implementation Status:** Implemented  
**Priority:** P1  
**Release Scope:** MVP
**Labels:** `user-story`, `type:user-story`, `priority:p1`, `status:implemented`, `scope:mvp`, `area:challenges`, `area:persistence`, `area:frontend`, `size:3`  
**Milestone:** MVP Product UX
**Story Size:** 3
**Project Column:** Product Backlog  
**Business Rank:** 022

#### User Story

**As a** motivation-focused user
**I need** to join a local hydration challenge
**So that** I can pursue a short-term goal without social sync or backend accounts.

#### Description

* Users can join a local hydration challenge to add lightweight engagement without requiring a social backend.
* Challenge state is local and should support progress feedback while avoiding claims about real multiplayer or shared leaderboards.

#### Details and Business Rules

* local challenge generator creates a Seven Day Steady Sip challenge.
* beginner challenge target is 2000 ml/day for 7 days; other levels exist in the generator.
* UI exposes a Join action and persists one active challenge.
* Business rule: Joining a challenge creates local challenge state only.
#### Data and State Requirements

* Local application state must remain scoped to Hydrion repositories and the `shared_preferences` backed local store unless the story explicitly says otherwise.
* Integration state must be represented through capability status, adapter contracts, or disabled placeholders until a real adapter is implemented.

#### Assumptions

* No additional product assumption is made beyond the repository evidence and explicit out-of-scope notes.

#### Acceptance Criteria

- [x] Hydrion shows local challenge mode and a joinable local challenge.
- [x] The challenge is marked joined and persisted locally.
- [x] It states challenge progress is saved on this device.

#### Acceptance Criteria Coverage

* Checked acceptance criteria: 3.
* Unchecked acceptance criteria: 0.
* Checked criteria are tied to the repository evidence listed in this story.
* Unchecked criteria represent work or verification still needed before the criterion can be claimed complete.

#### Dependencies

* `ChallengeRepository`
* `ChallengeGenerator`
* `HYD-US-031`

#### Non-Functional Requirements

* Keep the behavior offline-tolerant and honest about local-first limits.
* Keep user-visible behavior responsive on the supported web and Android MVP targets.
* Do not expose secrets, provider diagnostics, or disabled integrations in a misleading way.

#### Out of Scope

* Multiplayer/social invitations, leaderboards, or remote challenge catalogs.

#### Repository Evidence

* `lib/adapters/local/local_hydrion_adapters.dart`
* `lib/repositories/challenge_repository.dart`
* `lib/ui/screens/social_challenges_screen.dart`
* `test/runtime_ux_test.dart`
* `test/persistence_test.dart`

#### Story Quality Checklist

- [x] motivation-focused user and outcome are specific to Join a Local Hydration Challenge.
- [x] Scope is bounded to Implemented MVP behavior: Users can join a local hydration challenge to add lightweight engagement without requiring a social backend..
- [x] Primary dependency is `ChallengeRepository`; full dependency list is explicit.
- [x] Checked claims cite repository evidence beginning with `lib/adapters/local/local_hydrion_adapters.dart`.
- [x] Acceptance coverage is 3/3; 0 acceptance criteria remain open.

#### INVEST Check

- [x] Independent: 3 listed dependency link(s) for Join a Local Hydration Challenge.
- [x] Negotiable: implementation detail stays in repository evidence, not hidden in the User Story title.
- [x] Valuable: motivation-focused user needs to join a local hydration challenge so I can pursue a short-term goal without social sync or backend accounts.
- [x] Estimable: story size is 3 with evidence and open criteria visible.
- [x] Small: size 3 is within a focused slice.
- [x] Testable: 3 checkbox criterion/criteria and test/build evidence are listed.

#### Definition of Ready

- [x] Metadata is complete: P1, MVP, MVP Product UX, Product Backlog rank 022, size 3.
- [x] Dependencies are named for sequencing; first dependency is `ChallengeRepository`.
- [x] Acceptance criteria are checkbox-based and currently 3 checked / 0 unchecked.
- [x] Repository evidence is available for current claims; first evidence item is `lib/adapters/local/local_hydrion_adapters.dart`.
- [x] Ready state reflects Implemented: ready to pull or maintain.

#### Definition of Done

- [x] Implementation status is Implemented for Join a Local Hydration Challenge.
- [x] All acceptance criteria are checked for this story (3/3).
- [x] Verification evidence includes automated tests or CI/docs.
- [x] Project workflow metadata is valid: Product Backlog, rank 022, size 3.
- [x] Done means implemented, verified, and no open criteria for Join a Local Hydration Challenge.

### HYD-US-019: Track Local Challenge Progress

**Epic:** Challenges  
**Story Type:** User Story  
**Implementation Status:** Implemented  
**Priority:** P1  
**Release Scope:** MVP
**Labels:** `user-story`, `type:user-story`, `priority:p1`, `status:implemented`, `scope:mvp`, `area:challenges`, `area:persistence`, `area:frontend`, `size:3`  
**Milestone:** MVP Product UX
**Story Size:** 3
**Project Column:** Product Backlog  
**Business Rank:** 023

#### User Story

**As a** returning user in a challenge
**I need** challenge progress to update from saved hydration logs
**So that** I know how many challenge days I have completed.

#### Description

* Challenge progress uses local hydration logs so users can see whether their current activity is moving the challenge forward.
* The calculation must remain consistent with the repository's local-first challenge model.

#### Details and Business Rules

* progress counts completed days where local day total meets the challenge target.
* progress includes completed days, duration days, today's ml, and target ml.
* Business rule: Challenge progress is computed from local joined challenge state and local hydration logs.
#### Data and State Requirements

* Local application state must remain scoped to Hydrion repositories and the `shared_preferences` backed local store unless the story explicitly says otherwise.
* Integration state must be represented through capability status, adapter contracts, or disabled placeholders until a real adapter is implemented.

#### Assumptions

* No additional product assumption is made beyond the repository evidence and explicit out-of-scope notes.

#### Acceptance Criteria

- [x] The progress calculation counts that day as complete.
- [x] Hydrion shows today's ml against the challenge target.
- [x] Hydrion returns zero completed days and zero target context.

#### Acceptance Criteria Coverage

* Checked acceptance criteria: 3.
* Unchecked acceptance criteria: 0.
* Checked criteria are tied to the repository evidence listed in this story.
* Unchecked criteria represent work or verification still needed before the criterion can be claimed complete.

#### Dependencies

* `HYD-US-004`
* `HYD-US-018`

#### Non-Functional Requirements

* Keep the behavior offline-tolerant and honest about local-first limits.
* Keep user-visible behavior responsive on the supported web and Android MVP targets.
* Do not expose secrets, provider diagnostics, or disabled integrations in a misleading way.

#### Out of Scope

* Time-zone migration, challenge completion history, or remote progress sync.

#### Repository Evidence

* `lib/repositories/challenge_repository.dart`
* `lib/ui/screens/social_challenges_screen.dart`
* `lib/services/hydration_context_builder.dart`

#### Story Quality Checklist

- [x] returning user in a challenge and outcome are specific to Track Local Challenge Progress.
- [x] Scope is bounded to Implemented MVP behavior: Challenge progress uses local hydration logs so users can see whether their current activity is moving....
- [x] Primary dependency is `HYD-US-004`; full dependency list is explicit.
- [x] Checked claims cite repository evidence beginning with `lib/repositories/challenge_repository.dart`.
- [x] Acceptance coverage is 3/3; 0 acceptance criteria remain open.

#### INVEST Check

- [x] Independent: 2 listed dependency link(s) for Track Local Challenge Progress.
- [x] Negotiable: implementation detail stays in repository evidence, not hidden in the User Story title.
- [x] Valuable: returning user in a challenge needs challenge progress to update from saved hydration logs so I know how many challenge days I have completed.
- [x] Estimable: story size is 3 with evidence and open criteria visible.
- [x] Small: size 3 is within a focused slice.
- [ ] Testable: 3 checkbox criterion/criteria and planned verification are listed.

#### Definition of Ready

- [x] Metadata is complete: P1, MVP, MVP Product UX, Product Backlog rank 023, size 3.
- [x] Dependencies are named for sequencing; first dependency is `HYD-US-004`.
- [x] Acceptance criteria are checkbox-based and currently 3 checked / 0 unchecked.
- [x] Repository evidence is available for current claims; first evidence item is `lib/repositories/challenge_repository.dart`.
- [x] Ready state reflects Implemented: ready to pull or maintain.

#### Definition of Done

- [x] Implementation status is Implemented for Track Local Challenge Progress.
- [x] All acceptance criteria are checked for this story (3/3).
- [ ] Verification evidence includes no automated test/CI evidence yet.
- [x] Project workflow metadata is valid: Product Backlog, rank 023, size 3.
- [ ] Done means implemented, verified, and no open criteria for Track Local Challenge Progress.

### HYD-US-020: Leave Challenges and Keep Completion History

**Epic:** Challenges  
**Story Type:** User Story  
**Implementation Status:** Partial  
**Priority:** P2  
**Release Scope:** Supporting
**Labels:** `user-story`, `type:user-story`, `priority:p2`, `status:partial`, `scope:supporting`, `area:challenges`, `area:persistence`, `area:frontend`, `size:5`  
**Milestone:** MVP Product UX
**Story Size:** 5
**Project Column:** Product Backlog  
**Business Rank:** 038

#### User Story

**As a** challenge participant
**I need** to leave a challenge and retain local completion history
**So that** challenge state remains controllable and auditable.

#### Description

* Users eventually need a complete challenge lifecycle: leaving a challenge and retaining meaningful completion history.
* The repository has partial challenge support, but the end-to-end leave/history workflow is not yet exposed as a finished user capability.

#### Details and Business Rules

* `ChallengeRepository.leave()` can clear the active challenge.
* roadmap notes missing local challenge leave, completion, and history work.
* Business rule: Do not mark challenge lifecycle complete until leave behavior, completion history, and user-facing recovery states are implemented and verified.
#### Data and State Requirements

* Local application state must remain scoped to Hydrion repositories and the `shared_preferences` backed local store unless the story explicitly says otherwise.
* Integration state must be represented through capability status, adapter contracts, or disabled placeholders until a real adapter is implemented.

#### Assumptions

* No additional product assumption is made beyond the repository evidence and explicit out-of-scope notes.

#### Acceptance Criteria

- [x] The active challenge is cleared from local state.
- [x] Completion history is saved locally without requiring social sync.
- [ ] Hydrion must not claim challenge history is available.
- [ ] Remaining end-to-end user behavior for this story is implemented, verified, and ready for release..

#### Acceptance Criteria Coverage

* Checked acceptance criteria: 2.
* Unchecked acceptance criteria: 2.
* Checked criteria are tied to the repository evidence listed in this story.
* Unchecked criteria represent work or verification still needed before the criterion can be claimed complete.

#### Dependencies

* `HYD-US-018`
* `HYD-US-019`

#### Non-Functional Requirements

* Keep the behavior offline-tolerant and honest about local-first limits.
* Keep user-visible behavior responsive on the supported web and Android MVP targets.
* Do not expose secrets, provider diagnostics, or disabled integrations in a misleading way.
* Preserve capability gating until the unchecked acceptance criteria are implemented and verified.

#### Out of Scope

* Social challenge history, remote moderation, or backend achievements.

#### Repository Evidence

* `lib/repositories/challenge_repository.dart`
* `lib/ui/screens/social_challenges_screen.dart`
* `HYDRION_MVP_KANBAN_ROADMAP.md`

#### Story Quality Checklist

- [x] challenge participant and outcome are specific to Leave Challenges and Keep Completion History.
- [x] Scope is bounded to Partial Supporting behavior: Users eventually need a complete challenge lifecycle: leaving a challenge and retaining meaningful completion history..
- [x] Primary dependency is `HYD-US-018`; full dependency list is explicit.
- [x] Checked claims cite repository evidence beginning with `lib/repositories/challenge_repository.dart`.
- [ ] Acceptance coverage is 2/4; 2 acceptance criteria remain open.

#### INVEST Check

- [x] Independent: 2 listed dependency link(s) for Leave Challenges and Keep Completion History.
- [x] Negotiable: implementation detail stays in repository evidence, not hidden in the User Story title.
- [x] Valuable: challenge participant needs to leave a challenge and retain local completion history so challenge state remains controllable and auditable.
- [x] Estimable: story size is 5 with evidence and open criteria visible.
- [x] Small: size 5 is within a focused slice.
- [x] Testable: 4 checkbox criterion/criteria and planned verification are listed.

#### Definition of Ready

- [x] Metadata is complete: P2, Supporting, MVP Product UX, Product Backlog rank 038, size 5.
- [x] Dependencies are named for sequencing; first dependency is `HYD-US-018`.
- [x] Acceptance criteria are checkbox-based and currently 2 checked / 2 unchecked.
- [x] Repository evidence is available for current claims; first evidence item is `lib/repositories/challenge_repository.dart`.
- [x] Ready state reflects Partial: ready to pull or maintain.

#### Definition of Done

- [ ] Implementation status is Implemented for Leave Challenges and Keep Completion History.
- [ ] All acceptance criteria are checked for this story (2/4).
- [ ] Verification evidence includes no automated test/CI evidence yet.
- [x] Project workflow metadata is valid: Product Backlog, rank 038, size 5.
- [ ] Done means implemented, verified, and no open criteria for Leave Challenges and Keep Completion History.

### HYD-US-021: Show Local Hydration Advice on Home

**Epic:** Local Hydration Coach  
**Story Type:** User Story  
**Implementation Status:** Implemented  
**Priority:** P1  
**Release Scope:** MVP
**Labels:** `user-story`, `type:user-story`, `priority:p1`, `status:implemented`, `scope:mvp`, `area:coach`, `area:ai-provider`, `size:2`  
**Milestone:** MVP AI Provider Safety
**Story Size:** 2
**Project Column:** Product Backlog  
**Business Rank:** 024

#### User Story

**As a** application user
**I need** local hydration advice based on progress and entry count
**So that** I receive useful guidance without sending data off-device.

#### Description

* The home screen should surface local hydration advice that helps users decide what to do next without opening chat.
* Advice must be deterministic and safe when provider configuration is absent.

#### Details and Business Rules

* `LLMAdviceCard` uses `HydrationCoach`.
* local coach advice changes by hydration percent and adds context about heat and entry count.
* advice is localized on Home.
* failures render a retry UI.
* Business rule: Home advice must work through local rules or safe fallback and cannot require Gemini or another provider.
#### Data and State Requirements

* Provider-facing state must avoid persisted production secrets and must preserve local fallback behavior.
* Integration state must be represented through capability status, adapter contracts, or disabled placeholders until a real adapter is implemented.
* User-visible strings and locale state must remain compatible with generated localization resources and fallback rules.

#### Assumptions

* No additional product assumption is made beyond the repository evidence and explicit out-of-scope notes.

#### Acceptance Criteria

- [x] The advice is generated locally and localized for the active locale.
- [x] Hydrion shows a localized failure state with retry.
- [x] Cached advice is refreshed.

#### Acceptance Criteria Coverage

* Checked acceptance criteria: 3.
* Unchecked acceptance criteria: 0.
* Checked criteria are tied to the repository evidence listed in this story.
* Unchecked criteria represent work or verification still needed before the criterion can be claimed complete.

#### Dependencies

* `HYD-US-008`
* `HYD-US-029`

#### Non-Functional Requirements

* Keep the behavior offline-tolerant and honest about local-first limits.
* Keep user-visible behavior responsive on the supported web and Android MVP targets.
* Do not expose secrets, provider diagnostics, or disabled integrations in a misleading way.

#### Out of Scope

* Clinical advice, remote provider requirement, or raw prompt display.

#### Repository Evidence

* `lib/ui/components/llm_advice_card.dart`
* `lib/adapters/local/local_hydrion_adapters.dart`
* `lib/main.dart`
* `test/localization_test.dart`

#### Story Quality Checklist

- [x] application user and outcome are specific to Show Local Hydration Advice on Home.
- [x] Scope is bounded to Implemented MVP behavior: The home screen should surface local hydration advice that helps users decide what to do next....
- [x] Primary dependency is `HYD-US-008`; full dependency list is explicit.
- [x] Checked claims cite repository evidence beginning with `lib/ui/components/llm_advice_card.dart`.
- [x] Acceptance coverage is 3/3; 0 acceptance criteria remain open.

#### INVEST Check

- [x] Independent: 2 listed dependency link(s) for Show Local Hydration Advice on Home.
- [x] Negotiable: implementation detail stays in repository evidence, not hidden in the User Story title.
- [x] Valuable: application user needs local hydration advice based on progress and entry count so I receive useful guidance without sending data off-device.
- [x] Estimable: story size is 2 with evidence and open criteria visible.
- [x] Small: size 2 is within a focused slice.
- [x] Testable: 3 checkbox criterion/criteria and test/build evidence are listed.

#### Definition of Ready

- [x] Metadata is complete: P1, MVP, MVP AI Provider Safety, Product Backlog rank 024, size 2.
- [x] Dependencies are named for sequencing; first dependency is `HYD-US-008`.
- [x] Acceptance criteria are checkbox-based and currently 3 checked / 0 unchecked.
- [x] Repository evidence is available for current claims; first evidence item is `lib/ui/components/llm_advice_card.dart`.
- [x] Ready state reflects Implemented: ready to pull or maintain.

#### Definition of Done

- [x] Implementation status is Implemented for Show Local Hydration Advice on Home.
- [x] All acceptance criteria are checked for this story (3/3).
- [x] Verification evidence includes automated tests or CI/docs.
- [x] Project workflow metadata is valid: Product Backlog, rank 024, size 2.
- [x] Done means implemented, verified, and no open criteria for Show Local Hydration Advice on Home.

### HYD-US-022: Chat With Local Hydration Coach

**Epic:** Local Hydration Coach  
**Story Type:** User Story  
**Implementation Status:** Implemented  
**Priority:** P1  
**Release Scope:** MVP
**Labels:** `user-story`, `type:user-story`, `priority:p1`, `status:implemented`, `scope:mvp`, `area:coach`, `area:ai-provider`, `size:3`  
**Milestone:** MVP AI Provider Safety
**Story Size:** 3
**Project Column:** Product Backlog  
**Business Rank:** 025

#### User Story

**As a** local-first user
**I need** to ask a hydration coach question
**So that** I can receive deterministic guidance from saved local hydration context.

#### Description

* The coach screen gives users a conversational place to ask hydration questions and receive local guidance.
* The chat experience must stay bounded to hydration support and avoid acting as a medical or provider-controlled automation surface.

#### Details and Business Rules

* Coach screen shows today's ml, target, event count, selected provider, and active provider.
* local fallback replies include local deterministic mode and saved log summary.
* empty input and duplicate send while busy are ignored.
* provider errors show localized snack-bar errors or fallback notices.
* Business rule: Coach responses must remain within Hydrion validation and local/provider fallback boundaries.
#### Data and State Requirements

* Provider-facing state must avoid persisted production secrets and must preserve local fallback behavior.
* Integration state must be represented through capability status, adapter contracts, or disabled placeholders until a real adapter is implemented.

#### Assumptions

* No additional product assumption is made beyond the repository evidence and explicit out-of-scope notes.

#### Acceptance Criteria

- [x] Hydrion responds with deterministic local guidance based on saved logs.
- [x] No coach request is made.
- [x] Hydrion shows a localized fallback notice.

#### Acceptance Criteria Coverage

* Checked acceptance criteria: 3.
* Unchecked acceptance criteria: 0.
* Checked criteria are tied to the repository evidence listed in this story.
* Unchecked criteria represent work or verification still needed before the criterion can be claimed complete.

#### Dependencies

* `HYD-US-023`
* `HYD-US-031`

#### Non-Functional Requirements

* Keep the behavior offline-tolerant and honest about local-first limits.
* Keep user-visible behavior responsive on the supported web and Android MVP targets.
* Do not expose secrets, provider diagnostics, or disabled integrations in a misleading way.

#### Out of Scope

* Long-term chat memory, cloud chat history, or free-form provider tool execution.

#### Repository Evidence

* `lib/ui/screens/chat_coach_screen.dart`
* `lib/adapters/local/local_hydrion_adapters.dart`
* `lib/services/hydration_ai_orchestrator.dart`
* `test/product_qa_test.dart`

#### Story Quality Checklist

- [x] local-first user and outcome are specific to Chat With Local Hydration Coach.
- [x] Scope is bounded to Implemented MVP behavior: The coach screen gives users a conversational place to ask hydration questions and receive local guidance..
- [x] Primary dependency is `HYD-US-023`; full dependency list is explicit.
- [x] Checked claims cite repository evidence beginning with `lib/ui/screens/chat_coach_screen.dart`.
- [x] Acceptance coverage is 3/3; 0 acceptance criteria remain open.

#### INVEST Check

- [x] Independent: 2 listed dependency link(s) for Chat With Local Hydration Coach.
- [x] Negotiable: implementation detail stays in repository evidence, not hidden in the User Story title.
- [x] Valuable: local-first user needs to ask a hydration coach question so I can receive deterministic guidance from saved local hydration context.
- [x] Estimable: story size is 3 with evidence and open criteria visible.
- [x] Small: size 3 is within a focused slice.
- [x] Testable: 3 checkbox criterion/criteria and test/build evidence are listed.

#### Definition of Ready

- [x] Metadata is complete: P1, MVP, MVP AI Provider Safety, Product Backlog rank 025, size 3.
- [x] Dependencies are named for sequencing; first dependency is `HYD-US-023`.
- [x] Acceptance criteria are checkbox-based and currently 3 checked / 0 unchecked.
- [x] Repository evidence is available for current claims; first evidence item is `lib/ui/screens/chat_coach_screen.dart`.
- [x] Ready state reflects Implemented: ready to pull or maintain.

#### Definition of Done

- [x] Implementation status is Implemented for Chat With Local Hydration Coach.
- [x] All acceptance criteria are checked for this story (3/3).
- [x] Verification evidence includes automated tests or CI/docs.
- [x] Project workflow metadata is valid: Product Backlog, rank 025, size 3.
- [x] Done means implemented, verified, and no open criteria for Chat With Local Hydration Coach.

### HYD-US-023: Build Typed Hydration Context

**Epic:** Local Hydration Coach  
**Story Type:** System Story  
**Implementation Status:** Implemented  
**Priority:** P1  
**Release Scope:** Supporting
**Labels:** `user-story`, `type:system`, `priority:p1`, `status:implemented`, `scope:supporting`, `area:coach`, `area:ai-provider`, `size:3`  
**Milestone:** MVP AI Provider Safety
**Story Size:** 3
**Project Column:** Product Backlog  
**Business Rank:** 044

#### User Story

**As a** local application service
**I need** a typed hydration context for coaches and providers
**So that** advice and provider proposals use consistent, bounded app state.

#### Description

* Hydration context packages logs, reminders, challenge state, and capability status into typed data that coach and provider paths can safely consume.
* This system story prevents ad hoc prompt construction from reaching into UI or persistence directly.

#### Details and Business Rules

* `LocalHydrationContextProvider` builds daily summary, lifetime ml, event count, reminder context, challenge context, and capabilities.
* context is built from repositories and capability reporter.
* optional providers receive typed context instead of mutating repositories.
* Business rule: Provider and coach requests must use typed context rather than raw UI state or unvalidated storage reads.
#### Data and State Requirements

* Provider-facing state must avoid persisted production secrets and must preserve local fallback behavior.
* Integration state must be represented through capability status, adapter contracts, or disabled placeholders until a real adapter is implemented.

#### Assumptions

* No additional product assumption is made beyond the repository evidence and explicit out-of-scope notes.

#### Acceptance Criteria

- [x] The context contains daily summary, lifetime totals, reminder state, challenge state, and capabilities.
- [x] Disabled capability flags remain false.

#### Acceptance Criteria Coverage

* Checked acceptance criteria: 2.
* Unchecked acceptance criteria: 0.
* Checked criteria are tied to the repository evidence listed in this story.
* Unchecked criteria represent work or verification still needed before the criterion can be claimed complete.

#### Dependencies

* `HYD-US-004`
* `HYD-US-015`
* `HYD-US-018`
* `HYD-US-031`

#### Non-Functional Requirements

* Keep the behavior offline-tolerant and honest about local-first limits.
* Keep user-visible behavior responsive on the supported web and Android MVP targets.
* Do not expose secrets, provider diagnostics, or disabled integrations in a misleading way.

#### Out of Scope

* Raw provider prompts, raw cloud payload storage, or external context sync.

#### Repository Evidence

* `lib/services/hydration_context_builder.dart`
* `lib/domain/hydration_contracts.dart`
* `docs/architecture/AI_ACTION_CONTRACT.md`
* `test/adapter_contract_test.dart`

#### Story Quality Checklist

- [x] local application service and outcome are specific to Build Typed Hydration Context.
- [x] Scope is bounded to Implemented Supporting behavior: Hydration context packages logs, reminders, challenge state, and capability status into typed data that coach and....
- [x] Primary dependency is `HYD-US-004`; full dependency list is explicit.
- [x] Checked claims cite repository evidence beginning with `lib/services/hydration_context_builder.dart`.
- [x] Acceptance coverage is 2/2; 0 acceptance criteria remain open.

#### INVEST Check

- [x] Independent: 4 listed dependency link(s) for Build Typed Hydration Context.
- [x] Negotiable: implementation detail stays in repository evidence, not hidden in the System Story title.
- [x] Valuable: local application service needs a typed hydration context for coaches and providers so advice and provider proposals use consistent, bounded app state.
- [x] Estimable: story size is 3 with evidence and open criteria visible.
- [x] Small: size 3 is within a focused slice.
- [x] Testable: 2 checkbox criterion/criteria and test/build evidence are listed.

#### Definition of Ready

- [x] Metadata is complete: P1, Supporting, MVP AI Provider Safety, Product Backlog rank 044, size 3.
- [x] Dependencies are named for sequencing; first dependency is `HYD-US-004`.
- [x] Acceptance criteria are checkbox-based and currently 2 checked / 0 unchecked.
- [x] Repository evidence is available for current claims; first evidence item is `lib/services/hydration_context_builder.dart`.
- [x] Ready state reflects Implemented: ready to pull or maintain.

#### Definition of Done

- [x] Implementation status is Implemented for Build Typed Hydration Context.
- [x] All acceptance criteria are checked for this story (2/2).
- [x] Verification evidence includes automated tests or CI/docs.
- [x] Project workflow metadata is valid: Product Backlog, rank 044, size 3.
- [x] Done means implemented, verified, and no open criteria for Build Typed Hydration Context.

### HYD-US-024: Confirm Coach Suggestions Before State Changes

**Epic:** Local Hydration Coach  
**Story Type:** Security Story  
**Implementation Status:** Implemented  
**Priority:** P1  
**Release Scope:** Supporting
**Labels:** `user-story`, `type:security`, `priority:p1`, `status:implemented`, `scope:supporting`, `area:coach`, `area:ai-provider`, `size:3`  
**Milestone:** MVP AI Provider Safety
**Story Size:** 3
**Project Column:** Product Backlog  
**Business Rank:** 045

#### User Story

**As a** Hydrion stakeholder
**I need** coach suggestions that change logs, reminders, or challenges to require confirmation
**So that** no provider or coach output mutates my local data without consent.

#### Description

* Coach suggestions can propose helpful actions, but users must confirm any state-changing action before Hydrion mutates logs, reminders, or challenges.
* This keeps AI/provider output advisory instead of authoritative.

#### Details and Business Rules

* suggestion cards can represent hydration log, reminder, challenge, trend insight, and unsupported capability proposals.
* state-changing actions require confirmation.
* executor writes only through repositories after validation.
* dismissing a card removes the pending proposal without changing state.
* Business rule: No coach suggestion may change app state without user confirmation and Hydrion-side validation.
#### Data and State Requirements

* Provider-facing state must avoid persisted production secrets and must preserve local fallback behavior.
* Integration state must be represented through capability status, adapter contracts, or disabled placeholders until a real adapter is implemented.

#### Assumptions

* No additional product assumption is made beyond the repository evidence and explicit out-of-scope notes.

#### Acceptance Criteria

- [x] Hydrion writes the log through `HydrationRepository`.
- [x] No log, reminder, or challenge state is changed.
- [x] It is display-only and cannot be applied as a state change.

#### Acceptance Criteria Coverage

* Checked acceptance criteria: 3.
* Unchecked acceptance criteria: 0.
* Checked criteria are tied to the repository evidence listed in this story.
* Unchecked criteria represent work or verification still needed before the criterion can be claimed complete.

#### Dependencies

* `HYD-US-022`
* `HYD-US-031`

#### Non-Functional Requirements

* Keep the behavior offline-tolerant and honest about local-first limits.
* Keep user-visible behavior responsive on the supported web and Android MVP targets.
* Do not expose secrets, provider diagnostics, or disabled integrations in a misleading way.

#### Out of Scope

* Provider auto-execution, raw action class display, or long-term suggestion audit history.

#### Repository Evidence

* `lib/services/coach_suggestion_service.dart`
* `lib/services/hydration_ai_action_executor.dart`
* `lib/ui/screens/chat_coach_screen.dart`
* `test/coach_suggestion_service_test.dart`
* `test/coach_suggestion_cards_test.dart`

#### Story Quality Checklist

- [x] Hydrion stakeholder and outcome are specific to Confirm Coach Suggestions Before State Changes.
- [x] Scope is bounded to Implemented Supporting behavior: Coach suggestions can propose helpful actions, but users must confirm any state-changing action before Hydrion mutates....
- [x] Primary dependency is `HYD-US-022`; full dependency list is explicit.
- [x] Checked claims cite repository evidence beginning with `lib/services/coach_suggestion_service.dart`.
- [x] Acceptance coverage is 3/3; 0 acceptance criteria remain open.

#### INVEST Check

- [x] Independent: 2 listed dependency link(s) for Confirm Coach Suggestions Before State Changes.
- [x] Negotiable: implementation detail stays in repository evidence, not hidden in the Security Story title.
- [x] Valuable: Hydrion stakeholder needs coach suggestions that change logs, reminders, or challenges to require confirmation so no provider or coach output mutates my local data without consent.
- [x] Estimable: story size is 3 with evidence and open criteria visible.
- [x] Small: size 3 is within a focused slice.
- [x] Testable: 3 checkbox criterion/criteria and test/build evidence are listed.

#### Definition of Ready

- [x] Metadata is complete: P1, Supporting, MVP AI Provider Safety, Product Backlog rank 045, size 3.
- [x] Dependencies are named for sequencing; first dependency is `HYD-US-022`.
- [x] Acceptance criteria are checkbox-based and currently 3 checked / 0 unchecked.
- [x] Repository evidence is available for current claims; first evidence item is `lib/services/coach_suggestion_service.dart`.
- [x] Ready state reflects Implemented: ready to pull or maintain.

#### Definition of Done

- [x] Implementation status is Implemented for Confirm Coach Suggestions Before State Changes.
- [x] All acceptance criteria are checked for this story (3/3).
- [x] Verification evidence includes automated tests or CI/docs.
- [x] Project workflow metadata is valid: Product Backlog, rank 045, size 3.
- [x] Done means implemented, verified, and no open criteria for Confirm Coach Suggestions Before State Changes.

### HYD-US-025: Parse Hydration Commands for Typed or Future Voice Use

**Epic:** Local Hydration Coach  
**Story Type:** Enabler Story  
**Implementation Status:** Partial  
**Priority:** P2  
**Release Scope:** Supporting
**Labels:** `user-story`, `type:enabler`, `priority:p2`, `status:partial`, `scope:supporting`, `area:coach`, `area:ai-provider`, `area:voice`, `size:3`  
**Milestone:** MVP AI Provider Safety
**Story Size:** 3
**Project Column:** Product Backlog  
**Business Rank:** 039

#### User Story

**As a** hands-free or typed-command user
**I need** Hydrion to parse hydration-related commands into stable intents
**So that** future voice or command surfaces can route requests safely.

#### Description

* The command parser turns typed or future voice-like phrases into structured hydration intents for later execution paths.
* It is partial because parsing exists, while microphone capture and full voice UX remain gated.

#### Details and Business Rules

* local parser returns `log_hydration`, `schedule_reminder`, or `unknown_command`.
* numeric ml extraction supports simple commands like "log 450 ml".
* `VoiceLLMBridge` normalizes parser output.
* Business rule: Parsed commands must be validated as typed intents before any app state change is proposed.
#### Data and State Requirements

* Integration state must be represented through capability status, adapter contracts, or disabled placeholders until a real adapter is implemented.

#### Assumptions

* No additional product assumption is made beyond the repository evidence and explicit out-of-scope notes.

#### Acceptance Criteria

- [ ] It returns intent `log_hydration` and `volumeMl` 450.
- [ ] It returns intent `schedule_reminder`.
- [ ] It returns `unknown_command` with the original command.
- [ ] Remaining end-to-end user behavior for this story is implemented, verified, and ready for release..

#### Acceptance Criteria Coverage

* Checked acceptance criteria: 0.
* Unchecked acceptance criteria: 4.
* Checked criteria are tied to the repository evidence listed in this story.
* Unchecked criteria represent work or verification still needed before the criterion can be claimed complete.

#### Dependencies

* `HYD-US-026`
* `HYD-US-031`

#### Non-Functional Requirements

* Keep the behavior offline-tolerant and honest about local-first limits.
* Keep user-visible behavior responsive on the supported web and Android MVP targets.
* Do not expose secrets, provider diagnostics, or disabled integrations in a misleading way.
* Preserve capability gating until the unchecked acceptance criteria are implemented and verified.

#### Out of Scope

* Microphone permission, speech-to-text, command confirmation, or direct command execution.

#### Repository Evidence

* `lib/adapters/local/local_hydrion_adapters.dart`
* `lib/services/voice_llm_bridge.dart`
* `lib/services/voice_client.dart`
* `test/adapter_contract_test.dart`

#### Story Quality Checklist

- [x] hands-free or typed-command user and outcome are specific to Parse Hydration Commands for Typed or Future Voice Use.
- [x] Scope is bounded to Partial Supporting behavior: The command parser turns typed or future voice-like phrases into structured hydration intents for later execution....
- [x] Primary dependency is `HYD-US-026`; full dependency list is explicit.
- [x] Checked claims cite repository evidence beginning with `lib/adapters/local/local_hydrion_adapters.dart`.
- [ ] Acceptance coverage is 0/4; 4 acceptance criteria remain open.

#### INVEST Check

- [x] Independent: 2 listed dependency link(s) for Parse Hydration Commands for Typed or Future Voice Use.
- [x] Negotiable: implementation detail stays in repository evidence, not hidden in the Enabler Story title.
- [x] Valuable: hands-free or typed-command user needs Hydrion to parse hydration-related commands into stable intents so future voice or command surfaces can route requests safely.
- [x] Estimable: story size is 3 with evidence and open criteria visible.
- [x] Small: size 3 is within a focused slice.
- [x] Testable: 4 checkbox criterion/criteria and test/build evidence are listed.

#### Definition of Ready

- [x] Metadata is complete: P2, Supporting, MVP AI Provider Safety, Product Backlog rank 039, size 3.
- [x] Dependencies are named for sequencing; first dependency is `HYD-US-026`.
- [x] Acceptance criteria are checkbox-based and currently 0 checked / 4 unchecked.
- [x] Repository evidence is available for current claims; first evidence item is `lib/adapters/local/local_hydrion_adapters.dart`.
- [x] Ready state reflects Partial: ready to pull or maintain.

#### Definition of Done

- [ ] Implementation status is Implemented for Parse Hydration Commands for Typed or Future Voice Use.
- [ ] All acceptance criteria are checked for this story (0/4).
- [x] Verification evidence includes automated tests or CI/docs.
- [x] Project workflow metadata is valid: Product Backlog, rank 039, size 3.
- [ ] Done means implemented, verified, and no open criteria for Parse Hydration Commands for Typed or Future Voice Use.

### HYD-US-026: Gate Voice Capture Until a Real Adapter Exists

**Epic:** Local Hydration Coach  
**Story Type:** Security Story  
**Implementation Status:** Gated  
**Priority:** P2  
**Release Scope:** Post-MVP
**Labels:** `user-story`, `type:security`, `priority:p2`, `status:gated`, `scope:post-mvp`, `area:coach`, `area:ai-provider`, `area:voice`, `area:platform`, `area:native-integrations`, `size:8`  
**Milestone:** Post-MVP Native Integrations
**Story Size:** 8
**Project Column:** Ice Box  
**Business Rank:** 002

#### User Story

**As a** Hydrion stakeholder
**I need** voice capture to stay disabled until microphone capture and confirmation are real
**So that** Hydrion does not pretend to support a privacy-sensitive feature.

#### Description

* Voice capture stays blocked until Hydrion has a real microphone adapter, permission flow, and confirmation UX.
* The current UI must be honest about disabled voice input while still allowing command-parser work to continue safely.

#### Details and Business Rules

* `VoiceService.isAvailable` and `initialize()` return false.
* `VoiceInputWidget` is disabled and uses disabled semantics/tooltips.
* permissions service does not request microphone permissions in standalone mode.
* Business rule: Microphone access must not be requested or implied until the native voice adapter story is implemented.
#### Data and State Requirements

* Local application state must remain scoped to Hydrion repositories and the `shared_preferences` backed local store unless the story explicitly says otherwise.
* Integration state must be represented through capability status, adapter contracts, or disabled placeholders until a real adapter is implemented.

#### Assumptions

* future voice support needs permission flow, transcript preview, locale handling, and confirmation.

#### Acceptance Criteria

- [x] It is disabled and labeled as unavailable.
- [x] No microphone permission is requested.
- [ ] State changes still require user confirmation before execution.
- [ ] Remaining end-to-end user behavior for this story is implemented, verified, and ready for release..

#### Acceptance Criteria Coverage

* Checked acceptance criteria: 2.
* Unchecked acceptance criteria: 2.
* Checked criteria are tied to the repository evidence listed in this story.
* Unchecked criteria represent work or verification still needed before the criterion can be claimed complete.

#### Dependencies

* `HYD-US-025`
* `HYD-US-031`

#### Non-Functional Requirements

* Keep the behavior offline-tolerant and honest about local-first limits.
* Keep user-visible behavior responsive on the supported web and Android MVP targets.
* Do not expose secrets, provider diagnostics, or disabled integrations in a misleading way.
* Preserve capability gating until the unchecked acceptance criteria are implemented and verified.

#### Out of Scope

* Implementing ASR, TTS, wake phrase, audio storage, or platform microphone permissions.

#### Repository Evidence

* `lib/services/voice_client.dart`
* `lib/ui/components/voice_input_widget.dart`
* `lib/utils/permissions.dart`
* `test/persistence_test.dart`
* `HYDRION_MVP_KANBAN_ROADMAP.md`

#### Story Quality Checklist

- [x] Hydrion stakeholder and outcome are specific to Gate Voice Capture Until a Real Adapter Exists.
- [x] Scope is bounded to Gated Post-MVP behavior: Voice capture stays blocked until Hydrion has a real microphone adapter, permission flow, and confirmation UX..
- [x] Primary dependency is `HYD-US-025`; full dependency list is explicit.
- [x] Checked claims cite repository evidence beginning with `lib/services/voice_client.dart`.
- [ ] Acceptance coverage is 2/4; 2 acceptance criteria remain open.

#### INVEST Check

- [x] Independent: 2 listed dependency link(s) for Gate Voice Capture Until a Real Adapter Exists.
- [x] Negotiable: implementation detail stays in repository evidence, not hidden in the Security Story title.
- [x] Valuable: Hydrion stakeholder needs voice capture to stay disabled until microphone capture and confirmation are real so Hydrion does not pretend to support a privacy-sensitive feature.
- [x] Estimable: story size is 8 with evidence and open criteria visible.
- [ ] Small: size 8 is too large and should be split before sprint pull.
- [x] Testable: 4 checkbox criterion/criteria and test/build evidence are listed.

#### Definition of Ready

- [x] Metadata is complete: P2, Post-MVP, Post-MVP Native Integrations, Ice Box rank 002, size 8.
- [x] Dependencies are named for sequencing; first dependency is `HYD-US-025`.
- [x] Acceptance criteria are checkbox-based and currently 2 checked / 2 unchecked.
- [x] Repository evidence is available for current claims; first evidence item is `lib/services/voice_client.dart`.
- [x] Ready state reflects Gated: ready to pull or maintain.

#### Definition of Done

- [ ] Implementation status is Implemented for Gate Voice Capture Until a Real Adapter Exists.
- [ ] All acceptance criteria are checked for this story (2/4).
- [x] Verification evidence includes automated tests or CI/docs.
- [x] Project workflow metadata is valid: Ice Box, rank 002, size 8.
- [ ] Done means implemented, verified, and no open criteria for Gate Voice Capture Until a Real Adapter Exists.

### HYD-US-027: Persist Language Settings

**Epic:** Settings and Personalization  
**Story Type:** User Story  
**Implementation Status:** Implemented  
**Priority:** P1  
**Release Scope:** MVP
**Labels:** `user-story`, `type:user-story`, `priority:p1`, `status:implemented`, `scope:mvp`, `area:settings`, `area:frontend`, `size:2`  
**Milestone:** MVP Product UX
**Story Size:** 2
**Project Column:** Product Backlog  
**Business Rank:** 026

#### User Story

**As a** multilingual user
**I need** to select and persist my app language
**So that** Hydrion continues in my preferred supported language after reload.

#### Description

* Users can persist their language preference so Hydrion reopens in the selected supported locale.
* The setting must pass through the local settings repository and i18n resolver rather than a hardcoded screen-only toggle.

#### Details and Business Rules

* Settings exposes English, Spanish, and French in a locale picker.
* `I18nResolver` persists the resolved locale through `UserSettingsRepository`.
* unsupported locales fall back to English.
* Business rule: Locale settings persist locally and resolve through supported locale fallback rules.
#### Data and State Requirements

* Local application state must remain scoped to Hydrion repositories and the `shared_preferences` backed local store unless the story explicitly says otherwise.
* Integration state must be represented through capability status, adapter contracts, or disabled placeholders until a real adapter is implemented.
* User-visible strings and locale state must remain compatible with generated localization resources and fallback rules.

#### Assumptions

* No additional product assumption is made beyond the repository evidence and explicit out-of-scope notes.

#### Acceptance Criteria

- [x] App strings update to French and the locale is stored locally.
- [x] The previously selected locale is restored.
- [x] Hydrion falls back to English.

#### Acceptance Criteria Coverage

* Checked acceptance criteria: 3.
* Unchecked acceptance criteria: 0.
* Checked criteria are tied to the repository evidence listed in this story.
* Unchecked criteria represent work or verification still needed before the criterion can be claimed complete.

#### Dependencies

* `HYD-US-029`
* `HYD-US-004`

#### Non-Functional Requirements

* Keep the behavior offline-tolerant and honest about local-first limits.
* Keep user-visible behavior responsive on the supported web and Android MVP targets.
* Do not expose secrets, provider diagnostics, or disabled integrations in a misleading way.
* Preserve generated localization fallback behavior for supported and future locales.

#### Out of Scope

* Downloadable language packs or partial runtime string maps outside `gen_l10n`.

#### Repository Evidence

* `lib/ui/screens/settings_screen.dart`
* `lib/utils/i18n_resolver.dart`
* `lib/repositories/settings_repository.dart`
* `test/localization_test.dart`
* `test/persistence_test.dart`

#### Story Quality Checklist

- [x] multilingual user and outcome are specific to Persist Language Settings.
- [x] Scope is bounded to Implemented MVP behavior: Users can persist their language preference so Hydrion reopens in the selected supported locale..
- [x] Primary dependency is `HYD-US-029`; full dependency list is explicit.
- [x] Checked claims cite repository evidence beginning with `lib/ui/screens/settings_screen.dart`.
- [x] Acceptance coverage is 3/3; 0 acceptance criteria remain open.

#### INVEST Check

- [x] Independent: 2 listed dependency link(s) for Persist Language Settings.
- [x] Negotiable: implementation detail stays in repository evidence, not hidden in the User Story title.
- [x] Valuable: multilingual user needs to select and persist my app language so Hydrion continues in my preferred supported language after reload.
- [x] Estimable: story size is 2 with evidence and open criteria visible.
- [x] Small: size 2 is within a focused slice.
- [x] Testable: 3 checkbox criterion/criteria and test/build evidence are listed.

#### Definition of Ready

- [x] Metadata is complete: P1, MVP, MVP Product UX, Product Backlog rank 026, size 2.
- [x] Dependencies are named for sequencing; first dependency is `HYD-US-029`.
- [x] Acceptance criteria are checkbox-based and currently 3 checked / 0 unchecked.
- [x] Repository evidence is available for current claims; first evidence item is `lib/ui/screens/settings_screen.dart`.
- [x] Ready state reflects Implemented: ready to pull or maintain.

#### Definition of Done

- [x] Implementation status is Implemented for Persist Language Settings.
- [x] All acceptance criteria are checked for this story (3/3).
- [x] Verification evidence includes automated tests or CI/docs.
- [x] Project workflow metadata is valid: Product Backlog, rank 026, size 2.
- [x] Done means implemented, verified, and no open criteria for Persist Language Settings.

### HYD-US-028: Show Runtime Capability and Permission Status

**Epic:** Settings and Personalization  
**Story Type:** Operational Story  
**Implementation Status:** Implemented  
**Priority:** P1  
**Release Scope:** Supporting
**Labels:** `user-story`, `type:operations`, `priority:p1`, `status:implemented`, `scope:supporting`, `area:settings`, `area:frontend`, `size:2`  
**Milestone:** MVP Product UX
**Story Size:** 2
**Project Column:** Product Backlog  
**Business Rank:** 046

#### User Story

**As a** Hydrion stakeholder
**I need** Settings to show what Hydrion can and cannot do at runtime
**So that** I understand which features are local, disabled, unconfigured, or future.

#### Description

* Settings must show the current status of providers, permissions, and native capabilities so users understand what Hydrion can and cannot do.
* The dashboard is especially important because several integrations are intentionally disabled or future-only.

#### Details and Business Rules

* Settings shows local persistence, ELKA, cloud AI, voice, BLE, Health, OS notifications, AR, and social sync status.
* standalone permissions check reports that no platform permissions are requested.
* capability states come from `AppCapabilityReporter`.
* Business rule: Capability status must reflect runtime reality, not stale config or roadmap intent.
#### Data and State Requirements

* Provider-facing state must avoid persisted production secrets and must preserve local fallback behavior.
* Integration state must be represented through capability status, adapter contracts, or disabled placeholders until a real adapter is implemented.

#### Assumptions

* No additional product assumption is made beyond the repository evidence and explicit out-of-scope notes.

#### Acceptance Criteria

- [x] Local persistence is shown on-device and optional integrations are shown disabled or unconfigured.
- [x] Hydrion reports that no platform permissions were requested.
- [x] Cloud AI/Gemini status reflects the configured provider state.

#### Acceptance Criteria Coverage

* Checked acceptance criteria: 3.
* Unchecked acceptance criteria: 0.
* Checked criteria are tied to the repository evidence listed in this story.
* Unchecked criteria represent work or verification still needed before the criterion can be claimed complete.

#### Dependencies

* `HYD-US-031`
* `HYD-US-033`

#### Non-Functional Requirements

* Keep the behavior offline-tolerant and honest about local-first limits.
* Keep user-visible behavior responsive on the supported web and Android MVP targets.
* Do not expose secrets, provider diagnostics, or disabled integrations in a misleading way.

#### Out of Scope

* Runtime toggles for disabled integrations or actual permission request flows.

#### Repository Evidence

* `lib/ui/screens/settings_screen.dart`
* `lib/utils/permissions.dart`
* `lib/domain/hydration_contracts.dart`
* `test/runtime_ux_test.dart`
* `test/product_qa_test.dart`

#### Story Quality Checklist

- [x] Hydrion stakeholder and outcome are specific to Show Runtime Capability and Permission Status.
- [x] Scope is bounded to Implemented Supporting behavior: Settings must show the current status of providers, permissions, and native capabilities so users understand what....
- [x] Primary dependency is `HYD-US-031`; full dependency list is explicit.
- [x] Checked claims cite repository evidence beginning with `lib/ui/screens/settings_screen.dart`.
- [x] Acceptance coverage is 3/3; 0 acceptance criteria remain open.

#### INVEST Check

- [x] Independent: 2 listed dependency link(s) for Show Runtime Capability and Permission Status.
- [x] Negotiable: implementation detail stays in repository evidence, not hidden in the Operational Story title.
- [x] Valuable: Hydrion stakeholder needs Settings to show what Hydrion can and cannot do at runtime so I understand which features are local, disabled, unconfigured, or future.
- [x] Estimable: story size is 2 with evidence and open criteria visible.
- [x] Small: size 2 is within a focused slice.
- [x] Testable: 3 checkbox criterion/criteria and test/build evidence are listed.

#### Definition of Ready

- [x] Metadata is complete: P1, Supporting, MVP Product UX, Product Backlog rank 046, size 2.
- [x] Dependencies are named for sequencing; first dependency is `HYD-US-031`.
- [x] Acceptance criteria are checkbox-based and currently 3 checked / 0 unchecked.
- [x] Repository evidence is available for current claims; first evidence item is `lib/ui/screens/settings_screen.dart`.
- [x] Ready state reflects Implemented: ready to pull or maintain.

#### Definition of Done

- [x] Implementation status is Implemented for Show Runtime Capability and Permission Status.
- [x] All acceptance criteria are checked for this story (3/3).
- [x] Verification evidence includes automated tests or CI/docs.
- [x] Project workflow metadata is valid: Product Backlog, rank 046, size 2.
- [x] Done means implemented, verified, and no open criteria for Show Runtime Capability and Permission Status.

### HYD-US-029: Render English, Spanish, and French App Strings

**Epic:** Localization  
**Story Type:** User Story  
**Implementation Status:** Implemented  
**Priority:** P0  
**Release Scope:** MVP
**Labels:** `user-story`, `type:user-story`, `priority:p0`, `status:implemented`, `scope:mvp`, `area:localization`, `size:3`  
**Milestone:** MVP Release Readiness
**Story Size:** 3
**Project Column:** Product Backlog  
**Business Rank:** 012

#### User Story

**As a** multilingual user
**I need** Hydrion's core UI in English, Spanish, and French
**So that** I can use the main flows in a supported language.

#### Description

* Hydrion ships user-visible strings for English, Spanish, and French so core screens can be used in the supported MVP locales.
* Generated localization must stay aligned with settings and UI copy.

#### Details and Business Rules

* `lib/l10n/app_en.arb`, `app_es.arb`, and `app_fr.arb` exist.
* Flutter `gen_l10n` output is committed under `lib/l10n`.
* tests verify core shell strings and provider status strings in all three locales.
* Business rule: Supported localization resources must include EN, ES, and FR for committed user-facing strings.
#### Data and State Requirements

* Integration state must be represented through capability status, adapter contracts, or disabled placeholders until a real adapter is implemented.
* User-visible strings and locale state must remain compatible with generated localization resources and fallback rules.

#### Assumptions

* No additional product assumption is made beyond the repository evidence and explicit out-of-scope notes.

#### Acceptance Criteria

- [x] Core labels appear in the selected language.
- [x] Strings come from `AppLocalizations`.
- [x] Visible strings update without app restart.

#### Acceptance Criteria Coverage

* Checked acceptance criteria: 3.
* Unchecked acceptance criteria: 0.
* Checked criteria are tied to the repository evidence listed in this story.
* Unchecked criteria represent work or verification still needed before the criterion can be claimed complete.

#### Dependencies

* `HYD-US-027`

#### Non-Functional Requirements

* Keep the behavior offline-tolerant and honest about local-first limits.
* Keep user-visible behavior responsive on the supported web and Android MVP targets.
* Do not expose secrets, provider diagnostics, or disabled integrations in a misleading way.

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

#### Story Quality Checklist

- [x] multilingual user and outcome are specific to Render English, Spanish, and French App Strings.
- [x] Scope is bounded to Implemented MVP behavior: Hydrion ships user-visible strings for English, Spanish, and French so core screens can be used in....
- [x] Primary dependency is `HYD-US-027`; full dependency list is explicit.
- [x] Checked claims cite repository evidence beginning with `l10n.yaml`.
- [x] Acceptance coverage is 3/3; 0 acceptance criteria remain open.

#### INVEST Check

- [x] Independent: 1 listed dependency link(s) for Render English, Spanish, and French App Strings.
- [x] Negotiable: implementation detail stays in repository evidence, not hidden in the User Story title.
- [x] Valuable: multilingual user needs Hydrion's core UI in English, Spanish, and French so I can use the main flows in a supported language.
- [x] Estimable: story size is 3 with evidence and open criteria visible.
- [x] Small: size 3 is within a focused slice.
- [x] Testable: 3 checkbox criterion/criteria and test/build evidence are listed.

#### Definition of Ready

- [x] Metadata is complete: P0, MVP, MVP Release Readiness, Product Backlog rank 012, size 3.
- [x] Dependencies are named for sequencing; first dependency is `HYD-US-027`.
- [x] Acceptance criteria are checkbox-based and currently 3 checked / 0 unchecked.
- [x] Repository evidence is available for current claims; first evidence item is `l10n.yaml`.
- [x] Ready state reflects Implemented: ready to pull or maintain.

#### Definition of Done

- [x] Implementation status is Implemented for Render English, Spanish, and French App Strings.
- [x] All acceptance criteria are checked for this story (3/3).
- [x] Verification evidence includes automated tests or CI/docs.
- [x] Project workflow metadata is valid: Product Backlog, rank 012, size 3.
- [x] Done means implemented, verified, and no open criteria for Render English, Spanish, and French App Strings.

### HYD-US-030: Handle Future and Unsupported Locales Safely

**Epic:** Localization  
**Story Type:** System Story  
**Implementation Status:** Partial  
**Priority:** P2  
**Release Scope:** Supporting
**Labels:** `user-story`, `type:system`, `priority:p2`, `status:partial`, `scope:supporting`, `area:localization`, `size:2`  
**Milestone:** MVP Release Readiness
**Story Size:** 2
**Project Column:** Product Backlog  
**Business Rank:** 040

#### User Story

**As a** multilingual user outside current locale coverage
**I need** Hydrion to fall back safely and label future languages honestly
**So that** I am not shown incomplete localization as if it were shipped.

#### Description

* Unsupported and future locales should fall back predictably instead of breaking screens or producing missing-key experiences.
* The current implementation is partial because fallback exists, while full future-locale coverage is not complete.

#### Details and Business Rules

* `I18nResolver.futureLocales` includes Arabic, German, Portuguese, and Chinese.
* unsupported and future locales fall back to English for active UI.
* RTL helper exists for locale text direction.
* Business rule: Future locale codes must resolve safely to supported strings until their translations are complete.
#### Data and State Requirements

* Provider-facing state must avoid persisted production secrets and must preserve local fallback behavior.
* Integration state must be represented through capability status, adapter contracts, or disabled placeholders until a real adapter is implemented.
* User-visible strings and locale state must remain compatible with generated localization resources and fallback rules.

#### Assumptions

* No additional product assumption is made beyond the repository evidence and explicit out-of-scope notes.

#### Acceptance Criteria

- [x] Hydrion falls back to English and identifies German as future.
- [ ] Hydrion identifies it as unsupported.
- [x] The resolver can report RTL direction for that locale.
- [ ] Remaining end-to-end user behavior for this story is implemented, verified, and ready for release..

#### Acceptance Criteria Coverage

* Checked acceptance criteria: 2.
* Unchecked acceptance criteria: 2.
* Checked criteria are tied to the repository evidence listed in this story.
* Unchecked criteria represent work or verification still needed before the criterion can be claimed complete.

#### Dependencies

* `HYD-US-027`
* `HYD-US-029`

#### Non-Functional Requirements

* Keep the behavior offline-tolerant and honest about local-first limits.
* Keep user-visible behavior responsive on the supported web and Android MVP targets.
* Do not expose secrets, provider diagnostics, or disabled integrations in a misleading way.
* Preserve capability gating until the unchecked acceptance criteria are implemented and verified.

#### Out of Scope

* Shipping future translations before ARB parity and UI validation exist.

#### Repository Evidence

* `lib/utils/i18n_resolver.dart`
* `test/localization_test.dart`
* `docs/architecture/AI_ACTION_CONTRACT.md`

#### Story Quality Checklist

- [x] multilingual user outside current locale coverage and outcome are specific to Handle Future and Unsupported Locales Safely.
- [x] Scope is bounded to Partial Supporting behavior: Unsupported and future locales should fall back predictably instead of breaking screens or producing missing-key experiences..
- [x] Primary dependency is `HYD-US-027`; full dependency list is explicit.
- [x] Checked claims cite repository evidence beginning with `lib/utils/i18n_resolver.dart`.
- [ ] Acceptance coverage is 2/4; 2 acceptance criteria remain open.

#### INVEST Check

- [x] Independent: 2 listed dependency link(s) for Handle Future and Unsupported Locales Safely.
- [x] Negotiable: implementation detail stays in repository evidence, not hidden in the System Story title.
- [x] Valuable: multilingual user outside current locale coverage needs Hydrion to fall back safely and label future languages honestly so I am not shown incomplete localization as if it were shipped.
- [x] Estimable: story size is 2 with evidence and open criteria visible.
- [x] Small: size 2 is within a focused slice.
- [x] Testable: 4 checkbox criterion/criteria and test/build evidence are listed.

#### Definition of Ready

- [x] Metadata is complete: P2, Supporting, MVP Release Readiness, Product Backlog rank 040, size 2.
- [x] Dependencies are named for sequencing; first dependency is `HYD-US-027`.
- [x] Acceptance criteria are checkbox-based and currently 2 checked / 2 unchecked.
- [x] Repository evidence is available for current claims; first evidence item is `lib/utils/i18n_resolver.dart`.
- [x] Ready state reflects Partial: ready to pull or maintain.

#### Definition of Done

- [ ] Implementation status is Implemented for Handle Future and Unsupported Locales Safely.
- [ ] All acceptance criteria are checked for this story (2/4).
- [x] Verification evidence includes automated tests or CI/docs.
- [x] Project workflow metadata is valid: Product Backlog, rank 040, size 2.
- [ ] Done means implemented, verified, and no open criteria for Handle Future and Unsupported Locales Safely.

### HYD-US-031: Enforce Capability Gating and Safe Action Validation

**Epic:** Capability Gating  
**Story Type:** Security Story  
**Implementation Status:** Implemented  
**Priority:** P0  
**Release Scope:** Supporting
**Labels:** `user-story`, `type:security`, `priority:p0`, `status:implemented`, `scope:supporting`, `area:capability-gating`, `area:security`, `size:5`  
**Milestone:** MVP AI Provider Safety
**Story Size:** 5
**Project Column:** Product Backlog  
**Business Rank:** 003

#### User Story

**As a** local application service
**I need** unavailable features and unsafe provider claims to be blocked
**So that** Hydrion cannot mislead users or mutate state through unsupported capabilities.

#### Description

* Capability gating protects users from disabled adapters and unsafe AI actions by centralizing what Hydrion is allowed to do.
* This is a core safety layer for local-first operation, provider fallback, native placeholders, and confirmable actions.

#### Details and Business Rules

* standalone capabilities disable ELKA, Gemini, cloud AI, cloud sync, voice, BLE, Health, OS notifications, AR, and social sync by default.
* `HydrationAiActionValidator` blocks unavailable required capabilities and unsafe capability claims.
* invalid hydration amounts outside 1 to 5000 ml are rejected for provider suggestions.
* Business rule: Disabled capabilities must be blocked at validation boundaries, not only hidden in the UI.
#### Data and State Requirements

* Provider-facing state must avoid persisted production secrets and must preserve local fallback behavior.
* Integration state must be represented through capability status, adapter contracts, or disabled placeholders until a real adapter is implemented.

#### Assumptions

* No additional product assumption is made beyond the repository evidence and explicit out-of-scope notes.

#### Acceptance Criteria

- [x] The action is rejected and converted to an unsupported-capability notice.
- [x] Hydrion does not execute it.
- [x] They use capability state instead of guessing feature availability.

#### Acceptance Criteria Coverage

* Checked acceptance criteria: 3.
* Unchecked acceptance criteria: 0.
* Checked criteria are tied to the repository evidence listed in this story.
* Unchecked criteria represent work or verification still needed before the criterion can be claimed complete.

#### Dependencies

* `HYD-US-023`
* `HYD-US-024`

#### Non-Functional Requirements

* Keep the behavior offline-tolerant and honest about local-first limits.
* Keep user-visible behavior responsive on the supported web and Android MVP targets.
* Do not expose secrets, provider diagnostics, or disabled integrations in a misleading way.

#### Out of Scope

* Enabling disabled integrations or bypassing confirmation for provider output.

#### Repository Evidence

* `lib/domain/hydration_contracts.dart`
* `lib/adapters/local/local_hydrion_adapters.dart`
* `test/ai_action_contract_test.dart`
* `test/adapter_contract_test.dart`
* `docs/architecture/AI_ACTION_CONTRACT.md`

#### Story Quality Checklist

- [x] local application service and outcome are specific to Enforce Capability Gating and Safe Action Validation.
- [x] Scope is bounded to Implemented Supporting behavior: Capability gating protects users from disabled adapters and unsafe AI actions by centralizing what Hydrion is....
- [x] Primary dependency is `HYD-US-023`; full dependency list is explicit.
- [x] Checked claims cite repository evidence beginning with `lib/domain/hydration_contracts.dart`.
- [x] Acceptance coverage is 3/3; 0 acceptance criteria remain open.

#### INVEST Check

- [x] Independent: 2 listed dependency link(s) for Enforce Capability Gating and Safe Action Validation.
- [x] Negotiable: implementation detail stays in repository evidence, not hidden in the Security Story title.
- [x] Valuable: local application service needs unavailable features and unsafe provider claims to be blocked so Hydrion cannot mislead users or mutate state through unsupported capabilities.
- [x] Estimable: story size is 5 with evidence and open criteria visible.
- [x] Small: size 5 is within a focused slice.
- [x] Testable: 3 checkbox criterion/criteria and test/build evidence are listed.

#### Definition of Ready

- [x] Metadata is complete: P0, Supporting, MVP AI Provider Safety, Product Backlog rank 003, size 5.
- [x] Dependencies are named for sequencing; first dependency is `HYD-US-023`.
- [x] Acceptance criteria are checkbox-based and currently 3 checked / 0 unchecked.
- [x] Repository evidence is available for current claims; first evidence item is `lib/domain/hydration_contracts.dart`.
- [x] Ready state reflects Implemented: ready to pull or maintain.

#### Definition of Done

- [x] Implementation status is Implemented for Enforce Capability Gating and Safe Action Validation.
- [x] All acceptance criteria are checked for this story (3/3).
- [x] Verification evidence includes automated tests or CI/docs.
- [x] Project workflow metadata is valid: Product Backlog, rank 003, size 5.
- [x] Done means implemented, verified, and no open criteria for Enforce Capability Gating and Safe Action Validation.

### HYD-US-032: Use Optional Gemini Provider With Local Fallback

**Epic:** External Provider Integration  
**Story Type:** System Story  
**Implementation Status:** Gated  
**Priority:** P2  
**Release Scope:** Supporting
**Labels:** `user-story`, `type:system`, `priority:p2`, `status:gated`, `scope:supporting`, `area:ai-provider`, `area:security`, `size:5`  
**Milestone:** MVP AI Provider Safety
**Story Size:** 5
**Project Column:** Product Backlog  
**Business Rank:** 029

#### User Story

**As a** Hydrion stakeholder
**I need** Gemini to run only when explicitly configured
**So that** Hydrion keeps local_rules as default and avoids unsafe production key handling.

#### Description

* Gemini can be used only when explicitly configured for local development, and Hydrion must fall back to local rules when it is absent or unhealthy.
* The story is gated because production provider strategy, consent, and credential handling are not finished.

#### Details and Business Rules

* Gemini selection uses Dart defines `HYDRION_AI_PROVIDER=gemini`, `HYDRION_GEMINI_API_KEY`, and optional `HYDRION_GEMINI_MODEL`.
* missing key, timeout, HTTP error, malformed response, parser rejection, and validator rejection fall back to `local_rules`.
* Gemini returns typed `HydrationAiAction` proposals only.
* Business rule: Gemini is optional and cannot become a hard dependency for core hydration workflows.
#### Data and State Requirements

* Provider-facing state must avoid persisted production secrets and must preserve local fallback behavior.
* Integration state must be represented through capability status, adapter contracts, or disabled placeholders until a real adapter is implemented.

#### Assumptions

* No additional product assumption is made beyond the repository evidence and explicit out-of-scope notes.

#### Acceptance Criteria

- [x] Selected provider remains local_rules.
- [x] No Gemini network request is attempted and local_rules handles the reply.
- [ ] Hydrion may display the validated response or suggestion.
- [x] The user receives local_rules fallback without raw prompt, context, response, or full key leakage.
- [ ] Remaining end-to-end user behavior for this story is implemented, verified, and ready for release..

#### Acceptance Criteria Coverage

* Checked acceptance criteria: 3.
* Unchecked acceptance criteria: 2.
* Checked criteria are tied to the repository evidence listed in this story.
* Unchecked criteria represent work or verification still needed before the criterion can be claimed complete.

#### Dependencies

* `HYD-US-023`
* `HYD-US-031`
* `HYD-US-033`
* `HYD-US-051`

#### Non-Functional Requirements

* Keep the behavior offline-tolerant and honest about local-first limits.
* Keep user-visible behavior responsive on the supported web and Android MVP targets.
* Do not expose secrets, provider diagnostics, or disabled integrations in a misleading way.
* Preserve capability gating until the unchecked acceptance criteria are implemented and verified.

#### Out of Scope

* Production shared Gemini key shipping, Gemini SDK dependency, OpenAI/BYOK routing, or provider auto-execution.

#### Repository Evidence

* `lib/services/ai_provider_config.dart`
* `lib/adapters/gemini/gemini_adapter.dart`
* `lib/services/hydration_ai_orchestrator.dart`
* `test/gemini_provider_test.dart`
* `docs/architecture/GEMINI_API_INTEGRATION_AUDIT.md`
* `docs/architecture/PROVIDER_SECURITY.md`

#### Story Quality Checklist

- [x] Hydrion stakeholder and outcome are specific to Use Optional Gemini Provider With Local Fallback.
- [x] Scope is bounded to Gated Supporting behavior: Gemini can be used only when explicitly configured for local development, and Hydrion must fall back....
- [x] Primary dependency is `HYD-US-023`; full dependency list is explicit.
- [x] Checked claims cite repository evidence beginning with `lib/services/ai_provider_config.dart`.
- [ ] Acceptance coverage is 3/5; 2 acceptance criteria remain open.

#### INVEST Check

- [x] Independent: 4 listed dependency link(s) for Use Optional Gemini Provider With Local Fallback.
- [x] Negotiable: implementation detail stays in repository evidence, not hidden in the System Story title.
- [x] Valuable: Hydrion stakeholder needs Gemini to run only when explicitly configured so Hydrion keeps local_rules as default and avoids unsafe production key handling.
- [x] Estimable: story size is 5 with evidence and open criteria visible.
- [x] Small: size 5 is within a focused slice.
- [x] Testable: 5 checkbox criterion/criteria and test/build evidence are listed.

#### Definition of Ready

- [x] Metadata is complete: P2, Supporting, MVP AI Provider Safety, Product Backlog rank 029, size 5.
- [x] Dependencies are named for sequencing; first dependency is `HYD-US-023`.
- [x] Acceptance criteria are checkbox-based and currently 3 checked / 2 unchecked.
- [x] Repository evidence is available for current claims; first evidence item is `lib/services/ai_provider_config.dart`.
- [x] Ready state reflects Gated: ready to pull or maintain.

#### Definition of Done

- [ ] Implementation status is Implemented for Use Optional Gemini Provider With Local Fallback.
- [ ] All acceptance criteria are checked for this story (3/5).
- [x] Verification evidence includes automated tests or CI/docs.
- [x] Project workflow metadata is valid: Product Backlog, rank 029, size 5.
- [ ] Done means implemented, verified, and no open criteria for Use Optional Gemini Provider With Local Fallback.

### HYD-US-033: Display Safe Provider Health Diagnostics

**Epic:** External Provider Integration  
**Story Type:** Operational Story  
**Implementation Status:** Implemented  
**Priority:** P1  
**Release Scope:** Supporting
**Labels:** `user-story`, `type:operations`, `priority:p1`, `status:implemented`, `scope:supporting`, `area:ai-provider`, `area:security`, `size:3`  
**Milestone:** MVP AI Provider Safety
**Story Size:** 3
**Project Column:** Product Backlog  
**Business Rank:** 030

#### User Story

**As a** Hydrion stakeholder
**I need** provider status and safe diagnostics in Settings and Coach
**So that** I can understand whether local_rules or an optional provider handled a response.

#### Description

* Provider diagnostics should tell users and maintainers whether local rules or optional providers are active without leaking secrets.
* The diagnostic display must support troubleshooting while keeping credentials and unsafe provider details out of the UI.

#### Details and Business Rules

* provider health tracks selected provider, active provider, configured state, fallback state, diagnostics, and privacy disclosure.
* Settings displays safe Gemini diagnostics such as endpoint host, model path, key presence, key length, first/last four characters, request attempted, HTTP status class, parser/validator codes, and fallback code.
* normal Coach UI hides raw diagnostic internals and full secrets.
* Business rule: Provider health output must be redacted and safe for user-visible settings screens.
#### Data and State Requirements

* Provider-facing state must avoid persisted production secrets and must preserve local fallback behavior.
* Integration state must be represented through capability status, adapter contracts, or disabled placeholders until a real adapter is implemented.

#### Assumptions

* No additional product assumption is made beyond the repository evidence and explicit out-of-scope notes.

#### Acceptance Criteria

- [x] It shows local_rules as selected/active and local-only privacy copy.
- [x] It shows safe key/request metadata without full API key, raw prompt, raw context, or raw response.
- [x] The user can see fallback is active without private query leakage.

#### Acceptance Criteria Coverage

* Checked acceptance criteria: 3.
* Unchecked acceptance criteria: 0.
* Checked criteria are tied to the repository evidence listed in this story.
* Unchecked criteria represent work or verification still needed before the criterion can be claimed complete.

#### Dependencies

* `HYD-US-032`
* `HYD-US-051`

#### Non-Functional Requirements

* Keep the behavior offline-tolerant and honest about local-first limits.
* Keep user-visible behavior responsive on the supported web and Android MVP targets.
* Do not expose secrets, provider diagnostics, or disabled integrations in a misleading way.

#### Out of Scope

* Logging full provider payloads or exposing secret values for debugging.

#### Repository Evidence

* `lib/services/provider_health.dart`
* `lib/ui/screens/settings_screen.dart`
* `lib/ui/screens/chat_coach_screen.dart`
* `test/gemini_provider_test.dart`
* `test/product_qa_test.dart`

#### Story Quality Checklist

- [x] Hydrion stakeholder and outcome are specific to Display Safe Provider Health Diagnostics.
- [x] Scope is bounded to Implemented Supporting behavior: Provider diagnostics should tell users and maintainers whether local rules or optional providers are active without....
- [x] Primary dependency is `HYD-US-032`; full dependency list is explicit.
- [x] Checked claims cite repository evidence beginning with `lib/services/provider_health.dart`.
- [x] Acceptance coverage is 3/3; 0 acceptance criteria remain open.

#### INVEST Check

- [x] Independent: 2 listed dependency link(s) for Display Safe Provider Health Diagnostics.
- [x] Negotiable: implementation detail stays in repository evidence, not hidden in the Operational Story title.
- [x] Valuable: Hydrion stakeholder needs provider status and safe diagnostics in Settings and Coach so I can understand whether local_rules or an optional provider handled a response.
- [x] Estimable: story size is 3 with evidence and open criteria visible.
- [x] Small: size 3 is within a focused slice.
- [x] Testable: 3 checkbox criterion/criteria and test/build evidence are listed.

#### Definition of Ready

- [x] Metadata is complete: P1, Supporting, MVP AI Provider Safety, Product Backlog rank 030, size 3.
- [x] Dependencies are named for sequencing; first dependency is `HYD-US-032`.
- [x] Acceptance criteria are checkbox-based and currently 3 checked / 0 unchecked.
- [x] Repository evidence is available for current claims; first evidence item is `lib/services/provider_health.dart`.
- [x] Ready state reflects Implemented: ready to pull or maintain.

#### Definition of Done

- [x] Implementation status is Implemented for Display Safe Provider Health Diagnostics.
- [x] All acceptance criteria are checked for this story (3/3).
- [x] Verification evidence includes automated tests or CI/docs.
- [x] Project workflow metadata is valid: Product Backlog, rank 030, size 3.
- [x] Done means implemented, verified, and no open criteria for Display Safe Provider Health Diagnostics.

### HYD-US-034: Keep ELKA as an Optional Adapter Boundary

**Epic:** External Provider Integration  
**Story Type:** Architecture Story  
**Implementation Status:** Post-MVP  
**Priority:** P2  
**Release Scope:** Post-MVP
**Labels:** `user-story`, `type:architecture`, `priority:p2`, `status:post-mvp`, `scope:post-mvp`, `area:ai-provider`, `area:security`, `area:elka`, `size:8`  
**Milestone:** Post-MVP ELKA Integration
**Story Size:** 8
**Project Column:** Ice Box  
**Business Rank:** 003

#### User Story

**As a** Hydrion stakeholder
**I need** ELKA to plug in behind Hydrion contracts only when configured
**So that** Hydrion remains standalone and UI-provider independent.

#### Description

* ELKA is kept behind an adapter boundary so future work can integrate it without contaminating current local-first app code.
* The story belongs in Ice Box because no active ELKA runtime path is available in the MVP.

#### Details and Business Rules

* `ElkaAdapterShell.unconfigured()` exists and is compile-safe.
* shell methods throw `UnsupportedError` and `isConfigured` is false.
* UI import rules forbid direct ELKA adapter imports.
* Business rule: ELKA references must remain architectural boundaries until a real runtime adapter is implemented.
#### Data and State Requirements

* Integration state must be represented through capability status, adapter contracts, or disabled placeholders until a real adapter is implemented.

#### Assumptions

* a real ELKA adapter must implement existing domain contracts and require consent/provider health UX.

#### Acceptance Criteria

- [x] ELKA is unconfigured and unavailable.
- [ ] UI files do not import ELKA adapters directly.
- [x] Local_rules remains the default fallback.
- [ ] Remaining end-to-end user behavior for this story is implemented, verified, and ready for release..

#### Acceptance Criteria Coverage

* Checked acceptance criteria: 2.
* Unchecked acceptance criteria: 2.
* Checked criteria are tied to the repository evidence listed in this story.
* Unchecked criteria represent work or verification still needed before the criterion can be claimed complete.

#### Dependencies

* `HYD-US-031`
* `HYD-US-049`
* `HYD-US-051`

#### Non-Functional Requirements

* Keep the behavior offline-tolerant and honest about local-first limits.
* Keep user-visible behavior responsive on the supported web and Android MVP targets.
* Do not expose secrets, provider diagnostics, or disabled integrations in a misleading way.
* Preserve capability gating until the unchecked acceptance criteria are implemented and verified.

#### Out of Scope

* ELKA network calls, ELKA credentials, ELKA-specific UI coupling, or replacing local mode.

#### Repository Evidence

* `lib/adapters/elka/elka_adapter.dart`
* `docs/architecture/ADAPTER_BOUNDARY.md`
* `test/adapter_contract_test.dart`
* `test/boundary_architecture_test.dart`

#### Story Quality Checklist

- [x] Hydrion stakeholder and outcome are specific to Keep ELKA as an Optional Adapter Boundary.
- [x] Scope is bounded to Post-MVP Post-MVP behavior: ELKA is kept behind an adapter boundary so future work can integrate it without contaminating current....
- [x] Primary dependency is `HYD-US-031`; full dependency list is explicit.
- [x] Checked claims cite repository evidence beginning with `lib/adapters/elka/elka_adapter.dart`.
- [ ] Acceptance coverage is 2/4; 2 acceptance criteria remain open.

#### INVEST Check

- [x] Independent: 3 listed dependency link(s) for Keep ELKA as an Optional Adapter Boundary.
- [x] Negotiable: implementation detail stays in repository evidence, not hidden in the Architecture Story title.
- [x] Valuable: Hydrion stakeholder needs ELKA to plug in behind Hydrion contracts only when configured so Hydrion remains standalone and UI-provider independent.
- [x] Estimable: story size is 8 with evidence and open criteria visible.
- [ ] Small: size 8 is too large and should be split before sprint pull.
- [x] Testable: 4 checkbox criterion/criteria and test/build evidence are listed.

#### Definition of Ready

- [x] Metadata is complete: P2, Post-MVP, Post-MVP ELKA Integration, Ice Box rank 003, size 8.
- [x] Dependencies are named for sequencing; first dependency is `HYD-US-031`.
- [x] Acceptance criteria are checkbox-based and currently 2 checked / 2 unchecked.
- [x] Repository evidence is available for current claims; first evidence item is `lib/adapters/elka/elka_adapter.dart`.
- [ ] Ready state reflects Post-MVP: needs implementation, split, or uncertainty cleanup before sprint pull.

#### Definition of Done

- [ ] Implementation status is Implemented for Keep ELKA as an Optional Adapter Boundary.
- [ ] All acceptance criteria are checked for this story (2/4).
- [x] Verification evidence includes automated tests or CI/docs.
- [x] Project workflow metadata is valid: Ice Box, rank 003, size 8.
- [ ] Done means implemented, verified, and no open criteria for Keep ELKA as an Optional Adapter Boundary.

### HYD-US-035: Add Native BLE, Health, and AR Integrations Later

**Epic:** Platform and Native Capabilities  
**Story Type:** Architecture Story  
**Implementation Status:** Post-MVP  
**Priority:** P3  
**Release Scope:** Post-MVP
**Labels:** `user-story`, `type:architecture`, `priority:p3`, `status:post-mvp`, `scope:post-mvp`, `area:platform`, `area:native-integrations`, `area:ble`, `area:health-sync`, `area:ar`, `size:13`  
**Milestone:** Post-MVP Native Integrations
**Story Size:** 13
**Project Column:** Ice Box  
**Business Rank:** 004

#### User Story

**As a** user with device or platform integrations
**I need** BLE smart-bottle, Health, and AR capabilities only after real adapters exist
**So that** Hydrion does not request sensitive permissions or show fake integration behavior.

#### Description

* BLE smart bottle sync, Health/wearable sync, and AR/camera sessions are major native integration epics, not hidden MVP features.
* They require permissions, platform adapters, tests, privacy copy, and UI recovery states before they can leave Ice Box.

#### Details and Business Rules

* BLE service reports unavailable, returns empty scans, and reads no water level.
* wearable service reports BLE and Health sync unsupported.
* AR screen states no plugin, camera permission, or native AR session is active.
* stale config may claim BLE/voice/wearable enabled, but runtime capabilities are authoritative.
* Business rule: Native integration placeholders must not claim working BLE, Health, wearable, or AR behavior.
#### Data and State Requirements

* Integration state must be represented through capability status, adapter contracts, or disabled placeholders until a real adapter is implemented.

#### Assumptions

* No additional product assumption is made beyond the repository evidence and explicit out-of-scope notes.

#### Acceptance Criteria

- [x] BLE, Health, and AR are disabled or unavailable.
- [x] No camera or native AR session starts.
- [ ] Hydrion must gate the feature with explicit permission, privacy copy, and tests.
- [ ] Remaining end-to-end user behavior for this story is implemented, verified, and ready for release..

#### Acceptance Criteria Coverage

* Checked acceptance criteria: 2.
* Unchecked acceptance criteria: 2.
* Checked criteria are tied to the repository evidence listed in this story.
* Unchecked criteria represent work or verification still needed before the criterion can be claimed complete.

#### Dependencies

* `HYD-US-028`
* `HYD-US-031`

#### Non-Functional Requirements

* Keep the behavior offline-tolerant and honest about local-first limits.
* Keep user-visible behavior responsive on the supported web and Android MVP targets.
* Do not expose secrets, provider diagnostics, or disabled integrations in a misleading way.
* Preserve capability gating until the unchecked acceptance criteria are implemented and verified.

#### Out of Scope

* Implementing BLE protocols, HealthKit/Google Fit permissions, or AR camera rendering in the current MVP.

#### Repository Evidence

* `lib/services/ble_service.dart`
* `lib/services/wearable_service.dart`
* `lib/ui/screens/ar_visualization_screen.dart`
* `lib/ui/screens/settings_screen.dart`
* `docs/architecture/STALE_SCAFFOLD_AUDIT.md`

#### Story Quality Checklist

- [x] user with device or platform integrations and outcome are specific to Add Native BLE, Health, and AR Integrations Later.
- [x] Scope is bounded to Post-MVP Post-MVP behavior: BLE smart bottle sync, Health/wearable sync, and AR/camera sessions are major native integration epics, not hidden....
- [x] Primary dependency is `HYD-US-028`; full dependency list is explicit.
- [x] Checked claims cite repository evidence beginning with `lib/services/ble_service.dart`.
- [ ] Acceptance coverage is 2/4; 2 acceptance criteria remain open.

#### INVEST Check

- [x] Independent: 2 listed dependency link(s) for Add Native BLE, Health, and AR Integrations Later.
- [x] Negotiable: implementation detail stays in repository evidence, not hidden in the Architecture Story title.
- [x] Valuable: user with device or platform integrations needs BLE smart-bottle, Health, and AR capabilities only after real adapters exist so Hydrion does not request sensitive permissions or show fake integration behavior.
- [x] Estimable: story size is 13 with evidence and open criteria visible.
- [ ] Small: size 13 is too large and should be split before sprint pull.
- [x] Testable: 4 checkbox criterion/criteria and planned verification are listed.

#### Definition of Ready

- [x] Metadata is complete: P3, Post-MVP, Post-MVP Native Integrations, Ice Box rank 004, size 13.
- [x] Dependencies are named for sequencing; first dependency is `HYD-US-028`.
- [x] Acceptance criteria are checkbox-based and currently 2 checked / 2 unchecked.
- [x] Repository evidence is available for current claims; first evidence item is `lib/services/ble_service.dart`.
- [ ] Ready state reflects Post-MVP: needs implementation, split, or uncertainty cleanup before sprint pull.

#### Definition of Done

- [ ] Implementation status is Implemented for Add Native BLE, Health, and AR Integrations Later.
- [ ] All acceptance criteria are checked for this story (2/4).
- [ ] Verification evidence includes no automated test/CI evidence yet.
- [x] Project workflow metadata is valid: Ice Box, rank 004, size 13.
- [ ] Done means implemented, verified, and no open criteria for Add Native BLE, Health, and AR Integrations Later.

### HYD-US-036: Run as a Web App With PWA Metadata

**Epic:** Platform and PWA Capabilities  
**Story Type:** Operational Story  
**Implementation Status:** Partial  
**Priority:** P1  
**Release Scope:** MVP
**Labels:** `user-story`, `type:operations`, `priority:p1`, `status:partial`, `scope:mvp`, `area:platform`, `area:release`, `area:pwa`, `size:3`  
**Milestone:** MVP Release Readiness
**Story Size:** 3
**Project Column:** Product Backlog  
**Business Rank:** 027

#### User Story

**As a** web user
**I need** Hydrion to build and launch as a Flutter web app with PWA metadata
**So that** I can use the local-first hydration experience in a browser.

#### Description

* The web build should behave like a credible installable Hydrion PWA, not a default Flutter scaffold.
* Current support is partial because build artifacts exist while product metadata still needs cleanup.

#### Details and Business Rules

* README includes `flutter run -d chrome` and `flutter build web --release`.
* CI builds and uploads `build/web`.
* web manifest includes standalone display, icons, orientation, and manifest link.
* Business rule: PWA metadata must use Hydrion product identity before web release readiness is claimed complete.
#### Data and State Requirements

* Local application state must remain scoped to Hydrion repositories and the `shared_preferences` backed local store unless the story explicitly says otherwise.

#### Assumptions

* No additional product assumption is made beyond the repository evidence and explicit out-of-scope notes.

#### Acceptance Criteria

- [ ] Hydrion produces a web build artifact.
- [ ] Standalone display and icon metadata are available.
- [ ] Default Flutter title/description are replaced with Hydrion product metadata.
- [ ] Remaining end-to-end user behavior for this story is implemented, verified, and ready for release..

#### Acceptance Criteria Coverage

* Checked acceptance criteria: 0.
* Unchecked acceptance criteria: 4.
* Checked criteria are tied to the repository evidence listed in this story.
* Unchecked criteria represent work or verification still needed before the criterion can be claimed complete.

#### Dependencies

* `HYD-US-001`
* `HYD-US-050`

#### Non-Functional Requirements

* Keep the behavior offline-tolerant and honest about local-first limits.
* Keep user-visible behavior responsive on the supported web and Android MVP targets.
* Do not expose secrets, provider diagnostics, or disabled integrations in a misleading way.
* Preserve capability gating until the unchecked acceptance criteria are implemented and verified.

#### Out of Scope

* Service-worker custom offline caching strategy beyond Flutter defaults, web push notifications, or cloud hosting.

#### Repository Evidence

* `README.md`
* `web/manifest.json`
* `web/index.html`
* `.github/workflows/flutter-ci.yml`

#### Story Quality Checklist

- [x] web user and outcome are specific to Run as a Web App With PWA Metadata.
- [x] Scope is bounded to Partial MVP behavior: The web build should behave like a credible installable Hydrion PWA, not a default Flutter scaffold..
- [x] Primary dependency is `HYD-US-001`; full dependency list is explicit.
- [x] Checked claims cite repository evidence beginning with `README.md`.
- [ ] Acceptance coverage is 0/4; 4 acceptance criteria remain open.

#### INVEST Check

- [x] Independent: 2 listed dependency link(s) for Run as a Web App With PWA Metadata.
- [x] Negotiable: implementation detail stays in repository evidence, not hidden in the Operational Story title.
- [x] Valuable: web user needs Hydrion to build and launch as a Flutter web app with PWA metadata so I can use the local-first hydration experience in a browser.
- [x] Estimable: story size is 3 with evidence and open criteria visible.
- [x] Small: size 3 is within a focused slice.
- [x] Testable: 4 checkbox criterion/criteria and test/build evidence are listed.

#### Definition of Ready

- [x] Metadata is complete: P1, MVP, MVP Release Readiness, Product Backlog rank 027, size 3.
- [x] Dependencies are named for sequencing; first dependency is `HYD-US-001`.
- [x] Acceptance criteria are checkbox-based and currently 0 checked / 4 unchecked.
- [x] Repository evidence is available for current claims; first evidence item is `README.md`.
- [x] Ready state reflects Partial: ready to pull or maintain.

#### Definition of Done

- [ ] Implementation status is Implemented for Run as a Web App With PWA Metadata.
- [ ] All acceptance criteria are checked for this story (0/4).
- [x] Verification evidence includes automated tests or CI/docs.
- [x] Project workflow metadata is valid: Product Backlog, rank 027, size 3.
- [ ] Done means implemented, verified, and no open criteria for Run as a Web App With PWA Metadata.

### HYD-US-037: Build Android APK

**Epic:** Platform and PWA Capabilities  
**Story Type:** Operational Story  
**Implementation Status:** Implemented  
**Priority:** P1  
**Release Scope:** MVP
**Labels:** `user-story`, `type:operations`, `priority:p1`, `status:implemented`, `scope:mvp`, `area:platform`, `area:release`, `area:android`, `size:3`  
**Milestone:** MVP Release Readiness
**Story Size:** 3
**Project Column:** Product Backlog  
**Business Rank:** 028

#### User Story

**As a** Hydrion stakeholder
**I need** Hydrion to build as an Android APK
**So that** the MVP can be validated on Android devices or internal release channels.

#### Description

* Android APK builds must remain available through the documented Flutter/CI path so Hydrion can be tested on the main mobile target.
* The story covers build support, not Play Store release hardening.

#### Details and Business Rules

* README includes `flutter build apk --release`.
* CI build job builds and uploads the Android APK.
* Android manifest and Gradle config are standard Flutter output.
* Business rule: Android build success is required for MVP validation, but release signing and store deployment are outside this story.
#### Data and State Requirements

* Provider-facing state must avoid persisted production secrets and must preserve local fallback behavior.

#### Assumptions

* No additional product assumption is made beyond the repository evidence and explicit out-of-scope notes.

#### Acceptance Criteria

- [x] Hydrion produces a release APK artifact.
- [x] `hydrion-android-apk` contains the generated APK.
- [x] Default app id, label, and debug signing are flagged before production release.

#### Acceptance Criteria Coverage

* Checked acceptance criteria: 3.
* Unchecked acceptance criteria: 0.
* Checked criteria are tied to the repository evidence listed in this story.
* Unchecked criteria represent work or verification still needed before the criterion can be claimed complete.

#### Dependencies

* `HYD-US-001`
* `HYD-US-050`

#### Non-Functional Requirements

* Keep the behavior offline-tolerant and honest about local-first limits.
* Keep user-visible behavior responsive on the supported web and Android MVP targets.
* Do not expose secrets, provider diagnostics, or disabled integrations in a misleading way.

#### Out of Scope

* Store listing, production signing, Play Console deployment, or native integrations.

#### Repository Evidence

* `README.md`
* `android/app/build.gradle.kts`
* `android/app/src/main/AndroidManifest.xml`
* `.github/workflows/flutter-ci.yml`

#### Story Quality Checklist

- [x] Hydrion stakeholder and outcome are specific to Build Android APK.
- [x] Scope is bounded to Implemented MVP behavior: Android APK builds must remain available through the documented Flutter/CI path so Hydrion can be tested....
- [x] Primary dependency is `HYD-US-001`; full dependency list is explicit.
- [x] Checked claims cite repository evidence beginning with `README.md`.
- [x] Acceptance coverage is 3/3; 0 acceptance criteria remain open.

#### INVEST Check

- [x] Independent: 2 listed dependency link(s) for Build Android APK.
- [x] Negotiable: implementation detail stays in repository evidence, not hidden in the Operational Story title.
- [x] Valuable: Hydrion stakeholder needs Hydrion to build as an Android APK so the MVP can be validated on Android devices or internal release channels.
- [x] Estimable: story size is 3 with evidence and open criteria visible.
- [x] Small: size 3 is within a focused slice.
- [x] Testable: 3 checkbox criterion/criteria and test/build evidence are listed.

#### Definition of Ready

- [x] Metadata is complete: P1, MVP, MVP Release Readiness, Product Backlog rank 028, size 3.
- [x] Dependencies are named for sequencing; first dependency is `HYD-US-001`.
- [x] Acceptance criteria are checkbox-based and currently 3 checked / 0 unchecked.
- [x] Repository evidence is available for current claims; first evidence item is `README.md`.
- [x] Ready state reflects Implemented: ready to pull or maintain.

#### Definition of Done

- [x] Implementation status is Implemented for Build Android APK.
- [x] All acceptance criteria are checked for this story (3/3).
- [x] Verification evidence includes automated tests or CI/docs.
- [x] Project workflow metadata is valid: Product Backlog, rank 028, size 3.
- [x] Done means implemented, verified, and no open criteria for Build Android APK.

### HYD-US-038: Design Cloud, Social, BYOK, OpenAI, and Edge Integrations

**Epic:** External Provider Integration  
**Story Type:** Architecture Story  
**Implementation Status:** Post-MVP  
**Priority:** P3  
**Release Scope:** Post-MVP
**Labels:** `user-story`, `type:architecture`, `priority:p3`, `status:post-mvp`, `scope:post-mvp`, `area:ai-provider`, `area:security`, `area:cloud-sync`, `area:social`, `area:byok`, `area:openai`, `area:edge`, `size:13`  
**Milestone:** Post-MVP Cloud/Social Sync
**Story Size:** 13
**Project Column:** Ice Box  
**Business Rank:** 005

#### User Story

**As a** future integration owner
**I need** cloud/social/provider integrations to be designed before implementation
**So that** user privacy, consent, credentials, moderation, and sync conflicts are handled responsibly.

#### Description

* Cloud sync, social features, BYOK, OpenAI, and edge model packs are broad future product directions that need architecture before implementation.
* They are intentionally Ice Box work because they affect privacy, credentials, backend scope, and user trust.

#### Details and Business Rules

* Firebase and OpenAI configs are placeholders/future only.
* BYOK, edge LLM, and separate Gemini connector packs are not wired into Flutter runtime.
* local challenges have no social backend.
* README and architecture docs prohibit production shared provider keys in clients.
* Business rule: Future integration designs must not weaken the current local-first privacy baseline.
#### Data and State Requirements

* Provider-facing state must avoid persisted production secrets and must preserve local fallback behavior.
* Integration state must be represented through capability status, adapter contracts, or disabled placeholders until a real adapter is implemented.

#### Assumptions

* No additional product assumption is made beyond the repository evidence and explicit out-of-scope notes.

#### Acceptance Criteria

- [x] No active runtime path depends on those systems.
- [ ] The design includes auth, privacy, consent, conflict handling, export/delete behavior, and tests.
- [ ] Shared production secrets are not shipped in client artifacts.
- [ ] Remaining end-to-end user behavior for this story is implemented, verified, and ready for release..

#### Acceptance Criteria Coverage

* Checked acceptance criteria: 1.
* Unchecked acceptance criteria: 3.
* Checked criteria are tied to the repository evidence listed in this story.
* Unchecked criteria represent work or verification still needed before the criterion can be claimed complete.

#### Dependencies

* `HYD-US-031`
* `HYD-US-041`
* `HYD-US-051`

#### Non-Functional Requirements

* Keep the behavior offline-tolerant and honest about local-first limits.
* Keep user-visible behavior responsive on the supported web and Android MVP targets.
* Do not expose secrets, provider diagnostics, or disabled integrations in a misleading way.
* Preserve capability gating until the unchecked acceptance criteria are implemented and verified.

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

#### Story Quality Checklist

- [x] future integration owner and outcome are specific to Design Cloud, Social, BYOK, OpenAI, and Edge Integrations.
- [x] Scope is bounded to Post-MVP Post-MVP behavior: Cloud sync, social features, BYOK, OpenAI, and edge model packs are broad future product directions that....
- [x] Primary dependency is `HYD-US-031`; full dependency list is explicit.
- [x] Checked claims cite repository evidence beginning with `config/open_ai_config.yaml`.
- [ ] Acceptance coverage is 1/4; 3 acceptance criteria remain open.

#### INVEST Check

- [x] Independent: 3 listed dependency link(s) for Design Cloud, Social, BYOK, OpenAI, and Edge Integrations.
- [x] Negotiable: implementation detail stays in repository evidence, not hidden in the Architecture Story title.
- [x] Valuable: future integration owner needs cloud/social/provider integrations to be designed before implementation so user privacy, consent, credentials, moderation, and sync conflicts are handled responsibly.
- [x] Estimable: story size is 13 with evidence and open criteria visible.
- [ ] Small: size 13 is too large and should be split before sprint pull.
- [x] Testable: 4 checkbox criterion/criteria and planned verification are listed.

#### Definition of Ready

- [x] Metadata is complete: P3, Post-MVP, Post-MVP Cloud/Social Sync, Ice Box rank 005, size 13.
- [x] Dependencies are named for sequencing; first dependency is `HYD-US-031`.
- [x] Acceptance criteria are checkbox-based and currently 1 checked / 3 unchecked.
- [x] Repository evidence is available for current claims; first evidence item is `config/open_ai_config.yaml`.
- [ ] Ready state reflects Post-MVP: needs implementation, split, or uncertainty cleanup before sprint pull.

#### Definition of Done

- [ ] Implementation status is Implemented for Design Cloud, Social, BYOK, OpenAI, and Edge Integrations.
- [ ] All acceptance criteria are checked for this story (1/4).
- [ ] Verification evidence includes no automated test/CI evidence yet.
- [x] Project workflow metadata is valid: Ice Box, rank 005, size 13.
- [ ] Done means implemented, verified, and no open criteria for Design Cloud, Social, BYOK, OpenAI, and Edge Integrations.

### HYD-US-039: Manage Coach Prompt Templates Safely

**Epic:** Local Hydration Coach  
**Story Type:** Enabler Story  
**Implementation Status:** Partial  
**Priority:** P2  
**Release Scope:** Supporting
**Labels:** `user-story`, `type:enabler`, `priority:p2`, `status:partial`, `scope:supporting`, `area:coach`, `area:ai-provider`, `area:prompts`, `size:3`  
**Milestone:** MVP AI Provider Safety
**Story Size:** 3
**Project Column:** Product Backlog  
**Business Rank:** 031

#### User Story

**As a** coach-content maintainer
**I need** prompt templates and active provider prompts to be managed without confusing dormant scaffolds for runtime behavior
**So that** provider guidance stays auditable and safe.

#### Description

* Prompt templates need safe ownership and wiring so coach behavior can evolve without stale config misleading maintainers.
* The current state is partial because templates exist but are not fully active in the main local/Gemini coach path.

#### Details and Business Rules

* `LLMPromptBuilder` can load `config/prompt_templates.yaml`.
* architecture audit classifies `config/prompt_templates.yaml` as dormant because active Gemini/local coach does not use it.
* Gemini adapter builds its active prompt inline from typed `HydrationContext` and action rules.
* Business rule: Prompt template files must not be treated as runtime truth until the active coach path consumes and tests them.
#### Data and State Requirements

* Provider-facing state must avoid persisted production secrets and must preserve local fallback behavior.
* Integration state must be represented through capability status, adapter contracts, or disabled placeholders until a real adapter is implemented.

#### Assumptions

* future prompt-template work should preserve typed action schema and capability safety.

#### Acceptance Criteria

- [ ] Variables are interpolated and empty or missing templates throw a prompt builder error.
- [x] It uses typed context and action-contract instructions, not dormant template config.
- [x] Tests verify schema, capability safety, localization, and no clinical claims.
- [ ] Remaining end-to-end user behavior for this story is implemented, verified, and ready for release..

#### Acceptance Criteria Coverage

* Checked acceptance criteria: 2.
* Unchecked acceptance criteria: 2.
* Checked criteria are tied to the repository evidence listed in this story.
* Unchecked criteria represent work or verification still needed before the criterion can be claimed complete.

#### Dependencies

* `HYD-US-023`
* `HYD-US-031`
* `HYD-US-032`

#### Non-Functional Requirements

* Keep the behavior offline-tolerant and honest about local-first limits.
* Keep user-visible behavior responsive on the supported web and Android MVP targets.
* Do not expose secrets, provider diagnostics, or disabled integrations in a misleading way.
* Preserve capability gating until the unchecked acceptance criteria are implemented and verified.

#### Out of Scope

* Activating OpenAI prompts, remote prompt management, or untyped provider prompts.

#### Repository Evidence

* `lib/utils/llm_prompt_builder.dart`
* `config/prompt_templates.yaml`
* `lib/adapters/gemini/gemini_adapter.dart`
* `docs/architecture/STALE_SCAFFOLD_AUDIT.md`

#### Story Quality Checklist

- [x] coach-content maintainer and outcome are specific to Manage Coach Prompt Templates Safely.
- [x] Scope is bounded to Partial Supporting behavior: Prompt templates need safe ownership and wiring so coach behavior can evolve without stale config misleading....
- [x] Primary dependency is `HYD-US-023`; full dependency list is explicit.
- [x] Checked claims cite repository evidence beginning with `lib/utils/llm_prompt_builder.dart`.
- [ ] Acceptance coverage is 2/4; 2 acceptance criteria remain open.

#### INVEST Check

- [x] Independent: 3 listed dependency link(s) for Manage Coach Prompt Templates Safely.
- [x] Negotiable: implementation detail stays in repository evidence, not hidden in the Enabler Story title.
- [x] Valuable: coach-content maintainer needs prompt templates and active provider prompts to be managed without confusing dormant scaffolds for runtime behavior so provider guidance stays auditable and safe.
- [x] Estimable: story size is 3 with evidence and open criteria visible.
- [x] Small: size 3 is within a focused slice.
- [x] Testable: 4 checkbox criterion/criteria and planned verification are listed.

#### Definition of Ready

- [x] Metadata is complete: P2, Supporting, MVP AI Provider Safety, Product Backlog rank 031, size 3.
- [x] Dependencies are named for sequencing; first dependency is `HYD-US-023`.
- [x] Acceptance criteria are checkbox-based and currently 2 checked / 2 unchecked.
- [x] Repository evidence is available for current claims; first evidence item is `lib/utils/llm_prompt_builder.dart`.
- [x] Ready state reflects Partial: ready to pull or maintain.

#### Definition of Done

- [ ] Implementation status is Implemented for Manage Coach Prompt Templates Safely.
- [ ] All acceptance criteria are checked for this story (2/4).
- [ ] Verification evidence includes no automated test/CI evidence yet.
- [x] Project workflow metadata is valid: Product Backlog, rank 031, size 3.
- [ ] Done means implemented, verified, and no open criteria for Manage Coach Prompt Templates Safely.

### HYD-US-040: Keep Stale and Future Scaffolds Truthful

**Epic:** Maintenance and Quality Requirements  
**Story Type:** Operational Story  
**Implementation Status:** Partial  
**Priority:** P1  
**Release Scope:** Supporting
**Labels:** `user-story`, `type:operations`, `priority:p1`, `status:partial`, `scope:supporting`, `area:release`, `area:quality`, `area:docs`, `size:5`  
**Milestone:** MVP Release Readiness
**Story Size:** 5
**Project Column:** Product Backlog  
**Business Rank:** 032

#### User Story

**As a** contributor
**I need** stale configs, scripts, and blueprints to be labeled separately from active runtime behavior
**So that** Hydrion's MVP scope stays honest and maintainable.

#### Description

* Hydrion contains future scaffolds and config that can easily be mistaken for shipped behavior, so documentation and status reporting must stay honest.
* This story protects roadmap clarity by calling out stale or dormant paths instead of letting them become accidental product claims.

#### Details and Business Rules

* `docs/architecture/STALE_SCAFFOLD_AUDIT.md` classifies active, dormant, future, stale, and experimental folders.
* `config/app.yaml` claims BLE, voice, and wearable sync enabled, contradicting runtime capabilities.
* `scripts/test_all.sh` references old `app/`, KMP/Gradle, and integration paths.
* `overview`, `hydrion.txt`, and `p1.txt` describe a broader future/historical architecture not fully present in the repo.
* Business rule: Stale config, blueprint, or scaffold files cannot override verified runtime behavior.
#### Data and State Requirements

* Integration state must be represented through capability status, adapter contracts, or disabled placeholders until a real adapter is implemented.

#### Assumptions

* No additional product assumption is made beyond the repository evidence and explicit out-of-scope notes.

#### Acceptance Criteria

- [ ] Documentation marks them as non-runtime truth before release.
- [x] Capability reporter and Settings are treated as runtime truth.
- [x] Implementation, tests, docs, and capability status are updated together.
- [ ] Remaining end-to-end user behavior for this story is implemented, verified, and ready for release..

#### Acceptance Criteria Coverage

* Checked acceptance criteria: 2.
* Unchecked acceptance criteria: 2.
* Checked criteria are tied to the repository evidence listed in this story.
* Unchecked criteria represent work or verification still needed before the criterion can be claimed complete.

#### Dependencies

* `HYD-US-028`
* `HYD-US-031`
* `HYD-US-050`

#### Non-Functional Requirements

* Keep the behavior offline-tolerant and honest about local-first limits.
* Keep user-visible behavior responsive on the supported web and Android MVP targets.
* Do not expose secrets, provider diagnostics, or disabled integrations in a misleading way.
* Preserve capability gating until the unchecked acceptance criteria are implemented and verified.

#### Out of Scope

* Deleting future work solely because it is inactive.

#### Repository Evidence

* `docs/architecture/STALE_SCAFFOLD_AUDIT.md`
* `config/app.yaml`
* `scripts/test_all.sh`
* `overview`
* `hydrion.txt`
* `p1.txt`

#### Story Quality Checklist

- [x] contributor and outcome are specific to Keep Stale and Future Scaffolds Truthful.
- [x] Scope is bounded to Partial Supporting behavior: Hydrion contains future scaffolds and config that can easily be mistaken for shipped behavior, so documentation....
- [x] Primary dependency is `HYD-US-028`; full dependency list is explicit.
- [x] Checked claims cite repository evidence beginning with `docs/architecture/STALE_SCAFFOLD_AUDIT.md`.
- [ ] Acceptance coverage is 2/4; 2 acceptance criteria remain open.

#### INVEST Check

- [x] Independent: 3 listed dependency link(s) for Keep Stale and Future Scaffolds Truthful.
- [x] Negotiable: implementation detail stays in repository evidence, not hidden in the Operational Story title.
- [x] Valuable: contributor needs stale configs, scripts, and blueprints to be labeled separately from active runtime behavior so Hydrion's MVP scope stays honest and maintainable.
- [x] Estimable: story size is 5 with evidence and open criteria visible.
- [x] Small: size 5 is within a focused slice.
- [x] Testable: 4 checkbox criterion/criteria and planned verification are listed.

#### Definition of Ready

- [x] Metadata is complete: P1, Supporting, MVP Release Readiness, Product Backlog rank 032, size 5.
- [x] Dependencies are named for sequencing; first dependency is `HYD-US-028`.
- [x] Acceptance criteria are checkbox-based and currently 2 checked / 2 unchecked.
- [x] Repository evidence is available for current claims; first evidence item is `docs/architecture/STALE_SCAFFOLD_AUDIT.md`.
- [x] Ready state reflects Partial: ready to pull or maintain.

#### Definition of Done

- [ ] Implementation status is Implemented for Keep Stale and Future Scaffolds Truthful.
- [ ] All acceptance criteria are checked for this story (2/4).
- [ ] Verification evidence includes no automated test/CI evidence yet.
- [x] Project workflow metadata is valid: Product Backlog, rank 032, size 5.
- [ ] Done means implemented, verified, and no open criteria for Keep Stale and Future Scaffolds Truthful.

### HYD-US-041: Preserve Local-First Privacy Baseline

**Epic:** Privacy and Local-First Operation  
**Story Type:** Security Story  
**Implementation Status:** Implemented  
**Priority:** P0  
**Release Scope:** MVP
**Labels:** `user-story`, `type:security`, `priority:p0`, `status:implemented`, `scope:mvp`, `area:privacy`, `area:security`, `area:persistence`, `area:local-first`, `size:3`  
**Milestone:** MVP Stabilization
**Story Size:** 3
**Project Column:** Product Backlog  
**Business Rank:** 001

#### User Story

**As a** privacy-conscious user
**I need** Hydrion to work locally by default
**So that** my hydration history remains on the device unless I explicitly configure a non-local provider.

#### Description

* Hydrion's privacy baseline is local-first: core hydration workflows must run without accounts, cloud storage, or production provider keys.
* This story anchors the MVP trust model and constrains all future provider/native/cloud work.

#### Details and Business Rules

* local_rules is default and requires no network.
* Settings privacy copy says local_rules keeps hydration context on device.
* optional Gemini is local-development only and requires explicit configuration.
* Business rule: Core hydration tracking must remain usable without remote identity, remote storage, or shared production credentials.
#### Data and State Requirements

* Provider-facing state must avoid persisted production secrets and must preserve local fallback behavior.
* Integration state must be represented through capability status, adapter contracts, or disabled placeholders until a real adapter is implemented.

#### Assumptions

* No additional product assumption is made beyond the repository evidence and explicit out-of-scope notes.

#### Acceptance Criteria

- [x] Hydrion uses local repositories and local_rules without provider network dependency.
- [x] Hydrion discloses that typed hydration context may leave the device.
- [x] Explicit consent and a provider disable path are required before release.

#### Acceptance Criteria Coverage

* Checked acceptance criteria: 3.
* Unchecked acceptance criteria: 0.
* Checked criteria are tied to the repository evidence listed in this story.
* Unchecked criteria represent work or verification still needed before the criterion can be claimed complete.

#### Dependencies

* `HYD-US-001`
* `HYD-US-031`
* `HYD-US-032`

#### Non-Functional Requirements

* Keep the behavior offline-tolerant and honest about local-first limits.
* Keep user-visible behavior responsive on the supported web and Android MVP targets.
* Do not expose secrets, provider diagnostics, or disabled integrations in a misleading way.

#### Out of Scope

* Full privacy policy text, encrypted local storage, export/delete controls, or legal compliance certification.

#### Repository Evidence

* `README.md`
* `lib/ui/screens/settings_screen.dart`
* `lib/services/ai_provider_config.dart`
* `docs/architecture/PROVIDER_SECURITY.md`
* `test/product_qa_test.dart`

#### Story Quality Checklist

- [x] privacy-conscious user and outcome are specific to Preserve Local-First Privacy Baseline.
- [x] Scope is bounded to Implemented MVP behavior: Hydrion's privacy baseline is local-first: core hydration workflows must run without accounts, cloud storage, or production....
- [x] Primary dependency is `HYD-US-001`; full dependency list is explicit.
- [x] Checked claims cite repository evidence beginning with `README.md`.
- [x] Acceptance coverage is 3/3; 0 acceptance criteria remain open.

#### INVEST Check

- [x] Independent: 3 listed dependency link(s) for Preserve Local-First Privacy Baseline.
- [x] Negotiable: implementation detail stays in repository evidence, not hidden in the Security Story title.
- [x] Valuable: privacy-conscious user needs Hydrion to work locally by default so my hydration history remains on the device unless I explicitly configure a non-local provider.
- [x] Estimable: story size is 3 with evidence and open criteria visible.
- [x] Small: size 3 is within a focused slice.
- [x] Testable: 3 checkbox criterion/criteria and test/build evidence are listed.

#### Definition of Ready

- [x] Metadata is complete: P0, MVP, MVP Stabilization, Product Backlog rank 001, size 3.
- [x] Dependencies are named for sequencing; first dependency is `HYD-US-001`.
- [x] Acceptance criteria are checkbox-based and currently 3 checked / 0 unchecked.
- [x] Repository evidence is available for current claims; first evidence item is `README.md`.
- [x] Ready state reflects Implemented: ready to pull or maintain.

#### Definition of Done

- [x] Implementation status is Implemented for Preserve Local-First Privacy Baseline.
- [x] All acceptance criteria are checked for this story (3/3).
- [x] Verification evidence includes automated tests or CI/docs.
- [x] Project workflow metadata is valid: Product Backlog, rank 001, size 3.
- [x] Done means implemented, verified, and no open criteria for Preserve Local-First Privacy Baseline.

### HYD-US-042: Protect, Export, and Delete Local Personal Data

**Epic:** Privacy and Local-First Operation  
**Story Type:** Security Story  
**Implementation Status:** Partial  
**Priority:** P0  
**Release Scope:** MVP
**Labels:** `user-story`, `type:security`, `priority:p0`, `status:partial`, `scope:mvp`, `area:privacy`, `area:security`, `area:persistence`, `area:data-rights`, `size:8`  
**Milestone:** MVP Stabilization
**Story Size:** 8
**Project Column:** Product Backlog  
**Business Rank:** 013

#### User Story

**As a** privacy-conscious returning user
**I need** clear protection, export, and deletion controls for local hydration data
**So that** I can manage personal wellness data responsibly.

#### Description

* Users need stronger control over locally stored personal data, including protection, export, and deletion paths.
* The current state is partial because local persistence exists, but dedicated encryption/export/delete privacy controls are not complete.

#### Details and Business Rules

* hydration logs, settings, reminders, and challenge state persist locally.
* repositories expose clear methods in code, but no complete user-facing data export/delete settings workflow exists.
* local storage is shared preferences, not SQLCipher or OS-vault-backed encryption.
* roadmap flags local data protection as a release decision.
* Business rule: Do not claim full data-rights support until export, delete, and protection behaviors are user-facing and verified.
#### Data and State Requirements

* Local application state must remain scoped to Hydrion repositories and the `shared_preferences` backed local store unless the story explicitly says otherwise.
* Provider-facing state must avoid persisted production secrets and must preserve local fallback behavior.
* Integration state must be represented through capability status, adapter contracts, or disabled placeholders until a real adapter is implemented.

#### Assumptions

* No additional product assumption is made beyond the repository evidence and explicit out-of-scope notes.

#### Acceptance Criteria

- [x] Hydrion produces a documented local export without sending data to a backend.
- [ ] Hydration logs, reminders, settings, and challenge state are removed or reset according to documented policy.
- [ ] The gap is explicitly accepted or implemented before beta.
- [ ] Remaining end-to-end user behavior for this story is implemented, verified, and ready for release..

#### Acceptance Criteria Coverage

* Checked acceptance criteria: 1.
* Unchecked acceptance criteria: 3.
* Checked criteria are tied to the repository evidence listed in this story.
* Unchecked criteria represent work or verification still needed before the criterion can be claimed complete.

#### Dependencies

* `HYD-US-004`
* `HYD-US-015`
* `HYD-US-018`
* `HYD-US-027`

#### Non-Functional Requirements

* Keep the behavior offline-tolerant and honest about local-first limits.
* Keep user-visible behavior responsive on the supported web and Android MVP targets.
* Do not expose secrets, provider diagnostics, or disabled integrations in a misleading way.
* Preserve capability gating until the unchecked acceptance criteria are implemented and verified.

#### Out of Scope

* Cloud account deletion or synced-data conflict resolution.

#### Repository Evidence

* `lib/storage/local_store.dart`
* `lib/repositories/hydration_repository.dart`
* `lib/repositories/reminder_repository.dart`
* `lib/repositories/challenge_repository.dart`
* `HYDRION_MVP_KANBAN_ROADMAP.md`
* `docs/architecture/PROVIDER_SECURITY.md`

#### Story Quality Checklist

- [x] privacy-conscious returning user and outcome are specific to Protect, Export, and Delete Local Personal Data.
- [x] Scope is bounded to Partial MVP behavior: Users need stronger control over locally stored personal data, including protection, export, and deletion paths..
- [x] Primary dependency is `HYD-US-004`; full dependency list is explicit.
- [x] Checked claims cite repository evidence beginning with `lib/storage/local_store.dart`.
- [ ] Acceptance coverage is 1/4; 3 acceptance criteria remain open.

#### INVEST Check

- [x] Independent: 4 listed dependency link(s) for Protect, Export, and Delete Local Personal Data.
- [x] Negotiable: implementation detail stays in repository evidence, not hidden in the Security Story title.
- [x] Valuable: privacy-conscious returning user needs clear protection, export, and deletion controls for local hydration data so I can manage personal wellness data responsibly.
- [x] Estimable: story size is 8 with evidence and open criteria visible.
- [ ] Small: size 8 is too large and should be split before sprint pull.
- [x] Testable: 4 checkbox criterion/criteria and planned verification are listed.

#### Definition of Ready

- [x] Metadata is complete: P0, MVP, MVP Stabilization, Product Backlog rank 013, size 8.
- [x] Dependencies are named for sequencing; first dependency is `HYD-US-004`.
- [x] Acceptance criteria are checkbox-based and currently 1 checked / 3 unchecked.
- [x] Repository evidence is available for current claims; first evidence item is `lib/storage/local_store.dart`.
- [x] Ready state reflects Partial: ready to pull or maintain.

#### Definition of Done

- [ ] Implementation status is Implemented for Protect, Export, and Delete Local Personal Data.
- [ ] All acceptance criteria are checked for this story (1/4).
- [ ] Verification evidence includes no automated test/CI evidence yet.
- [x] Project workflow metadata is valid: Product Backlog, rank 013, size 8.
- [ ] Done means implemented, verified, and no open criteria for Protect, Export, and Delete Local Personal Data.

### HYD-US-043: Recover Gracefully From Invalid Stored Data

**Epic:** Data Persistence and Recovery  
**Story Type:** System Story  
**Implementation Status:** Implemented  
**Priority:** P0  
**Release Scope:** Supporting
**Labels:** `user-story`, `type:system`, `priority:p0`, `status:implemented`, `scope:supporting`, `area:persistence`, `area:reliability`, `size:3`  
**Milestone:** MVP Stabilization
**Story Size:** 3
**Project Column:** Product Backlog  
**Business Rank:** 005

#### User Story

**As a** returning user
**I need** Hydrion to handle corrupt or invalid local data without crashing
**So that** a bad stored payload does not block app access.

#### Description

* Hydrion must recover gracefully when local stored data is malformed, stale, or partially invalid.
* Recovery should protect the user from crashes while preserving valid data whenever possible.

#### Details and Business Rules

* repositories catch malformed JSON and return default/empty state.
* hydration log decode drops invalid entries.
* settings fallback to English.
* Business rule: Invalid local records must be filtered or reset safely instead of crashing app startup or core screens.
#### Data and State Requirements

* Local application state must remain scoped to Hydrion repositories and the `shared_preferences` backed local store unless the story explicitly says otherwise.
* Integration state must be represented through capability status, adapter contracts, or disabled placeholders until a real adapter is implemented.

#### Assumptions

* No additional product assumption is made beyond the repository evidence and explicit out-of-scope notes.

#### Acceptance Criteria

- [x] It returns an empty log list without throwing.
- [x] The invalid reminder is skipped.
- [x] Hydrion uses English defaults.

#### Acceptance Criteria Coverage

* Checked acceptance criteria: 3.
* Unchecked acceptance criteria: 0.
* Checked criteria are tied to the repository evidence listed in this story.
* Unchecked criteria represent work or verification still needed before the criterion can be claimed complete.

#### Dependencies

* `HYD-US-004`
* `HYD-US-027`

#### Non-Functional Requirements

* Keep the behavior offline-tolerant and honest about local-first limits.
* Keep user-visible behavior responsive on the supported web and Android MVP targets.
* Do not expose secrets, provider diagnostics, or disabled integrations in a misleading way.

#### Out of Scope

* Versioned migrations, user-visible quarantine reports, or repair UI.

#### Repository Evidence

* `lib/repositories/hydration_repository.dart`
* `lib/repositories/reminder_repository.dart`
* `lib/repositories/challenge_repository.dart`
* `lib/repositories/settings_repository.dart`
* `test/persistence_test.dart`

#### Story Quality Checklist

- [x] returning user and outcome are specific to Recover Gracefully From Invalid Stored Data.
- [x] Scope is bounded to Implemented Supporting behavior: Hydrion must recover gracefully when local stored data is malformed, stale, or partially invalid..
- [x] Primary dependency is `HYD-US-004`; full dependency list is explicit.
- [x] Checked claims cite repository evidence beginning with `lib/repositories/hydration_repository.dart`.
- [x] Acceptance coverage is 3/3; 0 acceptance criteria remain open.

#### INVEST Check

- [x] Independent: 2 listed dependency link(s) for Recover Gracefully From Invalid Stored Data.
- [x] Negotiable: implementation detail stays in repository evidence, not hidden in the System Story title.
- [x] Valuable: returning user needs Hydrion to handle corrupt or invalid local data without crashing so a bad stored payload does not block app access.
- [x] Estimable: story size is 3 with evidence and open criteria visible.
- [x] Small: size 3 is within a focused slice.
- [x] Testable: 3 checkbox criterion/criteria and test/build evidence are listed.

#### Definition of Ready

- [x] Metadata is complete: P0, Supporting, MVP Stabilization, Product Backlog rank 005, size 3.
- [x] Dependencies are named for sequencing; first dependency is `HYD-US-004`.
- [x] Acceptance criteria are checkbox-based and currently 3 checked / 0 unchecked.
- [x] Repository evidence is available for current claims; first evidence item is `lib/repositories/hydration_repository.dart`.
- [x] Ready state reflects Implemented: ready to pull or maintain.

#### Definition of Done

- [x] Implementation status is Implemented for Recover Gracefully From Invalid Stored Data.
- [x] All acceptance criteria are checked for this story (3/3).
- [x] Verification evidence includes automated tests or CI/docs.
- [x] Project workflow metadata is valid: Product Backlog, rank 005, size 3.
- [x] Done means implemented, verified, and no open criteria for Recover Gracefully From Invalid Stored Data.

### HYD-US-044: Provide Reliable Error Handling and Fallback UX

**Epic:** Error Handling and Reliability  
**Story Type:** Operational Story  
**Implementation Status:** Implemented  
**Priority:** P1  
**Release Scope:** Supporting
**Labels:** `user-story`, `type:operations`, `priority:p1`, `status:implemented`, `scope:supporting`, `area:reliability`, `size:5`  
**Milestone:** MVP Release Readiness
**Story Size:** 5
**Project Column:** Product Backlog  
**Business Rank:** 033

#### User Story

**As a** Hydrion stakeholder
**I need** Hydrion to fail gracefully across local and optional-provider flows
**So that** errors do not corrupt data or leave me without usable guidance.

#### Description

* Core workflows need reliable fallback and error handling so repository failures or provider issues do not leave users stuck.
* The story covers user-facing recovery for logging, editing, deleting, advice, and provider fallback paths.

#### Details and Business Rules

* advice card has loading, error, and retry states.
* chat catches coach errors and shows a localized error snack bar.
* provider failures fall back to local_rules with safe diagnostics.
* repository edit/delete failures show "log not found" feedback.
* Business rule: Errors must produce recoverable UI states and must not silently corrupt local hydration data.
#### Data and State Requirements

* Local application state must remain scoped to Hydrion repositories and the `shared_preferences` backed local store unless the story explicitly says otherwise.
* Provider-facing state must avoid persisted production secrets and must preserve local fallback behavior.
* Integration state must be represented through capability status, adapter contracts, or disabled placeholders until a real adapter is implemented.

#### Assumptions

* No additional product assumption is made beyond the repository evidence and explicit out-of-scope notes.

#### Acceptance Criteria

- [x] The user sees a retryable localized error state.
- [x] Local_rules fallback remains available.
- [x] Hydrion shows localized not-found feedback without crashing.

#### Acceptance Criteria Coverage

* Checked acceptance criteria: 3.
* Unchecked acceptance criteria: 0.
* Checked criteria are tied to the repository evidence listed in this story.
* Unchecked criteria represent work or verification still needed before the criterion can be claimed complete.

#### Dependencies

* `HYD-US-006`
* `HYD-US-007`
* `HYD-US-021`
* `HYD-US-032`

#### Non-Functional Requirements

* Keep the behavior offline-tolerant and honest about local-first limits.
* Keep user-visible behavior responsive on the supported web and Android MVP targets.
* Do not expose secrets, provider diagnostics, or disabled integrations in a misleading way.

#### Out of Scope

* Crash reporting, telemetry, or remote incident monitoring.

#### Repository Evidence

* `lib/ui/components/llm_advice_card.dart`
* `lib/ui/screens/chat_coach_screen.dart`
* `lib/services/hydration_ai_orchestrator.dart`
* `lib/ui/screens/log_screen.dart`
* `test/gemini_provider_test.dart`

#### Story Quality Checklist

- [x] Hydrion stakeholder and outcome are specific to Provide Reliable Error Handling and Fallback UX.
- [x] Scope is bounded to Implemented Supporting behavior: Core workflows need reliable fallback and error handling so repository failures or provider issues do not....
- [x] Primary dependency is `HYD-US-006`; full dependency list is explicit.
- [x] Checked claims cite repository evidence beginning with `lib/ui/components/llm_advice_card.dart`.
- [x] Acceptance coverage is 3/3; 0 acceptance criteria remain open.

#### INVEST Check

- [x] Independent: 4 listed dependency link(s) for Provide Reliable Error Handling and Fallback UX.
- [x] Negotiable: implementation detail stays in repository evidence, not hidden in the Operational Story title.
- [x] Valuable: Hydrion stakeholder needs Hydrion to fail gracefully across local and optional-provider flows so errors do not corrupt data or leave me without usable guidance.
- [x] Estimable: story size is 5 with evidence and open criteria visible.
- [x] Small: size 5 is within a focused slice.
- [x] Testable: 3 checkbox criterion/criteria and test/build evidence are listed.

#### Definition of Ready

- [x] Metadata is complete: P1, Supporting, MVP Release Readiness, Product Backlog rank 033, size 5.
- [x] Dependencies are named for sequencing; first dependency is `HYD-US-006`.
- [x] Acceptance criteria are checkbox-based and currently 3 checked / 0 unchecked.
- [x] Repository evidence is available for current claims; first evidence item is `lib/ui/components/llm_advice_card.dart`.
- [x] Ready state reflects Implemented: ready to pull or maintain.

#### Definition of Done

- [x] Implementation status is Implemented for Provide Reliable Error Handling and Fallback UX.
- [x] All acceptance criteria are checked for this story (3/3).
- [x] Verification evidence includes automated tests or CI/docs.
- [x] Project workflow metadata is valid: Product Backlog, rank 033, size 5.
- [x] Done means implemented, verified, and no open criteria for Provide Reliable Error Handling and Fallback UX.

### HYD-US-045: Support Accessibility Semantics

**Epic:** Accessibility and Responsive Design  
**Story Type:** User Story  
**Implementation Status:** Partial  
**Priority:** P1  
**Release Scope:** Supporting
**Labels:** `user-story`, `type:user-story`, `priority:p1`, `status:partial`, `scope:supporting`, `area:accessibility`, `area:frontend`, `size:5`  
**Milestone:** MVP Product UX
**Story Size:** 5
**Project Column:** Product Backlog  
**Business Rank:** 034

#### User Story

**As a** Hydrion stakeholder
**I need** meaningful labels, tooltips, semantics, and clear states
**So that** Hydrion is usable with assistive technology.

#### Description

* Hydrion should expose meaningful semantics for key controls and status components so assistive-technology users can understand progress and actions.
* The story is partial because targeted semantics exist, but a full accessibility audit is not complete.

#### Details and Business Rules

* Hydrion logo, progress ring, hydration score, achievement badges, and disabled voice button include semantics.
* important icon buttons include tooltips.
* disabled/future capabilities are labeled in UI text.
* Business rule: Accessibility claims must be limited to tested components until a full audit closes remaining gaps.
#### Data and State Requirements

* Integration state must be represented through capability status, adapter contracts, or disabled placeholders until a real adapter is implemented.

#### Assumptions

* No additional product assumption is made beyond the repository evidence and explicit out-of-scope notes.

#### Acceptance Criteria

- [ ] It exposes progress label, percent value, and consumed/target hint.
- [ ] It exposes badge name and locked/unlocked status.
- [ ] Navigation, focus order, labels, contrast, and text scaling issues are documented or fixed.
- [ ] Remaining end-to-end user behavior for this story is implemented, verified, and ready for release..

#### Acceptance Criteria Coverage

* Checked acceptance criteria: 0.
* Unchecked acceptance criteria: 4.
* Checked criteria are tied to the repository evidence listed in this story.
* Unchecked criteria represent work or verification still needed before the criterion can be claimed complete.

#### Dependencies

* `HYD-US-008`
* `HYD-US-011`
* `HYD-US-013`
* `HYD-US-026`

#### Non-Functional Requirements

* Keep the behavior offline-tolerant and honest about local-first limits.
* Keep user-visible behavior responsive on the supported web and Android MVP targets.
* Do not expose secrets, provider diagnostics, or disabled integrations in a misleading way.
* Preserve capability gating until the unchecked acceptance criteria are implemented and verified.

#### Out of Scope

* WCAG certification or full platform accessibility certification.

#### Repository Evidence

* `lib/ui/components/intake_ring.dart`
* `lib/ui/components/hydration_score_card.dart`
* `lib/ui/components/achievement_badge.dart`
* `lib/ui/components/voice_input_widget.dart`
* `lib/ui/screens/home_screen.dart`

#### Story Quality Checklist

- [x] Hydrion stakeholder and outcome are specific to Support Accessibility Semantics.
- [x] Scope is bounded to Partial Supporting behavior: Hydrion should expose meaningful semantics for key controls and status components so assistive-technology users can understand....
- [x] Primary dependency is `HYD-US-008`; full dependency list is explicit.
- [x] Checked claims cite repository evidence beginning with `lib/ui/components/intake_ring.dart`.
- [ ] Acceptance coverage is 0/4; 4 acceptance criteria remain open.

#### INVEST Check

- [x] Independent: 4 listed dependency link(s) for Support Accessibility Semantics.
- [x] Negotiable: implementation detail stays in repository evidence, not hidden in the User Story title.
- [x] Valuable: Hydrion stakeholder needs meaningful labels, tooltips, semantics, and clear states so Hydrion is usable with assistive technology.
- [x] Estimable: story size is 5 with evidence and open criteria visible.
- [x] Small: size 5 is within a focused slice.
- [x] Testable: 4 checkbox criterion/criteria and planned verification are listed.

#### Definition of Ready

- [x] Metadata is complete: P1, Supporting, MVP Product UX, Product Backlog rank 034, size 5.
- [x] Dependencies are named for sequencing; first dependency is `HYD-US-008`.
- [x] Acceptance criteria are checkbox-based and currently 0 checked / 4 unchecked.
- [x] Repository evidence is available for current claims; first evidence item is `lib/ui/components/intake_ring.dart`.
- [x] Ready state reflects Partial: ready to pull or maintain.

#### Definition of Done

- [ ] Implementation status is Implemented for Support Accessibility Semantics.
- [ ] All acceptance criteria are checked for this story (0/4).
- [ ] Verification evidence includes no automated test/CI evidence yet.
- [x] Project workflow metadata is valid: Product Backlog, rank 034, size 5.
- [ ] Done means implemented, verified, and no open criteria for Support Accessibility Semantics.

### HYD-US-046: Keep Core Screens Usable on Small Viewports

**Epic:** Accessibility and Responsive Design  
**Story Type:** User Story  
**Implementation Status:** Partial  
**Priority:** P1  
**Release Scope:** Supporting
**Labels:** `user-story`, `type:user-story`, `priority:p1`, `status:partial`, `scope:supporting`, `area:accessibility`, `area:frontend`, `size:5`  
**Milestone:** MVP Product UX
**Story Size:** 5
**Project Column:** Product Backlog  
**Business Rank:** 035

#### User Story

**As a** mobile or narrow-screen user
**I need** core Hydrion controls to remain usable on small screens
**So that** logging and navigation do not depend on desktop layout.

#### Description

* Core screens need to remain usable on narrow web and mobile viewports where hydration controls, history, and navigation compete for space.
* The story is partial because responsive behavior has targeted coverage, but full cross-screen validation remains open.

#### Details and Business Rules

* Home stacks the amount picker and log button under narrow width.
* tests verify Home usability at a 360x640 viewport.
* screens use scrollable layouts.
* Business rule: Responsive layout must preserve readable controls and prevent overlap on supported MVP viewports.
#### Data and State Requirements

* Integration state must be represented through capability status, adapter contracts, or disabled placeholders until a real adapter is implemented.

#### Assumptions

* No additional product assumption is made beyond the repository evidence and explicit out-of-scope notes.

#### Acceptance Criteria

- [ ] Logo, volume picker, log button, and progress remain reachable.
- [ ] The picker and log button stack vertically.
- [ ] Overflow and inaccessible controls are fixed before release.
- [ ] Remaining end-to-end user behavior for this story is implemented, verified, and ready for release..

#### Acceptance Criteria Coverage

* Checked acceptance criteria: 0.
* Unchecked acceptance criteria: 4.
* Checked criteria are tied to the repository evidence listed in this story.
* Unchecked criteria represent work or verification still needed before the criterion can be claimed complete.

#### Dependencies

* `HYD-US-002`
* `HYD-US-003`

#### Non-Functional Requirements

* Keep the behavior offline-tolerant and honest about local-first limits.
* Keep user-visible behavior responsive on the supported web and Android MVP targets.
* Do not expose secrets, provider diagnostics, or disabled integrations in a misleading way.
* Preserve capability gating until the unchecked acceptance criteria are implemented and verified.

#### Out of Scope

* Full visual regression infrastructure or tablet-specific layouts.

#### Repository Evidence

* `lib/ui/screens/home_screen.dart`
* `test/product_qa_test.dart`

#### Story Quality Checklist

- [x] mobile or narrow-screen user and outcome are specific to Keep Core Screens Usable on Small Viewports.
- [x] Scope is bounded to Partial Supporting behavior: Core screens need to remain usable on narrow web and mobile viewports where hydration controls, history,....
- [x] Primary dependency is `HYD-US-002`; full dependency list is explicit.
- [x] Checked claims cite repository evidence beginning with `lib/ui/screens/home_screen.dart`.
- [ ] Acceptance coverage is 0/4; 4 acceptance criteria remain open.

#### INVEST Check

- [x] Independent: 2 listed dependency link(s) for Keep Core Screens Usable on Small Viewports.
- [x] Negotiable: implementation detail stays in repository evidence, not hidden in the User Story title.
- [x] Valuable: mobile or narrow-screen user needs core Hydrion controls to remain usable on small screens so logging and navigation do not depend on desktop layout.
- [x] Estimable: story size is 5 with evidence and open criteria visible.
- [x] Small: size 5 is within a focused slice.
- [x] Testable: 4 checkbox criterion/criteria and test/build evidence are listed.

#### Definition of Ready

- [x] Metadata is complete: P1, Supporting, MVP Product UX, Product Backlog rank 035, size 5.
- [x] Dependencies are named for sequencing; first dependency is `HYD-US-002`.
- [x] Acceptance criteria are checkbox-based and currently 0 checked / 4 unchecked.
- [x] Repository evidence is available for current claims; first evidence item is `lib/ui/screens/home_screen.dart`.
- [x] Ready state reflects Partial: ready to pull or maintain.

#### Definition of Done

- [ ] Implementation status is Implemented for Keep Core Screens Usable on Small Viewports.
- [ ] All acceptance criteria are checked for this story (0/4).
- [x] Verification evidence includes automated tests or CI/docs.
- [x] Project workflow metadata is valid: Product Backlog, rank 035, size 5.
- [ ] Done means implemented, verified, and no open criteria for Keep Core Screens Usable on Small Viewports.

### HYD-US-047: Maintain Localization Quality Gates

**Epic:** Localization  
**Story Type:** Operational Story  
**Implementation Status:** Partial  
**Priority:** P1  
**Release Scope:** Supporting
**Labels:** `user-story`, `type:operations`, `priority:p1`, `status:partial`, `scope:supporting`, `area:localization`, `area:ci-cd`, `size:3`  
**Milestone:** MVP Release Readiness
**Story Size:** 3
**Project Column:** Product Backlog  
**Business Rank:** 036

#### User Story

**As a** contributor
**I need** localization quality checks to catch missing or stale strings
**So that** supported locales do not regress as features change.

#### Description

* Localization quality gates keep translated resources aligned so supported locales do not drift or ship missing app strings.
* The current state is partial because localization tests exist, but broader release gating and future-locale parity are not complete.

#### Details and Business Rules

* active ARB files exist for EN/ES/FR and tests cover many visible strings.
* CI does not explicitly run `flutter gen-l10n` or ARB parity checks in the workflow.
* roadmap identifies generated localization drift and ARB parity checks as needed.
* Business rule: Localization changes must keep generated resources and supported-locale tests in sync.
#### Data and State Requirements

* Provider-facing state must avoid persisted production secrets and must preserve local fallback behavior.
* Integration state must be represented through capability status, adapter contracts, or disabled placeholders until a real adapter is implemented.
* User-visible strings and locale state must remain compatible with generated localization resources and fallback rules.

#### Assumptions

* No additional product assumption is made beyond the repository evidence and explicit out-of-scope notes.

#### Acceptance Criteria

- [ ] Missing EN/ES/FR keys fail before release.
- [ ] The drift is detected.
- [x] Future locales are not presented as active.
- [ ] Remaining end-to-end user behavior for this story is implemented, verified, and ready for release..

#### Acceptance Criteria Coverage

* Checked acceptance criteria: 1.
* Unchecked acceptance criteria: 3.
* Checked criteria are tied to the repository evidence listed in this story.
* Unchecked criteria represent work or verification still needed before the criterion can be claimed complete.

#### Dependencies

* `HYD-US-029`
* `HYD-US-030`
* `HYD-US-050`

#### Non-Functional Requirements

* Keep the behavior offline-tolerant and honest about local-first limits.
* Keep user-visible behavior responsive on the supported web and Android MVP targets.
* Do not expose secrets, provider diagnostics, or disabled integrations in a misleading way.
* Preserve generated localization fallback behavior for supported and future locales.
* Preserve capability gating until the unchecked acceptance criteria are implemented and verified.

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

#### Story Quality Checklist

- [x] contributor and outcome are specific to Maintain Localization Quality Gates.
- [x] Scope is bounded to Partial Supporting behavior: Localization quality gates keep translated resources aligned so supported locales do not drift or ship missing....
- [x] Primary dependency is `HYD-US-029`; full dependency list is explicit.
- [x] Checked claims cite repository evidence beginning with `l10n.yaml`.
- [ ] Acceptance coverage is 1/4; 3 acceptance criteria remain open.

#### INVEST Check

- [x] Independent: 3 listed dependency link(s) for Maintain Localization Quality Gates.
- [x] Negotiable: implementation detail stays in repository evidence, not hidden in the Operational Story title.
- [x] Valuable: contributor needs localization quality checks to catch missing or stale strings so supported locales do not regress as features change.
- [x] Estimable: story size is 3 with evidence and open criteria visible.
- [x] Small: size 3 is within a focused slice.
- [x] Testable: 4 checkbox criterion/criteria and test/build evidence are listed.

#### Definition of Ready

- [x] Metadata is complete: P1, Supporting, MVP Release Readiness, Product Backlog rank 036, size 3.
- [x] Dependencies are named for sequencing; first dependency is `HYD-US-029`.
- [x] Acceptance criteria are checkbox-based and currently 1 checked / 3 unchecked.
- [x] Repository evidence is available for current claims; first evidence item is `l10n.yaml`.
- [x] Ready state reflects Partial: ready to pull or maintain.

#### Definition of Done

- [ ] Implementation status is Implemented for Maintain Localization Quality Gates.
- [ ] All acceptance criteria are checked for this story (1/4).
- [x] Verification evidence includes automated tests or CI/docs.
- [x] Project workflow metadata is valid: Product Backlog, rank 036, size 3.
- [ ] Done means implemented, verified, and no open criteria for Maintain Localization Quality Gates.

### HYD-US-048: Preserve Local Performance and Responsiveness

**Epic:** Error Handling and Reliability  
**Story Type:** Operational Story  
**Implementation Status:** Partial  
**Priority:** P2  
**Release Scope:** Supporting
**Labels:** `user-story`, `type:operations`, `priority:p2`, `status:partial`, `scope:supporting`, `area:reliability`, `area:performance`, `size:5`  
**Milestone:** MVP Release Readiness
**Story Size:** 5
**Project Column:** Product Backlog  
**Business Rank:** 037

#### User Story

**As a** Hydrion stakeholder
**I need** local logging, summaries, and coach fallback to respond quickly
**So that** Hydrion feels dependable during repeated daily use.

#### Description

* Local hydration workflows should feel responsive even as logs, analytics, provider fallback, and UI state update.
* The story is partial because targeted performance assumptions exist, but formal thresholds and broader profiling are not complete.

#### Details and Business Rules

* current repositories are in-memory lists persisted to shared preferences.
* local summary, analytics, and coach calculations run locally over repository data.
* provider calls have timeouts and fallback.
* Business rule: Performance claims must be backed by repeatable checks before they become release gates.
#### Data and State Requirements

* Provider-facing state must avoid persisted production secrets and must preserve local fallback behavior.
* Integration state must be represented through capability status, adapter contracts, or disabled placeholders until a real adapter is implemented.

#### Assumptions

* No additional product assumption is made beyond the repository evidence and explicit out-of-scope notes.

#### Acceptance Criteria

- [x] The UI updates without waiting for provider or network calls.
- [x] Hydrion falls back to local_rules within the configured timeout window.
- [ ] Measurable latency budgets and regression tests are added.
- [ ] Remaining end-to-end user behavior for this story is implemented, verified, and ready for release..

#### Acceptance Criteria Coverage

* Checked acceptance criteria: 2.
* Unchecked acceptance criteria: 2.
* Checked criteria are tied to the repository evidence listed in this story.
* Unchecked criteria represent work or verification still needed before the criterion can be claimed complete.

#### Dependencies

* `HYD-US-003`
* `HYD-US-010`
* `HYD-US-032`

#### Non-Functional Requirements

* Keep the behavior offline-tolerant and honest about local-first limits.
* Keep user-visible behavior responsive on the supported web and Android MVP targets.
* Do not expose secrets, provider diagnostics, or disabled integrations in a misleading way.
* Preserve capability gating until the unchecked acceptance criteria are implemented and verified.

#### Out of Scope

* Database indexing, Rust core optimization, or advanced profiling in the current MVP.

#### Repository Evidence

* `lib/repositories/hydration_repository.dart`
* `lib/adapters/local/local_hydrion_adapters.dart`
* `lib/services/hydration_ai_orchestrator.dart`
* `test/gemini_provider_test.dart`

#### Story Quality Checklist

- [x] Hydrion stakeholder and outcome are specific to Preserve Local Performance and Responsiveness.
- [x] Scope is bounded to Partial Supporting behavior: Local hydration workflows should feel responsive even as logs, analytics, provider fallback, and UI state update..
- [x] Primary dependency is `HYD-US-003`; full dependency list is explicit.
- [x] Checked claims cite repository evidence beginning with `lib/repositories/hydration_repository.dart`.
- [ ] Acceptance coverage is 2/4; 2 acceptance criteria remain open.

#### INVEST Check

- [x] Independent: 3 listed dependency link(s) for Preserve Local Performance and Responsiveness.
- [x] Negotiable: implementation detail stays in repository evidence, not hidden in the Operational Story title.
- [x] Valuable: Hydrion stakeholder needs local logging, summaries, and coach fallback to respond quickly so Hydrion feels dependable during repeated daily use.
- [x] Estimable: story size is 5 with evidence and open criteria visible.
- [x] Small: size 5 is within a focused slice.
- [x] Testable: 4 checkbox criterion/criteria and test/build evidence are listed.

#### Definition of Ready

- [x] Metadata is complete: P2, Supporting, MVP Release Readiness, Product Backlog rank 037, size 5.
- [x] Dependencies are named for sequencing; first dependency is `HYD-US-003`.
- [x] Acceptance criteria are checkbox-based and currently 2 checked / 2 unchecked.
- [x] Repository evidence is available for current claims; first evidence item is `lib/repositories/hydration_repository.dart`.
- [x] Ready state reflects Partial: ready to pull or maintain.

#### Definition of Done

- [ ] Implementation status is Implemented for Preserve Local Performance and Responsiveness.
- [ ] All acceptance criteria are checked for this story (2/4).
- [x] Verification evidence includes automated tests or CI/docs.
- [x] Project workflow metadata is valid: Product Backlog, rank 037, size 5.
- [ ] Done means implemented, verified, and no open criteria for Preserve Local Performance and Responsiveness.

### HYD-US-049: Maintain Adapter Boundary and Testability

**Epic:** Maintenance and Quality Requirements  
**Story Type:** Architecture Story  
**Implementation Status:** Implemented  
**Priority:** P0  
**Release Scope:** Supporting
**Labels:** `user-story`, `type:architecture`, `priority:p0`, `status:implemented`, `scope:supporting`, `area:release`, `area:quality`, `area:architecture`, `area:testing`, `size:5`  
**Milestone:** MVP Stabilization
**Story Size:** 5
**Project Column:** Product Backlog  
**Business Rank:** 014

#### User Story

**As a** maintainer
**I need** UI, providers, repositories, and future integrations separated by contracts
**So that** Hydrion can evolve without coupling screens to provider SDKs or mutable state layers.

#### Description

* Adapter boundaries keep UI, local repositories, provider code, and future native integrations testable independently.
* This story protects maintainability as Hydrion grows beyond the local MVP.

#### Details and Business Rules

* UI depends on domain contracts and repositories, not provider SDKs.
* architecture tests forbid UI imports of adapters, provider SDKs, raw AI action types, validators, and executor internals.
* provider adapter shells cannot import mutable app state layers.
* app shell can swap fake domain adapters in widget tests.
* Business rule: UI code must not take direct dependencies on provider SDKs, native adapters, or storage internals.
#### Data and State Requirements

* Provider-facing state must avoid persisted production secrets and must preserve local fallback behavior.
* Integration state must be represented through capability status, adapter contracts, or disabled placeholders until a real adapter is implemented.

#### Assumptions

* No additional product assumption is made beyond the repository evidence and explicit out-of-scope notes.

#### Acceptance Criteria

- [x] UI does not import forbidden adapters, packs, SDKs, or deprecated wrappers.
- [x] Provider shells do not import repositories or storage directly.
- [x] UI works through contracts without provider-specific changes.

#### Acceptance Criteria Coverage

* Checked acceptance criteria: 3.
* Unchecked acceptance criteria: 0.
* Checked criteria are tied to the repository evidence listed in this story.
* Unchecked criteria represent work or verification still needed before the criterion can be claimed complete.

#### Dependencies

* `HYD-US-023`
* `HYD-US-031`
* `HYD-US-034`

#### Non-Functional Requirements

* Keep the behavior offline-tolerant and honest about local-first limits.
* Keep user-visible behavior responsive on the supported web and Android MVP targets.
* Do not expose secrets, provider diagnostics, or disabled integrations in a misleading way.

#### Out of Scope

* Refactoring `HydrionServices` composition into smaller builders, which is tracked as tech debt.

#### Repository Evidence

* `docs/architecture/ADAPTER_BOUNDARY.md`
* `test/boundary_architecture_test.dart`
* `test/adapter_contract_test.dart`
* `lib/domain/hydration_contracts.dart`
* `lib/main.dart`

#### Story Quality Checklist

- [x] maintainer and outcome are specific to Maintain Adapter Boundary and Testability.
- [x] Scope is bounded to Implemented Supporting behavior: Adapter boundaries keep UI, local repositories, provider code, and future native integrations testable independently..
- [x] Primary dependency is `HYD-US-023`; full dependency list is explicit.
- [x] Checked claims cite repository evidence beginning with `docs/architecture/ADAPTER_BOUNDARY.md`.
- [x] Acceptance coverage is 3/3; 0 acceptance criteria remain open.

#### INVEST Check

- [x] Independent: 3 listed dependency link(s) for Maintain Adapter Boundary and Testability.
- [x] Negotiable: implementation detail stays in repository evidence, not hidden in the Architecture Story title.
- [x] Valuable: maintainer needs UI, providers, repositories, and future integrations separated by contracts so Hydrion can evolve without coupling screens to provider SDKs or mutable state layers.
- [x] Estimable: story size is 5 with evidence and open criteria visible.
- [x] Small: size 5 is within a focused slice.
- [x] Testable: 3 checkbox criterion/criteria and test/build evidence are listed.

#### Definition of Ready

- [x] Metadata is complete: P0, Supporting, MVP Stabilization, Product Backlog rank 014, size 5.
- [x] Dependencies are named for sequencing; first dependency is `HYD-US-023`.
- [x] Acceptance criteria are checkbox-based and currently 3 checked / 0 unchecked.
- [x] Repository evidence is available for current claims; first evidence item is `docs/architecture/ADAPTER_BOUNDARY.md`.
- [x] Ready state reflects Implemented: ready to pull or maintain.

#### Definition of Done

- [x] Implementation status is Implemented for Maintain Adapter Boundary and Testability.
- [x] All acceptance criteria are checked for this story (3/3).
- [x] Verification evidence includes automated tests or CI/docs.
- [x] Project workflow metadata is valid: Product Backlog, rank 014, size 5.
- [x] Done means implemented, verified, and no open criteria for Maintain Adapter Boundary and Testability.

### HYD-US-050: Keep CI and Build Quality Gates Stable

**Epic:** Maintenance and Quality Requirements  
**Story Type:** Operational Story  
**Implementation Status:** Implemented  
**Priority:** P0  
**Release Scope:** Supporting
**Labels:** `user-story`, `type:operations`, `priority:p0`, `status:implemented`, `scope:supporting`, `area:release`, `area:quality`, `area:ci-cd`, `size:5`  
**Milestone:** MVP Release Readiness
**Story Size:** 5
**Project Column:** Product Backlog  
**Business Rank:** 004

#### User Story

**As a** maintainer
**I need** CI to validate core Flutter quality and release build artifacts
**So that** MVP changes stay shippable for web and Android.

#### Description

* CI must continue to protect the main Flutter targets, tests, analysis, secret scanning, and release-build sanity checks.
* The story keeps build health visible before more integration work lands.

#### Details and Business Rules

* GitHub workflow runs root validation, `flutter pub get`, secret scan, dependency graph, analyze, tests with coverage, web build, and Android APK build.
* artifacts are uploaded for coverage, web build, and Android APK.
* Business rule: Quality gates must fail loudly for analysis, test, secret, web build, or Android build regressions.
#### Data and State Requirements

* Integration state must be represented through capability status, adapter contracts, or disabled placeholders until a real adapter is implemented.

#### Assumptions

* No additional product assumption is made beyond the repository evidence and explicit out-of-scope notes.

#### Acceptance Criteria

- [x] Quality-gate, web build, and Android build jobs run from repository root.
- [x] Coverage output is uploaded as an artifact.
- [x] Coverage thresholds, localization drift checks, and smoke validation are added.

#### Acceptance Criteria Coverage

* Checked acceptance criteria: 3.
* Unchecked acceptance criteria: 0.
* Checked criteria are tied to the repository evidence listed in this story.
* Unchecked criteria represent work or verification still needed before the criterion can be claimed complete.

#### Dependencies

* `HYD-US-036`
* `HYD-US-037`
* `HYD-US-047`
* `HYD-US-051`

#### Non-Functional Requirements

* Keep the behavior offline-tolerant and honest about local-first limits.
* Keep user-visible behavior responsive on the supported web and Android MVP targets.
* Do not expose secrets, provider diagnostics, or disabled integrations in a misleading way.

#### Out of Scope

* iOS, desktop, cloud, Rust workspace, or model-training CI as active MVP gates.

#### Repository Evidence

* `.github/workflows/flutter-ci.yml`
* `README.md`
* `scripts/build_release.sh`
* `docs/architecture/STALE_SCAFFOLD_AUDIT.md`

#### Story Quality Checklist

- [x] maintainer and outcome are specific to Keep CI and Build Quality Gates Stable.
- [x] Scope is bounded to Implemented Supporting behavior: CI must continue to protect the main Flutter targets, tests, analysis, secret scanning, and release-build sanity....
- [x] Primary dependency is `HYD-US-036`; full dependency list is explicit.
- [x] Checked claims cite repository evidence beginning with `.github/workflows/flutter-ci.yml`.
- [x] Acceptance coverage is 3/3; 0 acceptance criteria remain open.

#### INVEST Check

- [x] Independent: 4 listed dependency link(s) for Keep CI and Build Quality Gates Stable.
- [x] Negotiable: implementation detail stays in repository evidence, not hidden in the Operational Story title.
- [x] Valuable: maintainer needs CI to validate core Flutter quality and release build artifacts so MVP changes stay shippable for web and Android.
- [x] Estimable: story size is 5 with evidence and open criteria visible.
- [x] Small: size 5 is within a focused slice.
- [x] Testable: 3 checkbox criterion/criteria and test/build evidence are listed.

#### Definition of Ready

- [x] Metadata is complete: P0, Supporting, MVP Release Readiness, Product Backlog rank 004, size 5.
- [x] Dependencies are named for sequencing; first dependency is `HYD-US-036`.
- [x] Acceptance criteria are checkbox-based and currently 3 checked / 0 unchecked.
- [x] Repository evidence is available for current claims; first evidence item is `.github/workflows/flutter-ci.yml`.
- [x] Ready state reflects Implemented: ready to pull or maintain.

#### Definition of Done

- [x] Implementation status is Implemented for Keep CI and Build Quality Gates Stable.
- [x] All acceptance criteria are checked for this story (3/3).
- [x] Verification evidence includes automated tests or CI/docs.
- [x] Project workflow metadata is valid: Product Backlog, rank 004, size 5.
- [x] Done means implemented, verified, and no open criteria for Keep CI and Build Quality Gates Stable.

### HYD-US-051: Prevent Secret Leakage and Unsafe Provider Credentials

**Epic:** Maintenance and Quality Requirements  
**Story Type:** Security Story  
**Implementation Status:** Implemented  
**Priority:** P0  
**Release Scope:** Supporting
**Labels:** `user-story`, `type:security`, `priority:p0`, `status:implemented`, `scope:supporting`, `area:release`, `area:quality`, `area:secrets`, `size:3`  
**Milestone:** MVP AI Provider Safety
**Story Size:** 3
**Project Column:** Product Backlog  
**Business Rank:** 002

#### User Story

**As a** security-conscious maintainer
**I need** committed secrets and provider credentials to be detected or avoided
**So that** Hydrion does not leak API keys, private keys, or production provider secrets.

#### Description

* Hydrion must prevent API keys, private keys, and unsafe provider credentials from being committed or shipped in client artifacts.
* This story is critical because optional provider work increases the risk of accidental credential exposure.

#### Details and Business Rules

* `.gitignore` excludes `.env`, `.env.*`, `*.secrets.json`, `secrets/`, and secret reports.
* `tool/secret_scan.dart` scans for common Google/OpenAI/Anthropic API keys and private key blocks.
* tests assert no committed keys/private key blocks and placeholder keys are not treated as real secrets.
* docs prohibit shipping shared production Gemini keys in clients.
* Business rule: Production provider credentials must stay out of repository history and client-distributed artifacts.
#### Data and State Requirements

* Provider-facing state must avoid persisted production secrets and must preserve local fallback behavior.
* Integration state must be represented through capability status, adapter contracts, or disabled placeholders until a real adapter is implemented.

#### Assumptions

* No additional product assumption is made beyond the repository evidence and explicit out-of-scope notes.

#### Acceptance Criteria

- [x] The scan fails and reports the file and secret type.
- [x] Placeholders are not treated as real secrets.
- [x] Shared production keys are kept out of web/mobile/desktop client artifacts.

#### Acceptance Criteria Coverage

* Checked acceptance criteria: 3.
* Unchecked acceptance criteria: 0.
* Checked criteria are tied to the repository evidence listed in this story.
* Unchecked criteria represent work or verification still needed before the criterion can be claimed complete.

#### Dependencies

* `HYD-US-032`
* `HYD-US-033`
* `HYD-US-038`
* `HYD-US-050`

#### Non-Functional Requirements

* Keep the behavior offline-tolerant and honest about local-first limits.
* Keep user-visible behavior responsive on the supported web and Android MVP targets.
* Do not expose secrets, provider diagnostics, or disabled integrations in a misleading way.

#### Out of Scope

* Full enterprise secret management, key rotation automation, or external security audit.

#### Repository Evidence

* `tool/secret_scan.dart`
* `test/secret_hygiene_test.dart`
* `.gitignore`
* `.github/workflows/flutter-ci.yml`
* `docs/architecture/PROVIDER_SECURITY.md`

#### Story Quality Checklist

- [x] security-conscious maintainer and outcome are specific to Prevent Secret Leakage and Unsafe Provider Credentials.
- [x] Scope is bounded to Implemented Supporting behavior: Hydrion must prevent API keys, private keys, and unsafe provider credentials from being committed or shipped....
- [x] Primary dependency is `HYD-US-032`; full dependency list is explicit.
- [x] Checked claims cite repository evidence beginning with `tool/secret_scan.dart`.
- [x] Acceptance coverage is 3/3; 0 acceptance criteria remain open.

#### INVEST Check

- [x] Independent: 4 listed dependency link(s) for Prevent Secret Leakage and Unsafe Provider Credentials.
- [x] Negotiable: implementation detail stays in repository evidence, not hidden in the Security Story title.
- [x] Valuable: security-conscious maintainer needs committed secrets and provider credentials to be detected or avoided so Hydrion does not leak API keys, private keys, or production provider secrets.
- [x] Estimable: story size is 3 with evidence and open criteria visible.
- [x] Small: size 3 is within a focused slice.
- [x] Testable: 3 checkbox criterion/criteria and test/build evidence are listed.

#### Definition of Ready

- [x] Metadata is complete: P0, Supporting, MVP AI Provider Safety, Product Backlog rank 002, size 3.
- [x] Dependencies are named for sequencing; first dependency is `HYD-US-032`.
- [x] Acceptance criteria are checkbox-based and currently 3 checked / 0 unchecked.
- [x] Repository evidence is available for current claims; first evidence item is `tool/secret_scan.dart`.
- [x] Ready state reflects Implemented: ready to pull or maintain.

#### Definition of Done

- [x] Implementation status is Implemented for Prevent Secret Leakage and Unsafe Provider Credentials.
- [x] All acceptance criteria are checked for this story (3/3).
- [x] Verification evidence includes automated tests or CI/docs.
- [x] Project workflow metadata is valid: Product Backlog, rank 002, size 3.
- [x] Done means implemented, verified, and no open criteria for Prevent Secret Leakage and Unsafe Provider Credentials.

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
