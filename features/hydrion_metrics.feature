@v1 @release @domain @personalization
Feature: Hydrion health metrics and adaptive hydration personalization

As a Hydrion user
I want my hydration recommendations to consider relevant physiological, environmental, activity, behavioral, dietary, and health metrics
So that my hydration plan can adapt to my individual circumstances
And Hydrion can provide safer and more personalized hydration guidance

Background:
Given I have a Hydrion profile
And hydration personalization is available
And Hydrion protects health data according to the user's permissions and privacy settings

# ============================================================

# HEALTH DATA CONSENT AND SOURCES

# ============================================================

Scenario: User enables advanced hydration personalization
Given advanced hydration personalization is disabled
When I enable advanced hydration personalization
Then Hydrion should explain what categories of data may improve personalization
And I should be able to choose which data categories Hydrion may use
And optional health data should not be required to use Hydrion

Scenario: User connects an external health platform
Given my device provides a supported health data platform
When I choose to connect health data
Then Hydrion should request only the permissions required for enabled hydration features
And each supported health data category should remain subject to platform authorization
And denied permissions should not prevent unrelated Hydrion functionality

Scenario: User denies a health data permission
Given Hydrion requests access to an optional health metric
When I deny access
Then Hydrion should not read that health metric
And Hydrion should continue using available inputs
And the personalization engine should record that the metric is unavailable rather than assume a value

Scenario: User revokes a health data permission
Given Hydrion previously had permission to access a health metric
When I revoke that permission
Then Hydrion should stop reading new values for that metric
And calculations should no longer depend on unavailable live data
And Hydrion should preserve safe operation using remaining authorized data

Scenario: User enters health metrics manually
Given an applicable health metric is not available from a connected health platform
When I manually provide the metric
Then Hydrion should validate the value
And Hydrion should identify the metric as manually entered
And the metric should be available to applicable hydration calculations

Scenario: Health metric has multiple possible sources
Given the same metric is available from more than one authorized source
When Hydrion evaluates the metric
Then Hydrion should apply a deterministic source-priority policy
And Hydrion should avoid double counting the same underlying measurement
And the selected measurement should retain its source information

Scenario: Health metric includes measurement timestamp
Given Hydrion receives a physiological measurement
When the measurement is stored for personalization
Then Hydrion should retain the measurement time
And calculations requiring current information should account for measurement age

Scenario: Stale health metric is detected
Given a calculation depends on a recent physiological measurement
And the available measurement exceeds its allowed freshness period
When Hydrion evaluates the metric
Then Hydrion should treat the measurement as stale
And the calculation confidence should be reduced or the metric should be excluded
And Hydrion should not represent stale data as current

# ============================================================

# CORE BODY METRICS

# ============================================================

Scenario: Hydrion records body weight
When I provide or authorize access to my body weight
Then Hydrion should store the validated measurement
And body weight should be available to applicable baseline and fluid-loss calculations

Scenario: Hydrion records height
When I provide or authorize access to my height
Then Hydrion should store the validated measurement
And height should be available to applicable body composition calculations

Scenario: Hydrion considers age
Given my age is available in my profile
When Hydrion calculates my baseline hydration context
Then age should be available as an input to applicable validated models

Scenario: Hydrion considers physiological sex where scientifically applicable
Given physiological sex is available
When a validated hydration model requires physiological sex
Then Hydrion may use it for that calculation
And Hydrion should not use it for calculations where it is not required

Scenario: Hydrion calculates body mass index
Given my current weight and height are available
When Hydrion calculates body mass index
Then Hydrion should calculate BMI from validated measurements
And the resulting BMI should be treated as one contextual metric
And BMI should not be treated as a direct measurement of hydration status

Scenario: Hydrion records body fat percentage
When body fat percentage is available from an authorized source
Then Hydrion should store the measurement with its source
And the value should be available to body composition calculations

Scenario: Hydrion derives fat-free mass
Given body weight is available
And body fat percentage is available
When Hydrion calculates fat-free mass
Then Hydrion should derive fat-free mass from the available measurements
And the derived value should retain calculation metadata

Scenario: Hydrion records skeletal muscle mass
When skeletal muscle mass is available from an authorized source
Then Hydrion should store the measurement
And the measurement may contribute to applicable body composition models

Scenario: Hydrion records total body water
When total body water is available from a supported source
Then Hydrion should store the measurement with its source and timestamp
And Hydrion should not represent consumer-device total body water estimates as clinical measurements

Scenario: Hydrion records resting metabolic rate
When resting metabolic rate is available
Then Hydrion should store the value and its source
And it should be available to applicable energy and hydration models

Scenario: Hydrion records total daily energy expenditure
When total daily energy expenditure is available
Then Hydrion should make the value available to applicable personalization calculations

Scenario: Hydrion derives physical activity level
Given total daily energy expenditure is available
And an applicable basal or resting energy expenditure value is available
When Hydrion calculates physical activity level
Then Hydrion should derive the activity ratio
And the derived value should be available to validated water-turnover models

# ============================================================

# BASELINE WATER REQUIREMENT AND WATER TURNOVER

# ============================================================

Scenario: Hydrion calculates a baseline hydration estimate
Given sufficient baseline profile information is available
When Hydrion creates my daily hydration plan
Then Hydrion should calculate a baseline hydration estimate
And the calculation method should be identifiable
And subsequent contextual adjustments should remain distinguishable from the baseline

Scenario: Hydrion supports validated water-turnover models
Given the required inputs for a supported scientific water-turnover model are available
When Hydrion estimates daily water turnover
Then Hydrion should use the validated model implementation
And Hydrion should preserve the model version used
And the resulting water-turnover estimate should not automatically be treated as required drinking-water intake

Scenario: Water-turnover inputs are incomplete
Given a supported water-turnover model requires inputs that are unavailable
When Hydrion attempts to calculate water turnover
Then Hydrion should not invent missing measurements
And Hydrion should use an appropriate fallback calculation when available
And the resulting estimate should indicate reduced personalization confidence

Scenario: Hydrion separates total water requirement from drinking-water requirement
Given Hydrion estimates total daily water need
When Hydrion creates a drinking target
Then Hydrion should account for applicable water received from food and other beverages
And Hydrion should not represent total water need as plain-water requirement

# ============================================================

# ACTIVITY AND EXERCISE METRICS

# ============================================================

Scenario: Hydrion records daily steps
When step-count information is available
Then Hydrion should make daily steps available to activity-context calculations

Scenario: Hydrion records workout duration
Given I perform a recorded workout
When Hydrion receives workout information
Then workout duration should be available to hydration calculations

Scenario: Hydrion records workout type
Given a workout record includes an activity type
When Hydrion evaluates the workout
Then Hydrion should retain the activity type
And activity-specific models may use the activity type where scientifically justified

Scenario: Hydrion records workout intensity
Given sufficient workout information is available
When Hydrion determines workout intensity
Then the intensity should be available as activity context
And Hydrion should distinguish measured intensity from estimated intensity

Scenario: Hydrion records active energy expenditure
When active energy expenditure is available
Then Hydrion should make the metric available to applicable activity and metabolic calculations

Scenario: Activity increases estimated fluid requirement
Given activity information indicates increased fluid loss or water turnover
When Hydrion calculates my contextual hydration requirement
Then activity-related requirements should be calculated separately from baseline hydration
And the adjustment should be traceable to the activity data used

# ============================================================

# PERSONAL SWEAT RATE

# ============================================================

Scenario: User performs a sweat-rate assessment
Given I record my body weight immediately before an activity
And I record my body weight immediately after the activity
And I record fluid consumed during the activity
And I record applicable urine output during the assessment
And I record activity duration
When Hydrion calculates sweat loss
Then Hydrion should estimate fluid lost during the assessment
And Hydrion should calculate an estimated sweat rate
And the result should be associated with the assessment conditions

Scenario: Sweat-rate assessment lacks required measurements
Given a sweat-rate assessment is incomplete
When Hydrion attempts to calculate personal sweat rate
Then Hydrion should identify the missing measurements
And Hydrion should not represent the incomplete assessment as a measured sweat rate

Scenario: Hydrion stores multiple sweat profiles
Given I have completed sweat-rate assessments under different conditions
When Hydrion stores the assessments
Then each sweat profile should retain its activity context
And each sweat profile should retain its environmental context
And each sweat profile should retain its measurement confidence

Scenario: Hydrion predicts sweat loss from personal history
Given I have valid historical sweat-rate measurements
And my current activity and environmental conditions are sufficiently similar
When Hydrion estimates activity-related sweat loss
Then Hydrion should prioritize applicable personal sweat data over generic estimates
And Hydrion should identify the result as predicted rather than directly measured

Scenario: Hydrion falls back when personal sweat rate is unavailable
Given I do not have a usable personal sweat profile
When Hydrion estimates exercise-related fluid loss
Then Hydrion may use an approved population or activity estimate
And the estimate should have lower confidence than a relevant personal measurement

# ============================================================

# BODY-MASS CHANGE AND SHORT-TERM FLUID DEFICIT

# ============================================================

Scenario: Hydrion evaluates short-term body-mass change
Given a valid pre-activity body weight is available
And a valid post-activity body weight is available
When Hydrion evaluates acute body-mass change
Then Hydrion should calculate the percentage change relative to baseline
And the result may contribute to short-term fluid-balance assessment

Scenario: Hydrion does not treat long-term weight change as fluid loss
Given body-weight measurements are separated by a period unsuitable for acute fluid-loss assessment
When Hydrion evaluates the measurements
Then Hydrion should not assume the weight difference represents water loss

# ============================================================

# ENVIRONMENTAL METRICS

# ============================================================

Scenario: Hydrion records ambient temperature
When current environmental temperature is available
Then temperature should be available to environmental hydration calculations

Scenario: Hydrion records humidity
When current humidity is available
Then humidity should be available to environmental hydration calculations

Scenario: Hydrion calculates apparent temperature
Given sufficient weather inputs are available
When Hydrion evaluates environmental heat exposure
Then Hydrion should calculate or obtain an appropriate apparent-temperature metric
And the apparent-temperature value may contribute to heat-related hydration adjustment

Scenario: Hydrion considers heat index
Given environmental conditions support an applicable heat-index calculation
When Hydrion evaluates heat stress
Then the heat-index value should be available to applicable safety and hydration logic

Scenario: Hydrion records wind conditions
When wind data is available
Then Hydrion may use wind conditions in applicable environmental exposure models

Scenario: Hydrion records altitude
Given my current altitude is available
When Hydrion calculates contextual hydration requirements
Then altitude should be available to models that account for altitude-related water turnover or respiratory loss

Scenario: Hydrion records outdoor exposure duration
Given I spend time in an outdoor environment
When exposure duration is available
Then Hydrion should consider duration together with applicable environmental conditions

Scenario: Hydrion distinguishes indoor and outdoor activity
Given an activity has an environmental context
When Hydrion evaluates the activity
Then indoor and outdoor exposure should remain distinguishable

Scenario: Hydrion considers protective clothing or heavy equipment
Given I voluntarily indicate that I am wearing clothing or equipment that substantially affects heat dissipation
When Hydrion evaluates environmental and activity load
Then the additional heat context may contribute to fluid-loss estimation

Scenario: Hydrion maintains a heat acclimatization context
Given I have repeated recent exposure to hot environments
When Hydrion evaluates my heat exposure history
Then Hydrion may derive an acclimatization context from recent qualifying exposure
And the value should decay when qualifying heat exposure stops
And it should not be represented as a clinical measurement

Scenario: Environmental conditions change during the day
Given my hydration plan was calculated using earlier environmental conditions
And current conditions have materially changed
When Hydrion refreshes my plan
Then the environmental adjustment should be recalculated
And the revised target should preserve previously recorded intake

# ============================================================

# URINE AND HYDRATION STATUS INDICATORS

# ============================================================

Scenario: User records urine colour
When I voluntarily record urine colour using Hydrion's supported scale
Then Hydrion should store the observation with its timestamp
And the observation may contribute to hydration-state estimation
And urine colour alone should not be treated as proof of dehydration

Scenario: User records urination frequency
Given I voluntarily track urination events
When Hydrion evaluates my recent void frequency
Then the frequency may contribute to hydration-state estimation

Scenario: Hydrion combines urine colour and void frequency
Given recent urine colour observations are available
And recent void-frequency information is available
When Hydrion estimates hydration state
Then Hydrion may combine both indicators
And the combined evidence should remain distinct from a clinical diagnosis

Scenario: User records urine volume
When I voluntarily provide a measured urine volume
Then Hydrion should store the value with measurement metadata
And the measurement may contribute to applicable fluid-balance calculations

Scenario: Hydrion accepts urine specific gravity
Given I have a valid urine specific-gravity measurement
When I record the measurement
Then Hydrion should store it as a measured hydration-related biomarker
And the source should distinguish clinical, device, and manual measurements

Scenario: Hydrion accepts urine osmolality
Given I have a valid urine osmolality result
When I provide or authorize access to the result
Then Hydrion should store the measurement with source and timestamp
And it may contribute to applicable hydration-state calculations

# ============================================================

# SUBJECTIVE HYDRATION INDICATORS

# ============================================================

Scenario: User records thirst
When I record my current thirst level
Then Hydrion should store the subjective observation
And thirst may contribute to the hydration-state estimate
And subjective thirst should have an appropriate confidence weighting

Scenario: User records dry mouth
When I record dry-mouth symptoms
Then Hydrion may use the observation as supporting hydration context
And it should not independently determine dehydration status

Scenario: Subjective signals conflict with measured data
Given subjective hydration observations are available
And higher-confidence measurements indicate a different hydration state
When Hydrion combines the evidence
Then Hydrion should apply the configured confidence hierarchy
And Hydrion should not allow a low-confidence observation to silently override a higher-confidence measurement

# ============================================================

# REPRODUCTIVE HEALTH CONTEXT

# ============================================================

Scenario: User enables menstrual health context
Given reproductive health personalization is optional
When I enable menstrual health context
Then Hydrion should use only reproductive health information I have authorized
And menstrual information should remain optional

Scenario: Hydrion records menstruation period dates
When authorized menstrual period data is available
Then Hydrion should retain applicable period timing information for hydration context

Scenario: Hydrion records menstrual flow
When authorized menstrual flow information is available
Then Hydrion should retain the flow context
And Hydrion should not automatically convert flow category into an unsupported fixed water-volume adjustment

Scenario: Hydrion records menstrual cycle phase where available
When an authorized menstrual cycle phase is available
Then Hydrion may retain the phase as contextual information
And Hydrion should not assume that cycle phase alone determines hydration requirement

Scenario: Hydrion records ovulation context where available
When authorized ovulation information is available
Then Hydrion may retain the information as reproductive health context

Scenario: Hydrion records basal body temperature where available
When authorized basal body temperature is available
Then Hydrion may retain the measurement with its source and timestamp
And it should not be confused with environmental temperature

Scenario: Hydrion learns individual hydration patterns across menstrual cycles
Given I have authorized menstrual context
And sufficient hydration history exists across multiple cycles
When Hydrion evaluates recurring personal patterns
Then Hydrion may identify correlations between my hydration behavior and menstrual context
And Hydrion should distinguish personal observed patterns from general medical claims

# ============================================================

# PREGNANCY AND LACTATION

# ============================================================

Scenario: Hydrion records pregnancy status
Given I authorize pregnancy information for personalization
When pregnancy status is available
Then Hydrion should use pregnancy as an applicable hydration context
And pregnancy-related calculations should follow the configured evidence-based model

Scenario: Pregnancy status changes
Given Hydrion previously used pregnancy-related hydration context
When pregnancy status is no longer active
Then future hydration plans should stop applying the pregnancy adjustment
And historical calculations should preserve their original context

Scenario: Hydrion records lactation status
Given I authorize lactation information for personalization
When lactation status is available
Then Hydrion should use lactation as an applicable hydration context
And lactation-related calculations should follow the configured evidence-based model

Scenario: User indicates partial or exclusive breastfeeding where supported
Given lactation personalization supports feeding context
When I voluntarily provide the applicable feeding context
Then Hydrion may use that information only where a validated adjustment model exists
And Hydrion should not invent unsupported precise fluid requirements

# ============================================================

# ILLNESS AND TEMPORARY HEALTH CONDITIONS

# ============================================================

Scenario: User records fever
When I report a fever or authorize an applicable body-temperature measurement
Then Hydrion should recognize a temporary illness context
And the context may influence hydration guidance and safety messaging

Scenario: User records vomiting
When I report vomiting
Then Hydrion should recognize possible acute fluid loss
And Hydrion should activate applicable illness safety rules

Scenario: User records diarrhea
When I report diarrhea
Then Hydrion should recognize possible acute fluid and electrolyte loss
And Hydrion should activate applicable illness safety rules

Scenario: User reports combined acute fluid-loss symptoms
Given I report more than one acute fluid-loss condition
When Hydrion evaluates my health context
Then Hydrion should increase the severity of the safety assessment where appropriate
And Hydrion should not rely solely on the normal daily hydration target

Scenario: Illness state ends
Given a temporary illness modifier is active
When the condition is no longer active or its configured validity period expires
Then Hydrion should stop applying the temporary illness modifier
And normal personalization should resume subject to remaining health context

# ============================================================

# CARDIOVASCULAR AND WEARABLE METRICS

# ============================================================

Scenario: Hydrion records resting heart rate
When authorized resting heart-rate information is available
Then Hydrion may use it as supporting physiological context
And resting heart rate alone should not determine hydration status

Scenario: Hydrion records activity heart rate
Given I perform an activity
When authorized heart-rate information is available
Then Hydrion may use heart rate to help characterize activity intensity
And Hydrion should not interpret elevated heart rate alone as dehydration

Scenario: Hydrion records heart-rate recovery
Given sufficient post-activity heart-rate data is available
When Hydrion evaluates recovery context
Then heart-rate recovery may contribute to activity and recovery characterization
And it should not independently determine fluid requirement

Scenario: Hydrion records heart-rate variability
When authorized heart-rate variability is available
Then Hydrion may retain it as supporting context
And HRV should not be treated as a direct hydration measurement

Scenario: Hydrion records skin or wrist temperature
When an authorized wearable temperature metric is available
Then Hydrion should retain the measurement type and source
And wearable temperature should be interpreted according to its measurement limitations

Scenario: Hydrion records respiratory rate
When authorized respiratory-rate information is available
Then Hydrion may use it as supporting physiological context where applicable

Scenario: Hydrion records blood oxygen
When authorized blood-oxygen information is available
Then Hydrion may retain the measurement as supporting context
And it should not be treated as a direct measurement of hydration

Scenario: Hydrion combines wearable signals cautiously
Given multiple wearable physiological metrics are available
When Hydrion evaluates hydration context
Then Hydrion may use the combined pattern as supporting evidence
And no unsupported wearable signal should independently diagnose dehydration

# ============================================================

# SLEEP AND DAILY RHYTHM

# ============================================================

Scenario: Hydrion records wake time
When a reliable wake time is available
Then Hydrion should use it to determine my active hydration window where applicable

Scenario: Hydrion records bedtime
When a reliable bedtime is available
Then Hydrion should use it to help determine my hydration scheduling window

Scenario: Hydrion records sleep duration
When authorized sleep duration is available
Then Hydrion may use it to improve hydration scheduling and daily context

Scenario: Hydration pacing respects sleep
Given my daily hydration requirement has been calculated
And my expected sleeping period is known
When Hydrion schedules hydration
Then Hydrion should distribute appropriate intake across my waking period
And Hydrion should avoid unnecessary reminders during configured sleep periods

@safety
Scenario: Hydration pacing follows a normal waking window
Given my daily hydration requirement has been calculated
And my wake time and bedtime are both known
When Hydrion evaluates my pacing at a point within my waking window
Then Hydrion should report how my logged intake compares to my expected pace at that point

Scenario: Hydration pacing supports a waking window that crosses midnight
Given my wake time is later in the day than my bedtime
When Hydrion evaluates my pacing after midnight but before my bedtime
Then Hydrion should still treat that moment as within my waking window

@safety
Scenario: Sleeping hours do not change the hydration baseline
Given my daily hydration requirement has been calculated
When my configured waking period changes length
Then my calculated hydration baseline should remain unchanged

Scenario: Missing sleep schedule does not prevent hydration tracking
Given no wake time or bedtime has been configured
When Hydrion evaluates my pacing
Then Hydrion should continue to accept and record hydration logging

@safety
Scenario: Pacing respects clinician-directed hydration limits
Given my clinician has prescribed a specific fluid target
When Hydrion evaluates my pacing against that target
Then pacing should compare my progress to the clinician-directed target rather than any other calculated value

# ============================================================

# DIETARY WATER

# ============================================================

Scenario: Hydrion records plain water intake
When I log plain water
Then Hydrion should count the applicable fluid volume toward my recorded intake

Scenario: Hydrion records other beverages
When I log a supported beverage
Then Hydrion should record its fluid volume
And Hydrion may apply beverage-specific hydration rules where scientifically justified

Scenario: Hydrion records water obtained from food
Given food-water estimation is enabled
When I log supported food information
Then Hydrion should estimate applicable food-derived water
And the estimate should be distinguishable from measured beverage intake

Scenario: Hydrion integrates nutrition data
Given I authorize a supported nutrition data source
When applicable food information becomes available
Then Hydrion may estimate dietary water contribution
And Hydrion should avoid double counting manually and externally logged food

Scenario: Hydrion calculates total water intake
Given recorded plain-water intake is available
And other beverage intake is available
And applicable estimated food water is available
When Hydrion calculates total water intake
Then Hydrion should combine applicable water sources
And each contribution should remain independently identifiable

Scenario: Food-water information is unavailable
Given I do not track food-water intake
When Hydrion calculates my remaining drinking target
Then Hydrion should use the configured fallback strategy
And the reduced certainty should be reflected in the calculation confidence

# ============================================================

# ELECTROLYTE AND SODIUM LOSS

# ============================================================

Scenario: Hydrion records measured sweat sodium concentration
Given I have a supported sweat sodium measurement
When I provide or authorize the measurement
Then Hydrion should store the concentration with its source
And it should be considered higher-confidence than a population estimate

Scenario: Hydrion estimates sweat sodium loss
Given estimated sweat volume is available
And an applicable sweat sodium concentration is available
When Hydrion calculates estimated sodium loss
Then Hydrion should derive sodium loss from those inputs
And the result should retain the confidence level of its underlying inputs

Scenario: Personal sodium measurement is unavailable
Given no personal sweat sodium measurement exists
When Hydrion evaluates electrolyte-loss context
Then Hydrion may use an approved population estimate where appropriate
And the result should be clearly classified as estimated

Scenario: Prolonged sweating triggers electrolyte context
Given activity or environmental exposure indicates prolonged substantial sweating
When Hydrion evaluates my fluid-replacement context
Then Hydrion should consider whether electrolyte replacement guidance is applicable
And Hydrion should not treat water replacement as the only relevant factor

Scenario: Hydrion avoids excessive electrolyte recommendations
Given electrolyte-loss information is uncertain
When Hydrion creates hydration guidance
Then Hydrion should not prescribe an unsupported precise electrolyte replacement amount

# ============================================================

# CLINICAL CONDITIONS AND SAFETY CONSTRAINTS

# ============================================================

@safety
Scenario: User records clinician-prescribed daily fluid target
Given my clinician has prescribed a specific fluid target
When I enter the clinician-prescribed target
Then Hydrion should store the target as a clinical override
And the clinician target should take precedence over ordinary Hydrion target calculations

@safety
Scenario: User records clinician-prescribed fluid restriction
Given my clinician has instructed me to limit fluid intake
When I configure the prescribed fluid limit
Then Hydrion should enforce the limit as a safety constraint
And automatic personalization should not increase my target beyond the configured clinical limit

Scenario: User records a condition requiring individualized fluid management
Given I indicate that I have a health condition affecting fluid management
When Hydrion evaluates my hydration plan
Then Hydrion should activate the applicable safety pathway
And Hydrion should avoid unsupported automatic target increases

Scenario: User records relevant medication context
Given I voluntarily indicate use of medication that affects fluid balance
When Hydrion evaluates my health context
Then medication context should be treated as a safety modifier
And Hydrion should not infer a precise fluid adjustment without an approved rule

@safety
Scenario: Safety constraint conflicts with normal personalization
Given ordinary personalization calculates a target above an active safety constraint
When Hydrion finalizes the hydration plan
Then the safety constraint should take precedence

@safety
Scenario: Multiple safety constraints exist
Given more than one applicable hydration safety constraint is active
When Hydrion creates my plan
Then Hydrion should apply the most restrictive applicable safe boundary
And the resulting plan should identify that safety constraints affected personalization

# ============================================================

# HYDRATION STATE ESTIMATOR

# ============================================================

Scenario: Hydrion estimates current hydration state
Given one or more hydration-state indicators are available
When Hydrion evaluates my current hydration state
Then Hydrion should combine applicable evidence using configured confidence weights
And the result should be expressed as an estimate rather than a medical diagnosis

Scenario: Hydration state uses multiple evidence classes
Given body-mass trend is available
And urine information is available
And thirst information is available
And fluid-balance information is available
When Hydrion estimates hydration state
Then each evidence class should contribute according to its configured reliability
And no individual low-confidence signal should silently dominate the estimate

Scenario: Hydration-state evidence is insufficient
Given insufficient recent hydration-state data exists
When Hydrion evaluates my current state
Then Hydrion should classify the state as uncertain
And Hydrion should not fabricate certainty from missing information

Scenario: Hydration-state indicators conflict
Given available hydration indicators disagree
When Hydrion combines the evidence
Then Hydrion should preserve the disagreement in its confidence calculation
And the resulting state should reflect appropriate uncertainty

Scenario: Hydrion distinguishes hydration guidance from diagnosis
When Hydrion displays a hydration-state estimate
Then Hydrion should not claim to diagnose dehydration or another medical condition
And applicable safety guidance should remain separate from diagnostic claims

# ============================================================

# METRIC CONFIDENCE AND DATA QUALITY

# ============================================================

Scenario: Hydrion assigns confidence to metric sources
Given a metric can originate from measured, device-derived, manually reported, inferred, or population-estimated data
When Hydrion uses the metric
Then the metric should retain a source-quality classification
And the classification should influence applicable calculation confidence

Scenario: Direct measurement outranks population estimate
Given a valid recent personal measurement exists
And a generic population estimate exists for the same metric
When Hydrion chooses an input
Then Hydrion should prefer the valid personal measurement where appropriate

Scenario: Inferred metric is identified
Given Hydrion derives a value from other measurements
When the derived value is used
Then the value should be identified as calculated or inferred
And its source measurements should remain traceable

Scenario: Hydrion calculates personalization confidence
Given a hydration recommendation uses multiple metrics
When Hydrion finalizes the recommendation
Then Hydrion should calculate an overall personalization confidence
And the confidence should reflect data quality
And the confidence should reflect missing inputs
And the confidence should reflect data freshness
And the confidence should reflect estimation uncertainty

# ============================================================

# DAILY HYDRATION CALCULATION

# ============================================================

Scenario: Hydrion builds a contextual daily hydration plan
Given a baseline hydration estimate is available
When Hydrion calculates my contextual daily hydration plan
Then Hydrion should evaluate applicable body metrics
And Hydrion should evaluate activity
And Hydrion should evaluate environmental exposure
And Hydrion should evaluate estimated sweat loss
And Hydrion should evaluate reproductive health context
And Hydrion should evaluate pregnancy or lactation context
And Hydrion should evaluate temporary health conditions
And Hydrion should evaluate dietary water
And Hydrion should evaluate applicable electrolyte context
And Hydrion should evaluate active safety constraints

Scenario: Hydrion keeps calculation components independently traceable
Given multiple factors modify my daily hydration plan
When Hydrion stores the calculated plan
Then baseline hydration should remain identifiable
And activity contribution should remain identifiable
And environmental contribution should remain identifiable
And health-state contribution should remain identifiable
And dietary-water contribution should remain identifiable
And safety constraints should remain identifiable

Scenario: Hydrion calculates estimated remaining fluid requirement
Given my contextual fluid requirement has been calculated
And recorded applicable fluid intake is available
And applicable dietary water is available
When Hydrion calculates my remaining requirement
Then Hydrion should subtract applicable consumed water from the contextual requirement
And the remaining requirement should never ignore active safety limits

Scenario: Hydration requirement changes after new activity
Given my daily plan already exists
And I complete additional qualifying activity
When Hydrion receives the activity data
Then Hydrion should recalculate the applicable remaining requirement
And previously consumed fluid should remain credited

Scenario: Hydration requirement changes after health context changes
Given my daily plan already exists
And an applicable health-state modifier changes
When Hydrion refreshes my plan
Then Hydrion should recalculate future hydration guidance
And historical intake should remain unchanged

# ============================================================

# HYDRATION PACING

# ============================================================

Scenario: Hydrion calculates hydration pace
Given a remaining safe hydration requirement exists
And my remaining waking hydration window is known
When Hydrion calculates hydration pace
Then Hydrion should derive an appropriate intake pace across the remaining hydration window

Scenario: Hydration pace changes after drinking
Given a hydration pace is active
When I record additional fluid intake
Then Hydrion should recalculate the remaining requirement
And Hydrion should recalculate the remaining hydration pace

Scenario: Hydration pace changes when time passes
Given a remaining hydration requirement exists
When the remaining waking period becomes shorter
Then Hydrion should recalculate the recommended pace
And Hydrion should continue applying safe intake constraints

Scenario: Hydrion avoids unsafe catch-up drinking
Given I am substantially behind my planned hydration intake
And little time remains in my normal hydration window
When Hydrion recalculates the pace
Then Hydrion should not instruct me to consume an unsafe volume rapidly
And safety limits should take precedence over completing the numerical daily target

Scenario: Hydrion calculates next recommended drink
Given a safe remaining requirement exists
And sufficient scheduling information is available
When Hydrion creates my next hydration recommendation
Then Hydrion should calculate an appropriate next-drink amount
And Hydrion should calculate an appropriate recommendation time
And both should adapt when my context changes

# ============================================================

# OVERHYDRATION PROTECTION

# ============================================================

Scenario: Hydrion detects excessive recorded intake rate
Given recent fluid intake exceeds the configured safe pacing threshold
When Hydrion evaluates my intake history
Then Hydrion should suppress recommendations for additional immediate intake
And Hydrion should activate applicable excessive-intake safety guidance

Scenario: User exceeds calculated daily target
Given I have already met my calculated hydration requirement
When I continue logging fluid
Then Hydrion should continue recording the intake
And Hydrion should not continue encouraging drinking solely to increase completion metrics

Scenario: Hydrion prioritizes safe hydration over streaks and challenges
Given a challenge or streak encourages additional drinking
And the additional drinking conflicts with a hydration safety constraint
When Hydrion evaluates the challenge action
Then the safety constraint should take precedence
And Hydrion should not encourage unsafe fluid consumption for gamification purposes

# ============================================================

# BEHAVIORAL PERSONALIZATION

# ============================================================

Scenario: Hydrion learns usual drinking times
Given sufficient hydration history exists
When Hydrion evaluates my drinking behavior
Then Hydrion may identify recurring intake periods
And those patterns may improve reminder scheduling

Scenario: Hydrion learns typical drink volume
Given sufficient intake history exists
When Hydrion evaluates my drinking events
Then Hydrion may derive my typical consumed volume per drinking event
And the value may improve practical serving recommendations

Scenario: Hydrion learns reminder response
Given I receive hydration reminders
When I respond to or ignore reminders over time
Then Hydrion may calculate reminder-response patterns
And those patterns may improve reminder timing

Scenario: Hydrion identifies long gaps without recorded intake
Given my waking hydration window is active
When Hydrion detects an unusually long interval without recorded hydration
Then the gap may influence reminder timing
And Hydrion should still consider whether I may have consumed unrecorded fluids

Scenario: Hydrion distinguishes weekday and weekend behavior
Given sufficient historical data exists
When Hydrion identifies materially different hydration schedules
Then Hydrion may maintain distinct behavioral patterns for applicable day types

Scenario: Hydrion adapts around usual exercise periods
Given recurring activity times are identifiable
When Hydrion schedules hydration
Then Hydrion may adjust pre-activity and post-activity timing according to applicable safe hydration rules

# ============================================================

# PERSONAL LEARNING MODEL

# ============================================================

Scenario: New user begins with population-based personalization
Given I do not have sufficient personal hydration history
When Hydrion creates my plan
Then Hydrion should rely on approved population-level models and available current context
And the recommendation should indicate its applicable confidence level

Scenario: Hydrion develops a contextual personal model
Given sufficient personal history exists
When Hydrion evaluates repeated relationships between my metrics and hydration behavior
Then Hydrion may create personal contextual coefficients
And those coefficients should remain constrained by validated safety rules

Scenario: Personal data gradually replaces generic estimates
Given a generic estimate is currently used for a metric
And sufficient reliable personal measurements become available
When Hydrion recalculates my personalization model
Then applicable personal measurements should increasingly influence the calculation
And the transition should not bypass safety constraints

Scenario: Hydrion learns personal environmental response
Given sufficient hydration and environmental history exists
When Hydrion detects consistent personal responses to temperature, humidity, or altitude
Then Hydrion may incorporate those patterns into future estimates
And the learned adjustment should remain bounded by configured safety limits

Scenario: Hydrion learns personal activity response
Given sufficient activity and hydration history exists
When Hydrion identifies consistent relationships between activity and fluid loss
Then Hydrion may personalize activity-related hydration estimates

Scenario: Hydrion learns seasonal hydration patterns
Given sufficient long-term hydration and environmental history exists
When Hydrion detects recurring seasonal differences
Then Hydrion may incorporate seasonal context into future recommendations

Scenario: Hydrion does not learn from invalid data
Given a historical metric has been marked invalid, corrupted, duplicated, or unreliable
When Hydrion trains or updates a personal hydration model
Then the invalid metric should be excluded from learning

Scenario: Personal model remains explainable
Given Hydrion uses a learned personal adjustment
When the adjustment affects my hydration plan
Then Hydrion should be able to identify the major categories of data that influenced the adjustment
And Hydrion should not present the learned model as infallible

# ============================================================

# POPULATION TO PERSONAL MODEL PROGRESSION

# ============================================================

Scenario: Hydrion operates at population-model stage
Given insufficient personal history exists
When Hydrion calculates personalization
Then Hydrion should use supported population models
And current individual measurements should still be applied where available

Scenario: Hydrion operates at contextual-model stage
Given sufficient current context exists
And personal longitudinal history remains limited
When Hydrion calculates personalization
Then Hydrion should combine population models with current physiological, environmental, activity, health, and behavioral context

Scenario: Hydrion operates at personal-learned-model stage
Given sufficient high-quality longitudinal data exists
When Hydrion calculates personalization
Then validated personal patterns may influence applicable model coefficients
And safety boundaries should remain independent of learned personalization

Scenario: Personal model confidence decreases after major profile change
Given my personal model was trained using previous physiological conditions
And a substantial body, health, pregnancy, activity, or lifestyle change occurs
When Hydrion evaluates model applicability
Then Hydrion should reduce reliance on outdated personal patterns where appropriate
And new observations should be allowed to establish an updated personal baseline

# ============================================================

# MISSING AND CONFLICTING DATA

# ============================================================

Scenario: Optional metric is unavailable
Given an optional personalization metric is unavailable
When Hydrion calculates my hydration plan
Then Hydrion should continue using available applicable metrics
And Hydrion should not invent the missing value

Scenario: Required metric for a specific model is unavailable
Given a particular hydration model requires a metric that is unavailable
When Hydrion evaluates the model
Then Hydrion should not run that model with fabricated input
And Hydrion should use an eligible fallback model where available

Scenario: Two sources provide materially conflicting measurements
Given two authorized sources provide conflicting values for the same metric
When Hydrion resolves the measurements
Then Hydrion should apply source priority, freshness, and quality rules
And unresolved conflicts should reduce confidence

Scenario: User corrects an incorrect measurement
Given a stored measurement is incorrect
When I correct or remove the measurement
Then future calculations should use the corrected data
And applicable personal learning should no longer rely on the invalidated measurement

# ============================================================

# CALCULATION VERSIONING AND AUDITABILITY

# ============================================================

Scenario: Hydration algorithm is versioned
When Hydrion calculates a personalized hydration plan
Then the calculation should retain the algorithm version
And the input set required for reproducibility should be traceable

Scenario: Hydration model changes after an application update
Given a newer hydration algorithm has been released
When Hydrion creates a new hydration plan
Then the new plan should use the applicable current algorithm version
And historical plans should retain the algorithm version originally used

Scenario: Derived metric retains provenance
Given Hydrion calculates a metric from other measurements
When the derived metric is stored
Then Hydrion should retain the source metric references
And Hydrion should retain the calculation method and version

Scenario: User views hydration calculation context
Given Hydrion has generated my daily hydration plan
When I view the personalization details
Then Hydrion should be able to show the major factors affecting the plan
And Hydrion should distinguish measured, reported, estimated, and learned contributions

# ============================================================

# PRIVACY AND DATA MINIMIZATION

# ============================================================

Scenario: Hydrion collects only enabled health context
Given I have not enabled a health data category
When Hydrion performs personalization
Then Hydrion should not request or use that category solely because it may improve personalization

Scenario: Reproductive health data is optional
Given my profile contains information that could make reproductive health context potentially relevant
When Hydrion offers reproductive health personalization
Then Hydrion should not assume menstruation, pregnancy, fertility, or lactation status
And I should be able to decline the feature

Scenario: Health context is isolated from advertising use
Given Hydrion stores health-related personalization information
When that information is processed
Then it should be used only for authorized health and hydration functionality
And it should not be used to build advertising profiles

Scenario: User removes optional health context
Given I previously provided optional health information
When I remove that information
Then future personalization should stop using the removed information
And Hydrion should update applicable derived metrics or learned context according to its data-deletion policy

# ============================================================

# FINAL HYDRATION PLAN

# ============================================================

Scenario: Hydrion produces a personalized daily hydration plan
Given sufficient safe personalization information is available
When Hydrion finalizes my daily hydration plan
Then the plan should include my applicable daily hydration target
And the plan should include my recorded intake
And the plan should include my estimated remaining requirement
And the plan should include an appropriate hydration pace
And the plan may include a next recommended drink amount
And the plan may include a next recommended hydration time
And the plan should include applicable safety constraints
And the plan should retain a personalization confidence level

Scenario: Hydrion continuously adapts the daily plan
Given my daily hydration plan is active
When new intake, activity, environmental, physiological, dietary, or health context becomes available
Then Hydrion should reevaluate affected calculations
And Hydrion should update future recommendations
And Hydrion should preserve completed historical events

@safety
Scenario: Safety always overrides personalization
Given a personalized calculation conflicts with an active safety rule
When Hydrion finalizes a recommendation
Then the safety rule should take precedence
And Hydrion should never override a clinician-defined restriction or configured safety boundary solely to satisfy a hydration target

Scenario: Hydrion does not claim false precision
Given one or more important hydration inputs are estimated or unavailable
When Hydrion presents my hydration recommendation
Then Hydrion should communicate the appropriate level of uncertainty
And Hydrion should not represent an estimated hydration requirement as an exact physiological measurement
