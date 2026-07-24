# Hydrion Store Compliance Matrix

Status: internal owner-review draft. No store questionnaire has been submitted.

This matrix maps the current repository behavior to store-facing declarations. Public store answers must be reviewed against the exact binary and server behavior at submission time.

Official references checked:

- Apple App Store Review Guidelines: https://developer.apple.com/app-store/review/guidelines/
- Apple App Privacy Details: https://developer.apple.com/app-store/app-privacy-details/
- Apple privacy manifests: https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
- Google Play User Data policy: https://support.google.com/googleplay/android-developer/answer/10144311
- Google Play Data safety: https://support.google.com/googleplay/android-developer/answer/10787469
- Google Play Health Content and Services: https://support.google.com/googleplay/android-developer/answer/14738280

## Store Submission Matrix

| Area | Current Hydrion behavior | Proposed declaration | Owner action |
|---|---|---|---|
| App Store privacy-policy URL | Bundled offline Privacy Policy exists. Public URL not verified. | A public privacy-policy URL is still required for store submission. | Publish and verify URL. |
| App Store support URL | In-app support email is `hydrionsharks@gmail.com`. Public support URL not verified. | Support URL still required. | Publish support page or approved contact page. |
| App Store privacy questionnaire | Local-first app; coarse location may be sent to Open-Meteo for weather; support emails are user initiated. | Disclose coarse location for app functionality when weather is used; no tracking; no advertising. | Complete in App Store Connect. |
| iOS privacy manifest | `PrivacyInfo.xcprivacy` declares no tracking and coarse location for app functionality. | Aligns with weather provider transmission. | Recheck before upload. |
| Google Play privacy-policy URL | Bundled offline policy exists. Public URL not verified. | Public URL still required. | Publish and verify URL. |
| Google Play Data Safety | Local-first data; coarse location transmitted to Open-Meteo when weather mode is used; no ads, no sale, no analytics SDK. | Declare location transmission for app functionality as applicable; local-only app data should be reviewed under Google's form instructions. | Complete in Play Console. |
| Location permission | Android coarse foreground location; iOS when-in-use location. No background location. | Approximate foreground location for weather recommendations. | Validate permission prompt copy on real devices. |
| Notifications | Android local notifications and boot receiver support. No remote push tokens. | Local hydration reminders; delivery not guaranteed. | Validate on Android devices and store permission declarations. |
| Photo library | iOS photo-library usage; image picker dependency. No camera. | User-selected profile image stored locally. | Validate iOS limited-photo flow. |
| Advertising | No advertising SDK or ad identifiers in repository. | No ads. | Recheck dependencies before release. |
| Tracking | No tracking SDK; `NSPrivacyTracking=false`. | No tracking. | Recheck SDK inventory before release. |
| Target audience | App asks optional age but does not verify age or provide child accounts. | General wellness target audience requires owner decision. | Set final age/audience settings. |
| Health positioning | General wellness tracker; not medical device; health disclaimer required. | Health and wellness app, no diagnosis/treatment/medical device claim. | Confirm with qualified legal/product review. |
| Third-party SDK disclosures | Flutter plugins for local storage, location, notifications, image picker, localization, HTTP, Markdown. | No analytics, ads, crash reporting, HealthKit, Health Connect, contacts, camera, mic, Bluetooth. | Recheck `pubspec.lock` before submission. |
| Account deletion | No accounts. | Account deletion requirement not applicable to current binary. | Revisit if accounts are added. |
| Data deletion | In-app local-profile deletion removes profile-owned settings, logs, reminders, challenges, profile photo, and weather cache. Android notification and location grants belong to the app installation and are not silently revoked. | Do not claim remote account deletion or automatic platform-permission revocation. | Verify profile reset and permission disclosure on a physical device. |
| Public release | Not performed. | No App Store or Play production release. | Owner approval required. |

## Store Answers That Remain Owner Actions

- Final target audience and age category.
- Public privacy-policy URL.
- Public support URL.
- Store listing copy and screenshots.
- App Store privacy questionnaire.
- Google Play Data Safety form.
- Google Play health/wellness policy classification.
- Google Play content rating.
- Production signing and distribution approvals.

## Notes

The bundled in-app Markdown Privacy Policy is useful for offline access, but it does not replace the public privacy-policy URL expected by store submission flows.
