# LottieFiles Shark Animation Evidence

## Asset Record

- **Asset name:** Hydrion shark loading animation
- **Runtime asset:** `assets/buffer/Shark.json`
- **Original downloaded file retained at:** `assets/buffer/Shark.lottie`
- **Permanent LottieFiles share URL:** https://app.lottiefiles.com/share/a1310b00-ea2c-4d3a-b580-688ad4c56291
- **Source platform:** LottieFiles
- **Internal animation title:** `animals 3`
- **dotLottie animation id:** `12345`
- **Manifest author:** `LottieFiles`
- **Generator:** `dotLottie-js`
- **Download/import date:** 2026-07-07
- **Source verification date:** 2026-07-07
- **Local SHA-256:** `3A815B72240EB4F3280801F6AE1D0DC555054AC2875A6D46D3EF6BB87A51B2BB`
- **Windows source metadata:** `Zone.Identifier` contains
  `HostUrl=https://app.lottiefiles.com/`

## Source Evidence

- The permanent share URL returned HTTP 200 on 2026-07-07.
- The temporary browser blob URL is not used as release evidence.
- The static share page HTML did not expose creator name, owner workspace,
  animation-specific licence wording, attribution requirements, or commercial
  use terms.
- The static share page did preload a hosted dotLottie file at
  `https://lottie.host/16b69e12-0efb-4061-b33d-12dc2b93fd84/Ax2k12jKRd.lottie`.
  That hosted file is not byte-identical to the bundled file, so it is not
  treated as a binary match for `assets/buffer/Shark.lottie`.
- The general LottieFiles Lottie Simple License page was discoverable through
  public search and describes broad permissions for public animation files,
  including modification and commercial use, with attribution encouraged but
  not required. Because the share page itself did not display animation-specific
  terms in static HTML, production approval still requires owner/legal review.
- **Creator name:** Pending; the local file manifest only identifies
  `LottieFiles`.
- **Licence screenshot or PDF:** Pending owner-supplied capture if the signed-in
  source page displays animation-specific licence state.

## Repository Handling

- Hydrion bundles the animation locally in `assets/buffer/` instead of loading
  it from the LottieFiles CDN.
- Runtime code loads `assets/buffer/Shark.json`, extracted from
  `animations/12345.json` in the retained dotLottie source bundle.
- No modification has been made to the downloaded `.lottie` file.
- In-app credit is shown under Settings -> About Hydrion -> Credits and
  licences via the existing About & Legal screen.
- The release checklist stores the permanent share URL and usage documentation
  as completed evidence, but keeps creator identity, animation-specific licence
  evidence, and production approval unchecked.
