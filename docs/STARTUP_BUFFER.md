# Hydrion Startup Buffer

Status: implemented with a bundled shark JSON Lottie runtime asset for v1 owner
review.

## Runtime Behavior

Startup shows a minimal Flutter buffer after the native splash:

- `assets/buffer/Shark.json`
- `Welcome`
- `Preparing your hydration space...`

There are no background images, cards, progress bars, secondary loaders,
mascots, or extra decorative objects. The text may fade between the two states;
the shark Lottie is the only visual animation. When platform reduced motion is
enabled, Hydrion keeps the same shark Lottie asset visible without looping it.

## Route Handoff

`StartupScreen` starts app warmup while the buffer is visible. The buffer waits
for the current accepted minimum visible duration before handing off to the
normal route decision: onboarding, legal review, or Home.

## Lottie Asset

The original downloaded `assets/buffer/Shark.lottie` dotLottie ZIP is retained
as source evidence. Runtime startup uses the extracted
`assets/buffer/Shark.json` animation so launch does not depend on ZIP selection
during startup.

## Licence Evidence

The recovered permanent LottieFiles share URL is
`https://app.lottiefiles.com/share/a1310b00-ea2c-4d3a-b580-688ad4c56291`.
Static source-page inspection on 2026-07-07 did not expose creator identity or
animation-specific licence wording, so production approval remains blocked on
owner/legal evidence. The asset record lives in `THIRD_PARTY_NOTICES.md` and
`docs/third_party/lottiefiles_shark_animation.md`.
