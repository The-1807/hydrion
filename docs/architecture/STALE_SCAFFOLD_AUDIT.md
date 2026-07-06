# Hydrion Stale Scaffold Audit

Generated: 2026-05-26

This document classifies repo areas that are present but not part of the active
Flutter runtime.

| Path | Classification | Current status | Guidance |
|---|---|---|---|
| `lib/` | Active | Root Flutter app runtime. | Treat as product code. |
| `test/` | Active | Flutter widget, service, boundary, localization, provider, and QA tests. | Keep in CI. |
| `.github/workflows/flutter-ci.yml` | Active | Flutter CI for pub get, secret scan, analyze, tests, APK, and web. | Keep green. |
| `assets/icons/icon1807.jpg` | Active | Runtime logo asset. | Keep in `pubspec.yaml`. |
| `config/prompt_templates.yaml` | Dormant | Prompt builder can load it, but active Gemini/local coach does not use it. | Mark as template only until a prompt pipeline is implemented. |
| `config/app.yaml` | Dormant | Feature flags now match disabled BLE, voice, and wearable runtime state. | Do not use as runtime truth until a config loader exists. |
| `config/open_ai_config.yaml` | Future | Placeholder OpenAI/BYOK config. | Keep out of active runtime; archive unless BYOK/OpenAI becomes a phase. |
| `config/firebase_config.json` | Future | Placeholder Firebase config. | Keep out of active runtime; archive until cloud work starts. |
| `scripts/build_release.sh` | Partially active | Root Flutter build commands mostly match current project. | Update after release metadata/signing is decided. |
| `scripts/test_all.sh` | Dormant/stale | References old `app/`, Gradle/KMP, logs, and integration paths. | Do not use for CI until rewritten. |
| `scripts/lint_all.sh` | Dormant/stale | References old `app/`, Gradle/KMP, and Python lint assumptions. | Do not use for CI until rewritten. |
| `scripts/deploy_firebase.sh` | Future/stale | References missing `cloud/functions`. | Keep dormant until cloud scope exists. |
| `scripts/dev_setup.sh` | Experimental/stale | References old app/FFI paths and broad Rust tooling. | Treat as experimental; rewrite before recommending. |
| `core/` | Experimental/future | Rust crates exist but Cargo workspace names do not match all directories and Flutter does not call them. | Decide active vs archive before ELKA/Rust work. |
| `packs/byok_llm/` | Future | BYOK scaffolding not wired to Flutter runtime. | Keep outside active provider path. |
| `packs/gemini_connector/` | Future/stale | Separate from active `lib/adapters/gemini` adapter. | Avoid confusing it with the active Gemini provider. |
| `packs/edge_llm/` | Future | Empty edge model placeholders. | Archive unless edge model work starts. |
| `models/training/` | Experimental | Python training scripts not wired to app runtime or CI. | Keep experimental; do not imply shipped model behavior. |
| `i18n/` | Dormant | Old empty i18n placeholder. | Active localization is `lib/l10n`. |
| `assets/sounds/`, `assets/ui/` | Future placeholders | Empty `.gitkeep` folders not listed as runtime assets. | Keep only if roadmap needs them. |
