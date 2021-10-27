//
//  FMMovementFilter.swift
//  FantasmoSDK
//
//  Created by lucas kuzma on 3/30/21.
//

import ARKit

class FMMovementFilter: FMFrameFilter {
    let threshold: Float = 0.001
    var lastTransform: simd_float4x4 = simd_float4x4(1)

    public func accepts(_ frame: FMFrame) -> FMFrameFilterResult {
        if exceededThreshold(frame.fmCamera.transform) {
            lastTransform = frame.fmCamera.transform
            return .accepted
        } else {
            return .rejected(reason: .movingTooLittle)
        }
    }
    
    private func exceededThreshold(_ newTransform:simd_float4x4) -> Bool {
        return !simd_almost_equal_elements(lastTransform, newTransform, threshold)
    }
}

