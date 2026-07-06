# Hydrion Weather And Notification Permission Flow

Status: implementation-aligned notes for July 6, 2026.

## Product Rule

Weather and notification permissions are independent.

- Location is for live weather lookup.
- Notification permission is for local reminder delivery.
- Manual hydration logging works if either permission is declined.
- In-app weather recommendations do not require notification permission.

## Weather Setup

When the user changes Settings to weather-informed goals, Hydrion first shows a contextual explanation. The copy states that:

- weather can explain a conservative goal adjustment;
- approximate foreground location is needed only for live weather lookup;
- rounded coordinates are sent to Open-Meteo for that request;
- Hydrion does not intend to retain coordinates;
- background location is not used;
- manual goals remain available if location is declined;
- notification permission is separate and only needed for reminders.

After the user confirms, Settings immediately runs weather setup through
`DailyWeatherGoalCoordinator.prepareWeatherMode`:

- request/check approximate foreground location;
- retrieve today's Open-Meteo forecast;
- show temperature, humidity availability, condition, provider/cache source,
  and the bounded goal adjustment;
- enable Weather Mode only when location and forecast succeed and profile
  inputs are eligible;
- leave the app in Manual Mode when permission is denied, location is
  unavailable, profile inputs are incomplete, or the provider fails.

Notification permission is not requested by Weather Mode setup.

## Location Handling

`DailyWeatherGoalCoordinator.evaluate` checks location permission first. If permission is not granted and the call is not allowed to request permission, it returns `locationPermissionRequired`.

When a request is allowed:

- Hydrion records the prompt date locally;
- it avoids repeating the prompt on the same local day;
- denied, permanently denied, disabled service, timeout, and unavailable-coordinate states return safe non-success results;
- app settings remain reachable from Settings for permanent denial recovery.

Only coarse foreground location is declared for v1. No background location is requested.

## Notification Handling

Notification permission is requested from reminder-specific UI. The reminder dialog states that exact delivery is not guaranteed and that manual tracking still works if permission is declined.

Weather evaluation may optionally request notification permission, but notification denial does not block:

- live weather lookup;
- in-app recommendation;
- manual goal mode;
- manual logging.

## Tests

Covered by `test/weather_location_goal_test.dart` and `test/runtime_ux_test.dart`:

- Weather Mode setup fetches a forecast and does not request notifications;
- denied location leaves setup manual and skips lookup;
- no repeated same-day location permission prompt;
- denied and permanently denied location states block lookup safely;
- service disabled, timeout, and unavailable coordinates fall back safely;
- notification denial does not block weather recommendation;
- manual logging survives location denial;
- Settings keeps permissions contextual and separates reminder notifications from weather.
