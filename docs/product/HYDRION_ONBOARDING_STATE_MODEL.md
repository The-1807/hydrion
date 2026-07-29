# Hydrion Onboarding State Model

Onboarding uses persisted completed-step state. Before opening a nested Body
Metrics editor, the Basic Profile step validates and saves its nickname, age,
and optional identity value. The nested editor therefore reads the same age the
user currently sees.

New independent profiles require an age from 13 through 120. Values below 13,
corrupt values, and missing age remain on Basic Profile with an explicit
message. Previously saved unsupported profiles are not silently deleted.

Baseline selection and weather assistance are independent:

`baseline goal + optional weather adjustment = current daily suggestion`

The weather decision is persisted when the user explicitly enables it or
chooses Not now. Later screens read this setting and do not treat weather as a
baseline mode.

Legal acknowledgement is committed only at final completion. Process
restoration must not fabricate consent.
