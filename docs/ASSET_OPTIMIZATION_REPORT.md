# Hydrion Runtime Asset Optimization Report

Status: measured local pass on July 6, 2026.

Corrective follow-ups on July 10, 2026 removed the unreferenced
`assets/UI_BETA/hyd-ad/` runtime media folder, replaced boxed
`hydrion-lifestyle-*.jpg` runtime character art with transparent PNG assets,
and wired the supplied weather, challenge, and goals PNGs. Current measured
media under the declared Flutter asset paths is 31 files, 31,955,520 bytes.
The retained `assets/buffer/Shark.lottie` source original is not declared in
`pubspec.yaml`.

## Summary

| Metric | Before | After |
|---|---:|---:|
| Runtime asset files under `assets/` | 44 | 31 |
| Runtime asset bytes under `assets/` | 76,702,320 | 31,955,520 |
| Runtime byte reduction |  | 44,746,800 bytes |
| Runtime percentage reduction |  | 58.34% |
| Source originals preserved |  | `assets_source_original/` |

The before total is the measured pre-optimization `assets/` total from this pass. The after total is the current runtime-declared media asset set. Original owner assets were moved to `assets_source_original/assets/...` and are not declared in `pubspec.yaml`.

## Build Size Measurements

| Build artifact | Before optimization | After optimization | Notes |
|---|---:|---:|---|
| Web release build | Not measured before asset conversion | 64 files, 35,428,770 bytes | Do not infer a before/after web delta from asset bytes alone. |
| Release APK | Not measured locally | Blocked locally: no Android SDK/`ANDROID_HOME` | Do not claim APK reduction unless a local or CI build is actually observed. |

## Optimization Actions

- Replaced obsolete boxed runtime lifestyle JPGs with transparent PNG artwork
  supplied for V1 runtime surfaces.
- Resized profile avatars, shark companions, mascot, and app icon to a maximum long side of 640 px.
- Moved the unused `assets/pfp_mascot/pfp/1000064425.mp4` out of the runtime bundle.
- Moved generated human profile-avatar JPG derivatives out of the runtime bundle.
- Deleted the unreferenced `assets/UI_BETA/hyd-ad/` runtime ad artifacts.
- Updated Dart, tests, docs, and `pubspec.yaml` references to the active runtime
  media paths.
- Preserved shark avatar IDs in code; removed human avatar IDs migrate to the default shark.

## Transparency Check

The active `assets/UI_BETA/*.png` files are intentionally transparent runtime
illustrations. The newly supplied `weather.png`, `hot-summer.png`,
`challenge.png`, `goals.png`, `men-goals.png`, and `goals-lady.png` all decoded
as PNGs with alpha. `sunny.png` was not present, and `hot-summer.pnh` was not
present.

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
| `assets/UI_BETA/goals-lady.png` | 3000x4236 | 6,153,066 |
| `assets/UI_BETA/goals.png` | 3840x2396 | 4,735,592 |
| `assets/UI_BETA/men-goals.png` | 3216x3904 | 3,874,057 |
| `assets/UI_BETA/drinking-man.png` | 3504x4128 | 3,180,564 |
| `assets/UI_BETA/ble_bottle.png` | 3356x3356 | 2,321,833 |
| `assets/UI_BETA/workout-lady.png` | 3208x3516 | 1,683,283 |
| `assets/UI_BETA/lady-checking-app.png` | 1364x3720 | 1,652,010 |
| `assets/UI_BETA/man-checking-app.png` | 1900x3348 | 1,619,442 |
| `assets/UI_BETA/running-lady.png` | 3568x3600 | 1,566,459 |
| `assets/UI_BETA/running-man.png` | 2712x3160 | 1,268,188 |
| `assets/UI_BETA/workout-man.png` | 2124x3004 | 1,122,628 |
| `assets/UI_BETA/community-run.png` | 2252x1636 | 992,936 |
| `assets/UI_BETA/drinking-lady.png` | 2000x2000 | 213,693 |
| `assets/UI_BETA/weather.png` | 1232x1140 | 212,717 |
| `assets/UI_BETA/hot-summer.png` | 644x648 | 159,025 |
| `assets/pfp_mascot/pfp/snss.jpg` | 640x640 | 115,351 |
| `assets/pfp_mascot/pfp/strong_shark.jpg` | 640x640 | 111,407 |
| `assets/pfp_mascot/pfp/smartty_shark.jpg` | 640x640 | 101,450 |
| `assets/pfp_mascot/pfp/slicky_shark.jpg` | 640x640 | 101,016 |
| `assets/pfp_mascot/pfp/scout_shark.jpg` | 640x640 | 100,681 |

## Runtime Inventory Notes

- `assets/UI_BETA/*.png`: transparent runtime illustrations used by Home,
  Progress, Challenges, Profile, weather, and onboarding through
  `HydrionUiAssetManifest` and `HydrionLifestyleArtResolver`.
- `assets/UI_BETA/ble_bottle.png`: retained as documented future/coming-soon
  visual inventory only; it is not active BLE runtime support in V1.
- `assets/pfp_mascot/pfp/*.jpg`: selectable shark companion avatars through `HydrionAvatarManifest`.
- `assets/pfp_mascot/hydrion_mascot.jpg`: onboarding and fallback logo/brand moments.
- `assets/icons/icon1807.jpg`: Hydrion logo component and app icon source reference.

The generated human profile-avatar JPGs are archived under `assets_source_original/removed_runtime_assets/assets/pfp_mascot/hpfp/` and are not declared in `pubspec.yaml`.

No exact duplicate runtime asset identifiers were found by
`test/asset_registry_test.dart`. No `.mp4`, `hydrion-lifestyle-*.jpg`, or
`assets/pfp_mascot/hpfp/` runtime asset is declared in `pubspec.yaml`.
