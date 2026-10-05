# Handoff evidence index

Publication inventory, 2026-10-05. Historical evidence retains its original scope;
copying a report does not rerun or independently certify its measurements.

## Profile-photo decision

[PHOTO_CAP_MEASUREMENT.md](PHOTO_CAP_MEASUREMENT.md) preserves the human-readable
synthetic host experiment at `ac65254e36c4a7827b444e7a30647b5c8b869fdc`.
Only its user-specific checkout path was replaced with the public repository URL,
and a publication note was added. Its pre-implementation wording is historical.

The later owner-approved SEC-001C policy, recorded in [HTD](../../../HTD.md) and
the [implementation receipt](../SEC_001C_SETTINGS_PROFILE_IMPLEMENTATION.md), is:

- Maximum protected photo: 1,200,000 decoded BLOB bytes.
- Legacy input boundary: 1,600,000 Base64 characters.
- Successful Base64 decoding where applicable and actual image decoding.
- Width and height each at most 720 pixels.
- Invalid legacy photos preserved non-destructively.
- No mobile-performance, backup, physical-durability or forensic-erasure certification.

The report describes the synthetic fixtures, iterations, storage settings,
measurement method and limitations. Its temporary harness and raw JSON remain
local experimental artifacts; they are not included or claimed to be available
after cloning. Reproducing the exact experiment requires reconstructing that
harness or obtaining a separately reviewed copy. Current production behavior is
covered by the committed photo/settings/protected-store source and tests.
Generated databases, sidecars and binary fixtures were not copied.

## Other historical local references

HTD's pre-audit evidence paragraph references `HYDRION_BASELINE_SYNC_20260926.md`,
`hydrion-audit-integration-full-tests-20260926.log`, and the downloaded artifacts
for [CI run 36249499634](https://github.com/The-1807/hydrion/actions/runs/36249499634).
At handoff, the two named files were absent from the referenced temporary folder;
the downloaded artifact directory contained empty Android subdirectories and no
files. They cannot be copied or freshly verified. HTD retains the historical
audit conclusions; this handoff does not reconstruct missing raw evidence or
claim that hosted artifacts remain downloadable.

The architecture receipts contain no additional concrete machine-local evidence
paths requiring migration. Existing build/cache directories are excluded by the
repository ignore rules. No new logs, databases, binaries, credentials or user
health records are included in this handoff.
