@v1 @release @ios @widget @physical_device
Feature: iOS daily progress widget
  The widget must display canonical hydration progress without private profile data.

  Scenario: Widget is available in supported families
    Given the Hydrion iOS widget extension is installed
    Then the iOS widget should support small and medium families

  Scenario: Widget loads a valid shared snapshot
    Given a current privacy-safe Hydrion widget snapshot exists
    When WidgetKit loads the Hydrion timeline
    Then the iOS widget should show the canonical hydration progress

  Scenario: Widget has a safe empty state
    Given no Hydrion widget snapshot exists
    When WidgetKit loads the Hydrion timeline
    Then the iOS widget should ask the user to open Hydrion

  Scenario: Widget identifies stale state
    Given the Hydrion widget snapshot is stale
    When WidgetKit loads the Hydrion timeline
    Then the iOS widget should ask the user to refresh Hydrion

  Scenario: Widget snapshot excludes sensitive profile fields
    Given a current privacy-safe Hydrion widget snapshot exists
    Then the iOS widget snapshot should contain no sensitive profile data

  Scenario: Widget opens Hydrion home
    Given a current privacy-safe Hydrion widget snapshot exists
    When I tap the iOS hydration widget
    Then Hydrion should open from the widget deep link

  Scenario: Hydration state change refreshes the timeline
    Given a current privacy-safe Hydrion widget snapshot exists
    When hydration state changes in Hydrion
    Then the shared widget snapshot and WidgetKit timeline should refresh

  @accessibility
  Scenario: Widget announces accessible progress
    Given a current privacy-safe Hydrion widget snapshot exists
    When WidgetKit loads the Hydrion timeline
    Then the iOS widget should expose an accessible progress value
