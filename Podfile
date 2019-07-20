use_frameworks!
platform :ios, '11.0'

def common_pods
  pod 'Firebase/Core'
  pod 'Firebase/Firestore'
  pod 'Firebase/Functions'
  pod 'Firebase/Performance'
  pod 'Kingfisher'
end

target 'Embedded' do
  common_pods
end

target 'today-extension' do
  common_pods
end

target 'Twibu' do
  common_pods

  pod 'Firebase/Analytics'
  pod 'Firebase/Auth'

  pod 'TwitterKit'
  pod 'Fabric'
  pod 'Crashlytics'

  pod 'ReSwift'
  pod 'Parchment' # tab menu
  pod 'SwiftIcons'
  pod 'BadgeSwift'

  pod 'LicensePlist'

  target 'TwibuTests' do
    inherit! :search_paths
    # Pods for testing
  end
end

post_install do |installer|
  installer.aggregate_targets.each do |aggregate_target|
    aggregate_target.xcconfigs.each do |config_name, config_file|
      config_file.other_linker_flags[:frameworks].delete("TwitterCore")
      xcconfig_path = aggregate_target.xcconfig_path(config_name)
      config_file.save_as(xcconfig_path)
    end
  end
end
