# Hydrion Startup Droplet Loader

Status: implemented as a native Flutter startup element for v1 owner review.

## Architecture

`HydrionDropletLoader` is a reusable Flutter widget built with `CustomPainter`,
`TweenAnimationBuilder`, `AnimationController`, `Semantics`, and
`RepaintBoundary`. It does not use HTML, CSS, WebView, an MP4, or a heavy motion
dependency.

The widget accepts a real `progress` value from `0.0` to `1.0`, clamps unsafe
values, and paints the supplied Hydrion droplet geometry as scalable vector
paths. Startup owns the progress source through one `ValueNotifier<double>` in
`StartupScreen`.

## Startup Phases

The current startup architecture exposes discrete milestones rather than a
fine-grained task graph:

- `0.08`: underwater scene and startup run created.
- `0.16`: warmup started.
- `0.72`: app warmup completed.
- `0.88`: minimum startup scene duration completed.
- `1.00`: routing handoff is ready.

Warmup still runs concurrently with the startup scene. The loader does not add a
long blocking wait; it only holds completion briefly for a clean visual handoff.

## Droplet Painter

The painter translates the source SVG path:

`M50 5 C50 5, 15 50, 15 68 C15 87.3, 30.7 100, 50 100 C69.3 100, 85 87.3, 85 68 C85 50, 50 5, 50 5 Z`

The path is scaled to the widget bounds with an inset so the glow, rim, and
shadow do not clip. Liquid fill rises vertically from the bottom based on
progress. Two clipped wave layers move horizontally with different phase,
amplitude, opacity, and direction.

## Reduced Motion

When platform reduced motion is enabled, the shark travel is simplified, wave
looping stops, and the droplet uses a short linear fill update. The startup still
shows the Hydrion mascot, liquid level, and progress semantics.

## Completion Handoff

At high progress the droplet glow intensifies and a circular ring appears in the
same visual center. At `1.0`, the droplet scales/fades subtly while the ring
becomes visible, then startup routes to onboarding or Home according to the
existing settings decision.

## Performance

The animated droplet is isolated with `RepaintBoundary`; the wave controller
repaints only the droplet widget. Startup uses the existing scene controller plus
the droplet's internal wave controller, both disposed normally.

## Current Art Limits

The mascot remains a flattened PNG, so the startup uses safe native transforms:
tilt, scale, opacity, and buoyancy. A future Rive pass could add true layered
blink, fin, or swim-cycle animation if owner-supplied layered mascot art exists.
