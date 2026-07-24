---
document_id: privacy
title: Hydrion Privacy Policy
version: 1.0.1
effective_date: 2026-07-06
last_updated: 2026-07-06
intended_display: in_app_and_public
requires_acceptance: false
---

# Hydrion Privacy Policy

**Effective date:** July 6, 2026  
**Last updated:** July 24, 2026
**Version:** 1.0.1

Hydrion is a local-first hydration companion for logging water intake, setting personal goals, using local reminders, reviewing progress, and joining local challenges. This Privacy Policy explains how the current Hydrion app processes information based on the source code, platform manifests, and release configuration in this repository.

Hydrion does not currently provide accounts, authentication, Hydrion-hosted cloud synchronization, advertising, tracking, remote push notifications, HealthKit, Google Fit, Health Connect, contacts access, camera access, microphone access, or Bluetooth access.

For privacy questions, support, or product-owner review, contact: hydrionsharks@gmail.com.

## Summary

- Hydrion stores the main app experience on your device.
- Hydration logs, profile preferences, default avatar choice, reminders, challenges, streaks, achievements, language, units, goals, local profile photo, and legal acknowledgement state are stored locally.
- Weather-informed goals are optional. If you use live weather lookup, approximate foreground location coordinates may be sent to Open-Meteo for that weather request after you choose to continue.
- Hydrion does not store a location history. It may store a weather forecast summary for the local day.
- Hydrion does not sell personal information or use it for advertising.
- Optional non-local AI features are disabled unless configured and the user grants the app-level provider consent shown in the app.
- Local-only information may be removed by in-app controls where available, operating system app-storage controls, or uninstalling the app. Hydrion cannot recover local-only information after it is removed.

## Information Stored Locally

Hydrion may store the following information on your device when you use the app:

- nickname and profile preferences;
- optional age and sex selection used by product logic such as weather-goal eligibility and default lifestyle-art presentation;
- selected default avatar or companion;
- locally selected profile photo, saved as app-local data;
- hydration log entries, including intake amount, timestamp, and source label;
- daily goal, baseline goal, volume unit, container size, and reusable-container preference;
- weather-goal preferences, last weather-goal decision, and a short explanation of the last weather adjustment;
- reminder definitions, reminder messages, enabled state, and local scheduling state;
- challenge state, Bottle Bingo tiles, streaks, achievements, and eco-impact estimates;
- language and other app preferences;
- legal review state, including accepted Terms version, acceptance time, acknowledged Health and Safety Disclaimer version, acknowledgement time, and Privacy Policy version shown;
- permission prompt timestamps used to avoid repeated same-day prompting;
- local storage recovery events used to handle malformed local data safely.

This information is used to run Hydrion features, restore your app state, personalize local summaries, and keep the app from repeatedly asking for the same permission.

## Weather and Location

Weather-informed goals are optional. Enabling weather mode shows an explanation first and does not by itself request location. If you continue to live weather lookup:

- Hydrion may request foreground location permission through the operating system.
- The app asks for low-accuracy current location.
- Latitude and longitude are rounded before the weather request is sent.
- The coordinates are sent to Open-Meteo so Hydrion can retrieve the current daily forecast.
- Hydrion does not intend to retain coordinates or build a location-history trail.
- Hydrion may cache the resulting forecast summary for the local day, including temperature, humidity, condition, provider identifier, and retrieval time.
- Notification permission is separate. It is not required to view an in-app weather recommendation.

If location permission is denied, unavailable, or unsupported, Hydrion keeps manual goal behavior available.

Open-Meteo is an independent third-party weather provider. Your connection to Open-Meteo may reveal network information such as IP address to Open-Meteo and network operators. Open-Meteo's handling of that information is governed by its own terms and privacy practices.

## Profile Photos

If you choose a profile photo from your photo library, Hydrion stores the selected image locally for your profile display. The current app does not upload profile photos to a Hydrion server. You can remove the local profile photo in the profile editor by returning to the default avatar.

Hydrion requests photo-library access only when you choose the photo feature. The operating system may provide its own limited-photo or permission controls.

Hydrion also includes bundled default profile avatars and lifestyle artwork. Your selected profile avatar remains your manual choice. The optional sex selection may choose a default male, female, or neutral lifestyle-art presentation for app surfaces, but Hydrion does not infer sex or gender from your nickname, avatar, photo, device, location, or behavior.

## Reminders and Notifications

Hydrion can create local hydration reminders on supported Android builds. Reminder definitions are stored locally and scheduled through the operating system notification service.

Notification permission is used for hydration reminders. Denying notification permission does not prevent manual hydration tracking. Reminder delivery is not guaranteed because the operating system, battery settings, time zone changes, app suspension, device shutdown, and other factors can delay or prevent notifications.

The current app does not use remote push notification tokens.

## Optional AI Provider Features

Hydrion includes local rule-based coaching by default. The repository also contains an optional Gemini provider adapter. The current app keeps non-local provider transmission disabled unless a provider is configured and the user grants provider privacy consent in the app.

If a non-local provider is enabled, Hydrion may send the hydration context needed for the selected request to that provider. If provider consent is disabled or the provider is not configured, Hydrion falls back to local rules.

## Support Communications

If you email Hydrion or submit feedback through a third-party platform, Hydrion receives whatever you choose to send, such as the email address used for the message, screenshots, logs, device details, or attachments. Do not send passwords, government identifiers, financial information, private medical records, or another person's personal information unless specifically requested through an appropriate secure channel.

Public repository issues or discussions may be visible to others according to the platform's rules.

## What Hydrion Does Not Currently Do

Based on the current repository implementation, Hydrion does not currently:

- create user accounts;
- authenticate users;
- maintain a remote Hydrion database of user hydration data;
- synchronize hydration logs across devices;
- sell personal information;
- serve advertising;
- track users across apps or websites;
- include analytics or crash-reporting SDKs;
- access contacts, camera, microphone, background location, Bluetooth, HealthKit, Google Fit, or Health Connect.

If these practices change, this policy, in-app disclosures, platform permissions, and store declarations must be updated before release.

## Retention, Editing, and Deletion

Local data remains on your device until you change it, delete it through an in-app control, clear app storage, uninstall the app, or the operating system removes it.

Current in-app controls include:

- editing profile details;
- removing the local profile photo;
- editing or deleting hydration log entries;
- changing or disabling reminders;
- changing goal, weather, units, language, reusable-container, and challenge settings;
- restarting guided setup without deleting hydration history.
- deleting the local Hydrion profile, hydration history, reminders,
  challenges, profile photo, and cached weather data.

Because Hydrion currently has no account backend, local-profile deletion is
not remote account deletion. Deleting a profile does not revoke Android
notification or location permissions; those grants remain controlled through
device settings. A newly created local profile reads the installation's real
permission state and does not assume that access has never been granted.
Operating system storage controls, permissions, backup, and uninstall behavior
are controlled by the platform and device.

## Device Backups and Third Parties

Local Hydrion data may be included in device backups or transfer tools controlled by Apple, Google, the device manufacturer, or another backup provider. Those services are governed by their own terms and privacy policies.

Hydrion's third-party dependencies may run code inside the app to provide features such as local storage, local notifications, image picking, location permission, HTTP requests, localization, and UI rendering. The current repository does not include advertising, analytics, or crash-reporting SDKs.

## Security

Hydrion is designed to minimize transmission by keeping the main experience local-first. No app can guarantee absolute security. Local data may be affected by device compromise, shared-device access, backups, operating system behavior, physical access, malware, or user actions.

You are responsible for securing your device, operating system account, backups, and any support information you choose to send.

## Children and Younger Users

Hydrion is a general wellness app and is not designed for unsupervised use by children. The app currently asks for an optional age value for product logic; it does not verify age, create child accounts, or provide child-directed account features.

The product owner must confirm the final store target-audience settings before public release.

## International Processing

Hydrion's main app data is processed on your device. Weather requests to Open-Meteo and user-initiated support communications may be processed outside your country depending on your network, provider infrastructure, email provider, and support platform.

## Changes to This Policy

Hydrion may update this Privacy Policy when the app changes, when store requirements change, or when corrections are needed. Material privacy changes should be reflected in the bundled app documents, store disclosures, and public privacy-policy URL before release.

Minor formatting, spelling, or contact corrections do not require Terms acceptance, but the displayed document version and last-updated date should remain accurate.

## Contact

Privacy and support contact: hydrionsharks@gmail.com.
