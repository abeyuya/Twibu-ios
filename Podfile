# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'

target 'Twibu' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  pod 'Firebase/Core'
  pod 'Firebase/Analytics'
  pod 'Firebase/Auth'
  pod 'Firebase/Firestore'
  pod 'Firebase/Functions'
  pod 'TwitterKit'
  pod 'Fabric'
  pod 'Crashlytics'
  
  pod 'Parchment' # tab menu
  pod 'Kingfisher'
  pod 'ReSwift'
  pod 'SwiftIcons'
  pod 'BadgeSwift'

  target 'TwibuTests' do
    inherit! :search_paths
    # Pods for testing
  end

end

post_install do |installer|
  require 'fileutils'
  FileUtils.cp_r(
    'Pods/Target Support Files/Pods-Twibu/Pods-Twibu-acknowledgements.plist',
    'Twibu/4_external/license/Settings.bundle/Acknowledgements.plist',
    :remove_destination => true
  )
end
