# Hydrion Artwork Audit

Audit date: 2026-07-30

The registry preserves the six owner-supplied challenge images. Eight newer
challenges previously pointed at unrelated general UI artwork and need their
own images.

| Challenge set | Previous state | Unique and appropriate | Final behavior |
|---|---|---:|---|
| Original six challenges | Owner-supplied, challenge-specific artwork | Yes | Existing original asset remains mapped to its challenge |
| Lunch, study, afternoon, backpack challenges | Unrelated generic challenge, running, intake, and pride assets | No | Exact unique PNG path; ID-specific fallback until supplied |
| Desk, shift, travel, evening challenges | Generic goals, check, weather, and summer assets | No | Exact unique PNG path; ID-specific fallback until supplied |

Retained owner-supplied assets:

- `assets/UI_BETA/arounddworld-card.png`
- `assets/UI_BETA/temp-roulette-card.png`
- `assets/UI_BETA/eatyourwater-card.png`
- `assets/UI_BETA/pomodoro-card.jpg`
- `assets/UI_BETA/planttwin-card.png`
- `assets/UI_BETA/ble_bottle.png`

The canonical source of runtime paths is
`lib/domain/challenge_visual_registry.dart`. The machine-readable request source
is `assets/images/challenges/artwork_manifest.json`. No two challenge IDs share
a final path. Missing files do not crash or leave a blank surface.
