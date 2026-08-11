@v1 @release @android @physical_device
Feature: Android release artifact validation
  Studio-installed debug behavior does not prove that the downloadable release
  artifact is signed, installable, or upgrade-safe on real Android hardware.

  Scenario: Signed Android release artifact installs and preserves app data on upgrade
    Given a signed Hydrion Android release artifact and a supported physical device
    When I install or upgrade the release artifact on that device
    Then Hydrion should launch with the expected persisted user data
