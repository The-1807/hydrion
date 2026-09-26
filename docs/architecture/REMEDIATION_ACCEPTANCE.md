# Remediation Implementation and Independent Acceptance

HTD.md owns findings, stages and dependencies. This is the small reusable evidence
format and review procedure, not a second remediation ledger. Stage 0A introduces
contracts/harnesses only; it does not certify the existing application.

## Test meaning

`test/support/architecture_test_support.dart` labels two different kinds of test:

- CHARACTERIZATION identifies an OPEN finding, describes observed behavior and
  names the desired invariant. Passing preserves defect evidence; it does not
  approve that behavior. At the owning remediation stage replace the broken
  expectation with the accepted invariant and retain the original failure case.
- INVARIANT asserts desired behavior at a public boundary. Every new helper-based
  invariant has an explicit negative control which must be rejected by the same
  matcher. A positive-only happy-path check is insufficient evidence.

Existing `boundary_architecture_test.dart` continues to guard AI/UI/provider
boundaries. The new literal dependency guard adds only domain-to-UI isolation; it
is not a full Dart parser or runtime reachability proof. It resolves relative,
package and conditional directive URIs. Future robust call-graph guards must not
be inferred from a passing lexical check. Do not ban currently open domain-to-
repository dependencies and then claim their remediation is complete.

The initial behavioral characterizations cover DATA-007, DATA-008, DATA-003 and
ORCH-001 using synthetic memory stores, deterministic dates and direct public
boundaries. The controlled secure-store fake models supported-but-failing writes
and swallowed deletes; it is not physical Keychain/Keystore evidence. They do not
alter those findings or implement Stages 1/2/4. Unsupported health-persistence
readiness is a small existing invariant, not proof Web startup works.

## Diagnostic and error convention

`lib/domain/local_diagnostic.dart` is local/in-process only and has no production
callers yet. It deliberately has no logger, remote sink, dependency, persistence,
free-form message, exception, raw stack, user identifier or metadata map.
Subsystem/operation/disposition are derived from a closed code vocabulary;
callers cannot relabel a failed code as successful. Correlation IDs are generated
process-local sequence tokens, not account/record/provider identifiers. Timestamp
is captured from an explicitly supplied clock at observation time, not from a
health event. No app-wide calendar/clock refactor is implied.

No hydration amounts, body/clinical/reproductive values, fingerprints, payloads,
secrets, tokens or user-entered text may be added to this envelope. Any new field
or code requires a disclosure review and contract tests. Do not hash sensitive
values into a correlation ID. No optional metadata is needed by this foundation.

Diagnostic disposition is interpretation, not a universal domain result type.
Keep existing `HealthPersistenceResult`, health synchronization statuses,
`StorageRecoveryEvent` and provider diagnostics. Later domain-specific result
types must distinguish unavailable/absent, verified/unverified and partial/full
completion at the operation boundary. A diagnostic alone never proves a write or
delete succeeded and does not fix swallowed exceptions. Map reviewed outcomes
explicitly at each later caller; never map unknown exceptions to success.

## Evidence record template

Use this compact template in the implementation task or an existing validation
report. No per-run raw logs belong in HTD. Evidence artifacts must exclude secrets
and personal health records; record synthetic-fixture identity, not real values.

```yaml
stage: 0A
baseline_sha: <full SHA>
implementation_sha: <full SHA or UNCOMMITTED, never invented>
finding_ids: []
changed_files: []
tests_added_or_changed: []
focused_validation:
  - command: <exact command>
    result: <PASS|FAIL|TIMEOUT|INCOMPLETE|SKIPPED|NOT_RUN>
    exit_code: <integer or UNKNOWN>
    completed: <true or false>
    observed_total: <verified count or UNKNOWN>
    evidence: <artifact/log reference and hash where available>
broader_validation: []
known_failures: []
evidence_limits: []
independent_acceptance:
  status: <NOT_REQUESTED|PENDING|ACCEPTED|BLOCKED|REJECTED>
  reviewer: <independent reviewer identity or NONE>
  reviewed_sha: <full SHA or NONE>
  evidence: <read-only acceptance report reference or NONE>
changed_invariants: []
```

Capture command completion and exit status independently from test-count summaries.
TIMEOUT is never PASS, even if all completed tests passed or a generated report
claims zero failures. Exit 124/time-limit termination is TIMEOUT. Interrupted or
missing completion evidence is INCOMPLETE. A nonzero non-timeout exit or a raw
failing test is FAIL. PASS requires successful completion, exit zero and no
contradictory raw failures. SKIPPED/NOT_RUN are never successful execution.
Unknown totals remain UNKNOWN; never infer full-suite totals from focused runs.
If raw events disagree with a generated summary, retain both and report the
contradiction; do not change the result to PASS. This is a review convention;
repairing the CI summarizer belongs to Stage 0B and is not implemented here.

## Independent acceptance

OPEN -> IN_PROGRESS -> IMPLEMENTED_PENDING_ACCEPTANCE -> independent read-only
audit -> ACCEPTED. The implementer cannot be the acceptance reviewer. Independent
acceptance checks the exact implementation SHA, invariants, negative controls,
changed-file scope, raw evidence and non-goals. A coding agent may report its
implementation and self-review but must not approve its own remediation.

BLOCKED acceptance records unavailable evidence; REJECTED acceptance records the
failed criterion and returns the finding to IN_PROGRESS. Neither closes the
stage. Owner-approved DEFERRED requires rationale/risk/revisit conditions and does
not silently satisfy dependent gates. An unrelated known baseline failure can
coexist with explicitly scoped acceptance, but a relevant failure cannot be
waived merely because it is pre-existing. Physical, hosted and fake evidence are
separate. Stage 0A acceptance is required before Stages 1, 2 or 4 implementation.

For accepted findings HTD stores only final state, implementation SHA, acceptance
reference and changed invariant. Implementations require tasks, tests/evidence,
documentation and commits. No self-approval, raw log dump or automatic connector
unpause is permitted. Muse remains final under HTD Stage 10.

## Stage 0A implementation receipt

Baseline: `9ae695091711df47991417cee84ea5732601c90a` on
`audit/full-hydrion-integration`. Findings: HTD-DOC-001, HTD-TEST-002,
HTD-OBS-001. Implementation SHA and current state are recorded in HTD after
the scoped implementation commit. Independent acceptance: PENDING, reviewer
NONE, reviewed SHA NONE. No changed architectural invariant; the added guard
makes the existing inward-dependency requirement executable.

Implementation-side commands (2026-09-26; completed with exit 0):

```text
flutter test --no-pub --reporter expanded test/boundary_architecture_test.dart test/local_diagnostic_test.dart test/remediation_characterization_test.dart test/remediation_control_test.dart
  PASS: 24 tests, including four defect characterizations and negative controls.
flutter test --no-pub --reporter expanded test/health_database_key_store_test.dart test/sensitive_body_metrics_store_test.dart
  PASS: 11 existing tests.
flutter analyze --no-pub
  PASS: no issues.
dart format --output=none --set-exit-if-changed lib/domain/local_diagnostic.dart test/support/architecture_test_support.dart test/local_diagnostic_test.dart test/remediation_characterization_test.dart test/remediation_control_test.dart test/boundary_architecture_test.dart
  PASS: six files, zero changes.
dart run tool/secret_scan.dart
  PASS.
```

Evidence is command output from this implementation run plus reproducible tests;
no raw log artifact or new hosted/device certification is claimed. Existing
boundary tests were retained. Locked connector sections 2 and 3 were compared
against the baseline and are unchanged. Git diff/whitespace and preservation
checks are performed before scoped commits; the committed file list is the
implementation's Git diff, not an inferred whole-repository test result.

Broader validation NOT_RUN: complete Flutter suite, builds, devices and hosted
CI. Known baseline failures remain exactly as HTD section 12 records: formatting
in two unrelated files, full-suite timeout/stall, CI summary mismatch and two
literal-audit findings. Evidence limits: synthetic storage only, lexical guard,
no production adoption of the diagnostic contract, no independent acceptance.
The diagnostic tests exercise the envelope, not all current logging callers.
The document-status test checks status markers, not a medical/security audit.
