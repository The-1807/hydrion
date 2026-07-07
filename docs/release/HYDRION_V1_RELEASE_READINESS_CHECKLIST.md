# Hydrion V1 Release Readiness Checklist

> Hydrion V1 must not be released until every release-blocking requirement has been validated.
>
> A checked item must represent confirmed implementation and testing, not planned work or assumed behavior.

## Document Control

- **Product:** Hydrion
- **Release:** V1
- **Release type:** Minimum Viable Product
- **Platforms:** Android and iOS
- **Status:** Not Ready
- **Last reviewed:** 2026-07-07
- **Release candidate:** Not assigned
- **Release commit:** Not assigned
- **Android artifact:** Not assigned
- **iOS artifact:** Not assigned

## Release Status

- [x] Not Ready
- [ ] Ready for Internal Testing
- [ ] Ready for Closed Testing
- [ ] Ready for Open Testing
- [ ] Ready for V1 Production Release

---

# 1. Product Scope

- [ ] V1 scope is documented and frozen.
- [ ] Every V1 feature is linked to an approved user story, acceptance criterion, defect, or release requirement.
- [ ] Features not required for V1 are moved to the backlog or icebox.
- [ ] No unfinished feature is exposed as functional.
- [ ] V1.1 preview items are clearly marked as Coming Soon.
- [ ] No V1.1 feature request is delaying the V1 release.
- [ ] Product backlog, repository state, milestone, and Kanban board reflect the same release scope.
- [ ] Every V1 screen supports a required product journey.
- [ ] Decorative refinement is no longer delaying release work.
- [ ] The release scope has been reviewed against the implemented application.

# 2. Core User Journey

- [ ] A new user can install and launch Hydrion.
- [ ] A new user can complete onboarding.
- [ ] A new user can understand their hydration goal.
- [ ] A new user can log water.
- [ ] A new user can immediately see updated progress.
- [ ] A returning user can view existing hydration history.
- [ ] A returning user can edit an incorrect hydration record.
- [ ] A returning user can delete an incorrect hydration record.
- [ ] A user can configure reminders.
- [ ] A user can review hydration progress.
- [ ] A user can change settings.
- [ ] A user can access legal documents.
- [ ] The complete core journey works without internet access, except features that explicitly require internet access.

# 3. Onboarding

- [ ] New users can complete onboarding without confusion.
- [ ] Onboarding collects only information required for the hydration experience.
- [ ] Users can select their preferred measurement unit.
- [ ] Users can enter or confirm their hydration goal.
- [ ] The app explains how the hydration goal is determined.
- [ ] Users can skip optional onboarding steps.
- [ ] Users can change onboarding-related settings later.
- [ ] Health and wellness limitations are disclosed.
- [ ] Privacy Policy is accessible during onboarding.
- [ ] Terms of Use are accessible during onboarding.
- [ ] Health and Wellness Disclaimer is accessible during onboarding.
- [ ] Alpha or Beta Notice is shown when applicable.
- [x] Onboarding works correctly after a fresh installation.
- [x] Onboarding does not repeat after successful completion.
- [ ] Onboarding restarts only after intentional application data reset.
- [x] Onboarding state persists after the application is closed.
- [ ] Onboarding displays correctly on supported Android screen sizes.
- [ ] Onboarding displays correctly on supported iPhone screen sizes.

# 4. Hydration Logging

- [ ] Users can log water from the main screen.
- [ ] Common serving sizes are available.
- [ ] Users can enter a custom quantity.
- [ ] Logged water updates the daily total immediately.
- [ ] Logged water updates the daily percentage immediately.
- [ ] Logged water updates the remaining amount immediately.
- [ ] Users can edit an existing hydration record.
- [ ] Users can delete an existing hydration record.
- [ ] Users can undo an accidental hydration entry.
- [ ] Invalid quantities are rejected.
- [ ] Zero-value entries are rejected.
- [ ] Negative entries are rejected.
- [ ] Excessively large entries are handled safely.
- [ ] Duplicate taps do not create unintended duplicate records.
- [ ] Hydration logs remain available after closing and reopening the application.
- [ ] Hydration logs remain available after restarting the device.
- [ ] Hydration logging works without internet access.
- [ ] Date and time values are stored correctly.
- [ ] Date and time values are displayed correctly.
- [ ] Logging works correctly around midnight.
- [ ] Logging works correctly during day rollover.
- [ ] Editing a record updates all dependent calculations.
- [ ] Deleting a record updates all dependent calculations.
- [ ] Logging above the daily target does not break progress displays.
- [ ] Logging remains responsive during repeated use.

# 5. Home Screen

- [ ] The home screen clearly displays current intake.
- [ ] The home screen clearly displays the daily goal.
- [ ] The home screen clearly displays the remaining amount.
- [ ] The home screen clearly displays completion percentage.
- [ ] The progress visualization matches the actual logged amount.
- [ ] Quick-add controls are easy to identify.
- [ ] The current hydration status is understandable.
- [ ] The hydration score is understandable.
- [ ] The current streak is displayed correctly.
- [ ] The next recommended hydration action is displayed correctly.
- [ ] The home screen handles zero hydration records correctly.
- [ ] The home screen handles a completed daily goal correctly.
- [ ] The home screen handles intake above the daily goal correctly.
- [ ] The home screen does not appear overcrowded.
- [ ] Essential controls are reachable without unnecessary navigation.
- [ ] Decorative animation does not block interaction.
- [ ] No loading state remains visible indefinitely.
- [ ] No placeholder data appears.
- [ ] No fake data appears.
- [ ] Home screen state remains correct after returning from another screen.
- [ ] Home screen state remains correct after application restoration.

# 6. Daily Goal

- [ ] Users can view their active daily hydration goal.
- [ ] Users can manually change their hydration goal.
- [ ] Goal changes persist after restarting the application.
- [ ] Goal changes update progress calculations immediately.
- [ ] Goal calculations use the selected measurement unit correctly.
- [ ] Goal adjustment limits are documented.
- [ ] Goal adjustment limits are enforced.
- [ ] Goal calculations remain consistent across Android and iOS.
- [ ] The app does not present hydration goals as medical prescriptions.
- [ ] The app does not present medical recommendations as medical advice.
- [ ] Goal changes do not delete or corrupt existing history.

# 7. Weather Mode

- [ ] Weather Mode starts only after explicit user action.
- [ ] Weather Mode requests location permission only when the user enables it.
- [ ] Weather Mode checks the current permission state correctly.
- [ ] Weather Mode retrieves the current forecast successfully.
- [ ] Weather Mode displays the forecast used for adjustment.
- [ ] Weather Mode displays the bounded goal adjustment.
- [ ] Weather Mode enables only after successful setup.
- [ ] Weather Mode fails safely when location permission is denied.
- [ ] Weather Mode fails safely when location services are disabled.
- [ ] Weather Mode fails safely when forecast retrieval fails.
- [ ] Weather Mode does not silently modify the goal.
- [ ] Weather Mode clearly explains any goal adjustment.
- [ ] Notification permission remains independent from Weather Mode.
- [ ] Weather Mode does not create repeated network request loops.
- [ ] Weather Mode behaves correctly after restarting the application.
- [ ] Weather Mode behaves correctly after changing location permission.
- [ ] Weather Mode behaves correctly on Android.
- [ ] Weather Mode behaves correctly on iOS.

# 8. Reminders and Notifications

- [ ] Users can enable reminders.
- [ ] Users can disable reminders.
- [ ] Users can create reminder times.
- [ ] Users can edit reminder times.
- [ ] Users can delete reminder times.
- [ ] Users can configure reminder frequency.
- [ ] Users can define quiet hours.
- [ ] Users can pause reminders.
- [ ] Reminder settings persist after restarting the application.
- [ ] Notification permission is requested only when required.
- [ ] Notification permission denial is handled clearly.
- [ ] Users can continue using the application without granting notification permission.
- [ ] Notifications appear at the configured time.
- [ ] Notifications do not appear during quiet hours.
- [ ] Duplicate notifications are not generated.
- [ ] Deleted reminders no longer generate notifications.
- [ ] Disabled reminders no longer generate notifications.
- [ ] Reminder behavior after completing the daily goal is confirmed.
- [ ] Reminder behavior after restarting the device is confirmed.
- [ ] Notification text is localized correctly.
- [ ] Notification actions open the correct application screen.
- [ ] Notifications do not expose unnecessary personal information.
- [ ] Android notification scheduling is confirmed.
- [ ] iOS notification scheduling is confirmed.
- [ ] Android notification cancellation is confirmed.
- [ ] iOS notification cancellation is confirmed.

# 9. History

- [ ] Users can view daily hydration history.
- [ ] History is ordered correctly.
- [ ] Each record displays the correct quantity.
- [ ] Each record displays the correct date.
- [ ] Each record displays the correct time.
- [ ] Edited records display updated values.
- [ ] Deleted records disappear from history.
- [ ] Empty history displays a helpful empty state.
- [ ] Long history lists scroll smoothly.
- [ ] History remains available offline.
- [ ] History remains available after an application update.
- [ ] History does not reset after changing language.
- [ ] History does not reset after changing theme.
- [ ] History calculations remain correct across time zones.
- [ ] History remains correct after midnight rollover.
- [ ] History remains consistent across Android and iOS.

# 10. Analytics and Progress

- [ ] Seven-day hydration trends are calculated correctly.
- [ ] Average daily intake is calculated correctly.
- [ ] Daily completion rate is calculated correctly.
- [ ] Current streak is calculated correctly.
- [ ] Best streak is calculated correctly.
- [ ] Hydration score is calculated consistently.
- [ ] Analytics update immediately after logging water.
- [ ] Analytics update immediately after editing a log.
- [ ] Analytics update immediately after deleting a log.
- [ ] Analytics handle missing days correctly.
- [ ] Analytics handle partial days correctly.
- [ ] Analytics handle goal changes correctly.
- [ ] Charts display correctly on small screens.
- [ ] Charts display correctly on large screens.
- [ ] Empty analytics states are clear.
- [ ] Analytics do not imply medical diagnosis.
- [ ] Analytics do not imply medical treatment.
- [ ] Analytics calculations remain consistent across Android and iOS.

# 11. Streaks

- [ ] Streak rules are documented.
- [ ] Current streak calculations are correct.
- [ ] Best streak calculations are correct.
- [ ] Streaks reset only under documented conditions.
- [ ] Streaks persist after restarting the application.
- [ ] Streaks handle missed days correctly.
- [ ] Streaks handle goal changes correctly.
- [ ] Streaks handle time-zone changes correctly.
- [ ] Streak calculations remain consistent across Android and iOS.

# 12. Achievements

- [ ] Achievement rules are documented.
- [ ] Achievements unlock under the correct conditions.
- [ ] Achievements do not unlock more than once unless designed to repeat.
- [ ] Achievement progress persists after restarting the application.
- [ ] Achievement notifications do not interrupt essential actions.
- [ ] Completed achievements remain completed.
- [ ] Incomplete achievements do not display as completed.
- [ ] Achievement calculations remain consistent across Android and iOS.

# 13. Challenges

- [ ] Challenges have clear objectives.
- [ ] Challenge requirements are understandable.
- [ ] Challenge progress is calculated correctly.
- [ ] Completed challenges remain visibly completed.
- [ ] Incomplete challenges do not display as completed.
- [ ] Challenge progress persists after restarting the application.
- [ ] No social challenge feature is presented as active unless implemented.
- [ ] No leaderboard is presented as active unless implemented.
- [ ] Challenge behavior remains consistent across Android and iOS.

# 14. Eco Impact

- [ ] Eco impact calculations are documented.
- [ ] Eco impact values are tied to actual user activity.
- [ ] Eco impact does not use fabricated data.
- [ ] Eco impact assumptions are clearly stated.
- [ ] Eco impact displays correctly for new users.
- [ ] Eco impact updates after qualifying hydration logs.
- [ ] Eco impact works correctly across measurement units.
- [ ] Eco impact language avoids unsupported environmental claims.
- [ ] Eco impact calculations remain consistent across Android and iOS.

# 15. Profile and Avatars

- [ ] Users can select a profile avatar.
- [ ] All runtime avatars are licensed, original, or approved for use.
- [ ] Removed human avatar assets are not referenced at runtime.
- [x] Legacy removed avatar IDs migrate safely.
- [x] The fallback avatar works correctly.
- [ ] Avatar images display correctly on all required screens.
- [ ] Avatar assets are optimized for mobile.
- [ ] Missing avatar files do not crash the application.
- [ ] Profile changes persist after restarting the application.
- [ ] Profile information can be edited.
- [ ] Profile information does not expose unnecessary personal data.
- [ ] Avatar presentation is consistent across Android and iOS.

# 16. Settings

- [ ] All settings are grouped logically.
- [ ] Users can change measurement units.
- [ ] Unit changes update displayed values correctly.
- [ ] Users can change language.
- [ ] Users can change theme when supported.
- [ ] Users can configure reminders.
- [ ] Users can configure Weather Mode.
- [ ] Users can access legal documents.
- [ ] Users can view the application version.
- [ ] Users can reset local application data.
- [ ] Reset actions require confirmation.
- [ ] Settings persist after restarting the application.
- [ ] No setting appears functional when it is not implemented.
- [ ] Settings remain consistent across Android and iOS.

# 17. Connected Devices Coming Soon

- [ ] Connected Devices is clearly marked Coming Soon.
- [ ] Connected Devices performs no Bluetooth scanning.
- [ ] Connected Devices performs no smart-bottle connection attempts.
- [ ] Connected Devices performs no wearable reads.
- [ ] Connected Devices performs no HealthKit reads.
- [ ] Connected Devices performs no Health Connect reads.
- [ ] Connected Devices requests no permissions in V1.
- [ ] Connected Devices displays no fake device information.
- [ ] Connected Devices does not appear as an active V1 feature.
- [ ] Connected Devices does not block or interrupt core hydration actions.

# 18. Localization

- [ ] English localization is complete.
- [ ] French localization is complete.
- [ ] Spanish localization is complete.
- [ ] No untranslated localization keys are visible.
- [ ] No hardcoded user-facing strings remain outside the localization system.
- [ ] Text fits correctly in English.
- [ ] Text fits correctly in French.
- [ ] Text fits correctly in Spanish.
- [ ] Buttons remain readable in all supported languages.
- [ ] Navigation labels remain readable in all supported languages.
- [ ] Error messages are localized.
- [ ] Empty states are localized.
- [ ] Notification text is localized.
- [ ] Legal document navigation is localized.
- [ ] Measurement formatting follows the selected unit.
- [ ] Dates display appropriately for the selected locale.
- [ ] Times display appropriately for the selected locale.
- [ ] Localization behaves consistently across Android and iOS.

# 19. Accessibility

- [ ] Text contrast meets acceptable accessibility standards.
- [ ] Important information is not communicated through color alone.
- [ ] Buttons have sufficient touch-target sizes.
- [ ] Interactive controls have accessibility labels.
- [ ] Images with meaning have accessibility descriptions.
- [ ] Decorative images are excluded from screen-reader navigation.
- [ ] Screen-reader navigation follows a logical order.
- [ ] Text remains usable with increased system font size.
- [ ] Layouts remain usable with increased system font size.
- [ ] Essential actions are keyboard accessible where applicable.
- [x] Animations respect reduced-motion preferences where supported.
- [ ] Error states are announced accessibly.
- [ ] Forms identify invalid fields clearly.
- [ ] Accessibility behavior is validated on Android.
- [ ] Accessibility behavior is validated on iOS.

# 20. UI and UX Quality

- [ ] Every V1 screen has a confirmed design state.
- [ ] Loading states are implemented.
- [ ] Empty states are implemented.
- [ ] Error states are implemented.
- [ ] Permission-denied states are implemented.
- [ ] Offline states are implemented where relevant.
- [ ] Navigation is consistent.
- [ ] Back navigation behaves correctly.
- [ ] No dead-end screen exists.
- [ ] No button leads to an unfinished screen without explanation.
- [ ] No visual element overlaps another element.
- [ ] No text is clipped.
- [ ] No content extends beyond safe screen boundaries.
- [ ] The keyboard does not cover active input fields.
- [ ] Dialogs can be dismissed safely.
- [ ] Destructive actions require confirmation where appropriate.
- [ ] Success feedback is visible without being disruptive.
- [ ] Animations remain smooth on supported devices.
- [ ] Legal Markdown typography is readable on mobile.
- [x] Startup does not wait for an artificial splash delay.
- [x] Startup routing occurs after actual initialization.
- [ ] Visual refinement does not compromise performance.
- [ ] Visual refinement does not compromise usability.
- [ ] UI behavior remains coherent across Android and iOS.

# 21. Navigation

- [ ] Every navigation route opens correctly.
- [ ] Removed AR routes no longer exist.
- [ ] Removed AR localization keys no longer exist.
- [ ] Removed AR assets no longer exist at runtime.
- [ ] Removed AR tests no longer remain active.
- [ ] Deep links do not open invalid screens.
- [ ] Notification taps open the intended screen.
- [ ] Back navigation does not exit unexpectedly.
- [ ] Navigation state behaves correctly after application restoration.
- [ ] Navigation works correctly after language changes.
- [ ] Navigation works correctly after theme changes.
- [ ] Navigation works correctly after onboarding completion.
- [ ] Android back navigation is correct.
- [ ] iOS swipe-back navigation is correct.

# 22. Offline and Local Data

- [ ] Core hydration logging works offline.
- [ ] History works offline.
- [ ] Analytics work offline.
- [ ] Reminders work without an internet connection.
- [ ] Profile settings work offline.
- [ ] Local data persists after restarting the application.
- [ ] Local data persists after restarting the device.
- [ ] Local data survives a normal application update.
- [ ] Data migrations are tested.
- [ ] Existing storage keys remain compatible or migrate safely.
- [ ] Corrupt local data is handled without crashing.
- [ ] Resetting local data removes only the intended records.
- [ ] No cloud synchronization is implied when it does not exist.
- [ ] No account recovery is implied when data is stored only locally.
- [ ] Android local-storage behavior is confirmed.
- [ ] iOS local-storage behavior is confirmed.

# 23. Privacy, Safety, and Legal

- [ ] Privacy Policy is complete.
- [ ] Terms of Use are complete.
- [ ] Health and Wellness Disclaimer is complete.
- [ ] Alpha or Beta Notice is complete where applicable.
- [ ] Legal documents display correctly on Android.
- [ ] Legal documents display correctly on iOS.
- [ ] Legal documents are accessible from Settings.
- [ ] Legal documents are accessible during onboarding where required.
- [ ] Location permission is explained before the system prompt.
- [ ] Notification permission is explained before the system prompt.
- [ ] No unnecessary permission is requested.
- [ ] No health claim is presented as medical advice.
- [ ] No feature claims to diagnose dehydration.
- [ ] No feature claims to prevent a medical condition.
- [ ] No feature claims to treat a medical condition.
- [ ] Data collection matches the Privacy Policy.
- [ ] App-store privacy declarations match actual application behavior.
- [ ] No personal data is silently transmitted.
- [ ] No analytics SDK is active without disclosure.
- [ ] No tracking SDK is active without disclosure.
- [x] No production secrets are included in the repository scan.
- [x] No test credentials are included in the repository scan.
- [x] The permanent LottieFiles share URL for the shark loading animation is stored.
- [x] The shark loading animation usage is documented in THIRD_PARTY_NOTICES.md.
- [ ] Creator identity is documented, if visible and applicable.
- [ ] Displayed animation-specific licence evidence is stored, if available.
- [ ] The shark animation is approved for production use.

# 24. Android Compatibility

- [ ] The application builds successfully for Android.
- [ ] The Android debug build succeeds.
- [ ] The Android release APK builds successfully.
- [ ] The Android App Bundle builds successfully.
- [ ] The Android package identifier is final.
- [ ] The Android application name is final.
- [ ] The Android launcher icon is final.
- [ ] The Android splash screen is final.
- [ ] The Android version name is correct.
- [ ] The Android version code is incremented correctly.
- [ ] Minimum Android version is documented.
- [ ] Target Android SDK is appropriate for release.
- [ ] Required Android permissions are declared correctly.
- [ ] Unused Android permissions are removed.
- [ ] Notification permission behavior is verified on supported Android versions.
- [ ] Location permission behavior is verified on supported Android versions.
- [ ] The application launches successfully after a fresh installation.
- [ ] The application upgrades successfully from the previous test build.
- [ ] The application works after force stopping and reopening.
- [ ] The application works after device restart.
- [ ] Android back navigation works correctly.
- [ ] Android system dark mode behaves correctly.
- [ ] Android system font scaling behaves correctly.
- [ ] Android keyboard behavior is correct.
- [ ] Android status bar is styled correctly.
- [ ] Android navigation bar is styled correctly.
- [ ] Android safe areas are respected.
- [ ] Portrait orientation works correctly.
- [ ] Landscape behavior is supported or intentionally restricted.
- [ ] Small Android screen testing is complete.
- [ ] Standard Android screen testing is complete.
- [ ] Large Android screen testing is complete.
- [ ] Android tablet behavior is acceptable or explicitly unsupported.
- [ ] At least one lower-performance Android emulator has been tested.
- [ ] At least one recent Android emulator has been tested.
- [ ] Android release build has no debug banner.
- [ ] Android release build contains no debug-only controls.
- [ ] Android release signing is configured.
- [ ] Android release artifact installs successfully.
- [ ] Android release artifact launches successfully.
- [ ] Android crash logs show no unresolved release-blocking issue.

# 25. iOS Compatibility

- [ ] The Flutter project contains a valid iOS target.
- [ ] The iOS project opens successfully in Xcode or the selected cloud build environment.
- [ ] The application builds successfully for iOS.
- [ ] The iOS bundle identifier is final.
- [ ] The iOS display name is final.
- [ ] The iOS application icon set is complete.
- [ ] The iOS launch screen is complete.
- [ ] The iOS version is correct.
- [ ] The iOS build number is incremented correctly.
- [ ] Minimum supported iOS version is documented.
- [ ] Required iOS permission descriptions are present.
- [ ] Location usage descriptions are accurate.
- [ ] Notification permission messaging is accurate.
- [ ] Unused iOS permissions are removed.
- [ ] Unused iOS capabilities are removed.
- [ ] HealthKit capability is not enabled unless implemented.
- [ ] Bluetooth capability is not enabled unless implemented.
- [ ] Background modes are not enabled unless required.
- [ ] The application launches successfully on an iPhone simulator.
- [ ] The application works after termination and relaunch.
- [ ] The application works after simulator restart.
- [ ] iOS safe areas are respected.
- [ ] Dynamic Island areas do not overlap content.
- [ ] Notched iPhone layouts display correctly.
- [ ] Non-notched iPhone layouts display correctly.
- [ ] Small iPhone screen testing is complete.
- [ ] Standard iPhone screen testing is complete.
- [ ] Large iPhone screen testing is complete.
- [ ] iPad behavior is acceptable or explicitly unsupported.
- [ ] iOS text scaling behaves correctly.
- [ ] iOS dark mode behaves correctly.
- [ ] iOS keyboard behavior is correct.
- [ ] Swipe-back navigation works correctly.
- [ ] Modal presentation behaves correctly.
- [ ] Notification scheduling works on iOS.
- [ ] Notification cancellation works on iOS.
- [ ] Notification permission denial is handled correctly.
- [ ] Location permission denial is handled correctly.
- [ ] Weather Mode works correctly on iOS.
- [ ] Local storage persists correctly on iOS.
- [ ] Existing local data survives an iOS application update.
- [ ] iOS release build contains no debug banner.
- [ ] iOS release build contains no debug-only controls.
- [ ] iOS release signing is configured.
- [ ] Provisioning configuration is valid.
- [ ] The archived iOS build succeeds.
- [ ] The generated IPA or TestFlight artifact is valid.
- [ ] App Store Connect accepts the build.
- [ ] iOS crash logs show no unresolved release-blocking issue.

# 26. Cross-Platform Consistency

- [ ] Android and iOS expose the same V1 feature set.
- [ ] Android and iOS use the same hydration calculations.
- [ ] Android and iOS use the same streak calculations.
- [ ] Android and iOS use the same achievement rules.
- [ ] Android and iOS use the same challenge rules.
- [ ] Android and iOS use the same localization content.
- [ ] Android and iOS display the same legal documents.
- [ ] Android and iOS store equivalent local data.
- [ ] Android and iOS handle unit conversions consistently.
- [ ] Android and iOS handle dates consistently.
- [ ] Android and iOS handle time zones consistently.
- [ ] Android and iOS handle midnight rollover consistently.
- [ ] Android and iOS display comparable loading states.
- [ ] Android and iOS display comparable error states.
- [ ] Android and iOS display comparable empty states.
- [ ] Platform-specific behavior is documented.
- [ ] No platform is released with a known critical feature gap.

# 27. Responsive Device Testing

- [ ] The application has been tested on a small Android phone emulator.
- [ ] The application has been tested on a standard Android phone emulator.
- [ ] The application has been tested on a large Android phone emulator.
- [ ] The application has been tested on an iPhone SE-sized simulator.
- [ ] The application has been tested on a standard iPhone simulator.
- [ ] The application has been tested on a large iPhone simulator.
- [ ] No screen has horizontal overflow.
- [ ] No screen has vertical overflow that blocks actions.
- [ ] Bottom navigation remains usable on all target sizes.
- [ ] Dialogs fit on all target sizes.
- [ ] Forms fit on all target sizes.
- [ ] Charts fit on all target sizes.
- [ ] Profile layouts fit on all target sizes.
- [ ] Avatar layouts fit on all target sizes.
- [ ] Legal documents remain readable on all target sizes.

# 28. Performance and Stability

- [ ] Application startup time is acceptable.
- [ ] Startup contains no unnecessary fixed delay.
- [ ] Home screen interactions are responsive.
- [ ] Hydration logging feels immediate.
- [ ] History scrolling is smooth.
- [ ] Analytics rendering is smooth.
- [ ] Avatar loading is smooth.
- [ ] No major memory leak is observed.
- [ ] No excessive battery consumption is observed.
- [ ] No repeated network request loop exists.
- [ ] Weather requests are bounded.
- [ ] Weather request failures are handled safely.
- [ ] Failed network requests do not freeze the application.
- [ ] Rapid repeated taps do not crash the application.
- [ ] Backgrounding and restoring the application works.
- [ ] Device rotation does not corrupt state.
- [ ] Low-storage conditions fail safely where testable.
- [ ] Release builds produce no unresolved critical logs.
- [ ] No known crash remains unresolved.
- [ ] No known data-loss defect remains unresolved.

# 29. Automated Quality Gates

- [x] Flutter formatting checks pass.
- [x] Flutter static analysis passes.
- [x] All unit tests pass.
- [x] All widget tests pass.
- [ ] All required integration tests pass.
- [ ] Android build workflow passes.
- [ ] iOS build workflow passes.
- [ ] Web workflow passes if web remains supported.
- [ ] No test is skipped without a documented reason.
- [ ] No release-blocking warning is ignored.
- [ ] Continuous integration runs from a clean checkout.
- [ ] Continuous integration uses the documented Flutter version.
- [ ] Continuous integration artifacts are generated correctly.
- [ ] Build dependencies are pinned or controlled.
- [ ] Removed AR functionality is absent from tests.
- [ ] Removed AR functionality is absent from builds.
- [x] Generated assets referenced at runtime exist.
- [ ] Localization key validation passes.
- [ ] Repository contains no tracked temporary files.
- [ ] Repository contains no tracked build artifacts.
- [x] Repository contains no tracked credentials.

# 30. Repository and Kanban Alignment

- [ ] The local repository matches the intended remote branch.
- [ ] The release branch contains all approved V1 work.
- [ ] No unintended local-only changes remain.
- [ ] No unresolved merge conflict remains.
- [ ] Repository status is clean before release tagging.
- [ ] Every completed V1 story has evidence of completion.
- [ ] Every completed V1 story satisfies its acceptance criteria.
- [ ] Every open release-blocking defect is resolved.
- [ ] Remaining open issues are classified as post-V1 or non-blocking.
- [ ] Kanban cards match actual repository implementation status.
- [ ] Product stories remain separate from technical child issues where appropriate.
- [ ] V1 release notes match completed work.
- [ ] The final release commit is identified.
- [ ] The release tag is created from the correct commit.
- [ ] The release tag is pushed successfully.
- [ ] The GitHub milestone reflects the final V1 state.

# 31. User Validation

- [ ] A new user can complete onboarding without assistance.
- [ ] A new user can log water without assistance.
- [ ] A new user can understand daily progress without assistance.
- [ ] A new user can edit an incorrect log.
- [ ] A new user can delete an incorrect log.
- [ ] A new user can configure reminders.
- [ ] A new user can find history.
- [ ] A new user can understand basic analytics.
- [ ] A new user can find legal documents.
- [ ] Test users understand that Hydrion is not medical software.
- [ ] Test users understand what data is stored locally.
- [ ] Alpha feedback has been reviewed.
- [ ] Beta feedback has been reviewed.
- [ ] Critical usability complaints are resolved.
- [ ] Repeated tester confusion is resolved.
- [ ] Known non-blocking limitations are documented.
- [ ] Tester feedback is classified as a defect, user story, or feature request.

# 32. Google Play Preparation

- [ ] Final Android application name is approved.
- [ ] Final Android description is approved.
- [ ] Final Android short description is approved.
- [ ] Final Android category is selected.
- [ ] Final Android age rating is selected.
- [ ] Google Play data safety declarations match actual behavior.
- [ ] Google Play privacy declarations match actual behavior.
- [ ] Android screenshots represent the real V1 interface.
- [ ] Android screenshots contain no unfinished features.
- [ ] Android screenshots exist for required screen sizes.
- [ ] Android application icon meets store requirements.
- [ ] Android support contact information is valid.
- [ ] Android Privacy Policy location is valid.
- [ ] Android release notes are complete.
- [ ] Android store listing contains no unsupported claims.
- [ ] Android store listing does not advertise V1.1 features as available.
- [ ] Android release package is ready for submission.

# 33. Apple App Store Preparation

- [ ] Final iOS application name is approved.
- [ ] Final iOS description is approved.
- [ ] Final iOS subtitle is approved.
- [ ] Final iOS keywords are approved.
- [ ] Final iOS category is selected.
- [ ] Final iOS age rating is selected.
- [ ] App Store privacy declarations match actual behavior.
- [ ] iPhone screenshots represent the real V1 interface.
- [ ] iPhone screenshots contain no unfinished features.
- [ ] iPhone screenshots exist for required screen sizes.
- [ ] iOS application icon meets Apple requirements.
- [ ] iOS support contact information is valid.
- [ ] iOS Privacy Policy location is valid.
- [ ] iOS release notes are complete.
- [ ] App Store listing contains no unsupported claims.
- [ ] App Store listing does not advertise V1.1 features as available.
- [ ] The iOS build is ready for TestFlight or App Store submission.

# 34. V1.1 Anticipation

- [ ] V1 contains a polished and complete daily hydration loop.
- [ ] V1.1 features are not required for V1 usability.
- [ ] Connected Devices is presented only as Coming Soon.
- [ ] Smarter guidance is presented only as future functionality.
- [ ] Expanded analytics is presented only as future functionality.
- [ ] Social challenges are presented only as future functionality.
- [ ] Future feature messaging is restrained.
- [ ] Future feature messaging does not interrupt core hydration actions.
- [ ] No inaccessible control appears tappable.
- [ ] Users can clearly see that Hydrion will continue improving.
- [ ] The V1 experience is useful enough that users have a reason to return before V1.1.

---

# Final Release Gate

Hydrion V1 may proceed to production release only when every statement below is confirmed.

- [ ] Every release-blocking checkbox is confirmed.
- [ ] No unresolved critical defect remains.
- [ ] No unresolved high-severity defect remains.
- [ ] No known hydration data-loss issue remains.
- [ ] No known crash remains in the core user journey.
- [ ] Android release build is validated.
- [ ] iOS release build is validated.
- [ ] Core functionality is consistent across Android and iOS.
- [ ] Legal requirements are complete.
- [ ] Privacy requirements are complete.
- [ ] App-store declarations match actual behavior.
- [ ] The repository, Kanban board, milestone, release notes, and build artifacts agree.
- [ ] The final release candidate has been tested from a clean installation.
- [ ] The final release candidate has been tested as an upgrade.
- [ ] The V1 release decision is documented.
- [ ] The V1 production release is approved.

## Final Approval

| Responsibility | Name | Status | Date |
|---|---|---:|---|
| Product scope approval |  | Pending |  |
| Android validation |  | Pending |  |
| iOS validation |  | Pending |  |
| Quality assurance |  | Pending |  |
| Privacy and legal review |  | Pending |  |
| Release approval |  | Pending |  |

## Release Decision

- **Decision:** Not approved
- **Approved version:** Not assigned
- **Approved commit:** Not assigned
- **Android artifact:** Not assigned
- **iOS artifact:** Not assigned
- **Approval date:** Not assigned
