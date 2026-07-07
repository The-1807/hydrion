# Hydrion Startup Loading Animation

Status: implemented with the bundled shark dotLottie asset and native fallback
for v1 owner review.

## Architecture

`HydrionDropletLoader` is a reusable Flutter widget that renders the bundled
`assets/buffer/Shark.lottie` animation with the `lottie` package. It keeps the
existing native droplet painter as a static fallback for reduced-motion users,
loading placeholders, and asset/decode failures. It does not load animation
data from the LottieFiles CDN.

The widget accepts a real `progress` value from `0.0` to `1.0`, clamps unsafe
values, and exposes progress through semantics. Startup owns the progress
source through one `ValueNotifier<double>` in `StartupScreen`.

## Startup Phases

The current startup architecture exposes discrete milestones rather than a
fine-grained task graph:

- `0.08`: underwater scene and startup run created.
- `0.16`: warmup started.
- `0.72`: app warmup completed.
- `1.00`: routing handoff is ready.

Startup does not add a fixed splash delay. The loader remains visible while the
real warmup future is pending, then waits for the current frame boundary before
routing so a quick startup does not block on decoration.

## dotLottie Asset

The bundled file is a dotLottie ZIP archive containing `manifest.json` and
`animations/12345.json`. The `lottie` package's default ZIP decoder would find
`manifest.json` first, so Hydrion provides a decoder that selects the animation
JSON directly.

## Droplet Fallback

The fallback painter translates the source SVG path:

`M50 5 C50 5, 15 50, 15 68 C15 87.3, 30.7 100, 50 100 C69.3 100, 85 87.3, 85 68 C85 50, 50 5, 50 5 Z`

The path is scaled to the widget bounds with an inset so the glow, rim, and
shadow do not clip. Liquid fill rises vertically from the bottom based on
progress. The fallback is static by design so a failed Lottie load does not
leave startup in an infinite animation state.

## Reduced Motion

When platform reduced motion is enabled, Hydrion does not play the Lottie loop.
The startup still shows a static Hydrion loading mark and progress semantics.

## Completion Handoff

At high progress the completion ring appears in the same visual center. At
`1.0`, startup routes to onboarding or Home according to the existing settings
decision without an artificial hold.

## Performance

The Lottie widget and fallback are isolated with `RepaintBoundary`. Startup uses
the existing scene controller and routes immediately after real initialization
finishes.

## Licence Evidence

The recovered permanent LottieFiles share URL is
`https://app.lottiefiles.com/share/a1310b00-ea2c-4d3a-b580-688ad4c56291`.
Static source-page inspection on 2026-07-07 did not expose creator identity or
animation-specific licence wording, so production approval remains blocked on
owner/legal evidence. The asset record lives in `THIRD_PARTY_NOTICES.md` and
`docs/third_party/lottiefiles_shark_animation.md`.
