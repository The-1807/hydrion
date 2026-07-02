# Hydrion User Stories

Hydrion is a standalone-first Flutter hydration companion. The current product centers on local hydration tracking, local persistence, daily progress, history maintenance, analytics, local reminders, local challenges, multilingual UI, and a deterministic coach that can fall back safely when optional providers are unavailable.

The backlog below is the authoritative source for GitHub issues `HYD-US-001` through `HYD-US-051`. Product Backlog items are valuable near-term work for the MVP or release hardening. Ice Box items are deferred integrations, speculative bundles, or work that must be decomposed before sprint planning.

## User Stories

### HYD-US-001: Launch Standalone Local Application

**Story ID:** HYD-US-001  
**Title:** Launch Standalone Local Application  
**Epic:** Onboarding and Application Access  
**Story Type:** User Story  
**Priority:** P0  
**Release Scope:** MVP  
**T-shirt Size:** S  
**Project Column:** Product Backlog  
**Business Rank:** 006  
**Labels:** `user-story`, `type:user-story`, `epic:onboarding-access`, `priority:p0`, `scope:mvp`, `size:s`, `status:product-backlog`  
**Milestone:** MVP Stabilization

## User Story

**As a** first-time Hydrion user  
**I need** the app to open directly in local mode without account, network, or provider setup  
**So that** I can begin tracking hydration immediately.

## Business Value

Fast standalone launch is the entry point for every other MVP behavior. If boot depends on optional providers, accounts, permissions, or network availability, the product loses its local-first promise before the user can log water.

## Acceptance Criteria

- [ ] When Hydrion starts with no provider configuration, the Home screen loads and exposes local hydration logging controls.
- [ ] When the device is offline, startup still reaches the main app shell without an account prompt.
- [ ] When optional Gemini, ELKA, BLE, Health, AR, voice, or notification adapters are unavailable, the user can still access local hydration features.
- [ ] When startup fails to load optional capability details, the app reports local mode instead of blocking the Home screen.
- [ ] When the app is launched from a fresh install, no production secret or provider token is required.

## Out of Scope

Account creation, cloud onboarding, medical-profile setup, and guided first-run personalization are separate work.

### HYD-US-002: Access Core Product Screens

**Story ID:** HYD-US-002  
**Title:** Access Core Product Screens  
**Epic:** Onboarding and Application Access  
**Story Type:** User Story  
**Priority:** P1  
**Release Scope:** MVP  
**T-shirt Size:** S  
**Project Column:** Product Backlog  
**Business Rank:** 019  
**Labels:** `user-story`, `type:user-story`, `epic:onboarding-access`, `priority:p1`, `scope:mvp`, `size:s`, `status:product-backlog`  
**Milestone:** MVP Product UX

## User Story

**As a** Hydrion user  
**I need** clear navigation to the product's core screens  
**So that** I can move between logging, history, analytics, coach, reminders, challenges, and settings without hunting.

## Business Value

The app only feels usable when its current local features are reachable from the first screen. Clear navigation also helps future gated features remain discoverable without pretending they are active.

## Acceptance Criteria

- [ ] The Home screen exposes navigation to analytics, hydration history, coach, challenges, reminders, settings, and AR status.
- [ ] Each route opens the expected screen without resetting local app state.
- [ ] Disabled or unavailable feature routes identify their current status instead of failing silently.
- [ ] Returning from a secondary screen preserves the selected hydration amount and current local data.
- [ ] Navigation controls remain reachable on narrow mobile-width screens.

## Platform Considerations

The navigation must be usable on Flutter web and Android, which are the documented MVP build targets.

### HYD-US-003: Log Hydration Manually

**Story ID:** HYD-US-003  
**Title:** Log Hydration Manually  
**Epic:** Hydration Logging  
**Story Type:** User Story  
**Priority:** P0  
**Release Scope:** MVP  
**T-shirt Size:** M  
**Project Column:** Product Backlog  
**Business Rank:** 008  
**Labels:** `user-story`, `type:user-story`, `epic:hydration-logging`, `priority:p0`, `scope:mvp`, `size:m`, `status:product-backlog`  
**Milestone:** MVP Stabilization

## User Story

**As a** Hydrion user  
**I need** to record a water intake amount from the Home screen  
**So that** my daily progress reflects what I actually drank.

## Business Value

Manual logging is Hydrion's core loop. It must be quick, constrained to valid amounts, and immediately reflected across local summaries so the rest of the product has trustworthy data.

## Business Rules

- Preset intake options should cover common drink sizes without requiring typing for the MVP flow.
- Accepted records use a positive milliliter amount, a timestamp, and a source that identifies the entry as local.

## Acceptance Criteria

- [ ] When the user selects a preset amount and taps the log action, Hydrion creates one local hydration record for that amount.
- [ ] When the user changes the selected amount before logging, the button label and saved record use the new amount.
- [ ] When a record is saved, the Home progress, history, analytics, coach context, and eco estimate can read the same entry.
- [ ] When the user attempts to log a zero or negative amount through repository or provider paths, Hydrion rejects the entry and leaves history unchanged.
- [ ] When logging succeeds, the user receives confirmation that names the saved amount.
- [ ] When logging is repeated, each accepted entry has its own timestamped identity.

## Validation Notes

Exercise both widget-level logging from Home and repository-level validation for invalid amounts.

### HYD-US-004: Persist Hydration Logs Locally

**Story ID:** HYD-US-004  
**Title:** Persist Hydration Logs Locally  
**Epic:** Local Persistence  
**Story Type:** Technical Story  
**Priority:** P0  
**Release Scope:** MVP  
**T-shirt Size:** M  
**Project Column:** Product Backlog  
**Business Rank:** 007  
**Labels:** `user-story`, `type:technical-story`, `epic:local-persistence`, `priority:p0`, `scope:mvp`, `size:m`, `status:product-backlog`  
**Milestone:** MVP Stabilization

## User Story

**As a** returning Hydrion user  
**I need** hydration logs to survive app restarts and reloads on the same device  
**So that** my history and summaries are not lost between sessions.

## Business Value

Local persistence is the data foundation for progress, trends, reminders, coach context, challenges, and user trust. Losing entries would make the MVP unreliable even if logging itself works.

## Data and State Requirements

Hydration records must preserve ID, volume in milliliters, timestamp, and source. Invalid stored entries must not prevent valid entries from loading.

## Acceptance Criteria

- [ ] When a valid hydration record is saved, a later repository reload returns the record with the same volume, timestamp, ID, and source.
- [ ] When multiple records exist, the loaded history is ordered from newest to oldest.
- [ ] When persisted data contains malformed JSON, Hydrion starts with an empty hydration history instead of crashing.
- [ ] When persisted data contains a mix of valid and invalid records, valid records remain available and invalid records are ignored.
- [ ] When local hydration records are cleared, the persisted storage key is removed and dependent summaries return zero values.
- [ ] When web or Android builds run without cloud sync, local persistence remains the source of truth.

## Dependencies

This story supports manual logging, history, analytics, challenge progress, coach context, and privacy controls.

### HYD-US-005: View Recent Hydration History

**Story ID:** HYD-US-005  
**Title:** View Recent Hydration History  
**Epic:** Hydration History  
**Story Type:** User Story  
**Priority:** P0  
**Release Scope:** MVP  
**T-shirt Size:** S  
**Project Column:** Product Backlog  
**Business Rank:** 009  
**Labels:** `user-story`, `type:user-story`, `epic:hydration-history`, `priority:p0`, `scope:mvp`, `size:s`, `status:product-backlog`  
**Milestone:** MVP Product UX

## User Story

**As a** Hydrion user  
**I need** to view my recent hydration records  
**So that** I can confirm what Hydrion has counted for my day.

## Business Value

Visible history gives users confidence in the numbers shown elsewhere. It also creates the entry point for correcting or removing bad records.

## Acceptance Criteria

- [ ] When the user opens the Log screen with recent entries, Hydrion lists records from the last seven days.
- [ ] Each visible record shows its amount, timestamp, and source label.
- [ ] When no recent records exist, the screen displays an empty state that explains there are no hydration logs.
- [ ] When a new Home entry is saved, the Log screen can display it without requiring app restart.
- [ ] History rows expose edit and delete controls for records that can be changed locally.

### HYD-US-006: Edit Hydration Records

**Story ID:** HYD-US-006  
**Title:** Edit Hydration Records  
**Epic:** Hydration History  
**Story Type:** User Story  
**Priority:** P1  
**Release Scope:** MVP  
**T-shirt Size:** M  
**Project Column:** Product Backlog  
**Business Rank:** 010  
**Labels:** `user-story`, `type:user-story`, `epic:hydration-history`, `priority:p1`, `scope:mvp`, `size:m`, `status:product-backlog`  
**Milestone:** MVP Product UX

## User Story

**As a** Hydrion user  
**I need** to correct the amount on a saved hydration record  
**So that** mistakes do not distort my progress or analytics.

## Business Value

Editing reduces data-quality risk without forcing users to delete and recreate records. It protects daily summaries, streaks, badges, challenge progress, and coach context from accidental input errors.

## Acceptance Criteria

- [ ] When the user chooses edit on a history row, Hydrion opens a focused amount editor prefilled with the current value.
- [ ] When the user saves a positive replacement amount, the existing record keeps its identity and updates to the new amount.
- [ ] When the user enters nonnumeric, zero, or negative text, Hydrion does not update the record.
- [ ] When the user enters an amount above the supported maximum, Hydrion clamps or rejects it according to the agreed rule and avoids corrupting history.
- [ ] When a record is edited, daily progress, analytics, challenge progress, and coach context reflect the changed amount.
- [ ] When the target record no longer exists, Hydrion reports that the log was not found.

## Edge Cases

Editing must not create duplicate records, alter unrelated timestamps, or break newest-first ordering.

### HYD-US-007: Delete Hydration Records

**Story ID:** HYD-US-007  
**Title:** Delete Hydration Records  
**Epic:** Hydration History  
**Story Type:** User Story  
**Priority:** P1  
**Release Scope:** MVP  
**T-shirt Size:** S  
**Project Column:** Product Backlog  
**Business Rank:** 011  
**Labels:** `user-story`, `type:user-story`, `epic:hydration-history`, `priority:p1`, `scope:mvp`, `size:s`, `status:product-backlog`  
**Milestone:** MVP Product UX

## User Story

**As a** Hydrion user  
**I need** to remove an incorrect hydration record  
**So that** my local history and progress stay accurate.

## Business Value

Deletion is the simplest correction path for accidental logs. It is also a data-integrity requirement before Hydrion can credibly summarize or coach from saved records.

## Acceptance Criteria

- [ ] When the user deletes an existing history record, Hydrion removes exactly that record from local storage.
- [ ] When deletion succeeds, the Log screen no longer displays the removed record.
- [ ] When the removed record contributed to today's total, Home progress and analytics decrease accordingly.
- [ ] When the target record cannot be found, Hydrion reports that the log was not found and preserves existing records.
- [ ] When all recent records are deleted, the Log screen returns to its empty state.

### HYD-US-008: View Daily Summary and Progress Ring

**Story ID:** HYD-US-008  
**Title:** View Daily Summary and Progress Ring  
**Epic:** Daily Progress  
**Story Type:** User Story  
**Priority:** P0  
**Release Scope:** MVP  
**T-shirt Size:** M  
**Project Column:** Product Backlog  
**Business Rank:** 013  
**Labels:** `user-story`, `type:user-story`, `epic:daily-progress`, `priority:p0`, `scope:mvp`, `size:m`, `status:product-backlog`  
**Milestone:** MVP Product UX

## User Story

**As a** Hydrion user  
**I need** a clear daily progress summary on the Home screen  
**So that** I know how close I am to my hydration target.

## Business Value

The progress ring turns raw logs into an understandable status. It guides the next action, reinforces logging, and provides context for reminders and coaching.

## Data and State Requirements

The current MVP uses a 2200 ml daily target until configurable goals are delivered.

## Acceptance Criteria

- [ ] When no water has been logged today, the progress ring shows zero consumed milliliters against the current target.
- [ ] When one or more entries are saved today, the ring and summary use the summed total for the local day.
- [ ] When the total exceeds the target, the percentage display caps visually without losing the actual consumed amount.
- [ ] When a record is edited or deleted, the Home summary recalculates from the repository.
- [ ] When the app reloads, the daily summary is rebuilt from persisted local logs.
- [ ] When the user views the Home screen on a narrow viewport, the progress and logging controls remain readable.

## Dependencies

This story depends on local persistence and supplies context to reminders, analytics, and the coach.

### HYD-US-009: Configure Hydration Goals and Units

**Story ID:** HYD-US-009  
**Title:** Configure Hydration Goals and Units  
**Epic:** Goals and Personalization  
**Story Type:** User Story  
**Priority:** P1  
**Release Scope:** MVP  
**T-shirt Size:** L  
**Project Column:** Product Backlog  
**Business Rank:** 012  
**Labels:** `user-story`, `type:user-story`, `epic:goals-personalization`, `priority:p1`, `scope:mvp`, `size:l`, `status:product-backlog`  
**Milestone:** MVP Product UX

## User Story

**As a** Hydrion user  
**I need** to set my daily hydration goal and preferred display units  
**So that** progress reflects my personal target instead of a fixed default.

## Business Value

A fixed 2200 ml target is useful for the first MVP slice but weak for personalization. Goal and unit settings make summaries, reminders, score, challenges, and coach messages more relevant.

## Business Rules

- Hydrion must keep a safe default goal until the user changes it.
- Goal changes affect future summaries immediately but must not rewrite the amount stored on historical records.
- Unit conversion changes display values only; canonical storage remains milliliters.

## Acceptance Criteria

- [ ] The Settings screen lets the user enter a valid daily goal within the supported hydration range.
- [ ] When the user saves a goal, Home, analytics, score, reminders, challenges, and coach context use the updated target.
- [ ] When the user selects metric or supported alternate units, visible amounts convert consistently while stored logs remain in milliliters.
- [ ] When the user enters an empty, negative, zero, or extreme goal, Hydrion rejects the value and keeps the previous target.
- [ ] When the app reloads, the saved goal and unit preference are restored.
- [ ] When a legacy install has no goal setting, Hydrion falls back to the default target without migration errors.
- [ ] Changing the goal does not delete, duplicate, or mutate existing hydration logs.

## Sub-tasks

- [ ] Add goal and unit fields to local user settings.
- [ ] Route the saved goal through summary, analytics, reminder, challenge, and coach context services.
- [ ] Add validation coverage for invalid goals and unit conversion display.

### HYD-US-010: View Analytics Empty State and Daily Totals

**Story ID:** HYD-US-010  
**Title:** View Analytics Empty State and Daily Totals  
**Epic:** Analytics and Insights  
**Story Type:** User Story  
**Priority:** P1  
**Release Scope:** MVP  
**T-shirt Size:** S  
**Project Column:** Product Backlog  
**Business Rank:** 030  
**Labels:** `user-story`, `type:user-story`, `epic:analytics-insights`, `priority:p1`, `scope:mvp`, `size:s`, `status:product-backlog`  
**Milestone:** MVP Product UX

## User Story

**As a** Hydrion user  
**I need** analytics to show either a helpful empty state or my current daily totals  
**So that** I understand what data Hydrion has available.

## Business Value

Analytics should not look broken before the first log. Clear totals and empty states help users trust that Hydrion is using local data and not waiting for cloud services.

## Acceptance Criteria

- [ ] When no logs exist, the Analytics screen displays an empty state explaining that analytics need hydration entries.
- [ ] When today's logs exist, analytics show today's consumed amount against the current target.
- [ ] The screen displays the number of local entries used for the daily total.
- [ ] Lifetime-dependent analytics use all saved local logs rather than only today's records.
- [ ] Editing or deleting a record updates the analytics values on the next render.

### HYD-US-011: Calculate Hydration Score

**Story ID:** HYD-US-011  
**Title:** Calculate Hydration Score  
**Epic:** Analytics and Insights  
**Story Type:** User Story  
**Priority:** P1  
**Release Scope:** MVP  
**T-shirt Size:** S  
**Project Column:** Product Backlog  
**Business Rank:** 031  
**Labels:** `user-story`, `type:user-story`, `epic:analytics-insights`, `priority:p1`, `scope:mvp`, `size:s`, `status:product-backlog`  
**Milestone:** MVP Product UX

## User Story

**As a** Hydrion user  
**I need** a hydration score based on today's progress and entry count  
**So that** I can quickly interpret how well I am tracking.

## Business Value

A compact score turns raw milliliters into feedback that is easier to scan than a full history. It also supports future coaching and engagement features.

## Acceptance Criteria

- [ ] When today's total is zero, the score reflects a low-progress state without implying missing device data.
- [ ] When today's total approaches the target, the score increases consistently with the consumed percentage.
- [ ] When today's total exceeds the target, the score caps at the maximum supported score.
- [ ] The score includes entry-count context so a single large entry and several steady entries can be distinguished in copy or display.
- [ ] Score calculation uses the same target and daily total as the Home progress ring.

### HYD-US-012: Track Daily Goal Streaks

**Story ID:** HYD-US-012  
**Title:** Track Daily Goal Streaks  
**Epic:** Engagement  
**Story Type:** User Story  
**Priority:** P2  
**Release Scope:** Supporting  
**T-shirt Size:** S  
**Project Column:** Product Backlog  
**Business Rank:** 032  
**Labels:** `user-story`, `type:user-story`, `epic:engagement`, `priority:p2`, `scope:supporting`, `size:s`, `status:product-backlog`  
**Milestone:** MVP Product UX

## User Story

**As a** Hydrion user  
**I need** to see whether I am maintaining a daily hydration streak  
**So that** I have a lightweight reason to keep logging consistently.

## Business Value

Streaks add motivation without requiring social accounts or cloud sync. They are useful only if they are calculated from local day boundaries and stay honest about missing days.

## Acceptance Criteria

- [ ] When the user reaches the daily target today, today counts toward the current streak.
- [ ] When a prior local day is below target, the streak stops at that day.
- [ ] When there are no qualifying days, the streak value is zero.
- [ ] The streak calculation uses persisted local logs after app reload.
- [ ] Changing or deleting a historical record recalculates the streak from the updated data.

## Edge Cases

The MVP may limit the lookback window, but the displayed streak must not claim days Hydrion did not calculate.

### HYD-US-013: Display Local Achievement Badges

**Story ID:** HYD-US-013  
**Title:** Display Local Achievement Badges  
**Epic:** Engagement  
**Story Type:** User Story  
**Priority:** P2  
**Release Scope:** Supporting  
**T-shirt Size:** S  
**Project Column:** Product Backlog  
**Business Rank:** 033  
**Labels:** `user-story`, `type:user-story`, `epic:engagement`, `priority:p2`, `scope:supporting`, `size:s`, `status:product-backlog`  
**Milestone:** MVP Product UX

## User Story

**As a** Hydrion user  
**I need** local achievement badges for simple hydration milestones  
**So that** I can recognize progress without needing a social backend.

## Business Value

Badges give the analytics screen a positive feedback layer while keeping the MVP standalone. They should reflect observable local behavior rather than remote reputation or shared challenges.

## Acceptance Criteria

- [ ] A two-liter daily badge unlocks when today's local total reaches the badge threshold.
- [ ] A frequent-logging badge unlocks when today's local entry count reaches the badge threshold.
- [ ] A streak badge unlocks only when the locally calculated streak reaches the badge threshold.
- [ ] Locked badges remain visible with a clear locked state.
- [ ] Badge state recalculates after log edit or deletion.

### HYD-US-014: Estimate Eco Impact From Local Logs

**Story ID:** HYD-US-014  
**Title:** Estimate Eco Impact From Local Logs  
**Epic:** Analytics and Insights  
**Story Type:** User Story  
**Priority:** P2  
**Release Scope:** Supporting  
**T-shirt Size:** XS  
**Project Column:** Product Backlog  
**Business Rank:** 034  
**Labels:** `user-story`, `type:user-story`, `epic:analytics-insights`, `priority:p2`, `scope:supporting`, `size:xs`, `status:product-backlog`  
**Milestone:** MVP Product UX

## User Story

**As a** Hydrion user  
**I need** a local eco-impact estimate based on tracked water  
**So that** Hydrion can show an extra benefit of refill habits.

## Business Value

Eco impact is a lightweight differentiator. It should remain a clear estimate derived from saved logs, not a certified environmental claim.

## Acceptance Criteria

- [ ] When lifetime logs exist, Hydrion calculates an estimated plastic-saved value from total tracked milliliters.
- [ ] When there are no logs, the eco estimate displays zero.
- [ ] The analytics copy identifies the estimate as derived from local saved logs.
- [ ] Editing or deleting logs changes the estimate according to the new lifetime total.

### HYD-US-015: Save Local Reminder Definitions

**Story ID:** HYD-US-015  
**Title:** Save Local Reminder Definitions  
**Epic:** Reminders  
**Story Type:** User Story  
**Priority:** P1  
**Release Scope:** MVP  
**T-shirt Size:** M  
**Project Column:** Product Backlog  
**Business Rank:** 020  
**Labels:** `user-story`, `type:user-story`, `epic:reminders`, `priority:p1`, `scope:mvp`, `size:m`, `status:product-backlog`  
**Milestone:** MVP Product UX

## User Story

**As a** Hydrion user  
**I need** to save local reminder definitions  
**So that** Hydrion can help me plan hydration nudges without claiming OS notifications are active.

## Business Value

Reminder definitions are useful in standalone mode and provide a safe bridge to future notification scheduling. They must be stored honestly as app data until a native notification adapter exists.

## Business Rules

- Saving a reminder creates local reminder data only.
- Hydrion must not claim that the operating system will fire a notification while notifications are disabled.

## Acceptance Criteria

- [ ] When the user saves a reminder suggestion, Hydrion stores a local reminder with trigger time, message, and priority.
- [ ] When the reminder policy declines a reminder, no reminder definition is created.
- [ ] When a local reminder is saved, the user sees copy that distinguishes saved app data from OS notification scheduling.
- [ ] When the app reloads, saved reminder definitions are available from local storage.
- [ ] When capability reporting says OS notifications are disabled, reminder save flows continue to avoid native scheduling claims.
- [ ] Reminder messages must not contain provider secrets, diagnostics, or raw prompt text.

### HYD-US-016: Manage Saved Reminder Definitions

**Story ID:** HYD-US-016  
**Title:** Manage Saved Reminder Definitions  
**Epic:** Reminders  
**Story Type:** User Story  
**Priority:** P1  
**Release Scope:** MVP  
**T-shirt Size:** M  
**Project Column:** Product Backlog  
**Business Rank:** 021  
**Labels:** `user-story`, `type:user-story`, `epic:reminders`, `priority:p1`, `scope:mvp`, `size:m`, `status:product-backlog`  
**Milestone:** MVP Product UX

## User Story

**As a** Hydrion user  
**I need** to view and delete saved local reminder definitions  
**So that** I can control the reminders Hydrion has stored.

## Business Value

Managing reminders prevents stale nudge data from accumulating and keeps the local-first promise transparent. Users should never need cloud account tools to understand what reminder data exists.

## Acceptance Criteria

- [ ] When no reminder definitions exist, the Reminders screen shows an empty state for local reminders.
- [ ] When reminders exist, the screen lists each message with trigger time and priority.
- [ ] When the user deletes a reminder, Hydrion removes it from local storage.
- [ ] When deletion succeeds, the reminder list updates without app restart.
- [ ] When all reminders are deleted, the screen returns to the empty state.
- [ ] The Reminders screen displays whether OS notification scheduling is currently unavailable or configured.

### HYD-US-017: Gate OS Notification Scheduling

**Story ID:** HYD-US-017  
**Title:** Gate OS Notification Scheduling  
**Epic:** Reminders  
**Story Type:** Safety Story  
**Priority:** P2  
**Release Scope:** Supporting  
**T-shirt Size:** S  
**Project Column:** Product Backlog  
**Business Rank:** 022  
**Labels:** `user-story`, `type:safety-story`, `epic:reminders`, `priority:p2`, `scope:supporting`, `size:s`, `status:product-backlog`  
**Milestone:** MVP Product UX

## User Story

**As a** Hydrion user  
**I need** notification scheduling to be clearly gated until a real adapter exists  
**So that** I do not expect reminders my device will never deliver.

## Business Value

Honest notification status protects trust and reduces product-support risk. It also prevents future provider suggestions from overstating what the app can do.

## Acceptance Criteria

- [ ] When OS notification capability is disabled, Hydrion describes reminders as local definitions only.
- [ ] Provider or coach actions that claim OS notifications are scheduled are rejected or converted into a safe notice.
- [ ] The Settings and Reminders screens show notification capability status using user-facing language.
- [ ] Permission checks in standalone mode do not request native notification permission.
- [ ] A future notification adapter cannot be marked available without capability reporting and user-facing status changing together.

### HYD-US-018: Join a Local Hydration Challenge

**Story ID:** HYD-US-018  
**Title:** Join a Local Hydration Challenge  
**Epic:** Local Challenges  
**Story Type:** User Story  
**Priority:** P2  
**Release Scope:** Supporting  
**T-shirt Size:** S  
**Project Column:** Product Backlog  
**Business Rank:** 035  
**Labels:** `user-story`, `type:user-story`, `epic:local-challenges`, `priority:p2`, `scope:supporting`, `size:s`, `status:product-backlog`  
**Milestone:** MVP Product UX

## User Story

**As a** Hydrion user  
**I need** to join a standalone hydration challenge  
**So that** I can pursue a short-term goal without a social backend.

## Business Value

Local challenges create engagement while preserving offline operation. They give the app a motivational flow that does not depend on accounts, friends, leaderboards, or cloud state.

## Acceptance Criteria

- [ ] When the user opens Challenges with no active challenge, Hydrion offers a local challenge with name, target, and duration.
- [ ] When the user joins the challenge, Hydrion saves the active challenge locally.
- [ ] After joining, the challenge action shows a joined state instead of allowing duplicate joins.
- [ ] Challenge join state survives app reload on the same device.
- [ ] The screen states whether social sync is unavailable or only locally represented.

### HYD-US-019: Track Local Challenge Progress

**Story ID:** HYD-US-019  
**Title:** Track Local Challenge Progress  
**Epic:** Local Challenges  
**Story Type:** User Story  
**Priority:** P2  
**Release Scope:** Supporting  
**T-shirt Size:** M  
**Project Column:** Product Backlog  
**Business Rank:** 036  
**Labels:** `user-story`, `type:user-story`, `epic:local-challenges`, `priority:p2`, `scope:supporting`, `size:m`, `status:product-backlog`  
**Milestone:** MVP Product UX

## User Story

**As a** Hydrion user  
**I need** local challenge progress to reflect my saved hydration logs  
**So that** I can see whether I am meeting the challenge target.

## Business Value

Challenge progress connects motivation to the core logging loop. It should be calculated from local data so it remains available offline and consistent with analytics.

## Acceptance Criteria

- [ ] When a challenge is active, Hydrion shows the challenge target, duration, today's logged amount, and completed-day count.
- [ ] A day counts as complete only when local logs for that day meet or exceed the challenge target.
- [ ] Editing or deleting a hydration log recalculates challenge progress.
- [ ] Future days do not count toward completed days.
- [ ] When no challenge is active, progress displays a neutral state instead of using stale challenge data.
- [ ] Challenge progress survives app reload because it is derived from saved challenge state and hydration logs.

### HYD-US-020: Leave Challenges and Keep Completion History

**Story ID:** HYD-US-020  
**Title:** Leave Challenges and Keep Completion History  
**Epic:** Local Challenges  
**Story Type:** User Story  
**Priority:** P2  
**Release Scope:** Supporting  
**T-shirt Size:** L  
**Project Column:** Product Backlog  
**Business Rank:** 037  
**Labels:** `user-story`, `type:user-story`, `epic:local-challenges`, `priority:p2`, `scope:supporting`, `size:l`, `status:product-backlog`  
**Milestone:** MVP Product UX

## User Story

**As a** Hydrion user  
**I need** to leave an active local challenge and preserve completed challenge history  
**So that** challenge state remains understandable after I stop or finish a challenge.

## Business Value

Current active-challenge state is not enough for a complete user workflow. Leaving and history prevent Hydrion from trapping users in a challenge and create a foundation for future achievements.

## Business Rules

- Leaving a challenge clears the active challenge without deleting hydration logs.
- Completion history records local challenge facts, not social proof or backend validation.

## Acceptance Criteria

- [ ] When the user leaves an active challenge, Hydrion clears only the active challenge state.
- [ ] When the user completes a challenge locally, Hydrion records completion date, challenge ID, target, and duration.
- [ ] Completed challenge history is visible separately from the active challenge card.
- [ ] Leaving an incomplete challenge does not create a completed-history entry.
- [ ] Reloading the app restores completion history from local storage.
- [ ] Joining a new challenge after leaving does not resurrect the old active challenge.
- [ ] Challenge history can be exported or deleted once local data-rights controls exist.

## Sub-tasks

- [ ] Add persisted challenge history data separate from active challenge state.
- [ ] Add leave and completed-history UI states to the Challenges screen.
- [ ] Add tests for leave, completion, reload, and log-independent history behavior.

### HYD-US-021: Show Local Hydration Advice on Home

**Story ID:** HYD-US-021  
**Title:** Show Local Hydration Advice on Home  
**Epic:** Coach and Guidance  
**Story Type:** User Story  
**Priority:** P1  
**Release Scope:** MVP  
**T-shirt Size:** S  
**Project Column:** Product Backlog  
**Business Rank:** 038  
**Labels:** `user-story`, `type:user-story`, `epic:coach-guidance`, `priority:p1`, `scope:mvp`, `size:s`, `status:product-backlog`  
**Milestone:** MVP AI Provider Safety

## User Story

**As a** Hydrion user  
**I need** concise local hydration advice on the Home screen  
**So that** I get guidance even when no external AI provider is active.

## Business Value

Home advice makes Hydrion feel helpful from the core screen while preserving local-first behavior. It also creates a safe fallback when optional providers are missing or rejected.

## Acceptance Criteria

- [ ] Advice reflects today's hydration percentage and entry count.
- [ ] When progress is low, advice suggests a practical next intake action.
- [ ] When progress is near target, advice encourages maintaining pace.
- [ ] When progress is strong, advice confirms the user is on track without medical claims.
- [ ] Advice remains available in local rules mode and does not require network access.

### HYD-US-022: Chat With Local Hydration Coach

**Story ID:** HYD-US-022  
**Title:** Chat With Local Hydration Coach  
**Epic:** Coach and Guidance  
**Story Type:** User Story  
**Priority:** P1  
**Release Scope:** MVP  
**T-shirt Size:** M  
**Project Column:** Product Backlog  
**Business Rank:** 039  
**Labels:** `user-story`, `type:user-story`, `epic:coach-guidance`, `priority:p1`, `scope:mvp`, `size:m`, `status:product-backlog`  
**Milestone:** MVP AI Provider Safety

## User Story

**As a** Hydrion user  
**I need** a chat-style coach that can answer from local hydration context  
**So that** I can ask simple questions without sending data to a cloud provider by default.

## Business Value

The coach differentiates Hydrion, but it must not undermine privacy or reliability. A local chat fallback ensures the feature remains useful when provider configuration is absent.

## Acceptance Criteria

- [ ] When the user submits a nonempty question, the coach adds the user message to the thread and returns a local response.
- [ ] The coach response includes current hydration context such as today's total or entry count when available.
- [ ] Empty messages are ignored without adding blank chat bubbles.
- [ ] While a coach response is pending, the send action prevents duplicate submissions.
- [ ] When provider execution fails, the screen shows a safe fallback notice without exposing diagnostics.
- [ ] The chat screen labels the active provider state in user-facing language.

### HYD-US-023: Build Typed Hydration Context

**Story ID:** HYD-US-023  
**Title:** Build Typed Hydration Context  
**Epic:** Coach and Guidance  
**Story Type:** Technical Story  
**Priority:** P1  
**Release Scope:** Supporting  
**T-shirt Size:** M  
**Project Column:** Product Backlog  
**Business Rank:** 014  
**Labels:** `user-story`, `type:technical-story`, `epic:coach-guidance`, `priority:p1`, `scope:supporting`, `size:m`, `status:product-backlog`  
**Milestone:** MVP AI Provider Safety

## User Story

**As a** Hydration coach service  
**I need** a typed context object built from local state  
**So that** advice and provider proposals use validated hydration, reminder, challenge, and capability data.

## Business Value

Typed context keeps provider boundaries testable and reduces the risk of raw UI state or private data leaking into prompts. It also gives local and optional providers the same contract.

## Data and State Requirements

Context must include daily summary, lifetime total, event count, reminder summary, challenge summary, and capability availability.

## Acceptance Criteria

- [ ] When context is requested, Hydrion builds today's summary from local hydration logs and the current target.
- [ ] Reminder context includes saved reminder count, next reminder time, and OS notification availability.
- [ ] Challenge context identifies active challenge state and local progress values.
- [ ] Capability context lists unavailable integrations as unavailable rather than omitting them.
- [ ] Context construction does not include raw provider secrets, API keys, or prompt diagnostics.
- [ ] Context can be built after app reload from persisted local state.

### HYD-US-024: Confirm Coach Suggestions Before State Changes

**Story ID:** HYD-US-024  
**Title:** Confirm Coach Suggestions Before State Changes  
**Epic:** Coach and Guidance  
**Story Type:** Safety Story  
**Priority:** P1  
**Release Scope:** Supporting  
**T-shirt Size:** M  
**Project Column:** Product Backlog  
**Business Rank:** 015  
**Labels:** `user-story`, `type:safety-story`, `epic:coach-guidance`, `priority:p1`, `scope:supporting`, `size:m`, `status:product-backlog`  
**Milestone:** MVP AI Provider Safety

## User Story

**As a** Hydrion user  
**I need** to confirm coach suggestions before they change app state  
**So that** advice cannot silently add logs, reminders, or challenges.

## Business Value

User confirmation is a safety boundary for both local and optional AI flows. It protects data integrity and avoids surprising state changes from provider output.

## Acceptance Criteria

- [ ] State-changing coach suggestions render as cards that explain the proposed change.
- [ ] A hydration-log suggestion is not saved until the user confirms it.
- [ ] A reminder suggestion is not saved until the user confirms it.
- [ ] A challenge suggestion is not joined until the user confirms it.
- [ ] Dismissing a suggestion removes it from the visible list without applying it.
- [ ] Invalid or unsupported suggestions display a rejected or display-only status instead of mutating state.
- [ ] Confirmed actions report whether they were applied, rejected, or display-only.

### HYD-US-025: Parse Hydration Commands for Typed or Future Voice Use

**Story ID:** HYD-US-025  
**Title:** Parse Hydration Commands for Typed or Future Voice Use  
**Epic:** Voice and Commands  
**Story Type:** Enabler Story  
**Priority:** P2  
**Release Scope:** Supporting  
**T-shirt Size:** S  
**Project Column:** Product Backlog  
**Business Rank:** 040  
**Labels:** `user-story`, `type:enabler-story`, `epic:voice-commands`, `priority:p2`, `scope:supporting`, `size:s`, `status:product-backlog`  
**Milestone:** MVP AI Provider Safety

## User Story

**As a** Hydrion command service  
**I need** typed hydration command parsing  
**So that** text commands and future voice transcripts can become safe app intents.

## Business Value

Command parsing lets Hydrion reuse one safe intent path for typed input, coach actions, and future voice capture without granting microphone access early.

## Acceptance Criteria

- [ ] Commands containing a drink or log intent return a `log_hydration` intent.
- [ ] Commands with a milliliter amount return that amount as `volumeMl`.
- [ ] Reminder-like commands return a `schedule_reminder` intent without scheduling OS notifications.
- [ ] Unknown commands return an `unknown_command` intent that preserves the original command text.
- [ ] Parsed entities are structured data rather than raw UI instructions.

### HYD-US-026: Gate Voice Capture Until a Real Adapter Exists

**Story ID:** HYD-US-026  
**Title:** Gate Voice Capture Until a Real Adapter Exists  
**Epic:** Voice and Commands  
**Story Type:** Integration Story  
**Priority:** P3  
**Release Scope:** Post-MVP  
**T-shirt Size:** L  
**Project Column:** Ice Box  
**Business Rank:** 004  
**Labels:** `user-story`, `type:integration-story`, `epic:voice-commands`, `priority:p3`, `scope:post-mvp`, `size:l`, `status:ice-box`

## User Story

**As a** Hydrion user  
**I need** microphone-based voice capture to remain disabled until a complete adapter, permission flow, and confirmation UX exist  
**So that** Hydrion never listens or implies listening without consent.

## Business Value

Voice can improve accessibility and speed later, but premature microphone capture creates privacy, platform, and trust risks. Keeping it gated protects the MVP while preserving a future path.

## Business Rules

- A transcript parser is not the same as microphone capture.
- Voice capture requires explicit permission copy, adapter availability, error handling, and confirmation before state changes.

## Acceptance Criteria

- [ ] When voice capability is disabled, the Home voice control communicates that voice input is unavailable.
- [ ] Calling voice initialization without an adapter returns unavailable and does not request microphone permission.
- [ ] Future microphone capture cannot change hydration state without passing through command parsing and user confirmation.
- [ ] Voice status appears consistently in capability reporting and Settings.
- [ ] The future adapter plan covers web and Android permission behavior separately.
- [ ] Provider or coach output cannot claim live voice input is active while the capability is disabled.

## Out of Scope

Speech-to-text model choice, wake-word detection, background listening, and audio retention are not part of the current MVP.

### HYD-US-027: Persist Language Settings

**Story ID:** HYD-US-027  
**Title:** Persist Language Settings  
**Epic:** Localization  
**Story Type:** User Story  
**Priority:** P1  
**Release Scope:** MVP  
**T-shirt Size:** S  
**Project Column:** Product Backlog  
**Business Rank:** 023  
**Labels:** `user-story`, `type:user-story`, `epic:localization`, `priority:p1`, `scope:mvp`, `size:s`, `status:product-backlog`  
**Milestone:** MVP Product UX

## User Story

**As a** multilingual Hydrion user  
**I need** my selected app language to persist locally  
**So that** Hydrion opens in my chosen language after reload.

## Business Value

Language persistence makes localization usable beyond a demo. It also keeps the app consistent with its local-first storage model.

## Acceptance Criteria

- [ ] The Settings screen lets the user choose from supported app languages.
- [ ] When the user changes language, visible app text updates without requiring restart.
- [ ] The selected language is saved to local settings storage.
- [ ] Reloading services restores the saved language when it is supported.
- [ ] A language-change confirmation appears in the selected language.

### HYD-US-028: Show Runtime Capability and Permission Status

**Story ID:** HYD-US-028  
**Title:** Show Runtime Capability and Permission Status  
**Epic:** Capability Status  
**Story Type:** Operational Story  
**Priority:** P2  
**Release Scope:** Supporting  
**T-shirt Size:** S  
**Project Column:** Product Backlog  
**Business Rank:** 041  
**Labels:** `user-story`, `type:operational-story`, `epic:capability-status`, `priority:p2`, `scope:supporting`, `size:s`, `status:product-backlog`  
**Milestone:** MVP Product UX

## User Story

**As a** Hydrion user  
**I need** Settings to show which runtime capabilities are active or disabled  
**So that** I understand what the app can do on this device.

## Business Value

Capability status prevents confusion around local persistence, providers, notifications, voice, BLE, Health, AR, and social sync. It is especially important while many integrations are intentionally disabled.

## Acceptance Criteria

- [ ] Settings displays the current app mode and capability status.
- [ ] Local persistence appears as available when the local store is active.
- [ ] Disabled capabilities are labeled as disabled or unconfigured, not hidden.
- [ ] The permission check action explains when no platform permission is requested in standalone mode.
- [ ] Provider health and capability status use consistent labels for local rules, Gemini, and ELKA.

### HYD-US-029: Render English, Spanish, and French App Strings

**Story ID:** HYD-US-029  
**Title:** Render English, Spanish, and French App Strings  
**Epic:** Localization  
**Story Type:** User Story  
**Priority:** P1  
**Release Scope:** MVP  
**T-shirt Size:** M  
**Project Column:** Product Backlog  
**Business Rank:** 024  
**Labels:** `user-story`, `type:user-story`, `epic:localization`, `priority:p1`, `scope:mvp`, `size:m`, `status:product-backlog`  
**Milestone:** MVP Release Readiness

## User Story

**As a** multilingual Hydrion user  
**I need** English, Spanish, and French UI strings to render across core screens  
**So that** the app is usable in each supported language.

## Business Value

Supported languages are product commitments. Missing or mixed-language strings make the app feel unfinished and can break trust in settings, privacy, and provider status copy.

## Acceptance Criteria

- [ ] English, Spanish, and French generated localization files contain strings for Home, Settings, Log, Analytics, Coach, Reminders, Challenges, and provider status.
- [ ] Changing the locale updates visible navigation and primary action text.
- [ ] Provider safety, privacy, and capability messages render in each supported language.
- [ ] Suggestion cards and coach status strings render in Spanish and French.
- [ ] Missing translations fail localization quality checks before release.
- [ ] Locale-specific text remains readable on narrow mobile screens.

### HYD-US-030: Handle Future and Unsupported Locales Safely

**Story ID:** HYD-US-030  
**Title:** Handle Future and Unsupported Locales Safely  
**Epic:** Localization  
**Story Type:** Technical Story  
**Priority:** P2  
**Release Scope:** Supporting  
**T-shirt Size:** XS  
**Project Column:** Product Backlog  
**Business Rank:** 025  
**Labels:** `user-story`, `type:technical-story`, `epic:localization`, `priority:p2`, `scope:supporting`, `size:xs`, `status:product-backlog`  
**Milestone:** MVP Release Readiness

## User Story

**As a** Hydrion user with an unsupported device locale  
**I need** the app to fall back safely to a supported language  
**So that** Hydrion remains usable instead of displaying broken strings.

## Business Value

Locale fallback protects first launch for users outside the active language set and keeps future-language placeholders from becoming false commitments.

## Acceptance Criteria

- [ ] Unsupported locales resolve to the fallback locale.
- [ ] Future locales are identified as future or unsupported until translations exist.
- [ ] Text direction can be derived for right-to-left future locales without activating incomplete translations.
- [ ] Locale fallback does not overwrite a user's saved supported language.

### HYD-US-031: Enforce Capability Gating and Safe Action Validation

**Story ID:** HYD-US-031  
**Title:** Enforce Capability Gating and Safe Action Validation  
**Epic:** Safety and Capability Gating  
**Story Type:** Safety Story  
**Priority:** P0  
**Release Scope:** Supporting  
**T-shirt Size:** L  
**Project Column:** Product Backlog  
**Business Rank:** 005  
**Labels:** `user-story`, `type:safety-story`, `epic:safety-capability-gating`, `priority:p0`, `scope:supporting`, `size:l`, `status:product-backlog`  
**Milestone:** MVP AI Provider Safety

## User Story

**As a** Hydrion maintainer  
**I need** provider and coach actions validated against runtime capabilities before execution  
**So that** unavailable integrations cannot be claimed or mutated through unsafe output.

## Business Value

Capability validation is a security and trust boundary. It protects local data from invalid provider proposals and prevents disabled integrations from appearing active.

## Business Rules

- State-changing actions require confirmation after validation.
- Actions that require unavailable capabilities are rejected or transformed into safe notices.
- Structural validation must reject invalid volumes, negative reminder delays, and invalid challenge values.

## Acceptance Criteria

- [ ] Provider actions that require disabled capabilities are rejected before execution.
- [ ] Text that actively claims unavailable capabilities are enabled is converted into a safe unsupported-capability notice.
- [ ] Suggested hydration logs outside the supported amount range are rejected.
- [ ] Suggested reminders with negative delays are rejected.
- [ ] Suggested challenges with invalid targets or duration are rejected.
- [ ] State-changing actions cannot execute without explicit user confirmation.
- [ ] Validation results expose blocked capability labels without leaking provider secrets.
- [ ] Local rules mode continues to pass safe coach messages through validation.

### HYD-US-032: Use Optional Gemini Provider With Local Fallback

**Story ID:** HYD-US-032  
**Title:** Use Optional Gemini Provider With Local Fallback  
**Epic:** AI Provider Safety  
**Story Type:** Integration Story  
**Priority:** P1  
**Release Scope:** Supporting  
**T-shirt Size:** M  
**Project Column:** Product Backlog  
**Business Rank:** 017  
**Labels:** `user-story`, `type:integration-story`, `epic:ai-provider-safety`, `priority:p1`, `scope:supporting`, `size:m`, `status:product-backlog`  
**Milestone:** MVP AI Provider Safety

## User Story

**As a** Hydrion developer testing optional AI  
**I need** Gemini to run only when explicitly configured and fall back locally when unavailable  
**So that** the app never depends on a cloud provider for core hydration behavior.

## Business Value

Gemini can improve coaching experiments, but MVP reliability and privacy depend on local fallback. Safe configuration prevents accidental key exposure and broken runtime paths.

## Acceptance Criteria

- [ ] When no provider is configured, Hydrion selects `local_rules` as the active provider.
- [ ] When Gemini is selected without an API key, Hydrion records a fallback reason and continues with local rules.
- [ ] When Gemini is configured for local development, provider requests use typed hydration context and expect typed actions.
- [ ] Gemini responses that fail parsing, schema, validation, timeout, or HTTP checks fall back before app logic trusts them.
- [ ] Provider diagnostics redact API key values while preserving useful status details.
- [ ] The Home and Coach screens remain usable when Gemini fails.

## Security and Privacy Requirements

Production web or mobile clients must not ship a shared Gemini key.

### HYD-US-033: Display Safe Provider Health Diagnostics

**Story ID:** HYD-US-033  
**Title:** Display Safe Provider Health Diagnostics  
**Epic:** AI Provider Safety  
**Story Type:** Operational Story  
**Priority:** P1  
**Release Scope:** Supporting  
**T-shirt Size:** M  
**Project Column:** Product Backlog  
**Business Rank:** 018  
**Labels:** `user-story`, `type:operational-story`, `epic:ai-provider-safety`, `priority:p1`, `scope:supporting`, `size:m`, `status:product-backlog`  
**Milestone:** MVP AI Provider Safety

## User Story

**As a** Hydrion developer or support reviewer  
**I need** provider health diagnostics that are useful but redacted  
**So that** provider failures can be understood without exposing secrets or raw user prompts.

## Business Value

Diagnostics lower support cost and speed up provider debugging. They must be safe enough to display in Settings without leaking credentials or sensitive request content.

## Acceptance Criteria

- [ ] Settings shows selected provider, active provider, local fallback state, and Gemini configuration state.
- [ ] Gemini diagnostics display endpoint host, model path, request status, parser status, and validator status when relevant.
- [ ] API keys are never displayed in full.
- [ ] Fallback reasons are visible without including the user's prompt text.
- [ ] Provider success and failure timestamps are shown only when available.
- [ ] Privacy copy changes when a non-local provider is active or requires consent.

### HYD-US-034: Keep ELKA as an Optional Adapter Boundary

**Story ID:** HYD-US-034  
**Title:** Keep ELKA as an Optional Adapter Boundary  
**Epic:** Future Provider Integrations  
**Story Type:** Integration Story  
**Priority:** P3  
**Release Scope:** Post-MVP  
**T-shirt Size:** XL  
**Project Column:** Ice Box  
**Business Rank:** 003  
**Labels:** `user-story`, `type:integration-story`, `epic:future-provider-integrations`, `priority:p3`, `scope:post-mvp`, `size:xl`, `status:ice-box`, `needs-decomposition`

## User Story

**As a** Hydrion maintainer  
**I need** ELKA to remain an optional adapter boundary until its runtime, consent, and validation model are defined  
**So that** future provider work cannot leak into core app state prematurely.

## Business Value

An ELKA integration could become valuable, but it spans provider contracts, configuration, diagnostics, privacy disclosure, runtime availability, and user-facing fallbacks. Treating it as a small story would hide real delivery risk.

## Decomposition Plan

- [ ] Define ELKA runtime capability, configuration, and health diagnostics.
- [ ] Implement the ELKA provider adapter behind existing typed action contracts.
- [ ] Add consent, privacy disclosure, and fallback behavior for ELKA-specific data flow.
- [ ] Add tests proving ELKA cannot mutate state without validation and confirmation.

## Acceptance Criteria

- [ ] ELKA remains unavailable in standalone MVP mode until a configured adapter exists.
- [ ] UI and diagnostics identify ELKA as unconfigured rather than failed.
- [ ] Core screens do not import ELKA SDK or runtime dependencies directly.
- [ ] Future ELKA output must use typed Hydrion actions and the shared validator.
- [ ] The integration cannot be promoted from Ice Box until the decomposition slices are estimated separately.

### HYD-US-035: Add Native BLE, Health, and AR Integrations Later

**Story ID:** HYD-US-035  
**Title:** Add Native BLE, Health, and AR Integrations Later  
**Epic:** Native Integrations  
**Story Type:** Integration Story  
**Priority:** P3  
**Release Scope:** Post-MVP  
**T-shirt Size:** XL  
**Project Column:** Ice Box  
**Business Rank:** 002  
**Labels:** `user-story`, `type:integration-story`, `epic:native-integrations`, `priority:p3`, `scope:post-mvp`, `size:xl`, `status:ice-box`, `needs-decomposition`

## User Story

**As a** Hydrion user with connected devices or native sensors  
**I need** future BLE, Health, and AR integrations to be delivered as separate validated slices  
**So that** Hydrion can expand beyond manual logging without compromising privacy or reliability.

## Business Value

BLE, Health, and AR are distinct platform integrations with different permissions, adapters, data contracts, test strategies, and UX risks. Bundling them as one sprint story would make planning and validation misleading.

## Decomposition Plan

- [ ] BLE smart-bottle sync: device discovery, permission flow, ingestion contract, duplicate handling, and disconnect recovery.
- [ ] HealthKit or Google Fit sync: platform permissions, read scope, unit normalization, deduplication, and privacy copy.
- [ ] AR visualization: camera or native session setup, capability detection, fallback UI, and device support matrix.

## Acceptance Criteria

- [ ] Standalone mode continues to mark BLE, Health, and AR unavailable until adapters are present.
- [ ] Each native integration has its own permission copy and denial behavior before activation.
- [ ] Imported hydration data cannot duplicate manual entries without a deduplication rule.
- [ ] Unsupported devices show fallback UI instead of crashing or hiding the feature state.
- [ ] Child issues are created only after the original 51-story issue mapping is verified.

### HYD-US-036: Run as a Web App With PWA Metadata

**Story ID:** HYD-US-036  
**Title:** Run as a Web App With PWA Metadata  
**Epic:** Release Readiness  
**Story Type:** Platform Story  
**Priority:** P2  
**Release Scope:** MVP  
**T-shirt Size:** S  
**Project Column:** Product Backlog  
**Business Rank:** 042  
**Labels:** `user-story`, `type:platform-story`, `epic:release-readiness`, `priority:p2`, `scope:mvp`, `size:s`, `status:product-backlog`  
**Milestone:** MVP Release Readiness

## User Story

**As a** web user  
**I need** Hydrion to build and present correct PWA metadata  
**So that** the installed web app looks like Hydrion rather than a default Flutter project.

## Business Value

Web is a documented MVP target. Default manifest metadata weakens product polish and can confuse installation, bookmarking, and release review.

## Acceptance Criteria

- [ ] The web build completes from the repository root using the documented Flutter command.
- [ ] The PWA manifest uses Hydrion product name, short name, description, theme color, and icons.
- [ ] Web launch reaches the standalone local app without requiring provider credentials.
- [ ] Manifest icons and maskable icons resolve from the generated web build.
- [ ] The web release artifact preserves localization and local-first runtime behavior.

### HYD-US-037: Build Android APK

**Story ID:** HYD-US-037  
**Title:** Build Android APK  
**Epic:** Release Readiness  
**Story Type:** Platform Story  
**Priority:** P2  
**Release Scope:** MVP  
**T-shirt Size:** M  
**Project Column:** Product Backlog  
**Business Rank:** 043  
**Labels:** `user-story`, `type:platform-story`, `epic:release-readiness`, `priority:p2`, `scope:mvp`, `size:m`, `status:product-backlog`  
**Milestone:** MVP Release Readiness

## User Story

**As a** Hydrion release maintainer  
**I need** Android APK builds to succeed in CI and local release workflows  
**So that** Hydrion has a distributable Android artifact for MVP validation.

## Business Value

Android is a documented supported target. Build reliability catches dependency, SDK, manifest, and asset problems before they become release blockers.

## Acceptance Criteria

- [ ] The Android release APK build runs from the repository root with the documented Flutter command.
- [ ] CI uses a known Java and Flutter version for Android release builds.
- [ ] Android launch metadata does not require disabled integrations to be configured.
- [ ] The APK build includes required app assets and generated localization files.
- [ ] Build failure surfaces actionable output instead of being hidden behind a skipped artifact.
- [ ] Local APK build instructions mention the Android SDK environment requirement.

## Platform Considerations

This story does not add Play Store signing, store listing assets, or release-channel automation.

### HYD-US-038: Design Cloud, Social, BYOK, OpenAI, and Edge Integrations

**Story ID:** HYD-US-038  
**Title:** Design Cloud, Social, BYOK, OpenAI, and Edge Integrations  
**Epic:** Future Cloud and Provider Strategy  
**Story Type:** Architecture Story  
**Priority:** P4  
**Release Scope:** Post-MVP  
**T-shirt Size:** XL  
**Project Column:** Ice Box  
**Business Rank:** 001  
**Labels:** `user-story`, `type:architecture-story`, `epic:future-cloud-provider-strategy`, `priority:p4`, `scope:post-mvp`, `size:xl`, `status:ice-box`, `needs-decomposition`

## User Story

**As a** Hydrion product owner  
**I need** cloud sync, social features, BYOK, OpenAI, and edge providers designed as separate future initiatives  
**So that** Hydrion can expand without breaking local-first privacy or issue-number recovery.

## Business Value

These capabilities may unlock major future value, but they span accounts, backend storage, social permissions, provider billing, secret management, offline conflict resolution, and model deployment. They must not be planned as one implementable story.

## Decomposition Plan

- [ ] Cloud sync and accounts: identity, storage, conflict resolution, deletion, and offline behavior.
- [ ] Social challenges: friend or group model, sharing permissions, moderation, and backend challenge state.
- [ ] BYOK and OpenAI: user-owned credentials, secure storage, request routing, consent, and redaction.
- [ ] Edge provider runtime: model packaging, performance budgets, fallback behavior, and platform support.

## Acceptance Criteria

- [ ] No cloud, social, BYOK, OpenAI, or edge feature is marked active in MVP capability reporting.
- [ ] Future design separates account data from local-only hydration logs and data-rights controls.
- [ ] Shared production provider secrets are not stored in client config.
- [ ] Each integration slice defines privacy copy, failure modes, and tests before implementation.
- [ ] Child issues are deferred until the original 51-story mapping is synchronized.

### HYD-US-039: Manage Coach Prompt Templates Safely

**Story ID:** HYD-US-039  
**Title:** Manage Coach Prompt Templates Safely  
**Epic:** Coach and Guidance  
**Story Type:** Enabler Story  
**Priority:** P2  
**Release Scope:** Supporting  
**T-shirt Size:** M  
**Project Column:** Product Backlog  
**Business Rank:** 044  
**Labels:** `user-story`, `type:enabler-story`, `epic:coach-guidance`, `priority:p2`, `scope:supporting`, `size:m`, `status:product-backlog`  
**Milestone:** MVP AI Provider Safety

## User Story

**As a** Hydrion maintainer  
**I need** coach prompt templates to be loaded, validated, and versioned safely before runtime use  
**So that** stale or malformed prompt files cannot mislead provider behavior.

## Business Value

Prompt templates are useful only when they are tied to the active coach path and validated against typed context and action contracts. Otherwise they become configuration drift.

## Acceptance Criteria

- [ ] Hydrion identifies which prompt templates are active, dormant, or unused by runtime coach flows.
- [ ] Active templates are parsed from structured config with clear errors for malformed YAML.
- [ ] Templates can reference only approved hydration context fields.
- [ ] Prompt output expectations remain aligned with typed Hydrion action schemas.
- [ ] Provider prompts must not include API keys, secret diagnostics, or unredacted local storage payloads.
- [ ] Dormant templates are documented or removed so future maintainers do not treat them as runtime behavior.

## Sub-tasks

- [ ] Decide whether `config/prompt_templates.yaml` enters the active coach path or remains future config.
- [ ] Add validation for required template keys and unsupported placeholders.
- [ ] Cover template failure with local fallback behavior.

### HYD-US-040: Keep Stale and Future Scaffolds Truthful

**Story ID:** HYD-US-040  
**Title:** Keep Stale and Future Scaffolds Truthful  
**Epic:** Release Readiness  
**Story Type:** Operational Story  
**Priority:** P2  
**Release Scope:** Supporting  
**T-shirt Size:** S  
**Project Column:** Product Backlog  
**Business Rank:** 045  
**Labels:** `user-story`, `type:operational-story`, `epic:release-readiness`, `priority:p2`, `scope:supporting`, `size:s`, `status:product-backlog`  
**Milestone:** MVP Release Readiness

## User Story

**As a** Hydrion contributor  
**I need** dormant packs, configs, docs, and scaffolds to be labeled truthfully  
**So that** future files are not mistaken for production functionality.

## Business Value

The repository contains future integration material. Clear boundaries prevent roadmap artifacts from becoming false user-facing claims or accidental dependencies.

## Acceptance Criteria

- [ ] Future packs and configs state whether they are runtime-active, development-only, or dormant.
- [ ] User-facing screens do not claim dormant integrations are available.
- [ ] Documentation distinguishes implemented local behavior from future architecture notes.
- [ ] Stale scaffold audits identify files that should be removed, renamed, or explicitly deferred.
- [ ] CI or tests prevent UI code from importing future provider SDKs directly.

### HYD-US-041: Preserve Local-First Privacy Baseline

**Story ID:** HYD-US-041  
**Title:** Preserve Local-First Privacy Baseline  
**Epic:** Privacy and Data Rights  
**Story Type:** Privacy Story  
**Priority:** P0  
**Release Scope:** MVP  
**T-shirt Size:** L  
**Project Column:** Product Backlog  
**Business Rank:** 002  
**Labels:** `user-story`, `type:privacy-story`, `epic:privacy-data-rights`, `priority:p0`, `scope:mvp`, `size:l`, `status:product-backlog`  
**Milestone:** MVP Stabilization

## User Story

**As a** privacy-conscious Hydrion user  
**I need** the MVP to keep hydration data local unless I explicitly enable a future external provider  
**So that** I can use the app without surrendering personal hydration history.

## Business Value

Privacy is a core product promise and a differentiator. It must be protected across local storage, provider configuration, diagnostics, prompts, and disabled integrations.

## Security and Privacy Requirements

- Local hydration logs, reminder definitions, settings, and challenge state remain on device in standalone mode.
- Optional provider use requires explicit configuration and appropriate disclosure.
- Diagnostics must not reveal secrets or raw user prompts.

## Acceptance Criteria

- [ ] Standalone mode stores hydration data locally and does not require an account.
- [ ] Provider configuration is optional and disabled by default.
- [ ] Settings explains whether hydration context may leave the device when a non-local provider is active.
- [ ] Disabled cloud sync, social sync, BLE, Health, AR, and voice features do not transmit data.
- [ ] Provider diagnostics redact API keys and avoid displaying raw user coach prompts.
- [ ] Privacy copy remains visible wherever provider mode or capability status is surfaced.
- [ ] Future external integrations cannot be marked active without privacy disclosure and consent behavior.

## Implementation Evidence

- Local storage remains repository-backed through `HydrionLocalStore`, `HydrationRepository`, `ReminderRepository`, `ChallengeRepository`, and `UserSettingsRepository`.
- `UserSettings.nonLocalProviderConsentGranted` defaults to `false` and persists locally under `hydrion.user_settings.v1`.
- `ExternalIntegrationActivation` separates provider configuration from activation, requiring user enablement, visible disclosure, consent, and local fallback before transmission can be reported active.
- `ProviderBackedHydrationCoach` gates Gemini calls behind `nonLocalProviderEnabled`, so configured providers cannot receive hydration context until consent is enabled.
- Settings shows provider disclosure, consent status, and an explicit Gemini processing switch; Coach status shows when provider consent is required.
- Capability reporting keeps `cloudAi` disabled until provider consent is enabled, while still reporting that Gemini is configured.

## Verification

- `test/gemini_provider_test.dart` covers configured Gemini remaining inactive without consent and verifies the provider is not called and hydration context is not requested while consent is disabled.
- `test/secret_hygiene_test.dart` covers credential URL scanning, redacted credential URL safety, full repository secret scanning, and non-disclosure of detected credential values.

### HYD-US-042: Protect, Export, and Delete Local Personal Data

**Story ID:** HYD-US-042  
**Title:** Protect, Export, and Delete Local Personal Data  
**Epic:** Privacy and Data Rights  
**Story Type:** Privacy Story  
**Priority:** P0  
**Release Scope:** MVP  
**T-shirt Size:** XL  
**Project Column:** Product Backlog  
**Business Rank:** 003  
**Labels:** `user-story`, `type:privacy-story`, `epic:privacy-data-rights`, `priority:p0`, `scope:mvp`, `size:xl`, `status:product-backlog`, `needs-decomposition`  
**Milestone:** MVP Stabilization

## User Story

**As a** Hydrion user  
**I need** controls to protect, export, and delete my local personal data  
**So that** I can manage hydration records, reminders, settings, and challenge state under my own control.

## Business Value

Data rights are central to privacy and release readiness. This work spans storage design, UX, validation, platform behavior, and future encryption decisions, so it must be decomposed before sprint execution.

## Decomposition Plan

- [ ] Local data inventory: enumerate hydration logs, settings, reminders, challenge state, provider diagnostics, and future stored data.
- [ ] Export: produce a user-readable local export with schema version and timestamps.
- [ ] Delete: remove all local personal data and confirm summaries return to empty states.
- [ ] Protection: decide whether encryption, keyring, SQLCipher, or platform storage changes are required for MVP or later.

## Acceptance Criteria

- [ ] The user can see what categories of local personal data Hydrion stores.
- [ ] Export includes hydration logs, reminder definitions, language settings, and challenge state without provider secrets.
- [ ] Delete removes local personal data from all active repositories.
- [ ] After deletion, Home, history, analytics, reminders, challenge, and coach context show empty or default states.
- [ ] Export and delete actions require an intentional confirmation step.
- [ ] The implementation documents what is and is not encrypted in the current storage model.
- [ ] Future cloud or provider data categories are excluded until those integrations are active.

### HYD-US-043: Recover Gracefully From Invalid Stored Data

**Story ID:** HYD-US-043  
**Title:** Recover Gracefully From Invalid Stored Data  
**Epic:** Reliability  
**Story Type:** Technical Story  
**Priority:** P0  
**Release Scope:** MVP  
**T-shirt Size:** M  
**Project Column:** Product Backlog  
**Business Rank:** 004  
**Labels:** `user-story`, `type:technical-story`, `epic:reliability`, `priority:p0`, `scope:mvp`, `size:m`, `status:product-backlog`  
**Milestone:** MVP Stabilization

## User Story

**As a** returning Hydrion user  
**I need** the app to recover from invalid local storage values  
**So that** corrupted data does not prevent me from using Hydrion.

## Business Value

Local storage corruption can happen through old versions, manual tampering, or partial writes. Hydrion must protect availability and avoid data loss beyond the invalid records.

## Acceptance Criteria

- [ ] Invalid hydration log JSON does not crash repository loading.
- [ ] Invalid reminder JSON does not crash reminder loading.
- [ ] Invalid challenge JSON clears active challenge state without affecting hydration logs.
- [ ] Invalid user settings fall back to a supported locale.
- [ ] Valid records in a mixed hydration payload remain available when invalid records are skipped.
- [ ] Recovery behavior is covered by repository-level tests for each persisted data category.

## Edge Cases

Recovery should not silently rewrite unknown future schema data unless a migration decision exists.

## Recovery Policy

- Hydration logs: malformed top-level storage falls back to an empty in-memory list; mixed lists retain valid records and skip invalid records without rewriting storage.
- Reminders: malformed top-level storage falls back to an empty in-memory list; mixed lists retain valid reminder definitions and skip invalid records without scheduling platform notifications.
- Active challenge: malformed or invalid current-schema active challenge state is cleared only from the challenge key to avoid repeated recovery loops.
- User settings: malformed or invalid settings fall back to Hydrion's supported default locale while preserving valid unrelated settings when possible.
- Future schema markers: unsupported future schema payloads are reported through safe local recovery diagnostics and left untouched for a future migration decision.

## Validation Notes

- Repository-level recovery coverage is in `test/storage_recovery_test.dart`.
- Existing persistence and localization regressions remain covered by `test/persistence_test.dart` and `test/localization_test.dart`.

### HYD-US-044: Provide Reliable Error Handling and Fallback UX

**Story ID:** HYD-US-044  
**Title:** Provide Reliable Error Handling and Fallback UX  
**Epic:** Reliability  
**Story Type:** User Story  
**Priority:** P1  
**Release Scope:** MVP  
**T-shirt Size:** M  
**Project Column:** Product Backlog  
**Business Rank:** 028  
**Labels:** `user-story`, `type:user-story`, `epic:reliability`, `priority:p1`, `scope:mvp`, `size:m`, `status:product-backlog`  
**Milestone:** MVP Release Readiness

## User Story

**As a** Hydrion user  
**I need** errors and unavailable features to produce clear fallback states  
**So that** I can keep using local hydration features.

## Business Value

Fallback UX keeps the app resilient when providers, adapters, storage reads, or generated content fail. It prevents failure states from looking like missing product features.

## Acceptance Criteria

- [ ] Empty history, analytics, reminders, and challenge screens explain the current state.
- [ ] Coach failures show a user-facing error or fallback notice without raw diagnostics.
- [ ] Disabled AR, voice, notification, BLE, Health, and social flows show status-specific messages.
- [ ] Missing provider configuration does not block local Home, Log, Analytics, or Settings screens.
- [ ] Error messages avoid medical claims and avoid exposing secrets.
- [ ] Retrying a refreshable local challenge state does not duplicate saved challenge data.

### HYD-US-045: Support Accessibility Semantics

**Story ID:** HYD-US-045  
**Title:** Support Accessibility Semantics  
**Epic:** Accessibility and Responsive UX  
**Story Type:** User Story  
**Priority:** P1  
**Release Scope:** MVP  
**T-shirt Size:** L  
**Project Column:** Product Backlog  
**Business Rank:** 026  
**Labels:** `user-story`, `type:user-story`, `epic:accessibility-responsive-ux`, `priority:p1`, `scope:mvp`, `size:l`, `status:product-backlog`  
**Milestone:** MVP Release Readiness

## User Story

**As an** accessibility-focused Hydrion user  
**I need** core screens and controls to expose meaningful labels, tooltips, and readable states  
**So that** I can operate Hydrion with assistive technologies.

## Business Value

Accessibility is a release-quality requirement, not polish. Hydration logging, settings, privacy status, and destructive actions must remain understandable without relying only on visuals.

## Accessibility Requirements

- Icon-only controls need tooltips or semantic labels.
- Status chips and disabled feature states need text equivalents.
- Empty states should explain what action is available next.

## Acceptance Criteria

- [ ] Hydrion logo instances have semantic labels where they communicate brand or app identity.
- [ ] Icon buttons for settings, edit, delete, reminders, and send actions expose meaningful tooltips.
- [ ] Progress and score components provide readable text values in addition to visual indicators.
- [ ] Disabled voice, AR, notification, and provider states are communicated through text.
- [ ] Language selector and amount selector are reachable and labeled.
- [ ] Destructive delete actions identify the target record or reminder.
- [ ] Core accessibility behavior is validated on Home, Log, Analytics, Settings, Reminders, Challenges, and Coach screens.

### HYD-US-046: Keep Core Screens Usable on Small Viewports

**Story ID:** HYD-US-046  
**Title:** Keep Core Screens Usable on Small Viewports  
**Epic:** Accessibility and Responsive UX  
**Story Type:** User Story  
**Priority:** P1  
**Release Scope:** MVP  
**T-shirt Size:** M  
**Project Column:** Product Backlog  
**Business Rank:** 027  
**Labels:** `user-story`, `type:user-story`, `epic:accessibility-responsive-ux`, `priority:p1`, `scope:mvp`, `size:m`, `status:product-backlog`  
**Milestone:** MVP Release Readiness

## User Story

**As a** mobile Hydrion user  
**I need** core screens to remain usable on small viewports  
**So that** logging and settings work on common phone sizes.

## Business Value

Android and mobile web users are core MVP audiences. Small-screen layout failures can block hydration logging even when the underlying feature works.

## Acceptance Criteria

- [ ] Home logging controls stack or resize when horizontal space is narrow.
- [ ] The selected amount picker and log button remain visible and tappable on a 360 px wide viewport.
- [ ] Route chips wrap without covering the progress ring or advice card.
- [ ] Log edit and delete controls remain reachable on narrow history rows.
- [ ] Settings cards avoid horizontal overflow for provider diagnostics and capability status.
- [ ] Coach input and send controls remain usable with the keyboard area reserved.

### HYD-US-047: Maintain Localization Quality Gates

**Story ID:** HYD-US-047  
**Title:** Maintain Localization Quality Gates  
**Epic:** Localization  
**Story Type:** Operational Story  
**Priority:** P1  
**Release Scope:** MVP  
**T-shirt Size:** M  
**Project Column:** Product Backlog  
**Business Rank:** 046  
**Labels:** `user-story`, `type:operational-story`, `epic:localization`, `priority:p1`, `scope:mvp`, `size:m`, `status:product-backlog`  
**Milestone:** MVP Release Readiness

## User Story

**As a** Hydrion release maintainer  
**I need** localization quality checks for generated strings and supported locales  
**So that** supported-language regressions are caught before release.

## Business Value

Localization defects often appear as missing strings, untranslated provider copy, or broken widgets. Automated gates reduce manual review effort and protect supported users.

## Acceptance Criteria

- [ ] Generated localization files are present for every supported locale.
- [ ] English, Spanish, and French widget tests cover app shell, Home, Settings, provider status, and suggestion card strings.
- [ ] Unsupported locale fallback is covered by tests.
- [ ] Future locale metadata does not expose unfinished translations as active.
- [ ] CI runs localization-dependent tests before web and Android release builds.
- [ ] Adding a new user-facing string requires entries for all supported locales.

### HYD-US-048: Preserve Local Performance and Responsiveness

**Story ID:** HYD-US-048  
**Title:** Preserve Local Performance and Responsiveness  
**Epic:** Performance  
**Story Type:** Operational Story  
**Priority:** P1  
**Release Scope:** MVP  
**T-shirt Size:** M  
**Project Column:** Product Backlog  
**Business Rank:** 029  
**Labels:** `user-story`, `type:operational-story`, `epic:performance`, `priority:p1`, `scope:mvp`, `size:m`, `status:product-backlog`  
**Milestone:** MVP Release Readiness

## User Story

**As a** Hydrion user  
**I need** local hydration actions and screen transitions to stay responsive  
**So that** daily logging feels immediate and dependable.

## Business Value

Hydration logging is a repeated habit. Sluggish local actions reduce engagement and can cause duplicate taps or uncertainty about whether data was saved.

## Performance Requirements

Local logging, edit, delete, and summary recalculation should avoid unnecessary network calls and heavy provider work.

## Acceptance Criteria

- [ ] Manual logging updates local state without waiting on external provider calls.
- [ ] Editing and deleting records recalculate summaries from local repositories.
- [ ] Opening Analytics with ordinary local data volumes does not block on network activity.
- [ ] Provider fallback or diagnostics do not delay access to Home logging controls.
- [ ] Long provider responses or malformed output are bounded by timeout and fallback behavior.
- [ ] Performance validation includes web and Android build targets where practical.

### HYD-US-049: Maintain Adapter Boundary and Testability

**Story ID:** HYD-US-049  
**Title:** Maintain Adapter Boundary and Testability  
**Epic:** Architecture and Quality  
**Story Type:** Architecture Story  
**Priority:** P0  
**Release Scope:** Supporting  
**T-shirt Size:** L  
**Project Column:** Product Backlog  
**Business Rank:** 016  
**Labels:** `user-story`, `type:architecture-story`, `epic:architecture-quality`, `priority:p0`, `scope:supporting`, `size:l`, `status:product-backlog`  
**Milestone:** MVP AI Provider Safety

## User Story

**As a** Hydrion maintainer  
**I need** UI, repositories, services, and external adapters to stay behind clear boundaries  
**So that** optional integrations can be tested or replaced without destabilizing core hydration flows.

## Business Value

The repo already contains optional provider and future integration scaffolds. Strong boundaries keep the MVP shippable and make future work safer to decompose.

## Business Rules

- UI code should depend on Hydrion domain contracts and services, not provider SDKs or packs.
- External providers produce typed proposals; Hydrion owns validation and execution.
- Test services must be able to swap in memory repositories and fake providers.

## Acceptance Criteria

- [ ] UI code does not import provider SDKs, future packs, or adapter runtime internals.
- [ ] Provider adapters do not directly mutate hydration repositories or UI state.
- [ ] Local, fake, and optional provider implementations can satisfy the same domain contracts.
- [ ] Boundary tests fail when forbidden imports or deprecated wrappers return.
- [ ] Widget tests can run Hydrion with in-memory services.
- [ ] Future adapters must expose capability status before user-facing activation.
- [ ] Architecture notes explain active boundaries versus future scaffolds.

### HYD-US-050: Keep CI and Build Quality Gates Stable

**Story ID:** HYD-US-050  
**Title:** Keep CI and Build Quality Gates Stable  
**Epic:** Architecture and Quality  
**Story Type:** Operational Story  
**Priority:** P1  
**Release Scope:** MVP  
**T-shirt Size:** M  
**Project Column:** Product Backlog  
**Business Rank:** 047  
**Labels:** `user-story`, `type:operational-story`, `epic:architecture-quality`, `priority:p1`, `scope:mvp`, `size:m`, `status:product-backlog`  
**Milestone:** MVP Release Readiness

## User Story

**As a** Hydrion maintainer  
**I need** CI to run analysis, tests, secret checks, and release builds consistently  
**So that** regressions are caught before changes reach the main branches.

## Business Value

Stable quality gates protect the MVP from broken builds, missing localization, provider-safety regressions, and accidental secret commits.

## Acceptance Criteria

- [ ] CI validates the Flutter project root before running build steps.
- [ ] Dependency resolution runs before analysis, tests, and builds.
- [ ] Secret hygiene scanning runs before release artifacts are produced.
- [ ] Static analysis and the full Flutter test suite run on pull requests and mainline pushes.
- [ ] Android APK and web release builds run after the quality gate passes.
- [ ] Coverage and build artifacts are uploaded with failure behavior that does not hide missing outputs.
- [ ] CI version pins for Flutter and Java are documented and intentionally updated.

### HYD-US-051: Prevent Secret Leakage and Unsafe Provider Credentials

**Story ID:** HYD-US-051  
**Title:** Prevent Secret Leakage and Unsafe Provider Credentials  
**Epic:** Security and Provider Safety  
**Story Type:** Security Story  
**Priority:** P0  
**Release Scope:** MVP  
**T-shirt Size:** M  
**Project Column:** Product Backlog  
**Business Rank:** 001  
**Labels:** `user-story`, `type:security-story`, `epic:security-provider-safety`, `priority:p0`, `scope:mvp`, `size:m`, `status:product-backlog`  
**Milestone:** MVP Stabilization

## User Story

**As a** Hydrion maintainer  
**I need** secrets and provider credentials kept out of committed source and user-facing diagnostics  
**So that** optional AI experiments do not create security incidents.

## Business Value

Provider keys can be expensive, sensitive, and unsafe in client artifacts. Secret hygiene is a release blocker because Hydrion includes optional provider configuration and diagnostics.

## Security and Privacy Requirements

Development-only provider keys belong in local environment configuration, not in repository files, issue bodies, diagnostics screenshots, or release artifacts.

## Acceptance Criteria

- [ ] Local secret files and common credential formats are ignored by source control.
- [ ] The secret scan rejects committed API keys and private key blocks.
- [ ] Documented placeholder keys are allowed only when they cannot be used as real credentials.
- [ ] Provider diagnostics display key presence, shape, or partial markers without revealing a full key.
- [ ] Web and Android builds do not require a shared production provider key.
- [ ] CI runs the secret scan before analysis, tests, and release builds.
- [ ] Issue sync and project automation do not write provider secrets into labels, milestones, or issue bodies.
