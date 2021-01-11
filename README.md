# Fantasmo-iOS-SDK

## Overview

Supercharge your app with hyper-accurate positioning using just the camera. The Fantasmo SDK is the gateway to the Camera Positiong System (CPS) which provides 6 Degrees-of-Freedom (position and orientation) localization for mobile devices.

## Installation

### CocoaPods (iOS 11+)
CocoaPods is a dependency manager for Cocoa projects. For usage and installation instructions, visit https://cocoapods.org/. To integrate Fantasmo SDK into your Xcode project using CocoaPods, specify it in your Podfile:

   `pod 'FantasmoSDK'`

### Carthage (iOS 8+, OS X 10.9+)

You can use Carthage to install Fantasmo SDK by adding it to your Cartfile:
- Get Carthage by running `brew install carthage`
- Create a Cartfile using https://github.com/Carthage/Carthage/blob/master/Documentation/Artifacts.md#cartfile in the same directory where your .xcodeproj or .xcworkspace is and add below dependnacy in it. For example:

   `github "fantasmoio/Fantasmo-iOS-SDK" ~> 0.1.11`

- Add Carthage.sh by unzip [Carthage.sh.zip](https://github.com/fantasmoio/Fantasmo-iOS-SDK/files/5754931/Carthage.sh.zip) and place it to same directory where your .xcodeproj or .xcworkspace is.
- Give edit permission to Carthage.sh by `chmod +x Carthage.sh`
- Carthage is run simply by pasting the following command into Terminal:

   `./Carthage.sh update --platform iOS`
   
- In the "General" tab, scroll down to the bottom where you will see “Linked Frameworks and Libraries”. With the Xcode project window still available, open a Finder window and navigate to the project directory. In the project directory, open the following folders: “Carthage/Build/iOS”. In the “iOS” folder, you should see "Alamofire.framework", "BrightFutures.framework" and "FantasmoSDK.framework". Drag the framework into the “Linked Frameworks and Libraries” section of project. 

### Dependencies

Available via Cocoapods:

- `'Alamofire', '~> 5.0.0'`
- `'BrightFutures'`

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

Try out the `Example` project or implement the code below. 

```swift
import FantasmoSDK
import CoreLocation 
import ARKit

var sceneView: ARSCNView!

override func viewDidLoad() {

    sceneView.delegate = self
    sceneView.session.delegate = self

    FMLocationManager.shared.connect(accessToken: "", delegate: self)
    FMLocationManager.shared.startUpdatingLocation()
}

extension ViewController: FMLocationDelegate {
    func locationManager(didUpdateLocation location: CLLocation, 
                         withZones zones: [FMZone]?) {
        // Handle location update
    }
    
    func locationManager(didFailWithError error: Error, 
                         errorMetadata metadata: Any?) {
        // Handle error
    }
}
```

### Initialization

The location manager is accessed through a shared instance. `ARSessionDelegate` methods are swizzled to the SDK so there is no need to pass a reference.  

```swift
FMLocationManager.shared.connect(accessToken: "", delegate: self)
```

### Localizing 

To start location updates:
```swift
FMLocationManager.shared.startUpdatingLocation()
```

Images frames will be continuously captured and sent to the server for localization. 

To stop location updates:
```swift
FMLocationManager.shared.stopUpdatingLocation()
```

Location events are be provided through `FMLocationDelegate`.

```swift
extension ViewController: FMLocationDelegate {
    func locationManager(didUpdateLocation location: CLLocation, 
                         withZones zones: [FMZone]?) {
        // Handle location update
    }
    
    func locationManager(didFailWithError error: Error, 
                         errorMetadata metadata: Any?) {
        // Handle error
    }
}
```

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

### Simulation Mode

Since it's not always possible to be onsite for testing, a simulation mode is provided
queries the localization service with stored images. 

In order to activate simulation mode, set the flag and choose a semantic zone type to simulate. 

```swift
FMLocationManager.shared.isSimulation = true
FMLocationManager.shared.simulationZone = .parking
```
