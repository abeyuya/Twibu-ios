# Uncomment the next line to define a global platform for your project
platform :ios, '11.0'

def common_pods
  pod 'Firebase/Core'
  pod 'Firebase/Analytics'
  pod 'Firebase/Auth'
  pod 'Firebase/Firestore'
  pod 'Firebase/Functions'
  
  pod 'ReSwift'
end

target 'Embedded' do
  use_frameworks!
  common_pods 
end

target 'Twibu' do
  use_frameworks!
  common_pods 
  
  pod 'Firebase/Performance'
  
  pod 'TwitterKit'
  pod 'Fabric'
  pod 'Crashlytics'
  
  pod 'Parchment' # tab menu
  pod 'Kingfisher'
  pod 'SwiftIcons'
  pod 'BadgeSwift'

  pod 'LicensePlist'

  target 'TwibuTests' do
    inherit! :search_paths
    # Pods for testing
  end
end

target 'today-extension' do
  use_frameworks!
  common_pods 
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

