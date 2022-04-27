- [Fantasmo SDK UI Tests](#fantasmo-sdk-ui-tests)
  * [Running Test Locally](#running-test-locally)
  * [Microsoft App Center](#microsoft-app-center)
    + [App Center Requirements](#app-center-requirements)
    + [Building the XCUI Tests](#building-the-xcui-tests)
    + [Submitting A Build For Testing](#submitting-a-build-for-testing)
  * [Writing Tests](#writing-tests)

# Fantasmo SDK UI Tests

## Running Test Locally

These UI tests should be run on a real device and can be run by plugging in a supported iOS device and going to Product > Test (AppleKey + U) or by clicking the Play button next to any individual test case, or a test class, from within a UI...Tests file.

## Microsoft App Center

The tests also run in Microsoft App Center on wide range of supported iOS devices.

Access to the test runs and AppCenter build settings is restricted to Fantasmo/Tier employees but the last build status is reflected in the badge here. 

[![Build status](https://build.appcenter.ms/v0.1/apps/4a527284-3333-4f45-aff1-dc68d6cead74/branches/develop/badge)](https://appcenter.ms)


### App Center Requirements

You will need:

- [NodeJS](www.NodeJS.org/)
- AppCenter Package: `npm install -g appcenter`

### Building the XCUI Tests

After updating or writing new UI tests a new build will need to be created which is then submitted to App Center. Use the following commnand to achieve this task:

```
rm -rf DerivedData
xcrun xcodebuild build-for-testing \
  -configuration Debug \
  -sdk iphoneos \
  -scheme FantasmoSDKTestHarnessDev \
  -derivedDataPath DerivedData
```

### Submitting A Build For Testing

To submit and run the build via App Center use the following command:

```
appcenter test run xcuitest \
  --app "fantasmo-qa/iOS-Mobile-SDK" \
  --devices "fantasmo-qa/ios-sdk-testing" \
  --test-series "master" \
  --locale "en_US" \
  --build-dir DerivedData/Build/Products/Debug-iphoneos
```

If not already logged into AppCenter, you will be prompted to login. Your account will need to already be added as an Admin or Maintainer via AppCenter. Contact Lucas (CTO) or Nick (Lead iOS Developer) if you need access.

## Writing Tests

For an in depth guide to writing tests that follow the Screeplay pattern see the [Mobile Automation Principles](https://www.notion.so/fantasmo/Mobile-Automation-Principles-41390a5082704e75ba0d76c9f29837c7) document.
