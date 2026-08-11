@v1 @release @ios @reminders @notification @physical_device
Feature: iOS hydration reminders
  Hydrion must describe reminder delivery truthfully and preserve reminder definitions.

  Background:
    Given Hydrion is running on iOS with reminder scheduling available

  Scenario: Permission is requested when enabling a first reminder
    Given iOS notification permission has not been requested
    When I enable an iOS hydration reminder
    Then iOS notification permission should be requested once

  Scenario: Granted permission schedules the reminder
    Given iOS notification permission is granted
    When I enable an iOS hydration reminder
    Then the iOS reminder should be persisted and scheduled

  Scenario: Denied permission does not claim delivery
    Given iOS notification permission is denied
    When I enable an iOS hydration reminder
    Then the iOS reminder should be saved but not called enabled

  Scenario: Previously denied permission directs the user to settings
    Given iOS notification permission was previously denied
    When I try to enable an iOS hydration reminder
    Then Hydrion should offer to open iOS settings without prompting again

  Scenario: Scheduling failure is retained safely
    Given iOS reminder scheduling will fail
    When I enable an iOS hydration reminder
    Then the iOS reminder should be saved with a scheduling failure

  Scenario: Editing replaces the operating-system schedule
    Given a scheduled iOS hydration reminder exists
    When I edit the iOS hydration reminder
    Then the old iOS schedule should be cancelled and the edited reminder scheduled

  Scenario: Disabling cancels delivery but preserves the definition
    Given a scheduled iOS hydration reminder exists
    When I disable the iOS hydration reminder
    Then the iOS reminder definition should remain disabled and unscheduled

  Scenario: Deleting removes definition and delivery
    Given a scheduled iOS hydration reminder exists
    When I delete the iOS hydration reminder
    Then the iOS reminder definition and schedule should be removed

  Scenario: Restart reconciles a missing operating-system schedule
    Given a persisted enabled iOS reminder is missing from the operating system
    When Hydrion reconciles iOS reminders after restart
    Then the missing iOS reminder should be scheduled once

  Scenario: An expired reminder is not rescheduled
    Given a persisted iOS reminder has expired
    When Hydrion reconciles iOS reminders after restart
    Then the expired iOS reminder should require rescheduling
