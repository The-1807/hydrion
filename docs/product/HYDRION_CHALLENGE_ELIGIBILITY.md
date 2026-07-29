# Hydrion Challenge Eligibility

Eligibility is evaluated by `HydrionChallengeEligibilityPolicy` and is enforced
again by `ChallengeRepository.join`. Hiding a card is not authorization.

- Universal experiences remain available to supported teen and adult profiles.
- Teen extras are available to ages 13-17.
- Adult extras are available to ages 18 and older.
- Unsupported or corrupt profiles cannot join any challenge.
- Missing age may use universal challenges for migrated profiles, but cannot
  join a life-stage-specific experience.
- Joining is always explicit and the two-active-challenge limit remains.
- Check-ins never create hydration records or change the daily goal.

Teen extras: Lunch Break Refill, Homework Hydration, After-School Recharge, and
Backpack Bottle Check.

Adult extras: Desk-Day Reset, Shift Hydration Check, Commute Cup, and Evening
Goal Review.

Eligibility never uses BMI, weight, height, pregnancy, lactation, or gender
stereotypes.
