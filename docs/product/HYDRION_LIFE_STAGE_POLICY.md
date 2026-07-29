# Hydrion Life-Stage Policy

Hydrion uses one domain-owned policy in `life_stage_policy.dart`. Widgets must
not create their own age boundaries.

## Product access

| Saved age | Independent profile |
| --- | --- |
| Missing | Unresolved |
| Below 13 | Unsupported |
| 13-17 | Teen |
| 18-120 | Adult |
| Negative or above 120 | Invalid, requires review |

New independent profiles require a supported age. An existing unsupported
profile must be preserved for correction or local deletion; it must not receive
teen or adult challenge access.

## Body reference

Ages 13-19 use the adolescent body-reference stage. Ages 20 and older use the
adult body-reference stage. Adult BMI interpretation remains unavailable below
20. This policy does not introduce growth percentiles or new medical formulas.

Pregnancy and lactation remain optional only for supported female profiles aged
13 or older. Age alone must not remove relevant safety support from a teen.
Hydrion never infers reproductive state.
