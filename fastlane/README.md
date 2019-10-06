fastlane documentation
================
# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```
xcode-select --install
```

Install _fastlane_ using
```
[sudo] gem install fastlane -NV
```
or alternatively using `brew cask install fastlane`

# Available Actions
## iOS
### ios setup_local
```
fastlane ios setup_local
```

### ios unittest
```
fastlane ios unittest
```

### ios app_distribution
```
fastlane ios app_distribution
```
Push a new beta build to Firebase App Distribution
### ios build_app_adhoc
```
fastlane ios build_app_adhoc
```

### ios submit_appstore
```
fastlane ios submit_appstore
```
Submit ipa to AppStoreConnect
### ios build_app_appstore
```
fastlane ios build_app_appstore
```


----

This README.md is auto-generated and will be re-generated every time [fastlane](https://fastlane.tools) is run.
More information about fastlane can be found on [fastlane.tools](https://fastlane.tools).
The documentation of fastlane can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
