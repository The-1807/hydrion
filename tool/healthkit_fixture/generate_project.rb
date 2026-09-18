# Uses xcodeproj already installed with the repository's CocoaPods toolchain.
# Generates only ignored build output; production Runner has no fixture dependency.
require 'xcodeproj'
require 'fileutils'

root = File.expand_path('../..', __dir__)
flutter_root = ARGV.fetch(0)
output = File.join(root, 'build', 'healthkit-fixture')
FileUtils.mkdir_p(output)
project = Xcodeproj::Project.new(File.join(output, 'HealthKitFixture.xcodeproj'))
app = project.new_target(:application, 'HealthKitFixture', :ios, '14.0')
tests = project.new_target(:ui_test_bundle, 'FixtureUITests', :ios, '14.0')
tests.add_dependency(app)
app.add_file_references([
  project.main_group.new_file(File.join(__dir__, 'FixtureApp.swift')),
  project.main_group.new_file(File.join(root, 'ios', 'Runner', 'HealthKitHost.swift'))
])
tests.add_file_references([project.main_group.new_file(File.join(__dir__, 'FixtureUITests.swift'))])
flutter = project.frameworks_group.new_file(File.join(flutter_root, 'bin/cache/artifacts/engine/ios/Flutter.xcframework'))
app.frameworks_build_phase.add_file_reference(flutter)
embed = app.new_copy_files_build_phase('Embed Flutter')
embed.dst_subfolder_spec = '10'
embed.add_file_reference(flutter).settings = { 'ATTRIBUTES' => ['CodeSignOnCopy', 'RemoveHeadersOnCopy'] }
info = {
  'CFBundleIdentifier' => '$(PRODUCT_BUNDLE_IDENTIFIER)',
  'CFBundleExecutable' => '$(EXECUTABLE_NAME)',
  'CFBundleName' => 'HealthKit Fixture',
  'CFBundlePackageType' => 'APPL',
  'CFBundleShortVersionString' => '1.0',
  'CFBundleVersion' => '1',
  'UILaunchScreen' => {},
  'NSHealthShareUsageDescription' => 'Read synthetic records to validate the simulator HealthKit bridge.',
  'NSHealthUpdateUsageDescription' => 'Write and clean up synthetic test records in this isolated simulator only.'
}
Xcodeproj::Plist.write_to_path(info, File.join(output, 'Info.plist'))
Xcodeproj::Plist.write_to_path({'com.apple.developer.healthkit' => true}, File.join(output, 'Fixture.entitlements'))
[app, tests].each do |target|
  target.build_configurations.each do |config|
    config.build_settings['SWIFT_VERSION'] = '5.0'
    config.build_settings['SDKROOT'] = 'iphonesimulator'
    config.build_settings['SUPPORTED_PLATFORMS'] = 'iphonesimulator'
    config.build_settings['TARGETED_DEVICE_FAMILY'] = '1'
    config.build_settings['CODE_SIGN_IDENTITY'] = '-'
    config.build_settings['LD_RUNPATH_SEARCH_PATHS'] = ['$(inherited)', '@executable_path/Frameworks', '@loader_path/Frameworks']
    config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = target == app ? 'com.the1807.hydrion.healthkitfixture' : 'com.the1807.hydrion.healthkitfixture.uitests'
    if target == app
      config.build_settings['INFOPLIST_FILE'] = File.join(output, 'Info.plist')
      config.build_settings['CODE_SIGN_ENTITLEMENTS'] = File.join(output, 'Fixture.entitlements')
    else
      config.build_settings['GENERATE_INFOPLIST_FILE'] = 'YES'
      config.build_settings['TEST_TARGET_NAME'] = 'HealthKitFixture'
    end
  end
end
project.save
scheme = Xcodeproj::XCScheme.new
scheme.add_build_target(app)
scheme.set_launch_target(app)
scheme.add_test_target(tests)
scheme.save_as(project.path, 'HealthKitFixture', true)
puts project.path
