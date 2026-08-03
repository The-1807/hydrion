# Hydrion Settings Completion Rules

Every editable setting must expose both its action and its resulting state.

## Interaction Language

- **Save** persists a form or settings group.
- **Done** closes an editor and returns to its summary.
- **Apply** accepts a generated or suggested value.
- **Continue** advances an onboarding step.
- **Update** changes an existing saved value.
- **Edit** reopens a saved summary.
- **Enable**, **Enabled**, and **Disable** describe capability state.
- **Not now** declines an optional step without implying failure.

## Completion Contract

After success, persist first, update visible state, collapse heavy editors, and show the saved summary. Permission requests must show requesting, granted, denied, settings-required, or unavailable state. A snackbar can reinforce success but must not be the only acknowledgment.

Body metrics, daily context, challenge preferences, suggested goals, onboarding permissions, and weather assistance follow this contract. Future settings must add summary/edit tests alongside persistence tests.
