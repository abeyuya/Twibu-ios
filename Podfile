platform :ios, '11.0'
use_frameworks!

#
# 各自必要なpod
#

abstract_target 'All' do
  target 'Twibu' do
    pod 'Fabric'
    pod 'Crashlytics'

    pod 'UITextView+Placeholder'
    pod 'LicensePlist'
    pod 'SwiftIcons'

    target 'TwibuTests' do
      inherit! :search_paths
    end
  end
end

post_install do |installer|
  installer.aggregate_targets.each do |aggregate_target|
    puts aggregate_target.name
    
    if aggregate_target.name == 'Pods-All-Twibu'
      aggregate_target.xcconfigs.each do |config_name, config_file|
        config_file.frameworks.delete('TwitterCore')
        xcconfig_path = aggregate_target.xcconfig_path(config_name)
        config_file.save_as(xcconfig_path)
      end
    end
  end
end

