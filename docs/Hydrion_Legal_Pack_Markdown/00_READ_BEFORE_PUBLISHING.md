---
document_id: internal_publish_note
title: Read Before Publishing
version: 1.0.0
effective_date: 2026-07-06
last_updated: 2026-07-06
intended_display: internal_only
---

# Read Before Publishing

This file is an internal owner-review note. It must not appear in the in-app Legal menu or be used as public legal copy.

## Repository-Grounded Assumptions

The legal documents in this folder were rewritten for the current Hydrion repository state on July 6, 2026.

Current implementation evidence supports these assumptions:

- Hydrion is local-first and stores the main experience on the device.
- The Android application id and iOS bundle id are `com.the1807.hydrion`.
- The app has no account creation, authentication, Hydrion-hosted remote database, cloud sync, advertising SDK, analytics SDK, crash-reporting SDK, remote push token, HealthKit, Google Fit, Health Connect, contacts, camera, microphone, Bluetooth, or background location integration.
- Android declares internet, coarse location, notification, and boot-completed permissions.
- iOS declares foreground location and photo-library usage text.
- Weather-informed goals use approximate foreground location and send rounded coordinates to Open-Meteo for a forecast request.
- Profile photos are selected from the photo library and stored locally.
- Reminders are local Android notifications where supported.
- Gemini provider code exists but non-local AI transmission is disabled unless configured and app-level provider consent is granted.
- The public privacy-policy URL, support URL, final target audience, owner legal entity, business address, and governing law have not been verified in this repository.

## Owner Decisions Still Required

Before public store submission, the owner must decide and document:

- public privacy-policy URL;
- public support URL;
- final app-store target audience and age settings;
- legal operator identity if a company or registered owner must be displayed publicly;
- governing-law language if legal counsel recommends it;
- production Android signing credentials;
- Apple Developer Team, App Store Connect API integration, signing certificate, provisioning profile, and app record;
- whether TestFlight upload should be manual artifact download or Codemagic publishing;
- whether any future cloud sync, accounts, analytics, crash reporting, advertising, subscriptions, health integrations, wearable integrations, or AI providers will be added.

## Publication Guardrail

Do not describe the bundled Markdown files as legally approved. They are implementation-aligned drafts that require owner and qualified legal review before public release.

Public store questionnaires must match the shipped binary, active SDKs, platform permissions, and any server-side behavior at release time.
