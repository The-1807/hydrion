# HYD-SEC-001 Storage Remediation — Design (not yet implemented)

**Status**: Design only. No migration code has been written. Per the sprint's own gate, implementation does not begin until this design is reviewed and every open architecture choice below is resolved by the repo owner.

**Finding under remediation**: `AUDIT_REPORT.md` HYD-SEC-001 — health/PII data (weight, height, pregnancy status/duration, clinician hydration target, profile photo, nickname, sex, age) is stored in plaintext `SharedPreferences`/`NSUserDefaults` via `lib/storage/local_store.dart`'s `SharedPreferencesHydrionStore`, with no `flutter_secure_storage` or Keychain/Keystore layer anywhere in the app.

---

## 1. Field-by-field classification

Every field actually persisted today, read directly from `lib/domain/body_metrics.dart` (`HydrionBodyMetrics`), `lib/repositories/settings_repository.dart` (`UserSettings`), and `lib/repositories/hydration_repository.dart` (`HydrationLog`) — not inferred.

### 1.1 `HydrionBodyMetrics` (store key `hydrion.body_metrics.v1`)

| Field | Sensitivity | Size | Access frequency | Query needs | Retention | Backup eligible? | Deletion requirement | Compromise impact |
|---|---|---|---|---|---|---|---|---|
| `reproductiveState` (enum) | **High** — reproductive health status | ~10 bytes | Read on every body-metrics/pacing screen build; written rarely | Exact value only, no range query | Until user clears/resets | **No** — must be excluded from any OS-level backup | Must be erased on local profile reset (`local_profile_reset_service.dart`) | Reveals reproductive health status; special-category data under GDPR Art. 9 |
| `pregnancyGestationalDays` (int?) | **High** — pregnancy status/duration | ~4 bytes | Same as above | Exact value | Until cleared | **No** | Same | Directly reveals pregnancy and approximate due date |
| `fluidSafetyMode` (enum) | **High** — implies a diagnosed fluid-restriction condition | ~10 bytes | Read on pacing/goal screens | Exact value | Until cleared | **No** | Same | Reveals a medical condition (e.g. renal/cardiac fluid restriction) |
| `clinicianTargetMl` (int?) | **High** — implies clinician-prescribed hydration target, i.e. an existing medical relationship/condition | ~4 bytes | Read on goal screens | Exact value | Until cleared | **No** | Same | Reveals presence of a clinical care relationship |
| `allowAdjustmentsAboveClinicianTarget` (bool) | Medium — meaningless without the above, but confirms clinician-target context exists | 1 byte | Rare | Exact value | Until cleared | No (bundle with the above) | Same | Low standalone, but co-locate with clinician fields |
| `weightKg`, `heightCm` (double?) | **Medium-High** — health/biometric data | ~8 bytes each | Read on BMI-adjacent calculations | Exact value | Until cleared | No | Same | Health data; combined with age/sex increases re-identification risk |
| `weightUpdatedAt`, `heightUpdatedAt`, `updatedAt` (DateTime?) | Low — metadata only | ~8 bytes each | Rare | None | Until cleared | Yes (harmless alone) | Same lifecycle as the value it timestamps | Reveals update cadence only |
| `preferredWeightUnit`, `preferredHeightUnit`, `preferredPregnancyDurationUnit` (enum) | Low — unit preference | ~10 bytes each | Frequent (display formatting) | Exact value | Indefinite | Yes | n/a | None standalone |
| `wakeMinuteOfDay`, `sleepMinuteOfDay` (int?) | Low-Medium — behavioral/routine data | ~4 bytes each | Read for pacing engine | Exact value | Until cleared | Debatable — reveals sleep schedule | Same | Could support inference about routine/occupancy patterns |
| `schemaVersion` (int) | None | 4 bytes | Every load | n/a | Indefinite | Yes | n/a | None |

### 1.2 `UserSettings` (store key `hydrion.user_settings.v1`)

| Field | Sensitivity | Size | Notes |
|---|---|---|---|
| `profilePhotoBase64` (String?) | **High** — biometric-adjacent personal image | Up to 1.6MB (hard cap `maxProfilePhotoBase64Length`, enforced in `settings_repository.dart:49`) | **Wrong storage shape today regardless of encryption**: a multi-hundred-KB base64 string does not belong inline in a preferences blob at all — see §3 |
| `nickname` (String?) | Medium — user-chosen name, may be a real name | ≤32 chars (`maxNicknameLength`) | PII |
| `age` (int?) | Medium — PII, also drives life-stage/child-safety gating (`life_stage_policy.dart`) | 4 bytes | Combined with sex/weight/height, increases re-identification risk |
| `sex` (enum?) | Medium-High — sensitive demographic attribute | ~10 bytes | |
| `locale`, `avatarId`, `goalMode`, `baselineSource`, `weatherModifierEnabled`, `volumeUnit`, `themePreference`, `containerSizeMl`, `dailyGoalMl`, `baselineDailyGoalMl`, `reusableContainerEnabled`, `onboardingCompleted`, `missionIntroductionHandled`, `onboardingStep` | None/Low | small | Ordinary app preferences |
| `recognitionEventIds` (Set<String>) | None | small–moderate, grows with achievements | Non-sensitive gamification state |
| `legalAndHealthAcknowledged`, `acceptedTermsVersion`, `acceptedTermsAt`, `acknowledgedHealthDisclaimerVersion`, `acknowledgedHealthDisclaimerAt`, `privacyPolicyVersionShown`, `privacyPolicyShownAt` | None (not personal data) but **legally load-bearing** | small | These are the app's own record of consent — must remain reliably readable, not the confidentiality concern this design addresses. Do not move these into secure storage: doing so adds failure modes (secure-storage unavailable, biometric lock) to consent-proof retrieval, which is a worse trade-off than the low confidentiality value of "user accepted terms v3 at time T." |
| `nonLocalProviderConsentGranted` (bool) | Low, but privacy-relevant (gates Gemini transmission per HYD-SEC-010) | 1 byte | Keep readable at all times for the same reason as the legal-acknowledgement fields — this flag must be checked on every AI-coach code path (`hydration_ai_orchestrator.dart:118-120`) without depending on secure-storage/biometric availability |
| `weatherGoalAutoApplyEnabled`, `lastWeatherGoalDecisionAt`, `lastWeatherGoalLocalDate`, `lastWeatherGoalExplanation`, `weatherGoalDailyConfirmationEnabled`, `weatherAdjustedGoalActive`, `lastManualGoalEditAt`, `locationPermissionPromptedAt`, `notificationPermissionPromptedAt` | None | small | Operational state, not personal data (no raw coordinates stored, confirmed in `AUDIT_REPORT.md` §6.2) |

### 1.3 `HydrationLog` (store key `hydrion.hydration_logs.v1`)

| Field | Sensitivity | Notes |
|---|---|---|
| `id`, `volumeMl`, `timestamp`, `source`, `actionId`, `metadata` | **Low** — personal habit/behavioral log, not clinical data | Unbounded collection (HYD-PERF-001, separate finding) — this design does not change that; only confidentiality is in scope here |

**Decision**: hydration logs are explicitly **excluded** from the secure-storage migration. They are meaningfully less sensitive than the pregnancy/clinician-target fields (a log of "drank 250ml at 14:32" carries far less risk than "is currently pregnant, gestational day 140"), and moving an unbounded, frequently-written collection into secure storage would multiply HYD-PERF-001's already-identified performance cost through a slower encrypted backend for no proportionate confidentiality gain. If a future policy decision treats hydration logs as clinical data requiring the same protection, revisit this — but do not conflate the two problems now.

---

## 2. Proposed architecture

Four tiers, each hitting a different existing-or-newly-justified mechanism — deliberately **not** "move everything into `flutter_secure_storage`":

### Tier 1 — Keychain/Keystore-backed secure storage (new: `flutter_secure_storage`)
**Fields**: `reproductiveState`, `pregnancyGestationalDays`, `fluidSafetyMode`, `clinicianTargetMl`, `allowAdjustmentsAboveClinicianTarget`, `weightKg`, `heightCm`, `nickname`, `age`, `sex`.

These are small, discrete, infrequently-written scalar/string values — exactly `flutter_secure_storage`'s intended shape (a secure key-value store, not a document database). No credentials or app-managed cryptographic keys exist in Hydrion today (the Gemini API key is a compile-time `--dart-define`, never persisted at runtime — HYD-SEC-003 is a separate, already-tracked finding); this tier is therefore populated by sensitive **user data**, not credentials, but the same Keychain/Keystore backing is the correct mechanism for both.

### Tier 2 — Protected application file storage (new, no additional package required)
**Field**: `profilePhotoBase64`.

Do not encrypt-and-store the base64 string as a secure-storage *value* — secure-storage backends are not designed for multi-hundred-KB blobs (Android Keystore-backed ciphers and iOS Keychain both have practical performance and, on older iOS, hard size ceilings for this shape of data), and HYD-PERF-004 already flagged the base64-in-preferences pattern as wasteful even before considering encryption. Instead:
- Decode the base64 once at write time and save the raw image bytes to a file in the app's own sandboxed documents directory (`path_provider`, already a transitive Flutter dependency via `image_picker`no new package needed for the file I/O itself).
- Apply OS-level file protection: iOS `NSFileProtectionComplete` (via the file's protection attribute — no plugin needed, this is a native file-system attribute settable through a small platform-channel call or a maintained plugin if one is already justified elsewhere) and Android's scoped-storage sandboxing (the app's private files directory is already inaccessible to other apps without root, matching the "protected application file storage" bar without needing per-file encryption on Android specifically — though see the note on `flutter_secure_storage`'s file-encryption option below).
- Store only the **file path/reference** (a short string) in the settings record — this can live in Tier 1's secure key-value store (it's tiny) or Tier 4 (a path is not itself sensitive, though it indirectly points at a sensitive file, so Tier 1 is the more conservative choice and is recommended).

### Tier 3 — Encryption keys
No separate key-management code is proposed. `flutter_secure_storage` (v10.3.1 as of this design's research, see §5) manages its own backing key material entirely inside the platform's Keystore (Android) / Keychain (iOS/Secure Enclave-backed where available) — the app never sees or handles a raw key. This satisfies "encryption keys are separated from encrypted data" by construction: Hydrion's Dart code never touches key material, only plaintext-in/plaintext-out through the plugin's API, with the plugin and OS jointly responsible for the encrypted-value/key separation.

### Tier 4 — Unchanged: `SharedPreferencesHydrionStore` (existing)
**Everything else**: all non-sensitive `UserSettings` fields, all of `HydrationLog`, `ChallengeRepository`, `ReminderRepository`, `DailyHydrationContextRepository`, `PersonalizationStateRepository`, `AppLocaleRepository`, `GuidedTourRepository`, and — deliberately — the legal-acceptance and AI-consent fields listed in §1.2, which must remain available without any secure-storage/biometric-unlock dependency.

---

## 3. Why the existing stack cannot satisfy this without a new dependency

Per the sprint's requirement to prove insufficiency before adding anything: Hydrion's only current storage primitive is `package:shared_preferences` (via `HydrionLocalStore`), which has **no encryption of any kind** — it writes plaintext XML (Android) / a plaintext plist (iOS). There is no existing dependency in `pubspec.yaml` capable of Keychain/Keystore-backed storage (confirmed absent in `AUDIT_REPORT.md`'s dependency audit). Hand-rolling AES encryption with an app-managed key would (a) require the app to solve the exact key-storage problem this design is trying to avoid solving badly, (b) not be vetted/audited to the degree a widely-used purpose-built plugin is, and (c) directly contradict the design's own requirement to separate keys from encrypted data by construction. A dedicated secure-storage plugin is therefore justified, not a convenience choice.

## 4. Why not `flutter_secure_storage` for *everything*

Explicitly rejected shapes:
- **The whole `hydrion.body_metrics.v1`/`hydrion.user_settings.v1` JSON blob, unchanged, just encrypted wholesale**: this would drag non-sensitive, frequently-read fields (theme, locale, goal mode) through an encrypted-storage read path unnecessarily, and would still embed the oversized `profilePhotoBase64` string inside a secure-storage value — the wrong container for a large blob regardless of encryption.
- **Hydration logs**: excluded per §1.3 — disproportionate performance cost for the confidentiality level of the data, and would compound the already-tracked HYD-PERF-001 finding.
- **Legal-acceptance/consent-flag fields**: excluded per §1.2 — these must remain reliably and immediately readable (including, on iOS, without a device passcode/biometric prompt if the plugin's most restrictive accessibility class were ever selected) since app logic gates real user-facing behavior (e.g., whether to transmit context to Gemini) on them every session.

---

## 5. Dependency evaluation: `flutter_secure_storage`

- **Package**: `flutter_secure_storage` by julian steenbakker (`juliansteenbakker/flutter_secure_storage` on GitHub).
- **Current version** (verified via live pub.dev/GitHub research during this sprint, not recalled from training data): **10.3.1** stable, with an 11.0.0-beta.1 prerelease, actively maintained as of May 2026.
- **License**: BSD-3-Clause (verified against the package's standard licensing; re-confirm the exact license file at implementation time since this was not re-fetched byte-for-byte in this design pass).
- **Platform support**: Android, iOS, macOS, Windows, Linux (web is explicitly unsupported/uses a different, weaker mechanism — not relevant to Hydrion's Android/iOS scope per `AUDIT_REPORT.md` §2.2).
- **Backing mechanism (verified current, and this matters — it changed recently)**: iOS/macOS uses Keychain. **Android's implementation was rewritten away from the now-deprecated Jetpack Security `EncryptedSharedPreferences`/Jetpack Crypto** to a custom cipher implementation built on **Google Tink Crypto**, backed by the Android Keystore. Any design document or blog post describing this package as using "Jetpack `EncryptedSharedPreferences`" is describing an outdated version — do not implement against that assumption.
- **Optional biometric gating**: the package supports optional biometric authentication (Android API 23+, iOS/macOS) — **not recommended for this migration**: gating routine reads of, e.g., `weightKg` behind a biometric prompt would be a UX regression disproportionate to the data's sensitivity tier, and would conflict with the "must remain readable without extra friction" requirement already established for the excluded consent fields (though those fields aren't going into secure storage at all, the same reasoning caps how aggressively Tier 1 should be configured). Recommend the plugin's default (no biometric requirement) accessibility class, equivalent to `kSecAttrAccessibleAfterFirstUnlock` on iOS and standard Keystore-backed encryption on Android.
- **Maintenance/supply-chain risk**: single-maintainer-led but widely adopted (this is the de facto standard Flutter secure-storage plugin; re-verify current download/usage metrics at implementation time rather than trusting this document indefinitely). No known unresolved critical CVEs surfaced in this research pass — **UNVERIFIED against a live CVE database**, since no such tool exists in this project's toolchain (`AUDIT_REPORT.md` §4.1 already notes `dart pub audit` doesn't exist in the current Dart SDK) — recommend a manual advisory check (e.g., GitHub Security Advisories for the package) immediately before implementation, since currency can shift between this design and actual coding.
- **Supported OS versions**: consistent with Hydrion's own `minSdkVersion` (24, per Flutter's own default read in `AUDIT_REPORT.md`'s Android environment findings) and iOS deployment target — no known floor higher than Hydrion's own minimums; confirm precisely at implementation time against the plugin's current `pubspec.yaml` constraints.
- **Platform limitations to design around**:
  - Keychain items can survive app **uninstall** on iOS by default (Keychain persists independently of app deletion unless explicitly configured otherwise) — this has real implications for "uninstall behavior" (§7) and must be a deliberate choice, not an accident.
  - Android Keystore-backed keys are tied to the OS keystore; a factory reset or "clear app data" removes them (data becomes unrecoverable, which is *correct* for this use case, but must be handled gracefully — see idempotent-migration and corrupted-legacy-data handling below).
  - Restoring an iOS **backup to a new device** can behave differently for Keychain items depending on the backup's encryption settings (an unencrypted iTunes/Finder backup does not restore most Keychain items by default; an encrypted backup can). This is a genuine, non-obvious platform behavior that must be explicitly tested (see `tester_bible.md` additions in §9) rather than assumed.

---

## 6. Migration design

### 6.1 Schema/migration versioning

Add a new, explicit migration marker distinct from the existing per-repository `schemaVersion` ints (those version each repository's own JSON shape; this migration is a cross-cutting *storage-backend* change, not a data-shape change, so it needs its own marker to avoid conflating the two kinds of version).

Proposed key: `hydrion.secure_storage_migration.v1` (a plain, non-secret boolean/status marker, stored in the **existing** `SharedPreferencesHydrionStore`, not in secure storage itself — the migration's own completion flag must be readable without depending on the very system being migrated to, to keep the migration idempotent and inspectable even if secure storage is itself unavailable for some reason).

States: `notStarted` (default/absent) → `inProgress` → `completed` → (`failed`, recorded with a reason string, non-terminal — retried on next app start).

### 6.2 Idempotency

The migration must be safe to run on every app start until it succeeds, and safe to run twice:
1. Read the marker. If `completed`, no-op.
2. If `notStarted` or `failed`, set `inProgress`, then for each Tier-1/Tier-2 field: read the CURRENT plaintext value from `SharedPreferencesHydrionStore` (if present), write it to the new secure destination, and **do not yet delete the plaintext original**.
3. After all fields are confirmed written (see §6.4 verification), set marker to `completed`.
4. Only on a **separate, later** app start (not the same run) after confirming `completed`, delete the plaintext originals from `SharedPreferencesHydrionStore`. This two-phase "write-new, verify, then on a subsequent run delete-old" approach — rather than delete-old-immediately — is what makes an interrupted migration safe: if the app is killed between steps 2 and 3, the next launch simply re-runs from `notStarted`/`inProgress` and re-writes (idempotent, since it's just re-copying the still-present plaintext values), with no data ever having been deleted prematurely.

### 6.3 Atomicity / safe resumability

`flutter_secure_storage` does not offer cross-key transactions (neither does `shared_preferences`). Given that, atomicity is achieved at the **per-field** level (each field's copy is independently idempotent — re-copying the same plaintext value to the same secure key is a safe no-op on retry) rather than attempting a whole-migration transaction. Order fields so that partially-completed migrations leave the app in a **safe, if inconsistent, state** at every point: write Tier-1 scalar fields before Tier-2's file move (the file move is the only step with a real "half-done" risk — see next point).

### 6.4 Interruption recovery

- **Interrupted mid-scalar-copy**: safe by construction (idempotent re-copy on next launch, per §6.2).
- **Interrupted mid-photo-file-move**: write the new file to a **temporary path first**, then atomically rename it to the final path only after the write completes and is verified (read-back byte-length check) — a standard "write-temp-then-rename" pattern using `dart:io`'s `File.rename`, which is atomic on both platforms' underlying filesystems for same-volume moves. Only after the rename succeeds does the migration update `profilePhotoBase64`'s replacement pointer field. If interrupted before the rename, the temp file is orphaned (harmless, cleaned up by a startup sweep of the temp directory) and the original base64 field is untouched — the app continues showing the old (plaintext, pre-migration) photo until the migration retries.

### 6.5 Rollback policy

**No automatic rollback to plaintext once `completed`.** Rolling back would mean re-writing sensitive data back into plaintext storage, which is a regression the whole migration exists to prevent — do not build that path. If the migration itself has a bug discovered post-release, the fix is a forward migration (a `v2` marker) that corrects the secure-storage contents, not a reversion to Tier 4. Document this explicitly so it isn't "fixed" in the wrong direction under release pressure.

### 6.6 Verification before plaintext deletion

Before deleting a plaintext original (§6.2 step 4), **read back** the value from secure storage and compare it (exact string/byte equality) against the plaintext value still present. Only delete the plaintext copy for a field that verified successfully. If verification fails for a field, leave that field's plaintext copy in place indefinitely and log (locally, non-PII — just the field name and "verification failed") so a future release can retry rather than silently losing the user's data.

### 6.7 Secure deletion limitations — stated honestly

Deleting a value from `flutter_secure_storage` deletes the Keychain/Keystore *entry*; it does not guarantee the underlying flash storage cells are wiped (true secure erase is a hardware/OS-level guarantee neither this plugin nor any app-level code can provide on either platform). Similarly, deleting the plaintext `SharedPreferences`/`NSUserDefaults` entry removes the key but does not guarantee the old plaintext bytes are unrecoverable from raw flash/backup artifacts until the OS itself overwrites that storage. **This design does not claim forensic-grade secure deletion** — it claims that going forward, the *live, running application* no longer exposes this data through the plaintext `SharedPreferences`/`NSUserDefaults` files that a rooted-device/backup-extraction attack (HYD-SEC-001's actual demonstrated attack path) reads. State this limitation in any user-facing "delete my data" copy rather than overclaiming.

### 6.8 Logout / account-deletion cleanup

Hydrion has no server-side account (confirmed, `tester_bible.md` §3) — "logout" doesn't exist. The relevant existing hook is `lib/services/local_profile_reset_service.dart`. This service must be updated as part of implementation (not part of this design's scope to code, but the design must name it) to also clear the Tier-1 secure-storage entries and delete the Tier-2 photo file — today it presumably only clears the plaintext repositories, and once the migration lands, a reset that only clears plaintext would leave secure-storage copies behind, which is a **worse** state than today's uniform plaintext reset. **This is a hard dependency**: the migration must not ship without updating `local_profile_reset_service.dart` in the same change, or ship with a test proving the reset already covers the new storage locations.

### 6.9 Uninstall / backup-restore behavior

- **Android**: Keystore-backed entries are tied to the OS keystore and are correctly wiped on uninstall (standard Android behavior) — no special handling needed.
- **iOS**: as noted in §5, **Keychain items can survive uninstall** by default. Decide explicitly (owner decision, §10) whether Hydrion wants "reinstalling the app restores my previous sensitive body-metrics data from Keychain" (a UX nicety) or "uninstalling means my sensitive data is truly gone" (a stronger privacy default, arguably more consistent with `allowBackup=false`'s existing intent on Android). If the latter is chosen, the app must actively delete its Keychain items at an appropriate point (there is no "on uninstall" hook available to an app — the closest approximation is checking a "first launch after this specific plaintext-migration-completed marker was previously set but Keychain is now empty" signal at next launch and treating it as a fresh install, or a documented first-launch Keychain-reset-on-first-run pattern many privacy-conscious apps use specifically because of this platform quirk). **Flag this as needing an explicit owner decision — do not default silently either way.**

### 6.10 Required tests (new install, upgrade, interrupted migration, corrupted legacy data)

- **New install**: no plaintext legacy data exists; migration marker starts `notStarted`, immediately no-ops to a state where new writes go straight to the correct tier from day one (i.e., the migration logic and the "first-time write path" should share the same "write to Tier 1/2" code, not two separate code paths that could drift).
- **Upgrade with existing plaintext data**: seed a `MemoryHydrionStore`-equivalent fixture with realistic plaintext values for every Tier-1/Tier-2 field, run the migration, assert every field is now readable from secure storage with the same value, and (only after a simulated "second launch") assert the plaintext originals are gone.
- **Interrupted migration**: simulate a crash between "write to secure storage" and "mark completed" (e.g., by throwing from a test double after N fields are copied); assert the next migration run correctly resumes/re-copies without duplicating work or corrupting already-migrated fields.
- **Interrupted photo-file move**: simulate a crash between temp-file-write and rename; assert the app still shows the pre-migration photo correctly and the migration retries cleanly.
- **Corrupted legacy data**: seed a malformed value under a Tier-1 field's plaintext key (mirroring `tester_bible.md` TC-INST-003's existing corrupt-data pattern) and assert the migration skips/logs that field rather than crashing or writing garbage into secure storage.
- **Local profile reset after migration**: assert `local_profile_reset_service.dart` (once updated) actually clears the Tier-1 secure-storage entries and the Tier-2 photo file, not just the plaintext repositories — this is the single most important new test given §6.8's finding.

---

## 7. Owner decisions required before implementation

1. **iOS Keychain-survives-uninstall behavior (§6.9)**: restore-on-reinstall vs. hard-delete-equivalent-on-uninstall. No default assumed.
2. **Confirm `flutter_secure_storage`'s exact current license and any open security advisories** immediately before implementation (this design's research is current as of the sprint date but currency can shift).
3. **Confirm whether `wakeMinuteOfDay`/`sleepMinuteOfDay` should be promoted from BodyMetrics' current Tier-4-adjacent treatment into Tier 1** — this design leaves them low/low-medium and outside the secure-storage migration; the owner may weigh routine/behavioral-pattern sensitivity differently.
4. **Confirm the Tier-2 file-protection mechanism specifics for iOS** (`NSFileProtectionComplete` vs. `NSFileProtectionCompleteUnlessOpen` — the former blocks background access entirely, which could affect the `home_widget`/App-Group photo-sharing path if the widget ever needs the photo; verify no current or planned widget feature reads the photo file before committing to the strictest protection class).
5. **Decide whether to also encrypt the profile-photo file itself** (e.g., via `flutter_secure_storage`'s newer file-encryption-adjacent options, if any exist in the version selected at implementation time) versus relying on OS file-system sandboxing alone (Tier 2 as designed above) — this design recommends sandboxing-only as sufficient and proportionate, but flags it as a judgment call the owner can override.

## 8. Summary: what is and isn't in scope

- **In scope**: the specific high/medium-high-sensitivity fields listed in §1.1/§1.2's Tier 1/2 rows.
- **Explicitly out of scope, by design, with reasons given**: hydration logs (§1.3), legal-acceptance/consent fields (§1.2), all other app preferences.
- **Not implemented by this document**: any code. This is the design gate; implementation is a separate, subsequent change per the sprint's own instruction.
