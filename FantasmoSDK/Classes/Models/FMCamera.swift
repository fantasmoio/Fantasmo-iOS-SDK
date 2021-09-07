//
//  FMCamera.swift
//  FantasmoSDK
//
//  Created by Sébastien Roger on 07.09.21.
//

import Foundation
import ARKit

protocol FMCamera : AnyObject {
    var transform : simd_float4x4 { get }
    var eulerAngles : simd_float3 { get }
    var pitch : Float { get }
    var trackingState : ARCamera.TrackingState { get }
    var intrinsics: simd_float3x3 { get }
}
