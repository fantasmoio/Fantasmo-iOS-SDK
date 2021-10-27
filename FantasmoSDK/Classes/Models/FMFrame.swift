//
//  FMFrame.swift
//  FantasmoSDK
//
//  Created by Sébastien Roger on 07.09.21.
//

import Foundation
import ARKit

protocol FMFrame : AnyObject {
    var fmCamera : FMCamera { get }
    var capturedImage : CVPixelBuffer { get }
    var transformOfDeviceInWorldCS: simd_float4x4 { get }
    var transformOfVirtualDeviceInWorldCS: simd_float4x4 { get }
    var deviceOrientation: UIDeviceOrientation { get }
}
