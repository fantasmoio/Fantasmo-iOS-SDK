//
//  FMMovementFilter.swift
//  FantasmoSDK
//
//  Created by lucas kuzma on 3/30/21.
//

import ARKit

class FMMovementFilter: FMFrameFilter {
    let threshold: Float = 0.05
    var lastTransform: simd_float4x4 = simd_float4x4(1)
    
    func accepts(_ frame: ARFrame) -> Bool {
        let exceeded = exceededThreshold(frame.camera.transform)
        lastTransform = frame.camera.transform
        return exceeded
    }
    
    func exceededThreshold(_ newTransform:simd_float4x4) -> Bool {
        return !simd_almost_equal_elements(lastTransform, newTransform, threshold)
    }
}

