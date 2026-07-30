# Hydrion Challenge Visual Standard

Challenge artwork is a primary identity layer, not a decorative icon.

## Card Contract

- Catalogue cards use a stable 176 px hero region on phones and larger layouts.
- Artwork uses `BoxFit.contain` with a safe inset so supplied transparent art is not cropped.
- The title is anchored inside the hero composition with theme-aware contrast.
- Description, progress, metadata, and action follow the hero in that order.
- Every challenge owns a distinct final hero asset. Profile-aware variants are allowed within one challenge.
- Missing assets may use the registry fallback only as an error state, never as planned final art.
- Bottle Bingo remains the reference for visual strength, responsive balance, and concise supporting copy.

Hero images are excluded from accessibility semantics because the challenge title and card action already provide the meaningful label.
