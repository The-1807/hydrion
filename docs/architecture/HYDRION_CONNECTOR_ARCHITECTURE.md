# Hydrion Connector Architecture

## Document status

This document is the canonical, repository-grounded architecture record for
the Hydrion ↔ Muse connector. It supersedes `hydrion-connector-v1-proposal.pdf`
(root of this repository) as the source of truth for architecture decisions.

No editable source, generation script, or build pipeline for that PDF exists
anywhere in this repository (`scripts/`, `tool/`, `.github/workflows/`,
`codemagic.yaml` were checked; none reference it). The PDF is a standalone,
non-regenerable artifact, left in place unedited as historical review
material. It is not authoritative once this document exists.

**Gate 0 (architecture/topology lock) is CLOSED.** Every decision marked
**LOCKED** below has been explicitly approved. Items marked
**IMPLEMENTATION PREREQUISITE** are known, verified defects or gaps that
must be resolved — starting at Gate 1 — before the connector surface that
depends on them may ship. Items marked **DEFERRED / FUTURE** are
intentionally excluded from V1. **Gate 1 has not started.** No application
or runtime code has been modified to produce this document.

Basis: `hydrion-connector-v1-proposal.pdf` (24 Sep 2026 review draft); the
repository architecture audit; the verified target-derivation trace; the
target-ownership investigation; the final runtime-semantic verification; the
topology decision package; and the human approval with amendments that
closes Gate 0.

---

## 1. Purpose

Muse is a conversational, read-only consumer of hydration data Hydrion has
already computed. Hydrion remains the sole authoritative system for
hydration calculation. This document locks (a) the target-ownership
architecture inside Hydrion that the connector reads from, and (b) the
deployment topology by which Muse reaches that data at all — and corrects
proposal assumptions that repository evidence or the approved topology
package contradicted.

---

## 2. Locked architecture — target ownership (Gate 0a)

### 2.1 Hydrion authority — LOCKED

Hydrion remains the sole authoritative system for hydration targets,
hydration calculations, hydration state, hydration history, hydration
summaries, challenge/streak state, reminder state, reports, and every other
deterministic hydration-derived fact. Muse is a read-only consumer and
conversational layer. Muse must not become a second hydration engine.

### 2.2 Target calculation ownership — LOCKED

`PersonalizedHydrationEngine.calculate()`
(`lib/services/personalized_hydration_engine.dart:58-201`) is the canonical
target calculator and must become the **only** automated calculator of the
active hydration target. The independent weather-only calculator in
`DeterministicWeatherGoalService.recommend()`
(`lib/services/weather_goal_service.dart:514-593`) is not, and must not
remain, a second authority — its formula already substantially duplicates
`PersonalizedHydrationEngine._weatherAdjustment()`
(`personalized_hydration_engine.dart:254-296`). The current duplicate-
calculator arrangement is documented here as a **known defect** (§4), not as
intended architecture.

### 2.3 Target orchestration — LOCKED

`DailyHydrationRecommendationCoordinator`
(`lib/services/daily_hydration_recommendation_coordinator.dart`) is the
canonical orchestration layer for automated hydration recommendations. Its
responsibility is to gather canonical inputs from
`UserSettingsRepository`, `BodyMetricsRepository`,
`DailyHydrationContextRepository`, and weather; sanitize eligible inputs
(`HydrionBodyMetrics.sanitized(femaleProfile:)`,
`coordinator.dart:33-35`, `body_metrics.dart:246-282`); invoke
`PersonalizedHydrationEngine`; retain/review recommendation state via
`PersonalizationStateRepository`; and commit approved automated
recommendations.

### 2.4 Daily gating — LOCKED

The eligibility/dedup checks currently implemented in
`DailyWeatherGoalCoordinator.evaluate()`
(`weather_goal_service.dart:761-879`) — onboarding/legal readiness, profile
completeness, permission state, same-day manual-edit deference, already-
handled-today dedup — may remain conceptually as a pre-evaluation gate ahead
of the canonical calculator. This gate must not itself compute a target; it
decides only whether a recommendation cycle should run.

### 2.5 Automated commit ownership — LOCKED

There is one canonical automated-recommendation commit path:
`DailyHydrationRecommendationCoordinator.apply()`
(`daily_hydration_recommendation_coordinator.dart:76-86`), or a semantically
equivalent single safety-aware commit abstraction if later refactoring
demonstrates the naming needs improvement. All system-generated target
recommendations must flow through that policy. This method already has one
real, correctly-confirmed call site
(`lib/ui/screens/body_metrics_screen.dart:450`, gated by an explicit "Apply
suggested goal?" confirmation dialog, lines 429-447) — this is the pattern
every automated write should follow.

### 2.6 User-authoritative manual writes — LOCKED

Manual user goal edits remain legitimate and are architecturally distinct
from automated recommendations. Direct calls to
`UserSettingsRepository.setDailyGoalMl()`
(`lib/repositories/settings_repository.dart:763-792`) from onboarding,
settings, and profile screens are **user-authoritative manual writes**, not
a competing automated engine, and are unaffected by §2.2–§2.5.

### 2.7 Canonical active target — LOCKED

`UserSettings.dailyGoalMl`
(`lib/repositories/settings_repository.dart:54`) remains the canonical
settled/current active target read by all Hydrion consumers (confirmed
consumer: `lib/services/hydration_context_builder.dart:40,43,50`). A pending
`HydrationRecommendation` (`lib/domain/hydration_recommendation.dart:34-82`)
is not an active goal. Muse must never receive an unconfirmed recommendation
as though it were the user's current target (§9).

### 2.8 Weather role — LOCKED

Weather is context, not authority. Locked data flow:

```
WeatherSnapshot
    -> DailyHydrationRecommendationCoordinator
    -> PersonalizedHydrationEngine
    -> HydrationRecommendation
    -> confirmation / corrected auto-apply policy (§4)
    -> canonical commit (§2.5)
    -> UserSettings.dailyGoalMl
```

No standalone weather calculator may independently overwrite
`UserSettings.dailyGoalMl`.

### 2.9 Daily hydration context freshness (on-device) — LOCKED

`DailyHydrationContextRepository` (`lib/repositories/daily_hydration_context_repository.dart:39-40`)
is strictly date-keyed (`forDate(localDateKey)` returns `null`, never a prior
day's value, for a day with no saved context). A new day's calculation does
not and cannot reuse the prior day's activity or temporary-condition
context. This is distinct from connector *snapshot* freshness, covered in
§3.9.

### 2.10 Dedup / review state — current vs. target

Two mechanisms currently exist:

- `UserSettings.lastWeatherGoalLocalDate` (coarse, per-day, weather-workflow-specific).
- `PersonalizationStateRepository._reviewedRecommendationsByDate`
  (`lib/repositories/personalization_state_repository.dart:118-129`,
  per-day **and** per-input-fingerprint, richer).

These are **not currently unified**; the fingerprint-based mechanism is
under-wired today. The fingerprint-based mechanism is the **target**
canonical concept for eventual implementation. **This refactor is not yet
implemented.**

### 2.11 Weather metadata semantics

`UserSettings.weatherAdjustedGoalActive` currently means approximately "the
active goal was last committed through the weather workflow's accept
action," not "weather contributed a non-zero adjustment," and must not be
used as authoritative per-factor provenance. No schema/data migration is
required merely to lock this architecture. Eventual implementation should
rename, redefine, or retire this flag.

---

## 3. Locked architecture — connector topology (Gate 0b)

This section was previously recorded as **DECISION PENDING** throughout. It
is now **LOCKED** in full, per human approval of the topology decision
package with the amendments below.

### 3.1 Topology — LOCKED

```
Hydrion device
    | outbound publication only
    v
Hydrion-operated relay
    ^ Muse reads/polls
    |
Muse
```

- The Hydrion device **never** exposes an inbound network service, listening
  socket, or publicly reachable endpoint, on any platform, at any time.
- The relay **never** initiates a connection to the Hydrion device.
- Hydrion remains the sole hydration-computation authority. The relay may
  authenticate, store, route, and serve already-computed connector-safe
  snapshots. The relay may **not** calculate, modify, reinterpret, or feed
  hydration state back into Hydrion.

This resolves the reachability problem identified in the audit
(`ios/Runner/Info.plist` declares no `UIBackgroundModes`;
`AndroidManifest.xml` declares no foreground service; no backend of any kind
exists in this repository today) without requiring the Hydrion device to
become reachable from the internet.

### 3.2 Runtime ownership — LOCKED

| Component | Runs where |
|---|---|
| Hydrion Flutter application | User's phone (unchanged) |
| Connector publish component | New code inside the existing Hydrion app, following the existing outbound-adapter pattern already used by `lib/adapters/gemini/gemini_adapter.dart` — not a new process |
| Relay | New, small, Hydrion-operated backend service (does not exist today) |
| Muse client/connector | Outside this repository, outside Hydrion's control |

### 3.3 Publication model — LOCKED (event-triggered, not lifecycle-only)

Publication is **not** lifecycle-triggered-only. Approved behavior:

1. Hydrion commits authoritative state **locally first** — unchanged,
   existing repository write paths (§2) are not altered by the connector.
2. A relevant committed change to connector-exposed state should trigger an
   **opportunistic publish** of the affected sanitized resource snapshot.
   Potentially relevant committed changes include: hydration intake
   changes, settled target changes (post §2.5/§4 commit), reminder-state
   changes, report creation, and any other resource actually included in
   the approved V1 surface (§6 of the prior audit; resource map
   unchanged by this update).
3. Publishing is **asynchronous and non-blocking** relative to Hydrion's
   local functionality.
4. A failed publication **never** rolls back or blocks the local Hydrion
   operation that triggered it.
5. App start, resume, and other appropriate lifecycle events act as
   **reconciliation/retry opportunities** — a safety net, not the only
   trigger.
6. Implementations should debounce/coalesce rapid successive changes to the
   same resource where appropriate, to avoid redundant publishes.

This document does not prescribe specific implementation hooks (e.g. which
exact repository methods fire a publish) — that belongs to Gate 2/3
implementation design.

### 3.4 Connection direction — LOCKED

- Hydrion device → relay: **device-initiated only**, triggered by §3.3's
  event model (not solely by app-lifecycle events as an earlier draft of
  this document stated).
- Muse → relay: **Muse-initiated only**, standard client-server polling.
- Relay → Hydrion device: **never**, under any circumstance, in this
  architecture.

### 3.5 Relay retention — LOCKED, permanent principle

The relay stores:

- the **latest connector-safe snapshot per connection/resource only**,
- **no hydration history**.

A new publish **replaces** the previous snapshot for that resource. This is
a **permanent privacy principle**, not a V1-only optimization to be revisited
as a convenience later — the relay must not become a historical hydration
database at any future point without a separate, explicit architecture
decision.

Cached hydration snapshots are disposable data and should be excluded from
long-lived backup/archive systems wherever practical. If future
infrastructure causes deleted payloads to persist temporarily inside a
backup system, product and documentation wording must disclose a **bounded
backup expiry window**, not promise universal instantaneous deletion.

### 3.6 Credential model — LOCKED, two independent classes

| | Device publish credential | Muse read credential |
|---|---|---|
| Access | Write-only to that connection's allowed snapshot slots | Read-only to explicitly granted connector resources |
| Can read snapshots? | **No** | Yes, within granted scope |
| Can publish/modify snapshots? | Yes, within its own connection's slots | **No** |
| Where stored | Hydrion device, platform secure storage (existing pattern: `lib/services/health_database_key_store.dart:37-108`, Keychain/Keystore via `flutter_secure_storage`) | Muse's own secure storage |
| Ever shown to Muse? | **Never** | N/A — this is Muse's credential |
| Ever shown to the Hydrion user as a long-lived copy/paste secret? | No | **No** — delivered through the pairing transaction (§3.7), not manually copied |
| Rotation | Independent of the read credential | Independent of the publish credential |
| Revocation | Connection revocation invalidates both together (§3.10) | Same |

Splitting the credential prevents a leaked Muse-side credential from being
usable to forge or overwrite Hydrion-authoritative data at the relay,
independent of scope-check correctness.

### 3.7 Pairing — LOCKED, short-lived code exchange

V1 pairing capability is a **short-lived pairing-code exchange**, not a
long-lived copy-pasted secret. The pairing capability must be:

- short-lived (expires quickly),
- single-use,
- rate-limited,
- connection-specific,
- invalidated immediately after successful redemption.

A QR-code representation of the same pairing transaction may be supported as
an alternate presentation, not a different mechanism. **OAuth is not
introduced for V1** — this remains appropriate only for the current
single-Muse-integration product model; if the product later supports
multiple independent third-party integrators, this decision must be
revisited.

### 3.8 Confidentiality — LOCKED, corrected rationale

TLS is approved between Hydrion ↔ relay and Muse ↔ relay for V1.

**Corrected rationale** (an earlier draft of this document incorrectly
claimed the relay *technically must* read plaintext to enforce scopes or
compute ETags — an opaque relay design is in fact technically possible, and
that claim is withdrawn). The actual basis for this decision is:

- the V1 relay is explicitly **Hydrion-operated**,
- the relay sits inside Hydrion's confidentiality trust boundary by design,
- it stores only minimized, connector-safe projections (§3.5, §7 of the
  original resource-map work),
- application-layer end-to-end encryption between Hydrion and Muse would add
  real key-management and recovery complexity that is **not currently
  justified** given the above.

**If relay operation ever moves to an independent third party, this
confidentiality architecture must be re-evaluated and end-to-end encryption
reconsidered.** No custom cryptography is proposed anywhere in this
document.

### 3.9 Source authenticity / snapshot integrity — LOCKED requirement, mechanism deferred

Muse must have a trustworthy way to distinguish Hydrion-originated snapshots
from fabricated relay content. The required properties are:

- a snapshot can be verified as originating from the paired Hydrion
  installation,
- payload tampering is detectable,
- replay of an older, previously-valid snapshot is detectable or bounded
  using freshness/version semantics (§3.11).

A standard, device-held signing mechanism is an acceptable architectural
direction for satisfying this requirement. **No specific cryptographic
algorithm or library is locked by this document** — no existing repository
or security standard mandates one, and the exact mechanism belongs to the
security design/implementation gate (Gate 2/3), not this documentation
phase. No custom cryptography is to be designed.

### 3.10 Revocation — LOCKED, dual-sided

The earlier draft's implication that revocation could only happen from the
original Hydrion device is **rejected**. Approved V1 requirement: the
connection must be revocable from **either**:

- Hydrion's connected-services Settings UI, **or**
- the connected Muse-side connection-management UI.

Connection revocation must, from either side:

1. invalidate the Muse read credential,
2. invalidate the device publish credential,
3. prevent all future relay reads and publishes for that connection,
4. remove the active connector snapshot from relay storage (§3.5).

This does **not** mean Muse must delete information it already received
before revocation — that distinction (§2.13-equivalent rule, restated here)
is preserved explicitly: **revocation of access is not the same as deletion
of data already received.** No full Hydrion cloud-account/recovery system is
required merely to satisfy this dual-sided-revocation requirement.

### 3.11 Freshness — LOCKED, explicit publication semantics

Because Muse reads the relay rather than querying the device live, Muse is
always reading **latest published Hydrion state**, not necessarily
**current device state**. This distinction must be explicit in the API
contract and in any Muse-facing documentation.

Retained fields (unchanged from the original proposal):

- `generated_at` — when Hydrion formed the response/snapshot content.
- `data_through` — the newest hydration state included in that content.

**Added field**: `published_at` (or an equivalent transport/publication
timestamp) — when the relay received/stored this snapshot from the device,
distinct from `generated_at`. The architecture requires **deterministic
freshness semantics** so Muse never has to invent what counts as stale.
Muse must always be able to distinguish stale cached data from a freshly
published snapshot using these fields. No arbitrary staleness threshold is
locked by this document; resource-specific freshness limits may be defined
during contract design (Gate 2).

### 3.12 Local-first — LOCKED, refined operational definition

"Hydrion remains local-first" means, precisely:

1. Canonical hydration state remains on-device.
2. Hydration computation remains on-device.
3. Core Hydrion functionality does not depend on the relay — the app is
   fully functional with the connector entirely absent or disabled.
4. Relay publication is optional and one-way (device → relay only, §3.4).
5. The relay stores only minimized connector-safe projections (§3.5),
   never raw health data, full profile PII, or sensitive derivation
   factors.
6. The relay is never consulted by Hydrion to determine hydration
   behavior — Hydrion's own on-device logic never queries the relay to
   decide what it should do.
7. Disabling or removing the connector does not impair Hydrion's core
   local functionality in any way.

**Terminology correction**: the relay must not be described as
"transient" — it persistently stores a latest snapshot (§3.5). The accurate
term is a **bounded latest-snapshot remote cache**: bounded because it holds
only one snapshot per resource with no history, remote because it exists
outside the device, and a cache because it is disposable, replaceable,
non-authoritative data, not a database of record.

### 3.13 Public HTTPS — LOCKED, disambiguated

Exactly one component exposes public HTTPS: **the relay**. The Hydrion
mobile application itself exposes no public HTTP/HTTPS listener, on any
platform, at any time. Any prior or future wording implying "Hydrion exposes
a public HTTPS API" must be understood, and written, as referring
exclusively to the relay.

### 3.14 V1 infrastructure — LOCKED scope

V1 may require:

- a relay/API service,
- a latest-snapshot store (§3.5),
- a credential/connection-metadata store (§3.6) — **kept conceptually
  distinct from the snapshot store** even if co-located in the same
  physical database, so that backup/retention policy for credentials
  (durable until revoked) is never conflated with retention policy for
  hydration snapshots (disposable, latest-only, §3.5),
- basic per-credential rate limiting,
- an audit event log (create/rotate/revoke/failed-auth; metadata only, no
  payload content),
- basic health/operational metrics.

V1 does **not** require: a historical hydration database; a message queue;
APNs/FCM or any request-to-device push infrastructure; a persistent device
session; a multi-region system; an OAuth authorization server; or a general
Hydrion cloud backend. None of these are to be introduced under the banner
of this connector without a separate, explicit architecture decision.

### 3.15 Trust boundaries — LOCKED summary

- **Hydrion device/app**: full trust, full data, sole computation authority.
- **Relay**: bounded trust — authenticates, stores, and routes only
  already-minimized connector-safe snapshots; has no computation authority
  and cannot feed data back into Hydrion (§3.1). Compromise exposes the
  current latest snapshot per connection (bounded, no history, §3.5) and
  routing/credential-hash metadata; the two-credential split (§3.6) bounds
  a compromised Muse-side credential from being usable to forge published
  data.
- **Muse**: least trust — scope-limited read access only, revocable from
  either side (§3.10).

---

## 4. Implementation prerequisites (Gate 1 — not started)

These are verified, current defects, unrelated to and unaffected by the
Gate 0 topology decisions in §3. **None of these are fixed by this
documentation update.** No connector surface that depends on the affected
behavior may ship until the corresponding item is resolved and covered by a
regression test.

### 4.1 Decline-path correction — HIGH PRIORITY

`UserSettingsRepository.keepPreviousWeatherGoal()`
(`settings_repository.dart:940-954`) unconditionally sets
`dailyGoalMl = baselineDailyGoalMl`, which is not kept in sync with the
active target by any automated-write path. Both the "Keep standard goal"
and "Done" buttons in `hydrion_shell.dart:229-243` route to this reset
(`hydrion_shell.dart:256-259`), which can silently overwrite a
clinician-derived target, a previously-applied personalized recommendation,
or a reproductive/activity-adjusted target.

**Required invariant**: declining or dismissing a recommendation must not
modify the current active target. Decline must become a true no-op on
`dailyGoalMl`, matching the already-correct pattern in
`body_metrics_screen.dart:469-474`.

### 4.2 `mayAutoApply` clinician-target correction

`personalized_hydration_engine.dart:163-165,195` blocks
`fluidRestrictionWithoutTarget`, `unsure`, and any non-`none` temporary
condition, but does **not** block `clinicianTarget` mode. A clinician-target
user with no fluid-restriction flag and no temporary condition currently
receives `mayAutoApply == true`.

**Required policy**: `mayAutoApply` must be `false` whenever
`fluidSafetyMode == HydrionFluidSafetyMode.clinicianTarget`. Auto-apply
must require both user preference and Hydrion's domain safety policy to
allow it; domain safety wins.

### 4.3 Target-ownership unification (implementation of §2.2–§2.5)

`weather_goal_service.dart`'s auto-apply branch (`evaluate()`, lines
858-871) must be changed to compute through
`DailyHydrationRecommendationCoordinator` + `PersonalizedHydrationEngine`
instead of `DeterministicWeatherGoalService`, gated on the corrected
`mayAutoApply` (§4.2).

### 4.4 Local-storage security remediation (HYD-SEC-001)

Sensitive body-metric, clinician, and reproductive values
(`HydrionBodyMetrics.weightKg`, `.heightCm`, `.reproductiveState`,
`.pregnancyGestationalDays`, `.clinicianTargetMl`, `.fluidSafetyMode`) are
currently persisted in **plaintext** via `BodyMetricsRepository` →
`HydrionLocalStore` (`body_metrics_repository.dart:134-135`,
`local_store.dart:11-35`) — distinct from, and not resolved by, the
SQLCipher-backed `EncryptedHealthDataRepository`, which covers only imported
wearable/HealthKit/Health-Connect fitness records.
`REMEDIATION_LEDGER.md:8` records this (HYD-SEC-001) as still open.

**This remediation must be completed before any connector functionality
that derives from `HydrationRecommendation` (i.e. `/v1/hydration/target`)
is exposed.**

### 4.5 Snapshot signing mechanism (implementation of §3.9)

Selecting and implementing the specific device-held signing mechanism that
satisfies §3.9's source-authenticity/integrity requirement is a Gate
2/3 security-design task, not yet started.

---

## 5. Deferred / future

Excluded from V1 because no repository-backed implementation exists, per
the connector proposal review:

- **`score{value, scale_min, scale_max, label, model_version}`** on
  `/v1/hydration/today` — no such object exists anywhere in the domain
  model traced.
- **`chosen_goal`** on `/v1/hydration/target` — no clean domain analogue
  found.
- **General free-text `explanation`** and `/v1/hydration/summaries`'s
  `assessment` — no deterministic prose generator exists outside the
  narrow, fixed-enum-name `lastWeatherGoalExplanation` field.
- **`/v1/insights`** — no persisted, ID'd, kind/severity-tagged insight
  feed exists. The nearest analog is ephemeral, conversational, and gated
  by the consent-gated `HydrationCoach`/`HydrationAiProvider` pipeline.
  **Connector polling must never silently invoke that pipeline.**
  Deterministic, Hydrion-authored structured summaries may be exposed;
  AI-generated assessment prose must not be generated implicitly by a
  connector poll.
- **`/v1/hydration/summaries`'s `trend{comparison_period, ...}`** — no
  period-over-period diffing logic exists.
- **Rich `/v1/reminders` fields** (`timezone`, `quiet_hours`,
  `next_scheduled_at`) — no backing in `ScheduledReminder`.
- **Public numeric streak contract** — current streak logic is a private,
  30-day-capped helper built for a boolean achievement check, not a
  documented public contract.
- **Log-level hydration history** — out of scope per the original
  proposal's own privacy boundary.
- **Push-notification-triggered device wake (APNs/FCM)** — explicitly not
  V1 infrastructure (§3.14); a later-scale latency improvement only.
- **OAuth authorization server** — not justified for a single first-party
  Muse integration (§3.7); revisit only if the product model changes.
- **End-to-end encryption between Hydrion and Muse** — not justified while
  the relay is Hydrion-operated (§3.8); reconsider if relay operation ever
  moves to an independent third party.
- **Historical hydration database at the relay** — explicitly and
  permanently excluded (§3.5), not merely deferred.

---

## 6. V1 resource map

| Endpoint | Classification | Repository-backed source | Notes |
|---|---|---|---|
| `GET /v1/capabilities` | **READY** | Static/derivable from this document's locked scope | No domain dependency |
| `GET /v1/hydration/today` | **READY WITH SAFE PROJECTION** | `hydration_context_builder.dart:40`, `hydration_repository.dart:343-350` | `score{}` deferred (§5); `state` needs a lossy mapping from `HydrationPacingState` |
| `GET /v1/hydration/target` | **REQUIRES DOMAIN REFACTOR** | `PersonalizedHydrationEngine`/`HydrationRecommendation`, blocked on Gate 1 (§4) | `chosen_goal` and free-text `explanation` deferred (§5); `adjustments[]` requires the sensitive-factor allow-list in §7 |
| `GET /v1/hydration/days` | **READY WITH SAFE PROJECTION** | `lib/domain/hydration_report.dart:63-72` | Needs a thin DTO/pagination layer only |
| `GET /v1/hydration/summaries` | **READY WITH SAFE PROJECTION** | `HydrationReport` aggregate fields | `trend`/`assessment` deferred (§5) |
| `GET /v1/challenges/active` | **REQUIRES DOMAIN REFACTOR** | `ChallengeRepository` | Challenge list ready; streak needs the refactor in §5 |
| `GET /v1/reminders` | **REQUIRES DOMAIN REFACTOR** | `ScheduledReminder` | Reduce to repository-backed fields only (§5) |
| `GET /v1/insights` | **DEFERRED** | No backing subsystem exists (§5) | |
| `GET /v1/reports` | **READY WITH SAFE PROJECTION** | `HydrationReport` domain object (pre-PDF-rendering), never `HydrationReportPdfRenderer` | `sections`/narrative text deferred (§5) |

---

## 7. Sensitive derivation data — connector-safe projection

The connector must never directly serialize raw `HydrationFactorCode`
values (`lib/domain/hydration_recommendation.dart:13-32`). Confirmed
sensitive members: `reproductivePregnant`, `reproductiveLactating`,
`clinicianTarget`, `illnessGuidance`, `fluidRestriction` — these are the
literal enum values the engine emits into `appliedFactors`/`safetyNotices`
on a normal run.

**Required design**: an explicit allow-list mapping, not a pass-through.
Potentially public-safe concepts: `personalized_baseline`, `activity`,
`weather`, `manual_adjustment`. Sensitive factors must be omitted,
generalized, or gated behind a separate, explicitly-consented scope not
part of the V1 scope vocabulary. If omission would make the arithmetic
misleading, document a generic `protected_adjustment` concept (amount
shown, cause never named). No such allow-list exists today — new work,
required before `adjustments[]` can exist in the public API at all.

This projection gap is independent of, and in addition to, the storage
remediation in §4.4 — both must be resolved before `/v1/hydration/target`
ships.

---

## 8. Caching / conditional requests (V1 design)

Conditional polling (`ETag`/`304`) is retained from the original proposal,
with these corrections:

- ETags must be opaque and must not embed user identifiers or any
  reconstructible information in the validator string.
- `Cache-Control: private` alone is not a complete privacy policy — relay-
  side retention duration is governed by §3.5 (latest-only, no history),
  not by cache-control headers.
- Freshness must use the three timestamps in §3.11
  (`generated_at`/`data_through`/`published_at`), not inferred staleness.

---

## 9. Implementation gates

**Gate 0 — Architecture/topology lock and threat model. CLOSED.**
The target-ownership architecture (§2) and the connector topology (§3) are
both locked. The threat model produced during the topology decision package
is recorded as part of the approved package; a living threat-model document
may be split out separately during Gate 2/3 implementation.

**Gate 1 — Pre-connector Hydrion safety remediation. NOT STARTED.**
Requires, all verified and none yet fixed: §4.1–§4.5.

**Gate 2 — Canonical connector-safe projections and primitives. NOT STARTED.**
Units, dates/timezones, freshness fields (§3.11), public enums, the
sanitized target projection (§7), error envelope, pagination. Gated behind
Gate 1.

**Gate 3 — Credential lifecycle, pairing, and relay stand-up. NOT STARTED.**
Per §3.6/§3.7/§3.14. No relay, credential store, or pairing capability
exists anywhere in this repository today.

**Gate 4 — Smallest useful connector slice. NOT STARTED.**
`/v1/capabilities`, `/v1/hydration/today`. `/v1/hydration/target` is
explicitly excluded until Gate 1 closes (§6).

**Gate 5 — History/summaries. NOT STARTED.**
`/v1/hydration/days`, `/v1/hydration/summaries` (numeric fields only).

**Gate 6 — Other repository-ready authored resources. NOT STARTED.**
`/v1/challenges/active` (pending streak refactor), `/v1/reminders`
(reduced scope), `/v1/reports` (structured serialization).

**Gate 7 — Conformance/security/privacy testing. NOT STARTED.**
Scope enforcement, revocation semantics (§3.10), empty states, time-zone
boundaries, partial periods, stale-data behavior, and explicit verification
that no `HydrationFactorCode` value ever appears in a response body (§7).

**Gate 8 — Muse integration acceptance. NOT STARTED.**
Behavioral-contract sign-off per §2.12-equivalent rule (API security vs.
Muse behavioral contract, restated: if the API returns both `consumed_ml`
and `target_ml`, Hydrion cannot technically prevent Muse from computing a
percentage itself — "Muse must not independently derive authoritative
Hydrion assessments" is a behavioral contract requirement, not a
cryptographic guarantee. The API's job is to minimize what data leaves
Hydrion, not to police client-side arithmetic).

No gate before Gate 1 may be skipped by starting Gate 2+ work early; Gate 1
items are correctness/safety fixes to the app itself, independent of
whether the connector ships at all.

---

## 10. Change log

- **This revision**: closed Gate 0 by locking the connector topology (§3)
  per the approved topology decision package and its amendments. Corrected
  the confidentiality rationale (§3.8 — withdrew the earlier claim that the
  relay technically must read plaintext). Added the source-authenticity/
  snapshot-integrity requirement (§3.9, mechanism deferred to Gate 2/3).
  Replaced device-only revocation with dual-sided revocation (§3.10).
  Added `published_at` and explicit freshness semantics (§3.11). Corrected
  "transient" relay language to "bounded latest-snapshot remote cache"
  (§3.12). Disambiguated public HTTPS to the relay only (§3.13). Locked the
  two-credential-class model (§3.6) and short-lived pairing-code exchange
  (§3.7), replacing the original single-bearer-key copy/paste flow.
- **Prior revision**: initial creation from the repository architecture
  audit, target-derivation trace, target-ownership investigation, and
  runtime-semantic verification; removed/deferred proposal fields with no
  repository backing (`score{}`, `chosen_goal`, free-text `explanation`,
  `/v1/insights`, `trend{}`, rich reminder fields, public streak contract);
  established the target-ownership architecture (§2) and implementation
  prerequisites (§4).
