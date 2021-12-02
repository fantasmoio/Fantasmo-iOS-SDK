//
//  MockCamera.swift
//  FantasmoSDKTests
//
//  Created by Sébastien Roger on 07.09.21.
//

import Foundation
import ARKit
@testable import FantasmoSDK

class MockCamera : FantasmoSDK.FMCamera {
    
    var transform: simd_float4x4
    
    var eulerAngles: simd_float3
    
    var pitch: Float
    
    var trackingState: ARCamera.TrackingState
    
    var intrinsics: simd_float3x3
    
    init(transform: simd_float4x4 = simd_float4x4(1), eulerAngles: simd_float3 = simd_float3(repeating: 0), pitch: Float = 0, trackingState: ARCamera.TrackingState = .notAvailable, intrinsics: simd_float3x3 = simd_float3x3(0)) {
        self.transform = transform
        self.eulerAngles = eulerAngles
        self.pitch = pitch
        self.trackingState = trackingState
        self.intrinsics = intrinsics
    }
}
