# SEC-001C Profile-Photo Cap Measurement

> Publication note (2026-10-05): Historical measurement at the SHA below, before cap approval and SEC-001C implementation. The repository path was generalized for publication; measurement results are unchanged. See [the evidence index](README.md) for the later approved policy and reproduction limits.

## Scope and preflight

Measurement only; no cap is selected, recommended, or approved. SEC-001C is not implemented or enabled.

Repository: https://github.com/The-1807/hydrion
Branch: audit/full-hydrion-integration
HEAD: ac65254e36c4a7827b444e7a30647b5c8b869fdc

CURRENT HTD.md line 1133 requires a bounded protected photo BLOB and decode/database cost measurement before enabling it. Line 1193 requires owner approval after measurements. SEC-001C / M3 / I03-I05 remains gated. No remediation status changed.

Initial Git status: only pre-existing staged edge_case.md. Its preserved SHA-256 is ac65c576d20c7d63175f1053b61a0fc99d06648659f841f9e088f0eda0733538 and staged blob is 0384da11c265db4f4bb4b6ad376d491f6bbd38fc.

## Existing pipeline

- lib/services/profile_photo_service.dart requests a gallery image with maxWidth 720, maxHeight 720, imageQuality 82, then base64-encodes returned file bytes.
- SettingsRepository trims and checks nonempty text, a 1,600,000-character maximum and a base64-character regex. The limit applies after picker processing and encoding. It is not complete base64 or image validation.
- Profile screen catches FormatException from base64Decode, then uses Image.memory without cacheWidth/cacheHeight.
- Resolved Android picker 0.8.13+23 uses PNG for alpha and JPEG otherwise; PNG quality is not controlled like JPEG quality. Resize failures can return the original path. Scaled files use the app cache.
- Resolved iOS picker 0.8.13+7 preserves PNG or uses JPEG; quality applies to JPEG. It writes temporary picker files.
- There is no independent Dart pixel-dimension guard and no explicit deletion of picker output in the inspected Dart service. Requested 720-pixel bounds are not a hard guarantee against all returned data. User gallery originals are outside this operation.
- Ordinary resized JPEGs may be well below the cap, but no real-photo distribution was measured. PNG entropy/alpha, metadata and fallback paths mean the cap can still matter. Encoded byte limits do not alone bound decoded pixel memory.

## Store and method

The accepted EncryptedAppStore currently exposes daily-context TEXT storage, not a production photo/BLOB API. Existing protected-store tests provide SQLCipher infrastructure. This experiment first initialized an empty database with EncryptedAppStore, then used a temporary STRICT measurement_photo table with one BLOB row. No production schema or data was changed.

Host: Windows 11 Pro build 26200, four logical processors; Flutter 3.44.8 / Dart 3.12.2. SQLCipher 4.18.0 community, sqlite_async 0.14.5, sqlite3 3.5.2. Factory settings matched the inspected store: synthetic 32-byte key, cipher_memory_security ON, temp_store MEMORY, WAL, synchronous=1, page size 4096, wal_autocheckpoint=1000, one reader.

Four synthetic valid 720x720 PNG fixtures were measured. A 4,946-byte checkerboard PNG was extended to exact byte sizes using a valid private ancillary PNG chunk, deterministic random padding and CRC. These exercise exact storage/decoder sizes but DO NOT represent natural-photo compression or JPEG complexity. Fixture-creation times include padding/CRC.

Seven sequential iterations per size; 28 cycles total in one process. First iteration included; raw JSON also contains warm-six summaries. Each size began with a new database, then reused it. No forced garbage collection or OS cache flush. Writes were transactional; reads compared every byte. Writer-side TRUNCATE checkpoints exposed main-file growth. Same-size replacement used different synthetic bytes.

The UI-shaped combined path reads the BLOB, encodes base64 and runs the current-style base64/image decode. It is a measurement adapter, not integrated production UI, rendering/frame latency or an implemented migration. Reopen means closing/reopening database handles in the same process, not a device reboot. Legacy input for migration/failure checks stayed in memory.

## Representations

All lengths below are exact bytes or characters, not rounded MB.

| Current cap fraction | Base64 characters | Decoded bytes | BLOB bytes |
|---|---:|---:|---:|
| 25% | 400000 | 300000 | 300000 |
| 50% | 800000 | 600000 | 600000 |
| 75% | 1200000 | 900000 | 900000 |
| 100% | 1600000 | 1200000 | 1200000 |

The 100% case is also the exact current maximum. Base64 expands these payloads by 4/3. In-memory string/object overhead is additional and is not inferred from character counts.

## Timings

Milliseconds: minimum / median / maximum across all seven iterations.

| Operation | 300000-byte BLOB | 600000-byte BLOB | 900000-byte BLOB | 1200000-byte BLOB |
|---|---|---|---|---|
| create_payload | 19.991 / 26.679 / 35.105 | 35.611 / 39.390 / 84.429 | 57.710 / 63.116 / 76.297 | 72.327 / 75.485 / 78.771 |
| base64_encode | 1.523 / 1.681 / 5.921 | 3.095 / 4.448 / 19.274 | 6.064 / 14.392 / 15.667 | 6.494 / 13.857 / 16.858 |
| base64_decode | 1.874 / 2.900 / 5.178 | 3.484 / 4.885 / 8.797 | 5.106 / 5.912 / 8.507 | 6.759 / 8.035 / 9.162 |
| insert | 6.901 / 9.729 / 13.639 | 11.980 / 17.574 / 20.974 | 14.483 / 15.368 / 23.790 | 18.406 / 21.161 / 27.778 |
| verified_read | 3.726 / 3.971 / 13.382 | 6.126 / 9.785 / 16.380 | 8.578 / 9.812 / 10.314 | 11.618 / 12.573 / 14.888 |
| replace | 7.228 / 8.525 / 12.538 | 11.215 / 15.958 / 29.273 | 15.487 / 19.559 / 27.746 | 18.436 / 24.406 / 27.787 |
| ui_base64_decode | 1.751 / 1.797 / 8.063 | 3.421 / 4.631 / 7.175 | 5.074 / 9.464 / 13.570 | 6.871 / 8.183 / 14.202 |
| image_codec | 4.496 / 5.546 / 10.995 | 8.099 / 9.908 / 21.925 | 14.316 / 16.026 / 21.056 | 34.560 / 35.412 / 37.799 |
| protected_ui_read_encode_decode_codec | 9.553 / 11.175 / 24.162 | 17.077 / 17.213 / 31.769 | 26.787 / 28.438 / 33.246 | 52.007 / 53.840 / 55.243 |
| reopen_and_verified_read | 21.722 / 22.618 / 31.303 | 25.936 / 27.793 / 57.966 | 26.901 / 28.430 / 34.349 | 29.653 / 31.404 / 32.777 |
| delete_and_verify_absence | 11.176 / 15.300 / 18.854 | 17.023 / 18.437 / 34.566 | 21.028 / 23.254 / 40.016 | 26.220 / 27.921 / 35.269 |
| migration_decode_write_verify | 12.189 / 14.298 / 18.181 | 19.578 / 26.180 / 41.615 | 26.385 / 27.864 / 31.297 | 34.725 / 37.969 / 42.794 |

Verified-read timing includes comparison. Delete includes checking absence. Migration-shaped timing includes base64 decode, transaction write and verified readback. These timings are elapsed host times, not guarantees or physical write durability measurements.

## Database and sidecars

| BLOB bytes | Initial main | Main immediately after first insert | Main after checkpoint | Main growth | First-insert WAL | Maximum sampled WAL |
|---|---:|---:|---:|---:|---:|---:|
| 300000 | 12288 | 12288 | 315392 | 303104 | 313152 | 626272 |
| 600000 | 12288 | 12288 | 622592 | 610304 | 622152 | 1244272 |
| 900000 | 12288 | 12288 | 929792 | 917504 | 931152 | 1862272 |
| 1200000 | 12288 | 12288 | 1236992 | 1224704 | 1240152 | 2480272 |

SHM was 32768 bytes; rollback journal was absent (0 bytes). WAL was zero after explicit checkpoints. All seven same-size cycles had stable checkpointed main-file size. Maximum sampled WAL occurred in the delete/migration sequence. These are file lengths at operation boundaries, not guaranteed transient peaks or allocated filesystem clusters. Production reader/checkpoint behavior can change WAL retention.

Deletion did not shrink the main file. No VACUUM or forensic-erasure claim is made. Logical deletion, checkpointing and encrypted storage do not certify backup deletion or physical flash erasure.

## Process memory

MiB, whole Flutter test process:

| BLOB bytes | Start RSS | Sampled case peak RSS | End RSS | Process lifetime high-water at case end |
|---|---:|---:|---:|---:|
| 300000 | 134.14 | 163.68 | 149.42 | 165.79 |
| 600000 | 149.80 | 171.79 | 147.36 | 186.11 |
| 900000 | 147.60 | 179.44 | 172.00 | 193.80 |
| 1200000 | 172.29 | 186.82 | 165.57 | 203.39 |

RSS sampled every 2 ms where the event loop permitted plus operation boundaries. Synchronous allocations may escape timer sampling; native process lifetime high-water is cumulative across cases, not an isolated per-payload peak. RSS includes VM, Flutter, SQLCipher workers, fixtures and previous allocations; it must not be attributed entirely to the photo.

No allocation profiler, GC isolation or mobile RAM measurement was performed. The path simultaneously creates binary/base64/readback/image buffers at points; the raw RGBA content for 720x720 is 2073600 bytes by arithmetic, not measured total decoder allocation. Same-size cycles showed stable database growth, but do not prove absence of long-running leaks.

## Readback and failure checks

- All 28 close/reopen round trips preserved exact bytes. Four final post-delete reopen checks found no row.
- A controlled transaction updated then threw before commit: rollback retained the previous exact BLOB and left the in-memory legacy source unchanged.
- A deliberate expected-value mismatch after a committed write made verification fail while leaving the legacy source unchanged. The new database value may already be committed; this tests the harness's non-destructive source handling, not a production migrator.
- Measurement directories contained only app.db and SQLite sidecars, not plaintext image files. A bounded scan found neither the synthetic plaintext marker nor its base64 prefix. This is evidence about these directories/path only, not exhaustive OS paging, crash dump or native picker-cache certification.
- The synthetic fixture key was not a user credential. No user photos or health records were used.

| Boundary | Legacy validator | Base64 decode | Image decode |
|---|---|---|---|
| Exact maximum: 1600000 characters, 1200000 bytes | Accepts | Pass | Pass |
| Maximum plus one character: 1600001 | Rejects | Fails for this malformed length | Not required |
| Valid image plus one decoded byte: 1200001 bytes, 1600004 characters | Rejects | Pass | Pass |
| Invalid alphabet AA%? | Rejects | Fails | Not attempted |
| Invalid length A | Accepts | Fails | Not attempted |
| Invalid padding AAAA==== | Accepts | Fails | Not attempted |
| Exact fixture truncated by one base64 character: 1599999 | Accepts | Fails | Not attempted |
| PNG truncated to first 32 bytes, valid 44-character base64 | Accepts | Pass | Fails |

Malformed base64 is rejected by decoding, but not reliably by the current settings regex. Valid base64 can still contain an invalid image. These are existing validation limitations, not changed here. A future authorized migration needs an explicit validation/failure policy that does not destroy its legacy source.

## Candidate caps for OWNER decision

None selected, recommended or approved. Insert/read values are median / maximum milliseconds; memory is sampled whole-process case peak, not incremental BLOB cost.

| Candidate base64 cap | Max decoded BLOB bytes | Insert ms | Verified read ms | Sampled host peak MiB | Main DB growth bytes | Compatibility |
|---|---:|---|---|---:|---:|---|
| 400000 | 300000 | 9.729 / 13.639 | 3.971 / 13.382 | 163.68 | 303104 | Reduces current size envelope by 75% |
| 800000 | 600000 | 17.574 / 20.974 | 9.785 / 16.38 | 171.79 | 610304 | Reduces current size envelope by 50% |
| 1200000 | 900000 | 15.368 / 23.79 | 9.812 / 10.314 | 179.44 | 917504 | Reduces current size envelope by 25% |
| 1600000 | 1200000 | 21.161 / 27.778 | 12.573 / 14.888 | 186.82 | 1224704 | Retains current size envelope |

Lower candidates reduce serialized/DB/WAL work but can exclude currently accepted photos. Owner policy would need to define preserving oversize legacy source, user-authorized reprocessing/reselection, and retry behavior; silent discard is not justified. The existing-cap candidate preserves the size envelope but retains larger measured costs. All candidates still require image validity and decoded-dimension policy; byte caps alone do not settle that. No real-user compatibility percentage can be inferred from these synthetic fixtures.

## Validation and reproducibility

- Temporary measurement Flutter test: 1 passed, covering 28 cycles plus boundaries and controlled failures.
- Existing test/protected_app_store_test.dart and test/protected_daily_context_test.dart: 45 passed using flutter test --no-pub.
- Early harness-only failures (nullable String compilation, then checkpoint attempted on reader connection) were corrected before the successful run. Checkpointing uses the writer lock.
- Evidence beside this report: results.json (raw results and summaries), measurement_test.dart (successful harness), and four synthetic encrypted database directories.
- The harness was run from ignored build/ for package resolution. Its retained external copy can be temporarily placed there for reproduction using flutter test --no-pub build/sec001c_photo_cap_measurement_test.dart; it generates a new temporary evidence directory.
- No full suite, analyzer, mobile build, hosted CI, device latency, battery, low-memory-device, Keychain/Keystore performance or physical-durability certification is claimed.
- No production code, settings, photos, migration, HTD states or final cap changed. No commit or push.

## Decision boundary

Final repository verification: HEAD remains ac65254e36c4a7827b444e7a30647b5c8b869fdc. Complete git status --short is only `M  edge_case.md` (staged). The temporary build/ harness was removed. Both unstaged and staged git diff --check passed. edge_case.md SHA-256 and index blob exactly match the preflight values above. No tracked or untracked source changes remain from this measurement.

These host measurements establish that exact legacy-maximum synthetic payloads completed the tested SQLCipher operations. They do not establish an acceptable mobile product budget. Owner cap approval remains required before SEC-001C / M3 / I03-I05 proceeds.

SEC-001C PHOTO CAP MEASUREMENT: READY FOR OWNER DECISION
