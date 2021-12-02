//
//  MockFrame.swift
//  FantasmoSDKTests
//
//  Created by Sébastien Roger on 07.09.21.
//

import Foundation
import ARKit
@testable import FantasmoSDK

class MockFrame : FantasmoSDK.FMFrame {
    
    var fmCamera: FantasmoSDK.FMCamera
    
    var capturedImage: CVPixelBuffer
    
    var transformOfDeviceInWorldCS: simd_float4x4
    
    var transformOfVirtualDeviceInWorldCS: simd_float4x4
    
    var deviceOrientation: UIDeviceOrientation
    
    init(fmCamera: FantasmoSDK.FMCamera = MockCamera(), capturedImage: CVPixelBuffer, transformOfDeviceInWorldCS: simd_float4x4 = simd_float4x4(1), transformOfVirtualDeviceInWorldCS: simd_float4x4 = simd_float4x4(1), deviceOrientation: UIDeviceOrientation = .portrait) {
        self.fmCamera = fmCamera
        self.capturedImage = capturedImage
        self.transformOfDeviceInWorldCS = transformOfDeviceInWorldCS
        self.transformOfVirtualDeviceInWorldCS = transformOfVirtualDeviceInWorldCS
        self.deviceOrientation = deviceOrientation
    }
}
