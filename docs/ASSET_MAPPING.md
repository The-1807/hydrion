# Hydrion Asset Mapping

Status: implemented for owner review. This document records how the supplied
visual assets are used so they do not become arbitrary decoration.

## Shark Companion Assets

| Asset | Identity | Emotional role | Product use |
|---|---|---|---|
| `assets/pfp_mascot/hydrion_mascot.jpg` | Hydrion mascot | Brand anchor | Startup, onboarding, fallback brand moments |
| `assets/pfp_mascot/pfp/savvy-eco_shark.jpg` | Savvy Eco | Eco-minded and steady | Default shark companion and fallback avatar |
| `assets/pfp_mascot/pfp/scout_shark.jpg` | Scout | Curious and practical | Selectable shark companion |
| `assets/pfp_mascot/pfp/sensei_shark.jpg` | Sensei | Calm and focused | Selectable shark companion |
| `assets/pfp_mascot/pfp/slicky_shark.jpg` | Slicky | Smooth and upbeat | Selectable shark companion |
| `assets/pfp_mascot/pfp/smartty_shark.jpg` | Smartty | Analytical and tidy | Selectable shark companion |
| `assets/pfp_mascot/pfp/snss.jpg` | SNSS | Preserved community name | Selectable shark companion pending owner naming direction |
| `assets/pfp_mascot/pfp/strong_shark.jpg` | Strong | Reliable and direct | Selectable shark companion |
| `assets/pfp_mascot/pfp/sundown_shark.jpg` | Sundown | Relaxed evening energy | Selectable shark companion |
| `assets/pfp_mascot/pfp/supercool_shark.jpg` | Supercool | Cool and playful | Selectable shark companion |
| `assets/pfp_mascot/pfp/superhappy_shark.jpg` | Superhappy | Bright and celebratory | Selectable shark companion |

## Archived Human Profile Avatar Derivatives

Generated human profile-avatar JPGs were removed from the runtime bundle and
are no longer selectable defaults. They are archived under
`assets_source_original/removed_runtime_assets/assets/pfp_mascot/hpfp/` for
owner review only. Saved ids matching the removed `hydrion-human-*` set migrate
to the default `savvy-eco_shark` avatar. Users can still provide a custom
profile photo through the existing profile-photo flow.

## UI_BETA Lifestyle Assets

The files in `assets/UI_BETA/` are not PFPs. They are full-body or brand-scene
assets used to add product flavor to Home, Progress, Challenges, and Profile.

| Asset | Scene | Product use |
|---|---|---|
| `assets/UI_BETA/hydrion-lifestyle-app-check.jpg` | App Check | Home ritual rail and product atmosphere |
| `assets/UI_BETA/hydrion-lifestyle-blue-kit.jpg` | Blue Kit | Progress, profile, or empty-state accent |
| `assets/UI_BETA/hydrion-lifestyle-bottle-break.jpg` | Bottle Break | Home ritual rail and challenge routines |
| `assets/UI_BETA/hydrion-lifestyle-cooldown.jpg` | Cooldown | Seven-day Progress strip |
| `assets/UI_BETA/hydrion-lifestyle-plan-check.jpg` | Plan Check | Home ritual rail and weather-goal surfaces |
| `assets/UI_BETA/hydrion-lifestyle-portrait.jpg` | Portrait | Brand atmosphere only; not a selectable profile photo |
| `assets/UI_BETA/hydrion-lifestyle-runner-ready.jpg` | Runner Ready | Challenges hero |
| `assets/UI_BETA/hydrion-lifestyle-sip-break.jpg` | Sip Break | Home ritual rail |
| `assets/UI_BETA/hydrion-lifestyle-studio-bottle.jpg` | Studio Bottle | Profile lifestyle moment |

## Profile-Aware Lifestyle Resolver

Automatic lifestyle-art selection is centralized in
`lib/domain/ui_asset_manifest.dart`.

| Profile sex selection | Presentation bucket | Default behavior |
|---|---|---|
| Male | Male | Uses the available male Hydrion lifestyle artwork where mapped. |
| Female | Female | Uses the available female Hydrion lifestyle artwork where mapped. |
| Intersex | Neutral | Uses neutral/default Hydrion artwork. |
| Prefer not to say | Neutral | Uses neutral/default Hydrion artwork. |
| Missing/null | Neutral | Uses neutral/default Hydrion artwork. |

Hydrion does not infer sex or gender from nickname, selected profile image,
selected avatar, device information, location, behavior, or previous artwork.
This resolver controls automatic lifestyle-art selection only. Users can still
manually choose any shark companion or provide a custom profile photo.

Current scene defaults:

| Surface | Male | Female | Neutral/default |
|---|---|---|---|
| Home primary | App Check | Sip Break | Blue Kit |
| Home secondary | Bottle Break | Plan Check | Cooldown |
| Home tertiary | Blue Kit | Runner Ready | Plan Check |
| Home quaternary | Cooldown | Studio Bottle | Bottle Break |
| Weather | App Check | Plan Check | Plan Check |
| Progress | Cooldown | Runner Ready | Cooldown |
| Challenges | Bottle Break | Runner Ready | Blue Kit |
| Profile | App Check | Studio Bottle | Blue Kit |
| Onboarding | App Check | Portrait | Blue Kit |
| Empty state | Blue Kit | Sip Break | Cooldown |
| Recommendation | Bottle Break | Plan Check | Plan Check |

## Runtime Optimization Notes

Runtime images were converted from owner-supplied PNGs to high-quality JPG
derivatives after verifying the original PNGs did not contain alpha. Source
originals are preserved outside the bundled app path in
`assets_source_original/assets/...`.

Measured runtime asset totals:

- Before: 44 files, 76,702,320 bytes.
- After removing human default avatar JPGs: 21 runtime-declared files, 1,790,496 bytes.
- Reduction: 74,911,824 bytes, 97.67%.

The unused `assets/pfp_mascot/pfp/1000064425.mp4` was moved to
`assets_source_original/assets/pfp_mascot/pfp/1000064425.mp4` and is not
declared in `pubspec.yaml`.
The generated `assets/pfp_mascot/hpfp/*.jpg` human defaults were moved to
`assets_source_original/removed_runtime_assets/assets/pfp_mascot/hpfp/` and are
not declared in `pubspec.yaml`.

See `docs/ASSET_OPTIMIZATION_REPORT.md` for dimensions, largest-file tables,
and bundle-size notes.

## Rename Notes

The new generated image filenames were renamed to stable, neutral filenames.
Existing shark filenames were preserved because they already have community
identity and code references.
