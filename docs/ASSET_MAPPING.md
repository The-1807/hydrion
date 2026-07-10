# Hydrion Asset Mapping

Status: implemented for owner review. This document records how the supplied
visual assets are used so they do not become arbitrary decoration.

## Shark Companion Assets

| Asset | Identity | Emotional role | Product use |
|---|---|---|---|
| `assets/pfp_mascot/hydrion_mascot.jpg` | Hydrion mascot | Brand anchor | Onboarding and fallback brand moments |
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

## UI_BETA Transparent Runtime Assets

The active files in `assets/UI_BETA/` are PNG runtime illustrations. Character
and context art is intentionally transparent so Home, Progress, Challenges,
Profile, weather, and onboarding surfaces do not show boxed JPG backgrounds.
The older `hydrion-lifestyle-*.jpg` runtime files were removed in the V1 asset
replacement pass.

| Asset | Scene | Product use |
|---|---|---|
| `assets/UI_BETA/green-check.png` | Success Check | Onboarding ready/completion state |
| `assets/UI_BETA/drinking-lady.png` | Sip Break | Home ritual rail and hydration contexts |
| `assets/UI_BETA/drinking-man.png` | Bottle Break | Home rail and routine-building contexts |
| `assets/UI_BETA/workout-lady.png` | Workout Routine | Profile and active routine contexts |
| `assets/UI_BETA/workout-man.png` | Cooldown | Progress dashboard and activity-adjacent moments |
| `assets/UI_BETA/tracked_intake.png` | Tracked Intake | Progress, profile, or empty-state accent |
| `assets/UI_BETA/man-checking-app.png` | App Check | Home, weather, and app-checking contexts |
| `assets/UI_BETA/lady-checking-app.png` | Plan Check | Home daily-plan and weather-goal panels |
| `assets/UI_BETA/community-run.png` | Community Run | Local challenge and social-coming-soon context |
| `assets/UI_BETA/running-lady.png` | Runner Ready | Challenges and active routine cards |
| `assets/UI_BETA/running-man.png` | Runner | Active routine and challenge cards |
| `assets/UI_BETA/ble_bottle.png` | BLE Bottle | Preserved for documented future/coming-soon visual use only; not active V1 smart-bottle support |

No non-empty attribution text file was supplied with these PNGs. A zero-byte
`assets/UI_BETA/attributions` placeholder was removed from the runtime bundle.

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
- After the July 10 transparent PNG replacement: 25 runtime-declared media files, 16,790,393 bytes.
- Reduction: 74,908,847 bytes, 97.66%.

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

## Shark Loading Animation

`assets/buffer/Shark.json` is the bundled runtime startup animation. Hydrion
loads it locally through the Flutter `lottie` package for the minimal startup
buffer. The original downloaded `assets/buffer/Shark.lottie` file is retained
as source evidence and is not declared in `pubspec.yaml`.

Source-page creator and licence evidence are tracked in
`THIRD_PARTY_NOTICES.md` and
`docs/third_party/lottiefiles_shark_animation.md`; those fields must be
completed before this asset is release-approved.

Permanent source reference:
`https://app.lottiefiles.com/share/a1310b00-ea2c-4d3a-b580-688ad4c56291`.
