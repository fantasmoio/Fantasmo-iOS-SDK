//
//  FMMovementFilter.swift
//  FantasmoSDK
//
//  Created by lucas kuzma on 3/30/21.
//

import ARKit

class FMMovementFilterRule: FMFrameSequenceFilterRule {
    let threshold: Float = 0.25
    var lastTransform: simd_float4x4 = simd_float4x4(1)
    
    func check(_ frame: ARFrame) -> Result<Void, FMFrameFilterFailure> {
        if exceededThreshold(frame.camera.transform) {
            lastTransform = frame.camera.transform
            return .success(())
        } else {
            return .failure(.movingTooLittle)
        }
    }
    
    func exceededThreshold(_ newTransform:simd_float4x4) -> Bool {
        return !simd_almost_equal_elements(lastTransform, newTransform, threshold)
    }
}

