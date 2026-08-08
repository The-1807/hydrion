# Hydrion Android Active Challenge Widget

## Included

Hydrion ships one state-driven Android home-screen widget for the current
active challenge. It reads the canonical persisted challenge record and shows:

- the challenge title;
- a concise active, paused, available, or completed state;
- today's deliberate checkpoint progress where applicable;
- one action that opens the exact challenge activity.

When there is no active challenge, the widget offers a privacy-safe route to
the challenge list. Refreshing or tapping the widget never records challenge
progress and never creates a hydration log.

The widget uses `home_widget` for the Flutter/native bridge and Android
`RemoteViews` for launcher rendering. It has no independent progress database.
Snapshots exclude age, sex, pregnancy, BMI, clinical targets, restrictions,
hydration totals, and eligibility metadata.

## Visual And Accessibility Rules

- Use a compact Hydrion challenge presentation rather than detailed hero art.
- Maintain readable light and dark colors.
- Allow title and state text to wrap without clipping.
- Keep the action target at least 44 dp high.
- Give the action a clear TalkBack description.
- Use a privacy-safe preview and tolerate stale snapshots.

## Physical Android Checklist

- Add Active Challenge from the launcher picker.
- Verify empty, active, paused, and completed-day states.
- Verify small and expanded launcher sizes and large system font.
- Complete a checkpoint in-app and confirm the widget refreshes.
- Tap the widget and confirm the exact challenge opens.
- Confirm widget refresh and navigation create no progress or hydration log.
