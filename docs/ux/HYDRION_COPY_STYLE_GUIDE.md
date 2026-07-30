# Hydrion Copy Style Guide

Hydrion uses direct, ordinary language. Visible text must help someone
understand, decide, recover, or complete an action.

## Rules

- Lead action labels with verbs: `Join challenge`, `Pause`, `Review goal`.
- Describe the user-visible state, not the implementation state.
- Never render enum names, identifiers, storage keys, reason codes, schema
  versions, raw exceptions, or debug values.
- Keep eligibility and audience metadata internal. Eligible experiences appear
  naturally; the interface does not announce profile classifications.
- Preserve clear health, consent, privacy, permission, destructive-action, and
  recovery guidance.
- Use one concise description on catalog cards. Put instructions and schedules
  on the detail screen.
- Localize visible and semantic text in English, French, and Spanish.
- Do not encode words in artwork.

## Error Pattern

State what happened, say what remains safe or unchanged when relevant, and give
one recovery action. Do not expose the exception type.
