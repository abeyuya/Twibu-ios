platform :ios, '11.0'
use_frameworks!

pod 'Firebase/Core'
pod 'Firebase/Analytics'
pod 'Firebase/Auth'
pod 'Firebase/Firestore'
pod 'Firebase/Functions'
pod 'Firebase/Performance'
pod 'Kingfisher'

target 'Embedded' do
end

target 'today-extension' do
end

target 'Twibu' do
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
  end
end

post_install do |installer|
  installer.aggregate_targets.each do |aggregate_target|
    puts aggregate_target.name

    if aggregate_target.name != 'Pods-Embedded'
      aggregate_target.xcconfigs.each do |config_name, config_file|
        # config_file.other_linker_flags[:frameworks].delete("TwitterCore")

        # config_file.libraries.delete('GoogleAnalytics')

        config_file.frameworks.delete('FirebaseFirestore')
        # config_file.frameworks.delete('FirebaseAnalytics')
        config_file.frameworks.delete('FirebaseCore')
        # config_file.frameworks.delete('FirebaseCoreDiagnostics')
        # config_file.frameworks.delete('FirebaseInstanceID')
        # config_file.frameworks.delete('FirebaseNanoPB')
        # config_file.frameworks.delete('GoogleSymbolUtilities')
        # config_file.frameworks.delete('GoogleTagManager')
        # config_file.frameworks.delete('GoogleToolboxForMac')
        # config_file.frameworks.delete('GoogleUtilities')
        # config_file.frameworks.delete('nanopb')

        xcconfig_path = aggregate_target.xcconfig_path(config_name)
        config_file.save_as(xcconfig_path)
      end
    end

    if aggregate_target.name == 'Pods-Twibu'
      aggregate_target.xcconfigs.each do |config_name, config_file|
        config_file.frameworks.delete('TwitterCore')
        xcconfig_path = aggregate_target.xcconfig_path(config_name)
        config_file.save_as(xcconfig_path)
      end
    end
  end
end
