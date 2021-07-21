//
//  FMLocationManagerTester.swift
//  FantasmoSDK
//
//  Created by Yauheni Klishevich on 19.05.2021.
//

import ARKit

/// Used for injecting into FMLocationManager and getting access to private api for testing purposes.
public protocol FMLocationManagerTester: AnyObject {
    var anchorFrame: ARFrame? { set get }
    
    /// `FMLocationManager` will set this property on tester during initialization.
    var accumulatedARKitInfo: AccumulatedARKitInfo! { set get }
    
    /// - Parameter translationOfAnchorInVirtualDeviceCS: Translation of anchor in non-OpenCV coordinate system of virtual device.
    ///     Provided only in "anchoring" mode, otherwise `nil`.
    ///     For details about virtual device see comment to `ARFrame.transformOfVirtualDeviceInWorldCS`
    func locationManagerDidUpdateLocation(_ location: CLLocation, translationOfAnchorInVirtualDeviceCS: simd_float3?)
}
