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

  @startup @persistence
  Scenario: Startup restores the correct first-run or returning-user route
    When Hydrion starts with fresh partial or completed onboarding state
    Then startup should route to the corresponding persisted destination

  @profile @persistence @safety
  Scenario: Deleting a local profile clears profile-owned state
    When the user confirms local profile deletion
    Then profile-owned hydration reminder challenge and personalization state should clear
