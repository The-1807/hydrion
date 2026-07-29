# Hydrion Interaction Consistency Audit

Audit scope: all 15 production screens, application routes, dialogs, sheets,
menus, onboarding actions, profile deletion, permissions, reminder editors,
weather decisions, challenge joins and lifecycle actions, legal review, log
editing, and settings controls.

## Action inventory

| Surface | Controls | Classification | Completion and restart contract | Protection |
| --- | --- | --- | --- | --- |
| Startup/onboarding | Back, Continue, profile fields, avatar, baseline, hydration setup, permissions, legal review, Start | Draft editor; system permission; navigation | Completed steps persist; nested Body Metrics reads the saved completed profile step; legal consent commits only at completion | Onboarding and persistence tests |
| Profile/Body Metrics | Edit, Cancel, Save, measurement and personalization editors | Draft editor | Cancel discards draft; save persists and returns or restores readable summary | Body metrics and profile UI tests |
| Home/Log/Analytics | Add, edit, delete, filters, history navigation | Navigation; draft editor; destructive | Repository result changes the visible list/summary; destructive actions confirm | Hydration and responsive tests |
| Settings | Theme, language, goal, container, permissions, legal, delete profile | Immediate local; draft; destructive; navigation | Immediate settings update visible summary; editors return; deletion confirms and clears local state | Persistence and reset tests |
| Reminders | Permission, create/edit/delete, exact-alarm settings | System permission; draft; destructive | Request visibly loads and reconciles; editor saves once; denial retains usable fallback | Permission and reminder tests |
| Permission center | Allow, open settings, refresh, continue | System permission; external settings | Duplicate taps disabled; result refreshes card; resume refreshes external changes | Permission tests |
| Challenges | Recommendation, details, Join, pause/leave, progress actions, preferences | Navigation; explicit participation; draft; destructive | Details never auto-join; repository rechecks eligibility and active limit; explicit check-ins persist | Challenge eligibility and regression tests |
| Legal/About | Document navigation and acknowledgement | Read-only summary; immediate local | Current versions and acknowledgement time persist | Legal tests |

## Findings and resolutions

- Age boundaries were implicit. They are now centralized and tested.
- Challenge eligibility existed only as catalog visibility. Repository joins now
  reject ineligible direct calls.
- Weather was presented as a baseline mode. Current product behavior treats it
  as an optional modifier and migrates the legacy mode.
- Body Metrics could read an older age from the repository. Entering it from
  onboarding now validates and persists the completed Basic Profile step first.
- Permission actions lacked a per-control requesting acknowledgement. The
  permission center and onboarding controls now show progress and block repeats.
- Platform permission truth is refreshed after actions and on resume.

## Remaining conventions

All multi-control editors use Cancel and Save changes. Immediate settings must
change their summary in place. Destructive actions require confirmation.
External-settings actions must refresh on resume. Success cannot exist only in
a snackbar; the source summary or card must visibly change.
