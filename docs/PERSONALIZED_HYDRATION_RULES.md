# Hydrion Personalized Hydration Rules

Last updated: 2026-07-28

## Purpose and scope

Hydrion can produce a deterministic general-wellness hydration suggestion from
optional local inputs. This is a product estimate, not a prescription,
diagnosis, medical device output, or claim of medical accuracy.

The calculation runs locally. It uses no AI, cloud profile, analytics,
HealthKit, Health Connect, wearable, smart scale, or backend. Network access is
used only when the user separately enables the existing weather lookup.

## Optional inputs and canonical units

- Weight is stored as kilograms.
- Height is stored as centimetres.
- Hydration is stored as millilitres.
- Activity duration is stored as whole minutes.
- Daily context uses a local `YYYY-MM-DD` key.
- Weight and height display units never rewrite the canonical measurement.
- Pregnancy, lactation, activity, exposure, sweating, temporary condition,
  fluid-safety status, clinician target, and wake/sleep times are explicit
  optional user choices. Hydrion does not infer them.

Missing body-metrics storage means personalization is disabled and the existing
baseline remains. Invalid storage recovers to null measurements and produces a
non-sensitive storage-recovery event.

## Baseline-source and modifier architecture

Baseline source and modifiers are independent:

- Manual baseline
- Personalized baseline
- Optional daily activity modifier
- Optional weather modifier
- Explicit pregnancy or lactation modifier
- Optional user modifier
- Clinician-target protection

Legacy `manual` mode migrates to a manual baseline with weather disabled.
Legacy `weatherInformed` mode migrates to a manual baseline with weather
enabled. Existing users are never enrolled into body-metric personalization.
Adding measurements does not replace the current goal; the user must review and
apply the suggestion.

## Adult personalized baseline

The adult formula is available only when the user is at least 20, opts in, and
has valid weight and height.

1. `heightMetres = heightCm / 100`
2. `heightBasedWeightCapKg = 30 × heightMetres²`
3. `calculationWeightKg = min(actualWeightKg, heightBasedWeightCapKg, 100)`
4. Apply a 40 kg calculation floor.
5. `rawBaselineMl = calculationWeightKg × 30`
6. Round to the nearest 50 mL.
7. Bound the personalized baseline to 1,500–3,000 mL.

The 30 mL/kg factor and calculation-weight bounds are conservative Hydrion
product rules. They are not asserted to be universally correct clinical
guidance. For users younger than 20 or with missing measurements, Hydrion keeps
the existing baseline and identifies the skipped factor.

Reference-intake publications describe population guidance and variability;
they do not validate an exact individual app formula. See the
[National Academies water DRI report](https://doi.org/10.17226/10925) and
[EFSA dietary reference values](https://www.efsa.europa.eu/en/topics/topic/dietary-reference-values).

## BMI screening estimate

`BMI = weightKg / heightMetres²`

Hydrion displays one decimal place. For adults 20 and older:

- below 18.5: Below standard adult range
- 18.5 to 24.9: Standard adult screening range
- 25.0 to 29.9: Above standard adult range
- 30.0 and above: Higher adult screening range

BMI does not add or subtract water. It is never the sole challenge-ranking
signal. Adult categories are not interpreted for users younger than 20.

The UI states: “BMI is a screening estimate based on height and weight. It does
not diagnose health conditions or measure body composition.”

These thresholds follow the
[CDC adult BMI screening categories](https://www.cdc.gov/bmi/adult-calculator/bmi-categories.html).
Hydrion intentionally uses neutral product wording and does not label a person
or diagnose a condition.

## Pregnancy and lactation

Controls appear only when the saved profile sex is female. The user must choose
the state explicitly.

- None: 0 mL
- Pregnant: +300 mL
- Lactating: +700 mL

Male, intersex, and prefer-not-to-say profiles neither display nor apply the
modifier. Incompatible legacy data is sanitized to `none`. The modifier is a
bounded general estimate, not pregnancy care.

For a pregnant profile, gestational duration is stored canonically as total
days from 1 through 294 (42 weeks). The editor may display days, weeks, or
approximate months; month conversion uses 30.436875 days. Changing display
units never changes the stored day value. Duration does not alter the fixed
pregnancy adjustment, determine pregnancy stage, or calculate a due date. It
is an optional local general-wellness profile field.

## Activity and sweat tiers

- Rest/light below 30 minutes: 0 mL
- Moderate 30–59 minutes: +250 mL
- Moderate 60 minutes or longer: +500 mL
- Vigorous 30–59 minutes: +500 mL
- Vigorous 60 minutes or longer: +750 mL
- High reported sweating can raise the result one 250 mL tier when activity or
  outdoor exposure is meaningful.
- Activity never exceeds +750 mL without calibrated sweat-rate data.
- Unknown sweat adds nothing.

Fever, vomiting/diarrhea, and recovery produce a safety notice but no precise
illness adjustment.

## Weather and outdoor exposure

Weather reuses the existing `WeatherSnapshot`, location permission, Open-Meteo
provider, and local-day cache.

Effective temperature uses apparent temperature when valid, otherwise measured
temperature. Humidity is not added separately when apparent temperature is
available. When apparent temperature is absent, high humidity can add a
limited 100 mL fallback in warm conditions. High UV can add 100 mL only for
mixed/outdoor exposure.

Temperature tiers:

- 26–29.9°C: +150 mL
- 30–34.9°C: +300 mL
- 35°C or above: +450 mL
- Below 26°C: 0 mL; cold weather never lowers the goal

The combined weather modifier is bounded to 0–600 mL, then scaled:

- Mostly indoors: 0%
- Mixed: 50%
- Mostly outdoors: 100%

The scaled result is rounded to 50 mL. Permission denial, revocation, stale or
unavailable weather never produces a fabricated adjustment. The existing
baseline remains. Heat and hydration are variable and context-dependent; the
[CDC/NIOSH heat guidance](https://www.cdc.gov/niosh/heat-stress/recommendations/)
supports considering heat, exertion, rest, and hydration together rather than
treating a forecast as an exact prescription.

## Clinician targets and fluid restrictions

A clinician-set target overrides all other factors by default. Optional
increases above that target occur only after an explicit user choice.

When a user reports a fluid restriction without a target, or is unsure:

- Hydrion preserves the regular baseline.
- Weather and activity suggestions are not auto-applied.
- The UI directs the user to follow professional guidance.

Hydrion never decides whether a restriction, kidney/heart condition, pregnancy,
illness, or treatment exists.

## Final bounds, rounding, and confidence

The final suggestion is bounded to the established 500–5,000 mL app goal range
and rounded to the nearest 50 mL. The output records structured applied,
skipped, and safety reason codes, its local date, calculation time, whether
weather/cache was used, and whether a clinician target overrode modifiers.

Confidence labels describe input coverage only: fallback, manual,
profile-informed, daily-context-informed, weather-informed, calibrated, or
clinician-set. They are not medical-accuracy scores.

## Coordination and history safety

The coordinator fingerprints the local-day inputs and records one canonical
recommendation state per input set. Calculation never creates, edits, or
deletes hydration logs. Manual goal edits remain protected. Applying a
recommendation requires a user action and does not change historical logs.

Daily contexts retain at most 14 local days and never rewrite log timestamps.

## Challenge recommendations

Ranking is local, transparent, and read-only:

- Temperature Roulette: hot weather and outdoor context
- Pomodoro Sip: indoor/focus routine preference
- Bottle Bingo: inconsistent recent logging; generic varied-habit wording is
  only a secondary explanation
- Eat Your Water Day: explicit water-rich-food interest; adult BMI at or above
  25 may add a private weak secondary score, but BMI alone is never eligible
- Plant Twin: explicit visual-consistency interest
- Around the World Infusion Week: explicit infusion-variety interest

Current eligible weather comes from the existing local-day cache and is used
only while weather assistance and location permission remain enabled. The
Challenges screen performs no permission or network request during rendering.
Stale, missing, disabled, or revoked weather contributes no signal.

Challenge preferences are optional, default to false, and stay in the existing
local personalization-state record. No meaningful signal means no personalized
recommendation card; the complete catalogue remains available for manual
browsing. Neutral explanations never disclose BMI or exact body metrics.

Existing active challenges, same-day dismissals, and the two-active-challenge
limit are respected. A recommendation can only open details. `join` remains an
explicit action in the challenge setup flow. Ranking never creates hydration
logs and never activates, resumes, completes, or restarts a challenge.

## Privacy and deletion

Body metrics, daily contexts, calculation state, challenge preferences, and
challenge dismissals are stored locally under versioned keys. They are not
sold, advertised against, uploaded, logged to console, included in
notifications, or processed by AI.

Local profile deletion removes every personalization key, including body
metrics, BMI-derived state, reproductive state, clinician target, restriction
state, daily contexts, calculation fingerprints, and challenge dismissals.
Operating-system permissions remain installation-level and are disclosed
separately.

## Known limitations

- A deterministic estimate cannot measure hydration status or sweat loss.
- Forecasts and apparent temperature may be delayed or inaccurate.
- Food water, altitude, medication, illness, and individual physiology are not
  precisely measured.
- The product does not interpret paediatric BMI.
- Physical-device permission, weather, notification, accessibility, and
  clean-install behavior still require release-candidate testing.

Hydrion distinguishes its bounded product rules from the population reference
values and occupational heat guidance cited above. Users with medical
restrictions or significant symptoms should follow qualified professional
guidance rather than the app.
# Saved-state interaction contract

Body measurements, personalization settings, daily context, and challenge
preferences are displayed as saved summaries during normal use. Picker,
numeric-entry, switch, and dropdown controls appear only after an explicit Add,
Update, or Edit action. Weight and height persist independently with separate
update timestamps.

Picker defaults are draft-only and never become saved measurements until the
user selects Done. Cancel discards the draft. Today's activity and temporary
condition context is keyed to the local date and does not carry into another
day. Temporary illness is safety context only and does not add a numerical
illness adjustment.

Keeping the current hydration goal records the current recommendation
fingerprint as reviewed for that local date without changing the goal,
baseline, or hydration history.
