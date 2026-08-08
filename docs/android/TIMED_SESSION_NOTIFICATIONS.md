# Timed Session Notifications

Hydrion uses an Android ongoing notification for a genuine active Pomodoro Sip
or Homework Hydration timer. It does not run a decorative foreground service.

The persisted challenge/Pomodoro state remains the only timer authority. The
notification receives the canonical completion timestamp or paused remaining
duration and uses Android's countdown chronometer. It never owns a second Dart
or Android timer and never writes hydration or challenge progress.

Each supported challenge has one stable notification ID. Repeated equivalent
updates are suppressed. Running sessions show Pause, Stop, and Open; paused
sessions show Resume, Stop, and Open. Actions launch the exact challenge through
the existing URI dispatch path, where the canonical repository performs the
requested transition. Android removes a running notification at its completion
timeout, and Hydrion cancels it on pause-to-stop, completion, challenge cleanup,
or profile deletion.

This design avoids foreground-service permissions and battery cost. Android may
delay or suppress notification display when notification permission is denied,
and Hydrion does not bypass that choice. Physical verification of the small icon,
screen-lock countdown, actions, and OEM behavior remains mandatory on the
connected Infinix before release acceptance.
