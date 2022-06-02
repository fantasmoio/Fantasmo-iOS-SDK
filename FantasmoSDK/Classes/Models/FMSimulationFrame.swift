//
//  FMSimulationFrame.swift
//  FantasmoSDK
//
//  Created by Nicholas Jensen on 02.06.22.
//

import Foundation
import CoreLocation
import ARKit

/// Serializable data structure stored in recorded AR session videos.
struct FMSimulationFrame: Codable {
    let camera: FMSimulationFrameCamera
}

struct FMSimulationFrameCamera: Codable, FMCamera {
    var trackingState: ARCamera.TrackingState
    var eulerAngles: simd_float3
    var transform: simd_float4x4
    var intrinsics: simd_float3x3
    var pitch: Float { return eulerAngles.x }
}
