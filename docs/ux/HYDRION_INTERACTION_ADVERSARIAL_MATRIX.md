# Hydrion Interaction Adversarial Matrix

| Scenario | Expected result | Automated evidence |
| --- | --- | --- |
| Tap permission action repeatedly | One request; visible requesting state | Permission widget tests |
| Deny or permanently deny access | Card says denied/blocked and app remains usable | Permission state tests |
| Change access in system settings | Resume refresh replaces stale state | Permission lifecycle tests |
| Decline weather, revisit later | Decision remains off; no automatic prompt | Onboarding/settings tests |
| Enable weather, revoke location | Selected but inactive with explanation | Weather/permission tests |
| Open Body Metrics before profile Continue | Current valid age is persisted first | Onboarding UI test |
| Age 12 reaches onboarding Continue | Blocked with supported-age message | Life-stage/onboarding tests |
| Saved age is negative or above 120 | Invalid review state; no challenges | Life-stage tests |
| Teen opens adult challenge directly | Catalog hides it; repository join rejects it | Challenge eligibility tests |
| Adult opens teen challenge directly | Catalog hides it; repository join rejects it | Challenge eligibility tests |
| Third active challenge is joined | Repository rejects it | Challenge eligibility tests |
| Male profile opens reproductive controls | Current supported model keeps them unavailable | Body metrics tests |
| Pregnant teen uses safety controls | Supported without inference or social exposure | Body metrics tests |
| Intersex/prefer-not-to-say selected | Identity preserved; no physiology guessed | Profile/body metrics tests |
| Personalization is off | Personalized baseline is shown inactive | Body metrics tests |
| Exact alarms unavailable | Approximate scheduling is stated | Reminder/permission tests |
| Repository write fails | Editor preserves draft and reports failure | Repository failure tests |
| Async save is tapped twice | Submitting disables repeat | Editor tests |
| Profile is deleted | Settings, drafts, permissions history, and challenges clear | Local reset tests |
| 200% text, narrow width, keyboard, system inset | Actions stack/scroll and remain reachable | Responsive tests |
| Dark theme and EN/FR/ES | Status remains legible and copy fits | Theme/localization tests |

Manual physical Android acceptance remains required for real permission dialogs,
settings return, TalkBack traversal, gesture navigation, and notification
delivery. No emulator is used for this work unit.
