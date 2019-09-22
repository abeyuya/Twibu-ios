platform :ios, '11.0'
use_frameworks!

#
# 共通のpod
#
pod 'Kingfisher'

#
# 各自必要なpod
#
target 'today-extension' do
end

target 'action-extension' do
end

target 'Twibu' do
  pod 'Firebase/Core'
  pod 'Firebase/Analytics'
  pod 'Firebase/Auth'
  pod 'Firebase/Firestore'
  pod 'Firebase/Functions'
  pod 'Firebase/Performance'
  pod 'TwitterKit'
  pod 'Fabric'
  pod 'Crashlytics'

  pod 'PromisesSwift'
  pod 'UnderKeyboard'
  pod 'UITextView+Placeholder'
  pod 'RealmSwift'
  pod 'ReSwift'
  pod 'Parchment' # tab menu
  pod 'SwiftIcons'
  pod 'BadgeSwift'
  pod 'LicensePlist'
  pod 'PKHUD'

  target 'TwibuTests' do
    inherit! :search_paths
  end
end

post_install do |installer|
  installer.aggregate_targets.each do |aggregate_target|
    puts aggregate_target.name
    
    if aggregate_target.name == 'Pods-Twibu'
      aggregate_target.xcconfigs.each do |config_name, config_file|
        config_file.frameworks.delete('TwitterCore')
        xcconfig_path = aggregate_target.xcconfig_path(config_name)
        config_file.save_as(xcconfig_path)
      end
    end
  end
end

