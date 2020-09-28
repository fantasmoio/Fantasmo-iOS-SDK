# Fantasmo-iOS-SDK

# Requirements
- iOS 12.0+
- Xcode 11.0

# CocoaPods
CocoaPods is a dependency manager for Cocoa projects. For usage and installation instructions, visit their website. To integrate FantasmoSDK into your Xcode project using CocoaPods, specify it in your Podfile:

pod 'FantasmoSDK', :git => 'https://github.com/fantasmoio/Fantasmo-iOS-SDK.git'


# Usage example
```
import FantasmoSDK
import CoreLocation 
import ARKit

var sceneView: ARSCNView!

override func viewDidLoad() {

    sceneView.delegate = self
    sceneView.session.delegate = self

    FMLocationManager.shared.start(locationDelegate: self, licenseKey: "")
}

extension ViewController: FMLocationDelegate {
    func locationManager(didUpdateLocation location: CLLocation?, locationMetadata metadata: Any) {
         
    }
    
    func locationManager(didFailWithError error: Error, errorMetadata metadata: Any) {
        
    }
}
```
