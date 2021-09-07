//
//  FMMovementFilter.swift
//  FantasmoSDK
//
//  Created by lucas kuzma on 3/30/21.
//

import ARKit

public class FMMovementFilter: FMFrameFilter {
    let threshold: Float = 0.001
    var lastTransform: simd_float4x4 = simd_float4x4(1)

    internal func accepts(_ frame: FMFrame) -> FMFrameFilterResult {
        return accepts(frame.fmCamera.transform)
    }
    
    internal func accepts(_ transform: simd_float4x4) -> FMFrameFilterResult {
        if exceededThreshold(transform) {
            lastTransform = transform
            return .accepted
        } else {
            return .rejected(reason: .movingTooLittle)
        }
    }
    
    private func exceededThreshold(_ newTransform:simd_float4x4) -> Bool {
        return !simd_almost_equal_elements(lastTransform, newTransform, threshold)
    }
}

