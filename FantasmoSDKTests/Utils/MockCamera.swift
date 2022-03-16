//
//  MockCamera.swift
//  FantasmoSDKTests
//
//  Created by Sébastien Roger on 07.09.21.
//

import Foundation
import ARKit
@testable import FantasmoSDK

class MockCamera : FMCamera {
    
    var transform: simd_float4x4
    
    var eulerAngles: simd_float3
    
    var trackingState: ARCamera.TrackingState
    
    var intrinsics: simd_float3x3
    
    var pitch: Float { eulerAngles.x }
    
    var yaw: Float { eulerAngles.y }
    
    var roll: Float { eulerAngles.z }
    
    /// default values pass frame filters
    init(
        transform: simd_float4x4 = simd_float4x4(Float.random(in: 0...Float.greatestFiniteMagnitude)),
        eulerAngles: simd_float3 = simd_float3(x: 0, y: 0, z: -Float.pi / 2.0), // portrait oriented
        trackingState: ARCamera.TrackingState = .normal,
        intrinsics: simd_float3x3 = simd_float3x3(0))
    {
        self.transform = transform
        self.eulerAngles = eulerAngles
        self.trackingState = trackingState
        self.intrinsics = intrinsics
    }
    
    convenience init(pitch: Float = 0.0, yaw: Float = 0.0, roll: Float = 0.0) {
        self.init(eulerAngles: simd_float3(x: pitch, y: yaw, z: roll))
    }
}
