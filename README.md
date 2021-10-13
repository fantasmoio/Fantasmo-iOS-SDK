<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
<!-- *generated with [DocToc](https://github.com/thlorenz/doctoc)* -->

- [Fantasmo-iOS-SDK](#fantasmo-ios-sdk)
  - [Overview](#overview)
  - [Installation](#installation)
    - [CocoaPods (iOS 11+)](#cocoapods-ios-11)
    - [Carthage (iOS 8+, OS X 10.9+)](#carthage-ios-8-os-x-109)
    - [Importing](#importing)
  - [Requirements](#requirements)
  - [Functionality](#functionality)
    - [Localization](#localization)
    - [Anchors](#anchors)
    - [Semantic Zones](#semantic-zones)
  - [Usage](#usage)
    - [Quick Start](#quick-start)
    - [Initialization](#initialization)
    - [Delegation](#delegation)
    - [Localizing](#localizing)
    - [Behaviors](#behaviors)
    - [Anchors](#anchors-1)
    - [Radius Check](#radius-check)
    - [Simulation Mode](#simulation-mode)
    - [Logging](#logging)
    - [Overrides](#overrides)
  - [Testing](#testing)
    - [Running Tests](#running-tests)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# Fantasmo-iOS-SDK

## Overview

Supercharge your app with hyper-accurate positioning using just the camera. The Fantasmo SDK is the gateway to the Camera Positiong System (CPS) which provides 6 Degrees-of-Freedom (position and orientation) localization for mobile devices.

## Installation

### CocoaPods (iOS 11+)

CocoaPods is a dependency manager for Cocoa projects. For usage and installation instructions, visit https://cocoapods.org/. To integrate Fantasmo SDK into your Xcode project using CocoaPods, specify it in your Podfile:

   `pod 'FantasmoSDK'`

Your Podfile should also include the line `use_frameworks!` at the top

### Carthage (iOS 8+, OS X 10.9+)

You can use Carthage to install Fantasmo SDK by adding it to your Cartfile:
- Get Carthage by running `brew install carthage`
- Create a Cartfile using https://github.com/Carthage/Carthage/blob/master/Documentation/Artifacts.md#cartfile in the same directory where your .xcodeproj or .xcworkspace is and add below dependnacy in it. For example:

   `github "fantasmoio/Fantasmo-iOS-SDK" ~> 0.1.16`

- Add Carthage.sh by unzip [Carthage.sh.zip](https://github.com/fantasmoio/Fantasmo-iOS-SDK/files/5754931/Carthage.sh.zip) and place it to same directory where your .xcodeproj or .xcworkspace is.
- Give edit permission to Carthage.sh by `chmod +x Carthage.sh`
- Carthage is run simply by pasting the following command into Terminal:

   `./Carthage.sh update --platform iOS`
   
- In the **General** tab, scroll down to the bottom where you will see **Linked Frameworks and Libraries**. With the Xcode project window still available, open a Finder window and navigate to the project directory. In the project directory, open the following folders: **Carthage/Build/iOS**. In the iOS folder, you should see **FantasmoSDK.framework**. Drag the framework into the **Linked Frameworks and Libraries** section of project and select **Do Not Embed** under Embed option. 

- On your application targets’ Build Phases settings tab, click the + icon and choose New Run Script Phase. Create a Run Script in which you specify your shell (ex: /bin/sh), add the following contents to the script area below the shell:
   
   `/usr/local/bin/carthage copy-frameworks`
   
- Add below files in **Input Files** of above Run Script:   
   `$(SRCROOT)/Carthage/Build/iOS/FantasmoSDK.framework`   
   
- Add below files in **Output Files**:   
   `$(DERIVED_FILE_DIR)/$(FRAMEWORKS_FOLDER_PATH)/FantasmoSDK.framework`
  
### Importing

In the near term, the Fantasmo SDK will be provided as a Cocoapod. In the meantime,
the Fantasmo SDK directory can be imported directly into a project.

## Requirements

- iOS 11.0+
- Xcode 11.0+

## Functionality

### Localization

Camera-based localization is the process of determining the global position of the device camera from an image. Image frames are acquired from an active `ARSession` and sent to a server for computation. The server computation time is approximately 900 ms. The full round trip time is then dictated by latency of the connection.

Since the camera will likely move after the moment at which the image frame is captured, it is necessary to track the motion of the device continuously during localizaiton to determine the position of the device at the time of response. Tracking is provided by `ARSession`. Conventiently, it is then possible to determine the global position of the device at any point in the tracking session regardless of when the image was captured (though you may incur some drift after excessive motion).

### Anchors

Localization determines the position of the camera at a point in time. If it is desired to track the location of an object besides the camera itself (e.g., a scooter), then it is possible to set an anchor point for that object. When an anchor is set, the location update will provide the location of the anchor instead of the camera. The anchor position is determined by applying the inverse motion since the anchor was set until the localization was request was made. 

### Semantic Zones

The utility of precise localization is only as useful as the precision of the underlying map data. Semantic zones (e.g., "micro-geofences") allow your application to make contextual decisions about operating in the environment. 

When a position is found that is in a semantic zone, the server will report the zone type and ID. The zone types are as follows:

+ Street
+ Sidewalk
+ Furniture
+ Crosswalk
+ Access Ramp
+ Mobility parking
+ Auto parking
+ Bus stop
+ Planter


## Usage

### Quick Start 

Check out the `FantasmoSDKParkingExample` target or implement the code below. 

```swift
import UIKit
import FantasmoSDK
import CoreLocation

override func viewDidLoad() {
    super.viewDidLoad()
    
    // first check if parking is available nearby
    FMParkingViewController.isParkingAvailable(near: userLocation) { isParkingAvailable in
        if !isParkingAvailable {
            print("No mapped parking spaces nearby.")
            return
        }
        
        // construct a new parking view with a sessionId
        let sessionId = UUID().uuidString
        let parkingViewController = FMParkingViewController(sessionId: sessionId)
    
        // configure delegation
        parkingViewController.delegate = self
                
        // present modally to start
        parkingViewController.modalPresentationStyle = .fullScreen
        self.present(parkingViewController, animated: true)
    }
}

extension ViewController: FMParkingViewControllerDelegate {
    
    func parkingViewController(_ parkingViewController: FMParkingViewController,
                               didScanQRCode qrCode: CIQRCodeFeature,
                               continueBlock: @escaping ((Bool) -> Void)) {
        // Optional validation of the QR code can be done here
        let isValidCode = qrCode.messageString != nil
        continueBlock(isValidCode)
    }
    
    func parkingViewController(_ parkingViewController: FMParkingViewController,
                               didReceiveLocalizationResult result: FMLocationResult) {
        // Got a localization result
        let coordinate = result.location.coordinate
        print("Coordinate: \(coordinate.latitude), \(coordinate.longitude)\n\nConfidence: \(result.confidence)")
        if result.confidence == .low {
            return
        }
        // Medium or high confidence, dismiss to stop localizing
        parkingViewController.dismiss(animated: true, completion: nil)
    }
    
    func parkingViewController(_ parkingViewController: FMParkingViewController,
                               didReceiveLocalizationError error: FMError, errorMetadata: Any?) {
        // Got a localization error
        errorCount += 1
        print("Error: \(error.localizedDescription)")
        if errorCount < 5 {
            return
        }
        // Too many errors, dismiss to stop localizing
        parkingViewController.dismiss(animated: true, completion: nil)
    }
}
```

### Location Updates

During localization, the `FMParkingViewController` internally uses a `CLLocationManager` to get updates to the device's location. If you would like to provide your own `CLLocation` updates, you can set the `usesInternalLocationManager` property to `false` and manually call `updateLocation(_ location: CLLocation)` with each update to the location.

```swift
let parkingViewController = FMParkingViewController(sessionId: sessionId)
// disables the internal CLLocationManager
parkingViewController.usesInternalLocationManager = false
self.present(parkingViewController, animated: true)

// create our own CLLocationManager
let myLocationManager = CLLocationManager()
myLocationManager.delegate = self
myLocationManager.requestAlwaysAuthorization()
myLocationManager.startUpdatingLocation()

extension ViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // notify the parking view controller of the update
        parkingViewController.updateLocation(locations.last)
    }
}
```

If the SDK does not receive valid `CLLocation` updates either from the internal `CLLocationManager` or manually via `updateLocation(_ location: CLLocation)`, localization will return an error.

```swift
func parkingViewController(_ parkingViewController: FMParkingViewController,
                               didReceiveLocalizationError error: FMError, errorMetadata: Any?) {
    if (error.type as? FMLocationError) == FMLocationError.invalidCoordinate {
        print("No location updates received.")
    }
}
```

### Localizing 

To start location updates:
```swift
FMLocationManager.shared.startUpdatingLocation(sessionId: "")
```

Frames will be continuously captured and sent to the server for localization. Filtering logic in the SDK will automatically select the best frames, and it will issue requests to the user to help improve the incoming images.

The `sessionId` parameter will allow you to associate the location updates with your own session identifier. Typically this would be a UUID string, but it can also follow your own format. For example, a scooter parking session might involve multiple localization attempts. For analytics and billing purposes, this identifier allows you to link a set of attempts with a single parking session.

To stop location updates:
```swift
FMLocationManager.shared.stopUpdatingLocation()
```

Location events are be provided through `FMLocationDelegate`. Confidence in the location result increases during successive updates. Clients can choose to stop location updates when a desired confidence threshold is reached.

```swift
public enum FMResultConfidence {
    case low
    case medium
    case high
}

public struct FMLocationResult {
    public var location: CLLocation
    public var confidence: FMResultConfidence
    public var zones: [FMZone]?
}

extension ViewController: FMLocationDelegate {
    func locationManager(didUpdateLocation result: FMLocationResult) {
        // Handle location update
    }
    
    func locationManager(didFailWithError error: Error, 
                         errorMetadata metadata: Any?) {
        // Handle error
    }
}
```

### Behaviors

To maximize localization quality, camera input is filtered against common problems. The designated `FMLocationDelegate` will be called with behavior requests intended to alleviate such problems.

```swift
extension ViewController: FMLocationDelegate {
    func locationManager(didRequestBehavior behavior: FMBehaviorRequest) {
        // Handle behavior update
    }
}
```

The following behaviors are currently requested:

```swift
public enum FMBehaviorRequest: String {
    case tiltUp = "Tilt your device up"
    case tiltDown = "Tilt your device down"
    case panAround = "Pan around the scene"
    case panSlowly = "Pan more slowly"
}
```

When notified, your application should prompt the user to undertake the remedial behavior. Notifcations are issued at most once per every two seconds. You may use our enum cases to map to your own verbiage or simply rely on our `.rawValue` strings.

### Anchors

In order to get location updates for an anchor, set the anchor before
starting or during location updates. 

```swift
FMLocationManager.shared.setAnchor()
```

To return to device localization, simply unset the anchor point. 

```swift
FMLocationManager.shared.unsetAnchor()
```

Anchoring relies on ARKit and is therefore supported by iPhone SE, iPhone 6s, iPhone 6s Plus and newer.

### Radius Check

In order to check if a zone, like parking, is within a given radius of the current device location (as provided by CoreLocation) before attempting to localize, use the `isZoneInRadius` method. The method takes a closure which provides a boolean result.

Currently only `.parking` zones are supported.

```swift
FMLocationManager.shared.isZoneInRadius(.parking, radius: 50) { result in
  self.isParkingInRadius = result
}
```

### Simulation Mode

Since it's not always possible to be onsite for testing, a simulation mode is provided
queries the localization service with stored images. 

In order to activate simulation mode, set the flag and choose a semantic zone type to simulate. 

```swift
FMLocationManager.shared.isSimulation = true
FMLocationManager.shared.simulationZone = .parking
```

### Logging

By default only errors and warnings are logged, but other verbosity levels are available: `debug`, `info`, `warning`, and `error`.

```swift
FMLocationManager.shared.logLevel = .debug
```

### Overrides

For testing, the device location can be specified in the Info.plist.

    key: FM_GPS_LAT_LONG
    value: 25.762586765198417,-80.19404801110545

For _internal development_ testing and demo builds, the API server URL can be specified in the Info.plist. It should _not_ include the URI scheme.

    key: FM_API_BASE_URL
    value: 192:168:0:1:8090/v1/image.localize

## Testing

### Running Tests

To run unit tests from the command line use the following command:

`xcodebuild test -project FantasmoSDK.xcodeproj -scheme FantasmoSDKTests -destination 'platform=iOS Simulator,OS=latest,name=iPhone 12 Pro Max'`

If you would like to see the neatly formatted version that appears in the GitHub actions log pipe the output into xcpretty (you will need to install xcpretty separately):

`xcodebuild test -project FantasmoSDK.xcodeproj -scheme FantasmoSDKTests -destination 'platform=iOS Simulator,OS=latest,name=iPhone 12 Pro Max' | xcpretty`

You can specify multiple target OS and device names to run against if so desired.
