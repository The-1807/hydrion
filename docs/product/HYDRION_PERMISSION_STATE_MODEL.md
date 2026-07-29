# Hydrion Permission State Model

Platform permission truth is owned by `Permissions`; settings store only prompt
history and Hydrion preferences.

The canonical states are not requested, requesting, granted, approximate or
precise granted, denied, permanently denied, restricted, temporarily
unavailable, unsupported, not required, and unknown.

Permission controls disable duplicate taps while requesting. After a request
or return from system settings, Hydrion refreshes platform truth and changes
the visible card state. The permission center also refreshes on app resume.

Notification access and exact-alarm access are separate. When exact scheduling
is unavailable, approximate reminder scheduling remains the fallback and the
UI must not claim exact delivery.

Weather may be selected but inactive when location is unavailable. Denial does
not disable the standard or manual hydration baseline.
