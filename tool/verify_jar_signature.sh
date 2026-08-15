#!/usr/bin/env bash
set -euo pipefail

artifact="${1:?Usage: verify_jar_signature.sh <jar-or-aab>}"

# jarsigner's verification model cross-checks every entry between a JarFile
# scan and a JarInputStream scan. Android App Bundles route module metadata
# entries (META-INF/*.version, BUNDLE-METADATA, and similar) through the
# packager in a way that jarsigner reports as "signed in JarFile but is not
# signed in JarInputStream" even for a bundle that is genuinely, validly
# signed. That's a documented jarsigner/AAB interaction, not a signing
# defect - but it makes jarsigner return a non-zero exit status (and, in
# -strict mode, a bit outside the single value this script used to check
# for) even when the underlying signature is fine. So the exit status alone
# can't be the success signal here; classify the actual output instead and
# only fail on text that indicates a real problem with the signature.
strict_status=0
strict_output="$(jarsigner -verify -strict "$artifact" 2>&1)" || strict_status=$?
printf '%s\n' "$strict_output"

if test "$strict_status" -eq 0; then
  exit 0
fi

# Use here-strings (<<<), not `printf ... | grep -q`, for every check below.
# Under `set -o pipefail`, `grep -q` exits the instant it finds a match and
# closes its end of the pipe; `printf` is often still writing the rest of
# jarsigner's (multi-thousand-line) output at that point, gets SIGPIPE, and
# pipefail then reports that as the pipeline's exit status instead of
# grep's. That silently turned genuine matches into reported failures here
# ("printf: write error: Broken pipe" in the CI logs). A here-string hands
# grep the whole buffer up front with no concurrent writer to kill.
if grep -Eqi \
  'expired|not yet valid|security risk|treated as unsigned|jar is unsigned|no manifest|signature (is )?invalid|signature does not verify|digest error|unable to verify' \
  <<< "$strict_output"; then
  echo "::error::JAR signature failed strict verification."
  exit "$strict_status"
fi

# "disabled"/"weak" are deliberately not matched as bare words above: real
# jarsigner weak/disabled-algorithm warnings always say "...is considered a
# security risk...", but plenty of legitimate AAB entries (Android/Play
# Services resources such as googleg_disabled_color_18.png or
# abc_list_selector_disabled_holo_dark.9.png) contain "disabled" as part of
# the filename, which previously made this script fail valid signatures.
if grep -Eqi \
  'certificate chain is invalid|signer certificate is self-signed|PKIX path building failed|unable to find valid certification path|is signed in JarFile but is not signed in JarInputStream|does not include a timestamp|manifest is missing when reading via JarInputStream' \
  <<< "$strict_output"; then
  echo "::notice::Signature is valid; strict verification reported only known-benign warnings (self-signed/untrusted chain, Android App Bundle entry metadata, or a missing timestamp)."
  exit 0
fi

echo "::error::JAR signature failed strict verification."
exit "$strict_status"
