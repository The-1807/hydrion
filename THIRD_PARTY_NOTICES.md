# Third-Party Notices

This file records third-party materials that are bundled with Hydrion or used
to build Hydrion. Hydrion's own license remains separate from these third-party
license terms.

## LottieFiles Shark Loading Animation

- **Asset name:** Hydrion shark loading animation
- **Bundled asset:** `assets/buffer/Shark.lottie`
- **Original downloaded file retained at:** `assets/buffer/Shark.lottie`
- **Permanent source reference:** https://app.lottiefiles.com/share/a1310b00-ea2c-4d3a-b580-688ad4c56291
- **Source platform:** LottieFiles
- **Internal animation name:** `animals 3`
- **dotLottie animation id:** `12345`
- **File manifest author:** `LottieFiles`
- **Generator:** `dotLottie-js`
- **Download/import date:** 2026-07-07
- **Source verification date:** 2026-07-07
- **Windows source metadata:** `Zone.Identifier` records
  `HostUrl=https://app.lottiefiles.com/`
- **Local SHA-256:** `3A815B72240EB4F3280801F6AE1D0DC555054AC2875A6D46D3EF6BB87A51B2BB`
- **Creator name:** Not visible in the downloaded file manifest or static share
  page HTML inspected on 2026-07-07
- **Displayed animation-specific licence evidence:** Not visible in the static
  share page HTML inspected on 2026-07-07; screenshot/PDF evidence is still
  required if the signed-in LottieFiles page displays additional terms
- **General LottieFiles licence note:** LottieFiles' public Lottie Simple
  License page describes broad download, modification, and commercial-use
  permissions for public animation files and says attribution is permitted but
  not required. This is not a substitute for animation-specific evidence if the
  share page or account workspace shows a different licence state.
- **Modifications in Hydrion:** None to the downloaded `.lottie` file; Hydrion
  only selects `animations/12345.json` from the local dotLottie bundle at
  runtime
- **Runtime use:** Startup/loading animation, bundled locally for offline use
  and to avoid loading from the LottieFiles CDN
- **Hosted source comparison:** The recovered share page currently preloads
  `https://lottie.host/16b69e12-0efb-4061-b33d-12dc2b93fd84/Ax2k12jKRd.lottie`,
  whose SHA-256 differs from the bundled file. Treat the share page as source
  reference evidence, not proof that the current hosted binary is identical to
  `assets/buffer/Shark.lottie`.
- **Production approval:** Pending creator identity and animation-specific
  licence evidence review.

Suggested in-app attribution while creator evidence is incomplete:

> Loading animation by LottieFiles, obtained from LottieFiles for Hydrion.

Once the original creator is verified, replace the in-app and repository
wording with:

> Loading animation by [Creator Name], obtained from LottieFiles and modified
> for Hydrion.

## lottie Flutter Package

- **Package:** `lottie`
- **Purpose:** Renders the bundled dotLottie loading animation from local app
  assets.
- **Source:** https://pub.dev/packages/lottie
- **Licence:** MIT License, as published with the package.
