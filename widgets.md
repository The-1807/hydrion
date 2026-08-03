# Hydrion Widgets and Challenge Notification Visuals

## Purpose

Widgets can make Hydrion useful without requiring the user to open the full
application. They should support quick, private actions and glanceable progress,
not reproduce entire screens.

Hydrion should use the existing challenge visual system consistently:

- Custom challenge artwork remains the main image inside Hydrion.
- The challenge-specific fallback icon, colors, and pattern become the compact
  identity used by widgets and challenge notifications.
- Every challenge keeps its own icon identity. One generic challenge icon must
  not be reused for every challenge.
- Internal audience labels such as `Teen`, `Adult`, and `Universal` must never
  appear in widgets or notifications.

## How Widgets Improve Hydrion

Widgets reduce the distance between intent and action. A user can see progress,
log a familiar amount, or open an active challenge without navigating through
the application.

Useful benefits include:

- Faster hydration logging.
- A visible reminder without sending another notification.
- Easier return to an active challenge.
- Clear daily progress at a glance.
- Better support for routines and accessibility.
- Less pressure to open the app repeatedly.
- Private, local-first information with no account or cloud dependency.

Widgets must remain optional. Hydrion must continue working completely without
them.

## Proposed Widget Areas

### 1. Quick Log

The highest-priority widget.

Display:

- Current daily total and goal.
- Remaining amount or completion state.
- Two or three user-configured serving amounts.
- A button that opens Hydrion for a custom amount.

Behavior:

- Logging must use the existing hydration repository.
- Repeated taps must remain idempotent.
- The widget must refresh Home, History, Analytics, and eligible challenge
  progress from the same saved log.
- The widget must never invent hydration from a reminder or challenge check-in.

Recommended sizes:

- Small: progress and one primary quick-add action.
- Medium: progress and up to three quick-add actions.

### 2. Daily Progress

Display:

- Current intake.
- Daily goal.
- Progress ring or bar.
- A short state such as `650 ml remaining` or `Goal reached`.

This widget is primarily glanceable. Its main tap opens Home.

It must respect the selected volume unit, clinician target, fluid-restriction
behavior, and the currently applied daily goal.

### 3. Active Challenge

Display:

- The active challenge's fallback icon identity.
- Localized challenge title.
- Concise current task or progress.
- One relevant action: `Continue`, `Check in`, or `Open timer`.

Do not display:

- Audience classification.
- Internal category.
- Eligibility reason.
- Challenge ID.
- Repository or persistence state.

If two challenges are active, a medium widget may show both in a compact list.
A small widget should show the most recently used active challenge.

### 4. Pomodoro Sip

A focused widget for an active Pomodoro Sip session.

Display:

- Timer state and remaining time.
- Pomodoro Sip icon identity.
- Pause or resume action where platform behavior permits.
- Open-app action for completing or confirming a drink.

The widget must consume the same persisted timer snapshot as the application.
It must not run a separate timer or create hydration automatically.

### 5. Bottle Bingo

Display:

- Bottle Bingo icon identity.
- Completed tile and line counts.
- A compact five-by-five progress representation on medium or large widgets.
- An action that opens the live board.

The widget should not attempt to place full tile instructions into a small
surface.

### 6. Next Reminder

Display:

- Next enabled reminder time.
- Short reminder title.
- Open-reminders action.

The widget must distinguish between an app reminder definition and confirmed
Android delivery. It must not claim that delivery is guaranteed.

### 7. Daily Goal Review

Display only when there is useful user action:

- Current applied goal.
- A pending weather-informed or personalized recommendation.
- `Review` action that opens the existing explanation and consent flow.

The widget must never apply a recommendation automatically. Fluid restriction
and clinician-target safeguards remain authoritative.

### 8. History Snapshot

Lower priority.

Display:

- Recent daily totals or a seven-day compact trend.
- Selected volume unit.
- Tap to open Progress or Analytics.

Avoid dense charts, tiny labels, or private profile details.

## Recommended Delivery Order

1. Quick Log.
2. Daily Progress.
3. Active Challenge.
4. Pomodoro Sip.
5. Bottle Bingo.
6. Next Reminder.
7. Daily Goal Review.
8. History Snapshot.

Quick Log, Daily Progress, and Active Challenge provide the strongest value for
the least surface complexity.

## Challenge Notification Identity

The icon-and-color fallback system should become the notification identity for
each challenge. Examples include:

- Lunch Break Refill: lunch icon.
- Homework Hydration: book icon.
- After-School Recharge: battery/recharge icon.
- Backpack Bottle Check: backpack icon.
- Desk-Day Reset: chair/break icon.
- Shift Hydration Check: schedule icon.
- Commute Cup: travel icon.
- Evening Goal Review: evening icon.

Notification content should include:

- Challenge-specific compact visual identity.
- Localized challenge title.
- One short useful message.
- One direct action when supported.

Example:

**Lunch Break Refill**

`Ready for a quick bottle check?`

Action: `Open challenge`

Notifications must not include audience labels, internal categories, IDs,
reason codes, raw enum values, or technical delivery state.

## Android Notification Icon Constraint

Android notification small icons are not ordinary full-color images. They must
be purpose-built monochrome drawable resources with transparency. Android
applies the notification accent color and may render an unsuitable bitmap as a
solid or invisible shape.

Implementation must therefore use:

- A compliant monochrome small-notification icon for each challenge icon
  family, or a compliant Hydrion small icon when per-challenge small icons are
  unavailable.
- The challenge-specific fallback colors and composition as a large icon,
  expanded notification visual, or widget visual where Android supports it.
- The user's custom challenge artwork inside Hydrion, not as an Android small
  notification icon.

Do not generate Android resources at runtime. The required monochrome
notification drawables must be checked into the Android resource folders and
registered through the notification service.

## Widget Visual Rules

- Reuse the challenge fallback identity rather than unrelated stock artwork.
- Keep every challenge visually distinct.
- Use custom challenge artwork only where the widget has enough space and the
  artwork remains readable.
- Prefer the compact fallback icon for small widgets.
- Do not bake text into images.
- Support light and dark system themes.
- Maintain readable contrast.
- Support large text without clipping.
- Never place decorative imagery behind essential numbers or actions.
- Keep user information private in widget previews and locked-device contexts.

## Data and Update Rules

Widgets must read from the same persisted sources as Hydrion:

- Hydration repository for logs and totals.
- Settings repository for goal and volume unit.
- Challenge repository for active state and progress.
- Reminder repository for the next reminder.
- Personalization and daily-context repositories for reviewable suggestions.

Updates should be requested after:

- Hydration is logged, edited, deleted, or undone.
- The daily goal changes.
- The local date rolls over.
- A challenge is joined, paused, resumed, completed, or left.
- A challenge check-in changes progress.
- A Pomodoro session changes state.
- A reminder changes.
- The selected volume unit or language changes.

Widgets must tolerate stale platform snapshots and refresh safely when Hydrion
next opens.

## Accessibility and Privacy

- Every widget action needs a clear accessibility label.
- Announce useful state, not decorative artwork.
- Do not expose pregnancy, lactation, sex, age, BMI, clinician status, fluid
  restriction, or eligibility classifications on a home or lock-screen widget.
- Do not expose private challenge history in widget previews.
- Provide a privacy-safe placeholder while the device is locked when supported.
- Respect reduced motion and platform text scaling.

## Platform Architecture

Flutter does not render Android and iOS home-screen widgets directly as normal
Flutter widgets. They require platform widget implementations and a data bridge.

Expected implementation areas:

- Android App Widget or Jetpack Glance receiver and layouts.
- iOS WidgetKit extension if iOS widgets are included later.
- Shared serialized widget snapshot produced by Flutter.
- Platform channels or an established widget bridge package.
- Notification resource registry mapping challenge IDs to compliant Android
  drawable names.
- Widget refresh coordinator called after repository mutations.

No package or dependency should be added until the platform approach is
reviewed against the repository's current Flutter and Android versions.

## Acceptance Criteria

- Existing custom challenge artwork remains active inside Hydrion.
- All 14 challenges have distinct icon identities.
- The eight pending challenge images can be added without changing widget or
  notification identity.
- Quick logging updates the same canonical hydration data as the application.
- Challenge notifications use the correct challenge identity.
- No audience or internal metadata appears in any widget or notification.
- Android small notification icons comply with monochrome drawable rules.
- Widgets remain useful in light, dark, narrow, and large-text configurations.
- Hydrion remains fully functional when no widget is installed.
