# Hydrion User-Facing Copy Audit

Audit date: 2026-07-30

## Findings And Corrections

| Surface | Source | Previous output | Classification | Corrected behavior | Regression |
|---|---|---|---|---|---|
| Challenge catalog cards | `social_challenges_screen.dart` | `Teen routine`, `Adult routine`, and other domain categories | Inappropriate audience label / internal metadata | Category removed; eligibility remains internal | Source and widget tests prohibit audience labels |
| Challenge catalog cards | `social_challenges_screen.dart` | Description plus repeated daily task | Redundant and excessive copy | One concise description; instructions remain on details | Card copy-budget test |
| Challenge catalog card semantics | `social_challenges_screen.dart` | Raw domain title plus fixed English action | Localization issue | Semantics retains only useful title/action content; no category or audience | Semantics leak test |
| Challenge artwork | `challenge_visual_registry.dart` | Unrelated generic UI images used for eight newer challenges | Unclear presentation | Preserve owner-supplied images and use centralized unique paths and profile-aware variants | Registry and asset tests |
| Challenge details | `challenge_experience_screen.dart` | Long setup, rules, privacy, and safety sections | Excessive copy risk | Retained because it explains completion, persistence, and safe hydration behavior; scheduled for translation coverage | Review matrix |
| Startup warm-up | `startup_screen.dart` | Exception type enters internal trace data only | Raw technical output | Confirmed not visible or semantic; trace remains internal | Visible-source audit |
| BMI insight | `body_metrics_screen.dart` | Adult screening category labels | Legal/safety educational copy | Retained; categories are medically contextual explanations, not eligibility metadata | Existing BMI tests |
| Storage recovery | repositories | Schema versions and repository categories | Internal metadata | Confirmed repository-only and never directly rendered | Source leak scan |

## Application-Wide Review

Production routes, dialogs, sheets, cards, snackbars, tooltips, empty states,
notification strings, ARB files, and semantics were searched for raw enum
conversion, exception types, schema versions, reason codes, audience terms,
identifiers, placeholders, and category rendering. Numeric formatting and ISO
dates used for form values or storage were not classified as leaks unless
rendered without presentation formatting.

Safety, clinician-target, pregnancy/lactation, fluid-restriction, permission,
profile-deletion, local-only, and legal explanations remain intact.
