# Hydrion V1 Regression Recovery Audit

Starting branch: `main`  
Starting HEAD: `c9963dbdaf62d38f3c2ad57a4f62eff84da25337`  
Audit started: 2026-08-14

This ledger compares user-visible behavior, current runtime call paths,
historical source, and executable tests. Historical code is evidence, not a
rollback target.

| Behavior | Historical evidence | Current status | Regression? | Root cause | Fix |
|---|---|---|---|---|---|
| Apply tailored goal updates canonical selected goal | `151c8f8`, `0f58671` | Focused repository and widget tests | Yes | Apply result was ignored by UI | Transactional apply and canonical `dailyGoalMl` retained |
| Body Metrics exits after successful goal acceptance | `0f58671` | Focused widget test passes | Yes | Pop was limited to onboarding entry | Pop after every successful explicit apply |
| Manual edit of an accepted tailored goal requires confirmation | Personalized goal lifecycle | EN/FR/ES dialog tests pass | Yes | Settings and Profile saved immediately | Shared localized confirmation at commit points |
| Tailored association can reset without deleting profile/history | Personalized goal lifecycle | Focused repository test added | No current loss | Existing baseline-source reset lacked explicit proof | Regression coverage added |
| New recommendation never auto-overwrites selected goal | `81e60a8`, `cde2e30` | Coordinator test passes | No | Calculation and apply remain separate | Existing design retained |
| Goal changes refresh Android and iOS widgets | `8900385`, `b5e7c9d` | Service listener and snapshot tests | No | Settings listener already synchronizes both platforms | Existing design retained |
| Permission action displays Enabled after grant | `fdb38bb`, `13cea4b`, `0f58671` | Focused widget test passes | Yes | Granted cards removed the action entirely | Disabled localized Enabled control added |
| Permission state refreshes on app resume | `fdb38bb`, `13cea4b` | Lifecycle observer and permission tests | No | Existing resume refresh is intact | Existing design retained |
| Onboarding Not now does not prompt the OS | `13cea4b` | Consent tests | No | Independent actions remain intact | Existing design retained |
| Explicit app locale is authoritative | Recent localization corrections | Repository tests | No | `AppLocaleRepository` remains authoritative | Existing design retained |
| Locale switch updates UI, notifications, and widgets | Recent localization corrections | Locale and widget service tests | No | Consumers use authoritative repository | Existing design retained |
| Stable IDs, not translated identity strings, are persisted | Localization architecture | Existing repository tests | No | Domain IDs remain locale independent | Existing design retained |
| Responsive viewport and modal behavior | `a107cec` | Full Flutter suite passes | No observed loss | Responsive regression tests remain active | No change |
| Pomodoro persistence and lifecycle | `1376658` | Full Flutter suite passes | No observed loss | Service and UI lifecycle tests remain active | No change |
| Body Metrics persistence and migrations | `c3394a2`, `3b79289` | Full Flutter suite passes | No observed loss | Migration and UI tests remain active | Goal flow only |
| Personalized hydration safety invariants | `81e60a8`, `5558a38`, `cde2e30` | Full Flutter suite passes | Goal UX regressions only | Calculation engine remained intact | No calculation change |
| Wake/sleep pacing remains connected and private | Recent pacing work | Full Flutter suite passes | No observed loss | Pacing tests remain active | No change |
| Profile deletion preserves OS permission ownership | Permission/profile deletion work | Full Flutter suite passes | No observed loss | Reset tests remain active | No change |
| Reminder scheduling and reconciliation | Android/iOS reminder work | Full Flutter suite passes | No observed loss | Scheduling tests remain active | No change |
| Challenge catalogue, progress, history, Pomodoro, Homework | Challenge stabilization work | Full Flutter suite passes | No observed loss | Lifecycle and presentation tests remain active | No change |
| Android widgets remain functional and private | `8900385` | Full suite and artwork audit pass | No observed loss | Canonical snapshot/privacy tests remain active | No change |
| iOS WidgetKit metadata, App Group, and deep links remain valid | `b5e7c9d` and later fixes | Full Flutter suite passes | No observed loss | Configuration/deep-link tests remain active | No change |

## Regression Records

Detailed `REG-*` records will be added only after observable behavioral loss is
proven.

### REG-001: accepted tailored goal did not leave Body Metrics

- Evidence: `_applyRecommendation` only popped when
  `returnToOnboardingAfterApply` was true.
- Impact: users applying from normal Body Metrics remained on a completed form.
- Correction: persistence must return `true`; only then acknowledge and pop.
- Test: `applying a suggestion updates the goal and exits Body Metrics`.

### REG-002: tailored manual override had no confirmation

- Evidence: Settings and Profile called `setDailyGoalMl` directly.
- Impact: an accepted tailored goal could be replaced without a deliberate
  confirmation and its calculated baseline could be overwritten.
- Correction: localized EN/FR/ES confirmation and `updateBaseline: false` while
  the personalized baseline remains associated.
- Tests: `personalized_goal_override_confirmation_test.dart` and coordinator
  baseline-preservation coverage.

### REG-003: granted permission had no Enabled action state

- Evidence: permission actions rendered only for requestable or settings-only
  states.
- Impact: the original Enable action disappeared instead of visibly settling
  into Enabled.
- Correction: granted cards render a disabled localized Enabled control.
- Test: permission-center widget coverage.

## Validation Evidence

- Historical anchors: all 13 requested commits resolve as commits.
- `dart format --output=none --set-exit-if-changed .`: pass, 198 files,
  0 changed.
- `flutter analyze`: pass, no issues.
- `flutter test`: pass, 598 tests.
- Localization audit: 834/834 Flutter messages and 24/24 Android strings in
  EN/FR/ES; no placeholder drift.
- Mixed-language audit: pass, no untranslated EN/FR/ES duplicates.
- Production-string audit: 835/835 reviewed, 0 unresolved.
- Secret scan: pass.
- Artwork audit: pass, 12 challenge PNG files.
- `git diff --check`: pass (line-ending conversion warnings only).
- Behave: not run; Python reports `No module named behave`.
- Android/Web/iOS builds: not run; platform builds remain behind the task's
  explicit storage and approval gate.
- GitHub actions: none performed.
