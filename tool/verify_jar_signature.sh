#!/usr/bin/env bash
set -euo pipefail

artifact="${1:?Usage: verify_jar_signature.sh <jar-or-aab>}"

verify_status=0
verify_output="$(jarsigner -verify "$artifact" 2>&1)" || verify_status=$?
printf '%s\n' "$verify_output"
if test "$verify_status" -ne 0 ||
  ! printf '%s\n' "$verify_output" | grep -Eqi '^jar verified'; then
  echo "::error::JAR signature cryptographic verification failed."
  exit 1
fi

strict_status=0
strict_output="$(jarsigner -verify -strict "$artifact" 2>&1)" || strict_status=$?
printf '%s\n' "$strict_output"
if test "$strict_status" -eq 0; then
  exit 0
fi

if test "$strict_status" -eq 4 &&
  printf '%s\n' "$strict_output" | grep -Eqi 'certificate chain is invalid|signer certificate is self-signed|PKIX path building failed|unable to find valid certification path' &&
  ! printf '%s\n' "$strict_output" | grep -Eqi 'expired|not yet valid|disabled|weak|treated as unsigned|signature (is )?invalid|signature does not verify|digest error'; then
  echo "::notice::Signature is valid; strict verification reported only the expected self-signed/untrusted-chain warning."
  exit 0
fi

echo "::error::JAR signature failed strict verification."
exit "$strict_status"
