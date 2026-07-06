# Hydrion Runtime Asset Optimization Report

Status: measured local pass on July 6, 2026.

## Summary

| Metric | Before | After |
|---|---:|---:|
| Runtime asset files under `assets/` | 44 | 43 |
| Runtime asset bytes under `assets/` | 76,702,320 | 3,413,216 |
| Runtime byte reduction |  | 73,289,104 bytes |
| Runtime percentage reduction |  | 95.55% |
| Source originals preserved |  | `assets_source_original/` |

The before total is the measured pre-optimization `assets/` total from this pass. The after total is the current measured `assets/` tree. Original owner assets were moved to `assets_source_original/assets/...` and are not declared in `pubspec.yaml`.

## Build Size Measurements

| Build artifact | Before optimization | After optimization | Notes |
|---|---:|---:|---|
| Web release build | Not measured before asset conversion | 83 files, 37,058,566 bytes | Do not infer a before/after web delta from asset bytes alone. |
| Release APK | Not measured locally | Blocked locally: no Android SDK/`ANDROID_HOME` | Do not claim APK reduction unless a local or CI build is actually observed. |

## Optimization Actions

- Converted runtime PNG artwork to high-quality JPG derivatives because the original PNGs were RGB and did not require alpha.
- Resized `UI_BETA` lifestyle scenes to a maximum long side of 768 px.
- Resized profile avatars, shark companions, mascot, and app icon to a maximum long side of 640 px.
- Moved the unused `assets/pfp_mascot/pfp/1000064425.mp4` out of the runtime bundle.
- Updated Dart, tests, docs, and `pubspec.yaml` references from `.png` to `.jpg`.
- Preserved stable avatar IDs in code so stored user avatar selections continue to resolve.

## Transparency Check

All original PNG files in `assets_source_original/assets/...` were checked with `System.Drawing.Image.IsAlphaPixelFormat`. Every checked PNG reported `False`; no transparent runtime profile asset was flattened.

## 20 Largest Runtime Assets Before

| Path | Dimensions | Bytes |
|---|---:|---:|
| `assets_source_original/assets/pfp_mascot/pfp/1000064425.mp4` | n/a | 3,014,191 |
| `assets_source_original/assets/pfp_mascot/pfp/strong_shark.png` | 1254x1254 | 2,398,200 |
| `assets_source_original/assets/pfp_mascot/pfp/slicky_shark.png` | 1254x1254 | 2,395,039 |
| `assets_source_original/assets/pfp_mascot/pfp/snss.png` | 1254x1254 | 2,303,339 |
| `assets_source_original/assets/pfp_mascot/pfp/savvy-eco_shark.png` | 1254x1254 | 2,229,081 |
| `assets_source_original/assets/pfp_mascot/pfp/smartty_shark.png` | 1254x1254 | 2,220,418 |
| `assets_source_original/assets/pfp_mascot/hpfp/hydrion-human-silver.png` | 1254x1254 | 2,214,821 |
| `assets_source_original/assets/pfp_mascot/pfp/supercool_shark.png` | 1254x1254 | 2,105,437 |
| `assets_source_original/assets/pfp_mascot/pfp/sensei_shark.png` | 1254x1254 | 2,086,603 |
| `assets_source_original/assets/pfp_mascot/pfp/sundown_shark.png` | 1254x1254 | 1,988,863 |
| `assets_source_original/assets/pfp_mascot/hpfp/hydrion-human-wave.png` | 1254x1254 | 1,978,147 |
| `assets_source_original/assets/pfp_mascot/hpfp/hydrion-human-cove.png` | 1254x1254 | 1,962,942 |
| `assets_source_original/assets/UI_BETA/hydrion-lifestyle-portrait.png` | 1254x1254 | 1,962,942 |
| `assets_source_original/assets/pfp_mascot/hpfp/hydrion-human-sunrise.png` | 1254x1254 | 1,954,428 |
| `assets_source_original/assets/pfp_mascot/hpfp/hydrion-human-splash.png` | 1254x1254 | 1,941,169 |
| `assets_source_original/assets/UI_BETA/hydrion-lifestyle-app-check.png` | 1024x1536 | 1,939,297 |
| `assets_source_original/assets/pfp_mascot/hpfp/hydrion-human-harbor.png` | 1254x1254 | 1,937,119 |
| `assets_source_original/assets/pfp_mascot/pfp/scout_shark.png` | 1254x1254 | 1,923,795 |
| `assets_source_original/assets/pfp_mascot/hpfp/hydrion-human-lagoon.png` | 1254x1254 | 1,922,026 |
| `assets_source_original/assets/pfp_mascot/hpfp/hydrion-human-reef.png` | 1254x1254 | 1,908,474 |

## 20 Largest Runtime Assets After

| Path | Dimensions | Bytes |
|---|---:|---:|
| `assets/UI_BETA/hydrion-lifestyle-portrait.jpg` | 768x768 | 116,711 |
| `assets/pfp_mascot/pfp/snss.jpg` | 640x640 | 115,351 |
| `assets/pfp_mascot/pfp/strong_shark.jpg` | 640x640 | 111,407 |
| `assets/pfp_mascot/pfp/smartty_shark.jpg` | 640x640 | 101,450 |
| `assets/pfp_mascot/pfp/slicky_shark.jpg` | 640x640 | 101,016 |
| `assets/pfp_mascot/pfp/scout_shark.jpg` | 640x640 | 100,681 |
| `assets/pfp_mascot/hpfp/hydrion-human-splash.jpg` | 640x640 | 97,062 |
| `assets/pfp_mascot/pfp/supercool_shark.jpg` | 640x640 | 96,661 |
| `assets/UI_BETA/hydrion-lifestyle-app-check.jpg` | 512x768 | 95,011 |
| `assets/pfp_mascot/hpfp/hydrion-human-silver.jpg` | 640x640 | 93,574 |
| `assets/pfp_mascot/hpfp/hydrion-human-wave.jpg` | 640x640 | 92,256 |
| `assets/pfp_mascot/hpfp/hydrion-human-lagoon.jpg` | 640x640 | 91,014 |
| `assets/pfp_mascot/hpfp/hydrion-human-bluebell.jpg` | 640x640 | 90,636 |
| `assets/pfp_mascot/pfp/savvy-eco_shark.jpg` | 640x640 | 89,994 |
| `assets/pfp_mascot/hpfp/hydrion-human-compass.jpg` | 640x640 | 88,708 |
| `assets/pfp_mascot/hpfp/hydrion-human-sunrise.jpg` | 640x640 | 88,489 |
| `assets/pfp_mascot/hpfp/hydrion-human-cove.jpg` | 640x640 | 87,330 |
| `assets/pfp_mascot/hpfp/hydrion-human-mist.jpg` | 640x640 | 86,485 |
| `assets/pfp_mascot/hpfp/hydrion-human-bloom.jpg` | 640x640 | 85,349 |
| `assets/pfp_mascot/hpfp/hydrion-human-harbor.jpg` | 640x640 | 85,231 |

## Runtime Inventory Notes

- `assets/UI_BETA/*.jpg`: lifestyle scenes used by Home, Progress, Challenges, Profile, onboarding, empty/recommendation/weather surfaces through `HydrionUiAssetManifest` and `HydrionLifestyleArtResolver`.
- `assets/pfp_mascot/pfp/*.jpg`: selectable shark companion avatars through `HydrionAvatarManifest`.
- `assets/pfp_mascot/hpfp/*.jpg`: selectable human profile defaults through `HydrionAvatarManifest`.
- `assets/pfp_mascot/hydrion_mascot.jpg`: startup, onboarding, fallback logo/brand moments.
- `assets/icons/icon1807.jpg`: Hydrion logo component and app icon source reference.
- `.gitkeep` files in `assets/ar`, `assets/sounds`, and `assets/ui` are zero-byte placeholders only.

No exact duplicate runtime asset identifiers were found by `test/asset_registry_test.dart`. No `.mp4` or old `.png` runtime asset is declared in `pubspec.yaml`.
