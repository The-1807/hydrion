# Hydrion Technical Debt & Architecture Remediation

## 1. Audit Baseline

**Audit date:** 2026-09-26

**Checkout:** `C:\Users\User\StudioProjects\hydrion`

**Branch:** `audit/full-hydrion-integration`

**Audited HEAD:** `ab984bf0b1ea2a5bf4c74c246fd91c997a4aa3f4`

**Integration ancestry:** first parent `9ded4f19486859d7b82abbc804bda1d8066487b5` (recorded `origin/main`); second parent `0b4acb52c9704978716a6326f22df1be8de7d52a` (`origin/validate/apple-discovery-current-main`, includes repair `3fc9eef4456c603d71a3f76c38e1d69aa7d318ee`). Integration adds only `.github/workflows/flutter-ci.yml`, `tool/apple_simulator.py`, and `tool/tests/test_apple_simulator.py` relative to that main. No fetch, merge, branch switch, commit or push was performed during this audit.

**Initial worktree:** staged `edge_case.md`; untracked `HTD.md`. The existing 701-line HTD was the intended architecture/debt draft, not unrelated work. Its useful maps, 37 finding IDs and evidence were retained and corrected in place. Initial SHA-256: `b992edbefa45b4c84ea290eb53fb478024d09568e49c95180845f995e338b985`. Preserved `edge_case.md` SHA-256: `ac65c576d20c7d63175f1053b61a0fc99d06648659f841f9e088f0eda0733538`.

**Evidence baseline, not a green certification:** Flutter 3.44.8 / Dart 3.12.2. Prior synchronized-baseline validation: analyzer passed; 160 focused Flutter tests, 37 Python tests, workflow policy, secrets and EN/FR/ES localization/placeholder audits passed. Full Flutter suite stalled after 445 passes; two format failures and two literal-audit findings remain. These runs were not rerun or repaired by this read-only audit. Remote main run [36249499634](https://github.com/The-1807/hydrion/actions/runs/36249499634) failed its quality gate; all four dependent platform build jobs were skipped. See section 12 for exact distinctions and evidence.

Inspected surfaces include the Flutter composition root and Provider graph; domain models and policies; all repositories and storage adapters; hydration, personalization, weather, health-provider, reminder, challenge, report, widget, watch, AI and reset services; Android manifests/Kotlin bridges; iOS entitlements/Swift extensions; tests and integration tests; workflow/tooling boundaries; current architecture/security/legal documents; dormant Rust, pack and model scaffolds; and the Gate 0 connector architecture. This was a static architecture audit. It does not certify platform runtime behavior, hosted CI, physical devices, or undocumented external systems.

Repository truth classifications used below:

- **Implemented:** reachable runtime code with a composed production path.
- **Partial:** code exists but is deliberately disabled, not connected to downstream behavior, or only partly migrated.
- **Documented target:** an approved direction not yet represented by runtime authority.
- **Transitional/dead:** verified no production caller or no build/runtime integration.
- **Uncertain:** static evidence cannot establish runtime/platform behavior.

## 2. Executive Architecture Diagnosis

Hydrion is a **partially coherent local-first application with several strong bounded subsystems and a fragmented application/domain layer**. The strongest subsystem is wearable-health ingestion: `HealthDataProvider` adapters feed a canonical record model, reconciliation, transactional checkpoints and encrypted SQLCipher persistence. The AI proposal boundary is also intentionally constrained: providers propose typed actions and an application executor performs mutations after validation/confirmation.

The rest of the product grew feature-first around shared repositories. `HydrationRepository` and `UserSettingsRepository` are de facto centers, but they are persistence objects rather than complete domain authorities. Screens, widgets, challenges, AI execution and transitional services call them directly. Daily aggregation, summaries, streaks, date boundaries and target provenance are reconstructed in multiple places. The newest mainline commit improves target safety and starts secure body-metric migration, but it does not complete the architecture recorded in `HYDRION_CONNECTOR_ARCHITECTURE.md`: the weather preview calculator and direct automated commit APIs still exist, and Gate 1 status text is stale.

The evidence therefore supports the hypothesis **"feature silos connected by glue"**, but not uniformly. Health ingestion and notification persistence are comparatively disciplined; target orchestration, calendar semantics, projections and cross-feature invariants are the principal fragmentation zones. Incremental convergence is safer than a rewrite.

## 3. System-Wide Architecture Invariants

1. **One authority per domain fact.** A stored value, pending recommendation and projection must never masquerade as the same fact.
2. **Adapters provide observations; domain/application policy establishes Hydrion truth.** Platform, weather, AI, widget and connector adapters cannot define targets or derived hydration state.
3. **Every hydration intake command crosses one ingestion boundary** for validation, canonical millilitres, event identity, provenance, idempotency and persistence.
4. **`PersonalizedHydrationEngine` is the sole automated target calculator; one application policy is the sole automated committer.** Manual user edits remain a distinct command.
5. **Clinician and safety policy is enforced below UI and feature coordinators.** A screen or preference cannot bypass it.
6. **One calendar/time authority supplies clock, timezone, local-day intervals and date keys.** Calendar days are not fixed 24-hour durations.
7. **Reports, analytics, challenges, widgets, watch and AI consume canonical aggregates and historical target facts.** They do not rebuild truth independently.
8. **Imported health records and manual hydration events remain distinct domains** until an explicit, versioned derivation produces bounded context.
9. **Sensitive storage must fail closed or visibly degraded, never silently downgrade.** Migration state and deletion must be diagnosable.
10. **Derived values carry provenance, algorithm version, source period and freshness.** Projections are replaceable; source records remain authoritative.
11. **Local operation remains authoritative and non-blocking.** Optional cloud/AI/connector failure cannot roll back local truth.
12. **Muse is a minimized, stale-aware, read-only consumer.** Gate 0 is preserved; Gate 1 is partial; Gate 2+ remains paused until foundational remediation is complete.

## 4. Current System / Dependency Map

```text
UI / Android widget / confirmed AI / challenge intake actions
        |                         health platforms
        | direct repository calls       |
        v                               v
HydrationRepository              HealthDataProvider adapters
(JSON in SharedPreferences)             |
        |                        HealthDataSyncCoordinator
        |                               |
        +--> totals/screens       EncryptedHealthDataRepository
        |    challenges/AI              |
        |    widget/watch          HydrationFeatureExtractor
        |                               |
        |                         [production target integration disabled]
        v
UserSettingsRepository <--- UI/weather shell/recommendation coordinator
(active target + baseline + workflow flags + profile in one JSON document)
        ^
        |
PersonalizedHydrationEngine <--- body metrics + daily context + weather
        ^
        +--- DailyHydrationRecommendationCoordinator (intended authority)
        +--- DailyWeatherGoalCoordinator + weather-only preview (parallel residue)

Optional Gemini: canonical HydrationContext -> remote prompt -> typed proposal
                 -> validator -> confirmed executor -> repositories

Future connector: authoritative local state -> minimized signed snapshot
                  -> Hydrion relay -> read-only Muse (documented only)
```

Dependency direction is inconsistent. Domain files import repository models (`lib/domain/hydration_report.dart` -> `lib/repositories/hydration_repository.dart`), `lib/services/hydration_report_pdf.dart` imports UI `intake_ring.dart`, and the root exposes raw mutable repositories through Provider (`lib/main.dart:390-460`). `HydrionServices` is composition root and a wide service locator (`lib/main.dart:534-1128`). A read-only lexical Dart import/export/part graph covered 147 files and 535 resolved local edges: its only multi-file strongly connected component was generated `app_localizations.dart` with EN/FR/ES implementations (BENIGN); no handwritten Dart import cycle was found. This is not a proof about native/channel runtime cycles. Watch is a downstream receiver, not an intake writer.

**Evidence path convention:** abbreviated filenames below resolve under `lib/repositories/` for repositories, `lib/domain/` for models, `lib/services/` for engines/coordinators/services, `lib/ui/screens/` for screens, `lib/adapters/local/local_hydrion_adapters.dart`, `lib/adapters/gemini/gemini_adapter.dart`, and `test/` for tests. Exceptions use full paths. Line references are this exact HEAD; symbol names are the durable locator. `notifications.dart`, `core_bridge.dart`, `eco_tracker.dart`, `watch_connectivity_service.dart` and `android_widget_service.dart` are services. Architecture documentation is `docs/architecture/HYDRION_CONNECTOR_ARCHITECTURE.md`.

## 5. Domain Authority Map

| Domain concept | Canonical owner | Other producers/writers | Consumers | Duplicate/bypass | Status | Evidence |
|---|---|---|---|---|---|---|
| Hydration intake event | `HydrationRepository` record | Home, widget, challenge, AI executor; transitional wearable/core APIs | All hydration features | No command-level ingestion authority | FRAGMENTED | `hydration_repository.dart:211-249`; direct calls listed in HTD-INGEST-001 |
| Normalized intake amount | `HydrationLog.volumeMl` | Each caller supplies `int` | Totals/reports/challenges | Repository accepts zero and has no upper bound | CONFLICTING | `hydration_repository.dart:211-220`; widget applies 50-2000 at `android_widget_service.dart:182-191` |
| Current daily consumed volume | `HydrationRepository.totalForDay` de facto | Report calculator and challenge-specific folds | UI/AI/widgets/watch | Inclusive `fetch` counts differ at boundary | DUPLICATED | `hydration_repository.dart:333-349`; `hydration_report.dart:141-165`; `challenge_repository.dart:1550-1609` |
| Active daily target | `UserSettings.dailyGoalMl` | Manual screens, shell, weather accept API, recommendation coordinator | Nearly all features | Multiple commit APIs | FRAGMENTED | `settings_repository.dart:54,763-792,915-937`; `hydrion_shell.dart:178-188,270-277` |
| Baseline target | `baselineDailyGoalMl` | Manual setters/personalized baseline | Engine/weather | Lifecycle/provenance coupled to flags | FRAGMENTED | `settings_repository.dart:82,763-792`; coordinator `88-102` |
| Automated target calculation | `PersonalizedHydrationEngine` documented target | `DeterministicWeatherGoalService` preview | Shell/setup/tests | Parallel formula remains callable | DUPLICATED | `personalized_hydration_engine.dart:58-205`; `weather_goal_service.dart:514-593` |
| Automated target commit | Intended: `DailyHydrationRecommendationCoordinator.apply` | Shell and `DailyWeatherGoalCoordinator.acceptRecommendation` call settings directly | Settings state | Safety/provenance can be bypassed | CONFLICTING | coordinator `76-86`; shell `178-188,270-277`; weather `873-889` |
| Hydration pacing/state | `HydrationPacingEngine` | Home and notification service assemble inputs | Home advisory; notification waking-window guard | Reminder policy still has separate urgency/time; other projections use percent | FRAGMENTED | `hydration_pacing_engine.dart:12-103`; `home_screen.dart:150-156`; `notifications.dart:514-525` |
| Personalization recommendation | Coordinator + engine + state repository | Body metrics and shell workflows | Body-metrics UI/weather dialog | Two review/dedup ledgers | FRAGMENTED | coordinator `25-73`; connector architecture `149-161` |
| Clinician/safety policy | `HydrionBodyMetrics` + engine | Body-metrics UI | Target computation | Commit API does not itself verify recommendation policy | FRAGMENTED | `body_metrics.dart:117-120`; engine `126-205` |
| Weather contribution | Engine intended | Weather-only calculator and cache/context | Shell/challenges | Duplicate thresholds/formulas | DUPLICATED | weather `514-593`; engine `_weatherAdjustment` |
| Activity contribution | Daily context + engine | Manual daily context; wearable extractor is disabled downstream | Recommendation | Imported health context not wired | FRAGMENTED | `hydration_feature_extractor.dart:3-126`; field `productionTargetIntegrationEnabled=false` |
| Reproductive adjustment | `PersonalizedHydrationEngine` | Secure/body metrics repository | Recommendation UI | Sensitive origin projected in factor enum | CLEAR | engine `111-151,203+`; `body_metrics_repository.dart:290-314` |
| Temporary-condition effect | Daily context + engine | Body-metrics/context UI | Recommendation | Plaintext context, no historical provenance in target | FRAGMENTED | `daily_hydration_context.dart`; engine `119-151` |
| Daily/weekly/monthly summary | No single owner | Local summary adapter, context builder, analytics screen, report calculator | Home/AI/analytics/export | Separate calculations and periods | DUPLICATED | `local_hydrion_adapters.dart:17-44`; `hydration_context_builder.dart:27-72`; `hydration_report.dart:132-174` |
| Report metrics | `HydrationReportCalculator` | Report screen supplies target history | PDF/UI | Only one latest target change is available | CONFLICTING | `hydration_reports_screen.dart:35-53`; `hydration_report.dart:132-174` |
| Streak | None | Home private 365-day helper; AchievementService private 30-day helper | Recognition/achievement | Different caps | CONFLICTING | `home_screen.dart:962-970`; `achievement_service.dart:69-83` |
| Challenge progress | `ChallengeRepository` | Challenge-specific UI/action metadata | Challenge screens/widgets/AI | Custom day and evidence rules | CLEAR | `challenge_repository.dart:1519-1630` |
| Reminder definition/schedule | `ReminderRepository` + `NotificationService` | UI, AI, challenge/Pomodoro | OS/UI/AI context | Timed-session notification path is separate | FRAGMENTED | `notifications.dart:434-920`; `timed_session_notification_service.dart:133-180` |
| Next reminder | No explicit authority | AI context takes repository first element; OS has pending IDs | Coach/UI | Definition and OS delivery can diverge | UNCERTAIN | `hydration_context_builder.dart:55-59`; notification reconciliation `669+` |
| Current local day/timezone | None | Many local helpers and `DateTime.now()` call sites | Nearly every feature | At least seven notions; UTC dashboard | UNOWNED | 103 literal `DateTime.now()` occurrences in 30 files; not 103 different policies; HTD-TIME findings |
| User profile | `UserSettingsRepository` | Onboarding/profile/settings | Most features | Large mixed-sensitivity JSON | FRAGMENTED | `settings_repository.dart:39-129,281-312` |
| Consent/legal state | `UserSettingsRepository` | onboarding/legal screens | weather/AI routing | Non-local AI consent is a single broad flag | FRAGMENTED | `settings_repository.dart:53,73-79,757-760` |
| AI context representation | `HydrationContextBuilder` | repositories | local/Gemini providers | Separate summary reconstruction; broad payload | CLEAR | `hydration_context_builder.dart:27-72`; `gemini_adapter.dart:408-455` |
| Wearable health record | `HealthDataRepository` | HealthKit/Health Connect adapters via sync coordinator | dashboard/extractor | None found in core ingestion | CLEAR | `health_data_sync_coordinator.dart:32-237`; encrypted repository `264-303` |
| Wearable connection state | `HealthConnectionController` plus provider OS state | persisted flags + live permission checks | connection UI | Two-source reconstruction | FRAGMENTED | `health_connection_controller.dart:113-194,322-385,411-466` |
| Widget/watch projection | AndroidWidgetService/WatchConnectivityService | repository listeners | native widgets/watch | Timestamps/schema exist; freshness handling differs by receiver | FRAGMENTED | widget `284-319`; `ios/Runner/WatchConnectivityHost.swift:76-81`; `ios/HydrionWidgets/HydrionWidgets.swift:35-50` |
| Muse connector state | None in runtime | Gate 0 document only | Future relay/Muse | No credentials, relay or projection code | UNOWNED | `HYDRION_CONNECTOR_ARCHITECTURE.md:174-455,623-670` |

## 6. Ingestion Map

The authority table above uses `Other producers/writers` for inputs and mutators, `Consumers` for readers, and `Duplicate/bypass` for alternate authorities. Join each row to the lifecycle table below for storage/caches/deletion. Additional explicit authorities and gaps:

| Concept | Owner / inputs / writers | Readers / storage / derived copies | Duplicates and bypasses | Status / evidence |
|---|---|---|---|---|
| Intake identity | Repository optional action ID; source-specific widget/challenge IDs | All intake readers; hydration JSON | Timestamp+volume fallback, undo checks only record ID | FRAGMENTED; `hydration_repository.dart:222-237,317-329` |
| Score | Private `HydrationScoreCard._score`; Analytics supplies percent/entry count | Analytics only; derived, not persisted | No domain policy for another consumer | UNOWNED at domain level; `lib/ui/components/hydration_score_card.dart:46-74` |
| Baseline calculation | Full engine, manual settings baseline; body metrics/context inputs | Recommendation/current settings | Weather-only result is not a second body baseline but can override active target | FRAGMENTED; engine `58-110`, coordinator `88-102` |
| Sweat/environment adjustment | Engine weather/activity factors, not measured sweat | Recommendations/settings | Weather preview also models environment; no sensor-derived sweat authority | DUPLICATED; engine `_weatherAdjustment`, weather `514-593` |
| Body metrics | BodyMetricsRepository; user input -> sanitization | Engine/body UI; preferences plus secure fields | Fingerprint copy, ambiguous fallback ordering | CONFLICTING; HTD-SEC-003 / DATA-007 |
| Provider synchronization | HealthDataSyncCoordinator + transactional health repository | Connection dashboard/extractor; SQLCipher checkpoint/records, separate preference status | Status persist can fail after record commit; controller exposes metadataUnavailable | CLEAR for commit, FRAGMENTED for status; sync `130-237`, controller `113-194` |
| AI provider health | LocalProviderHealthReporter; config/consent/request outcomes | AI coach routing; in-memory status | Not wearable connection state and must not be conflated | CLEAR; `lib/services/provider_health.dart` |
| Notification eligibility | ReminderPolicy; definition/time/permission inputs | NotificationService; decisions derived, definitions in reminder store | Timed-session visibility is a different mechanism | FRAGMENTED orchestration; `lib/services/notifications.dart`, `lib/services/policy_service.dart` |
| Timezone | Device local settings; no persisted event-zone policy | Reports/reminders/health/day consumers | UTC health instants vs local calendar grouping | UNOWNED; HTD-TIME-001 |
| Wear OS / BLE / Hyders connection | Unavailable facades, not provider OS authorization | Capability messages/tests; no active device transport | Legacy false flags cannot describe real Health Connect/HealthKit | UNCERTAIN future / unavailable now; `wearable_service.dart`, `ble_service.dart` |

All derived source copies above are observations/projections, not an additional authoritative database. The local health DB and local hydration log store own different record types.

| Source | Validation / normalization | Identity / deduplication | Persistence | Domain computation / projection | Bypass or uncertainty |
|---|---|---|---|---|---|
| Manual intake | UI amount selection; repository rejects negative only | Usually no `actionId` | Hydration SharedPreferences JSON | Repository totals, then feature-local summaries | No canonical upper bound or provenance command |
| Android widget intake | Widget range 50-2000 ml | Tap-derived action ID | Direct `HydrationRepository.addLog` | Widget refresh and shared log consumers | Adapter owns stricter validation than repository |
| Challenge intake | Challenge-specific qualification | Challenge action/day IDs and in-flight guards | Direct repository write plus challenge state | Challenge progress and general totals | Two command paths own feature-shaped identity |
| Confirmed AI intake | Proposal validator and user confirmation | No universal intake event ID | Executor writes repository directly | Shared logs and AI context refresh | Skips canonical idempotency/provenance boundary |
| HealthKit / Health Connect | Provider adapters normalize to canonical health records | Provider key, fingerprint, update and deletion reconciliation | Encrypted SQLCipher health repository | Dashboard and versioned feature extractor | Extractor-to-target production integration disabled |
| Legacy wearable/core APIs | Minimal integer input | None | Direct hydration repository write | General totals if called | Wearable has test callers; CoreBridge has `EcoTracker.logHydration` caller, but that method has no product call site |
| Log edit / undo deletion | `LogScreen` -> `updateLog` / `restoreLog`; negative rejected | Edit retains ID; restore checks ID, not canonical action identity | Same hydration JSON | All log consumers refresh | Two additional mutation routes, not new-intake `addLog` sites; `log_screen.dart:40,80` |
| Hyders / smart bottle | Not implemented | Not implemented | Not implemented | Not implemented | Capability unavailable; future adapter would lack a canonical intake command |
| Weather | Provider/cache validation and context DTOs | Cache timestamps and daily workflow flags | Weather cache plus daily context/settings | Full engine in shell; parallel preview remains | Direct target commit APIs remain reachable |
| Profile/body metrics | Repository sanitization; selected Tier-1 fields secured on mobile | Latest-value settings semantics | Mixed SharedPreferences and secure store | Full personalized engine | Failed/unsupported secure write can retain plaintext |
| Activity/temporary context | Date-keyed context repository | One record per date/key | SharedPreferences JSON | Personalized engine | Imported wearable features do not yet feed this boundary |
| External Gemini | Remote response parsed to typed proposals | Proposal/action confirmation state | No provider write; confirmed executor writes local repositories | Context builder and action executor | Context is broader than minimum purpose; client key model is unsafe for distribution |

**Health-specific trace:** `health_kit_provider.dart` / `health_connect_provider.dart` -> platform channel DTO validation -> canonical units and UTC instants with provenance in `lib/domain/health_data.dart` -> provider record identity/fingerprint/tombstones -> `health_data_sync_coordinator.dart` -> one `commitImport` transaction for records and cursor -> dashboard/extractor only. Imported workout/energy/steps/distance are NOT water intake. Provider permission is requested via explicit connection UI, not inferred from a phone brand or the presence of Samsung/FitPro/XOS apps. Android discovery is capability discovery, not an undocumented vendor importer. Retry is bounded; expired cursor rebootstrap exists. Whether every expired-cursor resnapshot reconciles an absent previously imported record is NOT FULLY VERIFIED and requires deletion/rebootstrap fixtures before provider expansion.

**Timestamp/units/provenance trace:** manual and AI intake use caller clock and integer ml; widget uses processing time and optional tap ID; two challenge commands use session/day-qualified metadata and caller time. None converts a source timezone through a shared calendar policy. Undo retains the original event time/ID; edit can replace time. Weather and body/context inputs affect recommendations, not the water log. Stored hydration deserialization is recovery, not a new deduplicated import stream. No live watch/smart-bottle intake or general backup-file importer was found.

### Overlap classification

| Responsibility | Implementations | Classification | Reason |
|---|---|---|---|
| Automated target calculation | Full personalization engine; weather-only recommendation service | DEFECT | Both produce target-shaped recommendations; only the full engine owns all safety factors. |
| Automated target commit | Recommendation coordinator; shell direct write; weather accept direct write | DEFECT | Callers can bypass the intended policy boundary. |
| Daily consumed volume | Repository day total; report aggregation; qualified challenge folds | SUSPICIOUS | General totals disagree at endpoint semantics; qualified challenge subsets may legitimately differ. |
| Summary/report assembly | Local summary, AI context, Analytics UI, report calculator | DEFECT | Consumers reconstruct overlapping domain facts and periods independently. |
| Streak calculation | Home 365-day helper; AchievementService 30-day helper | DEFECT | Both claim the same visible streak fact with different caps. |
| Reminder delivery | Scheduled OS reminders; active timed-session notification | BENIGN | Delivery modes differ, but their lifecycle reconciliation is suspicious and needs one orchestration contract. |
| Event deduplication | Intake action IDs, challenge guards, health fingerprints, notification reconciliation, Pomodoro state, recognition IDs | BENIGN | Source-specific identity is legitimate; hydration intake still needs a common envelope. |
| Unit normalization | ml intake, provider canonical health units, display conversions | BENIGN | Different dimensions legitimately use different conversion contracts; general intake bounds remain fragmented. |
| Recommendation review | Weather daily flags and personalization date/fingerprint map | SUSPICIOUS | Same user decision can have two ledgers; neither is a target-history authority. |
| Retry / error recovery | Provider deadlines/rebootstrap, AI provider failures, plaintext recovery, secure fallback | SUSPICIOUS | Different transports need different retries; silent secure fallback changes domain truth. |
| Consent / sanitization | Legal settings, permission controller, AI action validator, model parsers | BENIGN | Distinct trust boundaries; broad AI context scope and raw fingerprints are separate defects. |
| Goal bounds / rounding | Settings 500-5000 ml, body clinician validation 500-5000, engine 500-5000 and round-to-50, weather round-to-50 | SUSPICIOUS | Identical present constants have separate owners; engine and weather computation duplication is DEFECT (ARCH-001). These are repository rules, not a clinical endorsement. |
| Life stage / reproductive rules | `lib/domain/life_stage_policy.dart`, challenge eligibility, body sanitization, engine | BENIGN when purpose differs | Product access and target eligibility differ legitimately. Pregnancy canonical days conversion stays in body policy; no pregnancy calculation change is proposed by this audit. |
| Local-day calculation | Fixed 24-hour days, calendar-date constructors, challenge activity days, direct UI dates, UTC health dashboard | DEFECT | Cross-feature facts can land on different days. |
| Secure persistence | SQLCipher health DB, mobile secure body fields, plaintext preference stores | SUSPICIOUS | Different classifications can be legitimate, but comparable sensitive data silently receives different protection. |
| Notification reconciliation | Reminder definitions/OS IDs; timed-session signatures; multiple lifecycle hooks | SUSPICIOUS | Separate mechanics are valid, while ordering and final state are implicit. |

### Important data lifecycle and protection map

| Data class | Canonical storage / copies | Protection and lifecycle | Stale, recovery, deletion and backup concerns |
|---|---|---|---|
| Hydration logs | SharedPreferences JSON; derived widget/watch/report projections | Plaintext app preferences; whole-list rewrite | No transaction/journal; reset is sequential; Android backup disabled; other-platform backup behavior varies |
| Active/baseline targets | Mixed settings JSON; copied into widget/watch and report inputs | Plaintext app preferences | No complete history/provenance ledger; projections lack freshness |
| Clinician/restriction state | Body metrics/settings and derived recommendation state | Selected Tier-1 mobile fields migrate to secure storage | Fallback may retain plaintext; target commit does not independently revalidate policy |
| Reproductive/body metrics | Body metrics repository; selected secure-store entries; recommendation factors | Partial Android/iOS secure migration with read-back | Unsupported/failure path retains plaintext; deletion spans multiple stores |
| Daily activity/temporary context | Date-keyed SharedPreferences JSON | Plaintext and retained with profile state | No imported-health source link or versioned target-decision provenance |
| Imported health records | SQLCipher database; key in secure storage; dashboard/extractor projections | Encrypted repository with transactional sync/checkpoints | Provider deletion/update supported; physical backup/recovery and OEM behavior remain unverified |
| Consent/profile | Large settings JSON including provider/AI flags and profile attributes | Plaintext application preferences | Mixed sensitivity and broad AI consent; sequential reset can partially complete |
| Reminders/challenge state | Feature repositories plus OS notification state | Local preferences and platform scheduler state | Reconciliation is required; definitions and OS deliveries can diverge |
| Widget/watch state | Android HomeWidget preferences, iOS app group, WatchConnectivity context | Schema and update timestamp are present; iOS widget checks age/day | No common data-through/timezone contract; Android/watch do not share iOS widget stale-day policy |
| AI provider credential | Dart environment value when configured | Compiled into distributable client | Extractable shared secret; revocation/quota are not per user |
| Reports/PDFs | Generated transient files and share surface | Output protection depends on destination | Can contain historical conclusions based on incomplete target history; retention after sharing is external |
| Future Muse projection | Documentation only | Gate 0 requires minimized signed snapshots | No runtime store, credentials or relay; must remain paused until foundation stages complete |

### Security, lifecycle and failure review

| Boundary | Verified repository behavior | Finding / limitation |
|---|---|---|
| Health SQLCipher/key | `encrypted_health_data_repository.dart:53-59` verifies cipher availability; records/checkpoints transact at `264-303`; key store generates secure random key and refuses replacement when existing DB key is missing | Strong fail-closed boundary. `purgeBefore` exists; no production retention scheduler call found. Logical deletion is not certified forensic erasure/backup deletion. Physical behavior NOT FULLY VERIFIED. |
| Plaintext recovery | `lib/repositories/storage_recovery.dart` records recovery status and parsers sanitize malformed values; JSON stores can recover to defaults | Defaults are not the same as recovered truth; secure-body null outcome is especially unsafe (DATA-007). Never log discarded source values. |
| Context/recommendation caches | Daily context is date keyed; recommendation JSON persists latest result and reviewed fingerprint history | Sensitive copies and growth are SEC-003; recommendation factor enums also reveal sensitive category membership. |
| Weather | `weather_goal_service.dart:212-280` date/age cache validation and typed stale fallback; Open-Meteo HTTPS at `305`; coarse location permission | Stale forecast is represented, not silently certified current. Consumers must honor eligibility before target mutation; coordinates are external disclosure under location consent, not health-provider records. |
| AI | `ai_provider_config.dart`, Gemini adapter HTTPS default, typed actions, explicit confirmation and non-local consent | No raw HealthKit/Connect record or full body model found in Gemini prompt. Context includes more than a simple daily query needs (PRIV-001). Compile-time app key is SEC-002. No certificate-bypass override found in reviewed network paths; no live TLS penetration test. |
| Android exposure | Main manifest exported launcher/health rationale; health usage alias protected by START_VIEW_PERMISSION_USAGE; notification receivers non-exported; widget receivers exported for platform delivery; backup/cleartext disabled | Exported alone is not evidence of a vulnerability. Widget URI allow-list (`android_widget_service.dart:240-277`) validates host, keys, amount and ID; native caller authenticity/replay still needs adversarial platform tests. |
| iOS native boundaries | Runner HealthKit/app-group/keychain entitlements; widget app group; watch schema/value validation and one-way context | HealthKit reads do not mean unrestricted sensor streaming. Widget/watch show narrow totals, not raw clinical records. Physical entitlement/keychain/backup certification not performed. |
| Platform channels | Typed health canonical parsers, bounded provider deadlines, safe diagnostic codes; watch validates schema/ranges | Inspecting handlers is not a fuzz/security certification. Keep external payloads out of generic debug messages. Widget sync currently prints caught error/stack; this is a potential diagnostic disclosure surface, not evidence of captured health values (OBS-001). |
| Reset | Wearable deletion must succeed first; later store failures return partial result; secure body delete hides errors | Retain honest partial-state behavior; DATA-005/008 require explicit pending deletion and restart handling. |
| Profile photo / files | `profile_photo_service.dart` picks/downsizes photo; settings bounds/sanitizes base64 and stores it in profile JSON; PDFs generated/shared by report services | Photo is sensitive plaintext, not a secret-store field. Shared report destinations can retain copies beyond app reset. Bundled art/model/config assets are not user health records. No claim that source asset size equals runtime footprint. |
| macOS/Windows/Linux/Web | Health persistence stub/unsupported outcome; secure body store supported only Android/iOS; desktop/web profile preferences remain plaintext | Intentional unsupported health capability must be explicit. macOS release entitlement is sandbox-only, without network-client entitlement: external-network runtime remains unverified. Web startup has concrete missing platform guard (PLATFORM-003). |
| Resource lifetime | Whole hydration JSON rewrites; repeated total scans; health sync pages accumulated before transactional commit; services dispose closes DB only | PERF-001/002 and ORCH-004; no RAM/battery/latency measurements or fabricated thresholds. Provider max-page bound is good; retained reviewed fingerprints have no analogous count bound. |

Security classification is explicit: SEC-002 is a conditional SECURITY BUG; SEC-003 and DATA-008 are PRIVACY BUGS; silent fallback in SEC-001/DATA-007 is security/data-integrity debt; backup scope, diagnostic minimization and native exposure testing are HARDENING. Connector credentials, relay authorization, revocation and retention are FUTURE CONNECTOR REQUIREMENTS, not runtime implementations or newly authorized work.

## 7. Feature Integration Matrix

Only meaningful interactions are listed. Omission is not proof a relationship is forbidden: new relationships require an explicit domain contract, not a direct cross-feature mutation.

| Feature A | Feature B | Classification | Repository evidence |
|---|---|---|---|
| Manual logging | Analytics | INTEGRATED THROUGH SHARED DOMAIN | Both use `HydrationRepository`, but analytics owns period assembly. |
| Manual logging | Reports | INTEGRATED THROUGH SHARED DOMAIN | Reports consume stored logs; historical targets are incomplete. |
| Manual logging | Challenges/streaks | AD-HOC CONNECTION | Challenge repository scans logs and metadata; streak helpers diverge. |
| Manual logging | Widgets/watch | INTEGRATED THROUGH SHARED DOMAIN | Projections read canonical logs/target; freshness is implicit. |
| Manual logging | AI coach | INTEGRATED THROUGH SHARED DOMAIN | Context builder reads repository totals; AI-confirmed intake writes directly back. |
| HealthKit | Health Connect | INTEGRATED THROUGH SHARED DOMAIN | Same provider contract, canonical model, repository and sync coordinator. |
| HealthKit/Health Connect | Activity/context | MISSING INTEGRATION | Extractor exists but `productionTargetIntegrationEnabled` is false. |
| HealthKit/Health Connect | Manual intake | SHOULD NOT INTERACT | Imported metrics are activity observations, not hydration intake. |
| Wearables facade | Manual intake | DUPLICATED RESPONSIBILITY | Unsupported `WearableService.syncHydration` can write a local log without provenance. |
| Hyders/smart bottle | Intake | MISSING INTEGRATION | BLE service is unavailable; no device identity/replay pipeline exists. |
| Weather | Personalization | AD-HOC CONNECTION | Shell uses canonical engine, but weather preview calculator/gate remains parallel. |
| Weather | Clinician/safety | AD-HOC CONNECTION | Main shell checks `mayAutoApply`; lower commit API can still be called directly. |
| Body metrics | Personalization | INTEGRATED THROUGH SHARED DOMAIN | Coordinator sanitizes and passes metrics to the engine; fingerprint persistence leaks the inputs (HTD-SEC-003). |
| Body metrics | Secure storage | AD-HOC CONNECTION | Android/iOS Tier-1 migration exists; unsupported/failure fallback stays plaintext. |
| Clinician/safety | Active target | AD-HOC CONNECTION | Engine is safe; repository commit methods do not revalidate the policy. |
| Activity/context | Personalization | INTEGRATED THROUGH SHARED DOMAIN | Date-keyed repository feeds engine for manually recorded context. |
| Wearable activity | Personalization | MISSING INTEGRATION | Versioned extractor output is not applied to production targets. |
| Reminders | Notifications | CORRECT DIRECT INTEGRATION | Definitions and scheduled IDs reconcile through `NotificationService`. |
| Challenges | Notifications | AD-HOC CONNECTION | Challenge screens and Pomodoro invoke reminder/timed-session services separately. |
| Pomodoro/homework | Notifications | DUPLICATED RESPONSIBILITY | Future reminder scheduler and active timed-session notifier have separate state/reconciliation. |
| Analytics | Reports | DUPLICATED RESPONSIBILITY | Both build period metrics independently and use different target history inputs. |
| Challenges | Streaks | DUPLICATED RESPONSIBILITY | Challenge progress is repository-owned; global streak is two private helpers. |
| Widgets | Challenges | INTEGRATED THROUGH SHARED DOMAIN | Widget projection reads challenge repository and opens app routes. |
| Widgets/watch | Time/day | AD-HOC CONNECTION | Capture clocks differ; iOS widget has age/day checks, Android/watch do not use an equivalent contract. |
| AI coach | Consent | AD-HOC CONNECTION | Non-local provider is gated, but one broad flag covers the full context. |
| Gemini | Hydration mutation | CORRECT DIRECT INTEGRATION | Typed proposal -> validator -> confirmed executor; provider itself does not write. |
| AI coach | Reports/analytics | DUPLICATED RESPONSIBILITY | AI receives a separately reconstructed daily summary, not a canonical report projection. |
| Profile/settings | Target | AD-HOC CONNECTION | Manual authority is valid, but profile/settings/onboarding call repository mutation directly. |
| Legal/consent | Health providers | CORRECT DIRECT INTEGRATION | Explicit connection/controller state and user-initiated permission flow. |
| Import/export | Reports | CORRECT DIRECT INTEGRATION | Structured report feeds PDF/share; no general hydration-file importer found; log undo is separate. |
| Muse | Hydration state | MISSING INTEGRATION | Gate 0 locks read-only minimized snapshots; no runtime exists and work is paused. |
| Muse | AI coach | SHOULD NOT INTERACT | Connector polling must not invoke conversational AI. |
| Muse | Clinician/reproductive data | SHOULD NOT INTERACT | Gate 0 requires an allow-listed projection; raw factors are prohibited. |
| Muse | Widgets/watch | SHOULD NOT INTERACT | They are separate downstream projections, not authorities for each other. |

## 8. Root Causes

Six causes explain the findings; the matching group under section 9 assigns each finding its root cause.

| Root | Architectural cause | Main consequences |
|---|---|---|
| A | Target policy has a documented owner but callers retain authority | Parallel calculator, unguarded commits, flag state, missing history, silo tests |
| B | Shared persistence is mistaken for an intake command boundary | Source-specific validation/identity, alternate writes, asynchronous rollback collisions |
| C | Consumers reconstruct aggregate and calendar truth | Conflicting intervals/streaks/history, UI score and eco estimates, unbounded derivation assumptions |
| D | Protection and deletion follow features, not the full data lineage | Plaintext copies, stale secure authority, false-success deletion, credential and backup risks |
| E | Cross-feature work depends on listeners and mutable repositories | Dropped publications, ambiguous lifecycle ownership, diagnostics and scaling gaps |
| F | Capability, tests and documentation do not uniformly reflect composed runtime | Unsupported-platform startup, misleading legacy flags, incomplete health-to-target integration |

Root C has the widest current consumer blast radius. Roots A/B create the greatest future adapter collision risk. Root D requires the earliest data-loss/privacy correction. None implies a rewrite of the strong canonical health ingestion pipeline.

## 9. Detailed Findings

### Root cause A: automated target ownership is documented but not fully enforced

#### HTD-ARCH-001 - Parallel automated target calculators remain
- **Severity / confidence:** HIGH / HIGH
- **Affected:** `PersonalizedHydrationEngine.calculate`, `DeterministicWeatherGoalService.recommend`, weather setup/evaluate tests.
- **Observed/evidence:** The full engine applies body, reproductive, activity, weather, user and clinician/safety policy (`personalized_hydration_engine.dart:58-205`). The weather service independently applies temperature/humidity/UV thresholds (`weather_goal_service.dart:514-593`) and remains composed at `673-691`.
- **Problem / why it works today:** Main shell now uses the full engine before commit, so the dangerous auto-apply defect is reduced. The second result is called a "preview", but remains a callable target-shaped value and tests assert it. Formula drift or a future caller can restore competing authority.
- **Violated invariant / impact:** One automated target calculator; inconsistent recommendations and safety context.
- **Dependencies / direction:** Preserve weather acquisition/eligibility; replace target preview with eligibility/context DTO and migrate callers. **Do not** create a third calculator or merely synchronize constants. Validate all target factors and weather setup UX against one engine.

#### HTD-ORCH-001 - Automated target commit policy has bypasses
- **Severity / confidence:** HIGH / HIGH
- **Affected:** shell weather flow, `DailyWeatherGoalCoordinator.acceptRecommendation`, `DailyHydrationRecommendationCoordinator.apply`, settings repository.
- **Observed/evidence:** The documented canonical commit is coordinator `apply()` (`daily_hydration_recommendation_coordinator.dart:76-86`), but the shell calls `UserSettingsRepository.applyWeatherGoal` directly (`hydrion_shell.dart:178-188,270-277`), and the weather coordinator retains a direct accepting writer (`weather_goal_service.dart:873-889`).
- **Important qualification:** `apply()` itself is only a settings forwarder: it does not recheck `mayAutoApply`, recommendation age or current clinician state. Merely routing callers to it is insufficient; it must become a decision-mode-aware policy boundary. Manual confirmation and automatic eligibility are different policies.
- **Problem / why it works today:** The shell explicitly checks `mayAutoApply`, and current manual dialog confirms. Safety depends on those callers behaving correctly; the repository write accepts any bounded integer without recommendation identity or safety state.
- **Violated invariant / impact:** One automated commit policy; future call sites can bypass clinician/consent/provenance rules.
- **Dependencies / direction:** After HTD-ARCH-001, make one application command accept a recommendation plus decision mode and enforce policy. Keep manual writes separate. **Do not** put feature-specific policy into `UserSettingsRepository`.

#### HTD-ORCH-002 - UI shell is a domain orchestrator and lifecycle safety pin
- **Severity / confidence:** HIGH / HIGH
- **Affected:** `HydrionShell._evaluateWeatherAssistance`, lifecycle/day rollover.
- **Observed/evidence:** The widget performs provider gating, cache selection, recommendation calculation, auto-apply policy, dialog policy and persistence (`hydrion_shell.dart:51-117,121-282`).
- **Problem / why it works today:** One screen happens to execute operations in the intended order. Background work, tests or another UI can omit a step, and unmounting controls domain progress.
- **Violated invariant / impact:** Domain safety below UI; inconsistent target state and duplicated lifecycle calls.
- **Dependencies / direction:** Move the use case into the existing recommendation orchestration boundary; UI should render a typed decision and send a command. **Do not** add another screen-specific coordinator.

#### HTD-STATE-001 - Goal state requires boolean archaeology
- **Severity / confidence:** MEDIUM / HIGH
- **Affected:** `UserSettings.goalMode`, baseline source, weather flags and timestamps.
- **Observed/evidence:** `setGoalMode` always stores `HydrionGoalMode.manual` and encodes weather mode in `weatherModifierEnabled` (`settings_repository.dart:849-866`). Active provenance is inferred from `baselineSource`, `weatherAdjustedGoalActive`, auto-apply/daily-confirmation flags and dates.
- **Problem / why it works today:** Current screens read the same flag combinations. The enum name no longer represents persisted semantics and report/connector callers can misinterpret it.
- **Direction:** Define one explicit target state/provenance value object and migrate JSON. **Do not** add another compensating boolean.

#### HTD-DATA-001 - No authoritative target history or provenance ledger
- **Severity / confidence:** HIGH / HIGH
- **Affected:** settings, recommendation state, reports, future connector.
- **Observed/evidence:** Settings retain only current/baseline target and latest manual/weather dates (`settings_repository.dart:54,80-87`). Report screen synthesizes at most one target change (`hydration_reports_screen.dart:35-53`).
- **Problem / why it works today:** Current-day displays need only one number. Historical target-met percentages, clinician provenance and connector snapshots cannot be reconstructed reliably.
- **Direction:** Add an append-only, versioned target decision history after commit authority is unified; migrate current state conservatively. **Do not** infer history from flags.

#### HTD-TEST-001 - Target tests certify silos, not the system invariant
- **Severity / confidence:** MEDIUM / HIGH
- **Affected:** `weather_location_goal_test.dart`, personalized engine/coordinator tests.
- **Observed/evidence:** Weather tests still call `acceptRecommendation` and assert the preview value; engine tests prove safety separately. There is no single test asserting every automated production write crosses the canonical committer.
- **Problem / why it works today:** Each component passes independently while a bypass remains.
- **Direction:** Add architecture/call-graph guard and end-to-end clinician/weather/manual-decline tests after convergence. Do not delete safety unit tests.

### Root cause B: repository convergence is mistaken for canonical ingestion

#### HTD-INGEST-001 - Hydration intake has seven direct source write sites
- **Severity / confidence:** HIGH / HIGH
- **Affected:** `home_screen.dart:62`, `android_widget_service.dart:186`, `challenge_repository.dart:1073,1141`, `hydration_ai_action_executor.dart:67`, `wearable_service.dart:21`, `core_bridge.dart:14`.
- **Observed/evidence:** Six components call `HydrationRepository.addLog`; challenge has two command methods. Active flows converge only at persistence.
- **Reachability:** five product call sites plus two transitional sites, not seven independently reachable product features. Log editing and undo add two separate mutation routes through `updateLog`/`restoreLog`.
- **Problem / why it works today:** Millilitres are already used, and some callers generate action IDs. Validation, provenance and idempotency vary by source; transitional APIs can create indistinguishable "local" events.
- **Direction:** Introduce one application-level intake command handler using the existing repository as persistence; migrate callers source by source. **Do not** make each adapter replicate validation.

#### HTD-INGEST-002 - Event identity and provenance are optional and feature-shaped
- **Severity / confidence:** MEDIUM / HIGH
- **Affected:** `HydrationLog.actionId/source/metadata`, widget, challenge and AI inputs.
- **Observed/evidence:** Repository deduplicates only non-empty `actionId` (`hydration_repository.dart:222-228`). Widget IDs depend on a tap query parameter; challenge IDs embed local-day/action strings; AI supplies no action ID; wearable uses source `local`.
- **Problem / why it works today:** UI tap suppression and challenge state reduce common duplicates. Replay/offline/device imports have no universal identity contract.
- **Direction:** Define source event ID, source kind, observed/recorded time and provenance schema at ingestion. Keep provider-specific metadata behind typed fields.

#### HTD-DATA-002 - Intake validation is inconsistent and repository bounds are incomplete
- **Severity / confidence:** MEDIUM / HIGH
- **Affected:** `HydrationRepository.addLog`, widget/AI/challenge callers.
- **Observed/evidence:** Repository rejects only values `< 0`, so zero and unbounded positive values are accepted (`hydration_repository.dart:211-220`). Widget independently enforces 50-2000 (`android_widget_service.dart:182-191`).
- **Problem / why it works today:** Normal UI pickers and validators send reasonable values. Any new adapter or public method can persist invalid domain data.
- **Direction:** Put canonical physical/business bounds and zero policy at ingestion; UI may add narrower UX bounds.

#### HTD-DATA-003 - Inclusive `fetch` and exclusive day totals disagree at midnight
- **Severity / confidence:** MEDIUM / HIGH
- **Affected:** hydration repository, home/local summary/context builder.
- **Observed/evidence:** `fetch(start,end)` includes `end` (`hydration_repository.dart:333-336`), while `totalForDay` excludes it (`343-349`). Several "today logs" calls pass next midnight as `end` (`local_hydrion_adapters.dart:31-34`, `hydration_context_builder.dart:32-34`, `home_screen.dart:133-136`).
- **Problem / why it works today:** Exact-midnight events are rare; totals and entry counts can still disagree.
- **Direction:** Adopt half-open intervals throughout and test DST/midnight boundaries. Do not patch each consumer separately.

#### HTD-DEAD-001 - Unsupported wearable and "core bridge" APIs can still write intake
- **Severity / confidence:** LOW / HIGH
- **Affected:** `WearableService.syncHydration`, `CoreBridge.logEcoEvent`.
- **Observed/evidence:** Both public methods call `addLog`. `CoreBridge.logEcoEvent` has a caller at `lib/services/eco_tracker.dart:18-19`, but `EcoTracker.logHydration` has no product caller; `WearableService.syncHydration` is exercised by `test/persistence_test.dart`, not an enabled adapter. Wearable capability flags are false (`wearable_service.dart:12-25`); `CoreBridge` is pure Dart, not Rust FFI. EcoTracker's read-only estimate IS used by Analytics and is not dead.
- **Problem / why it works today:** They are uncalled. Names invite future developers to use bypasses or believe inactive architecture is live.
- **Direction:** After call-site/roadmap confirmation, deprecate then remove or rename. Do not activate them to "use existing code."

#### HTD-DATA-010 - Whole-list rollback can undo another successful mutation
- **Severity / confidence:** HIGH / HIGH
- **Affected / evidence:** `lib/repositories/hydration_repository.dart:259-329`, `updateLog`, `deleteLog`, `restoreLog`; callers are `lib/ui/screens/log_screen.dart:40,80` and the intake sites above.
- **Observed:** edit/delete copy the entire list, mutate it, await persistence, then restore the old list on failure. There is no repository-wide mutation queue. A second operation may finish during that await; the first failure then discards its in-memory result. Add/restore rollback removes by ID; timestamp-plus-volume IDs can also collide without an action ID.
- **Why wrong / why it appears to work:** isolated rollback tests and ordinary sequential taps pass; different async sources can interleave. One successful source event must not be erased by another command's rollback.
- **Impact / invariant:** data-loss/state-divergence risk; committed events have serializable ownership. This is a source-level interleaving proof, not a claim of observed user data loss.
- **Dependencies / direction:** canonical intake identity and serialized transactional mutation (stage 3); preserve old storage until migration is verified. **Do not** add per-screen locks or swallow write errors. Validate delayed failing writes interleaved with successful add/edit/delete/undo and restart; extend `test/storage_recovery_test.dart` and `test/persistence_test.dart`.

### Root cause C: aggregate and calendar truth is reconstructed by consumers

#### HTD-TIME-001 - No canonical clock, timezone or local-day policy
- **Severity / confidence:** HIGH / HIGH
- **Affected:** 103 literal `DateTime.now()` occurrences across 30 Dart files, lifecycle, reports, challenges, widgets and notifications; this lexical count is not a semantic policy count.
- **Observed/evidence:** Some services inject clocks, most screens/repositories do not; wearable dashboard starts from UTC while hydration UI uses local components.
- **Problem / why it works today:** Tests pass explicit times for selected services. DST, travel/timezone change and midnight races can produce cross-feature disagreement.
- **Direction:** Establish a small calendar/clock policy and migrate domain/application code first. Do not wrap every call mechanically without defining semantics.

#### HTD-TIME-002 - Fixed 24-hour "day" intervals are DST-unsafe
- **Severity / confidence:** MEDIUM / HIGH
- **Affected:** `HydrationRepository.totalForDay`, `HydrationFeatureExtractor`, AchievementService.
- **Observed/evidence:** Local midnight plus `Duration(days:1)` is used at `hydration_repository.dart:343-345` and `hydration_feature_extractor.dart:33-35`; report code correctly constructs the next calendar date (`hydration_report.dart:40-46`).
- **Problem / why it works today:** Most days are 24 hours. DST transition days are not.
- **Direction:** Centralize half-open calendar-day intervals in the user timezone and migrate both hydration and health derivation.

#### HTD-TIME-003 - Challenge day semantics are a second calendar system
- **Severity / confidence:** MEDIUM / HIGH
- **Affected:** `_localDayToken`, `_activityDayToken`, direct year/month/day comparisons, challenge history presenter.
- **Observed/evidence:** ChallengeRepository has special overnight activity mapping and several direct date comparisons (`challenge_repository.dart:953-967,1550-1562,1601-1609`).
- **Problem / why it works today:** Challenge-local rules are internally tested, but global totals, streaks and widget day rollovers do not share the same day object.
- **Direction:** Keep legitimate challenge windows as explicit policies layered on canonical calendar days.

#### HTD-ARCH-002 - Four summary/report builders reconstruct overlapping facts
- **Severity / confidence:** MEDIUM / HIGH
- **Affected:** `LocalHydrationSummaryService`, `HydrationContextBuilder`, `AnalyticsScreen`, `HydrationReportCalculator`.
- **Observed/evidence:** Each assembles totals/entries/targets/periods independently. Analytics computes seven days in UI (`analytics_screen.dart:33-47`); report calculator re-aggregates raw logs (`hydration_report.dart:141-165`).
- **Problem / why it works today:** All read the same log list and current target, so common cases align. Boundary and historical-target semantics differ.
- **Direction:** Define canonical daily facts and period aggregation as domain queries; projections format them.

#### HTD-ARCH-003 - Streak has two conflicting private implementations
- **Severity / confidence:** MEDIUM / HIGH
- **Affected:** Home recognition and AchievementService.
- **Observed/evidence:** Home scans up to 365 days (`home_screen.dart:962-970`); AchievementService scans 30 (`achievement_service.dart:69-83`), both applying the current target historically.
- **Problem / why it works today:** Both only need a seven-day threshold today. They disagree for longer streaks and after target changes.
- **Direction:** One streak policy over historical daily facts/targets, with a public tested contract.

#### HTD-DATA-004 - Historical reports can present the current target as past truth
- **Severity / confidence:** HIGH / HIGH
- **Affected:** report screen/calculator/PDF and future connector summaries.
- **Observed/evidence:** Report calculator supports target changes, but the screen supplies zero or one change using the current `dailyGoalMl` (`hydration_reports_screen.dart:35-53`).
- **Problem / why it works today:** Volumes are correct and simple users rarely change targets. Target-met days/percent can be materially false.
- **Direction:** Depends on HTD-DATA-001; report unknown target explicitly rather than backfilling current state.

#### HTD-ARCH-004 - Shared pacing exists, but advisory state is assembled differently
- **Severity / confidence:** MEDIUM / HIGH
- **Affected:** `HydrationPacingEngine`, Home, reminders/AI/widgets.
- **Observed/evidence:** Home invokes the engine at `home_screen.dart:150-156`; `notifications.dart:514-525` ALSO uses it to suppress suggested reminders outside the waking window. `policy_service.dart:64-116` separately computes urgency and trigger time using `DateTime.now()`, while notifications accept an injected `now`. Widgets/AI use percent/shortfall instead of a named shared advisory projection.
- **Problem / why it works today:** The waking-window guard is a real shared-policy improvement. However the reminder policy clock and the supplied evaluation clock can disagree; no common advisory projection captures when and why the state was derived. Different UI purposes need not display identical text, but must not silently reinterpret source facts.
- **Direction:** Expose pacing as a read-only domain query; consumers choose whether to display it.

#### HTD-ARCH-008 - User-facing hydration score is a UI-owned policy
- **Severity / confidence:** MEDIUM / HIGH
- **Affected / evidence:** `lib/ui/components/hydration_score_card.dart:46-74`, used by `lib/ui/screens/analytics_screen.dart:95`. `_score` combines 80% capped target progress and 20% capped entry frequency (four entries); thresholds select advice.
- **Observed / why wrong:** the app DOES have a displayed score, but no domain score authority/version/provenance. A new AI/report consumer would have to copy a private widget formula. Entry splitting changes score without changing consumed volume.
- **Why it appears to work / impact:** Analytics can render it from two scalars; that is a heuristic, not a validated hydration measurement. Do not export it as canonical health truth.
- **Invariant / dependencies / direction:** derived policy has a named owner and explanation; depends on stage 5 daily facts. Owner must approve meaning and bounds before extracting a shared read model. **Do not** invent a medical score or merely move constants. Validate equal-volume/different-entry histories, zero/over-goal, and consistent labels; inspect existing analytics/widget coverage, which does not certify scientific validity.

#### HTD-DATA-009 - Current reusable-container preference rewrites the historical eco estimate
- **Severity / confidence:** MEDIUM / HIGH
- **Affected / evidence:** `lib/services/eco_tracker.dart:22-28`, `getTotalPlasticSavedKg`; Analytics reads it (`lib/ui/screens/analytics_screen.dart:33,150`).
- **Observed:** with reusable containers enabled, all lifetime hydration is divided by 500 ml and multiplied by 0.01 kg; disabling it returns zero. Recorded event metadata is not consulted.
- **Why wrong / why it appears to work:** simple all-reusable histories fit the assumption; mixed histories or a later preference change do not. Present-day preference is not historical evidence.
- **Invariant / impact:** derived historical claims retain source attribution; displayed environmental savings can change retroactively without any intake change.
- **Dependencies / direction:** stage 3 provenance, stage 5 aggregation; distinguish an explicitly hypothetical estimate from attributable savings. **Do not** manufacture past container evidence during migration. Validate mixed metadata, toggle changes and unknown legacy history; extend `test/persistence_test.dart` eco coverage.

#### HTD-DATA-011 - Cross-day health intervals can contribute their whole value to each day
- **Severity / confidence:** MEDIUM / HIGH
- **Affected / evidence:** `lib/services/hydration_feature_extractor.dart:33-116`, `extract`; `test/hydration_feature_extractor_test.dart`.
- **Observed:** overlapping records are selected by interval. Workout durations are clipped to the day, but energy, steps and distance sum full `record.value`. A record spanning midnight is eligible on both days and contributes its full amount twice if both days are queried.
- **Why wrong / why it appears to work:** within-day fixtures fit; cross-day quantity allocation has no explicit policy. Source records remain correct, and production target integration is disabled, limiting present impact.
- **Invariant / impact:** period aggregation must conserve quantities or explicitly mark them unallocatable; future wearable-derived context can be inflated.
- **Dependencies / direction:** canonical calendar and provider temporal precision before stage 8 activation. **Do not** assume uniform proration is medically or provider-correct. Define permitted bucket/query semantics and test midnight, multi-day and point records, with no double counting.

### Root cause D: data protection and lifecycle policies are split by feature

#### HTD-SEC-001 - Sensitive storage protection is partial and platform-dependent
- **Severity / confidence:** HIGH / HIGH
- **Type:** privacy/security architecture bug with an in-progress hardening migration.
- **Affected:** hydration logs, user settings/profile photo/age/sex/consent, daily context, body metrics, wearable DB.
- **Observed/evidence:** Imported health records use SQLCipher plus a secure key (`health_data_persistence_io.dart:18-49`; `health_database_key_store.dart:37-107`). Latest main securely migrates selected body metrics on Android/iOS, but explicitly retains plaintext on unsupported platforms or failed secure writes (`body_metrics_repository.dart:170-219`). Hydration logs and mixed user settings remain SharedPreferences JSON.
- **Problem / why it works today:** Android backup is disabled and the app is local-first. Data with comparable sensitivity receives inconsistent protection; a silent secure-store failure intentionally downgrades to plaintext without a user-visible state.
- **Direction:** Finish the classified storage design, record degradation state, and migrate atomically. Preserve the current no-data-loss read-back approach. **Do not** delete plaintext until secure verification and recovery are proven.

#### HTD-SEC-002 - Production Gemini key model embeds a shared secret in client builds
- **Severity / confidence:** HIGH / HIGH
- **Type:** security bug when Gemini is shipped with an app-owned key; acceptable only for bounded local development.
- **Affected:** `HydrionAiRuntimeConfig.fromEnvironment`, Gemini HTTP client.
- **Observed/evidence:** `HYDRION_GEMINI_API_KEY` is compiled from a Dart environment value (`ai_provider_config.dart:124-140`) and sent as `x-goog-api-key` (`gemini_adapter.dart:147-165`). Mobile/web clients cannot keep this secret.
- **Problem / why it works today:** Provider is optional and unconfigured by default; secret scans prevent committing a key. A configured distributable exposes quota/billing credentials.
- **Direction:** Owner must choose BYOK with secure entry or a minimal authenticated proxy. Do not treat compile-time defines as secret storage.

#### HTD-PRIV-001 - Non-local AI context exceeds minimum daily coaching facts
- **Severity / confidence:** MEDIUM / HIGH
- **Affected:** `HydrationContextBuilder`, Gemini prompt.
- **Observed/evidence:** Prompt includes daily totals/target/date, lifetime ml, event count, reminder count/next time and active challenge details (`gemini_adapter.dart:408-455`). It omits raw body/clinician records, which is good.
- **Problem / why it works today:** One broad consent flag gates the provider. A user asking a simple question cannot scope which unrelated categories leave the device.
- **Direction:** Define per-purpose minimized projections and a context preview/scope consent. Never send raw health-provider records.

#### HTD-PRIV-002 - Backup behavior differs by platform and store
- **Severity / confidence:** MEDIUM / MEDIUM
- **Affected:** Android manifest, iOS preferences/app group, secure stores.
- **Observed/evidence:** Android declares `allowBackup=false` and cleartext disabled (`AndroidManifest.xml:14-21`). No equivalent repository evidence excludes all iOS SharedPreferences/app-group data from backup; legal copy acknowledges device backup/transfer.
- **Problem / why it works today:** Platform protection may encrypt backups, but retention/export expectations differ silently.
- **Direction:** Document and test per-store backup classes; exclude sensitive caches where supported. Physical backup behavior remains unverified.

#### HTD-DATA-005 - Local profile reset is sequential, non-transactional deletion
- **Severity / confidence:** MEDIUM / HIGH
- **Affected:** `LocalProfileResetService`, all local repositories, notifications, secure health/body stores.
- **Observed/evidence:** Reset deletes wearable data first, then cancels/deletes each subsystem sequentially and converts exceptions to status (`local_profile_reset_service.dart:101-182`). A later failure leaves earlier stores deleted.
- **Problem / why it works today:** Operations normally succeed and the result reports failure. "Failed reset" can mean a partially erased profile with no resumable journal.
- **Direction:** Add an idempotent deletion plan/journal and explicit retry state; never promise atomicity the stores cannot provide.

#### HTD-DATA-006 - Snapshot freshness policy differs across native consumers
- **Severity / confidence:** MEDIUM / HIGH
- **Affected:** HomeWidget SharedPreferences/app group and WatchConnectivity application context.
- **Observed/evidence:** `android_widget_service.dart:294-295` writes `snapshot_schema` and `snapshot_updated_at`; `ios/Runner/WatchConnectivityHost.swift:76-81` adds schema/update time; `ios/HydrionWatch/HydrationSnapshot.swift:16-32` validates and rejects older contexts. `ios/HydrionWidgets/HydrionWidgets.swift:35-50` already marks six-hour/previous-day data stale. The Android widget Kotlin readers and watch ContentView do not apply that equivalent age/day policy; watch reachability is not data freshness. No common data-through/timezone contract exists.
- **Problem / why it works today:** Repository listeners and app launch usually refresh. Killed/background apps can leave yesterday's Android/watch state looking current; the iOS widget mitigation must be preserved, not reinvented.
- **Direction:** Use one versioned projection with day/freshness fields and stale UI. Do not make native extensions recompute hydration truth.

#### HTD-SEC-003 - Recommendation fingerprints persist sensitive source values in plaintext
- **Severity / confidence:** HIGH / HIGH
- **Type:** PRIVACY BUG.
- **Affected / evidence:** `lib/services/daily_hydration_recommendation_coordinator.dart:38-51,69-72` joins `metrics.toJson()`, daily context, age/sex and weather into a string, not a digest. `lib/repositories/personalization_state_repository.dart:121-127,144-157,184-195` stores it as `lastInputFingerprint` and copies it into `reviewedRecommendationsByDate` in SharedPreferences.
- **Observed / why wrong:** clinician target, reproductive fields, body measurements and context can leave the secure-body boundary through this derived copy. Securing only `BodyMetricsRepository` does not secure their lineage; reviewed fingerprints accumulate by date without a retention bound in that map.
- **Why it appears to work / impact:** equality checks deduplicate calculations correctly, hiding the plaintext disclosure. No network exfiltration is claimed. Existing installations can retain sensitive copies after the source migration.
- **Invariant / dependencies / direction:** least disclosure applies to every derived cache (root D, stage 1). Use a deliberately minimized opaque equality token and explicit migration/deletion of legacy copies; a plain hash of low-entropy sensitive values is not automatically privacy-safe. **Do not** log or export fingerprints. Validate actual serialized stores after recommendation/review/restart/reset, including migrated legacy data; extend `test/daily_hydration_recommendation_coordinator_test.dart`, `test/personalization_repository_test.dart`, and `test/sensitive_body_metrics_store_test.dart`.

#### HTD-DATA-007 - Stale secure values override a newer plaintext fallback on restart
- **Severity / confidence:** HIGH / HIGH
- **Affected / evidence:** `lib/repositories/body_metrics_repository.dart:175-203,229-249`, `_persist` / `_mergeWithSecureStore`; `lib/services/sensitive_body_metrics_store.dart:66-81` conflates unavailable/corrupt/absent reads as null.
- **Observed:** secure A exists; saving B fails secure write/readback, so B is written to plaintext. Next load finds secure A and treats it as authoritative, merges A over B and strips sensitive plaintext B. No generation/commit marker orders the two copies. Conversely, a transient null secure read after plaintext stripping can expose default metrics/safety state.
- **Why wrong / why it appears to work:** first migration and successful writes pass; already-migrated partial failures violate latest-committed authority. This is a concrete code-path failure, not observed physical data loss.
- **Impact / invariant:** saved clinician/safety/body values may silently revert or disappear; secure unavailability must not redefine health truth.
- **Dependencies / direction:** stage 1 explicit read outcomes, versioned migration/recovery protocol and typed degraded state. **Do not** blindly prefer either store or strip an unverified newer copy. Validate secure A -> failed B -> restart, read unavailable after successful migration, malformed secure maps and recovery; extend `test/sensitive_body_metrics_store_test.dart`.

#### HTD-DATA-008 - Secure body deletion can report success while preserving recoverable data
- **Severity / confidence:** HIGH / HIGH
- **Type:** PRIVACY BUG.
- **Affected / evidence:** `lib/services/sensitive_body_metrics_store.dart:106-119` catches delete failures; `lib/repositories/body_metrics_repository.dart:160-167` clears preferences then awaits that best-effort method; `lib/services/local_profile_reset_service.dart:101-182` cannot see the swallowed failure.
- **Observed:** a failing native delete leaves the secure map; reset can count body metrics as cleared. A later load merges the remaining secure map into the empty profile.
- **Why wrong / why it appears to work:** the memory fake always deletes successfully; an unavailable native store does not. Deletion completion must represent every sensitive copy.
- **Impact / invariant:** private values can reappear after an apparently successful reset. Separate from the honestly reported partial reset in HTD-DATA-005.
- **Dependencies / direction:** typed secure outcomes and resumable deletion (stage 1); verify deletion or retain explicit pending state without repopulating a deleted profile. **Do not** swallow failure or wipe unrelated records. Validate denied/locked native deletion, restart, retries and successful absence; extend secure-store and profile-reset tests.

### Root cause E: orchestration, diagnostics and boundaries are feature-local

#### HTD-ARCH-005 - `HydrionServices` and raw Provider exposure form a mutable service locator
- **Severity / confidence:** MEDIUM / HIGH
- **Affected:** `main.dart:390-460,534-1128` and screens.
- **Observed/evidence:** One large object composes repositories, controllers, adapters and inactive shells; UI receives raw repositories and services.
- **Problem / why it works today:** Construction is centralized and tests can use memory services. Any screen can bypass application policy, which is exactly how target commits and summary recomputation proliferated.
- **Direction:** Keep one composition root but expose bounded use cases/read models per domain. Do not split into many global singletons.

#### HTD-ARCH-006 - Layer dependency inversions leak persistence/UI types
- **Severity / confidence:** MEDIUM / HIGH
- **Affected:** `domain/hydration_report.dart` imports repository model; `domain/companion_state.dart` and `profile_art_registry.dart` import settings repository; `domain/temperature_roulette.dart` imports weather service; PDF service imports UI `intake_ring.dart`.
- **Problem / why it works today:** Dart compiles and ownership is informal. Domain evolution drags persistence/UI dependencies and prevents isolated contracts.
- **Direction:** Move shared value models/policies into domain; adapters/services depend inward. Refactor only while migrating real callers.

#### HTD-ORCH-003 - Two notification mechanisms and several reconciliation hooks coexist
- **Severity / confidence:** MEDIUM / HIGH
- **Affected:** `NotificationService`, `TimedSessionNotificationService`, Pomodoro, homework, shell/startup.
- **Observed/evidence:** Scheduled reminders reconcile persisted definitions/OS IDs (`notifications.dart:669+`); timed sessions maintain separate signatures/active notifications (`timed_session_notification_service.dart:133-180`). Startup and resume invoke multiple reconciliations (`main.dart:713-735`; `hydrion_shell.dart:86-100`).
- **Concrete caller gap:** `lib/ui/components/reminder_tile.dart:40-45` invokes the suggested-reminder method without wake/sleep values or sent-today count. Those default to absent schedule and zero count (`notifications.dart:493-519`), so the new waking-window/cap policy is not enforced by that UI path even though `test/notification_service_test.dart` can exercise it with explicit inputs. `isActiveTime=false` lowers urgency; it is not equivalent to passing the waking schedule.
- **Problem / why it works today:** The mechanisms serve legitimate different delivery modes, but lifecycle ordering and cleanup are cross-wired by callbacks.
- **Direction:** Keep adapters distinct, define one notification orchestration contract and authoritative timer state. Add ordering/idempotency invariants.

#### HTD-STATE-002 - Health connection truth is reconstructed from persisted flags and live OS permissions
- **Severity / confidence:** LOW / MEDIUM
- **Affected:** `HealthConnectionController`.
- **Observed/evidence:** Controller persists `_locallyConnected`, permission-request state and sync results, then refreshes against provider authorization (`health_connection_controller.dart:113-194,322-385,411-466`).
- **Problem / why it works today:** Refresh correctly resets live availability/permission fields and distinguishes installation, update, unavailable, denied, partial and revoked states. Combining persisted user intent with live authorization is BENIGN, not inherently a defect. Residual HARDENING: no explicit age for the last permission observation, and a refresh request is dropped while `_operationInProgress` is true. No false connected state was reproduced in this audit.
- **Direction:** Treat OS capability/permission as observed truth and persisted state as last-known metadata with timestamps.

#### HTD-ORCH-004 - Busy snapshot publishers drop the final state change
- **Severity / confidence:** MEDIUM / HIGH
- **Affected / evidence:** `lib/services/android_widget_service.dart:280-321` and `lib/services/watch_connectivity_service.dart:48-71`, repository listeners registered during initialization.
- **Observed:** each captures a snapshot, awaits platform publication, and ignores any concurrent `sync()` while `_syncing` is true. No dirty flag, generation comparison or follow-up sync exists. Widget keys are written separately with `Future.wait`, not as one atomic snapshot envelope.
- **Why wrong / why it appears to work:** slow separated interactions refresh correctly; an intake/goal change during an in-flight send can leave the latest state unpublished until another event. Native watch queuing only coalesces snapshots it receives; it cannot recover a Dart-side dropped one.
- **Invariant / impact:** eventual projection reflects the latest committed version; widgets/watch can remain stale or briefly read mixed-version keys.
- **Dependencies / direction:** stage 6 versioned projection, coalesced dirty retry and atomic native read envelope. **Do not** introduce unbounded retries or send raw source records. Extend `test/android_widget_service_test.dart` and watch channel tests with controlled delayed publication, two updates, failure, disposal and restart.

#### HTD-OBS-001 - Failures are often swallowed or collapsed into generic codes
- **Severity / confidence:** MEDIUM / HIGH
- **Affected:** repositories, health sync, notifications, reset, secure stores, reports and watch/widget sync.
- **Observed/evidence:** Numerous `catch (_)` blocks; health sync maps unknown provider/repository failure to one code (`health_data_sync_coordinator.dart:222-235`); watch logs only a generic message; secure body store swallows failures.
- **Problem / why it works today:** User flows fail softly and privacy is protected. Developers cannot distinguish storage corruption, permission failure, adapter bugs or transient platform errors without payload logging.
- **Direction:** Add structured, non-sensitive diagnostic events with subsystem/stage/code/correlation ID. Never log health values, tokens or provider payloads.

#### HTD-PERF-001 - Hydration history is a whole-list JSON store with repeated linear scans
- **Severity / confidence:** MEDIUM / HIGH
- **Affected:** `HydrationRepository`, analytics/reports/challenges/widgets.
- **Observed/evidence:** Every write serializes the log list; many screens scan `logs` or call `totalForDay` repeatedly; reports aggregate raw history. No retention/index/page boundary exists.
- **Problem / why it works today:** Current datasets are small. Long-term users create increasing startup, write, memory and report costs.
- **Direction:** After canonical event/query contracts exist, migrate to an indexed transactional store. Do not optimize by persisting more unsourced aggregates.

#### HTD-PERF-002 - Challenge modules are oversized responsibility clusters
- **Severity / confidence:** MEDIUM / HIGH
- **Affected:** `challenge_repository.dart` (~1,700 lines), `challenge_experience_screen.dart` (>4,000 lines), `settings_repository.dart` (>1,200 lines), `main.dart` (>1,100 lines).
- **Problem / why it works today:** Co-location makes feature delivery fast. Persistence, session state, qualification, date logic, UI and notification orchestration cannot evolve/test independently.
- **Concrete responsibility evidence:** challenge `1073/1141` performs intake commands, `1519-1630` computes progress/date qualification, and the experience screen controls timed-session notifications. Size alone is not the finding. Resource follow-up: `HydrionServices.dispose` (`lib/main.dart:1098-1100`) closes only the health DB despite widget/watch listener disposal methods; replacement-graph lifetime cleanup needs verification, not an assertion of a measured leak.
- **Direction:** Extract by existing responsibilities and invariants while retaining one challenge authority. Do not create one service per challenge.

### Root cause F: partial/platform/future surfaces blur current capability

#### HTD-PLATFORM-001 - Capability reporting conflicts with implemented provider surfaces
- **Severity / confidence:** MEDIUM / HIGH
- **Affected:** `WearableService`, `AppCapabilities`, HealthKit/Health Connect UI/controllers.
- **Observed/evidence:** Legacy wearable facade reports `supportsHealthSync=false` while real HealthKit/Health Connect adapters and connection screens exist; standalone capability flags also default false.
- **Problem / why it works today:** Modern screens use the controller, legacy status tests remain honest about the facade. Generic capability consumers/AI can say health sync is unavailable despite a connected provider.
- **Direction:** Derive capability from registered provider + runtime availability + permission state; retire legacy facade claims.

#### HTD-PLATFORM-002 - Desktop/web and physical-platform parity is not established
- **Severity / confidence:** MEDIUM / HIGH
- **Affected:** secure body store, encrypted health persistence, notifications, widgets/watch, file export.
- **Observed/evidence:** Health persistence and secure body store explicitly support Android/iOS only; widgets are platform-specific; other platforms use fallbacks. Static scaffolding exists for web/desktop, but current audit did not run them.
- **Problem / why it works today:** Mobile is the active product path. Shared UI can imply features that are absent or plaintext elsewhere.
- **Direction:** Publish a capability matrix enforced by runtime tests; intentional unsupported states must be explicit.

#### HTD-ARCH-007 - Wearable health extraction is a high-quality island, not production personalization input
- **Severity / confidence:** MEDIUM / HIGH
- **Affected:** `HydrationFeatureExtractor`, daily context/recommendation coordinator.
- **Observed/evidence:** Extractor merges workout intervals, selects source priority, excludes duplicates and versions output, but sets `productionTargetIntegrationEnabled=false` (`hydration_feature_extractor.dart:3-126`).
- **Problem / why it works today:** Imported health data is safely viewable and cannot unexpectedly change a target. Product expectation of wearable-informed hydration is not fulfilled, and a future shortcut could bypass daily context.
- **Direction:** Add a consented, freshness-bounded derivation into canonical daily context, never direct target mutation.

#### HTD-DEAD-002 - Dormant Rust, packs, configs and scripts enlarge the apparent architecture
- **Severity / confidence:** LOW / HIGH
- **Affected:** `core/`, `packs/byok_llm`, `packs/gemini_connector`, `packs/edge_llm`, model/scripts/config placeholders.
- **Observed/evidence:** No Flutter FFI/build hook or runtime reference; active Gemini lives under `lib/adapters/gemini`. Existing `STALE_SCAFFOLD_AUDIT.md` records the same separation.
- **Problem / why it works today:** Build ignores most of it. Contributors can mistake historical scaffolding for supported integration, and some dormant config is bundled as assets.
- **Direction:** Classify/archive only after owner decision and call/build verification. Preserve Gate 0 connector work; it is not this stale pack.

#### HTD-TEST-002 - Test architecture lacks cross-feature system invariants
- **Severity / confidence:** MEDIUM / HIGH
- **Affected:** test suite and memory service graph.
- **Observed/evidence:** Extensive focused tests exist (health sync, repositories, notifications, targets, reports), but memory composition uses fake platform adapters and tests usually exercise one feature. No test proves all consumers share one daily fact, one calendar boundary or one target committer.
- **Correction to scope:** `test/boundary_architecture_test.dart` DOES enforce AI adapter/UI/import and dependency rules. These are valuable narrow architecture tests, not absence of architecture testing. They do not cover the target/ingestion/calendar/secure-copy invariants listed here.
- **Problem / why it works today:** Unit coverage catches local regressions while architectural duplication stays green.
- **Direction:** Add invariant/contract suites after each convergence stage; keep platform tests separate and truthfully labeled.

#### HTD-DOC-001 - Connector document status is stale relative to main
- **Severity / confidence:** MEDIUM / HIGH
- **Affected:** `docs/architecture/HYDRION_CONNECTOR_ARCHITECTURE.md`.
- **Observed/evidence:** Lines 20 and 458-517 say Gate 1 has not started and list decline/clinician/auto-apply/storage items as unfixed; commit `50dc1dc` fixed decline and clinician auto-apply, changed weather evaluation, and began secure body-metric migration.
- **Problem / why it works today:** The architecture itself remains useful, but gate status can mislead implementation ordering and audits.
- **Direction:** Update evidence/status without declaring Gate 1 complete. Do not start Gate 2 from a partially closed checklist.

#### HTD-PLATFORM-003 - Shared startup reaches unguarded dart:io platform queries on Web
- **Severity / confidence:** HIGH / HIGH
- **Affected / evidence:** `lib/main.dart:740,749` unconditionally awaits widget/watch initialization in `HydrionServices.local`; `lib/services/android_widget_service.dart:128` and `lib/services/watch_connectivity_service.dart:35` evaluate `Platform.isAndroid/isIOS` without `kIsWeb` or a conditional adapter. Both sync guards have the same issue outside their try blocks.
- **Observed / why wrong:** production Web startup reaches an unsupported `dart:io Platform` query instead of an explicit unavailable implementation. A successful Web compilation would not establish startup success. This audit did not run a browser or claim a reproduced runtime trace.
- **Why it appears to work / impact:** native mobile and tests using `fromStore` bypass the failing platform boundary; Web loading can fail before the app is ready.
- **Invariant / dependencies / direction:** unsupported platform features do not break core hydration (root F, stage 0). Use capability-safe adapters/guards in the composed startup path. **Do not** suppress all initialization exceptions or pretend watch support exists on Web. Validate a production-composition Web launch and manual intake, plus native widget/watch regression; extend `test/widget_test.dart` and browser smoke coverage.

### Finding completion matrix

This matrix completes the dependency, invariant, prohibition and validation fields for every finding. It is normative together with the detailed evidence above.

| Finding | Dependencies | Canonical invariant | What not to do | Required post-remediation validation |
|---|---|---|---|---|
| HTD-ARCH-001 | Weather acquisition and full engine | One automated calculator | Do not synchronize duplicate constants | Golden factor tests plus production call-site scan |
| HTD-ORCH-001 | HTD-ARCH-001 | One automated commit policy | Do not bury feature policy in persistence | Clinician, restriction, decline, manual and auto-apply system tests |
| HTD-ORCH-002 | Recommendation coordinator | UI renders decisions; it does not own safety | Do not create another screen coordinator | Lifecycle/unmount and alternate-caller tests |
| HTD-STATE-001 | Explicit target decision modes; history follows in stage 5 | State and provenance are explicit | Do not add another boolean | Legacy JSON migration and state-machine tests |
| HTD-DATA-001 | Unified commit authority | Historical target facts are append-only | Do not infer history from current flags | Migration, ordering, recovery and report-history tests |
| HTD-TEST-001 | Target convergence | Tests certify system invariants | Do not delete existing safety unit tests | Architecture guard plus end-to-end target suite |
| HTD-INGEST-001 | Existing repository persistence | Every intake crosses one command boundary | Do not duplicate validation in adapters | Caller scan and source-by-source contract tests |
| HTD-INGEST-002 | HTD-INGEST-001 | Every event has typed identity and provenance | Do not encode identity only in metadata | Replay, retry, offline and collision tests |
| HTD-DATA-002 | Canonical intake command | Invalid physical values cannot persist | Do not rely on picker bounds | Zero, negative, upper-bound and adapter tests |
| HTD-DATA-003 | Time policy | All periods are half-open | Do not patch consumers independently | Exact-midnight and cross-period consistency tests |
| HTD-DEAD-001 | Caller and roadmap confirmation | Unsupported APIs cannot mutate truth | Do not activate code to justify keeping it | Static caller scan and regression suite after removal |
| HTD-TIME-001 | Timezone/product decision | One clock and calendar policy | Do not mechanically wrap calls without semantics | Injected-clock, travel, rollover and DST suites |
| HTD-TIME-002 | HTD-TIME-001 | Calendar days use local boundaries | Do not add fixed 24-hour local days | Spring/fall DST and timezone tests |
| HTD-TIME-003 | HTD-TIME-001 | Challenge windows layer on canonical days | Do not erase legitimate overnight rules | Overnight, rollover and widget parity tests |
| HTD-ARCH-002 | Daily facts query | Consumers format, not reconstruct, facts | Do not persist unsourced duplicate aggregates | Cross-consumer golden projection tests |
| HTD-ARCH-003 | Target history and daily facts | One streak policy | Do not retain private capped variants | Long-streak and target-change tests |
| HTD-DATA-004 | HTD-DATA-001 | Historical reports use historical targets | Do not backfill unknown history with current target | Multi-change, unknown-target and PDF tests |
| HTD-ARCH-004 | Canonical daily facts | Hydration pacing is a shared read model | Do not let projections mutate pacing | Home, AI and reminder parity tests |
| HTD-SEC-001 | Approved data classification and migrations | Sensitive storage fails closed or visibly degraded | Do not delete plaintext before verified secure write | Device migration, rollback, backup and deletion tests |
| HTD-SEC-002 | Owner decision on BYOK or proxy | Distributed clients contain no app-owned secret | Do not call compile-time defines secure storage | Binary scan, revocation, quota and auth tests |
| HTD-PRIV-001 | Purpose-specific projection contract | Remote disclosure is minimized and consented | Do not send raw provider or clinical records | Payload snapshot, redaction and consent tests |
| HTD-PRIV-002 | Per-platform store inventory | Backup behavior is explicit by data class | Do not assume platform encryption equals policy | Physical backup/restore and exclusion tests |
| HTD-DATA-005 | Store deletion capabilities | Reset is idempotent, resumable and honest | Do not claim cross-store atomicity | Failure-at-each-stage and retry tests |
| HTD-DATA-006 | Canonical projection contract | Every snapshot declares day and freshness | Do not recompute truth in extensions | Killed-app, stale-day and version migration tests |
| HTD-ARCH-005 | Migrated commands/read models | Composition exposes bounded capabilities | Do not replace it with global singletons | Import/caller guards and full UI suite |
| HTD-ARCH-006 | Shared domain value models | Dependencies point inward | Do not move types without real caller migration | Dependency-rule scan and focused compilation tests |
| HTD-ORCH-003 | Notification ownership decision | Lifecycle reconciliation is ordered and idempotent | Do not conflate scheduled and active mechanisms | Restart, resume, cancel and duplicate-delivery tests |
| HTD-STATE-002 | Provider capability contract | OS truth and last-known state are distinct | Do not persist permission as eternal truth | Revoke, unavailable, stale and recovery tests |
| HTD-OBS-001 | Error taxonomy | Diagnostics are structured and non-sensitive | Do not log payloads, tokens or health values | Redaction tests and failure-code coverage |
| HTD-PERF-001 | Canonical event/query contracts | Source events remain authoritative | Do not add unsourced caches as truth | Bounded large-history benchmarks and migration tests |
| HTD-PERF-002 | Stable challenge authority | Modules split by responsibility | Do not create one service per challenge | Behavior snapshots and challenge suite |
| HTD-PLATFORM-001 | Registered provider registry | Capability derives from runtime provider state | Do not hard-code one global health flag | Platform/provider capability matrix tests |
| HTD-PLATFORM-002 | Product platform scope | Unsupported behavior is explicit | Do not infer parity from shared Flutter UI | Per-platform build and runtime acceptance |
| HTD-ARCH-007 | Consent, freshness and source-priority policy | Imported observations enter bounded daily context | Do not mutate target from a provider adapter | Synthetic extraction-to-recommendation system tests |
| HTD-DEAD-002 | Owner classification | Repository surfaces match supported architecture | Do not delete Gate 0 or uncertain user assets | Build/reference scan and artifact manifest review |
| HTD-TEST-002 | Each convergence stage | Cross-feature invariants are executable | Do not substitute fake-platform tests for device evidence | Contract suite plus separately labelled platform runs |
| HTD-DOC-001 | Verified Gate 1 evidence | Architecture status matches repository truth | Do not declare Gate 1 complete | Document checklist review against current SHA |

### Finding impact ledger

| Finding | User/system impact if unresolved |
|---|---|
| HTD-ARCH-001 | Users can receive divergent targets as formulas or callers evolve. |
| HTD-ORCH-001 | Automated changes can bypass clinician, consent or provenance policy. |
| HTD-ORCH-002 | Correctness depends on one mounted screen and lifecycle ordering. |
| HTD-STATE-001 | Reports and future integrations can misstate why a target is active. |
| HTD-DATA-001 | Historical compliance, reports and published snapshots cannot be trusted. |
| HTD-TEST-001 | Locally green tests can coexist with a production policy bypass. |
| HTD-INGEST-001 | Intake sources can disagree on validation, replay and provenance. |
| HTD-INGEST-002 | Retries or offline replay can duplicate indistinguishable events. |
| HTD-DATA-002 | Invalid zero or extreme hydration volumes can enter canonical history. |
| HTD-DATA-003 | Midnight entries can change counts and totals inconsistently. |
| HTD-DEAD-001 | Future code can accidentally revive unsupported mutation paths. |
| HTD-TIME-001 | Travel, DST and rollover can split one user's facts across features. |
| HTD-TIME-002 | Totals can omit or include the wrong hour on DST transition days. |
| HTD-TIME-003 | Challenge progress can disagree with global day totals and widgets. |
| HTD-ARCH-002 | Home, analytics, AI and reports can show different summaries. |
| HTD-ARCH-003 | Visible streak length can depend on which screen computes it. |
| HTD-DATA-004 | Historical target-met results can be materially false. |
| HTD-ARCH-004 | Advisory hydration state is inconsistent or absent outside Home. |
| HTD-SEC-001 | Comparable sensitive data can silently remain less protected. |
| HTD-SEC-002 | A shipped app-owned Gemini key exposes quota and billing credentials. |
| HTD-PRIV-001 | More personal context than needed can leave the device. |
| HTD-PRIV-002 | Backup and retention expectations differ silently by platform. |
| HTD-DATA-005 | A failed reset can leave a partially erased, hard-to-recover profile. |
| HTD-DATA-006 | Widgets or watch can present yesterday's data as current. |
| HTD-ARCH-005 | Any screen can bypass intended policy and duplicate orchestration. |
| HTD-ARCH-006 | Domain changes require coordinated persistence/UI changes and increase regression risk. |
| HTD-ORCH-003 | Restart/resume ordering can leave duplicate or stale notifications. |
| HTD-STATE-002 | Connection UI can temporarily claim stale or underspecified provider state. |
| HTD-OBS-001 | Failures can be user-visible without safe evidence of their cause. |
| HTD-PERF-001 | Long-lived accounts face growing startup, write and report cost. |
| HTD-PERF-002 | Challenge changes carry a wide regression and review surface. |
| HTD-PLATFORM-001 | Capability messages can contradict an available connected provider. |
| HTD-PLATFORM-002 | Shared UI can imply unavailable or differently protected behavior. |
| HTD-ARCH-007 | Imported health data remains disconnected from promised personalization. |
| HTD-DEAD-002 | Contributors can build against unsupported historical scaffolding. |
| HTD-TEST-002 | Cross-feature divergence can remain undetected despite broad unit coverage. |
| HTD-DOC-001 | Teams can start later connector work from an incorrect gate status. |

### Test evidence and system-invariant gaps

These are inspected existing suites, not newly executed tests or claims that proposed cases already pass. Full suite status is section 12.

| Findings / boundaries | Existing source evidence | Missing system-level proof |
|---|---|---|
| ARCH-001, ORCH-001/002, STATE-001, TEST-001 | `test/personalized_hydration_engine_test.dart`, `test/weather_location_goal_test.dart`, `test/daily_hydration_recommendation_coordinator_test.dart` | Every recommendation writer enforces current safety/decision mode; preview acceptance cannot become an alternate authority |
| SEC-001/003, DATA-007/008 | `test/sensitive_body_metrics_store_test.dart`, `test/personalization_repository_test.dart`, `test/health_database_key_store_test.dart` | Secure A / failed B / restart; denied deletion; no sensitive raw fingerprint in ANY persisted key; supported-but-unavailable distinct from unsupported |
| INGEST-001/002, DATA-002/003/010 | `test/persistence_test.dart`, `test/storage_recovery_test.dart`, `test/android_widget_service_test.dart` | All sources have same validation/identity; concurrent rollback serializability; midnight total/count parity; restoration cannot bypass replay policy |
| DATA-001/004, TIME-001/002/003, ARCH-002/003/004/008, DATA-009 | `test/hydration_report_test.dart`, `test/hydration_pacing_engine_test.dart`, `test/notification_service_test.dart` | Shared daily facts after historical target change, DST/travel, real reminder caller inputs, score/eco attribution and long streak consistency |
| ARCH-007, DATA-011, STATE-002 | `test/health_data_sync_coordinator_test.dart`, `test/health_connection_controller_test.dart`, `test/hydration_feature_extractor_test.dart`, `test/encrypted_health_data_repository_test.dart` | Cross-day quantity conservation and expired-cursor absent-record treatment before activating derived targets; physical provider binding remains separate |
| DATA-006, ORCH-004, PLATFORM-003 | `test/android_widget_service_test.dart`, `test/ios_release_configuration_test.dart`, `test/widget_test.dart` | Production Web startup, delayed send/latest update delivery, native freshness and atomic snapshot publication |
| SEC-002, PRIV-001/002, ARCH-005/006, TEST-002, DEAD-001/002 | `test/boundary_architecture_test.dart`, provider/config tests and manifest/entitlement source | Shipped binary credential exposure, actual backup retention, runtime resource disposal and broader non-AI domain boundaries |

No absent proof above is a claim that all related testing is missing. In particular, encrypted health rollback, source deduplication, authorization and AI adapter boundaries already have meaningful focused coverage. Their strengths should become reusable patterns.

### Audit completeness answers

1. **Independent hydration intake paths:** seven static `addLog` sites across six components: five reachable product command sites (manual, widget, two challenge commands, confirmed AI), two transitional sites (wearable and CoreBridge through uncalled EcoTracker.logHydration). Additionally, LogScreen edit and undo use `updateLog`/`restoreLog`: nine mutation call sites in this defined inventory, not nine new-intake products. HealthKit/Connect are two separate observation adapters, not water intake. Startup deserialization is restoration, not a live ingestion command. No implemented bottle/watch-water import found.
2. **Do they converge before domain computation?** They converge at `HydrationRepository`, but not through a complete canonical ingestion policy. Therefore **no** for validation/provenance/idempotency; **yes** only for persistence.
3. **Daily consumed volume implementations:** two general implementations (`totalForDay`, report aggregation), plus challenge-specific folds. Exact semantic count is **NOT FULLY VERIFIED** because challenge objectives intentionally use qualified subsets.
4. **Target calculators:** two (`PersonalizedHydrationEngine`, `DeterministicWeatherGoalService`). Only the first is intended to be authoritative.
5. **Target recommendation commit paths:** three caller families with four direct write sites: shell auto (`178-188`) and confirmed dialog (`270-277`), weather `acceptRecommendation`, recommendation coordinator `apply`. They reach two settings mutators. Only shell auto is unconfirmed automatic application; the others apply calculated recommendations with caller-dependent consent. The coordinator itself is not yet a safety-enforcing committer. Manual baseline/restore/reset paths are distinct and excluded from this count.
6. **Streak implementations:** two.
7. **Summary/report metric builders:** four general builders (local summary adapter, AI context builder, Analytics UI, report calculator), excluding challenge-specific progress.
8. **Reminder schedulers/decision systems:** one scheduled OS notification service, one active timed-session notification service, one `ReminderPolicy` suggestion/urgency decision class, plus the shared pacing waking-window guard. Native adapters are transport implementations, not additional domain schedulers. These four roles must not be collapsed into one misleading count.
9. **Distinct notions of "today":** **NOT FULLY VERIFIED; at least seven** (hydration 24-hour interval, report calendar interval, date-key helper, challenge local/activity day, UI direct local dates, widget/watch capture, UTC wearable dashboard).
10. **Separate dedup/reconciliation mechanisms:** **at least six**: hydration action IDs, challenge completed/in-flight actions, health provider key+fingerprint+deletion reconciliation, notification duplicate/OS-ID reconciliation, Pomodoro consumed-session reconciliation, recognition-event IDs. This is a lower bound because per-feature day gates are also dedup.
11. **Sensitive storage:** at least five storage families: application SharedPreferences (multiple datasets including raw recommendation fingerprints); SQLCipher health DB; native secure store (body fields/DB key); widget/app-group preferences; watch platform context/cache. Generated/shared reports are a sixth external-copy surface. This is a family count, NOT a verified count of all native files/backups; that exact physical count is NOT FULLY VERIFIED. Photo base64 is inside settings, not a separate file store.
12. **Facts without obvious canonical owner:** current local day/timezone, historical target/provenance, public streak, cross-feature daily summary, next reminder truth, and a unified hydration state projection.
13. **Features that write data they should only consume:** shell weather UI and weather accept API write active target directly; legacy WearableService and CoreBridge can write intake; challenge/AI writes are legitimate commands but bypass a shared ingestion use case.
14. **Tests certifying obsolete/duplicated architecture:** weather preview/accept tests preserve the second calculator/direct committer; legacy persistence tests preserve false wearable capability; separate summary/streak tests do not assert shared semantics.
15. **Highest-collision feature pair:** weather/personalization with clinician-safety, because it combines duplicate calculation, direct commit and UI lifecycle ordering.
16. **Largest-blast-radius defect:** absence of canonical calendar/day and aggregate authority. It affects logs, totals, streaks, challenges, reports, widgets/watch, AI context, wearable derivation and future Muse freshness.
17. **Greatest future-feature root-cause risk:** B, persistence mistaken for an intake authority, together with A's optional target policy. New bottle/assistant/provider adapters can repeat the existing source-specific mutation pattern. New weather/AI/report/notification adapters must consume typed observations/commands/projections, not invent another calculator or state store.
18. **Most orchestration-dependent working feature:** daily weather-assisted target application in `HydrionShell`: lifecycle/cache eligibility -> engine -> mayAutoApply -> dialog -> settings/review bookkeeping. Widget/watch publication is a second example dependent on a single listener event after any in-flight send.

## 10. Working-but-Wrong Architecture

| Working behavior | Why it works today | Why it is not sufficient architecture |
|---|---|---|
| Secure body migration | Successful write/readback tests preserve data | Another plaintext fingerprint copy survives; failed later writes restore stale secure truth (SEC-003/DATA-007) |
| Weather assistance | Shell checks current engine eligibility before its normal automatic write | Other commit paths and the proposed coordinator do not enforce policy themselves (ORCH-001/002) |
| Reports/streaks | Ordinary current-target, within-day fixtures agree | Historical targets and interval boundaries differ by consumer (DATA-004/ARCH-003) |
| Score and eco savings | Widget formulas return plausible numbers | Entry count/current preference are not canonical historical hydration/environment facts (ARCH-008/DATA-009) |
| Widget/watch refresh | A normal single event publishes successfully | Busy events are discarded; transport update time is not universal freshness (ORCH-004/DATA-006) |
| Green focused tests | Fakes/isolated flows exercise their intended feature | They bypass composed Web startup and do not settle concurrent writes or secure fallback restart ordering (TEST-002/PLATFORM-003/DATA-010) |
| Wearable ingestion | Canonical, encrypted, transactional records/checkpoints are well bounded | That success does not enable personalized target integration; extractor period allocation needs validation before activation (ARCH-007/DATA-011) |

## 11. Fragile Glue / Safety Pins

Ranked by affected truth, not by file size:

1. **Very high:** secure-copy preference and read-null/delete-success assumptions connect native storage to clinician/body authority (DATA-007/008). Single swallowed outcomes can change source truth.
2. **Very high:** UI shell eligibility is the safety gate before raw target mutation (ORCH-001/002); manual versus automated decisions are not encoded at the write boundary.
3. **High:** one mutable log list plus awaited whole-list rollback connects all intake writers and projections (DATA-010); per-action dedup is not a transaction lock.
4. **High:** latest manual/weather flag/timestamp stands in for target history across reports and streaks (DATA-001/004/STATE-001).
5. **High:** root startup awaits platform-specific widget/watch initialization without a Web-safe capability boundary (PLATFORM-003).
6. **Medium:** a listener callback is the only publication trigger; `_syncing` loses updates (ORCH-004). iOS WidgetKit's stale badge is an existing mitigation, not delivery proof.
7. **Medium:** startup/resume separately reconcile session notifications, reminders and weather; settings/listener ordering acts as an implicit event bus (ORCH-003/ARCH-005).
8. **Medium:** personalization baseline options and target value are separate awaited writes (`daily_hydration_recommendation_coordinator.dart:88-102`); failure can leave intent and active value inconsistent (STATE-001).
9. **Low / hardening:** provider local intent plus live permission refresh is legitimate; dropped refresh while busy needs explicit observation freshness, not another persisted permission boolean (STATE-002).

## 12. Known CI / Validation Debt

This section records existing evidence. No formatting fix, test change, CI repair or new runtime certification occurred during the audit.

| Evidence | Result / scope |
|---|---|
| Main run 36249499634 at `9ded4f1` | Secret hygiene, analyzer and workflow policy passed; format failed; full test process exit 124 at outer 30-minute deadline; quality gate failed |
| Dependent jobs on that run | Android debug, Android release, Web and iOS all SKIPPED. Not build failures and not successes |
| Provider run 36248590774 at `50dc1dc` | Same pre-existing format/test-timeout symptoms, before integration |
| Prior repair run 35751306799 at `0b4acb5` | All five jobs passed historically; does NOT certify `ab984bf` |
| Local baseline analyzer | `flutter analyze --no-pub`: passed |
| Local focused tests | 70 architecture/personalization/weather/secure-store + 90 provider/controller/sync/iOS configuration/widget/dashboard/workflow = 160 passed |
| Python/workflow/secrets | 37 helper tests; 2 workflow validations; secret scan passed |
| Localization | EN/FR/ES 962 Flutter keys and 24 Android messages each; zero placeholder/identical-language findings in mixed-language audit |
| Formatting | `lib/repositories/body_metrics_repository.dart`, `test/sensitive_body_metrics_store_test.dart`: fail; both originated in Gate 1 `50dc1dc`; left untouched |
| Full local suite | Stalled after 445 passes; diagnostic process was stopped; no full-suite pass or final total claimed |
| Literal audit | 939 findings / 937 reviewed / 2 unresolved: `lib/services/health_connection_controller.dart:169` (`provider_refresh_failed`, `0a1e2fd`); `lib/services/watch_connectivity_service.dart:67` (`Hydrion watch sync failed.`, `b905869`) |

Raw CI machine events identify ten-minute timeouts in `startup_onboarding_test.dart` (first-run completion and partial-onboarding resume), `startup_buffer_test.dart` (fresh-install buffer), and `mission_and_farewell_test.dart` (single continuation/no replay). Legacy completed-user and legal-review tests remained unfinished at cutoff. The generated CI `BUG_REPORT.md` says zero failures/no timeout despite those events and exit 124: reporting debt, not evidence that tests passed. Exact hang cause remains UNPROVEN. Secure-body startup introduces a platform await, but correlation is not proof of causation; do not patch it on this audit alone.

Retained pre-audit evidence: `%LOCALAPPDATA%/Temp/HYDRION_BASELINE_SYNC_20260926.md`, `hydrion-audit-integration-full-tests-20260926.log`, and `hydrion-main-ci-36249499634/ci-artifacts/`. These were read, not generated or deleted by this audit. No fresh Flutter test/build was run merely to repeat known failures. Static inspection, graph tracing and document checks are the new evidence.

## 13. Remediation Program

The program has **12 stages: 0A, 0B, and 1-10**. Rank by security/data loss first; then domain correctness, authority ownership, foundational dependencies, blast radius, migration risk, duplicate elimination, testing prerequisites and operational risk. Broad cleanup never blocks an urgent safety correction. Each finding has exactly one primary stage below; references elsewhere are dependencies, not duplicate assignments. Numbering is not a serial execution requirement. This document-control checkpoint authorizes no runtime remediation.

### Dependency contract

The following table defines hard stage prerequisites. Each edge points from prerequisite to dependent and forms an acyclic plan. Local entry criteria still apply. Stage 0B is not a blanket prerequisite for security, calendar or target-policy repairs; an actual inability to run a required focused acceptance test blocks only the affected task until that validation is restored.

| Stage | Hard prerequisites | Purpose of dependency |
|---|---|---|
| 0A | None | Minimum control, evidence and acceptance discipline |
| 0B | 0A | Baseline/platform repairs under truthful validation controls |
| 1 | 0A | Sensitive storage/deletion corrections with failure fixtures |
| 2 | 0A | Calendar contract and boundary fixtures |
| 3 | 2 | Intake identity and event-day semantics |
| 4 | 0A | Enforcing target policy and explicit decision modes |
| 5 | 2, 3, 4 | Calendar, intake provenance and target authority before historical facts |
| 6 | 1, 5 | Safe disclosure/storage and canonical facts before projection convergence |
| 7 | 2, 6 | Time semantics and freshness contract before final lifecycle convergence |
| 8 | 1, 2, 4, 6 | Protected observations, calendar, target policy and projections before wearable activation |
| 9 | 3, 4, 5, 6, 7, 8 | Cleanup follows the relevant caller migrations |
| 10 | 0A, 0B, 1, 2, 3, 4, 5, 6, 7, 8, 9 | All foundation acceptance and owner authorization before Muse |

After 0A acceptance, **0B, 1, 2 and 4 may proceed independently**, subject to separate implementation authorization. Coordinate changes to shared settings/body/context files through explicit interface contracts and integration review; parallel eligibility does not authorize simultaneous uncoordinated edits. Stage 4 must model unavailable/degraded body inputs honestly and must not claim to repair Stage 1 storage defects. Cross-stage integration acceptance is required at their downstream joins. Design-only preparation can occur earlier without declaring an implementation stage started.

### Remediation governance

Current implementation state: **41 findings remain OPEN**; HTD-DATA-008 is
**IMPLEMENTED_PENDING_ACCEPTANCE** (H1 screen-local deletion completion); HTD-DATA-007 is
**ACCEPTED** (authority recovery, async safety, H4 ordering and acknowledgement-contract containment);
HTD-DOC-001,
HTD-TEST-002 and HTD-OBS-001 are **ACCEPTED** for the
Stage 0A foundation scope, following the owner-reported independent approval
recorded below. These four findings alone are accepted. Acceptance of the audit or
a local implementation commit does not close a remediation stage. Sections
1-12 retain the historical audited evidence; the status record below governs
subsequent implementation progress without rewriting that evidence.

- **OPEN:** recorded defect or hardening requirement, no implementation accepted.
- **IN_PROGRESS:** separately authorized implementation task identifies scope, owner, branch/base and affected invariants.
- **IMPLEMENTED_PENDING_ACCEPTANCE:** implementation commit exists with relevant test/evidence results; no claim of architectural completion yet.
- **ACCEPTED:** a reviewer independent of the implementing coding agent has audited the change and recorded acceptance against explicit criteria and commit SHA.
- **DEFERRED:** owner-approved rationale, residual risk, revisit condition and dependent-stage impact are recorded; this is not fixed or automatically gate-clearing.

Every stage requires an implementation task, independent acceptance audit, evidence/test results, documentation update and implementation commit/SHA references. A coding agent must not self-approve its own architectural remediation. Failed acceptance returns the finding to IN_PROGRESS; changed assumptions can reopen an accepted finding. A stage closes only when its assigned findings and non-finding obligations pass independent acceptance, or the owner explicitly approves a documented exception without misrepresenting acceptance.

For later completed findings, HTD records only final state, remediation commit, acceptance evidence link/reviewer and any changed invariant. Keep detailed run logs in external artifacts, not this master document. Preserve failed/skipped/not-run distinctions. Known unrelated baseline failures may accompany scoped acceptance when the independent reviewer documents sufficient focused evidence and limitations; they cannot support a full-suite, release or platform-success claim. A relevant validation failure cannot be waived merely by labelling it pre-existing.

### Document checkpoint control

This plan revision preserves audited runtime HEAD `ab984bf0b1ea2a5bf4c74c246fd91c997a4aa3f4` as its parent baseline; a document-only commit does not recertify that runtime. Pre-revision HTD SHA-256: `bcc3e0817b993ec219f33e9498f5943ca9b06557f6f35058427c1cd2bb82a3cb`. Sections 1-12 and all findings remain unchanged. The unrelated staged `edge_case.md` must not enter this checkpoint. No push is authorized. Historical audit self-check statements below describe the audit run, not this later document-only checkpoint.

## 14. Remediation Stages

### Stage 0A - Remediation control plane
- **Findings:** HTD-DOC-001, HTD-TEST-002, HTD-OBS-001.
- **STATE:** ACCEPTED (administrative closure 2026-09-27). The existing Stage 0A prerequisite for Stages 0B/1/2/4 is satisfied; each still requires separate authorization and its own entry criteria. No subsequent stage is started or completed by this closure.
- **IMPLEMENTATION COMMITS:** `21eebe8543fb214e8c014562aacfcc1b8211726e` (foundation), `f3827e74fda2b0cd55961d235e0c6338b7196981` (status/evidence), `4845f623cbf52357f6a218c532b5a27f09a35e99` (scanner correction), based on checkpoint `9ae695091711df47991417cee84ea5732601c90a`. Scope: status correction, test/diagnostic foundations and acceptance discipline only; no defect remediation outside 0A.
- **INDEPENDENT ACCEPTANCE:** `STAGE 0A ACCEPTANCE: APPROVED`; reviewed SHA `4845f623cbf52357f6a218c532b5a27f09a35e99`. Acceptance reference: owner's 2026-09-27 instruction, "Administratively close Hydrion Stage 0A", reporting completed independent acceptance. Reviewer identity and a separate report URL were not supplied. This entry records that owner-supplied verdict, not implementer self-approval.
- **OBJECTIVE:** Establish canonical architecture status, invariant/characterization framework, structured non-sensitive diagnostic/error taxonomy, truthful CI evidence handling and independent remediation validation discipline.
- **BLOCKS:** architecture implementation stages until the minimum controls and relevant characterization harness are accepted.
- **BLOCKED BY:** none.
- **CAN RUN IN PARALLEL WITH:** storage design review, not runtime migrations.
- **MUST NOT START UNTIL:** owner authorizes remediation, preserves staged `edge_case.md`, and accepts the non-green baseline.
- **ENTRY CRITERIA:** fixed audit SHA and retained raw failure evidence; Apple repair already integrated, not uncommitted work.
- **EXIT CRITERIA:** corrected architecture status, accepted test/diagnostic contracts and executable characterization harness for the next authorized tasks, raw-evidence precedence and independent acceptance procedure. No requirement to fix Web startup, isolate the full-suite hang or resolve unrelated format/literal failures. Finding ownership remains here; broader consumer adoption is verified at later stage acceptance without reassigning these findings.
- **VALIDATION REQUIRED:** focused harness/diagnostic-redaction/boundary tests and document/evidence reconciliation; record known failed or unavailable validation separately. Independent review must verify the harness can detect the intended invariant violations, not just that it executes.

**Implementation evidence:** [commands, results and acceptance format](docs/architecture/REMEDIATION_ACCEPTANCE.md#stage-0a-implementation-receipt).
Acceptance validation against the reviewed SHA: **49 tests passed** (38 focused
architecture/control/diagnostic/characterization tests and 11 secure-store/key
tests); `flutter analyze --no-pub`, scoped Dart formatting, secret scan and
whitespace checks passed. The full Flutter suite, builds and physical-device
validation were **NOT RUN**; those remain separate Stage 0B/later evidence.
No new hosted validation is claimed.
Locked connector sections 2/3 were verified unchanged. Findings and stage
ownership remain 46/12 with no duplicate assignment or dependency cycle.

| Finding | Implementation state | Delivered foundation / remaining boundary |
|---|---|---|
| HTD-DOC-001 | ACCEPTED | Gate 1 partial/not-accepted status corrected; Gate 0 locked, Gate 2+ unstarted, Muse final/paused |
| HTD-TEST-002 | ACCEPTED | Existing AI guards retained; labelled characterization/invariant helper; parser-based domain-to-UI guard with source-to-assertion negative controls, four synthetic defect characterizations, explicit unsupported-result invariant and plan/status checks |
| HTD-OBS-001 | ACCEPTED | Closed-vocabulary local diagnostic/error interpretation contract with injected observation clock and generated correlation IDs; no free-text payload, telemetry or production caller rewrites |

**Limits / remaining work:** acceptance is limited to the Stage 0A foundation
scope under the owner-reported independent verdict above. Dependency guards are
not complete call graphs;
synthetic storage is not native failure certification. Diagnostic adoption and
domain-specific outcome repairs remain with later owning stages. Known format,
full-suite hang, literal-audit and CI-summary failures remain in section 12 and
Stage 0B. No Stage 1/2/4, Stage 0B runtime or connector fix was implemented, and
none of the four characterizations closes the defect it demonstrates.

### Stage 0B - Baseline, validation and platform debt
- **Findings:** HTD-PLATFORM-003.
- **OBJECTIVE:** Repair composed Web startup; investigate full-suite hangs, known formatting/literal failures, CI report/raw-event disagreement and other recorded baseline-validation issues. Section 12 issues are work obligations, not invented or duplicated finding IDs. Diagnostic taxonomy remains owned by OBS-001 in 0A; applying it to CI reporting is a dependent task here.
- **BLOCKED BY:** Stage 0A.
- **BLOCKS:** trustworthy whole-suite/platform/release claims and final Stage 10 acceptance; only an actually affected validation route can block another scoped repair.
- **CAN RUN IN PARALLEL WITH:** Stages 1, 2 and 4 after 0A; later stages when their own prerequisites are met.
- **MUST NOT START UNTIL:** owner authorizes baseline fixes and exact failing commands/raw evidence are retained.
- **ENTRY CRITERIA:** reproducible or explicitly unresolved failure inventory; scoped hypotheses and no hidden retry/skip workaround.
- **EXIT CRITERIA:** composed Web startup works; full-suite failure/hang causes are resolved with a completed truthful run; format/literal audits pass; generated CI summaries agree with exit codes and raw events. Required hosted/platform checks are run, not inferred from focused tests.
- **VALIDATION REQUIRED:** browser/manual-intake smoke, native widget/watch regression, complete Flutter suite with discovered total, analyzer/format/literal/secret/workflow checks and accurate CI report regression tests. Physical certification remains separate.

### Stage 1 - Sensitive data and deletion safety
- **Findings:** HTD-SEC-001, HTD-SEC-002, HTD-SEC-003, HTD-PRIV-002, HTD-DATA-005, HTD-DATA-007, HTD-DATA-008.
- **DATA-007 STATE:** ACCEPTED (administrative closure 2026-09-28). Accepted implementation SHA: `8cb107ab4ba660223b21086c2f1dee1d079e9090`. The historical DATA-007 failures described below are remediated within the accepted scope; their original evidence is retained. Stage 1 as a whole is not closed, and no other remediation work is authorized or started by this closure.
- **DATA-007 IMPLEMENTATION LINEAGE:** `19e7ef011c336cc908951eaffc897a256d270a6a` (authority/recovery and minimum consumers), `8e7bd6573b44fadcded613a41e29bb8012c0991a` (H1 native acknowledgement and H2 async safety), `8cb107ab4ba660223b21086c2f1dee1d079e9090` (H4 ordering and acknowledgement-contract containment).
- **DATA-007 INDEPENDENT ACCEPTANCE:** `HTD-DATA-007 ACCEPTANCE: APPROVED`; independently reviewed SHA `8cb107ab4ba660223b21086c2f1dee1d079e9090`. Acceptance reference: owner's 2026-09-28 instruction, "Administratively close Hydrion finding HTD-DATA-007", reporting completed independent acceptance. Reviewer identity and a separate report URL were not supplied. This records the owner-supplied independent verdict, not implementer self-approval.
- **DATA-007 ACCEPTANCE VALIDATION:** 281 tests passed; `flutter analyze --no-pub`, scoped formatting, secret scan and whitespace checks passed. Independent acceptance findings: none BLOCKER, none HIGH, none MEDIUM, none LOW. These are the reported independent results, separate from the earlier implementation runs below.
- **DATA-007 ACCEPTANCE LIMITATIONS:** SharedPreferences coordination covers adapters sharing one preferences object in one isolate; body revision handling assumes one repository-instance writer. Native write acknowledgement is not physical flash-durability certification. Legacy callers may still ignore false write acknowledgements; broader persistence-integrity debt remains unresolved. Simulator, benchmark, full-suite, builds, hosted CI and physical-device certification were not performed as part of DATA-007 acceptance.
- **OTHER STAGE 1 STATES:** HTD-SEC-003, HTD-SEC-001, HTD-DATA-005, HTD-PRIV-002 and HTD-SEC-002 remain OPEN. Their scope and dependencies are unchanged. DATA-008 is separately authorized below, not by DATA-007 closure.
- **DATA-008 STATE:** IMPLEMENTED_PENDING_ACCEPTANCE after the H1 screen-local completion correction based on `4ba5802fd0d33b657a9333277791baf752c63756` (storage deletion implementation, based on checkpoint `18e09088ced65a13c616bab77c4f205535c013dd`). The focused H1 commit containing this record is titled `fix(data-008): unify body editor deletion completion`. The owner-reported independent review verified the storage-layer design but blocked acceptance on stale editor/recommendation state after Retry. Storage deletion architecture and DATA-007 remain unchanged. Independent read-only re-acceptance is required; no other finding is started or closed.
- **DATA-008 H1 reproduction and correction (2026-09-28):** deterministic widget tests first reproduced stale clinician safety mode after first-pass deletion and a retained personalized baseline after successful Retry. Retry previously called initialization that returned early because the screen was already initialized. Both routes now call one `_completeMetricsDeletion` routine: explicitly reinitialize all drafts/controllers from the empty repository, close editors, clear pregnancy validation and screen recommendation state, and perform the existing manual-baseline transition while preserving the daily goal and persisted weather option. A screen-local generation check rejects recommendations calculated before deletion even if delivered afterward; recommendation orchestration and persistence are not redesigned.
- **DATA-008 H1 validation:** 297 tests passed in one 22-file scoped run, including DATA-008 deletion/restart/reset and DATA-007 authority/cache/async regressions. Three new H1 widget tests cover first-pass/retry parity, cleared reproductive/pregnancy/clinician/safety controls, no sensitive restoration when saving without new data, and late recommendation invalidation. After adding explicit reopened-screen control assertions, all 14 body-editor widget tests passed again. Analyzer (`flutter analyze --no-pub`), two-file scoped formatting, secret scan and whitespace checks passed. Only the body-metrics screen, its widget tests and this HTD record change. Repository deletion protocol, secure store, reset service, engine, weather logic and DATA-007 authority code are unchanged. Full suite, builds, hosted and physical-device validation were not run. DATA-005, SEC-001, SEC-003, PRIV-002 and SEC-002 remain OPEN.
- **DATA-008 reproduction (2026-09-28):** three deterministic tests through the real platform secure adapter, repository and reset service failed before correction: native delete exception was swallowed, restart exposed the surviving body value, and reset reported its body portion completed. The original section 9 failure evidence is retained. The Stage 0A DATA-008 characterization now checks the corrected invariant using the same surviving-secure-copy scenario.
- **DATA-008 deletion protocol:** `SensitiveBodyMetricsStore.delete()` returns a typed status: verifiedAbsent (including already absent), failed, verificationFailed, unavailable or unsupported. The platform adapter deletes then reuses the DATA-007 typed read to verify absence; returning without throwing is insufficient. Corrupt or surviving payload fails verification, unavailable/unsupported is never success, and diagnostics contain status only. This is logical application-level absence, not forensic erasure.
- **DATA-008 intent and ordering:** clear joins the existing single-repository operation queue. It first hides active metrics and replaces the entire local body payload/authority with acknowledged, read-back-checked `{"_bodyDeletion":{"version":1,"pending":true}}`. This payload-free intent outranks any surviving secure revision or older pending fallback on restart; it is not a body revision. Loading intent does not import secure data or silently retry deletion. Saves remain blocked while pending. Explicit clear/reload retries secure deletion; only verified secure absence permits acknowledged blanking of the migration hint and replacement of the body record with `{}`. These empty records contain no sensitive fields; the pending marker is gone, revisions restart at zero, and subsequent new saves use unchanged DATA-007 authority rules. No global local-store/remove contract is changed.
- **DATA-008 consumers:** incomplete clear throws payload-free `BodyMetricsDeletionIncomplete` and remains retryable. LocalProfileResetService already catches subsystem failures, so its unchanged partial-result mechanism reports body deletion failed rather than completed; successful retry reports completed. The body editor handles failure without a deleted-success message and handles repeated failed Retry without an escaping exception. No cross-repository reset journal, fingerprint migration, backup cleanup or other Stage 1 remediation is introduced.
- **DATA-008 validation (2026-09-28):** final scoped run: 294 tests passed across 22 files, including 16 new deletion regressions and one new failed-delete/retry widget test. Covers native rejection/no-op, unavailable verification, corrupt/unsupported/already-absent storage, plaintext pending authority, restart quarantine, each local write rejection phase, retry/idempotency, save/delete interleaving, reset partial results, safe diagnostics, existing DATA-007 authority/async/cache tests, repository/storage recovery, notifications, health connection, weather, Stage 0A boundaries/control, challenge and Pomodoro. Analyzer (`flutter analyze --no-pub`), scoped formatting (9 Dart files), secret scan and whitespace checks passed. Successful reset fixtures now explicitly mock secure storage and expect acknowledged empty local body records instead of missing keys. Full suite, builds, simulator, benchmark, hosted and physical-device checks were not run.
- **DATA-008 limitations:** restart protection requires the initial intent write to be acknowledged. If that write fails, clear reports incomplete, blocks use in the current instance and does not attempt secure deletion; it cannot promise persisted intent across restart. Acknowledgement/readback is not physical flash durability. Coordination assumes one repository-instance writer and the existing preference-object/isolate boundary, not cross-process transactions. Unsupported secure platforms conservatively remain incomplete. Logical deletion excludes backups, cloud copies, old snapshots and recommendation fingerprints. Broader reset orchestration remains DATA-005; sensitive-storage migration remains SEC-001; fingerprints remain SEC-003; backup policy remains PRIV-002. All five other Stage 1 findings remain OPEN.
- **DATA-007 historical H1 correction (superseded contract):** reproduced native `setString == false` with optimistic cached B while the native map retained A; the repository incorrectly returned success before correction. The coherent `HydrionLocalStore.writeString` contract retains `Future<void>`: completion means underlying acknowledgement; rejection/exception throws a payload-free `LocalStoreWriteFailure`. Existing implementations already use completion/exception semantics, so no signature migration or body-only persistence API is needed. SharedPreferences failures invalidate cache trust across adapters sharing the singleton; a subsequent read requires successful native reload. Body publication already catches write failures, remains unavailable, and reconciles recoverable secure B without advancing local authority on a rejected write. If both stores reject B, the save reports failure; no claim is made that rejected B survives restart.
- **DATA-007 historical H1 blast radius:** the previous global throw-on-native-false policy introduced Reminder/Locale control-flow regressions (H3/M1). That policy is superseded by the acknowledgement contract below, not accepted as caller recovery.
- **DATA-007 current acknowledgement contract:** `HydrionLocalStore.writeString` returns `Future<bool>` across memory, SharedPreferences and test implementations. Native false is reported without a new exception; native exceptions still propagate. Legacy callers may continue awaiting and ignoring the result, preserving pre-DATA-007 false-ack control flow. Only BodyMetrics explicitly requires true before readback/publication; false produces its existing typed local-write failure, does not advance authority, and retains recoverable secure/pending state. No Reminder, NotificationService, Locale, Weather, Challenge, DailyContext, PersonalizationState or HealthConnection production implementation is changed.
- **DATA-007 H4 correction:** one serialized operation queue and invalid-cache flag are shared through an Expando keyed by the SharedPreferences singleton. Adapter reads/reloads, writes and removals use the same queue; an older reload must finish before a newer write can acknowledge. Failed reload leaves trust invalid, failed writes invalidate it, and a failed operation does not poison later recovery. Clean acknowledged writes do not force reloads. Queue callbacks invoke only native preference operations, not queued adapter methods. Removal is ordered only; deletion acknowledgement policy remains DATA-008 work. Coordination covers adapters sharing the object in one isolate, not direct plugin access or cross-process writers.
- **DATA-007 H4/containment evidence (2026-09-28):** before correction, controlled one-/two-adapter stale-reload tests and Reminder/Locale false-ack tests failed (5 passed, 4 failed). After correction, 263 tests passed across 19 scoped files, including 11 real-adapter publication tests, body authority/recovery, async shell/coordinator H2 interleavings, secure body store, personalization, characterization, persistence, Locale, notification/reminder, HealthConnection, Weather, Stage 0A controls/boundaries, Challenge and Pomodoro. Reminder cancellation/replacement scheduling and Locale notification continue on native false without claiming persistence integrity. `flutter analyze --no-pub`, formatting verification of all 11 changed Dart files, secret scan and whitespace checks passed. Tracked benchmark and simulator-test fake signatures are mechanically updated; neither benchmark execution nor simulator certification is claimed. Full suite, builds, physical devices and hosted checks were not run.
- **DATA-007 deferred acknowledgement debt:** the 46 canonical findings contain no clear general coverage for legacy repositories ignoring native write acknowledgements. DATA-010 covers hydration list rollback/concurrency, not all caller transaction policies. A new candidate for broader local-persistence acknowledgement/rollback semantics should be reviewed after DATA-007 acceptance; no finding is added or reclassified here. H3/M1 induced exceptions are removed, but existing Reminder/Locale and other caller persistence-integrity debt is not repaired.
- **DATA-007 H2 correction:** reproduced the real coordinator await race with a completer-paused recommendation write, changed known body state to unavailable, and observed an escaping recommendation before correction. Calculation now checks after recommendation persistence and again at typed-result return; personalized-baseline application also checks after its settings await. Shell guards immediately before auto-apply and after the confirmation-dialog await reject unknown safety state without defaults. Fingerprints, weather calculation and Stage 4 commit architecture are unchanged.
- **DATA-007 H1/H2 validation (2026-09-27):** 220 tests passed in one scoped run across authority regressions, sensitive store, coordinator, characterization, personalization repository, storage recovery, personalized engine, remediation control, boundary architecture, health keys, local-store publication, async shell, persistence, weather/location, personalized UI, challenge activity lifecycle UI and Pomodoro service. Includes 5 real-adapter/native-channel H1 tests, 1 controlled coordinator interleaving, and 3 real shell cases (paused auto-apply, lost-safety confirmation, successful known-safety confirmation). Analyzer, six-file scoped formatting, secret scan and whitespace checks passed. No full-suite/build/physical/hosted claim; native acknowledgement is not a physical flash-durability guarantee. DATA-008, SEC-003, SEC-001 and Stage 4 remain OPEN.
- **DATA-007 implementation:** local `_bodyAuthority` version/revision/pending metadata and secure `_bodyRevision` order accepted updates independently of storage location. Save/update/reload are serialized within the repository instance. Failed secure writes/readback retain a full pending record; successful readback precedes stripping. Failed local publication blocks further edits until reload reconciles a possible secure commit. Store reads distinguish found/absent/unavailable/corrupt/unsupported; write diagnostics distinguish verified/writeFailed/verificationFailed/localWriteFailed without payloads. Unknown body state exposes no metrics, rather than trusted defaults.
- **DATA-007 legacy policy:** plaintext-only data migrates after confirmed secure absence, retains its original copy for that load, and converges on a subsequent verified load. Secure-only and equal valid copies load. Unequal unversioned copies remain ambiguous and preserved. Legacy null/default sentinels cannot prove whether an older strip or a newer intentional clear occurred, even with the old completed marker; those conflicting installations are deliberately blocked, not silently ranked. Corrupt local/secure fields do not become known defaults.
- **DATA-007 minimum consumers:** startup skips reproductive sanitation when unknown; coordinator returns an unavailable recommendation and blocks application; shell skips absent recommendations; body editor blocks full-record edits with existing Unavailable/Retry UI and retains initialized draft controls; challenge ranking is skipped without safety inputs; home pacing reads only non-sensitive wake/sleep fields. PersonalizedHydrationEngine is unchanged. All other body consumers were inspected; reset/deletion orchestration is unchanged.
- **DATA-007 evidence (2026-09-27):** 125 required focused tests passed across body authority (20), sensitive store (13), personalization repository (12), personalized engine (24), coordinator (9), characterization (6), remediation control (19), storage recovery (18), and health key store (4). Another 50 UI/challenge/pacing/boundary tests passed. Analyzer (`flutter analyze --no-pub`), scoped Dart formatting, secret scan and whitespace checks passed. The original three reproduction scenarios now pass without removing their requirements. Stage 0A DATA-007 characterization is converted to its corrected invariant; DATA-008 still demonstrates unsuccessful deletion restoring data. Initial validation exposed missing-plugin test assumptions and old corrupt-as-default expectations; fixtures now explicitly mock secure storage and require unknown/corrupt state instead.
- **DATA-007 limitations:** single repository-instance writer, not cross-process transactional persistence; local readback is not proof of physical disk durability. Pending fallback can still contain plaintext (SEC-001); fingerprints remain unchanged (SEC-003); deletion remains unverified (DATA-008). Ambiguous legacy conflicts require separately approved resolution UX; Retry never invents ordering. No full suite, build, physical-device or hosted validation is claimed; those remain separate evidence.
- **OBJECTIVE:** Finish classified local storage migration/degradation state; make reset resumable; decide Gemini credential model and backups. Disabling a distributed app-owned key or approved BYOK is not permission to build a backend/proxy.
- **BLOCKS:** connector projections, broader external providers, claims of complete local deletion.
- **BLOCKED BY:** Stage 0A; not Stage 0B.
- **CAN RUN IN PARALLEL WITH:** Stages 0B, 2 and 4, with agreed storage/target input contracts and shared-file ownership.
- **MUST NOT START UNTIL:** migration/recovery/rollback fixtures exist.
- **ENTRY CRITERIA:** scoped per-store classification and generation/failed-write/delete fixtures. Backup or credential decisions gate their own work items, not urgent secure-value/deletion corrections.
- **EXIT CRITERIA:** no hidden sensitive fingerprint copy or silent downgrade; latest saved values survive partial failures; deletion reports pending truthfully and does not resurrect data.
- **VALIDATION REQUIRED:** failure-at-every-storage-step/restart/migration/retention tests, platform keychain/keystore tests, credential binary scan. No health payload logging; physical backup remains separately gated.

**Internal priority (primary finding ownership remains in Stage 1):**

1. **HTD-DATA-007:** establish explicit secure-store outcomes and generation/authority semantics first; stale A versus newer fallback B and unavailable-versus-absent reads must not redefine saved clinical state (`body_metrics_repository.dart:175-249`).
2. **HTD-DATA-008:** use those outcomes for observable deletion completion and restart protection; the current swallowed native delete cannot be treated as successful (`sensitive_body_metrics_store.dart:100-119`).
3. **HTD-SEC-003:** remove/minimize plaintext fingerprint copies and migrate existing review history using the now-defined failure/deletion guarantees (`daily_hydration_recommendation_coordinator.dart:38-51`, personalization state persistence).
4. **HTD-SEC-001:** converge broader classified storage/degradation on the proven authority and cleanup protocol, rather than scaling up the existing fallback defect.
5. **HTD-DATA-005:** compose resumable profile reset from truthful per-store deletion outcomes; do not journal false success.
6. **HTD-PRIV-002:** validate per-platform backup/recovery/deletion policy against the resulting store inventory; policy research and fixture design may begin earlier.
7. **HTD-SEC-002:** resolve distributed Gemini credentials under a separate owner decision; do not couple this decision to urgent local data repair or authorize a backend implicitly.

The proposed order is retained: it follows storage authority -> deletion truth -> leaked-copy cleanup -> broader migration -> cross-store reset -> backup validation. Credential design is independent and last in default priority, not technically blocked by all six items. Earlier containment/research for fingerprints, backups or credentials may proceed after 0A if it does not overwrite data or bypass the accepted storage protocol; evidence of an actively exposed distributed key requires owner triage, not waiting for an ordinal slot. Initial data classification and synthetic failure fixtures precede the relevant change; completion of the entire broad SEC-001 migration is not a prerequisite for DATA-007.

### Stage 2 - Canonical time, day and interval semantics
- **Findings:** HTD-TIME-001, HTD-TIME-002, HTD-TIME-003, HTD-DATA-003.
- **OBJECTIVE:** Define clock/timezone/calendar-day contract and half-open intervals; migrate core totals then consumers.
- **BLOCKS:** accurate aggregation, streak/history, wearable-derived context and connector freshness.
- **BLOCKED BY:** Stage 0A; not Stage 0B or Stage 1.
- **CAN RUN IN PARALLEL WITH:** Stages 0B, 1 and 4 with agreed date-key interfaces.
- **MUST NOT START UNTIL:** DST, timezone-change and midnight fixtures are agreed.
- **ENTRY CRITERIA:** owner chooses event-zone versus current-zone historical grouping and travel behavior.
- **EXIT CRITERIA:** one interval/day policy, explicit challenge windows, consistent endpoint semantics.
- **VALIDATION REQUIRED:** midnight, DST both directions, UTC/local, travel, year/month boundaries and injected-clock parity.

### Stage 3 - Canonical intake command and event provenance
- **Findings:** HTD-INGEST-001, HTD-INGEST-002, HTD-DATA-002, HTD-DATA-010, HTD-DEAD-001.
- **OBJECTIVE:** Establish one ingestion command; migrate manual/widget/challenge/AI and edit/undo; serialize mutations, then deprecate misleading public writers.
- **BLOCKS:** reliable smart-bottle/wearable intake and cross-source replay.
- **BLOCKED BY:** Stage 2 interval semantics for event dates.
- **CAN RUN IN PARALLEL WITH:** Stages 1 and 4 implementation after Stage 2, with mutation/interface ownership agreed; 0B is independent.
- **MUST NOT START UNTIL:** event/provenance migration compatibility is specified.
- **ENTRY CRITERIA:** inventory includes edit/undo and every reachable intake caller; serialized-write contract approved.
- **EXIT CRITERIA:** canonical command validates/normalizes/identifies intake, concurrent failure cannot erase another committed event; dormant mutation APIs have an owner-approved disposition.
- **VALIDATION REQUIRED:** all-source replay/idempotency, rollback interleavings, edit/undo, store restart and legacy-event migration tests.

### Stage 4 - One target calculator and one automated commit policy
- **Findings:** HTD-ARCH-001, HTD-ORCH-001, HTD-ORCH-002, HTD-STATE-001, HTD-TEST-001.
- **OBJECTIVE:** Remove target computation from weather gate; make the existing coordinator enforce policy and route shell/accept through it; replace flag archaeology with explicit state.
- **BLOCKS:** trustworthy recommendations, target history, connector target resource.
- **BLOCKED BY:** Stage 0A; not completion of Stages 0B, 1, 2 or 3.
- **CAN RUN IN PARALLEL WITH:** Stages 0B, 1 and 2 immediately after 0A; Stage 3 once its calendar prerequisite closes.
- **MUST NOT START UNTIL:** clinician, restriction, temporary-condition, decline and manual-override invariants are executable.
- **ENTRY CRITERIA:** explicit manual/confirmed/automatic decision modes and current-policy validation contract, including degraded/unavailable sensitive inputs. Do not assume Stage 1 storage defects are fixed; isolate policy tests with explicit input states and coordinate interface changes.
- **EXIT CRITERIA:** one calculator and enforcing committer, no preview-as-authority path, explicit target state replaces contradictory flags.
- **VALIDATION REQUIRED:** caller/import guards, stale recommendation rejection, clinician/safety precedence, decline/restore, partial paired-write and lifecycle tests.

### Stage 5 - Target history and canonical daily/period facts
- **Findings:** HTD-DATA-001, HTD-DATA-004, HTD-DATA-009, HTD-ARCH-002, HTD-ARCH-003, HTD-ARCH-004, HTD-ARCH-008.
- **OBJECTIVE:** Persist target decisions; create canonical daily facts/period queries/streak; migrate analytics, reports, AI and achievements.
- **BLOCKS:** accurate public summaries and long-term analytics.
- **BLOCKED BY:** Stages 2, 3 and 4; intake provenance is required for historical attribution, alongside calendar and target convergence.
- **CAN RUN IN PARALLEL WITH:** Stage 6 projection contract design.
- **MUST NOT START UNTIL:** history migration and unknown-target behavior are defined.
- **ENTRY CRITERIA:** approved score/eco semantics and target provenance; ingestion provenance for any historical attribution.
- **EXIT CRITERIA:** daily/period facts, streak and historical target states have named owners; unknown history is not invented; score/eco are explained heuristics or removed by owner decision.
- **VALIDATION REQUIRED:** multi-target histories, all-consumer golden outputs, long streaks, period boundaries, mixed container evidence, split-entry score and PDF tests.

### Stage 6 - Projection convergence and freshness
- **Findings:** HTD-DATA-006, HTD-PRIV-001, HTD-ORCH-004.
- **OBJECTIVE:** Version minimized daily/AI/widget/watch projections with generated-at/data-through/day and stale semantics; retain and extend existing native safeguards.
- **BLOCKS:** connector-safe DTOs and honest offline UI.
- **BLOCKED BY:** Stages 1 and 5 (Stage 2 is transitive); safe disclosure/storage and canonical facts are both required.
- **CAN RUN IN PARALLEL WITH:** Stage 7 design/characterization, not its final freshness integration; Stage 0B remains independent.
- **MUST NOT START UNTIL:** canonical daily facts exist.
- **ENTRY CRITERIA:** minimized versioned read model, freshness/consent schema, platform atomic-publication strategy.
- **EXIT CRITERIA:** latest change is eventually published; Android/watch/iOS have truthful stale/day behavior; AI disclosure is purpose scoped.
- **VALIDATION REQUIRED:** busy-send interleavings, schema/age/timezone, killed-app/restart, projection payload allow-lists and consent withdrawal tests. Preserve existing WidgetKit stale checks.

### Stage 7 - Notification and lifecycle orchestration
- **Findings:** HTD-ORCH-003, HTD-STATE-002.
- **OBJECTIVE:** Define one lifecycle reconciliation boundary while retaining distinct scheduled/timed adapters; make last-known provider state explicit and supply actual user policy inputs.
- **BLOCKS:** reliable background behavior and diagnostics.
- **BLOCKED BY:** Stages 2 and 6 for complete implementation/acceptance; earlier design/characterization does not close this stage.
- **CAN RUN IN PARALLEL WITH:** Stage 8 health-context wiring.
- **MUST NOT START UNTIL:** notification/timer ownership is documented.
- **ENTRY CRITERIA:** event ordering and permission-observation age are explicit; scheduled and active delivery retain distinct roles.
- **EXIT CRITERIA:** repeated lifecycle events converge without duplicate schedules or dropped required refresh; no permission is treated as permanently granted.
- **VALIDATION REQUIRED:** restart/resume/reboot/timezone/cancel/revoke tests, stale OS observation, partial persistence and native delivery acceptance.

### Stage 8 - Health/wearable context integration and platform parity
- **Findings:** HTD-ARCH-007, HTD-DATA-011, HTD-PLATFORM-001, HTD-PLATFORM-002.
- **OBJECTIVE:** Feed consented, bounded extractor results into canonical daily context; make capability state provider-derived; certify supported platforms separately.
- **BLOCKS:** honest wearable-informed personalization and vendor expansion.
- **BLOCKED BY:** Stages 1, 2, 4 and 6; protected observation storage is required as well as safe calendar/target/projection boundaries.
- **CAN RUN IN PARALLEL WITH:** Stage 7.
- **MUST NOT START UNTIL:** source priority, freshness and deletion propagation invariants are accepted.
- **ENTRY CRITERIA:** owner-approved metric/temporal semantics, consent and supported-platform matrix; quantity allocation defined before activation.
- **EXIT CRITERIA:** bounded observation-to-context integration cannot bypass target policy; cross-day allocation and capability reporting are honest. Unimplemented Wear OS/OEM/bottle routes remain unavailable.
- **VALIDATION REQUIRED:** multi-source overlap/deletion/expired-cursor rebootstrap, cross-day energy/steps/distance, revocation/offline and per-platform provider tests; independent physical Android/iPhone/watch acceptance.

### Stage 9 - Boundary cleanup and resource architecture
- **Findings:** HTD-ARCH-005, HTD-ARCH-006, HTD-PERF-001, HTD-PERF-002, HTD-DEAD-002.
- **OBJECTIVE:** Narrow Provider/use-case exposure, fix dependency direction, migrate log storage if measurements justify it, split challenge responsibilities, classify/archive verified scaffolds.
- **BLOCKS:** cheap future feature development, but not emergency safety corrections.
- **BLOCKED BY:** Stages 3-8 so cleanup removes obsolete paths rather than moving them.
- **CAN RUN IN PARALLEL WITH:** final documentation and performance measurement.
- **MUST NOT START UNTIL:** callers have migrated and removal scans/tests pass.
- **ENTRY CRITERIA:** measured dataset workloads and lifecycle resource ownership inventory, owner decision on dormant assets/packs.
- **EXIT CRITERIA:** dependency directions guarded, bounded APIs exposed, indexed storage justified by evidence, service listeners/resources have explicit lifetimes.
- **VALIDATION REQUIRED:** import graph guards, disposal/reinitialization tests, large-history startup/write/report measurements, storage migration/recovery and full regression.

### Final Stage 10 - Resume Hydrion <-> Muse connector gates
- **OBJECTIVE:** expose only certified canonical read-only projections under the locked topology; no independent hydration calculator.
- **FINDINGS:** no additional defect assignment; depends on closure/evidence of all primary findings in stages 0A, 0B and 1-9.
- **Status:** **PAUSED UNTIL HYDRION FOUNDATION REMEDIATION COMPLETES.**
- **Preserve:** Gate 0 locked topology in `docs/architecture/HYDRION_CONNECTOR_ARCHITECTURE.md` and the historical PDF.
- **Classify current work:** Gate 0 architecture is closed; Gate 1 is **partial**, not complete (decline and clinician auto-apply improved; target ownership and sensitive storage remain incomplete); Gate 2+ is not implemented.
- **Work when unblocked:** Update Gate 1 evidence, then implement minimized canonical projections, freshness/error contracts, device signing, credential lifecycle, relay and conformance in the approved gate order.
- **BLOCKED BY:** Stages 0A, 0B and 1-9, plus explicit owner approval for backend/credential operations. Scoped earlier acceptance does not waive unresolved baseline or platform obligations here.
- **CAN RUN IN PARALLEL WITH:** none of the foundational stages.
- **MUST NOT START UNTIL:** one target authority, one daily fact/time policy, secure data classification, stale-aware projections and system invariants are verified.
- **BLOCKS:** all Muse-facing runtime, backend, credential issuance and deployment work.
- **ENTRY CRITERIA:** Gate 0 completed/locked; Gate 1 partially implemented but acceptance blocked until foundation evidence closes it; Gate 2+ not started. Explicit owner approval and verified Muse integration/Secure Vault capabilities are mandatory.
- **EXIT CRITERIA:** approved gate-specific conformance, revocation/deletion/freshness and threat-model acceptance; not inferred from a token or successful local query.
- **VALIDATION REQUIRED:** authenticated contract/isolation, stale/offline/conflict, signed projection, replay, consent/retention/revocation/deletion and operational-cost tests on approved infrastructure. Physical-device certification remains separate.

### Finding inventory and validation limits

**Finding count:** 46 total: 0 CRITICAL, 14 HIGH, 29 MEDIUM, 3 LOW.

| Category | Count |
|---|---:|
| Architecture (`HTD-ARCH`) | 8 |
| Data (`HTD-DATA`) | 11 |
| Security (`HTD-SEC`) | 3 |
| Privacy (`HTD-PRIV`) | 2 |
| Orchestration (`HTD-ORCH`) | 4 |
| Ingestion (`HTD-INGEST`) | 2 |
| State (`HTD-STATE`) | 2 |
| Time (`HTD-TIME`) | 3 |
| Test (`HTD-TEST`) | 2 |
| Performance (`HTD-PERF`) | 2 |
| Platform (`HTD-PLATFORM`) | 3 |
| Dead/transitional (`HTD-DEAD`) | 2 |
| Observability (`HTD-OBS`) | 1 |
| Documentation (`HTD-DOC`) | 1 |

The prefix counts sum to 46; the original 37 IDs remain stable, with nine added findings. HTD-DOC-001 is retained rather than renumbered into another category. Six root causes and 12 proposed stages cover all findings exactly once as primary assignments. The completion/impact matrices describe the original IDs; added findings contain those fields inline. Parent root-cause headings apply to every finding beneath them. This plan-control revision does not change finding severity, evidence or acceptance state.

**NOT FULLY VERIFIED:** exact semantic count of all challenge-specific aggregates/day policies/dedup variants; native physical file/backup copy counts; physical iOS/watchOS/Android/OEM background behavior; secure-store/backup hardware behavior; Web/desktop startup/runtime; full-suite hang cause; user-visible large-data performance; expired-cursor absent-record reconciliation; Muse's external integration/Secure Vault and any backend outside this repository. These are explicit evidence limits, not uninspected source subsystems or permission to claim unsupported capability. Static Web/secure interleaving findings are code-path evidence, not fabricated runtime reproductions.

**Audit self-check:** only this intended root HTD document was edited; runtime, tests, workflow and edge_case were preserved. No fixes, dependencies, builds, device actions, commits, pushes, backend work or connector implementation were started. No temporary diagnostic file was created during this audit. The known failed CI/format/literal/full-suite baseline remains visible. Completing this static audit does not certify the app or close physical-device acceptance criteria.
