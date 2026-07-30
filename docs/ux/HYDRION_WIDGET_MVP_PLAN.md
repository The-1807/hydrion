# Hydrion Android Widget MVP

## Included

### Daily Progress

A small Android home-screen widget shows today's total, current goal, percentage, status, and a progress bar.

### Quick Log + Progress

A medium Android home-screen widget adds one quick-log action. It uses the saved reusable-container amount when enabled and otherwise uses 250 ml. The action enters Hydrion through the existing hydration repository. Repeated taps against the same widget state share an action id and are deduplicated.

Both widgets use `home_widget` for the Flutter/native bridge and native `RemoteViews` for reliable Android rendering. Data remains local. Widgets never expose BMI, age, reproductive state, clinical targets, restrictions, eligibility metadata, or internal identifiers.

## Notification Icon Decision

Full challenge illustrations depend on color and detail and are unsuitable for Android's monochrome small-icon mask. Hydrion therefore keeps a compliant system small icon. The Pomodoro Sip notification may use its dedicated monochrome timer vector because it remains legible under Android masking. Challenge identity otherwise belongs in notification title/body and the destination screen.

## Physical Android Checklist

- Add both widgets from the launcher picker.
- Verify small and medium layouts at minimum and expanded sizes.
- Verify light/dark launcher backgrounds and large system font.
- Log in-app and confirm both widgets refresh.
- Tap Quick Log twice rapidly and confirm only one immediate entry.
- Wait for refresh, tap again, and confirm a later intentional entry.
- Trigger Pomodoro completion and inspect its small icon in collapsed and expanded notification views.
- Verify tapping widget content opens Hydrion.
