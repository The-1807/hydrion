# Hydrion — Security Test Matrix

Maps every security/privacy finding in `AUDIT_REPORT.md` §6.2 to its verification method, current status, and relevant MASVS/MASTG identifier. This is the living document to re-run at every release candidate.

| Finding ID | Area | MASVS/MASTG | Test method | Status at audit time | Test case(s) |
|---|---|---|---|---|---|
| HYD-SEC-001 | Unencrypted health/PII storage | MASVS-STORAGE-1, MASVS-STORAGE-2 / MSTG-STORAGE-1, MSTG-STORAGE-2 | Static code read (`local_store.dart`, repository storage keys) + live rooted-device extraction | **Confirmed, unresolved** — highest-severity finding | TC-SEC-001, TC-WIPE-001 |
| HYD-SEC-002 | iOS privacy manifest missing required-reason API declaration | Apple App Store privacy-manifest policy | Static code read (`PrivacyInfo.xcprivacy` vs `HydrionWidgets.swift:35`) | **Confirmed, unresolved** | TC-IOS-001, TC-IOS-002 |
| HYD-SEC-003 | Gemini API key embedded in compiled binary | MASVS-CRYPTO-1 / MSTG-STORAGE-14 | Static code read (`ai_provider_config.dart:129`) | **Confirmed pattern; server-side key-restriction posture UNVERIFIED (outside repo visibility)** | Manual — verify Google Cloud console key restrictions directly, not a repo test |
| HYD-SEC-004 | No Android release minification/obfuscation | MASVS-RESILIENCE-1 / MSTG-RESILIENCE-9 | Static config read (`build.gradle.kts:63-64`) | **Confirmed, unresolved** | TC-AND-003 (post-fix regression) |
| HYD-SEC-005 | Dependency staleness | General SDLC hygiene | `dart pub outdated --show-all` | **Confirmed; no CVE lookup performed (out of scope for read-only pass)** | TC-REGR-003 (extend to check for CVEs once a `dart pub audit`-equivalent tool exists) |
| HYD-SEC-006 | Dead config files shipped as compiled assets | MASVS-STORAGE-1 / MSTG-STORAGE-14 (hygiene) | Static code read + `pubspec.yaml` asset declaration | **Confirmed; currently placeholders only, no live secret exposed** | Extend `tool/secret_scan.dart` to also scan `pubspec.yaml`-declared asset paths |
| HYD-SEC-007 | Non-release-guarded `debugPrint` | MASVS-STORAGE-3 / MSTG-STORAGE-3 | Static code read (`android_widget_service.dart:318`) | **Confirmed, unresolved, low severity** | Manual code review checklist item for future PRs |
| HYD-SEC-008 | No root/jailbreak detection | MASVS-RESILIENCE-1 / MSTG-RESILIENCE-1 | Static absence-check | **Confirmed absent — accepted-risk decision needed from owner, not an automatic defect** | n/a until a decision is made |
| HYD-SEC-009 | No certificate pinning | MASVS-NETWORK-2 / MSTG-NETWORK-4 | Static absence-check | **Confirmed absent — optional control, standard TLS/ATS protection is in place and correct** | n/a (defense-in-depth backlog item) |
| — | Secret scanning | n/a (SDLC control) | `dart run tool/secret_scan.dart`, CI-gated | **Clean, working, CI-enforced** | TC-SEC-002 |
| — | AI-provider consent gate | n/a (privacy control) | Code read (`hydration_ai_orchestrator.dart:118-120`) + test | **Confirmed correctly implemented and matches privacy policy text** | TC-SEC-003 |
| — | Android backup exclusion | n/a | Manifest read (`allowBackup=false`) | **Declared correctly; live `adb backup` confirmation not performed in this pass** | TC-SEC-004 |
| — | Cleartext traffic / TLS bypass | MASVS-NETWORK-1 | Static code read + manifest/`Info.plist` read | **Confirmed clean — no cleartext, no cert-bypass code, ATS fully enforced** | TC-IOS-003 |
| — | WebView attack surface | n/a | Static absence-check (`webview_flutter` not a dependency) | **Confirmed absent — no WebView anywhere in the app** | n/a |
| — | Deep-link/URL-scheme hijacking risk | MASVS-PLATFORM-3 / MSTG-PLATFORM-3 | Static code read (`Info.plist`, `AppDelegate.swift`, Android manifest) | **Confirmed low risk — scheme exists but no sensitive action is gated behind it, and no handler even parses incoming URLs on iOS** | TC-LINK-001, TC-LINK-002, TC-LINK-003 |
| — | Screenshot/app-switcher exposure of sensitive fields | n/a directly (data-exposure adjacent) | **Not checked in this audit — genuine gap in the audit itself** | **UNVERIFIED — new test needed** | TC-SEC-005 |
| HYD-CORR-001 | Crash risk from unguarded `context` access (not strictly "security" but a stability/DoS-adjacent concern) | n/a | Static code read | **Confirmed, unresolved, High severity** | TC-CTRL-004 |
| HYD-CORR-002 | Data-integrity race under persist failure | n/a | Static code read | **Confirmed, unresolved, Medium severity** | TC-RES-001 |

## Coverage gaps in this matrix itself

- **No dynamic/runtime SAST or DAST tool was run** beyond `flutter analyze` + the project's own five custom `tool/*.dart` scripts. Per the audit's own constraint (do not add tooling without first proving the existing stack insufficient), this matrix does not currently include MobSF, Semgrep, or similar — if the owner wants that coverage, it should be evaluated as a deliberate addition, not assumed.
- **No penetration test of the Gemini REST integration** was performed (e.g., fuzzing the response-parsing path in `gemini_adapter.dart` with malformed/adversarial API responses) — the existing unit tests (`gemini_provider_test.dart`) cover malformed/oversized/invalid-schema responses reasonably well per the audit's read of that file, but an adversarial fuzz pass was not independently run.
- **No network traffic capture/inspection (e.g., mitmproxy/Charles) was performed live** to independently confirm the exact payload sent to Gemini/Open-Meteo matches what the source code implies — the audit's finding on Gemini payload contents (§6.2, cross-referenced in `AUDIT_REPORT.md` §6.2's AI/LLM privacy section) was derived from reading `_buildPrompt` directly, not from a live capture. A live capture is recommended as a confirming step before this matrix is considered fully closed on that point.
