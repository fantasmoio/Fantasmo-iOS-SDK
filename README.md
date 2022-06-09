# Fantasmo-iOS-SDK

## Overview

Supercharge your app with hyper-accurate positioning using just the camera. The Fantasmo SDK is the gateway to the Camera Positioning System (CPS) which provides 6 Degrees-of-Freedom (position and orientation) localization for mobile devices.

## Functionality

Camera-based localization is the process of determining the global position of the device camera from an image. Image frames are acquired from an active `ARSession` and sent to a server for computation. The server computation time is approximately 900 ms. The full round trip time is then dictated by latency of the connection.

Since the camera will likely move after the moment at which the image frame is captured, it is necessary to track the motion of the device continuously during localizaiton to determine the position of the device at the time of response. Tracking is provided by `ARSession`. Conventiently, it is then possible to determine the global position of the device at any point in the tracking session regardless of when the image was captured (though you may incur some drift after excessive motion).

## Installation

### CocoaPods (iOS 11+)

CocoaPods is a dependency manager for Cocoa projects. For usage and installation instructions, visit https://cocoapods.org/. To integrate Fantasmo SDK into your Xcode project using CocoaPods, specify it in your Podfile:

   `pod 'FantasmoSDK'`

Your Podfile should also include the line `use_frameworks!` at the top

### Carthage (iOS 8+, OS X 10.9+)

You can use Carthage to install Fantasmo SDK by adding it to your Cartfile:
- Get Carthage by running `brew install carthage`
- Create a Cartfile using https://github.com/Carthage/Carthage/blob/master/Documentation/Artifacts.md#cartfile in the same directory where your .xcodeproj or .xcworkspace is and add below dependnacy in it. For example:

   `github "fantasmoio/Fantasmo-iOS-SDK" ~> 2.0.0`

- Add Carthage.sh by unzip [Carthage.sh.zip](https://github.com/fantasmoio/Fantasmo-iOS-SDK/files/5754931/Carthage.sh.zip) and place it to same directory where your .xcodeproj or .xcworkspace is.
- Give execute permission to Carthage.sh by `chmod +x Carthage.sh`
- Note: you may need to update the XCode version number inside the Carthage.sh file. It should work out of the box for XCode 12, but for XCode 13 update the follow section:

`... __XCODE__1200__BUILD_ ...`

to

`... __XCODE__1300__BUILD_ ...`

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

In the near term, the Fantasmo SDK will be provided as a Cocoapod. In the meantime, the Fantasmo SDK directory can be imported directly into a project.

### Access Tokens

Set your Fantasmo access token by adding it to your app's `Info.plist`.
```xml
<key>FM_ACCESS_TOKEN</key>
<string>a0fc7aa1e1144f1e81eaa2ad47794a9e</string>
```

You may also set your access token at runtime via the `FMConfiguration` class.
```swift
FMConfiguration.setAccessToken("a0fc7aa1e1144f1e81eaa2ad47794a9e")
```

Note: Access tokens set via `FMConfiguration` take precedence over ones in the `Info.plist`.

### Camera and Location Access

FantasmoSDK requires access to the device's camera and location. Therefore you will need to add usage descriptions for the following keys in your apps `Info.plist`.

```xml
NSCameraUsageDescription
NSLocationWhenInUseUsageDescription
```

## Requirements

- iOS 11.0+
- Xcode 11.0+
- ARKit
   * iPhone 6s, 6s Plus, SE or newer
   * iPad/iPad Mini 5th Gen or newer
   * iPad Pro (9.7”, 10.5” or 12.9”)
   * iPod touch 7th generation or newer

## Usage

### Quick Start

To park and localize with the Fantasmo SDK, you should first check if parking is available in the user's current location. You can do this with the static method `FMParkingViewController.isParkingAvailable(near:)` and passing a `CLLocation`. The result block is called with a boolean indicating whether or not the user is near a mapped parking space.

```swift
import FantasmoSDK

FMParkingViewController.isParkingAvailable(near: userLocation) { isParkingAvailable in
    if !isParkingAvailable {
        print("No mapped parking spaces nearby.")
        return
    }
    // Safe to start parking flow
    self.startParkingFlow()
}
```
The above method also checks that the device supports ARKit. If the device is not supported, the `completion` block is immediately called with `false`.

```swift
// SomeViewController.swift

func startParkingFlow() {            
    // construct a new parking view controller with a sessionId
    let sessionId = UUID().uuidString
    let sessionTags = ["berlin", "e-scooter"]  // optionally add tags
    let parkingViewController = FMParkingViewController(sessionId: sessionId, sessionTags: sessionTags)

    // configure delegation
    parkingViewController.delegate = self

    // present modally to start
    parkingViewController.modalPresentationStyle = .fullScreen
    self.present(parkingViewController, animated: true)
}
```

### Providing `sessionId` and `sessionTags`

The `sessionId` parameter allows you to associate localization results with your own session identifier. Typically this would be a UUID string, but it can also follow your own format. For example, a scooter parking session might take multiple localization attempts. For analytics and billing purposes, this identifier allows you to link multiple attempts with a single parking session. This string is currently limited to 64 characters.

Similar to `sessionId`, you may also provide a list of `sessionTags`. This optional parameter can be used to label and group parking sessions that have something in common. For example sessions that take place in the same city might have the city name as a tag. These are used for analytics purposes only and will be included in your usage reports. Each tag must be a string and there is currently no limit to the number of tags a session can have.

### Providing Location Updates

By default, during localization the `FMParkingViewController` uses a `CLLocationManager` internally to get automatic updates of the device's location. If you would like to provide your own `CLLocation` updates, you can set the `usesInternalLocationManager` property to `false` and manually call `updateLocation(_ location: CLLocation)` with each update to the location.

```swift
let parkingViewController = FMParkingViewController(sessionId: sessionId)

// disables the internal CLLocationManager
parkingViewController.usesInternalLocationManager = false
self.present(parkingViewController, animated: true)

// create your own CLLocationManager
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

If the SDK does not receive valid `CLLocation` updates either from the internal `CLLocationManager` or manually via `updateLocation(_ location: CLLocation)`, then you will receive a localization error.

```swift
func parkingViewController(_ parkingViewController: FMParkingViewController,
                               didReceiveLocalizationError error: FMError, errorMetadata: Any?) {
    if (error.type as? FMLocationError) == FMLocationError.invalidCoordinate {
        print("No location updates received.")
    }
}
```

If this occurs you should check that you're correctly providing the location updates, or if you're using the internal location manager, that the user has given permission to access the device's location.

### QR Codes

Scanning a QR code is the first and only step before localizing. Because we are trying to localize a vehicle and not the device itself, we need a way to determine the vehicle's position relative to the device. This is accomplished by setting an anchor in the `ARSession` and it's done automatically when the user scans a QR code. 

The SDK doesn't care about the contents of the QR code and by default will start localizing after any QR code is detected. If your app _does_ care about the contents of the QR code, they can be validated by implementing the following method in your `FMParkingViewControllerDelegate`.

```swift
func parkingViewController(_ parkingViewController: FMParkingViewController,
                           didScanQRCode qrCode: CIQRCodeFeature,
                           continueBlock: @escaping ((Bool) -> Void)) {
    // Validate the QR code
    let isValidCode = qrCode.messageString != nil
    
    // Call the continue block with the result
    continueBlock(isValidCode)
    
    // Alternatively, validation can be done asynchronously
    APIService.validateQRCode(qrCode) { isValidCode in
        continueBlock(isValidCode)
    }
}
```

### Manual QR Code Entry

If a code is unable to be scanned, you may want to have the user enter it manually. When using the default QR code scanning UI, this feature is implemented for you. Simply tap the _Enter Manually_ button and enter the code into the prompt. If you are using a custom UI, then you should prompt the user to enter the code and pass the string to the `enterQRCode(string:)` method of your parking view controller.

Validating a manually-entered QR code is also optional and works the same as a validating a scanned one. Implement the following method in your `FMParkingViewControllerDelegate`.

```swift
func parkingViewController(_ parkingViewController: FMParkingViewController,
                           didEnterQRCodeString qrCodeString: String,
                           continueBlock: @escaping ((Bool) -> Void)) {
    // Validate the entered QR code
    let isValidCode = qrCodeString.isEmpty == false
    
    // Call the continue block with the result
    continueBlock(isValidCode)
    
    // Alternatively, validation can be done asynchronously
    APIService.validateQRCode(qrCode) { isValidCode in
        continueBlock(isValidCode)
    }
}
```

**Important:** If you implement either of the QR code validation methods, you must call the `continueBlock` with a boolean value. A value of `true` indicates the QR code is valid and that localization should start. Passing `false` to this block indicates the code is invalid and allows the user to scan, or enter in a new code. This block may be called synchronously or asynchronously but must be done so on the main queue.

### Disabling QR Codes

While we recommend using the QR code scanner, it is not required. If you do not wish to use the QR code scanner, you can disable it by setting the `qrCodeScannerEnabled` property to false. Please note that you must do this before presenting the view controller to the user.

```swift
    // disable the QR code scanner
    parkingViewController.qrCodeScannerEnabled = false
```

Normally when scanning a QR code on a vehicle, an anchor is set in the AR session. This anchor allows Fantasmo to locate the vehicle even if the user walks away. If the QR code scanner is disabled however, this anchor is set at the earliest possible moment during localization. This may result in the anchor not being precisely where the vehicle is, if the user has moved.

### Localizing 

During localization, frames are continuously captured and sent to the server. Filtering logic in the SDK will automatically select the best frames, and it will issue behavior requests to the user to help improve the incoming images. Confidence in the location result increases during successive updates and clients can choose to stop localizing by dismissing the view, when a desired confidence level is reached.

```swift
func parkingViewController(_ parkingViewController: FMParkingViewController,
                           didReceiveLocalizationResult result: FMLocationResult) {
    // Got a localization result
    if result.confidence == .low {
        return
    }
    let coordinate = result.location.coordinate
    print("Coordinate: \(coordinate.latitude), \(coordinate.longitude)")
    // Medium or high confidence, dismiss to stop localizing
    parkingViewController.dismiss(animated: true, completion: nil)
}
```

Localization errors may occur but the localization process will not stop and it is still possible to get a successful localization result. You should decide on an acceptable threshold for errors and only stop localizing when it is reached, again by dismissing the view.

```swift
func parkingViewController(_ parkingViewController: FMParkingViewController,
                           didReceiveLocalizationError error: FMError, errorMetadata: Any?) {
    // Got a localization error
    errorCount += 1
    if errorCount < 5 {
        return
    }
    // Too many errors, dismiss to stop localizing
    parkingViewController.dismiss(animated: true, completion: nil)
}
```

As of right now behavior requests are only available in English. More languages coming soon.

### Customizing UI

The UI for both scanning QR codes and localizing can be completely customized by creating your own implementations of the view protocols.

```swift
public protocol FMQRScanningViewControllerProtocol: UIViewController {
    func didStartQRScanning()
    func didStopQRScanning()
    func didScanQRCode(_ qrCode: CIQRCodeFeature)
}

public protocol FMLocalizingViewControllerProtocol: UIViewController {
    func didStartLocalizing()
    func didRequestLocalizationBehavior(_ behavior: FMBehaviorRequest)
    func didReceiveLocalizationResult(_ result: FMLocationResult)
    func didReceiveLocalizationError(_ error: FMError, errorMetadata: Any?)
}
```

Once you've created view controllers for the above protocols, simply register them with your `FMParkingViewController` instance before presenting it.

```swift
parkingViewController.registerQRScanningViewController(MyCustomQRScanningViewController.self)
parkingViewController.registerLocalizingViewController(MyCustomLocalizingViewController.self)
```

*Tip:* Your custom views are child views of the `FMParkingViewController` and you can access the parking view from within your custom views.

```swift
// MyCustomViewController.swift
let parkingViewController = self.parent as? FMParkingViewController
```

**Important:** Your custom views will be placed on top of a view that displays a live camera feed. Therefore your custom views should be semi-transparent, or contain some areas of transparency to allow the user to see the camera underneath.

### Behavior Requests

To help the user localize successfully and to maximize the result quality, camera input is filtered against common problems and behavior requests are displayed to the user. These are messages explaining what the user should be doing with their device in order to localize properly. For example, if the users device is aimed at the ground, you may receive a `"Tilt your device up"` request. 

If you're using the default localization UI, these requests are already displayed to the user. If you've registered your own custom UI, you should use the `didRequestLocalizationBehavior(_ behavior: FMBehaviorRequest)` method of `FMLocalizingViewControllerProtocol` to display these requests to users. 

```swift
class MyCustomLocalizingViewController: UIViewController, FMLocalizingViewControllerProtocol {
  
    @IBOutlet var label: UILabel!
  
    func didRequestLocalizationBehavior(_ behavior: FMBehaviorRequest) {
        // display the requested behavior to the user
        label.text = behavior.description
    }
}
```

### Simulation Mode

Since it's not always possible to be onsite for testing, a simulation mode is provided. Recorded simulations can be found inside the `FantasmoSDKTestHarness/Videos` folder and set to run in your parking view.

```swift
parkingViewController.simulation = FMSimulation(named: "parking-session-1")
```

### Debugging

Sometimes it's useful to see what's happening under the hood. To see live, detailed debug info you can show the statistics view.

```swift
parkingViewController.showsStatistics = true
```

### Logging

By default only errors and warnings are logged, but other verbosity levels are available: `debug`, `info`, `warning`, and `error`.

```swift
parkingViewController.logLevel = .debug
```

You may also intercept logging calls to send log messages to your own analytics services.

```swift
parkingViewController.logIntercept = { message in
    sendToAnalytics(message)
}
```

### Overrides

For testing, the device location can be specified in the Info.plist.

    key: FM_GPS_LAT_LONG
    value: 25.762586765198417,-80.19404801110545

For _Fantasmo internal development_ testing and demo builds, the API server URL can be specified in the Info.plist. It should _not_ include the URI scheme.

    key: FM_API_BASE_URL
    value: 192:168:0:1:8090/v1/image.localize

## Testing

### Running Tests

To run unit tests from the command line use the following command:

`xcodebuild test -project FantasmoSDK.xcodeproj -scheme FantasmoSDKTests -destination 'platform=iOS Simulator,OS=latest,name=iPhone 12 Pro Max'`

If you would like to see the neatly formatted version that appears in the GitHub actions log pipe the output into xcpretty (you will need to install xcpretty separately):

`xcodebuild test -project FantasmoSDK.xcodeproj -scheme FantasmoSDKTests -destination 'platform=iOS Simulator,OS=latest,name=iPhone 12 Pro Max' | xcpretty`

You can specify multiple target OS and device names to run against if so desired.
