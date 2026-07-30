# Hydrion Artwork Audit

Audit date: 2026-07-30

The former registry mixed challenge-specific artwork with general UI artwork.
Those files remain available to their original non-challenge surfaces, but no
longer act as final challenge artwork.

| Challenge set | Previous state | Unique and appropriate | Final behavior |
|---|---|---:|---|
| Original six challenges | Mostly challenge-specific, with repeated card/detail files and inconsistent JPG/PNG formats | Partial | Exact unique PNG path; ID-specific fallback until supplied |
| Lunch, study, afternoon, backpack challenges | Unrelated generic challenge, running, intake, and pride assets | No | Exact unique PNG path; ID-specific fallback until supplied |
| Desk, shift, travel, evening challenges | Generic goals, check, weather, and summer assets | No | Exact unique PNG path; ID-specific fallback until supplied |

The canonical source of runtime paths is
`lib/domain/challenge_visual_registry.dart`. The machine-readable request source
is `assets/images/challenges/artwork_manifest.json`. No two challenge IDs share
a final path. Missing files do not crash or leave a blank surface.
