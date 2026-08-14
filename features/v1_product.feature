@v1 @release @domain
Feature: Hydrion v1 implemented product journeys
  These representative journeys are backed by live Flutter tests against the
  production repositories, services, and presentation flows.

  Background:
    Given the live Hydrion v1 acceptance harness is available

  @hydration @persistence
  Scenario: Hydration logs survive restart and local day rollover
    When hydration state is restored across a restart and local date change
    Then saved logs should remain and the new local day total should reset

  @hydration @persistence
  Scenario: Persisted hydration logs can be edited and deleted
    When a saved hydration record is edited and then deleted
    Then repository totals and history should reflect each mutation

  @challenge @persistence
  Scenario: Challenges preserve join progress completion leave and history state
    When a user exercises the implemented challenge lifecycle
    Then challenge state and evidence should remain correct across restart

  @challenge @personalization @safety
  Scenario: Challenge recommendations never join on the user's behalf
    When Hydrion evaluates a challenge recommendation
    Then recommendation evaluation should not activate a challenge

  @challenge @notification
  Scenario: Timed challenge notifications remain singular across lifecycle changes
    When Pomodoro or Homework notification state starts pauses resumes and stops
    Then each active session should retain one stable notification identity

  @android @reminders @notification
  Scenario: Android reminder definitions remain durable and reconcile safely
    When Android reminder definitions are created edited disabled or restored
    Then reminder persistence and operating-system reconciliation should remain consistent

  @android @widget
  Scenario: Android widgets expose canonical progress and quick logging
    When an Android widget reads or changes canonical hydration state
    Then widget progress and quick logging should use the hydration repository

  @localization
  Scenario: English French and Spanish switch live and persist
    When the user switches among supported production languages
    Then visible and restored language should match the selected locale

  @personalization @goal @regression
  Scenario: A tailored recommendation changes the selected daily goal only after acceptance
    When the user explicitly accepts a reviewed tailored recommendation
    Then the canonical selected daily goal should update and Body Metrics should close

  @personalization @goal @regression
  Scenario: A manual edit does not erase the calculated personalized baseline
    Given the user has accepted a tailored hydration goal
    When the user confirms a manual daily-goal override
    Then the manual goal should become selected and the calculated baseline should remain unchanged

  @permissions @regression
  Scenario: Granted optional access is reflected from operating-system state
    When an optional permission becomes granted and the app resumes
    Then its permission action should display Enabled

  @startup @persistence
  Scenario: Startup restores the correct first-run or returning-user route
    When Hydrion starts with fresh partial or completed onboarding state
    Then startup should route to the corresponding persisted destination

  @profile @persistence @safety
  Scenario: Deleting a local profile clears profile-owned state
    When the user confirms local profile deletion
    Then profile-owned hydration reminder challenge and personalization state should clear
